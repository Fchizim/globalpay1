import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:globalpay/profile_details/tier2_completion.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import '../models/kyc_model.dart';
import '../provider/user_provider.dart';
import '../provider/kyc_provider.dart';
// import '../model/kyc_model.dart';


class Tiertwo extends StatefulWidget {
  const Tiertwo({super.key});

  @override
  State<Tiertwo> createState() => _TiertwoState();
}


class _TiertwoState extends State<Tiertwo> {
  final TextEditingController ninController = TextEditingController();
  final TextEditingController bvnController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  File? _ninImage;
  bool isValid = false;
  String userId = "";
  bool loading = false;


  Future<bool> _submitTier2() async {
    if (_ninImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload your NIN image")),
      );
      return false;
    }

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User session expired. Please login again.")),
      );
      return false;
    }

    if (loading) return false;

    setState(() => loading = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://glopa.org/glo/tier_2.php'),
      )
        ..fields['user_id'] = userId
        ..fields['nin_number'] = ninController.text
        ..fields['bvn'] = bvnController.text
        ..files.add(await http.MultipartFile.fromPath('nin_image', _ninImage!.path));

      print("Sending request with fields: ${request.fields}");
      print("Sending file: ${_ninImage!.path}");

      final response = await request.send();

      print("HTTP status: ${response.statusCode}");

      final res = await http.Response.fromStream(response);

      print("Raw response body: ${res.body}");

      final data = jsonDecode(res.body);

      if (data['status'] == 'success') {

        /// UPDATE PROVIDER HERE (REAL SERVER VALUES)
        Provider.of<KycProvider>(context, listen: false).setKyc(
          KycModel(
            tier: data['tier'],
            status: data['kyc_status'],
            kycId: data['kyc_id'],
          ),
        );

        print("Upload successful, kyc_id: ${data['kyc_id']}");
        return true;
      } else {
        print("Server error message: ${data['message']}");
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(data['message'])));
        return false;
      }
    } catch (e, stack) {
      print("Exception during upload: $e");
      print(stack);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      return false;
    } finally {
      setState(() => loading = false);
    }
  }


  @override
  void initState() {
    super.initState();
    ninController.addListener(_validate);
    bvnController.addListener(_validate);
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final providerUser =
        Provider.of<UserProvider>(context, listen: false).user;

    if (providerUser != null) {
      userId = providerUser.userId;
    } else {
      userId = await storage.read(key: "userId") ?? "";
    }

    setState(() {});
  }

  void _validate() {
    setState(() {
      isValid =
          ninController.text.length == 11 &&
              bvnController.text.length == 11 &&
              _ninImage != null;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        _ninImage = File(image.path);
      });
      _validate();
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            children: [
              const Center(
                child: Text(
                  "Select Option",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.deepOrange),
                title: const Text("Snap Photo"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.deepOrange),
                title: const Text("Upload from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    ninController.dispose();
    bvnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tier 2"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter your details to upgrade to Tier 2 (Elite).",
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 25),

            GestureDetector(
              onTap: _showImagePickerOptions,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _ninImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(_ninImage!, fit: BoxFit.cover),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_circle_outline,
                        size: 40, color: Colors.deepOrange),
                    SizedBox(height: 10),
                    Text(
                      "Upload your NIN Photo",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            TextField(
              controller: ninController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter NIN",
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: bvnController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter BVN",
              ),
            ),
            const SizedBox(height: 30),

            GestureDetector(
              onTap: (isValid && !loading)
                  ? () async {
                bool success = await _submitTier2();

                if (success) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          Tier2Completion(nin: ninController.text, submittedTime: ''),
                    ),
                  );
                }
              }
                  : null,
              child: Container(
                height: 55,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isValid && !loading
                      ? Colors.deepOrange
                      : Colors.deepOrange.shade300,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: loading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                      : Text(
                    "Next",
                    style: TextStyle(
                      color: isValid ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}