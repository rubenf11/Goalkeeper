import 'package:firebase_auth/firebase_auth.dart';

import '../data/repositories/user_repository.dart';

class UserService {
  final UserRepository _repository = UserRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<Map<String, dynamic>?> watchCurrentUserProfile() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _repository.watchUserDoc(uid).map((snap) => snap.data());
  }

  Stream<String?> watchCurrentUserPhotoUrl() {
    return watchCurrentUserProfile().map((data) {
      return data?['photoUrl'] as String? ?? _auth.currentUser?.photoURL;
    });
  }
}
