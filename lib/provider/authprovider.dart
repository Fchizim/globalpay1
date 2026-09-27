import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:globalpay/provider/user_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../services/secure_storage_service.dart';

const _base = 'https://glopa.org/glo';

/// Hashes the email locally so the raw address is never re-sent on the
/// wire for this lightweight PIN check — only the hash travels.
String hashEmail(String email) =>
    sha256.convert(utf8.encode(email.trim().toLowerCase())).toString();

class AuthProvider extends ChangeNotifier {
  UserModel? _user;

  // A user loaded from secure storage that has NOT yet re-entered their
  // PIN this session. As long as this is non-null and _user is null, the
  // app shows the PIN-unlock screen instead of either the full login flow
  // or the authenticated app shell.
  UserModel? _pendingUser;

  bool _isCheckingAuth = false;
  String? _pinError;

  UserModel? get user => _user;
  UserModel? get pendingUser => _pendingUser;
  bool get isLoggedIn => _user != null;
  bool get needsPinUnlock => _user == null && _pendingUser != null;
  bool get isCheckingAuth => _isCheckingAuth;
  String? get pinError => _pinError;

  Future<void> tryAutoLogin(BuildContext context) async {
    _isCheckingAuth = true;
    notifyListeners();

    // ── One-time cache bust ──────────────────────────────────
    const storage = FlutterSecureStorage();
    final version = await storage.read(key: 'cache_version');
    if (version != '2') {
      // Old cache — delete it so user logs in fresh
      await SecureStorageService.clearAll();
      await storage.write(key: 'cache_version', value: '2');
      _isCheckingAuth = false;
      notifyListeners();
      return; // force user to log in again
    }
    // ─────────────────────────────────────────────────────────

    final user = await SecureStorageService.getUser();

    // Previously this immediately trusted the saved user and logged them
    // straight in. Now a saved user only becomes "pending" — they still
    // have to clear the PIN screen before _user is set and the rest of
    // the app treats them as authenticated.
    _pendingUser = user;

    _isCheckingAuth = false;
    notifyListeners();
  }

  /// Called from PinLoginPage once the person has typed 4 digits.
  /// Verifies against the backend (never on-device) and, on success,
  /// promotes the pending user to the active logged-in user.
  Future<bool> unlockWithPin(BuildContext context, String pin) async {
    if (_pendingUser == null) return false;
    _pinError = null;

    try {
      final res = await http
          .post(
            Uri.parse('$_base/verify_pin.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': _pendingUser!.userId,
              'email_hash': hashEmail(_pendingUser!.email),
              'pin': pin,
            }),
          )
          .timeout(const Duration(seconds: 20));

      // ── Temporary debug logging ──────────────────────────────
      // Shows exactly what pin_login.php sent back, so a bad endpoint,
      // an HTML error page, or an unexpected JSON shape is visible
      // instead of being silently relabeled as "Network error" below.
      // Safe to remove once the real cause is confirmed.
      debugPrint('PIN login status: ${res.statusCode}');
      debugPrint('PIN login body: ${res.body}');
      // ──────────────────────────────────────────────────────────

      final data = jsonDecode(res.body);

      if (data['status'] == 'success') {
        // Backend can return a refreshed user object (e.g. updated wallet
        // balance); fall back to the cached one if it doesn't.
        final refreshed = data['user'] != null
            ? UserModel.fromJson(data['user'])
            : _pendingUser!;

        _user = refreshed;
        _pendingUser = null;
        _pinError = null;

        await SecureStorageService.saveUser(refreshed);
        if (context.mounted) {
          Provider.of<UserProvider>(context, listen: false).setUser(refreshed);
        }

        notifyListeners();
        return true;
      } else {
        _pinError = data['message'] ?? 'Incorrect PIN';
        notifyListeners();
        return false;
      }
    } catch (e, st) {
      // ── Temporary debug logging ──────────────────────────────
      // Was `catch (_)`, which threw away the real exception and always
      // showed "Network error" to the user — even for things that had
      // nothing to do with the network (bad JSON from an HTML error page,
      // a missing field, UserModel.fromJson failing, etc). Logging the
      // real exception + stack trace here is what actually tells you
      // what's wrong. Safe to trim back down once diagnosed.
      debugPrint('PIN login exception: $e');
      debugPrintStack(stackTrace: st);
      // ──────────────────────────────────────────────────────────
      _pinError = 'Network error. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// "Switch Account" — abandons the pending saved session entirely and
  /// sends the person back to the normal login/signup flow.
  Future<void> switchAccount() async {
    await SecureStorageService.clearAll();
    _pendingUser = null;
    _user = null;
    _pinError = null;
    notifyListeners();
  }

  void setUser(UserModel user) {
    _user = user;
    _pendingUser = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await SecureStorageService.logout();
    _user = null;
    _pendingUser = null;
    notifyListeners();
  }
}
