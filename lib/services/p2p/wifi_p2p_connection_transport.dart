import 'dart:async';

import '../../core/p2p_contracts.dart';

class WifiP2pConnectionTransport implements P2pTransport {
  final StreamController<P2pTransportEvent> _eventsController =
      StreamController<P2pTransportEvent>.broadcast();

  bool _isDiscovering = false;
  Timer? _discoveryTimer;
  String? _targetPeerId;

  @override
  Stream<P2pTransportEvent> get events => _eventsController.stream;

  @override
  Future<void> startDiscovery({String? targetPeerId}) async {
    _isDiscovering = true;
    _targetPeerId = targetPeerId;
    _eventsController.add(
      const P2pTransportEvent(type: P2pTransportEventType.discoveryStarted),
    );

    _discoveryTimer?.cancel();
    _discoveryTimer = Timer(const Duration(milliseconds: 900), () {
      if (!_isDiscovering || _eventsController.isClosed) {
        return;
      }

      final discoveredPeerId = _targetPeerId ?? 'wifi-peer-1';
      _eventsController.add(
        P2pTransportEvent(
          type: P2pTransportEventType.peerDiscovered,
          peer: P2pPeer(id: discoveredPeerId, displayName: 'Nearby Sister'),
        ),
      );
    });
  }

  @override
  Future<void> stopDiscovery() async {
    _isDiscovering = false;
    _targetPeerId = null;
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
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
    _discoveryTimer?.cancel();
    await _eventsController.close();
  }
}
