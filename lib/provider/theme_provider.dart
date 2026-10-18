import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app's theme (light/dark) and remembers it between launches.
class ThemeProvider extends ChangeNotifier {
  static const String _key = 'isDarkMode';

  bool isDarkMode;

  ThemeProvider({this.isDarkMode = false});

  /// Reads the saved choice from the phone's storage.
  /// Call this once in main() before runApp().
  static Future<ThemeProvider> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return ThemeProvider(isDarkMode: prefs.getBool(_key) ?? false);
    } catch (e) {
      debugPrint('Could not load theme: $e');
      return ThemeProvider();
    }
  }

  /// Switches the theme immediately, then saves the new choice.
  Future<void> toggle() async {
    isDarkMode = !isDarkMode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, isDarkMode);
    } catch (e) {
      debugPrint('Could not save theme: $e');
    }
  }
}
