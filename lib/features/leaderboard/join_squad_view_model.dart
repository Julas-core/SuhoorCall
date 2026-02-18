import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/p2p_contracts.dart';
import '../../services/p2p/p2p_repository_factory.dart';

class SquadMember {
  final String id;
  final String displayName;
  final DateTime joinedAt;

  const SquadMember({
    required this.id,
    required this.displayName,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  factory SquadMember.fromMap(Map<String, dynamic> map) {
    return SquadMember(
      id: map['id'] as String,
      displayName: map['displayName'] as String,
      joinedAt: DateTime.parse(map['joinedAt'] as String),
    );
  }
}

class JoinSquadViewModel extends ChangeNotifier {
  static const String _storageKey = 'squad_members_v1';

  final P2pRepository _repository;
  SharedPreferences? _sharedPreferences;

  StreamSubscription<P2pTransportEvent>? _eventsSubscription;

  List<SquadMember> _members = [];
  List<P2pPeer> _discoveredPeers = [];

  bool _isScanning = false;
  String _statusMessage = 'Ready to scan';
  String? _currentSessionNonce;
  JoinQrPayload? _activeJoinQrPayload;

  JoinSquadViewModel({P2pRepository? repository})
    : _repository =
          repository ?? P2pRepositoryFactory.createHybridRepository() {
    _initialize();
  }

  List<SquadMember> get members => _members;
  bool get isScanning => _isScanning;
  String get statusMessage => _statusMessage;

  Future<void> _initialize() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    await _loadPersistedMembers();
    _eventsSubscription = _repository.events.listen(_handleTransportEvent);
  }

  static String buildSampleQrPayload() {
    final samplePayload = JoinQrPayload(
      peerId: 'nearby-peer-1',
      peerDisplayName: 'Nearby Brother',
      sessionNonce: DateTime.now().microsecondsSinceEpoch.toString(),
      handshakeString: P2pRepositoryFactory.handshakeString,
      protocolVersion: P2pRepositoryFactory.protocolVersion,
      timestamp: DateTime.now().toUtc(),
    );

    return samplePayload.toEncodedString();
  }

  Future<void> scanToJoin(String qrPayloadRaw) async {
    if (_isScanning) {
      return;
    }

    late final JoinQrPayload parsedPayload;
    try {
      parsedPayload = JoinQrPayload.fromEncodedString(qrPayloadRaw);
    } catch (_) {
      _statusMessage = 'Invalid QR payload';
      notifyListeners();
      return;
    }

    _activeJoinQrPayload = parsedPayload;
    _currentSessionNonce = parsedPayload.sessionNonce;

    _isScanning = true;
    _statusMessage = 'Scanning for QR...';
    _discoveredPeers = [];
    notifyListeners();

    try {
      await _repository.startDiscovery(targetPeerId: parsedPayload.peerId);
    } catch (_) {
      _isScanning = false;
      _statusMessage = 'Unable to start scan';
      notifyListeners();
    }
  }

  Future<void> addSquadMemberManually(String displayName) async {
    final cleanedName = displayName.trim();
    if (cleanedName.isEmpty) {
      return;
    }

    final newMember = SquadMember(
      id: 'manual-${DateTime.now().millisecondsSinceEpoch}',
      displayName: cleanedName,
      joinedAt: DateTime.now(),
    );

    _members = [..._members, newMember];
    await _persistMembers();
    _statusMessage = '$cleanedName added to squad';
    notifyListeners();
  }

  void _handleTransportEvent(P2pTransportEvent event) {
    switch (event.type) {
      case P2pTransportEventType.peerDiscovered:
        final discoveredPeer = event.peer;
        if (discoveredPeer == null) {
          return;
        }

        final peerExists = _discoveredPeers.any(
          (peer) => peer.id == discoveredPeer.id,
        );
        if (!peerExists) {
          _discoveredPeers = [..._discoveredPeers, discoveredPeer];

          final expectedPeerId = _activeJoinQrPayload?.peerId;
          if (expectedPeerId != null && discoveredPeer.id != expectedPeerId) {
            return;
          }

          unawaited(_connectAndHandshake(discoveredPeer));
        }
        break;

      case P2pTransportEventType.messageReceived:
        final message = event.message;
        if (message == null) {
          return;
        }
        unawaited(_handleIncomingMessage(message));
        break;

      case P2pTransportEventType.error:
        _isScanning = false;
        _statusMessage = event.errorMessage ?? 'Connection error';
        notifyListeners();
        break;

      case P2pTransportEventType.discoveryStarted:
      case P2pTransportEventType.connected:
      case P2pTransportEventType.disconnected:
        break;
    }
  }

  Future<void> _connectAndHandshake(P2pPeer peer) async {
    try {
      _currentSessionNonce = _generateSessionNonce();
      _statusMessage = 'Connecting to ${peer.displayName}...';
      notifyListeners();

      await _repository.connectToPeer(peer);

      final handshakePayload = HandshakePayload(
        handshakeString:
            _activeJoinQrPayload?.handshakeString ??
            P2pRepositoryFactory.handshakeString,
        peerId: peer.id,
        sessionNonce: _currentSessionNonce!,
        protocolVersion:
            _activeJoinQrPayload?.protocolVersion ??
            P2pRepositoryFactory.protocolVersion,
        timestamp: DateTime.now().toUtc(),
      );

      final handshakeEnvelope = MessageEnvelope(
        type: P2pMessageType.handshakeResponse,
        senderId: peer.id,
        recipientId: 'local-user',
        sessionNonce: _currentSessionNonce!,
        payload: handshakePayload.toMap(),
        timestamp: DateTime.now().toUtc(),
      );

      await _repository.sendMessage(handshakeEnvelope);
    } catch (_) {
      _isScanning = false;
      _statusMessage = 'Could not join ${peer.displayName}';
      notifyListeners();
    }
  }

  Future<void> _handleIncomingMessage(MessageEnvelope envelope) async {
    if (envelope.type != P2pMessageType.handshakeResponse) {
      return;
    }

    try {
      final payload = HandshakePayload.fromMap(envelope.payload);
      final expectedNonce = envelope.sessionNonce;
      final isValid = await _repository.verifyHandshake(payload, expectedNonce);
      final expectedPayload = _activeJoinQrPayload;

      final isExpectedPeer = expectedPayload == null
          ? true
          : payload.peerId == expectedPayload.peerId;
      final isExpectedHandshakeString = expectedPayload == null
          ? true
          : payload.handshakeString == expectedPayload.handshakeString;
      final isExpectedProtocol = expectedPayload == null
          ? true
          : payload.protocolVersion == expectedPayload.protocolVersion;
      final isExpectedNonce = expectedPayload == null
          ? true
          : payload.sessionNonce == expectedPayload.sessionNonce;

      if (!isValid ||
          !isExpectedPeer ||
          !isExpectedHandshakeString ||
          !isExpectedProtocol ||
          !isExpectedNonce) {
        _isScanning = false;
        _statusMessage = 'Handshake verification failed';
        notifyListeners();
        return;
      }

      final peerName = _discoveredPeers
          .where((peer) => peer.id == payload.peerId)
          .map((peer) => peer.displayName)
          .cast<String?>()
          .fold<String?>(null, (previous, current) => previous ?? current);

      final memberName = peerName ?? 'Squad Member';
      final alreadyExists = _members.any(
        (member) => member.id == payload.peerId,
      );

      if (!alreadyExists) {
        _members = [
          ..._members,
          SquadMember(
            id: payload.peerId,
            displayName: memberName,
            joinedAt: DateTime.now(),
          ),
        ];
        await _persistMembers();
      }

      _isScanning = false;
      _statusMessage = '$memberName joined successfully';
      _activeJoinQrPayload = null;
      notifyListeners();

      await _repository.stopDiscovery();
    } catch (_) {
      _isScanning = false;
      _statusMessage = 'Invalid handshake payload';
      notifyListeners();
    }
  }

  String _generateSessionNonce() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  Future<void> _loadPersistedMembers() async {
    final prefs = _sharedPreferences;
    if (prefs == null) {
      return;
    }

    final rawMembers = prefs.getString(_storageKey);
    if (rawMembers == null || rawMembers.isEmpty) {
      return;
    }

    final decodedMembers = (jsonDecode(rawMembers) as List<dynamic>)
        .map(
          (entry) =>
              SquadMember.fromMap(Map<String, dynamic>.from(entry as Map)),
        )
        .toList();

    _members = decodedMembers;
    notifyListeners();
  }

  Future<void> _persistMembers() async {
    final prefs = _sharedPreferences;
    if (prefs == null) {
      return;
    }

    final encodedMembers = jsonEncode(
      _members.map((member) => member.toMap()).toList(),
    );

    await prefs.setString(_storageKey, encodedMembers);
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
