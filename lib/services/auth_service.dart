import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/auth_repository.dart';

class AuthService {
  final AuthRepository _repository = AuthRepository();

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
}