// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppUserAdapter extends TypeAdapter<AppUser> {
  @override
  final int typeId = 0;

  @override
  AppUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppUser()
      ..id = fields[0] as String
      ..name = fields[1] as String
      ..pin = fields[2] as String
      ..roleIndex = fields[3] as int
      ..colorIndex = fields[4] as int
      ..emoji = fields[5] as String
      ..createdAt = fields[6] as DateTime
      ..isActive = fields[7] as bool;
  }

  @override
  void write(BinaryWriter writer, AppUser obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.pin)
      ..writeByte(3)
      ..write(obj.roleIndex)
      ..writeByte(4)
      ..write(obj.colorIndex)
      ..writeByte(5)
      ..write(obj.emoji)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.isActive);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}

class ChoreAdapter extends TypeAdapter<Chore> {
  @override
  final int typeId = 1;

  @override
  Chore read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Chore()
      ..id = fields[0] as String
      ..title = fields[1] as String
      ..description = fields[2] as String
      ..timeSlotIndex = fields[3] as int
      ..specificTime = fields[4] as String?
      ..repeatIndex = fields[5] as int
      ..repeatDays = (fields[6] as List).cast<int>()
      ..assignedChildIds = (fields[7] as List).cast<String>()
      ..rewardGroupId = fields[8] as String?
      ..createdAt = fields[9] as DateTime
      ..isActive = fields[10] as bool
      ..emoji = fields[11] as String
      ..choreGroupId = fields[12] as String?;
  }

  @override
  void write(BinaryWriter writer, Chore obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.timeSlotIndex)
      ..writeByte(4)
      ..write(obj.specificTime)
      ..writeByte(5)
      ..write(obj.repeatIndex)
      ..writeByte(6)
      ..write(obj.repeatDays)
      ..writeByte(7)
      ..write(obj.assignedChildIds)
      ..writeByte(8)
      ..write(obj.rewardGroupId)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.isActive)
      ..writeByte(11)
      ..write(obj.emoji)
      ..writeByte(12)
      ..write(obj.choreGroupId);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChoreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}

class ChoreInstanceAdapter extends TypeAdapter<ChoreInstance> {
  @override
  final int typeId = 2;

  @override
  ChoreInstance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChoreInstance()
      ..id = fields[0] as String
      ..choreId = fields[1] as String
      ..childId = fields[2] as String
      ..statusIndex = fields[3] as int
      ..date = fields[4] as DateTime
      ..photoPath = fields[5] as String?
      ..submittedAt = fields[6] as DateTime?
      ..reviewedAt = fields[7] as DateTime?
      ..deniedReason = fields[8] as String?
      ..reviewedByParentId = fields[9] as String?;
  }

  @override
  void write(BinaryWriter writer, ChoreInstance obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.choreId)
      ..writeByte(2)
      ..write(obj.childId)
      ..writeByte(3)
      ..write(obj.statusIndex)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.photoPath)
      ..writeByte(6)
      ..write(obj.submittedAt)
      ..writeByte(7)
      ..write(obj.reviewedAt)
      ..writeByte(8)
      ..write(obj.deniedReason)
      ..writeByte(9)
      ..write(obj.reviewedByParentId);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChoreInstanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}

class ChoreGroupAdapter extends TypeAdapter<ChoreGroup> {
  @override
  final int typeId = 3;

  @override
  ChoreGroup read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChoreGroup()
      ..id = fields[0] as String
      ..name = fields[1] as String
      ..timeSlotIndex = fields[2] as int
      ..choreIds = (fields[3] as List).cast<String>()
      ..assignedChildIds = (fields[4] as List).cast<String>()
      ..createdAt = fields[5] as DateTime;
  }

  @override
  void write(BinaryWriter writer, ChoreGroup obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.timeSlotIndex)
      ..writeByte(3)
      ..write(obj.choreIds)
      ..writeByte(4)
      ..write(obj.assignedChildIds)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChoreGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}

class RewardAdapter extends TypeAdapter<Reward> {
  @override
  final int typeId = 4;

  @override
  Reward read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Reward()
      ..id = fields[0] as String
      ..title = fields[1] as String
      ..description = fields[2] as String
      ..emoji = fields[3] as String
      ..choreGroupId = fields[4] as String
      ..assignedChildIds = (fields[5] as List).cast<String>()
      ..createdAt = fields[6] as DateTime
      ..isActive = fields[7] as bool;
  }

  @override
  void write(BinaryWriter writer, Reward obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.emoji)
      ..writeByte(4)
      ..write(obj.choreGroupId)
      ..writeByte(5)
      ..write(obj.assignedChildIds)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.isActive);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}

class RewardInstanceAdapter extends TypeAdapter<RewardInstance> {
  @override
  final int typeId = 5;

  @override
  RewardInstance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RewardInstance()
      ..id = fields[0] as String
      ..rewardId = fields[1] as String
      ..childId = fields[2] as String
      ..unlockedAt = fields[3] as DateTime
      ..redeemed = fields[4] as bool
      ..redeemedAt = fields[5] as DateTime?;
  }

  @override
  void write(BinaryWriter writer, RewardInstance obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.rewardId)
      ..writeByte(2)
      ..write(obj.childId)
      ..writeByte(3)
      ..write(obj.unlockedAt)
      ..writeByte(4)
      ..write(obj.redeemed)
      ..writeByte(5)
      ..write(obj.redeemedAt);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardInstanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}

class CalendarEventAdapter extends TypeAdapter<CalendarEvent> {
  @override
  final int typeId = 6;

  @override
  CalendarEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalendarEvent()
      ..id = fields[0] as String
      ..title = fields[1] as String
      ..description = fields[2] as String
      ..date = fields[3] as DateTime
      ..time = fields[4] as String?
      ..assignedChildIds = (fields[5] as List).cast<String>()
      ..createdAt = fields[6] as DateTime
      ..createdByParentId = fields[7] as String
      ..emoji = fields[8] as String;
  }

  @override
  void write(BinaryWriter writer, CalendarEvent obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.time)
      ..writeByte(5)
      ..write(obj.assignedChildIds)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.createdByParentId)
      ..writeByte(8)
      ..write(obj.emoji);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
