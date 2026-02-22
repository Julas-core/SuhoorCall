import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/circle_models.dart' as core;
import '../../services/circle/wake_circle_service.dart';

typedef SquadMember = core.CircleMember;
typedef MemberWakeStatus = core.MemberWakeStatus;

class JoinSquadViewModel extends ChangeNotifier {
  final WakeCircleService _service;
  VoidCallback? _serviceListener;

  JoinSquadViewModel({WakeCircleService? service})
    : _service = service ?? WakeCircleService() {
    _serviceListener = () => notifyListeners();
    _service.addListener(_serviceListener!);
    unawaited(_service.ensureInitialized());
  }

  static Stream<void> get membersChanged => WakeCircleService().membersChanged;

  List<SquadMember> get members => _service.members;
  bool get isScanning => _service.isScanning;
  bool get isGeneratingQr => _service.isGeneratingQr;
  String? get hostInvitationPayload => _service.hostInvitationPayload;
  String? get hostCircleId => _service.hostCircleId;
  String? get joinedCircleId => _service.joinedCircleId;
  String? get activeCircleId => _service.activeCircleId;
  String get localPeerId => _service.localPeerId;
  int get joinedMembersCount => _service.members.length;
  String get statusMessage => _service.statusMessage;

  int get awakeCount => _service.awakeCount;
  int get notYetAwakeCount => _service.notYetAwakeCount;
  int get unreachableCount => _service.unreachableCount;

  Future<String> createCircleAndBuildInvitation({
    String hostDisplayName = 'Circle Host',
  }) {
    return _service.createCircleAndBuildInvitation(
      hostDisplayName: hostDisplayName,
    );
  }

  static String buildSampleQrPayload() {
    return WakeCircleService.buildSampleQrPayload();
  }

  Future<void> scanToJoin(String qrPayloadRaw) {
    return _service.scanToJoin(qrPayloadRaw);
  }

  Future<void> addSquadMemberManually(String displayName) {
    return _service.addSquadMemberManually(displayName);
  }

  Future<void> setMemberWakeStatus(String memberId, MemberWakeStatus status) {
    return _service.setMemberWakeStatus(memberId, status);
  }

  Future<void> startWakeEvent() {
    return _service.startWakeEvent();
  }

  Future<void> markCurrentDeviceAwake() {
    return _service.markCurrentDeviceAwake();
  }

  static Future<void> markCurrentDeviceAwakePersisted() {
    return WakeCircleService().markCurrentDeviceAwake();
  }

  static Future<void> startWakeEventPersisted() {
    return WakeCircleService().startWakeEvent();
  }

  @override
  void dispose() {
    final listener = _serviceListener;
    if (listener != null) {
      _service.removeListener(listener);
    }
    _serviceListener = null;
    super.dispose();
  }
}
