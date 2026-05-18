import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/models/habit.dart';
import '../data/repositories/habit_repository.dart';

class HabitService {
  final HabitRepository _repository = HabitRepository();

  Future<String?> createHabit({
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

      await _repository.createHabit(habit);
      return null;
    } on FirebaseException catch (e) {
      return e.message ?? 'Failed to create habit.';
    } on StateError catch (e) {
      return e.message;
    } catch (e) {
      return 'Error: $e';
    }
  }
}
