import '../../core/p2p_contracts.dart';
import 'hybrid_p2p_repository.dart';
import 'nearby_connections_transport.dart';
import 'wifi_p2p_connection_transport.dart';

class P2pRepositoryFactory {
  const P2pRepositoryFactory._();

  static const String handshakeString = 'SUHOOR_CIRCLE_HANDSHAKE_V1';
  static const int protocolVersion = 1;

  static P2pRepository createHybridRepository() {
    return HybridP2pRepository(
      primaryTransport: NearbyConnectionsTransport(),
      fallbackTransport: WifiP2pConnectionTransport(),
      handshakeVerifier: const SessionNonceHandshakeVerifier(
        expectedHandshakeString: handshakeString,
        expectedProtocolVersion: protocolVersion,
      ),
    );
  }
}
