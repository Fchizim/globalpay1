import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────
class AppSettings {
  final int id;
  final String appName;
  final String logo;
  final String address;
  final String about;
  final String supportEmail;
  final String contactEmail;
  final String callNumber;
  final String whatsappNumber;
  final String themeMode;
  final String version;
  final String updatedAt;

  const AppSettings({
    required this.id,
    required this.appName,
    required this.logo,
    required this.address,
    required this.about,
    required this.supportEmail,
    required this.contactEmail,
    required this.callNumber,
    required this.whatsappNumber,
    required this.themeMode,
    required this.version,
    required this.updatedAt,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      id:              int.tryParse(json['id'].toString()) ?? 0,
      appName:         json['app_name']        ?? '',
      logo:            json['logo']            ?? '',
      address:         json['address']         ?? '',
      about:           json['about']           ?? '',
      supportEmail:    json['support_email']   ?? '',
      contactEmail:    json['contact_email']   ?? '',
      callNumber:      json['call_number']     ?? '',
      whatsappNumber:  json['whatsapp_number'] ?? '',
      themeMode:       json['theme_mode']      ?? 'light',
      version:         json['version']         ?? '1.0.0',
      updatedAt:       json['updated_at']      ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id':               id,
    'app_name':         appName,
    'logo':             logo,
    'address':          address,
    'about':            about,
    'support_email':    supportEmail,
    'contact_email':    contactEmail,
    'call_number':      callNumber,
    'whatsapp_number':  whatsappNumber,
    'theme_mode':       themeMode,
    'version':          version,
    'updated_at':       updatedAt,
  };

  /// Fallback empty settings
  static const empty = AppSettings(
    id:             0,
    appName:        '',
    logo:           '',
    address:        '',
    about:          '',
    supportEmail:   '',
    contactEmail:   '',
    callNumber:     '',
    whatsappNumber: '',
    themeMode:      'light',
    version:        '1.0.0',
    updatedAt:      '',
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────────────────────
class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings.empty;
  bool _isLoading = false;
  String? _error;

  AppSettings get settings   => _settings;
  bool        get isLoading  => _isLoading;
  String?     get error      => _error;

  Future<void> fetchSettings() async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      final res = await http.get(
        Uri.parse('https://glopa.org/glo/get_setting.php'),
        headers: {'Content-Type': 'application/json'},
      );

      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        if (map['status'] == 'success') {
          _settings = AppSettings.fromJson(
              map['settings'] as Map<String, dynamic>);
        } else {
          _error = map['message'] ?? 'Failed to load settings';
        }
      } else {
        _error = 'Server error ${res.statusCode}';
      }
    } catch (e) {
      _error = 'Network error: $e';
      debugPrint('SettingsProvider error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}