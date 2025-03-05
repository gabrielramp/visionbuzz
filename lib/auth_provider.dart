import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;

  AuthProvider() {
    // Check login status when created
    _checkLoginStatus();
  }

  bool get isLoggedIn => _isLoggedIn;
  AuthService get authService => _authService;

  Future<void> _checkLoginStatus() async {
    _isLoggedIn = await _authService.isLoggedIn();
    notifyListeners();
  }

  // Login with token
  Future<void> login(String token) async {
    await _authService.saveToken(token);
    _isLoggedIn = true;
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    await _authService.deleteToken();
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<String?> getToken() async {
    notifyListeners();
    var token = _authService.getToken();
    return _authService.getToken();
  }
}
