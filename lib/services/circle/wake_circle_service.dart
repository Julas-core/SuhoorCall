import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/circle_models.dart';
import '../../core/p2p_contracts.dart';
import '../p2p/p2p_repository_factory.dart';

class WakeCircleService extends ChangeNotifier {
	WakeCircleService._internal({P2pRepository? repository})
		: _repository =
					repository ?? P2pRepositoryFactory.createHybridRepository() {
		unawaited(_initialize());
	}

	static final WakeCircleService _instance = WakeCircleService._internal();

	factory WakeCircleService() => _instance;

	static const String _membersStorageKey = 'squad_members_v1';
	static const String _hostCircleStorageKey = 'host_circle_qr_v1';
	static const String _hostCircleIdStorageKey = 'host_circle_id_v1';
	static const String _joinedCircleIdStorageKey = 'joined_circle_id_v1';
	static const String _localPeerIdStorageKey = 'local_peer_id_v1';
	static const String _activeWakeEventStorageKey = 'active_wake_event_v1';
	static const Duration _scanTimeoutDuration = Duration(seconds: 10);

	final P2pRepository _repository;
	final StreamController<void> _membersChangedController =
			StreamController<void>.broadcast();

	SharedPreferences? _sharedPreferences;
	StreamSubscription<P2pTransportEvent>? _eventsSubscription;
	Timer? _scanTimeoutTimer;

	List<CircleMember> _members = [];
	List<P2pPeer> _discoveredPeers = [];

	bool _isInitialized = false;
	bool _isScanning = false;
	bool _isGeneratingQr = false;
	String _statusMessage = 'Ready to scan';

	String? _hostInvitationPayload;
	WakeCircle? _hostCircle;
	String? _joinedCircleId;
	String? _hostPeerIdForCurrentCircle;
	String _localPeerId = '';
	String? _currentSessionNonce;
	JoinQrPayload? _activeJoinQrPayload;
	WakeEvent? _activeWakeEvent;

	bool get isInitialized => _isInitialized;
	bool get isScanning => _isScanning;
	bool get isGeneratingQr => _isGeneratingQr;
	String get statusMessage => _statusMessage;
	String get localPeerId => _localPeerId;
	List<CircleMember> get members => List.unmodifiable(_members);
	String? get hostInvitationPayload => _hostInvitationPayload;
	String? get hostCircleId => _hostCircle?.circleId;
	String? get joinedCircleId => _joinedCircleId;
	String? get activeCircleId => _hostCircle?.circleId ?? _joinedCircleId;
	WakeEvent? get activeWakeEvent => _activeWakeEvent;

	Stream<void> get membersChanged => _membersChangedController.stream;

	int get awakeCount => _members
			.where((member) => member.wakeStatus == MemberWakeStatus.awake)
			.length;

	int get notYetAwakeCount => _members
			.where((member) => member.wakeStatus == MemberWakeStatus.notYetAwake)
			.length;

	int get unreachableCount => _members
			.where((member) => member.wakeStatus == MemberWakeStatus.unreachable)
			.length;

	bool get isCurrentUserAwake {
		final me = _members.where((member) => member.id == _localPeerId).firstOrNull;
		if (me == null) {
			return false;
		}
		return me.wakeStatus == MemberWakeStatus.awake;
	}

	Future<void> ensureInitialized() async {
		if (_isInitialized) {
			return;
		}

		await _initialize();
	}

	Future<void> _initialize() async {
		if (_isInitialized) {
			return;
		}

		_sharedPreferences = await SharedPreferences.getInstance();
		await _initializeLocalPeerId();
		await _loadPersistedState();
		_eventsSubscription = _repository.events.listen(_handleTransportEvent);
		_isInitialized = true;
		notifyListeners();
	}

	Future<String> createCircleAndBuildInvitation({
		String hostDisplayName = 'Circle Host',
	}) async {
		await ensureInitialized();

		if (_isGeneratingQr) {
			return _hostInvitationPayload ?? '';
		}

		_isGeneratingQr = true;
		notifyListeners();

		try {
			final circleId = _generateCircleId();
			final hostPeerId = _localPeerId;
			final sessionNonce = _generateSessionNonce();

			final invitationPayload = JoinQrPayload(
				circleId: circleId,
				peerId: hostPeerId,
				peerDisplayName: hostDisplayName,
				sessionNonce: sessionNonce,
				handshakeString: P2pRepositoryFactory.handshakeString,
				protocolVersion: P2pRepositoryFactory.protocolVersion,
				timestamp: DateTime.now().toUtc(),
			).toEncodedString();

			_hostCircle = WakeCircle(
				circleId: circleId,
				hostPeerId: hostPeerId,
				createdAt: DateTime.now(),
			);
			_hostPeerIdForCurrentCircle = hostPeerId;
			_hostInvitationPayload = invitationPayload;

			await _sharedPreferences?.setString(_hostCircleStorageKey, invitationPayload);
			await _sharedPreferences?.setString(_hostCircleIdStorageKey, circleId);

			_statusMessage = 'Circle $circleId created. Share QR with your squad.';
			await _ensureLocalMemberExists(defaultStatus: MemberWakeStatus.notYetAwake);
			notifyListeners();

			return invitationPayload;
		} finally {
			_isGeneratingQr = false;
			notifyListeners();
		}
	}

	Future<void> scanToJoin(String qrPayloadRaw) async {
		await ensureInitialized();

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
		_hostPeerIdForCurrentCircle = parsedPayload.peerId;
		_joinedCircleId = parsedPayload.circleId;
		if (_joinedCircleId != null) {
			await _sharedPreferences?.setString(_joinedCircleIdStorageKey, _joinedCircleId!);
		}
		_currentSessionNonce = parsedPayload.sessionNonce;

		_isScanning = true;
		_statusMessage = _joinedCircleId == null
				? 'Scanning for QR...'
				: 'Scanning for circle $_joinedCircleId...';
		_discoveredPeers = [];
		await _ensureLocalMemberExists(defaultStatus: MemberWakeStatus.notYetAwake);
		notifyListeners();

		_scanTimeoutTimer?.cancel();
		_scanTimeoutTimer = Timer(_scanTimeoutDuration, () async {
			if (!_isScanning) {
				return;
			}

			_isScanning = false;
			_statusMessage = _joinedCircleId == null
					? 'No nearby peer found. Try scanning again.'
					: 'No nearby peer found for circle $_joinedCircleId. Try scanning again.';
			_activeJoinQrPayload = null;
			notifyListeners();
			await _repository.stopDiscovery();
		});

		try {
			await _repository.startDiscovery(targetPeerId: parsedPayload.peerId);
		} catch (_) {
			_scanTimeoutTimer?.cancel();
			_scanTimeoutTimer = null;
			_isScanning = false;
			_statusMessage = 'Unable to start scan';
			notifyListeners();
		}
	}

	Future<void> addSquadMemberManually(String displayName) async {
		await ensureInitialized();

		final cleanedName = displayName.trim();
		if (cleanedName.isEmpty) {
			return;
		}

		final newMember = CircleMember(
			id: 'manual-${DateTime.now().millisecondsSinceEpoch}',
			displayName: cleanedName,
			joinedAt: DateTime.now(),
			wakeStatus: MemberWakeStatus.notYetAwake,
		);

		_members = [..._members, newMember];
		await _persistMembers();
		_statusMessage = '$cleanedName added to squad';
		notifyListeners();
	}

	Future<void> setMemberWakeStatus(
		String memberId,
		MemberWakeStatus status,
	) async {
		await ensureInitialized();

		final index = _members.indexWhere((member) => member.id == memberId);
		if (index == -1) {
			return;
		}

		final updatedMembers = [..._members];
		final member = updatedMembers[index];
		updatedMembers[index] = member.copyWith(wakeStatus: status);
		_members = updatedMembers;

		_statusMessage = '${member.displayName}: ${_labelForStatus(status)}';
		await _persistMembers();
		await _broadcastAwakeStatus(updatedMembers[index]);
		notifyListeners();
	}

	Future<void> startWakeEvent() async {
		await ensureInitialized();

		if (_members.isEmpty) {
			return;
		}

		await _setAllMembersStatus(MemberWakeStatus.notYetAwake);

		final event = WakeEvent(
			id: 'wake-${DateTime.now().millisecondsSinceEpoch}',
			circleId: activeCircleId ?? 'local-circle',
			initiatedByPeerId: _localPeerId,
			startedAt: DateTime.now().toUtc(),
			status: WakeEventStatus.active,
		);
		_activeWakeEvent = event;
		await _persistActiveWakeEvent();

		_statusMessage = 'Wake event started. Awaiting confirmations.';

		final envelope = MessageEnvelope(
			type: P2pMessageType.awakeStatus,
			senderId: _localPeerId,
			recipientId: null,
			sessionNonce: _currentSessionNonce ?? _generateSessionNonce(),
			payload: {
				'action': 'wakeStart',
				'circleId': activeCircleId,
				'status': MemberWakeStatus.notYetAwake.name,
			},
			timestamp: DateTime.now().toUtc(),
		);

		try {
			await _repository.sendMessage(envelope);
		} catch (_) {
			// Keep local state even if transport unavailable.
		}

		notifyListeners();
	}

	Future<void> markCurrentDeviceAwake() async {
		await ensureInitialized();

		if (_localPeerId.isEmpty) {
			return;
		}

		final existing = _members.where((member) => member.id == _localPeerId).firstOrNull;
		if (existing == null) {
			await _upsertMember(
				id: _localPeerId,
				displayName: 'You',
				wakeStatus: MemberWakeStatus.awake,
			);
		} else {
			await setMemberWakeStatus(_localPeerId, MemberWakeStatus.awake);
			return;
		}

		final current = _members.where((member) => member.id == _localPeerId).firstOrNull;
		if (current != null) {
			await _broadcastAwakeStatus(current);
		}

		_statusMessage = 'You are Awake';
		notifyListeners();
	}

	String labelForStatus(MemberWakeStatus status) {
		return _labelForStatus(status);
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

	void _handleTransportEvent(P2pTransportEvent event) {
		switch (event.type) {
			case P2pTransportEventType.peerDiscovered:
				final discoveredPeer = event.peer;
				if (discoveredPeer == null) {
					return;
				}

				final peerExists = _discoveredPeers.any((peer) => peer.id == discoveredPeer.id);
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
			_currentSessionNonce ??= _generateSessionNonce();
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
				senderId: 'local-user',
				recipientId: peer.id,
				sessionNonce: _currentSessionNonce!,
				payload: handshakePayload.toMap(),
				timestamp: DateTime.now().toUtc(),
			);

			await _repository.sendMessage(handshakeEnvelope);
		} catch (_) {
			_scanTimeoutTimer?.cancel();
			_scanTimeoutTimer = null;
			_isScanning = false;
			_statusMessage = 'Could not join ${peer.displayName}';
			notifyListeners();
		}
	}

	Future<void> _handleIncomingMessage(MessageEnvelope envelope) async {
		if (envelope.type == P2pMessageType.awakeStatus) {
			final action = envelope.payload['action'] as String?;
			if (action == 'wakeStart') {
				await _setAllMembersStatus(MemberWakeStatus.notYetAwake);
				_statusMessage = 'Wake event started';
				notifyListeners();
				return;
			}

			final memberId = envelope.payload['memberId'] as String?;
			if (memberId == null || memberId.isEmpty) {
				return;
			}

			final memberName =
					(envelope.payload['displayName'] as String?) ?? 'Squad Member';
			final rawStatus = envelope.payload['status'] as String?;
			final wakeStatus = MemberWakeStatus.values.firstWhere(
				(value) => value.name == rawStatus,
				orElse: () => MemberWakeStatus.notYetAwake,
			);

			await _upsertMember(
				id: memberId,
				displayName: memberName,
				wakeStatus: wakeStatus,
			);
			_statusMessage = '$memberName is ${_labelForStatus(wakeStatus)}';
			notifyListeners();
			return;
		}

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
				_scanTimeoutTimer?.cancel();
				_scanTimeoutTimer = null;
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
			final alreadyExists = _members.any((member) => member.id == payload.peerId);

			if (!alreadyExists) {
				await _upsertMember(
					id: payload.peerId,
					displayName: memberName,
					wakeStatus: MemberWakeStatus.notYetAwake,
				);
			}

			_isScanning = false;
			_statusMessage = '$memberName joined successfully';
			_activeJoinQrPayload = null;
			_scanTimeoutTimer?.cancel();
			_scanTimeoutTimer = null;
			notifyListeners();

			await _repository.stopDiscovery();
		} catch (_) {
			_scanTimeoutTimer?.cancel();
			_scanTimeoutTimer = null;
			_isScanning = false;
			_statusMessage = 'Invalid handshake payload';
			notifyListeners();
		}
	}

	Future<void> _loadPersistedState() async {
		final prefs = _sharedPreferences;
		if (prefs == null) {
			return;
		}

		final rawMembers = prefs.getString(_membersStorageKey);
		if (rawMembers != null && rawMembers.isNotEmpty) {
			final decodedMembers = (jsonDecode(rawMembers) as List<dynamic>)
					.map(
						(entry) => CircleMember.fromMap(Map<String, dynamic>.from(entry as Map)),
					)
					.toList();
			_members = decodedMembers;
		}

		_hostInvitationPayload = prefs.getString(_hostCircleStorageKey);
		final hostCircleId = prefs.getString(_hostCircleIdStorageKey);
		if (hostCircleId != null && hostCircleId.isNotEmpty) {
			_hostCircle = WakeCircle(
				circleId: hostCircleId,
				hostPeerId: _localPeerId,
				createdAt: DateTime.now(),
			);
		}

		_joinedCircleId = prefs.getString(_joinedCircleIdStorageKey);

		final rawWakeEvent = prefs.getString(_activeWakeEventStorageKey);
		if (rawWakeEvent != null && rawWakeEvent.isNotEmpty) {
			try {
				_activeWakeEvent = WakeEvent.fromMap(
					Map<String, dynamic>.from(jsonDecode(rawWakeEvent) as Map),
				);
			} catch (_) {
				_activeWakeEvent = null;
			}
		}

		await _ensureLocalMemberExists(defaultStatus: MemberWakeStatus.notYetAwake);
		notifyListeners();
	}

	Future<void> _initializeLocalPeerId() async {
		final prefs = _sharedPreferences;
		if (prefs == null) {
			return;
		}

		final stored = prefs.getString(_localPeerIdStorageKey);
		if (stored != null && stored.isNotEmpty) {
			_localPeerId = stored;
			return;
		}

		_localPeerId = 'peer-${DateTime.now().millisecondsSinceEpoch}';
		await prefs.setString(_localPeerIdStorageKey, _localPeerId);
	}

	Future<void> _ensureLocalMemberExists({
		required MemberWakeStatus defaultStatus,
	}) async {
		if (_localPeerId.isEmpty) {
			return;
		}

		final exists = _members.any((member) => member.id == _localPeerId);
		if (exists) {
			return;
		}

		await _upsertMember(
			id: _localPeerId,
			displayName: 'You',
			wakeStatus: defaultStatus,
		);
	}

	Future<void> _upsertMember({
		required String id,
		required String displayName,
		required MemberWakeStatus wakeStatus,
	}) async {
		final index = _members.indexWhere((member) => member.id == id);
		if (index == -1) {
			_members = [
				..._members,
				CircleMember(
					id: id,
					displayName: displayName,
					joinedAt: DateTime.now(),
					wakeStatus: wakeStatus,
				),
			];
			await _persistMembers();
			return;
		}

		final updatedMembers = [..._members];
		updatedMembers[index] = updatedMembers[index].copyWith(
			displayName: displayName,
			wakeStatus: wakeStatus,
		);
		_members = updatedMembers;
		await _persistMembers();
	}

	Future<void> _setAllMembersStatus(MemberWakeStatus status) async {
		_members = _members.map((member) => member.copyWith(wakeStatus: status)).toList();
		await _persistMembers();
	}

	Future<void> _broadcastAwakeStatus(CircleMember member) async {
		final hostPeerId = _hostPeerIdForCurrentCircle;
		if (hostPeerId == null || hostPeerId.isEmpty) {
			return;
		}

		final envelope = MessageEnvelope(
			type: P2pMessageType.awakeStatus,
			senderId: _localPeerId,
			recipientId: hostPeerId,
			sessionNonce: _currentSessionNonce ?? _generateSessionNonce(),
			payload: {
				'circleId': activeCircleId,
				'memberId': member.id,
				'displayName': member.displayName,
				'status': member.wakeStatus.name,
			},
			timestamp: DateTime.now().toUtc(),
		);

		try {
			await _repository.sendMessage(envelope);
		} catch (_) {
			// Keep local state even if transport unavailable.
		}
	}

	Future<void> _persistMembers() async {
		final prefs = _sharedPreferences;
		if (prefs == null) {
			return;
		}

		final encodedMembers = jsonEncode(_members.map((member) => member.toMap()).toList());
		await prefs.setString(_membersStorageKey, encodedMembers);
		_membersChangedController.add(null);
	}

	Future<void> _persistActiveWakeEvent() async {
		final prefs = _sharedPreferences;
		if (prefs == null) {
			return;
		}

		final wakeEvent = _activeWakeEvent;
		if (wakeEvent == null) {
			await prefs.remove(_activeWakeEventStorageKey);
			return;
		}

		await prefs.setString(_activeWakeEventStorageKey, jsonEncode(wakeEvent.toMap()));
	}

	String _generateSessionNonce() {
		return DateTime.now().microsecondsSinceEpoch.toString();
	}

	String _generateCircleId() {
		const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
		final timestamp = DateTime.now().millisecondsSinceEpoch;
		final seed = timestamp.toRadixString(36).toUpperCase();
		final suffix = seed.length >= 6 ? seed.substring(seed.length - 6) : seed;

		final buffer = StringBuffer();
		for (var i = 0; i < 6; i++) {
			if (i < suffix.length && chars.contains(suffix[i])) {
				buffer.write(suffix[i]);
			} else {
				buffer.write(chars[(timestamp + i * 7) % chars.length]);
			}
		}
		return buffer.toString();
	}

	String _labelForStatus(MemberWakeStatus status) {
		switch (status) {
			case MemberWakeStatus.awake:
				return 'Awake';
			case MemberWakeStatus.notYetAwake:
				return 'Not yet awake';
			case MemberWakeStatus.unreachable:
				return 'Unreachable';
		}
	}

	@override
	void dispose() {
		_scanTimeoutTimer?.cancel();
		unawaited(_eventsSubscription?.cancel());
		unawaited(_repository.dispose());
		unawaited(_membersChangedController.close());
		super.dispose();
	}
}
