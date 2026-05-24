import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create User Auth
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> saveUserToFirestore(
    String uid,
    String name,
    String username,
    String email, {
    String? photoUrl,
  }) async {
    final Map<String, dynamic> userData = {
      'name': name,
      'username': username,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (photoUrl != null) {
      userData['photoUrl'] = photoUrl;
    }

    await _firestore.collection('users').doc(uid).set(userData);
  }

  Future<void> updateUserPhotoUrl(String uid, String photoUrl) async {
    await _firestore.collection('users').doc(uid).set({
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<UserCredential> loginWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }
}