import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/circle_models.dart';

/// Computed streak values for a single member.
class StreakInfo {
	final int currentStreak;
	final int longestStreak;

	const StreakInfo({required this.currentStreak, required this.longestStreak});
}

/// Leaderboard entry built from real history data.
class LeaderboardEntry {
	final int rank;
	final String memberId;
	final String displayName;
	final int totalCompleted;
	final StreakInfo streak;

	const LeaderboardEntry({
		required this.rank,
		required this.memberId,
		required this.displayName,
		required this.totalCompleted,
		required this.streak,
	});
}

/// Service that persists wake history records and computes streaks/leaderboard.
///
/// Singleton, safe to call before [ensureInitialized] — the data will be loaded
/// lazily on the first async call.
class HistoryService extends ChangeNotifier {
	static final HistoryService _instance = HistoryService._internal();
	factory HistoryService() => _instance;
	HistoryService._internal();

	static const String _historyStorageKey = 'wake_history_v1';

	SharedPreferences? _prefs;
	List<WakeHistoryRecord> _history = [];
	bool _isInitialized = false;

	List<WakeHistoryRecord> get history => List.unmodifiable(_history);

	// ── Initialization ──────────────────────────────────────────────────────

	Future<void> ensureInitialized() async {
		if (_isInitialized) return;
		_prefs = await SharedPreferences.getInstance();
		_loadHistory();
		_isInitialized = true;
	}

  /// Resets singleton state. Use only in tests.
  @visibleForTesting
  void reset() {
    _history = [];
    _prefs = null;
    _isInitialized = false;
  }

	void _loadHistory() {
		final raw = _prefs?.getString(_historyStorageKey);
		if (raw == null || raw.isEmpty) {
			_history = [];
			return;
		}
		try {
			final list = jsonDecode(raw) as List<dynamic>;
			_history = list
					.map(
						(item) =>
								WakeHistoryRecord.fromMap(Map<String, dynamic>.from(item as Map)),
					)
					.toList();
		} catch (_) {
			_history = [];
		}
	}

	// ── Writing ─────────────────────────────────────────────────────────────

	/// Records a wake outcome for [memberId]. Replaces any existing record for
	/// the same member on the same calendar day so repeated calls are idempotent.
	Future<void> recordWake({
		required String memberId,
		required String displayName,
		required bool completed,
		DateTime? completionTime,
	}) async {
		await ensureInitialized();

		final today = _normalizeDate(DateTime.now().toUtc());

		// Remove any stale record for this member on today (idempotent upsert).
		_history = _history
				.where(
					(record) =>
							!(record.memberId == memberId &&
									_normalizeDate(record.date) == today),
				)
				.toList();

		_history = [
			..._history,
			WakeHistoryRecord(
				memberId: memberId,
				displayName: displayName,
				date: today,
				completed: completed,
				completionTime:
						completed ? (completionTime ?? DateTime.now().toUtc()) : null,
			),
		];

		await _persistHistory();
		notifyListeners();
	}

	// ── Queries ──────────────────────────────────────────────────────────────

	/// Returns all records for one member, newest first.
	List<WakeHistoryRecord> historyForMember(String memberId) {
		return _history
				.where((record) => record.memberId == memberId)
				.toList()
			..sort((a, b) => b.date.compareTo(a.date));
	}

	/// Computes streak values for a member from their history.
	///
	/// A "streak" counts consecutive calendar days ending today on which the
	/// member had a [completed] == true record. A gap of even one day resets
	/// the current streak.
	StreakInfo computeStreak(String memberId) {
		final records = historyForMember(memberId)
				.where((record) => record.completed)
				.toList()
			..sort((a, b) => b.date.compareTo(a.date)); // newest first

		if (records.isEmpty) {
			return const StreakInfo(currentStreak: 0, longestStreak: 0);
		}

		final today = _normalizeDate(DateTime.now().toUtc());

		int currentStreak = 0;
		int longestStreak = 0;
		int runningStreak = 0;
		DateTime? expectedDate;

		for (final record in records) {
			final recordDate = _normalizeDate(record.date);

			if (expectedDate == null) {
				// First record: start streak only if it's today or yesterday
				final diff = today.difference(recordDate).inDays;
				if (diff > 1) {
					// Most recent completed day is older — current streak is 0
					longestStreak = _computeLongestFrom(records);
					return StreakInfo(
						currentStreak: 0,
						longestStreak: longestStreak,
					);
				}
				runningStreak = 1;
				expectedDate = recordDate.subtract(const Duration(days: 1));
			} else if (recordDate == expectedDate) {
				runningStreak++;
				expectedDate = recordDate.subtract(const Duration(days: 1));
			} else {
				break;
			}
		}

		currentStreak = runningStreak;
		longestStreak = _computeLongestFrom(records);

		return StreakInfo(
			currentStreak: currentStreak,
			longestStreak: longestStreak > currentStreak ? longestStreak : currentStreak,
		);
	}

	/// Computes a ranked leaderboard from all persisted history.
	///
	/// Members are sorted by total completed wakes descending, then by earliest
	/// completionTime as a tiebreaker (faster = higher rank).
	List<LeaderboardEntry> computeLeaderboard() {
		if (_history.isEmpty) return [];

		// Group by memberId → pick up displayName and count completed wakes
		final memberMap = <String, ({String displayName, int completed})>{};
		for (final record in _history) {
			if (!record.completed) continue;
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

		// Sort descending by completed count
		final sorted = memberMap.entries.toList()
			..sort((a, b) => b.value.completed.compareTo(a.value.completed));

		return sorted.indexed.map(
			(entry) {
				final rank = entry.$1 + 1;
				final memberId = entry.$2.key;
				final data = entry.$2.value;
				return LeaderboardEntry(
					rank: rank,
					memberId: memberId,
					displayName: data.displayName,
					totalCompleted: data.completed,
					streak: computeStreak(memberId),
				);
			},
		).toList();
	}

	// ── Private helpers ───────────────────────────────────────────────────────

	DateTime _normalizeDate(DateTime dt) {
		return DateTime.utc(dt.year, dt.month, dt.day);
	}

	/// Walk all completed records (sorted newest-first) and find the longest run.
	int _computeLongestFrom(List<WakeHistoryRecord> sortedRecords) {
		if (sortedRecords.isEmpty) return 0;

		int longest = 1;
		int running = 1;
		for (var i = 1; i < sortedRecords.length; i++) {
			final prev = _normalizeDate(sortedRecords[i - 1].date);
			final curr = _normalizeDate(sortedRecords[i].date);
			if (prev.difference(curr).inDays == 1) {
				running++;
				if (running > longest) longest = running;
			} else {
				running = 1;
			}
		}
		return longest;
	}

	Future<void> _persistHistory() async {
		final prefs = _prefs;
		if (prefs == null) return;
		final encoded = jsonEncode(_history.map((r) => r.toMap()).toList());
		await prefs.setString(_historyStorageKey, encoded);
	}
}
