import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> addEntryAndUpdateHabit(String habitId, double amountEntered) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final habitDoc = FirebaseFirestore.instance
        .collection('habits')
        .doc(habitId);

    // 1. Add the entry
    await habitDoc.collection('entries').add({
      'amount': amountEntered,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Recalculate everything for this specific habit
    await recalculateHabitStats(habitId);
  }

  Future<void> recalculateHabitStats(String habitId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final habitRef = FirebaseFirestore.instance
        .collection('habits')
        .doc(habitId);

    // 1. Get the Habit configuration
    final habitSnap = await habitRef.get();
    if (!habitSnap.exists) return;
    final int goal = habitSnap.data()?['goal'] ?? 0;

    // 2. Get all entries for this habit
    final entriesSnap = await habitRef.collection('entries').orderBy('timestamp', descending: true).get();

    // 3. Calculate Progress for TODAY
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    double progressToday = 0;

    // Use a Set to track which unique days had the goal completed for streak calculation
    Set<DateTime> successfulDays = {};
    Map<DateTime, double> dailyTotals = {};

    for (var doc in entriesSnap.docs) {
      final data = doc.data();
      final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      final day = DateTime(timestamp.year, timestamp.month, timestamp.day);
      final amount = (data['amount'] ?? 0).toDouble();

      // Track total for this specific day
      dailyTotals[day] = (dailyTotals[day] ?? 0) + amount;

      if (day == today) {
        progressToday += amount;
      }

      // If the total for that day reached the goal, mark it as a successful day
      if (dailyTotals[day]! >= goal) {
        successfulDays.add(day);
      }
    }

    // 4. Calculate Streak (working backwards from today or yesterday)
    int streak = 0;
    DateTime checkDate = today;

    // If they haven't finished today yet, start checking from yesterday
    if (!successfulDays.contains(today)) {
      checkDate = today.subtract(const Duration(days: 1));
    }

    // Keep going back as long as the goal was met for that day
    while (successfulDays.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }


    // 5. Update the habit document with fresh data
    await habitRef.update({
      'progress': progressToday,
      'streak': streak,
      'goal_reached': progressToday >= goal,
    });
  }

  Stream<List<Habit>> watchCurrentUserHabits() {
    return _repository.watchCurrentUserHabits();
  }

  Stream<Map<String, num>> watchDailyProgress(String habitId) {
    return _repository.watchDailyProgress(habitId);
  }

  Stream<Map<String, num>> watchWeeklyProgress(String habitId, {String mode = 'Sum'}) {
    return _repository.watchWeeklyProgress(habitId, mode: mode);
  }

  Stream<Map<String, num>> watchMonthlyProgress(String habitId, {String mode = 'Sum'}) {
    return _repository.watchMonthlyProgress(habitId, mode: mode);
  }
}
