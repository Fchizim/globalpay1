import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:globalpay/Market/editors_profile.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoreSetupPage extends StatefulWidget {
  const StoreSetupPage({super.key});

  @override
  State<StoreSetupPage> createState() => _StoreSetupPageState();
}

class _StoreSetupPageState extends State<StoreSetupPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _cacController = TextEditingController();
  String? _selectedCategory;

  final List<String> _categories = [
    'Fashion',
    'Electronics',
    'Food & Groceries',
    'Beauty & Health',
    'Home & Office',
    'Services',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cacController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool _isStepValid() {
    if (_currentStep == 0) {
      return _nameController.text.trim().isNotEmpty &&
          _selectedCategory != null;
    }
    return true;
  }

  Future<void> _saveStoreData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ownerName', _nameController.text.trim());
    await prefs.setString(
      'ownerBio',
      _bioController.text.trim().isEmpty
          ? "Top Seller & Curator"
          : _bioController.text.trim(),
    );
  }

  // --- SHOW PAYMENT MODAL ---
  void _showPaymentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentPinSheet(
        onSuccess: () async {
          await _saveStoreData();
          if (!mounted) return;
          Navigator.pop(context); // Close modal
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OwnerPage()),
          );
        },
      ),
    );
  }

  void _handleNavigation() {
    if (_isStepValid()) {
      if (_currentStep == 0) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        _showPaymentModal(); // Trigger the Payment PIN modal
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Colors.deepOrange;
    final bool active = _isStepValid();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () {
            if (_currentStep > 0) {
              _pageController.previousPage(
                duration: 300.ms,
                curve: Curves.ease,
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          "Setup Store",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              children: List.generate(2, (index) {
                return Expanded(
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
                );
              }),
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
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: active ? _handleNavigation : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: active ? primaryColor : Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _currentStep == 1 ? "Finish & Launch" : "Continue",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: isDark
                      ? Colors.white10
                      : Colors.grey.shade100,
                  child: Icon(
                    IconsaxPlusLinear.camera,
                    color: primaryColor,
                    size: 28,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _addIconCircle(primaryColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildLabel("Store Name *"),
          _buildTextField(
            _nameController,
            "e.g. Gold's Premium Fashion",
            IconsaxPlusLinear.shop,
            isDark,
          ),
          const SizedBox(height: 20),
          _buildLabel("Store Category *"),
          _buildCategoryDropdown(isDark),
          const SizedBox(height: 20),
          _buildLabel("Bio / Description (Optional)"),
          _buildTextField(
            _bioController,
            "What do you sell?",
            IconsaxPlusLinear.edit_2,
            isDark,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStep(bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            "Official Details",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          const Text(
            "Users with CAC get a verified seller badge.",
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 30),
          _buildLabel("CAC Registration Number (Optional)"),
          _buildTextField(
            _cacController,
            "RC-1234567",
            IconsaxPlusLinear.verify,
            isDark,
          ),
          const SizedBox(height: 40),
          _infoCard(
            "Your KYC Tier will be linked automatically. You must be in Tier 3 to launch.",
          ),
        ],
      ),
    );
  }

  // Helper widgets... (same as your original)
  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    ),
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
        Text(
          "Tier 3 verification required.",
          style: TextStyle(color: Colors.blue, fontSize: 12),
        ),
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
  Widget _addIconCircle(Color color) => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: const Icon(Icons.add, color: Colors.white, size: 14),
  );
}

// --- PIN MODAL COMPONENT ---
class _PaymentPinSheet extends StatefulWidget {
  final VoidCallback onSuccess;
  const _PaymentPinSheet({required this.onSuccess});

  @override
  State<_PaymentPinSheet> createState() => _PaymentPinSheetState();
}

class _PaymentPinSheetState extends State<_PaymentPinSheet> {
  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onPinChanged(int index, String value) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-submit if all 4 are filled
    if (_pinControllers.every((c) => c.text.isNotEmpty)) {
      widget.onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 32,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Enter Transaction PIN",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Pay ₦500.00 to launch your store",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              4,
              (index) => SizedBox(
                width: 60,
                height: 60,
                child: TextField(
                  controller: _pinControllers[index],
                  focusNode: _focusNodes[index],
                  autofocus: index == 0,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(1),
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (v) => _onPinChanged(index, v),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "This transaction would be debited from your wallet.\nMake sure it's funded.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Wallet Balance: ₦0.00",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
