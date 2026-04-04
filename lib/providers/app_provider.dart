import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

class AppProvider extends ChangeNotifier {
  static const String _usersBox = 'users';
  static const String _choresBox = 'chores';
  static const String _instancesBox = 'chore_instances';
  static const String _groupsBox = 'chore_groups';
  static const String _rewardsBox = 'rewards';
  static const String _rewardInstancesBox = 'reward_instances';
  static const String _eventsBox = 'calendar_events';

  final _uuid = const Uuid();

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isParent => _currentUser?.isParent ?? false;

  // ─── Getters ─────────────────────────────────────────────────────────────

  List<AppUser> get allUsers =>
      Hive.box<AppUser>(_usersBox).values.where((u) => u.isActive).toList();

  List<AppUser> get parents =>
      allUsers.where((u) => u.isParent).toList();

  List<AppUser> get children =>
      allUsers.where((u) => u.isChild).toList();

  List<Chore> get allChores =>
      Hive.box<Chore>(_choresBox).values.where((c) => c.isActive).toList();

  List<ChoreGroup> get allChoreGroups =>
      Hive.box<ChoreGroup>(_groupsBox).values.toList();

  List<Reward> get allRewards =>
      Hive.box<Reward>(_rewardsBox).values.where((r) => r.isActive).toList();

  List<CalendarEvent> get allEvents =>
      Hive.box<CalendarEvent>(_eventsBox).values.toList();

  // ─── Initialization ───────────────────────────────────────────────────────

  Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(AppUserAdapter());
    Hive.registerAdapter(ChoreAdapter());
    Hive.registerAdapter(ChoreInstanceAdapter());
    Hive.registerAdapter(ChoreGroupAdapter());
    Hive.registerAdapter(RewardAdapter());
    Hive.registerAdapter(RewardInstanceAdapter());
    Hive.registerAdapter(CalendarEventAdapter());

    await Hive.openBox<AppUser>(_usersBox);
    await Hive.openBox<Chore>(_choresBox);
    await Hive.openBox<ChoreInstance>(_instancesBox);
    await Hive.openBox<ChoreGroup>(_groupsBox);
    await Hive.openBox<Reward>(_rewardsBox);
    await Hive.openBox<RewardInstance>(_rewardInstancesBox);
    await Hive.openBox<CalendarEvent>(_eventsBox);

    // Seed default parents if none exist
    if (allUsers.isEmpty) {
      await _seedDefaultUsers();
    }

    notifyListeners();
  }

  Future<void> _seedDefaultUsers() async {
    final box = Hive.box<AppUser>(_usersBox);

    final parent1 = AppUser()
      ..id = _uuid.v4()
      ..name = 'Parent 1'
      ..pin = '1234'
      ..roleIndex = 0
      ..colorIndex = 0
      ..emoji = '👨'
      ..createdAt = DateTime.now();

    final parent2 = AppUser()
      ..id = _uuid.v4()
      ..name = 'Parent 2'
      ..pin = '5678'
      ..roleIndex = 0
      ..colorIndex = 0
      ..emoji = '👩'
      ..createdAt = DateTime.now();

    await box.put(parent1.id, parent1);
    await box.put(parent2.id, parent2);
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

  bool login(String userId, String pin) {
    final box = Hive.box<AppUser>(_usersBox);
    final user = box.get(userId);
    if (user != null && user.pin == pin && user.isActive) {
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // ─── User Management ──────────────────────────────────────────────────────

  Future<AppUser> addChild({
    required String name,
    required String pin,
    required int colorIndex,
    required String emoji,
  }) async {
    final box = Hive.box<AppUser>(_usersBox);
    final child = AppUser()
      ..id = _uuid.v4()
      ..name = name
      ..pin = pin
      ..roleIndex = 1
      ..colorIndex = colorIndex
      ..emoji = emoji
      ..createdAt = DateTime.now();
    await box.put(child.id, child);
    notifyListeners();
    return child;
  }

  Future<void> updateUser(AppUser user) async {
    await user.save();
    if (_currentUser?.id == user.id) {
      _currentUser = user;
    }
    notifyListeners();
  }

  Future<void> removeChild(String childId) async {
    final box = Hive.box<AppUser>(_usersBox);
    final user = box.get(childId);
    if (user != null) {
      user.isActive = false;
      await user.save();
    }
    notifyListeners();
  }

  // ─── Chore Management ─────────────────────────────────────────────────────

  Future<Chore> addChore({
    required String title,
    String description = '',
    required ChoreTimeSlot timeSlot,
    String? specificTime,
    required RepeatFrequency repeat,
    List<int> repeatDays = const [],
    required List<String> assignedChildIds,
    String? choreGroupId,
    String emoji = '✅',
  }) async {
    final box = Hive.box<Chore>(_choresBox);
    final chore = Chore()
      ..id = _uuid.v4()
      ..title = title
      ..description = description
      ..timeSlotIndex = timeSlot.index
      ..specificTime = specificTime
      ..repeatIndex = repeat.index
      ..repeatDays = repeatDays
      ..assignedChildIds = assignedChildIds
      ..choreGroupId = choreGroupId
      ..emoji = emoji
      ..createdAt = DateTime.now();
    await box.put(chore.id, chore);
    _ensureTodayInstances();
    notifyListeners();
    return chore;
  }

  Future<void> updateChore(Chore chore) async {
    await chore.save();
    notifyListeners();
  }

  Future<void> deleteChore(String choreId) async {
    final box = Hive.box<Chore>(_choresBox);
    final chore = box.get(choreId);
    if (chore != null) {
      chore.isActive = false;
      await chore.save();
    }
    notifyListeners();
  }

  // ─── Chore Groups ─────────────────────────────────────────────────────────

  Future<ChoreGroup> addChoreGroup({
    required String name,
    required ChoreTimeSlot timeSlot,
    required List<String> choreIds,
    required List<String> assignedChildIds,
  }) async {
    final box = Hive.box<ChoreGroup>(_groupsBox);
    final group = ChoreGroup()
      ..id = _uuid.v4()
      ..name = name
      ..timeSlotIndex = timeSlot.index
      ..choreIds = choreIds
      ..assignedChildIds = assignedChildIds
      ..createdAt = DateTime.now();
    await box.put(group.id, group);
    notifyListeners();
    return group;
  }

  Future<void> deleteChoreGroup(String groupId) async {
    final box = Hive.box<ChoreGroup>(_groupsBox);
    await box.delete(groupId);
    notifyListeners();
  }

  // ─── Chore Instances ──────────────────────────────────────────────────────

  void _ensureTodayInstances() {
    final today = _dateOnly(DateTime.now());
    final box = Hive.box<ChoreInstance>(_instancesBox);
    final chores = allChores;

    for (final chore in chores) {
      if (!_choreIsScheduledFor(chore, today)) continue;
      for (final childId in chore.assignedChildIds) {
        final key = '${chore.id}_${childId}_${today.millisecondsSinceEpoch}';
        if (!box.containsKey(key)) {
          final instance = ChoreInstance()
            ..id = key
            ..choreId = chore.id
            ..childId = childId
            ..statusIndex = ChoreStatus.pending.index
            ..date = today;
          box.put(key, instance);
        }
      }
    }
  }

  bool _choreIsScheduledFor(Chore chore, DateTime date) {
    switch (chore.repeat) {
      case RepeatFrequency.daily:
        return true;
      case RepeatFrequency.weekdays:
        return date.weekday <= 5;
      case RepeatFrequency.weekends:
        return date.weekday >= 6;
      case RepeatFrequency.weekly:
        return true; // simplified
      case RepeatFrequency.custom:
        return chore.repeatDays.contains(date.weekday);
      case RepeatFrequency.none:
        return _dateOnly(chore.createdAt) == date;
    }
  }

  List<ChoreInstance> getInstancesForChild(String childId, DateTime date) {
    _ensureTodayInstances();
    final d = _dateOnly(date);
    return Hive.box<ChoreInstance>(_instancesBox)
        .values
        .where((i) => i.childId == childId && _dateOnly(i.date) == d)
        .toList();
  }

  List<ChoreInstance> getPendingApprovals() {
    return Hive.box<ChoreInstance>(_instancesBox)
        .values
        .where((i) => i.statusIndex == ChoreStatus.submitted.index)
        .toList();
  }

  Future<void> submitChoreInstance(String instanceId, String? photoPath) async {
    final box = Hive.box<ChoreInstance>(_instancesBox);
    final instance = box.get(instanceId);
    if (instance != null) {
      instance.status = ChoreStatus.submitted;
      instance.photoPath = photoPath;
      instance.submittedAt = DateTime.now();
      await instance.save();
      notifyListeners();
      _checkGroupCompletion(instance);

      // 🔔 Notify parents that a chore was submitted
      if (!kIsWeb) {
        final chore = getChoreById(instance.choreId);
        final child = getUserById(instance.childId);
        if (chore != null && child != null) {
          await NotificationService().notifyParentChoreSubmitted(
            childName: child.name,
            choreName: chore.title,
            childEmoji: child.emoji,
          );
        }
      }
    }
  }

  Future<void> approveChoreInstance(String instanceId, String parentId) async {
    final box = Hive.box<ChoreInstance>(_instancesBox);
    final instance = box.get(instanceId);
    if (instance != null) {
      instance.status = ChoreStatus.approved;
      instance.reviewedAt = DateTime.now();
      instance.reviewedByParentId = parentId;
      await instance.save();
      notifyListeners();
      _checkGroupCompletion(instance);

      // 🔔 Notify child their chore was approved
      if (!kIsWeb) {
        final chore = getChoreById(instance.choreId);
        final child = getUserById(instance.childId);
        if (chore != null && child != null) {
          await NotificationService().notifyChildChoreApproved(
            choreName: chore.title,
            childEmoji: child.emoji,
          );
        }
      }
    }
  }

  Future<void> denyChoreInstance(
      String instanceId, String parentId, String reason) async {
    final box = Hive.box<ChoreInstance>(_instancesBox);
    final instance = box.get(instanceId);
    if (instance != null) {
      instance.status = ChoreStatus.denied;
      instance.reviewedAt = DateTime.now();
      instance.reviewedByParentId = parentId;
      instance.deniedReason = reason;
      await instance.save();
      notifyListeners();

      // 🔔 Notify child their chore was denied
      if (!kIsWeb) {
        final chore = getChoreById(instance.choreId);
        if (chore != null) {
          await NotificationService().notifyChildChoreDenied(
            choreName: chore.title,
            reason: reason.isNotEmpty ? reason : 'Please try again.',
          );
        }
      }
    }
  }

  void _checkGroupCompletion(ChoreInstance completedInstance) {
    final chore = Hive.box<Chore>(_choresBox).get(completedInstance.choreId);
    if (chore?.choreGroupId == null) return;

    final group =
        Hive.box<ChoreGroup>(_groupsBox).get(chore!.choreGroupId);
    if (group == null) return;

    final date = _dateOnly(completedInstance.date);
    final instanceBox = Hive.box<ChoreInstance>(_instancesBox);

    final allGroupInstances = group.choreIds
        .map((cId) {
          final key =
              '${cId}_${completedInstance.childId}_${date.millisecondsSinceEpoch}';
          return instanceBox.get(key);
        })
        .where((i) => i != null)
        .toList();

    final allApproved = allGroupInstances.every(
        (i) => i!.statusIndex == ChoreStatus.approved.index);

    if (allApproved) {
      _unlockGroupRewards(group.id, completedInstance.childId);
    }
  }

  Future<void> _unlockGroupRewards(String groupId, String childId) async {
    final rewards = allRewards.where(
        (r) => r.choreGroupId == groupId && r.assignedChildIds.contains(childId));

    final box = Hive.box<RewardInstance>(_rewardInstancesBox);
    final child = getUserById(childId);
    final group = Hive.box<ChoreGroup>(_groupsBox).get(groupId);

    for (final reward in rewards) {
      final ri = RewardInstance()
        ..id = _uuid.v4()
        ..rewardId = reward.id
        ..childId = childId
        ..unlockedAt = DateTime.now()
        ..redeemed = false;
      await box.put(ri.id, ri);

      // 🔔 Notify child reward unlocked
      if (!kIsWeb && child != null) {
        await NotificationService().notifyChildRewardUnlocked(
          rewardTitle: reward.title,
          rewardEmoji: reward.emoji,
          childName: child.name,
        );
      }
    }

    // 🔔 Notify parents that a group was completed
    if (!kIsWeb && child != null && group != null) {
      await NotificationService().notifyParentGroupComplete(
        childName: child.name,
        groupName: group.name,
        childEmoji: child.emoji,
      );
    }

    notifyListeners();
  }

  // ─── Rewards ─────────────────────────────────────────────────────────────

  Future<Reward> addReward({
    required String title,
    required String description,
    required String emoji,
    required String choreGroupId,
    required List<String> assignedChildIds,
  }) async {
    final box = Hive.box<Reward>(_rewardsBox);
    final reward = Reward()
      ..id = _uuid.v4()
      ..title = title
      ..description = description
      ..emoji = emoji
      ..choreGroupId = choreGroupId
      ..assignedChildIds = assignedChildIds
      ..createdAt = DateTime.now();
    await box.put(reward.id, reward);
    notifyListeners();
    return reward;
  }

  List<RewardInstance> getUnredeemedRewardsForChild(String childId) {
    return Hive.box<RewardInstance>(_rewardInstancesBox)
        .values
        .where((ri) => ri.childId == childId && !ri.redeemed)
        .toList();
  }

  Future<void> redeemReward(String rewardInstanceId) async {
    final ri =
        Hive.box<RewardInstance>(_rewardInstancesBox).get(rewardInstanceId);
    if (ri != null) {
      ri.redeemed = true;
      ri.redeemedAt = DateTime.now();
      await ri.save();
      notifyListeners();
    }
  }

  // ─── Calendar Events ──────────────────────────────────────────────────────

  Future<CalendarEvent> addEvent({
    required String title,
    String description = '',
    required DateTime date,
    String? time,
    required List<String> assignedChildIds,
    String emoji = '📅',
  }) async {
    final box = Hive.box<CalendarEvent>(_eventsBox);
    final event = CalendarEvent()
      ..id = _uuid.v4()
      ..title = title
      ..description = description
      ..date = date
      ..time = time
      ..assignedChildIds = assignedChildIds
      ..createdAt = DateTime.now()
      ..createdByParentId = _currentUser?.id ?? ''
      ..emoji = emoji;
    await box.put(event.id, event);
    notifyListeners();
    return event;
  }

  Future<void> deleteEvent(String eventId) async {
    await Hive.box<CalendarEvent>(_eventsBox).delete(eventId);
    notifyListeners();
  }

  List<CalendarEvent> getEventsForDate(DateTime date) {
    final d = _dateOnly(date);
    return allEvents.where((e) => _dateOnly(e.date) == d).toList();
  }

  List<CalendarEvent> getEventsForChild(String childId, DateTime date) {
    final d = _dateOnly(date);
    return allEvents.where((e) {
      if (_dateOnly(e.date) != d) return false;
      return e.isAllFamily || e.assignedChildIds.contains(childId);
    }).toList();
  }

  // ─── Statistics ───────────────────────────────────────────────────────────

  Map<String, double> getCompletionRatesForToday() {
    final today = DateTime.now();
    final rates = <String, double>{};
    for (final child in children) {
      final instances = getInstancesForChild(child.id, today);
      if (instances.isEmpty) {
        rates[child.id] = 0.0;
        continue;
      }
      final approved =
          instances.where((i) => i.statusIndex == ChoreStatus.approved.index).length;
      rates[child.id] = approved / instances.length;
    }
    return rates;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  AppUser? getUserById(String id) =>
      Hive.box<AppUser>(_usersBox).get(id);

  Chore? getChoreById(String id) =>
      Hive.box<Chore>(_choresBox).get(id);

  Reward? getRewardById(String id) =>
      Hive.box<Reward>(_rewardsBox).get(id);

  Color getChildColor(AppUser child) {
    final idx = child.colorIndex.clamp(0, AppTheme.childColors.length - 1);
    return AppTheme.childColors[idx];
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  final NotificationService notificationService = NotificationService();

  Future<void> setupRemindersForAllChildren() async {
    if (kIsWeb) return;
    for (final child in children) {
      await notificationService.setupChildReminders(
        childId: child.id,
        childName: child.name,
        morningEnabled: true,
        afternoonEnabled: true,
        eveningEnabled: true,
      );
    }
    // Also schedule daily parent summary
    final totalChores = allChores.length;
    await notificationService.scheduleParentDailySummary(
      totalChoresCount: totalChores,
    );
  }

  Future<void> setupRemindersForChild({
    required String childId,
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
    final child = getUserById(childId);
    if (child == null) return;
    await notificationService.setupChildReminders(
      childId: childId,
      childName: child.name,
      morningEnabled: morningEnabled,
      afternoonEnabled: afternoonEnabled,
      eveningEnabled: eveningEnabled,
      morningHour: morningHour,
      morningMinute: morningMinute,
      afternoonHour: afternoonHour,
      afternoonMinute: afternoonMinute,
      eveningHour: eveningHour,
      eveningMinute: eveningMinute,
    );
  }
}
