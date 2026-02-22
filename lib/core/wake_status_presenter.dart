import 'package:flutter/material.dart';

import 'circle_models.dart';

class WakeStatusPresentation {
  final String label;
  final Color color;
  final IconData icon;

  const WakeStatusPresentation({
    required this.label,
    required this.color,
    required this.icon,
  });
}

class WakeStatusPresenter {
  const WakeStatusPresenter._();

  static WakeStatusPresentation present(MemberWakeStatus status) {
    switch (status) {
      case MemberWakeStatus.awake:
        return const WakeStatusPresentation(
          label: 'Awake',
          color: Color(0xFF00F58D),
          icon: Icons.check_circle,
        );
      case MemberWakeStatus.notYetAwake:
        return const WakeStatusPresentation(
          label: 'Not yet awake',
          color: Color(0xFFFFC857),
          icon: Icons.bedtime,
        );
      case MemberWakeStatus.unreachable:
        return const WakeStatusPresentation(
          label: 'Unreachable',
          color: Color(0xFFE94560),
          icon: Icons.signal_wifi_off,
        );
    }
  }
}
