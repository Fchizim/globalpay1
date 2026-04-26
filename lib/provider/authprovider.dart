import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:globalpay/provider/user_provider.dart';
import 'package:provider/provider.dart';
// import '../home/electricity.dart';
import '../models/user_model.dart';
import '../services/secure_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isCheckingAuth = false;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isCheckingAuth => _isCheckingAuth;

  Future<void> tryAutoLogin(BuildContext context) async {
    _isCheckingAuth = true;
    notifyListeners();

    // ── One-time cache bust ──────────────────────────────────
    const _storage = FlutterSecureStorage();
    final version = await _storage.read(key: 'cache_version');
    if (version != '2') {
      // Old cache — delete it so user logs in fresh
      await SecureStorageService.clearAll();
      await _storage.write(key: 'cache_version', value: '2');
      _isCheckingAuth = false;
      notifyListeners();
      return; // force user to log in again
    }
    // ─────────────────────────────────────────────────────────

    final user = await SecureStorageService.getUser();
    _user = user;

    if (user != null) {
      await SecureStorageService.saveUser(user);
      Provider.of<UserProvider>(context, listen: false).setUser(user);
    }

    _isCheckingAuth = false;
    notifyListeners();
  }

  /// 🔥 ADD THIS
  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  Future<void> logout() async {
    await SecureStorageService.logout();
    _user = null;
    notifyListeners();
  }
}