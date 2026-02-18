import 'dart:convert';
import 'dart:io';
import 'package:globalpay/services/secure_storage_service.dart';
import 'package:http/http.dart' as http;
import '../models/kyc_model.dart';
import '../models/user_model.dart';
import '../provider/kyc_provider.dart';

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

  static Future<bool> submitTier2({
    required String userId,
    required String nin,
    required String bvn,
    required File ninImage,
    required KycProvider provider,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/tier_2.php'),
      );

      request.fields['user_id'] = userId;
      request.fields['nin_number'] = nin;
      request.fields['bvn'] = bvn;
      request.files.add(await http.MultipartFile.fromPath('nin_image', ninImage.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        // Update provider with new tier info
        provider.setKyc(KycModel(tier: "2", status: "pending", kycId: ''));
        return true;
      } else {
        print("Tier 2 submission failed: ${data['message']}");
        return false;
      }
    } catch (e) {
      print("Error submitting Tier 2 KYC: $e");
      return false;
    }
  }

  // ---------------- Tier 3 Submission ----------------
  static Future<bool> submitTier3({
    required String userId,
    required String homeAddress,
    required File selfie,
    required File addressProof,
    required KycProvider provider,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/tier_3.php'),
      );

      request.fields['user_id'] = userId;
      request.fields['home_address'] = homeAddress;
      request.files.add(await http.MultipartFile.fromPath('selfie', selfie.path));
      request.files.add(await http.MultipartFile.fromPath('address_proof', addressProof.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        provider.setKyc(KycModel(tier: "3", status: "pending", kycId: ''));
        return true;
      } else {
        print("Tier 3 submission failed: ${data['message']}");
        return false;
      }
    } catch (e) {
      print("Error submitting Tier 3 KYC: $e");
      return false;
    }
  }


  static Future<void> loadKyc({
    required String userId,
    required KycProvider provider,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/get_kyc_status.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId}),
    );

    final data = jsonDecode(res.body);

    if (data["status"] == "success") {
      provider.setKyc(KycModel.fromJson(data));
    }
  }




  static Future<UserModel?> updateUser({
    required String userId,
    required Map<String, dynamic> body,
  }) async {
    try {
      // Include user_id in body
      body['user_id'] = userId;

      final res = await http.put(
        Uri.parse('$baseUrl/userupdate.php'),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);

      if (data['status'] == 'success') {
        final user = UserModel.fromJson(data['user']);

        // Save updated user locally
        await SecureStorageService.saveUser(user);

        return user;
      } else {
        print("Update failed: ${data['message']}");
      }
    } catch (e) {
      print("Error updating profile: $e");
    }

    return null;
  }

}