import 'package:flutter/foundation.dart';

class UserBalance extends ChangeNotifier {
  UserBalance._();
  static final UserBalance instance = UserBalance._();

  double _balance = 0;
  double get balance => _balance;

  set balance(double value) {
    if (_balance == value) return;
    _balance = value;
    notifyListeners();
  }
}