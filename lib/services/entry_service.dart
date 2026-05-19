import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/entry_repository.dart';

class EntryService {
  final EntryRepository _repository = EntryRepository();

  Future<String?> addEntrytoHabit({
    required String habitId,
    required double value,
    required int currentProgress,
    File? imageFile,
  }) async {
    try {
      final Timestamp now = Timestamp.now();
      final String entryId = FirebaseFirestore.instance.collection('habits').doc().id;

      await _repository.saveEntry(
        habitId: habitId,
        entryId: entryId,
        value: value,
        createdAt: now,
      );

      /*if (imageFile != null) {
        final String momentId = FirebaseFirestore.instance.collection('habits').doc().id;
 
        String imageUrl = await _repository.uploadMomentImage(
          habitId: habitId,
          momentId: momentId,
          imageFile: imageFile,
        );

        await _repository.saveMoment(
          habitId: habitId,
          momentId: momentId,
          entryId: entryId,
          imageUrl: imageUrl,
          createdAt: now,
        );
      }*/

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