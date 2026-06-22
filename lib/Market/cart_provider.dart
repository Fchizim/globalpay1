import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CartProvider extends ChangeNotifier {
  int _count = 0;
  int get count => _count;

  static const String _base = 'https://glopa.org/glo/cart.php';

  // Call this on app start / login to sync count from backend
  Future<void> fetchCount(String userId) async {
    try {
      final res = await http.get(Uri.parse('$_base?action=get&user_id=$userId'));
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        _count = (data['count'] as num).toInt();
        notifyListeners();
      }
    } catch (_) {}
  }

  // Optimistic increment — called right after successful addToCart
  void increment() {
    _count++;
    notifyListeners();
  }

  // Decrement (when item removed)
  void decrement() {
    if (_count > 0) _count--;
    notifyListeners();
  }

  // Set exact value (after cart screen loads full list)
  void setCount(int value) {
    _count = value;
    notifyListeners();
  }

  // Clear (after order placed)
  void clear() {
    _count = 0;
    notifyListeners();
  }
}