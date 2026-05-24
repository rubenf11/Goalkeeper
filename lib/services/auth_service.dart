import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/storage_repository.dart';

class AuthService {
  final AuthRepository _repository = AuthRepository();
  final StorageRepository _storageRepository = StorageRepository();

  Future<String?> registerUser({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _repository.registerWithEmailAndPassword(email, password);
      
      User? user = credential.user;
      if (user != null) {
        await user.updateDisplayName(name);
        
        await _repository.saveUserToFirestore(user.uid, name, username, email);
        
        return null;
      }
      return "Error while creating an account.";
      
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') return 'Password is too weak.';
      if (e.code == 'email-already-in-use') return 'This email address is already registered.';
      return e.message;
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _repository.loginWithEmailAndPassword(email, password);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential' || e.code == 'user-not-found' || e.code == 'wrong-password') {
        return 'Email or password incorrect.';
      }
      return e.message;
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<String> updateProfilePhoto(File imageFile) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('User not authenticated.');
      }

      final String photoUrl = await _storageRepository.uploadProfileImage(imageFile, user.uid);
      await user.updatePhotoURL(photoUrl);
      await user.reload();
      await _repository.updateUserPhotoUrl(user.uid, photoUrl);

      return photoUrl;
    } catch (e) {
      throw Exception('Error updating profile photo: $e');
    }
  }
}