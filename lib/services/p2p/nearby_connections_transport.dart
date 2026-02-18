import 'dart:async';

import '../../core/p2p_contracts.dart';

class NearbyConnectionsTransport implements P2pTransport {
  final StreamController<P2pTransportEvent> _eventsController =
      StreamController<P2pTransportEvent>.broadcast();

  bool _isDiscovering = false;

  @override
  Stream<P2pTransportEvent> get events => _eventsController.stream;

  @override
  Future<void> startDiscovery() async {
    _isDiscovering = true;
    _eventsController.add(
      const P2pTransportEvent(type: P2pTransportEventType.discoveryStarted),
    );
  }

  @override
  Future<void> stopDiscovery() async {
    _isDiscovering = false;
  }

  @override
  Future<void> connectToPeer(P2pPeer peer) async {
    if (!_isDiscovering) {
      throw StateError(
        'Discovery must be started before connecting to a peer.',
      );
    }

    _eventsController.add(
      P2pTransportEvent(type: P2pTransportEventType.connected, peer: peer),
    );
  }

  @override
  Future<void> disconnectFromPeer(String peerId) async {
    _eventsController.add(
      P2pTransportEvent(
        type: P2pTransportEventType.disconnected,
        peer: P2pPeer(id: peerId, displayName: peerId),
      ),
    );
  }

  @override
  Future<void> sendMessage(MessageEnvelope envelope) async {
    _eventsController.add(
      P2pTransportEvent(
        type: P2pTransportEventType.messageReceived,
        message: envelope,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    await _eventsController.close();
  }
}
