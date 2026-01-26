import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class SecureStorageService {
  // SINGLE instance (recommended)
  static const _storage = FlutterSecureStorage();

  static const String _userKey = 'logged_in_user';

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

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    return await _storage.containsKey(key: _userKey);
  }

  /// Logout
  static Future<void> logout() async {
    await _storage.delete(key: _userKey);
  }

  /// Clear everything (optional)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}