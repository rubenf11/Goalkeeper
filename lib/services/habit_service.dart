import 'package:cloud_firestore/cloud_firestore.dart';

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
    required int goal,
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
        progress: 0,
        goalReached: false,
        streak: 0,
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
}
