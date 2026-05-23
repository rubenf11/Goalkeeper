import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/moment_photo.dart';

class MomentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveMomentEntry({
    required String userId,
    required String habitId,
    required String imageUrl,
    String? caption,
  }) async {
    final Map<String, dynamic> payload = {
      'user_id': userId,
      'habit_id': habitId,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (caption != null && caption.trim().isNotEmpty) {
      payload['caption'] = caption.trim();
    }

    await _firestore.collection('habits').doc(habitId).collection('entries').add(payload);
  }

  Stream<List<MomentPhoto>> watchHabitMoments(String habitId) {
    return _firestore
        .collection('habits')
        .doc(habitId)
        .collection('entries')
        .snapshots()
        .map((snapshot) => _mapPhotos(snapshot.docs, habitId: habitId));
  }

  Stream<List<MomentPhoto>> watchMomentsForUser(String userId) {
    final controller = StreamController<List<MomentPhoto>>();
    Set<String> habitIds = <String>{};
    List<QueryDocumentSnapshot<Map<String, dynamic>>> entryDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    StreamSubscription? habitsSubscription;
    StreamSubscription? entriesSubscription;

    void emitPhotos() {
      final photos = entryDocs
          .where((doc) {
            final habitId = doc.reference.parent.parent?.id;
            if (habitId == null || !habitIds.contains(habitId)) {
              return false;
            }

            final data = doc.data();
            final imageUrl = data['imageUrl'] as String?;
            return imageUrl != null && imageUrl.isNotEmpty;
          })
          .map((doc) {
            final habitId = doc.reference.parent.parent?.id ?? '';
            return MomentPhoto.fromMap(doc.data(), habitId: habitId);
          })
          .toList();

      _sortPhotos(photos);

      if (!controller.isClosed) {
        controller.add(photos);
      }
    }

    habitsSubscription = _firestore
        .collection('habits')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      habitIds = snapshot.docs.map((doc) => doc.id).toSet();
      emitPhotos();
    }, onError: controller.addError);

    entriesSubscription = _firestore
        .collectionGroup('entries')
        .snapshots()
        .listen((snapshot) {
      entryDocs = snapshot.docs;
      emitPhotos();
    }, onError: controller.addError);

    controller.onCancel = () async {
      await habitsSubscription?.cancel();
      await entriesSubscription?.cancel();
    };

    return controller.stream;
  }

  List<MomentPhoto> _mapPhotos(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required String habitId,
  }) {
    final photos = docs
        .where((doc) {
          final imageUrl = doc.data()['imageUrl'] as String?;
          return imageUrl != null && imageUrl.isNotEmpty;
        })
        .map((doc) => MomentPhoto.fromMap(doc.data(), habitId: habitId))
        .toList();

    _sortPhotos(photos);
    return photos;
  }

  void _sortPhotos(List<MomentPhoto> photos) {
    photos.sort((first, second) {
      return (second.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(first.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0));
    });
  }
}