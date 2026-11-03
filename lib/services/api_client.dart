import 'dart:convert';
import 'package:http/http.dart' as http;
import 'secure_storage_service.dart';

class ApiClient {
  static const baseUrl = 'https://glopa.org/glo';

  /// Set in main.dart: called when the server says the session is invalid.
  static void Function()? onUnauthorized;

  static Future<Map<String, String>> _headers() async {
    final token = await SecureStorageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (token != null && token.isNotEmpty) 'X-Auth-Token': token,
    };
  }

  static Future<Map<String, dynamic>> _handle(http.Response res) async {
    if (res.statusCode == 401) {
      // Clears both the saved user and the token
      await SecureStorageService.logout();
      onUnauthorized?.call();
      throw 'Session expired. Please log in again.';
    }

    Map<String, dynamic> decoded;
    try {
      final body = jsonDecode(res.body);
      if (body is! Map<String, dynamic>) {
        throw 'Unexpected server response.';
      }
      decoded = body;
    } catch (_) {
      throw 'Server error. Please try again.';
    }
    return decoded;
  }

  static Future<Map<String, dynamic>> get(String path) async => _handle(
    await http.get(
      Uri.parse('$baseUrl/$path'),
      headers: await _headers(),
    ),
  );

  static Future<Map<String, dynamic>> post(String path, Map body) async =>
      _handle(
        await http.post(
          Uri.parse('$baseUrl/$path'),
          headers: await _headers(),
          body: jsonEncode(body),
        ),
      );

  static Future<Map<String, dynamic>> put(String path, Map body) async =>
      _handle(
        await http.put(
          Uri.parse('$baseUrl/$path'),
          headers: await _headers(),
          body: jsonEncode(body),
        ),
      );

  static Future<Map<String, dynamic>> delete(String path, [Map? body]) async =>
      _handle(
        await http.delete(
          Uri.parse('$baseUrl/$path'),
          headers: await _headers(),
          body: body == null ? null : jsonEncode(body),
        ),
      );
}