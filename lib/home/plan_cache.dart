
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PlansCache extends ChangeNotifier {
  PlansCache._();
  static final PlansCache instance = PlansCache._();

  Map<String, dynamic>? _rawData;
  bool _isFetching = false;

  Map<String, dynamic>? get rawData => _rawData;
  bool get isReady => _rawData != null;
  bool get isFetching => _isFetching;

  Future<void> prefetch() async {
    if (_rawData != null || _isFetching) return;
    _isFetching = true;
    notifyListeners(); // ← tell listeners fetching started
    try {
      final response = await http.post(
        Uri.parse('https://glopa.org/glo/get_plans.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fetch': 'DATA'}),
      ).timeout(const Duration(seconds: 15));

      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        final status  = (decoded['status'] ?? '').toString().toLowerCase();
        if (status == 'successful') {
          _rawData = decoded;
          debugPrint('PlansCache: prefetch complete');
        }
      }
    } catch (e) {
      debugPrint('PlansCache prefetch error: $e');
    } finally {
      _isFetching = false;
      notifyListeners(); // ← tell listeners done
    }
  }

  void setData(Map<String, dynamic> data) {
    _rawData = data;
    notifyListeners();
  }

  void invalidate() {
    _rawData = null;
    notifyListeners();
  }
}
