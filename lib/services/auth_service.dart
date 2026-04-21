/// Authentication service
/// Placeholder for Firebase Authentication — swap in later
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  /// Simulate login
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Placeholder validation — replace with Firebase Auth
    if (email.isNotEmpty && password.length >= 6) {
      _isLoggedIn = true;
      return true;
    }
    return false;
  }

  /// Simulate signup
  Future<bool> signup(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (email.isNotEmpty && password.length >= 6) {
      _isLoggedIn = true;
      return true;
    }
    return false;
  }

  /// Logout
  void logout() {
    _isLoggedIn = false;
  }
}
