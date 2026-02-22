import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/circle_models.dart';
import '../../services/circle/wake_circle_service.dart';

class Friend {
  final String name;
  final MemberWakeStatus wakeStatus;
  final String imageUrl;

  Friend({
    required this.name,
    required this.wakeStatus,
    required this.imageUrl,
  });

  bool get isAwake => wakeStatus == MemberWakeStatus.awake;
}

class DashboardViewModel extends ChangeNotifier {
  final WakeCircleService _service;
  VoidCallback? _serviceListener;

  DashboardViewModel({WakeCircleService? service})
    : _service = service ?? WakeCircleService() {
    _serviceListener = () => notifyListeners();
    _service.addListener(_serviceListener!);
    unawaited(_service.ensureInitialized());
  }

  bool get isUserAwake => _service.isCurrentUserAwake;

  List<Friend> get friends {
    final localPeerId = _service.localPeerId;

    return _service.members
        .where((member) => localPeerId.isEmpty || member.id != localPeerId)
        .map(
          (member) => Friend(
            name: member.displayName,
            wakeStatus: member.wakeStatus,
            imageUrl: '',
          ),
        )
        .toList();
  }

  void toggleAwakeStatus() {
    if (isUserAwake) {
      return;
    }
    unawaited(_service.markCurrentDeviceAwake());
  }

  Future<void> wakeEveryone() {
    return _service.startWakeEvent();
  }

  void markAsAwake() {
    unawaited(_service.markCurrentDeviceAwake());
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
