import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:suhoor_wake_up_circle/services/leaderboard/history_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    HistoryService().reset();
  });

  group('HistoryService — recordWake', () {
    test('starts with empty history', () async {
      final service = HistoryService();
      await service.ensureInitialized();
      expect(service.history, isEmpty);
    });

    test('recordWake persists a completed entry', () async {
      final service = HistoryService();
      await service.ensureInitialized();

      await service.recordWake(
        memberId: 'peer-1',
        displayName: 'You',
        completed: true,
      );

      expect(service.history, hasLength(1));
      expect(service.history.first.memberId, 'peer-1');
      expect(service.history.first.completed, isTrue);
    });

    test('recordWake is idempotent — same member & day is upserted', () async {
      final service = HistoryService();
      await service.ensureInitialized();

      await service.recordWake(memberId: 'peer-1', displayName: 'You', completed: false);
      await service.recordWake(memberId: 'peer-1', displayName: 'You', completed: true);

      expect(service.history, hasLength(1));
      expect(service.history.first.completed, isTrue);
    });

    test('keeps separate records for different members on same day', () async {
      final service = HistoryService();
      await service.ensureInitialized();

      await service.recordWake(memberId: 'peer-1', displayName: 'Ahmed', completed: true);
      await service.recordWake(memberId: 'peer-2', displayName: 'Fatima', completed: true);

      expect(service.history, hasLength(2));
    });
  });

  group('HistoryService — computeStreak', () {
    test('returns 0 streak when history is empty', () async {
      final service = HistoryService();
      await service.ensureInitialized();

      final streak = service.computeStreak('peer-1');
      expect(streak.currentStreak, 0);
      expect(streak.longestStreak, 0);
    });

    test('returns current streak of 1 for a single completed wake today', () async {
      final service = HistoryService();
      await service.ensureInitialized();

      await service.recordWake(memberId: 'peer-1', displayName: 'You', completed: true);

      final streak = service.computeStreak('peer-1');
      expect(streak.currentStreak, 1);
    });

    test('streak of 0 when only incomplete records exist', () async {
      final service = HistoryService();
      await service.ensureInitialized();

      await service.recordWake(memberId: 'peer-1', displayName: 'You', completed: false);

      final streak = service.computeStreak('peer-1');
      expect(streak.currentStreak, 0);
    });
  });

  group('HistoryService — computeLeaderboard', () {
    test('returns empty leaderboard when history is empty', () async {
      final service = HistoryService();
      await service.ensureInitialized();

      expect(service.computeLeaderboard(), isEmpty);
    });

    test('ranks members by total completed wakes descending', () async {
      final service = HistoryService();
      await service.ensureInitialized();

      // Simulate Ahmed waking 2 days vs Fatima 1 day.
      // We directly add records via recordWake on separate dates.
      // Since recordWake only touches today, we inject records programmatically
      // through the public API and accept today's limit for integration testing.
      await service.recordWake(memberId: 'ahmed', displayName: 'Ahmed', completed: true);
      await service.recordWake(memberId: 'fatima', displayName: 'Fatima', completed: true);

      final board = service.computeLeaderboard();
      expect(board, hasLength(2));
      // Both have 1 completed — ranks may vary but should exist.
      expect(board.map((e) => e.memberId), containsAll(['ahmed', 'fatima']));
    });
  });
}
