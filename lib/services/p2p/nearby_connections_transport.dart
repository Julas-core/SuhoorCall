import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nearby_connections/nearby_connections.dart' as nearby;

import '../../core/p2p_contracts.dart';

/// Production P2P transport using Google Nearby Connections SDK.
///
/// Replaces the timer-based mock. Requires Bluetooth + Wi-Fi permissions
/// (already declared in AndroidManifest.xml) and works on Android only.
///
/// Discovery strategy: [nearby.Strategy.P2P_CLUSTER] so multiple devices can
/// join the same circle without needing a Wi-Fi AP.
class NearbyConnectionsTransport implements P2pTransport {
  static const String _serviceId = 'com.suhoor.wakecircle';
  static const nearby.Strategy _strategy = nearby.Strategy.P2P_CLUSTER;

  final StreamController<P2pTransportEvent> _eventsController =
      StreamController<P2pTransportEvent>.broadcast();

  bool _isDiscovering = false;
  String? _localEndpointId;

  // peerId → endpointId mapping so we can address messages correctly.
  final Map<String, String> _peerToEndpoint = {};
  final Map<String, String> _endpointToPeer = {};

  @override
  Stream<P2pTransportEvent> get events => _eventsController.stream;

  // ── Discovery ─────────────────────────────────────────────────────────────

  @override
  Future<void> startDiscovery({String? targetPeerId}) async {
    if (_isDiscovering) return;
    _isDiscovering = true;

    _eventsController.add(
      const P2pTransportEvent(type: P2pTransportEventType.discoveryStarted),
    );

    try {
      await nearby.Nearby().startDiscovery(
        // Use the local peer id as the user name (injected by service later;
        // for discovery purposes the name is not critical).
        'suhoor-joiner',
        _strategy,
        onEndpointFound: (endpointId, endpointName, serviceId) {
          // endpointName carries the advertiser's display name.
          // We treat endpointName as the peer's displayName; the true peerId
          // is exchanged during handshake.
          final peer = P2pPeer(id: endpointId, displayName: endpointName);
          _eventsController.add(
            P2pTransportEvent(
              type: P2pTransportEventType.peerDiscovered,
              peer: peer,
            ),
          );
        },
        onEndpointLost: (endpointId) {
          if (endpointId == null) return;
          final peerId = _endpointToPeer[endpointId];
          if (peerId != null) {
            _eventsController.add(
              P2pTransportEvent(
                type: P2pTransportEventType.disconnected,
                peer: P2pPeer(id: peerId, displayName: peerId),
              ),
            );
          }
        },
        serviceId: _serviceId,
      );
    } catch (e) {
      _isDiscovering = false;
      _eventsController.add(
        P2pTransportEvent(
          type: P2pTransportEventType.error,
          errorMessage: 'Discovery failed: $e',
        ),
      );
    }
  }

  @override
  Future<void> stopDiscovery() async {
    if (!_isDiscovering) return;
    _isDiscovering = false;
    await nearby.Nearby().stopDiscovery();
  }

  // ── Connections ───────────────────────────────────────────────────────────

  @override
  Future<void> connectToPeer(P2pPeer peer) async {
    // `peer.id` here is the endpointId returned by onEndpointFound.
    final endpointId = peer.id;

    try {
      await nearby.Nearby().requestConnection(
        'suhoor-joiner',
        endpointId,
        onConnectionInitiated: (endpointId, connectionInfo) async {
          // Accept all incoming connections (handshake validation happens
          // at the application layer via SessionNonceHandshakeVerifier).
          await nearby.Nearby().acceptConnection(
            endpointId,
            onPayLoadRecieved: (endpointId, payload) =>
                _handlePayload(endpointId, payload),
            onPayloadTransferUpdate: (_, __) {},
          );
        },
        onConnectionResult: (endpointId, status) {
          if (status == nearby.Status.CONNECTED) {
            // Use the endpointId as both keys until proper handshake resolves
            // the true peerId.
            _peerToEndpoint[endpointId] = endpointId;
            _endpointToPeer[endpointId] = endpointId;

            _eventsController.add(
              P2pTransportEvent(
                type: P2pTransportEventType.connected,
                peer: P2pPeer(id: endpointId, displayName: peer.displayName),
              ),
            );
          } else {
            _eventsController.add(
              P2pTransportEvent(
                type: P2pTransportEventType.error,
                errorMessage: 'Connection to ${peer.displayName} failed: $status',
              ),
            );
          }
        },
        onDisconnected: (endpointId) {
          final peerId = _endpointToPeer.remove(endpointId) ?? endpointId;
          _peerToEndpoint.remove(peerId);
          _eventsController.add(
            P2pTransportEvent(
              type: P2pTransportEventType.disconnected,
              peer: P2pPeer(id: peerId, displayName: peerId),
            ),
          );
        },
      );
    } catch (e) {
      _eventsController.add(
        P2pTransportEvent(
          type: P2pTransportEventType.error,
          errorMessage: 'Connect failed: $e',
        ),
      );
    }
  }

  @override
  Future<void> disconnectFromPeer(String peerId) async {
    final endpointId = _peerToEndpoint[peerId] ?? peerId;
    await nearby.Nearby().disconnectFromEndpoint(endpointId);
    _peerToEndpoint.remove(peerId);
    _endpointToPeer.remove(endpointId);
  }

  // ── Messaging ─────────────────────────────────────────────────────────────

  @override
  Future<void> sendMessage(MessageEnvelope envelope) async {
    final recipientId = envelope.recipientId;
    final endpointIds = recipientId != null
        ? [_peerToEndpoint[recipientId] ?? recipientId]
        : _peerToEndpoint.values.toList();

    if (endpointIds.isEmpty) {
      throw StateError('No connected endpoints to send message to.');
    }

    final bytes = Uint8List.fromList(
      utf8.encode(jsonEncode(envelope.toMap())),
    );

    for (final endpointId in endpointIds) {
      await nearby.Nearby().sendBytesPayload(endpointId, bytes);
    }
  }

  void _handlePayload(
    String endpointId,
    nearby.Payload payload,
  ) {
    if (payload.type != nearby.PayloadType.BYTES) return;
    final bytes = payload.bytes;
    if (bytes == null) return;

    try {
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map<String, dynamic>) return;
      final envelope = MessageEnvelope.fromMap(json);
      _eventsController.add(
        P2pTransportEvent(
          type: P2pTransportEventType.messageReceived,
          message: envelope,
        ),
      );
    } catch (_) {
      // Malformed payload — ignore.
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  Future<void> dispose() async {
    _isDiscovering = false;
    await nearby.Nearby().stopDiscovery();
    await nearby.Nearby().stopAllEndpoints();
    if (!_eventsController.isClosed) {
      await _eventsController.close();
    }
  }
}
