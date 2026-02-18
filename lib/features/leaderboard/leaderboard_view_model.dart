import 'package:flutter/material.dart';

class LeaderboardEntry {
  final int rank;
  final String name;
  final int score; // Points or current score
  final String streak;
  final bool isNudged;
  final bool isCompleted; // If they are already awake/done for the day
  final String avatarUrl; // Mock, using first letter or icon for now

  LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.score,
    required this.streak,
    this.isNudged = false,
    this.isCompleted = false,
    required this.avatarUrl,
  });
}

class LeaderboardViewModel extends ChangeNotifier {
  String _selectedPeriod = 'This Week';
  String get selectedPeriod => _selectedPeriod;

  // Mock Data matching the screenshot
  List<LeaderboardEntry> _entries = [
    LeaderboardEntry(
      rank: 1,
      name: 'Yusuf',
      score: 24,
      streak: '18 Day Streak',
      avatarUrl: 'Y',
      isCompleted: true,
    ),
    LeaderboardEntry(
      rank: 2,
      name: 'Sarah',
      score: 21,
      streak: '15 Day Streak',
      avatarUrl: 'S',
      isCompleted: false,
    ),
    LeaderboardEntry(
      rank: 3,
      name: 'Ahmed',
      score: 18,
      streak: '12 Day Streak',
      avatarUrl: 'A',
      isCompleted: false,
    ),
    LeaderboardEntry(
      rank: 4,
      name: 'Fatima Zahra',
      score: 15,
      streak: '12 Day Streak',
      avatarUrl: 'F',
      isCompleted: false,
    ),
    LeaderboardEntry(
      rank: 5,
      name: 'Omar K.',
      score: 12,
      streak: '8 Day Streak',
      avatarUrl: 'O',
      isCompleted: true,
    ), // Checkmark in screenshot
    LeaderboardEntry(
      rank: 6,
      name: 'Bilal S.',
      score: 9,
      streak: '3 Day Streak',
      avatarUrl: 'B',
      isCompleted: false,
    ),
    LeaderboardEntry(
      rank: 7,
      name: 'Zainab',
      score: 6,
      streak: '1 Day Streak',
      avatarUrl: 'Z',
      isCompleted: false,
    ),
  ];

  List<LeaderboardEntry> get topThree => _entries.take(3).toList();
  List<LeaderboardEntry> get restList => _entries.skip(3).toList();

  void setPeriod(String period) {
    _selectedPeriod = period;
    // simulating data refresh or filter change if needed
    notifyListeners();
  }

  void nudgeUser(int rank) {
    // In a real app, this would send a P2P message or notification
    final index = _entries.indexWhere((e) => e.rank == rank);
    if (index != -1) {
      final entry = _entries[index];
      // Toggle nudged state locally to show UI feedback
      _entries[index] = LeaderboardEntry(
        rank: entry.rank,
        name: entry.name,
        score: entry.score,
        streak: entry.streak,
        isNudged: true,
        isCompleted: entry.isCompleted,
        avatarUrl: entry.avatarUrl,
      );
      notifyListeners();
    }
  }
}
