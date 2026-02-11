import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/secure_storage_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;

  Future<void> setUser(UserModel user) async {
    _user = user;

    // save updated user globally
    await SecureStorageService.saveUser(user);

    notifyListeners();
  }

  Future<void> updateUser(UserModel user) async {
    _user = user;

    // persist update
    await SecureStorageService.saveUser(user);

    notifyListeners();
  }

  Future<void> clear() async {
    _user = null;

    await SecureStorageService.clearAll();

    notifyListeners();
  }
}