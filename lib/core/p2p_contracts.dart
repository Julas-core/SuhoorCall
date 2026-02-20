import 'dart:async';
import 'dart:convert';

enum P2pConnectionState {
  idle,
  discovering,
  connecting,
  connected,
  disconnected,
  error,
}

enum P2pMessageType {
  handshakeRequest,
  handshakeResponse,
  awakeStatus,
  joinRequest,
  joinResponse,
  heartbeat,
}

enum P2pTransportEventType {
  discoveryStarted,
  peerDiscovered,
  connected,
  disconnected,
  messageReceived,
  error,
}

class MessageEnvelope {
  final P2pMessageType type;
  final String senderId;
  final String? recipientId;
  final String sessionNonce;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  const MessageEnvelope({
    required this.type,
    required this.senderId,
    required this.recipientId,
    required this.sessionNonce,
    required this.payload,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'senderId': senderId,
      'recipientId': recipientId,
      'sessionNonce': sessionNonce,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MessageEnvelope.fromMap(Map<String, dynamic> map) {
    return MessageEnvelope(
      type: P2pMessageType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => P2pMessageType.heartbeat,
      ),
      senderId: map['senderId'] as String,
      recipientId: map['recipientId'] as String?,
      sessionNonce: map['sessionNonce'] as String,
      payload: Map<String, dynamic>.from(map['payload'] as Map),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

class HandshakePayload {
  final String handshakeString;
  final String peerId;
  final String sessionNonce;
  final int protocolVersion;
  final DateTime timestamp;

  const HandshakePayload({
    required this.handshakeString,
    required this.peerId,
    required this.sessionNonce,
    required this.protocolVersion,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'handshakeString': handshakeString,
      'peerId': peerId,
      'sessionNonce': sessionNonce,
      'protocolVersion': protocolVersion,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory HandshakePayload.fromMap(Map<String, dynamic> map) {
    return HandshakePayload(
      handshakeString: map['handshakeString'] as String,
      peerId: map['peerId'] as String,
      sessionNonce: map['sessionNonce'] as String,
      protocolVersion: map['protocolVersion'] as int,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

class JoinQrPayload {
  final String? circleId;
  final String peerId;
  final String peerDisplayName;
  final String sessionNonce;
  final String handshakeString;
  final int protocolVersion;
  final DateTime timestamp;

  const JoinQrPayload({
    this.circleId,
    required this.peerId,
    required this.peerDisplayName,
    required this.sessionNonce,
    required this.handshakeString,
    required this.protocolVersion,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'circleId': circleId,
      'peerId': peerId,
      'peerDisplayName': peerDisplayName,
      'sessionNonce': sessionNonce,
      'handshakeString': handshakeString,
      'protocolVersion': protocolVersion,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  String toEncodedString() {
    return jsonEncode(toMap());
  }

  factory JoinQrPayload.fromEncodedString(String encodedPayload) {
    final decoded = jsonDecode(encodedPayload);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid QR payload format.');
    }

    return JoinQrPayload(
      circleId: decoded['circleId'] as String?,
      peerId: decoded['peerId'] as String,
      peerDisplayName: decoded['peerDisplayName'] as String,
      sessionNonce: decoded['sessionNonce'] as String,
      handshakeString: decoded['handshakeString'] as String,
      protocolVersion: decoded['protocolVersion'] as int,
      timestamp: DateTime.parse(decoded['timestamp'] as String),
    );
  }
}

class P2pPeer {
  final String id;
  final String displayName;

  const P2pPeer({required this.id, required this.displayName});
}

class P2pTransportEvent {
  final P2pTransportEventType type;
  final P2pPeer? peer;
  final MessageEnvelope? message;
  final String? errorMessage;

  const P2pTransportEvent({
    required this.type,
    this.peer,
    this.message,
    this.errorMessage,
  });
}

abstract class P2pTransport {
  Stream<P2pTransportEvent> get events;
  Future<void> startDiscovery({String? targetPeerId});
  Future<void> stopDiscovery();
  Future<void> connectToPeer(P2pPeer peer);
  Future<void> disconnectFromPeer(String peerId);
  Future<void> sendMessage(MessageEnvelope envelope);
  Future<void> dispose();
}

abstract class HandshakeVerifier {
  bool verify(HandshakePayload payload, String expectedSessionNonce);
}

class SessionNonceHandshakeVerifier implements HandshakeVerifier {
  final String expectedHandshakeString;
  final int expectedProtocolVersion;
  final Duration maxClockDrift;

  const SessionNonceHandshakeVerifier({
    required this.expectedHandshakeString,
    required this.expectedProtocolVersion,
    this.maxClockDrift = const Duration(minutes: 2),
  });

  @override
  bool verify(HandshakePayload payload, String expectedSessionNonce) {
    final now = DateTime.now().toUtc();
    final payloadTime = payload.timestamp.toUtc();
    final drift = now.difference(payloadTime).abs();

    return payload.handshakeString == expectedHandshakeString &&
        payload.protocolVersion == expectedProtocolVersion &&
        payload.sessionNonce == expectedSessionNonce &&
        drift <= maxClockDrift;
  }
}

abstract class P2pRepository {
  Stream<P2pTransportEvent> get events;
  Future<void> startDiscovery({String? targetPeerId});
  Future<void> stopDiscovery();
  Future<void> connectToPeer(P2pPeer peer);
  Future<void> disconnectFromPeer(String peerId);
  Future<void> sendMessage(MessageEnvelope envelope);
  Future<bool> verifyHandshake(
    HandshakePayload payload,
    String expectedSessionNonce,
  );
  Future<void> dispose();
}
