import 'package:cloud_firestore/cloud_firestore.dart';
import 'habit_repository.dart';

class EntryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HabitRepository _habitRepository = HabitRepository();
  
  Future<void> saveEntry({
    required String habitId,
    required String entryId,
    required double value,
    required Timestamp timestamp,
    String? imageUrl,
    String? caption,
  }) async {
    final Map<String, dynamic> payload = {
      'value': value,
      'timestamp': timestamp,
    };

    if (imageUrl != null) {
      payload['imageUrl'] = imageUrl;
    }

    if (caption != null && caption.trim().isNotEmpty) {
      payload['caption'] = caption.trim();
    }

    await _firestore
        .collection('habits')
        .doc(habitId)
        .collection('entries')
        .doc(entryId)
        .set(payload);

    await _habitRepository.recalculateHabitStats(habitId);
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