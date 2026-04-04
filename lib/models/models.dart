import 'package:hive/hive.dart';

part 'models.g.dart';

// ─── Enums ───────────────────────────────────────────────────────────────────

enum UserRole { parent, child }

enum ChoreTimeSlot { morning, afternoon, evening, specific }

enum ChoreStatus { pending, submitted, approved, denied, missed }

enum RepeatFrequency { none, daily, weekly, weekdays, weekends, custom }

// ─── User Model ──────────────────────────────────────────────────────────────

@HiveType(typeId: 0)
class AppUser extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String pin; // 4-digit PIN

  @HiveField(3)
  late int roleIndex; // 0=parent, 1=child

  @HiveField(4)
  late int colorIndex; // index into AppTheme.childColors

  @HiveField(5)
  late String emoji; // Avatar emoji

  @HiveField(6)
  late DateTime createdAt;

  @HiveField(7)
  bool isActive = true;

  UserRole get role => UserRole.values[roleIndex];
  bool get isParent => role == UserRole.parent;
  bool get isChild => role == UserRole.child;
}

// ─── Chore Model ─────────────────────────────────────────────────────────────

@HiveType(typeId: 1)
class Chore extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  String description = '';

  @HiveField(3)
  late int timeSlotIndex; // ChoreTimeSlot index

  @HiveField(4)
  String? specificTime; // "HH:mm" for specific time slot

  @HiveField(5)
  late int repeatIndex; // RepeatFrequency index

  @HiveField(6)
  List<int> repeatDays = []; // 1=Mon...7=Sun for custom

  @HiveField(7)
  late List<String> assignedChildIds;

  @HiveField(8)
  String? rewardGroupId; // which reward group this belongs to

  @HiveField(9)
  late DateTime createdAt;

  @HiveField(10)
  bool isActive = true;

  @HiveField(11)
  String emoji = '✅';

  @HiveField(12)
  String? choreGroupId; // chore set group (morning chores, etc.)

  ChoreTimeSlot get timeSlot => ChoreTimeSlot.values[timeSlotIndex];
  RepeatFrequency get repeat => RepeatFrequency.values[repeatIndex];
}

// ─── Chore Instance (daily record) ───────────────────────────────────────────

@HiveType(typeId: 2)
class ChoreInstance extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String choreId;

  @HiveField(2)
  late String childId;

  @HiveField(3)
  late int statusIndex;

  @HiveField(4)
  late DateTime date; // which day this instance is for

  @HiveField(5)
  String? photoPath; // local file path to verification photo

  @HiveField(6)
  DateTime? submittedAt;

  @HiveField(7)
  DateTime? reviewedAt;

  @HiveField(8)
  String? deniedReason;

  @HiveField(9)
  String? reviewedByParentId;

  ChoreStatus get status => ChoreStatus.values[statusIndex];
  set status(ChoreStatus s) => statusIndex = s.index;
}

// ─── Chore Group ─────────────────────────────────────────────────────────────

@HiveType(typeId: 3)
class ChoreGroup extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name; // e.g. "Morning Routine"

  @HiveField(2)
  late int timeSlotIndex;

  @HiveField(3)
  late List<String> choreIds;

  @HiveField(4)
  late List<String> assignedChildIds;

  @HiveField(5)
  late DateTime createdAt;

  ChoreTimeSlot get timeSlot => ChoreTimeSlot.values[timeSlotIndex];
}

// ─── Reward Model ─────────────────────────────────────────────────────────────

@HiveType(typeId: 4)
class Reward extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title; // "30 min Screen Time"

  @HiveField(2)
  String description = '';

  @HiveField(3)
  late String emoji;

  @HiveField(4)
  late String choreGroupId; // completing this group unlocks reward

  @HiveField(5)
  late List<String> assignedChildIds;

  @HiveField(6)
  late DateTime createdAt;

  @HiveField(7)
  bool isActive = true;
}

// ─── Reward Instance ─────────────────────────────────────────────────────────

@HiveType(typeId: 5)
class RewardInstance extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String rewardId;

  @HiveField(2)
  late String childId;

  @HiveField(3)
  late DateTime unlockedAt;

  @HiveField(4)
  bool redeemed = false;

  @HiveField(5)
  DateTime? redeemedAt;
}

// ─── Calendar Event ───────────────────────────────────────────────────────────

@HiveType(typeId: 6)
class CalendarEvent extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  String description = '';

  @HiveField(3)
  late DateTime date;

  @HiveField(4)
  String? time; // "HH:mm"

  @HiveField(5)
  late List<String> assignedChildIds; // empty = all family

  @HiveField(6)
  late DateTime createdAt;

  @HiveField(7)
  String createdByParentId = '';

  @HiveField(8)
  String emoji = '📅';

  bool get isAllFamily => assignedChildIds.isEmpty;
}
