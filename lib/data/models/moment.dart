import 'package:cloud_firestore/cloud_firestore.dart';

class MomentModel {
  final String momentId;
  final String entryId;
  final String imageUrl;
  final String caption;
  final Timestamp timestamp;

  MomentModel({
    required this.momentId,
    required this.entryId,
    required this.imageUrl,
    required this.caption,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'moment_id': momentId,
      'entry_id': entryId,
      'image_url': imageUrl,
      'caption': caption,
      'timestamp': timestamp,
    };
  }
}