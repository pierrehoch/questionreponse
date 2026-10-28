import 'package:firebase_auth/firebase_auth.dart';
import 'package:question_reponse/features/auth/domain/auth_failure.dart';
import 'package:question_reponse/features/auth/domain/auth_repository.dart';
import 'package:question_reponse/features/auth/domain/auth_user.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  @override
  Stream<AuthUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(
      (user) => user == null ? null : AuthUser(id: user.uid, email: user.email),
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseError(error);
    }
  }

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseError(error);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseError(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseError(error);
    }
  }

  AuthFailure _mapFirebaseError(FirebaseAuthException error) {
    final message = switch (error.code) {
      'invalid-email' => 'Cette adresse e-mail est invalide.',
      'user-disabled' => 'Ce compte a été désactivé.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Adresse e-mail ou mot de passe incorrect.',
      'email-already-in-use' => 'Un compte utilise déjà cette adresse e-mail.',
      'weak-password' => 'Le mot de passe doit contenir au moins 6 caractères.',
      'too-many-requests' =>
        'Trop de tentatives. Veuillez réessayer plus tard.',
      'network-request-failed' =>
        'Connexion impossible. Vérifiez votre accès à Internet.',
      'operation-not-allowed' => 'La connexion par e-mail n’est pas activée.',
      _ => 'Une erreur d’authentification est survenue.',
    };

    return AuthFailure(message);
  }
}
