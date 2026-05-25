import 'package:cloud_firestore/cloud_firestore.dart';
import 'habit_repository.dart';
import '../models/entry.dart';

class EntryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HabitRepository _habitRepository = HabitRepository();
  
  Future<void> saveEntry({
    required String habitId,
    required String entryId,
    required String userId,
    required double amount,
    required Timestamp timestamp,
    String? imageUrl,
    String? caption,
  }) async {
    final Map<String, dynamic> payload = {
      'user_id': userId,
      'amount': amount,
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

  Stream<List<Entry>> watchHabitEntries(String habitId) {
    return _firestore
        .collection('habits')
        .doc(habitId)
        .collection('entries')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Entry.fromMap(doc.data(), id: doc.id);
          }).toList();
        });
  }

  Future<Entry?> getEntryByImageUrl(String habitId, String imageUrl) async {
    try {
      final snapshot = await _firestore
          .collection('habits')
          .doc(habitId)
          .collection('entries')
          .where('imageUrl', isEqualTo: imageUrl)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return Entry.fromMap(doc.data(), id: doc.id);
      }
    } catch (e) {
      print("Erro ao buscar entry pela imagem: $e");
    }
    return null;
  }
}