import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:globalpay/profile_details/tier2_completion.dart';

class Tiertwo extends StatefulWidget {
  const Tiertwo({super.key});

  @override
  State<Tiertwo> createState() => _TiertwoState();
}

class _TiertwoState extends State<Tiertwo> {
  final TextEditingController ninController = TextEditingController();
  final TextEditingController bvnController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _ninImage;
  bool isValid = false;

  @override
  void initState() {
    super.initState();
    ninController.addListener(_validate);
    bvnController.addListener(_validate);
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

            // NIN PHOTO
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

            // NIN FIELD
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

            // BVN FIELD
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

            // NEXT BUTTON
            GestureDetector(
              onTap: isValid
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        Tier2Completion(nin: ninController.text, submittedTime: '',),
                  ),
                ).then((value) {
                  if (value == true) {
                    Navigator.pop(context, true);
                  }
                });
              }
                  : null,
              child: Container(
                height: 55,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isValid
                      ? Colors.deepOrange
                      : Colors.deepOrange.shade300,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
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
