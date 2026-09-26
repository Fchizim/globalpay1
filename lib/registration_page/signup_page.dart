import 'package:flutter/material.dart';
import 'set_pin.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SignupPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onLoginSuccess;

  const SignupPage({
    super.key,
    required this.onToggleTheme,
    required this.onLoginSuccess,
  });

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final PageController _pageController = PageController();

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  String? selectedGender;
  bool isLoading = false;
  int currentPage = 0;

  final allowedDomains = ["gmail.com", "outlook.com", "yahoo.com"];

  @override
  void dispose() {
    _pageController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    if (email.isEmpty) return false;
    final regex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
    if (!regex.hasMatch(email)) return false;

    final parts = email.split('@');
    if (parts.length != 2) return false;

    final domain = parts.last.toLowerCase();
    return allowedDomains.contains(domain);
  }

  bool _isValidPhone(String phone) {
    final regex = RegExp(r"^[0-9]{10,15}$");
    return regex.hasMatch(phone);
  }

  void _gotoOtpScreen() async {
    if (!_isValidEmail(emailController.text.trim())) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter valid email")));
      return;
    }

    if (!_isValidPhone(phoneController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter a valid phone number (10-15 digits)"),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await http.post(
        Uri.parse("https://glopa.org/glo/reg.php"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": fullNameController.text.trim(),
          "email": emailController.text.trim(),
          "phone": phoneController.text.trim(),
          "gender": selectedGender,
          "pin": "0000",
          "address": "Not set",
        }),
      );

      final data = jsonDecode(res.body);

      if (data['status'] == 'success') {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Network error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _verifyOtp() async {
    if (otpController.text.length != 4) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter valid 4-digit OTP")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await http.post(
        Uri.parse("https://glopa.org/glo/verify_otp.php"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": emailController.text.trim(),
          "otp": otpController.text.trim(),
        }),
      );

      final data = jsonDecode(res.body);

      if (data['status'] == 'success') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SetPinPage(email: emailController.text.trim()),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Network error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _nextPage() {
    if (currentPage == 0) {
      if (fullNameController.text.isEmpty || selectedGender == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
        return;
      }
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _back() {
    if (currentPage == 0) {
      Navigator.pop(context);
    } else {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  // ---- RESPONSIVE HELPERS ----

  // Clamp a "phone-sized" width so it scales down on small phones
  // and doesn't stretch too wide on tablets/foldables.
  double _scale(BuildContext context, double base) {
    final width = MediaQuery.of(context).size.width;
    // 375 is a common baseline phone width (iPhone SE/8 class)
    final factor = (width / 375).clamp(0.85, 1.25);
    return base * factor;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lightBg = const Color(0xFFF5F6F8);
    final darkBg = const Color(0xFF121212);

    final screenWidth = MediaQuery.of(context).size.width;
    // Cap the usable content width so it doesn't stretch edge-to-edge on tablets.
    final maxContentWidth = screenWidth > 600 ? 480.0 : screenWidth;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(),
        title: Text(
          "Sign Up",
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.deepOrange),
        leading: IconButton(
          onPressed: _back,
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.deepOrange),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [darkBg, Colors.grey.shade900]
                : [lightBg, Colors.grey.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => currentPage = i),
                    children: [
                      _pageBasic(isDark),
                      _pageContactChoice(isDark),
                      _pageOtp(isDark),
                    ],
                  ),
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.deepOrange),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // PAGE 1 BASIC DETAILS
  Widget _pageBasic(bool isDark) {
    return _buildPage(
      title: "Create Account",
      isDark: isDark,
      children: [
        _textField("Full Name", fullNameController, isDark),
        _genderDropdown(isDark),
        const SizedBox(height: 10),
        _nextBackButtons(isDark),
      ],
    );
  }

  // PAGE 2 EMAIL + PHONE
  Widget _pageContactChoice(bool isDark) {
    return _buildPage(
      title: "Verify your contact",
      isDark: isDark,
      children: [
        _textField(
          "Email Address",
          emailController,
          isDark,
          keyboardType: TextInputType.emailAddress,
        ),
        _textField(
          "Phone Number",
          phoneController,
          isDark,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 15),
        _primaryButton("Send Code", _gotoOtpScreen),
      ],
    );
  }

  // PAGE 3 OTP
  Widget _pageOtp(bool isDark) {
    return _buildPage(
      title: "Enter verification code",
      isDark: isDark,
      children: [
        _textField(
          "4-digit code",
          otpController,
          isDark,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 15),
        _primaryButton("Continue", _verifyOtp),
      ],
    );
  }

  // COMMON BUILDERS

  Widget _buildPage({
    required String title,
    required bool isDark,
    required List<Widget> children,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hPad = _scale(context, 20);
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
          child: ConstrainedBox(
            // Ensures content can grow to fill height on tall/tablet screens
            // without being forced to, avoiding both overflow and awkward gaps.
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: _scale(context, 20)),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: _scale(context, 24),
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: _scale(context, 18)),
                  ...children,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller,
    bool isDark, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _scale(context, 8)),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: _scale(context, 15)),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          prefixIcon: const Icon(Icons.person, color: Colors.deepOrange),
          fillColor: isDark ? Colors.grey[850] : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _genderDropdown(bool isDark) {
    return DropdownButtonFormField<String>(
      initialValue: selectedGender,
      isExpanded: true, // prevents overflow if a value is long
      decoration: InputDecoration(
        labelText: "Gender",
        prefixIcon: const Icon(Icons.person_2, color: Colors.deepOrange),
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: const [
        DropdownMenuItem(value: "Male", child: Text("Male")),
        DropdownMenuItem(value: "Female", child: Text("Female")),
        DropdownMenuItem(value: "Other", child: Text("Other")),
      ],
      onChanged: (v) => setState(() => selectedGender = v),
    );
  }

  Widget _primaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: _scale(context, 55),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: const TextStyle(color: Colors.black)),
        ),
      ),
    );
  }

  Widget _nextBackButtons(bool isDark) {
    return _primaryButton("Next", _nextPage);
  }
}
