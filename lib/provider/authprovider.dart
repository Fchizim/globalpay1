import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/secure_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isCheckingAuth = false;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isCheckingAuth => _isCheckingAuth;

  Future<void> tryAutoLogin() async {
    _isCheckingAuth = true;
    notifyListeners();

    final user = await SecureStorageService.getUser();
    _user = user;

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