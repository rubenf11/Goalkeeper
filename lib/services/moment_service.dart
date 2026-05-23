import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/repositories/storage_repository.dart';

class MomentService {
  final StorageRepository _storageRepository = StorageRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    await _firestore.collection('habits').doc(habitId).collection('entries').add({
    'imageUrl': imageUrl,
    });
  }
}