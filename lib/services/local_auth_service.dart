import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'local_database_service.dart';

class LocalAuthService {
  final LocalDatabaseService _db = LocalDatabaseService.instance;
  static const String _userIdKey = 'current_user_id';
  static const String _userEmailKey = 'current_user_email';

  // Get current user ID from shared preferences
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    final userId = await getCurrentUserId();
    if (userId == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_userEmailKey);
    if (email == null) return null;

    return await _db.getUserByEmail(email);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final userId = await getCurrentUserId();
    return userId != null;
  }

  // Sign up with email and password
  Future<UserModel> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      // Validation
      if (email.isEmpty || password.isEmpty) {
        throw AuthException('Email and password are required');
      }

      if (password.length < 6) {
        throw AuthException('Password must be at least 6 characters');
      }

      if (!_isValidEmail(email)) {
        throw AuthException('Please enter a valid email address');
      }

      // Check if email already exists
      final emailExists = await _db.emailExists(email);
      if (emailExists) {
        throw AuthException(
            'An account already exists with this email address');
      }

      // Create user
      final user = await _db.createUser(
        email: email,
        password: password,
        displayName: displayName,
      );

      // Save session
      await _saveUserSession(user);

      return user;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to create account: ${e.toString()}');
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

      // Validate credentials
      final isValid = await _db.validateUserCredentials(email, password);
      if (!isValid) {
        throw AuthException('Invalid email or password');
      }

      // Get user
      final user = await _db.getUserByEmail(email);
      if (user == null) {
        throw AuthException('User not found');
      }

      // Save session
      await _saveUserSession(user);

      return user;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to sign in: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
  }

  // Save user session
  Future<void> _saveUserSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, user.id);
    await prefs.setString(_userEmailKey, user.email);
  }

  // Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
