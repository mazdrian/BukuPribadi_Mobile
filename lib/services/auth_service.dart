import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserModel> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw AuthException('Email and password are required');
      }

      if (password.length < 6) {
        throw AuthException('Password must be at least 6 characters');
      }

      if (!_isValidEmail(email)) {
        throw AuthException('Please enter a valid email address');
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw AuthException('Failed to create user');
      }

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await userCredential.user!.updateDisplayName(displayName);
      }

      // Create user document in Firestore
      final userModel = UserModel(
        id: userCredential.user!.uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userModel.id)
          .set(userModel.toJson());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  // Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw AuthException('Email and password are required');
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw AuthException('Sign in failed');
      }

      // Get user data from Firestore
      final doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!doc.exists) {
        // Create user document if it doesn't exist
        final userModel = UserModel(
          id: userCredential.user!.uid,
          email: email,
          displayName: userCredential.user!.displayName,
          createdAt: DateTime.now(),
        );
        await _firestore
            .collection('users')
            .doc(userModel.id)
            .set(userModel.toJson());
        return userModel;
      }

      return UserModel.fromJson(doc.data()!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Failed to sign out: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      if (email.isEmpty) {
        throw AuthException('Email is required');
      }

      if (!_isValidEmail(email)) {
        throw AuthException('Please enter a valid email address');
      }

      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  // Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Get user-friendly error messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
