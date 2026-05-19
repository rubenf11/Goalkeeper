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
    final batch = _firestore.batch();

    // 1. Increment progress
    batch.update(habitRef, {
      'progress': FieldValue.increment(amount),
    });

    // 2. Create entry record
    final entryRef = habitRef.collection('entries').doc();
    batch.set(entryRef, {
      'amount': amount,
      'timestamp': FieldValue.serverTimestamp(),
      'user_id': currentUser.uid,
    });

    await batch.commit();
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
}
