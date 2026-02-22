import 'package:flutter/material.dart';

import '../../services/leaderboard/history_service.dart';

export '../../services/leaderboard/history_service.dart'
    show LeaderboardEntry, StreakInfo;

class LeaderboardViewModel extends ChangeNotifier {
  final HistoryService _historyService;
  VoidCallback? _historyListener;

  String _selectedPeriod = 'This Week';
  String get selectedPeriod => _selectedPeriod;

  LeaderboardViewModel({HistoryService? historyService})
    : _historyService = historyService ?? HistoryService() {
    _historyListener = () => notifyListeners();
    _historyService.addListener(_historyListener!);
    // Make sure history is loaded before first render.
    _historyService.ensureInitialized().then((_) => notifyListeners());
  }

  List<LeaderboardEntry> get allEntries => _historyService.computeLeaderboard();

  List<LeaderboardEntry> get topThree => allEntries.take(3).toList();
  List<LeaderboardEntry> get restList => allEntries.skip(3).toList();

  /// How many days back to consider for "This Week" / "This Month".
  int get _periodDays {
    switch (_selectedPeriod) {
      case 'This Month':
        return 30;
      case 'All Time':
        return 99999;
      case 'This Week':
      default:
        return 7;
    }
  }

  /// Returns leaderboard entries filtered to [_periodDays] days.
  List<LeaderboardEntry> get filteredEntries {
    final cutoff = DateTime.now().toUtc().subtract(Duration(days: _periodDays));
    final filtered = _historyService.history
        .where(
          (record) =>
              record.completed &&
              record.date.isAfter(cutoff),
        )
        .toList();

    // Group by memberId
    final memberMap = <String, ({String displayName, int completed})>{};
    for (final record in filtered) {
      final existing = memberMap[record.memberId];
      if (existing == null) {
        memberMap[record.memberId] = (
          displayName: record.displayName,
          completed: 1,
        );
      } else {
        memberMap[record.memberId] = (
          displayName: existing.displayName,
          completed: existing.completed + 1,
        );
      }
    }

    final sorted = memberMap.entries.toList()
      ..sort((a, b) => b.value.completed.compareTo(a.value.completed));

    return sorted.indexed.map((entry) {
      final rank = entry.$1 + 1;
      final memberId = entry.$2.key;
      final data = entry.$2.value;
      return LeaderboardEntry(
        rank: rank,
        memberId: memberId,
        displayName: data.displayName,
        totalCompleted: data.completed,
        streak: _historyService.computeStreak(memberId),
      );
    }).toList();
  }

  bool get hasHistory => _historyService.history.isNotEmpty;

  void setPeriod(String period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  @override
  void dispose() {
    final listener = _historyListener;
    if (listener != null) {
      _historyService.removeListener(listener);
    }
    _historyListener = null;
    super.dispose();
  }
}
