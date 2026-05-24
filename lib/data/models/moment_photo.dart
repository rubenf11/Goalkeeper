import 'package:cloud_firestore/cloud_firestore.dart';

class MomentPhoto {
  const MomentPhoto({
    required this.imageUrl,
    required this.habitId,
    this.caption,
    this.timestamp,
  });

  final String imageUrl;
  final String habitId;
  final String? caption;
  final DateTime? timestamp;

  factory MomentPhoto.fromMap(
    Map<String, dynamic> map, {
    required String habitId,
  }) {
    final timestampValue = map['timestamp'];

    return MomentPhoto(
      imageUrl: map['imageUrl'] as String? ?? '',
      habitId: habitId,
      caption: map['caption'] as String?,
      timestamp: timestampValue is Timestamp ? timestampValue.toDate() : null,
    );
  }
}