import 'dart:async';

import '../../core/p2p_contracts.dart';

class HybridP2pRepository implements P2pRepository {
  final P2pTransport primaryTransport;
  final P2pTransport fallbackTransport;
  final HandshakeVerifier handshakeVerifier;

  final StreamController<P2pTransportEvent> _eventsController =
      StreamController<P2pTransportEvent>.broadcast();

  StreamSubscription<P2pTransportEvent>? _primarySubscription;
  StreamSubscription<P2pTransportEvent>? _fallbackSubscription;

  P2pTransport? _activeTransport;

  HybridP2pRepository({
    required this.primaryTransport,
    required this.fallbackTransport,
    required this.handshakeVerifier,
  }) {
    _activeTransport = primaryTransport;
    _primarySubscription = primaryTransport.events.listen(
      _eventsController.add,
    );
    _fallbackSubscription = fallbackTransport.events.listen(
      _eventsController.add,
    );
  }

  @override
  Stream<P2pTransportEvent> get events => _eventsController.stream;

  @override
  Future<void> startDiscovery() async {
    await _withFallback(
      primaryAction: () => primaryTransport.startDiscovery(),
      fallbackAction: () => fallbackTransport.startDiscovery(),
    );
  }

  @override
  Future<void> stopDiscovery() async {
    final transport = _activeTransport;
    if (transport == null) {
      return;
    }
    await transport.stopDiscovery();
  }

  @override
  Future<void> connectToPeer(P2pPeer peer) async {
    await _withFallback(
      primaryAction: () => primaryTransport.connectToPeer(peer),
      fallbackAction: () => fallbackTransport.connectToPeer(peer),
    );
  }

  @override
  Future<void> disconnectFromPeer(String peerId) async {
    final transport = _activeTransport;
    if (transport == null) {
      return;
    }
    await transport.disconnectFromPeer(peerId);
  }

  @override
  Future<void> sendMessage(MessageEnvelope envelope) async {
    final transport = _activeTransport;
    if (transport == null) {
      throw StateError('No active transport available.');
    }

    try {
      await transport.sendMessage(envelope);
    } catch (_) {
      if (transport == fallbackTransport) {
        rethrow;
      }
      _activeTransport = fallbackTransport;
      await fallbackTransport.sendMessage(envelope);
    }
  }

  @override
  Future<bool> verifyHandshake(
    HandshakePayload payload,
    String expectedSessionNonce,
  ) async {
    return handshakeVerifier.verify(payload, expectedSessionNonce);
  }

  @override
  Future<void> dispose() async {
    await _primarySubscription?.cancel();
    await _fallbackSubscription?.cancel();
    await primaryTransport.dispose();
    await fallbackTransport.dispose();
    await _eventsController.close();
  }

  Future<void> _withFallback({
    required Future<void> Function() primaryAction,
    required Future<void> Function() fallbackAction,
  }) async {
    try {
      await primaryAction();
      _activeTransport = primaryTransport;
    } catch (_) {
      await fallbackAction();
      _activeTransport = fallbackTransport;
    }
  }
}
