import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class EntryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<void> saveEntry({
    required String habitId,
    required String entryId,
    required double value,
    required Timestamp timestamp,
  }) async {
    await _firestore
        .collection('habits')
        .doc(habitId)
        .collection('entries')
        .doc(entryId)
        .set({
      'value': value,
      'timestamp': timestamp,
    });
  }

  Future<void> updateHabitProgress({
    required String habitId,
    required int newProgress,
  }) async {
    await _firestore.collection('habits').doc(habitId).update({
      'progress': newProgress,
    });
  }
}