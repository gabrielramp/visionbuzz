import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'auth_service.dart';
import 'contacts.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;
  String _username = "";

  AuthProvider() {
    // Check login status when created
    _initializeAuthState();
  }

  bool get isLoggedIn => _isLoggedIn;
  String get username => _username;
  AuthService get authService => _authService;

  Future<void> _initializeAuthState() async {
    _isLoggedIn = await _authService.isLoggedIn();
    
    if (_isLoggedIn) {
      // Try to extract username from token
      final token = await _authService.getToken();
      if (token != null) {
        _extractUsernameFromToken(token);
      }
    }
    
    notifyListeners();
  }

  // Extract username from JWT token if possible
  void _extractUsernameFromToken(String token) {
    try {
      // JWT token has three parts: header.payload.signature
      final parts = token.split('.');
      if (parts.length == 3) {
        // Decode the payload (middle part)
        String normalizedPayload = base64Url.normalize(parts[1]);
        Map<String, dynamic> payload = json.decode(
          utf8.decode(base64Url.decode(normalizedPayload))
        );
        
        // Try to extract username from common JWT fields
        if (payload.containsKey('username')) {
          _username = payload['username'];
        } else if (payload.containsKey('sub')) {
          _username = payload['sub'];
        } else if (payload.containsKey('preferred_username')) {
          _username = payload['preferred_username'];
        } else if (payload.containsKey('email')) {
          // Use email as fallback, without the domain
          final email = payload['email'];
          _username = email.toString().split('@')[0];
        }
      }
    } catch (e) {
      print('Error extracting username from token: $e');
      _username = "User"; // Fallback
    }
  }

  // Login with token
  Future<void> login(String token, {String? username}) async {
    await _authService.saveToken(token);
    _isLoggedIn = true;
    
    // Set username from parameter if provided
    if (username != null && username.isNotEmpty) {
      _username = username;
    } else {
      // Try to extract from token
      _extractUsernameFromToken(token);
    }
    
    notifyListeners();
  }

  // Update username
  void setUsername(String username) {
    _username = username;
    notifyListeners();
  }

  // Logout - now sets state immediately before token deletion
  Future<void> logout() async {
    // Set logged out state first (important to avoid loading state)
    _isLoggedIn = false;
    _username = "";
    notifyListeners();
    
    // Clear contact cache
    ContactsCache.reset();
    
    // Then clear token
    await _authService.deleteToken();
  }

  Future<String?> getToken() async {
    return _authService.getToken();
  }
}
