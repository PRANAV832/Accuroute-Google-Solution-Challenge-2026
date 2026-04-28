import 'package:firebase_auth/firebase_auth.dart';

/// Authentication service — backed by Firebase Auth
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Current Firebase user (null if not signed in)
  User? get currentUser => _auth.currentUser;

  /// Whether a user is currently signed in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Stream of auth state changes (useful for reactive UI)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email & password
  /// Returns the [User] on success, throws [FirebaseAuthException] on failure
  Future<User?> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  /// Create a new account with email & password
  /// Returns the [User] on success, throws [FirebaseAuthException] on failure
  Future<User?> signup(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  /// Sign out
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Convert Firebase error codes to user-friendly messages
  static String friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return e.message ?? 'An unexpected error occurred.';
    }
  }
}
