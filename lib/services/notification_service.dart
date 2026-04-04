import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── Notification ID ranges ───────────────────────────────────────────────
  // 1000-1999 : chore reminders (morning slot)
  // 2000-2999 : chore reminders (afternoon slot)
  // 3000-3999 : chore reminders (evening slot)
  // 4000-4999 : parent approval alerts
  // 5000-5999 : group completion alerts
  // 6000-6999 : calendar event reminders
  // 9000      : daily summary

  // ─── Initialization ───────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) return; // notifications not supported on web

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Could route to specific screen based on payload
    if (kDebugMode) {
      debugPrint('Notification tapped: ${response.payload}');
    }
  }

  // ─── Permissions ──────────────────────────────────────────────────────────

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    }

    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  // ─── Notification Details ─────────────────────────────────────────────────

  NotificationDetails _buildDetails({
    required String channelId,
    required String channelName,
    required String channelDesc,
    String? ticker,
    bool ongoing = false,
  }) {
    final android = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ticker: ticker,
      ongoing: ongoing,
      styleInformation: const DefaultStyleInformation(true, true),
      icon: '@mipmap/ic_launcher',
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    return NotificationDetails(android: android, iOS: ios);
  }

  // ─── Immediate Notifications ──────────────────────────────────────────────

  /// Notify parent that a child submitted a chore for approval
  Future<void> notifyParentChoreSubmitted({
    required String childName,
    required String choreName,
    required String childEmoji,
  }) async {
    if (kIsWeb) return;
    final details = _buildDetails(
      channelId: 'approvals',
      channelName: 'Chore Approvals',
      channelDesc: 'Notifications when kids submit chores for review',
    );
    await _plugin.show(
      _generateId('approval'),
      '$childEmoji $childName completed a chore!',
      '"$choreName" is waiting for your approval.',
      details,
      payload: 'approval',
    );
  }

  /// Notify parent that a child completed ALL chores in a group
  Future<void> notifyParentGroupComplete({
    required String childName,
    required String groupName,
    required String childEmoji,
  }) async {
    if (kIsWeb) return;
    final details = _buildDetails(
      channelId: 'group_complete',
      channelName: 'Group Completions',
      channelDesc: 'Notifications when a chore group is fully completed',
    );
    await _plugin.show(
      _generateId('group'),
      '🎉 $childName finished $groupName!',
      'All chores in "$groupName" have been submitted. Time to review!',
      details,
      payload: 'group_complete',
    );
  }

  /// Notify child that their chore was approved
  Future<void> notifyChildChoreApproved({
    required String choreName,
    required String childEmoji,
  }) async {
    if (kIsWeb) return;
    final details = _buildDetails(
      channelId: 'chore_status',
      channelName: 'Chore Status',
      channelDesc: 'Updates on your chore approvals',
    );
    await _plugin.show(
      _generateId('approved'),
      '✅ Chore approved!',
      '"$choreName" has been approved. Great job! $childEmoji',
      details,
      payload: 'approved',
    );
  }

  /// Notify child that their chore was denied and needs a redo
  Future<void> notifyChildChoreDenied({
    required String choreName,
    required String reason,
  }) async {
    if (kIsWeb) return;
    final details = _buildDetails(
      channelId: 'chore_status',
      channelName: 'Chore Status',
      channelDesc: 'Updates on your chore approvals',
    );
    await _plugin.show(
      _generateId('denied'),
      '↩ Chore needs a redo',
      '"$choreName": $reason',
      details,
      payload: 'denied',
    );
  }

  /// Notify child that a reward was unlocked
  Future<void> notifyChildRewardUnlocked({
    required String rewardTitle,
    required String rewardEmoji,
    required String childName,
  }) async {
    if (kIsWeb) return;
    final details = _buildDetails(
      channelId: 'rewards',
      channelName: 'Rewards',
      channelDesc: 'Reward unlock notifications',
    );
    await _plugin.show(
      _generateId('reward'),
      '$rewardEmoji Reward Unlocked!',
      '$childName earned: "$rewardTitle"! Ask a parent to redeem it.',
      details,
      payload: 'reward',
    );
  }

  // ─── Scheduled Notifications ──────────────────────────────────────────────

  /// Schedule a daily chore reminder for a child at a specific time
  Future<void> scheduleDailyChoreReminder({
    required int notifId,
    required String childName,
    required String slotLabel, // "Morning", "Afternoon", "Evening"
    required String slotEmoji,
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;

    final details = _buildDetails(
      channelId: 'chore_reminders',
      channelName: 'Chore Reminders',
      channelDesc: 'Daily reminders for chore time slots',
    );

    await _plugin.zonedSchedule(
      notifId,
      '$slotEmoji $slotLabel Chores',
      'Time to check off your $slotLabel chores, $childName!',
      _nextInstanceOfTime(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'reminder_$slotLabel',
    );
  }

  /// Schedule a calendar event reminder (1 hour before event)
  Future<void> scheduleEventReminder({
    required int notifId,
    required String eventTitle,
    required String eventEmoji,
    required DateTime eventDateTime,
    required String childName,
  }) async {
    if (kIsWeb) return;

    final reminderTime = eventDateTime.subtract(const Duration(hours: 1));
    if (reminderTime.isBefore(DateTime.now())) return;

    final details = _buildDetails(
      channelId: 'calendar_events',
      channelName: 'Calendar Events',
      channelDesc: 'Reminders for upcoming calendar events',
    );

    await _plugin.zonedSchedule(
      notifId,
      '$eventEmoji Coming up in 1 hour!',
      '$eventTitle — Don\'t forget, $childName!',
      tz.TZDateTime.from(reminderTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'event_$eventTitle',
    );
  }

  /// Schedule a morning summary for parents (8 AM daily)
  Future<void> scheduleParentDailySummary({
    required int totalChoresCount,
  }) async {
    if (kIsWeb) return;

    await cancelNotification(9000);

    final details = _buildDetails(
      channelId: 'parent_summary',
      channelName: 'Daily Summary',
      channelDesc: 'Daily family chore summary for parents',
    );

    await _plugin.zonedSchedule(
      9000,
      '📋 Family Chores Today',
      '$totalChoresCount chores scheduled across all kids today. Tap to review.',
      _nextInstanceOfTime(8, 0),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_summary',
    );
  }

  // ─── Cancel Notifications ─────────────────────────────────────────────────

  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  Future<void> cancelChoreRemindersForChild(String childId) async {
    if (kIsWeb) return;
    // Cancel morning, afternoon, evening reminders for this child
    final childHash = childId.hashCode.abs() % 100;
    await _plugin.cancel(1000 + childHash);
    await _plugin.cancel(2000 + childHash);
    await _plugin.cancel(3000 + childHash);
  }

  // ─── Setup All Reminders for a Child ─────────────────────────────────────

  Future<void> setupChildReminders({
    required String childId,
    required String childName,
    required bool morningEnabled,
    required bool afternoonEnabled,
    required bool eveningEnabled,
    int morningHour = 8,
    int morningMinute = 0,
    int afternoonHour = 14,
    int afternoonMinute = 0,
    int eveningHour = 19,
    int eveningMinute = 0,
  }) async {
    if (kIsWeb) return;

    final childHash = childId.hashCode.abs() % 100;

    if (morningEnabled) {
      await scheduleDailyChoreReminder(
        notifId: 1000 + childHash,
        childName: childName,
        slotLabel: 'Morning',
        slotEmoji: '☀️',
        hour: morningHour,
        minute: morningMinute,
      );
    } else {
      await cancelNotification(1000 + childHash);
    }

    if (afternoonEnabled) {
      await scheduleDailyChoreReminder(
        notifId: 2000 + childHash,
        childName: childName,
        slotLabel: 'Afternoon',
        slotEmoji: '🌤️',
        hour: afternoonHour,
        minute: afternoonMinute,
      );
    } else {
      await cancelNotification(2000 + childHash);
    }

    if (eveningEnabled) {
      await scheduleDailyChoreReminder(
        notifId: 3000 + childHash,
        childName: childName,
        slotLabel: 'Evening',
        slotEmoji: '🌙',
        hour: eveningHour,
        minute: eveningMinute,
      );
    } else {
      await cancelNotification(3000 + childHash);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  int _generateId(String type) {
    final base = DateTime.now().millisecondsSinceEpoch % 10000;
    return base;
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (kIsWeb) return [];
    return await _plugin.pendingNotificationRequests();
  }
}
