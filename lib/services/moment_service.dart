import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/moment_photo.dart';
import '../data/repositories/moment_repository.dart';
import '../data/repositories/storage_repository.dart';

class MomentService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageRepository _storageRepository = StorageRepository();
  final MomentRepository _momentRepository = MomentRepository();

  Future<void> saveMoment({
    required String userId,
    required String habitId,
    required File imageFile,
  }) async {
    // 1. Generate a unique path/filename
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String path = '$userId/$habitId/$fileName';

    // 2. Upload to Supabase via Repository
    final String imageUrl = await _storageRepository.uploadImage(imageFile, path);

    // 3. Link this URL to your Habit/Moment in Firestore (Logic you already have)
    await _momentRepository.saveMomentEntry(
      userId: userId,
      habitId: habitId,
      imageUrl: imageUrl,
    );
  }

  Stream<List<MomentPhoto>> watchHabitMoments(String habitId) {
    return _momentRepository.watchHabitMoments(habitId);
  }

  Stream<List<MomentPhoto>> watchCurrentUserMoments() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream<List<MomentPhoto>>.value(const <MomentPhoto>[]);
    }

    return watchMomentsForUser(currentUser.uid);
  }

  Stream<List<MomentPhoto>> watchMomentsForUser(String userId) {
    return _momentRepository.watchMomentsForUser(userId);
  }
}