import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Custom AuthException class
class AuthException implements Exception {
  final String message;
  final String code;

  AuthException(this.message, this.code);

  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('Kein Benutzer angemeldet', 'no-user');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update user email
  Future<void> updateEmail(String newEmail, String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('Kein Benutzer angemeldet', 'no-user');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Update email
      await user.updateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle auth exceptions
  AuthException _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthException('Kein Benutzer mit dieser E-Mail gefunden.', e.code);
      case 'wrong-password':
        return AuthException('Falsches Passwort.', e.code);
      case 'email-already-in-use':
        return AuthException('Diese E-Mail wird bereits verwendet.', e.code);
      case 'weak-password':
        return AuthException('Das Passwort ist zu schwach.', e.code);
      case 'invalid-email':
        return AuthException('Ungültige E-Mail-Adresse.', e.code);
      case 'user-disabled':
        return AuthException('Dieser Benutzer wurde deaktiviert.', e.code);
      case 'too-many-requests':
        return AuthException('Zu viele Anfragen. Bitte versuchen Sie es später erneut.', e.code);
      case 'operation-not-allowed':
        return AuthException('Diese Operation ist nicht erlaubt.', e.code);
      case 'requires-recent-login':
        return AuthException('Bitte melden Sie sich erneut an, um fortzufahren.', e.code);
      default:
        return AuthException('Ein Fehler ist aufgetreten: ${e.message}', e.code);
    }
  }

  // Get user role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;
    final role = await getUserRole(user.uid);
    return role == 'admin';
  }
}
