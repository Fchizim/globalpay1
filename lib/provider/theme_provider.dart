import 'package:flutter/material.dart';

/// Holds theme state on its own. Previously dark-mode was a plain bool
/// living in MyApp's State, but MyApp's build() sat inside a
/// Consumer<AuthProvider> — so every unrelated AuthProvider notification
/// (a PIN error clearing, isCheckingAuth flipping, etc.) rebuilt the
/// entire MaterialApp too. If one of those rebuilds landed mid-tap on the
/// dark-mode switch, the tap could be lost, which is why it sometimes
/// took several taps to register. Giving theme its own ChangeNotifier
/// means a toggle only triggers listeners of ThemeProvider, and an
/// AuthProvider change no longer touches theme at all.
class ThemeProvider extends ChangeNotifier {
  bool isDarkMode = false;

  void toggle() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }
}
