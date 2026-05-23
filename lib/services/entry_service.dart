import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/entry_repository.dart';
import '../data/repositories/storage_repository.dart';

class EntryService {
  final EntryRepository _repository = EntryRepository();
  final StorageRepository _storageRepository = StorageRepository();

  Future<String?> addEntrytoHabit({
    required String habitId,
    required double value,
    required int currentProgress,
    File? imageFile,
    String? caption,
  }) async {
    try {
      final Timestamp now = Timestamp.now();
      final String entryId = FirebaseFirestore.instance.collection('habits').doc().id;
      String? imageUrl;

      if (imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          return 'You must be logged in to upload images.';
        }

        final String path = '$userId/$habitId/$entryId.jpg';
        imageUrl = await _storageRepository.uploadImage(imageFile, path);
      }

      await _repository.saveEntry(
        habitId: habitId,
        entryId: entryId,
        value: value,
        timestamp: now,
        imageUrl: imageUrl,
        caption: caption,
      );

      int updatedProgress = currentProgress + value.toInt();
      await _repository.updateHabitProgress(
        habitId: habitId,
        newProgress: updatedProgress,
      );

      return null;
    } catch (e) {
      return "Error trying to save entry: $e";
    }
  }
}