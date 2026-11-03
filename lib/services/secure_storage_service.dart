import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class SecureStorageService {
  // SINGLE instance (recommended)
  static const _storage = FlutterSecureStorage();

  static const String _userKey = 'logged_in_user';
  static const String _tokenKey = 'api_token';

  // ───────────── USER ─────────────

  /// Save user
  static Future<void> saveUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await _storage.write(key: _userKey, value: userJson);
  }

  /// Get user
  static Future<UserModel?> getUser() async {
    final userString = await _storage.read(key: _userKey);

    if (userString == null) return null;

    final Map<String, dynamic> json =
    jsonDecode(userString) as Map<String, dynamic>;

    return UserModel.fromJson(json);
  }

  // ───────────── TOKEN ─────────────

  /// Save API token (called right after a successful login)
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Get API token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Clear only the token
  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // ───────────── SESSION ─────────────

  /// Logged in only if BOTH the user and a token exist.
  /// Users who logged in before this update have no token,
  /// so they are treated as logged out and must log in once more.
  static Future<bool> isLoggedIn() async {
    final hasUser = await _storage.containsKey(key: _userKey);
    final token = await _storage.read(key: _tokenKey);
    return hasUser && token != null && token.isNotEmpty;
  }

  /// Logout: remove the user AND the token
  static Future<void> logout() async {
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _tokenKey);
  }

  /// Clear everything (optional)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}