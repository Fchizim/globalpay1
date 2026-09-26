import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserBalance extends ChangeNotifier {
  UserBalance._() {
    _loadHiddenState();
  }
  static final UserBalance instance = UserBalance._();

  static const String _hiddenKey = 'balance_is_hidden';

  double _balance = 0;
  double get balance => _balance;

  set balance(double value) {
    if (_balance == value) return;
    _balance = value;
    notifyListeners();
  }

  bool _isHidden = false;
  bool get isHidden => _isHidden;

  Future<void> _loadHiddenState() async {
    final prefs = await SharedPreferences.getInstance();
    _isHidden = prefs.getBool(_hiddenKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleHidden() async {
    _isHidden = !_isHidden;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hiddenKey, _isHidden);
  }
}
