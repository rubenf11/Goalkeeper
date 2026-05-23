import 'package:cloud_firestore/cloud_firestore.dart';

enum Frequency { daily, weekly, monthly, yearly }

extension FrequencyX on Frequency {
  String get value {
    switch (this) {
      case Frequency.daily:
        return 'daily';
      case Frequency.weekly:
        return 'weekly';
      case Frequency.monthly:
        return 'monthly';
      case Frequency.yearly:
        return 'yearly';
    }
  }

  static Frequency fromString(String value) {
    switch (value.toLowerCase()) {
      case 'daily':
        return Frequency.daily;
      case 'weekly':
        return Frequency.weekly;
      case 'monthly':
        return Frequency.monthly;
      case 'yearly':
        return Frequency.yearly;
      default:
        throw ArgumentError('Invalid frequency value: $value');
    }
  }
}

class Habit {
  const Habit({
    required this.habitId,
    required this.userId,
    required this.name,
    required this.category,
    required this.frequency,
    required this.goal,
    required this.unit,
    required this.accelerometer,
    required this.progress,
    required this.goalReached,
    required this.streak,
    required this.highestStreak,
    required this.isDone,
    required this.createdAt,
    this.lastEntryAt,
  });

  final String habitId;
  final String userId;
  final String name;
  final String category;
  final Frequency frequency;
  final int goal;
  final String unit;
  final bool accelerometer;
  final int progress;
  final bool goalReached;
  final int streak;
  final int highestStreak;
  final bool isDone;
  final DateTime? createdAt;
  final DateTime? lastEntryAt;

  Habit copyWith({
    String? habitId,
    String? userId,
    String? name,
    String? category,
    Frequency? frequency,
    int? goal,
    String? unit,
    bool? accelerometer,
    int? progress,
    bool? goalReached,
    int? streak,
    int? highestStreak,
    bool? isDone,
    DateTime? createdAt,
    DateTime? lastEntryAt,
  }) {
    return Habit(
      habitId: habitId ?? this.habitId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      goal: goal ?? this.goal,
      unit: unit ?? this.unit,
      accelerometer: accelerometer ?? this.accelerometer,
      progress: progress ?? this.progress,
      goalReached: goalReached ?? this.goalReached,
      streak: streak ?? this.streak,
      highestStreak: highestStreak ?? this.highestStreak,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
      lastEntryAt: lastEntryAt ?? this.lastEntryAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'habit_id': habitId,
      'user_id': userId,
      'name': name,
      'category': category,
      'frequency': frequency.value,
      'goal': goal,
      'unit': unit,
      'accelerometer': accelerometer,
      'progress': progress,
      'goal_reached': goalReached,
      'streak': streak,
      'highest_streak': highestStreak,
      'is_done': isDone,
      'created_at': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'last_entry_at': lastEntryAt == null
          ? null
          : Timestamp.fromDate(lastEntryAt!),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map, {required String id}) {
    final createdAt = map['created_at'];
    final lastEntryAt = map['last_entry_at'];

    return Habit(
      habitId: map['habit_id'] as String? ?? id,
      userId: map['user_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      frequency: FrequencyX.fromString(map['frequency'] as String? ?? 'daily'),
      goal: (map['goal'] as num?)?.toInt() ?? 0,
      unit: map['unit'] as String? ?? '',
      accelerometer: map['accelerometer'] as bool? ?? false,
      progress: (map['progress'] as num?)?.toInt() ?? 0,
      goalReached: map['goal_reached'] as bool? ?? false,
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      highestStreak: (map['highest_streak'] as num?)?.toInt() ?? 0,
      isDone: map['is_done'] as bool? ?? false,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      lastEntryAt: lastEntryAt is Timestamp ? lastEntryAt.toDate() : null,
    );
  }

  String get id => habitId;
}
