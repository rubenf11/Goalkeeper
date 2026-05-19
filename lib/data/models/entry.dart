import 'package:cloud_firestore/cloud_firestore.dart';

class EntryModel {
  final String entryId;
  final String habitId;
  final int value;
  final Timestamp timestamp;

  EntryModel({
    required this.entryId,
    required this.habitId,
    required this.value,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'entry_id': entryId,
      'habit_id': habitId,
      'value': value,
      'timestamp': timestamp,
    };
  }
}