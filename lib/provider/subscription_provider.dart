// providers/subscription_provider.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/subscription_model.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionModel? _subscription;
  bool _isLoading = false;
  String? _error;

  SubscriptionModel? get subscription => _subscription;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─── Check if active ────────────────────────────────────────────────────────
  bool get isActive => _subscription != null && _subscription!.status == 'active';

  // ─── Fetch from API ─────────────────────────────────────────────────────────
  Future<void> fetchSubscription(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://glopa.org/glo/check_subscription.php?user_id=$userId'),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'success' && data['active'] == true) {
        _subscription = SubscriptionModel.fromJson(data['sub']);
      } else {
        _subscription = null;
      }
    } catch (e) {
      _error = 'Failed to load subscription';
      _subscription = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Set after successful subscribe ─────────────────────────────────────────
  void setSubscription(SubscriptionModel sub) {
    _subscription = sub;
    notifyListeners();
  }

  // ─── Clear on logout ─────────────────────────────────────────────────────────
  void clear() {
    _subscription = null;
    notifyListeners();
  }
}
