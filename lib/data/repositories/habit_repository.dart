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

  Future<void> recalculateHabitStats(String habitId) async {
    final habitRef = _firestore.collection('habits').doc(habitId);
    final habitSnap = await habitRef.get();
    if (!habitSnap.exists) return;

    final habit = Habit.fromMap(habitSnap.data() as Map<String, dynamic>, id: habitSnap.id);

    // Fetch all entries ordered by timestamp
    final entriesSnap = await habitRef.collection('entries').orderBy('timestamp', descending: true).get();

    // Helper to compute the period start for a given date depending on frequency
    DateTime periodStartFor(DateTime dt, Frequency freq) {
      switch (freq) {
        case Frequency.daily:
          return DateTime(dt.year, dt.month, dt.day);
        case Frequency.weekly:
          // Monday as start of week
          final int weekday = dt.weekday; // Monday=1
          final DateTime monday = DateTime(dt.year, dt.month, dt.day).subtract(Duration(days: weekday - 1));
          return DateTime(monday.year, monday.month, monday.day);
        case Frequency.monthly:
          return DateTime(dt.year, dt.month, 1);
        case Frequency.yearly:
          return DateTime(dt.year, 1, 1);
      }
    }

    // Build totals per period
    final Map<DateTime, int> periodTotals = {};
    final DateTime now = DateTime.now();
    for (var doc in entriesSnap.docs) {
      final data = doc.data();
      final timestamp = data['timestamp'] as Timestamp?;
      final date = timestamp?.toDate() ?? now;
      final amount = (data['amount'] as num?)?.toInt() ?? 0;

      final DateTime key = periodStartFor(date, habit.frequency);
      periodTotals[key] = (periodTotals[key] ?? 0) + amount;
    }

    // Current period
    final DateTime currentPeriod = periodStartFor(now, habit.frequency);
    final int currentProgress = periodTotals[currentPeriod] ?? 0;
    final bool currentMet = currentProgress >= habit.goal;

    // Streak calculation: count consecutive previous periods that met the goal
    int streak = 0;
    DateTime checkPeriod = currentPeriod;
    if (!currentMet) {
      // move to previous period
      switch (habit.frequency) {
        case Frequency.daily:
          checkPeriod = checkPeriod.subtract(const Duration(days: 1));
          break;
        case Frequency.weekly:
          checkPeriod = checkPeriod.subtract(const Duration(days: 7));
          break;
        case Frequency.monthly:
          checkPeriod = DateTime(checkPeriod.year, checkPeriod.month - 1, 1);
          break;
        case Frequency.yearly:
          checkPeriod = DateTime(checkPeriod.year - 1, 1, 1);
          break;
      }
    }

    while (true) {
      final int tot = periodTotals[checkPeriod] ?? 0;
      if (tot >= habit.goal) {
        streak++;
        switch (habit.frequency) {
          case Frequency.daily:
            checkPeriod = checkPeriod.subtract(const Duration(days: 1));
            break;
          case Frequency.weekly:
            checkPeriod = checkPeriod.subtract(const Duration(days: 7));
            break;
          case Frequency.monthly:
            checkPeriod = DateTime(checkPeriod.year, checkPeriod.month - 1, 1);
            break;
          case Frequency.yearly:
            checkPeriod = DateTime(checkPeriod.year - 1, 1, 1);
            break;
        }
      } else {
        break;
      }
    }

    // Highest streak and daysCompleted across all periods
    int highestStreak = 0;
    int currentRun = 0;
    int daysCompleted = 0;
    final sortedPeriods = periodTotals.keys.toList()..sort((a, b) => a.compareTo(b));

    bool isConsecutive(DateTime prev, DateTime curr, Frequency freq) {
      switch (freq) {
        case Frequency.daily:
          return curr.difference(prev).inDays == 1;
        case Frequency.weekly:
          return curr.difference(prev).inDays == 7;
        case Frequency.monthly:
          return (curr.year == prev.year && curr.month == prev.month + 1) || (curr.year == prev.year + 1 && prev.month == 12 && curr.month == 1);
        case Frequency.yearly:
          return curr.year == prev.year + 1;
      }
    }

    DateTime? prev;
    for (final p in sortedPeriods) {
      final int tot = periodTotals[p] ?? 0;
      final bool met = tot >= habit.goal;
      if (met) {
        daysCompleted++;
        if (prev != null && isConsecutive(prev, p, habit.frequency)) {
          currentRun++;
        } else {
          currentRun = 1;
        }
        if (currentRun > highestStreak) highestStreak = currentRun;
      } else {
        currentRun = 0;
      }
      prev = p;
    }

    highestStreak = highestStreak < streak ? streak : highestStreak;

    try {
      print('recalculateHabitStats: habitId=$habitId');
      print('periodTotals keys=${periodTotals.keys.toList()}');
      print('currentProgress=$currentProgress, currentMet=$currentMet');
      print('computed streak=$streak, computed highestStreak=$highestStreak, habit.highestStreak=${habit.highestStreak}, daysCompleted=$daysCompleted');

      final updateData = {
        'progress': currentProgress,
        'goal_reached': currentMet,
        'streak': streak,
        'highest_streak': highestStreak,
        'days_completed': daysCompleted,
        'last_entry_at': FieldValue.serverTimestamp(),
      };

      print('recalculateHabitStats updateData=$updateData');
      await habitRef.update(updateData);
    } catch (e, st) {
      print('recalculateHabitStats ERROR for $habitId: $e');
      print(st);
      rethrow;
    }
  }

  Future<void> markHabitAsCompleted(String habitId) async {
    await _firestore.collection('habits').doc(habitId).update({
      'is_done': true,
    });
  }

  Future<void> setHabitCompletionStatus({
    required String habitId,
    required bool isDone,
  }) async {
    await _firestore.collection('habits').doc(habitId).update({
      'is_done': isDone,
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

  Stream<List<Habit>> watchCurrentUserActiveHabits() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Stream<List<Habit>>.value(const <Habit>[]);
    }

    return _firestore
        .collection('habits')
        .where('user_id', isEqualTo: currentUser.uid)
        .where('is_done', isEqualTo: false)
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
        Map<String, num> sumMap = {};

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final timestamp = data['timestamp'] as Timestamp?;
          if (timestamp == null) continue;

          final date = timestamp.toDate();
          final dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          final amount = (data['amount'] ?? 0);

          sumMap[dateString] = (sumMap[dateString] ?? 0) + amount;
        }
        return sumMap;
      });
  }

  Stream<Map<String,num>> watchWeeklyProgress(String habitId, {String mode = 'Sum'}) {
    final now = DateTime.now();

    final sixWeeksAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 42));

    return _firestore
      .collection('habits')
      .doc(habitId)
      .collection('entries')
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(sixWeeksAgo))
      .snapshots()
      .map((snapshot) {
        Map<String, num> weeklyMap = {};

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final timestamp = data['timestamp'] as Timestamp?;
          if (timestamp == null) continue;
          final date = timestamp.toDate();

          final monday = date.subtract(Duration(days: date.weekday - 1));
          final weekLabel = "${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}";

          final amount = (data['amount'] ?? 0);
          weeklyMap[weekLabel] = (weeklyMap[weekLabel] ?? 0) + amount;
        }

        if (mode == 'Average') {
          Map<String, num> averageMap = {};
          weeklyMap.forEach((key, sum) {
            averageMap[key] = double.parse((sum / 7).toStringAsFixed(1));
          });
          return averageMap;
        }
        return weeklyMap;
      });
  }

  Stream<Map<String,num>> watchMonthlyProgress(String habitId, {String mode = 'Sum'}) {
    final now = DateTime.now();

    final fourMonthsAgo = DateTime(now.year, now.month - 3, 1);

    return _firestore
      .collection('habits')
      .doc(habitId)
      .collection('entries')
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(fourMonthsAgo))
      .snapshots()
      .map((snapshots) {
        Map<String, num> sumMap = {};

        for (var doc in snapshots.docs) {
          final data = doc.data();
          final timestamp = data['timestamp'] as Timestamp?;
          if (timestamp == null) continue;

          final date = timestamp.toDate();

          final monthLabel = "${date.year}-${date.month.toString().padLeft(2, '0')}";

          final amount = (data['amount'] ?? 0);
          sumMap[monthLabel] = (sumMap[monthLabel] ?? 0) + amount;
        }

        if (mode == 'Average') {
          Map<String, num> averageMap = {};
          sumMap.forEach((key, sum) {
            final parts = key.split('-');
            if (parts.length == 2) {
              final year = int.tryParse(parts[0]) ?? now.year;
              final month = int.tryParse(parts[1]) ?? now.month;
              
              final daysInMonth = DateTime(year, month + 1, 0).day; 
              
              averageMap[key] = double.parse((sum / daysInMonth).toStringAsFixed(1));
            } else {
              averageMap[key] = double.parse((sum / 30).toStringAsFixed(1));
            }
          });
          return averageMap;
        }
        return sumMap;
      });
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchHabitsForUser(String userId) async {
    final snapshot = await _firestore.collection('habits').where('user_id', isEqualTo: userId).get();
    return snapshot.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>();
  }

  Stream<Habit?> watchHabit(String habitId) {
    return _firestore.collection('habits').doc(habitId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data() as Map<String, dynamic>;
      return Habit.fromMap(data, id: snap.id);
    });
  }
}
