import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final storage = FlutterSecureStorage();
  final String tokenKey = 'jwt_token';

  // Save token
  Future<void> saveToken(String token) async {
    await storage.write(key: tokenKey, value: token);
  }

  // Get token
  Future<String?> getToken() async {
    return await storage.read(key: tokenKey);
  }

  // Remove token
  Future<void> deleteToken() async {
    await storage.delete(key: tokenKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    // print("HELLLLL YEAH (We're logged in)");
    final token = await getToken();
    return token != null;
  }
}