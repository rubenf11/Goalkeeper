import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/habit.dart';

class HabitRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Habit> createHabit(Habit habit) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw StateError('User must be signed in to create a habit.');
    }

    final String habitId = habit.habitId.isEmpty
        ? _firestore.collection('habits').doc().id
        : habit.habitId;

    final Habit habitToSave = habit.copyWith(
      habitId: habitId,
      userId: habit.userId.isEmpty ? currentUser.uid : habit.userId,
    );

    await _firestore.collection('habits').doc(habitId).set(habitToSave.toMap());

    final savedHabitSnapshot = await _firestore
        .collection('habits')
        .doc(habitId)
        .get();
    final savedHabitData = savedHabitSnapshot.data();

    if (savedHabitData != null) {
      return Habit.fromMap(savedHabitData, id: savedHabitSnapshot.id);
    }

    return habitToSave;
  }

  Future<void> addEntry(String habitId, int amount) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw StateError('User not authenticated');

    final habitRef = _firestore.collection('habits').doc(habitId);

    // 1. Add the entry to the subcollection
    await habitRef.collection('entries').add({
      'value': amount,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Recalculate stats
    await recalculateHabitStats(habitId);
  }

  Future<void> recalculateHabitStats(String habitId) async {
    final habitRef = _firestore.collection('habits').doc(habitId);
    final habitSnap = await habitRef.get();
    if (!habitSnap.exists) return;

    final habit = Habit.fromMap(habitSnap.data() as Map<String, dynamic>, id: habitSnap.id);
    
    // Fetch all entries
    final entriesSnap = await habitRef.collection('entries').orderBy('timestamp', descending: true).get();
    
    final Map<DateTime, int> dailyTotals = {};
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    for (var doc in entriesSnap.docs) {
      final data = doc.data();

      final timestamp = data['timestamp'] as Timestamp?;

      final date = timestamp?.toDate() ?? now;

      final dayKey = DateTime(date.year, date.month, date.day);
      final amount = (data['value'] as num?)?.toInt() ?? 0;

      dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0) + amount;
    }

    // 1. Calculate Today's Progress
    final int todayProgress = dailyTotals[today] ?? 0;
    final bool isGoalReachedToday = todayProgress >= habit.goal;

    // 2. Calculate Streak
    int streak = 0;
    DateTime checkDate = today;

    // If today hasn't reached the goal, the streak might still be alive from yesterday
    if (!isGoalReachedToday) {
      checkDate = today.subtract(const Duration(days: 1));
    }

    while (true) {
      final int dayTotal = dailyTotals[checkDate] ?? 0;
      if (dayTotal >= habit.goal) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        // Streak broken
        break;
      }
    }

    // Special case: if today met the goal, it's counted. 
    // The loop above already handles it if we start from today and it's met.

    await habitRef.update({
      'progress': todayProgress,
      'goal_reached': isGoalReachedToday,
      'streak': streak,
      'last_entry_at': FieldValue.serverTimestamp(),
      'is_done': isGoalReachedToday,
    });
  }

  Stream<List<Habit>> watchCurrentUserHabits() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Stream<List<Habit>>.value(const <Habit>[]);
    }

    return _firestore
        .collection('habits')
        .where('user_id', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
          final habits = snapshot.docs
              .map((doc) => Habit.fromMap(doc.data(), id: doc.id))
              .toList();

          habits.sort(
            (first, second) =>
                (second.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                    .compareTo(
                      first.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                    ),
          );

          return habits;
        });
  }

  Stream<Map<String, num>> watchDailyProgress(String habitId) {
    final now = DateTime.now();
    final sevenDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));

    return _firestore
      .collection('habits')
      .doc(habitId)
      .collection('entries')
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
      .snapshots()
      .map((snapshot) {
        Map<String, num> progressMap = {};

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final timestamp = data['timestamp'] as Timestamp?;
          if (timestamp == null) continue;

          final date = timestamp.toDate();
          final dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          final amount = (data['value'] ?? 0);

          progressMap[dateString] = (progressMap[dateString] ?? 0) + amount;
        } 
        return progressMap;
      });
  }
}
