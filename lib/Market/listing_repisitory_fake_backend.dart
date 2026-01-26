import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ListingRepository {
  static const String key = 'all_listings';

  Future<List<Map<String, dynamic>>> fetchListings() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(key);
    if (saved == null) return [];
    final decoded = jsonDecode(saved) as List;
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> addListing(Map<String, dynamic> listing) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await fetchListings();
    current.insert(0, listing); // newest first
    await prefs.setString(key, jsonEncode(current));
  }
}
