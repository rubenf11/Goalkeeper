import 'package:cloud_firestore/cloud_firestore.dart';

class Entry {
  final String id;
  final String userId;
  final double amount;
  final Timestamp timestamp;
  final String? imageUrl;
  final String? caption;

  Entry({
    required this.id,
    required this.userId,
    required this.amount,
    required this.timestamp,
    this.imageUrl,
    this.caption,
  });

  factory Entry.fromMap(Map<String, dynamic> map, {required String id}) {
    return Entry(
      id: id,
      userId: map['user_id'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      timestamp: map['timestamp'] ?? Timestamp.now(),
      imageUrl: map['imageUrl'] as String?,
      caption: map['caption'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'amount': amount,
      'timestamp': timestamp,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (caption != null) 'caption': caption,
    };
  }
}