import 'package:firebase_auth/firebase_auth.dart';

import '../data/models/habit.dart';
import '../data/repositories/habit_repository.dart';

class HabitCreationResult {
  const HabitCreationResult({this.habit, this.error});

  final Habit? habit;
  final String? error;
}

class HabitService {
  final HabitRepository _repository = HabitRepository();

  Future<HabitCreationResult> createHabit({
    required String name,
    required String category,
    required Frequency frequency,
    required double goal,
    required String unit,
    required bool accelerometer,
  }) async {
    try {
      final Habit habit = Habit(
        habitId: '',
        userId: '',
        name: name.trim(),
        category: category.trim(),
        frequency: frequency,
        goal: goal,
        unit: unit.trim(),
        accelerometer: accelerometer,
        progress: 0.0,
        goalReached: false,
        streak: 0,
        highestStreak: 0,
        daysCompleted: 0,
        isDone: false,
        createdAt: null,
      );

      final createdHabit = await _repository.createHabit(habit);
      return HabitCreationResult(habit: createdHabit);
    } on FirebaseException catch (e) {
      return HabitCreationResult(error: e.message ?? 'Failed to create habit.');
    } on StateError catch (e) {
      return HabitCreationResult(error: e.message);
    } catch (e) {
      return HabitCreationResult(error: 'Error: $e');
    }
  }

  Future<void> recalculateHabitStats(String habitId) async {
    await _repository.recalculateHabitStats(habitId);
  }

  Future<void> refreshAllHabits() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final docs = await _repository.fetchHabitsForUser(user.uid);
    for (var doc in docs) {
      try {
        await recalculateHabitStats(doc.id);
      } catch (_) {
        // ignore individual failures
      }
    }
  }

  Stream<List<Habit>> watchCurrentUserHabits() {
    return _repository.watchCurrentUserHabits();
  }

  Stream<List<Habit>> watchCurrentUserActiveHabits() {
    return _repository.watchCurrentUserActiveHabits();
  }

  Stream<Map<String, num>> watchDailyProgress(String habitId) {
    return _repository.watchDailyProgress(habitId);
  }

  Stream<Habit?> watchHabit(String habitId) {
    return _repository.watchHabit(habitId);
  }

  Future<String?> setHabitCompletionStatus({
    required String habitId,
    required bool isDone,
  }) async {
    try {
      await _repository.setHabitCompletionStatus(
        habitId: habitId,
        isDone: isDone,
      );
      return null;
    } catch (e) {
      return 'Error updating habit completion status: $e';
    }
  }

  Stream<Map<String, num>> watchWeeklyProgress(
    String habitId, {
    String mode = 'Sum',
  }) {
    return _repository.watchWeeklyProgress(habitId, mode: mode);
  }

  Stream<Map<String, num>> watchMonthlyProgress(
    String habitId, {
    String mode = 'Sum',
  }) {
    return _repository.watchMonthlyProgress(habitId, mode: mode);
  }
}
