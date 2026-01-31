import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ProfileService {
  static const String baseUrl = "https://glopa.org/glo"; // your API folder

  static Future<UserModel?> getProfile(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get-profile.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          return UserModel.fromJson(data['user']);
        } else {
          print("Profile fetch failed: ${data['message']}");
        }
      } else {
        print("HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }

    return null;
  }
}