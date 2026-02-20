import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../leaderboard/join_squad_view_model.dart';

class Friend {
  final String name;
  final bool isAwake;
  final String imageUrl; // Mock image URL or asset path

  Friend({required this.name, required this.isAwake, required this.imageUrl});
}

class DashboardViewModel extends ChangeNotifier {
  static const String _squadMembersStorageKey = 'squad_members_v1';
  static const String _localPeerIdStorageKey = 'local_peer_id_v1';

  SharedPreferences? _prefs;
  StreamSubscription<void>? _membersChangedSubscription;

  bool _isUserAwake = false;
  bool get isUserAwake => _isUserAwake;

  List<Friend> _friends = [];

  DashboardViewModel() {
    _membersChangedSubscription = JoinSquadViewModel.membersChanged.listen((_) {
      unawaited(_reloadFromStorage());
    });
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _reloadFromStorage();
  }

  Future<void> _reloadFromStorage() async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }

    final rawMembers = prefs.getString(_squadMembersStorageKey);
    final localPeerId = prefs.getString(_localPeerIdStorageKey);

    if (rawMembers == null || rawMembers.isEmpty) {
      _friends = [];
      notifyListeners();
      return;
    }

    final members = (jsonDecode(rawMembers) as List<dynamic>)
        .map(
          (entry) =>
              SquadMember.fromMap(Map<String, dynamic>.from(entry as Map)),
        )
        .toList();

    SquadMember? me;
    if (localPeerId != null) {
      for (final member in members) {
        if (member.id == localPeerId) {
          me = member;
          break;
        }
      }
    }

    if (me != null) {
      _isUserAwake = me.wakeStatus == MemberWakeStatus.awake;
    }

    _friends = members
        .where((member) => localPeerId == null || member.id != localPeerId)
        .map(
          (member) => Friend(
            name: member.displayName,
            isAwake: member.wakeStatus == MemberWakeStatus.awake,
            imageUrl: '',
          ),
        )
        .toList();

    notifyListeners();
  }

  void toggleAwakeStatus() {
    _isUserAwake = !_isUserAwake;
    notifyListeners();
  }

  Future<void> wakeEveryone() async {
    await JoinSquadViewModel.startWakeEventPersisted();
    await _reloadFromStorage();
  }

  void markAsAwake() {
    _isUserAwake = true;
    notifyListeners();
  }

  List<Friend> get friends => _friends;

  @override
  void dispose() {
    _membersChangedSubscription?.cancel();
    super.dispose();
  }
}
