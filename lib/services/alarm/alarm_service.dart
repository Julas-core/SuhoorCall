import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service that manages suhoor alarm scheduling.
///
/// Singleton. Call [ensureInitialized] once at app startup (before any alarm
/// can fire). The alarm will trigger the Challenge screen via the navigator key
/// provided in [main.dart].
class AlarmService extends ChangeNotifier {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  static const int _alarmId = 1;
  static const String _prefHour = 'alarm_hour_v1';
  static const String _prefMinute = 'alarm_minute_v1';
  static const String _prefEnabled = 'alarm_enabled_v1';

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  /// Currently scheduled alarm time, or null if no alarm is set.
  TimeOfDay? _nextAlarmTime;
  TimeOfDay? get nextAlarmTime => _nextAlarmTime;
  bool get hasAlarm => _nextAlarmTime != null;

  // ── Initialization ──────────────────────────────────────────────────────

  /// Must be called once before using any other method.
  ///
  /// Safe to call multiple times — will no-op if already initialized.
  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    await Alarm.init();
    _prefs = await SharedPreferences.getInstance();
    _loadPersistedAlarm();
    _isInitialized = true;
  }

  void _loadPersistedAlarm() {
    final prefs = _prefs;
    if (prefs == null) return;

    final enabled = prefs.getBool(_prefEnabled) ?? false;
    if (!enabled) {
      _nextAlarmTime = null;
      return;
    }

    final hour = prefs.getInt(_prefHour);
    final minute = prefs.getInt(_prefMinute);
    if (hour != null && minute != null) {
      _nextAlarmTime = TimeOfDay(hour: hour, minute: minute);
    }
  }

  // ── Scheduling ───────────────────────────────────────────────────────────

  /// Schedules the alarm for [time] on the next occurrence of that time.
  ///
  /// If the time has already passed today it will fire tomorrow.
  Future<void> scheduleAlarm(TimeOfDay time) async {
    await ensureInitialized();

    final scheduledDate = _nextOccurrence(time);

    final settings = AlarmSettings(
      id: _alarmId,
      dateTime: scheduledDate,
      assetAudioPath: 'assets/alarm_sound.mp3',
      loopAudio: true,
      vibrate: true,
      volume: 0.8,
      fadeDuration: 3,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      notificationSettings: const NotificationSettings(
        title: 'Suhoor Time! 🌙',
        body: "Time to wake up for Suhoor! Solve the challenge to confirm you're awake.",
        stopButton: 'Dismiss',
        icon: 'notification_icon',
      ),
    );

    await Alarm.set(alarmSettings: settings);

    _nextAlarmTime = time;
    await _persistAlarm(time);
    notifyListeners();
  }

  /// Cancels the currently scheduled alarm.
  Future<void> cancelAlarm() async {
    await ensureInitialized();
    await Alarm.stop(_alarmId);
    _nextAlarmTime = null;
    await _clearPersistedAlarm();
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns the next [DateTime] at which [time] occurs.
  DateTime _nextOccurrence(TimeOfDay time) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now) || scheduled == now) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _persistAlarm(TimeOfDay time) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setInt(_prefHour, time.hour);
    await prefs.setInt(_prefMinute, time.minute);
    await prefs.setBool(_prefEnabled, true);
  }

  Future<void> _clearPersistedAlarm() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.remove(_prefHour);
    await prefs.remove(_prefMinute);
    await prefs.setBool(_prefEnabled, false);
  }

  /// Human-readable label for the current alarm time, e.g. "04:30 AM".
  String get alarmLabel {
    final time = _nextAlarmTime;
    if (time == null) return 'No alarm set';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
