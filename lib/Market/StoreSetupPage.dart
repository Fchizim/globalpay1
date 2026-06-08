import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:globalpay/Market/editors_profile.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../provider/user_provider.dart';

class StoreSetupPage extends StatefulWidget {
  const StoreSetupPage({super.key});

  @override
  State<StoreSetupPage> createState() => _StoreSetupPageState();
}

class _StoreSetupPageState extends State<StoreSetupPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController    = TextEditingController();
  final TextEditingController _bioController     = TextEditingController();
  String? _selectedCategory;

  final TextEditingController _phoneController   = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _rcController      = TextEditingController();
  final TextEditingController _taxController     = TextEditingController();

  final List<String> _categories = [
    'Fashion', 'Electronics', 'Food & Groceries',
    'Beauty & Health', 'Home & Office', 'Services',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
    _addressController.addListener(() => setState(() {}));
    _rcController.addListener(() => setState(() {}));
    _taxController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _rcController.dispose();
    _taxController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ─── Image Picker ─────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (picked != null) {
        setState(() => _pickedImage = File(picked.path));
      }
    } catch (e) {
      _showSnack(
        'Could not access ${source == ImageSource.camera ? "camera" : "gallery"}. Check permissions.',
        isError: true,
      );
    }
  }

  void _showImageSourceSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text("Business Logo",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text("Choose how to add your image",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _sourceOption(
                    icon: IconsaxPlusLinear.camera,
                    label: "Camera",
                    onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: _sourceOption(
                    icon: IconsaxPlusLinear.gallery,
                    label: "Gallery",
                    onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
                  )),
                ],
              ),
              if (_pickedImage != null) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _pickedImage = null);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  label: const Text("Remove photo", style: TextStyle(color: Colors.red)),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.deepOrange, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ─── Validation ───────────────────────────────────────────────────────────
  bool _isStepValid() {
    if (_currentStep == 0) {
      return _nameController.text.trim().isNotEmpty && _selectedCategory != null;
    }
    if (_currentStep == 1) {
      return _phoneController.text.trim().isNotEmpty &&
          _addressController.text.trim().isNotEmpty &&
          _rcController.text.trim().isNotEmpty &&
          _taxController.text.trim().isNotEmpty;
    }
    return true;
  }

  void _handleNavigation() {
    if (!_isStepValid()) return;
    if (_currentStep == 0) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _submitProfile();
    }
  }

  // ─── Submit — plain JSON just like login.dart ─────────────────────────────
  Future<void> _submitProfile() async {
    final user = context.read<UserProvider>().user;
    if (user == null) {
      _showSnack('Session expired. Please log in again.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ── Step 1: Submit business profile as JSON ──────────────
      final res = await http.post(
        Uri.parse('https://glopa.org/glo/insert_business.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id':        user.userId,
          'business_name':  _nameController.text.trim(),
          'business_phone': _phoneController.text.trim(),
          'business_type':  _selectedCategory ?? '',
          'address':        _addressController.text.trim(),
          'rc_number':      _rcController.text.trim(),
          'tax_id':         _taxController.text.trim(),
        }),
      );

      debugPrint('=== SERVER RESPONSE (${res.statusCode}) ===');
      debugPrint(res.body);

      if (res.statusCode != 200) {
        _showSnack('Server error (${res.statusCode}). Please try again.', isError: true);
        return;
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(res.body);
      } catch (_) {
        _showSnack('Unexpected server response.', isError: true);
        return;
      }

      if (data['status'] != 'success') {
        _showSnack(data['message'] ?? 'Something went wrong', isError: true);
        return;
      }

      final businessId = data['data']?['business_id'] ?? '';

      // ── Step 2: Upload image separately if picked ─────────────
      if (_pickedImage != null && businessId.isNotEmpty) {
        final imgRequest = http.MultipartRequest(
          'POST',
          Uri.parse('https://glopa.org/glo/upload_business_img.php'),
        );
        imgRequest.fields['business_id'] = businessId;
        imgRequest.files.add(await http.MultipartFile.fromPath(
          'business_img', _pickedImage!.path,
        ));
        final imgStreamed = await imgRequest.send();
        final imgRes = await http.Response.fromStream(imgStreamed);
        debugPrint('IMG UPLOAD: ${imgRes.body}');
      }

      _showSnack('Business profile created! 🎉');
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OwnerPage()),
        );
      }

    } on SocketException {
      _showSnack('No internet connection.', isError: true);
    } catch (e) {
      debugPrint('Error: $e');
      _showSnack('Something went wrong. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Colors.deepOrange;
    final bool active = _isStepValid() && !_isLoading;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20,
              color: isDark ? Colors.white : Colors.black),
          onPressed: () {
            if (_currentStep > 0) {
              _pageController.previousPage(duration: 300.ms, curve: Curves.ease);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text("Setup Store",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 18, fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Progress bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              children: List.generate(2, (index) => Expanded(
                child: Container(
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? primaryColor
                        : (isDark ? Colors.white10 : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              )),
            ),
          ).animate().fadeIn(),

          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentStep = page),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBasicInfoStep(isDark, primaryColor),
                _buildVerificationStep(isDark, primaryColor),
              ],
            ),
          ),

          // ── Bottom button ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: active ? _handleNavigation : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: active ? primaryColor : Colors.grey.shade400,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 22, width: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
                    : Text(
                  _currentStep == 1 ? "Finish & Launch" : "Continue",
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 1 ───────────────────────────────────────────────────────────────
  Widget _buildBasicInfoStep(bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _tier3Alert(),
          const SizedBox(height: 25),
          Center(
            child: GestureDetector(
              onTap: _showImageSourceSheet,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                    backgroundImage: _pickedImage != null ? FileImage(_pickedImage!) : null,
                    child: _pickedImage == null
                        ? Icon(IconsaxPlusLinear.camera, color: primaryColor, size: 30)
                        : null,
                  ),
                  Positioned(
                    bottom: 2, right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF121212) : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _pickedImage != null ? Icons.edit : Icons.add,
                        color: Colors.white, size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_pickedImage != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text("Tap to change photo",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ),
          ],
          const SizedBox(height: 30),
          _buildLabel("Store Name *"),
          _buildTextField(_nameController, "e.g. Gold's Premium Fashion", IconsaxPlusLinear.shop, isDark),
          const SizedBox(height: 20),
          _buildLabel("Store Category *"),
          _buildCategoryDropdown(isDark),
          const SizedBox(height: 20),
          _buildLabel("Bio / Description (Optional)"),
          _buildTextField(_bioController, "What do you sell?", IconsaxPlusLinear.edit_2, isDark, maxLines: 2),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── Step 2 ───────────────────────────────────────────────────────────────
  Widget _buildVerificationStep(bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text("Business Details",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
            "Your registered email will be used as your business email.",
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 25),
          _buildLabel("Phone Number *"),
          _buildTextField(_phoneController, "e.g. 08012345678", IconsaxPlusLinear.call, isDark),
          const SizedBox(height: 20),
          _buildLabel("Business Address *"),
          _buildTextField(_addressController, "e.g. 12 Lagos Street, Abuja", IconsaxPlusLinear.location, isDark),
          const SizedBox(height: 20),
          _buildLabel("RC Number *"),
          _buildTextField(_rcController, "RC-1234567", IconsaxPlusLinear.verify, isDark),
          const SizedBox(height: 20),
          _buildLabel("Tax ID *"),
          _buildTextField(_taxController, "TIN-0000000", IconsaxPlusLinear.document_text, isDark),
          const SizedBox(height: 25),
          _infoCard("Your KYC Tier will be linked automatically. You must be in Tier 3 to launch."),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
  );

  Widget _buildTextField(
      TextEditingController ctrl,
      String hint,
      IconData icon,
      bool isDark, {
        int maxLines = 1,
      }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 18),
        hintText: hint,
        filled: true,
        fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          hint: const Text("Select category"),
          items: _categories
              .map((it) => DropdownMenuItem(value: it, child: Text(it)))
              .toList(),
          onChanged: (val) => setState(() => _selectedCategory = val),
        ),
      ),
    );
  }

  Widget _tier3Alert() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.blue.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        Icon(IconsaxPlusLinear.info_circle, color: Colors.blue, size: 18),
        SizedBox(width: 10),
        Text("Tier 3 verification required.",
            style: TextStyle(color: Colors.blue, fontSize: 12)),
      ],
    ),
  );

  Widget _infoCard(String text) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.grey.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
  );
}

