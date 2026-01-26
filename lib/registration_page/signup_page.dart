import 'package:flutter/material.dart';
import 'set_pin.dart';
// import 'package:http/http.dart';
import 'dart:convert'; // for jsonEncode & jsonDecode
import 'package:http/http.dart' as http; // for http.post

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
  // final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  String? selectedGender;
  bool isLoading = false;
  int currentPage = 0;

  bool useEmail = true; // tab state

  final allowedDomains = ["gmail.com", "outlook.com", "yahoo.com"];

  @override
  void dispose() {
    _pageController.dispose();
    fullNameController.dispose();
    // usernameController.dispose();
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

  void _gotoOtpScreen() async {
    if (!_isValidEmail(emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid email")),
      );
      return;
    }

    setState(() => isLoading = true);

    final res = await http.post(
      Uri.parse("https://glopa.org/glo/reg.php"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "name": fullNameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim().isEmpty
            ? "0000000000"
            : phoneController.text.trim(),
        "gender": selectedGender,   // ✅ ADD THIS
        "pin": "0000",
        "address": "Not set"
      }),
    );

    setState(() => isLoading = false);

    final data = jsonDecode(res.body);

    if (data['status'] == 'success') {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'])),
      );
    }
  }

  void _verifyOtp() async {
    if (otpController.text.length != 4) {  // match PHP OTP
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid 4-digit OTP")),
      );
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
        // navigate to SetPinPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SetPinPage(email: emailController.text.trim()),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _nextPage() {
    if (currentPage == 0) {
      if (fullNameController.text.isEmpty ||
          selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all fields")),
        );
        return;
      }
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    if (currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lightBg = const Color(0xFFF5F6F8);
    final darkBg = const Color(0xFF121212);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Sign Up"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => currentPage = i),
                children: [
                  _pageBasic(isDark),
                  _pageContactChoice(isDark),
                  _pageOtp(isDark),
                ],
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
        // _textField("Username", usernameController, isDark),
        _genderDropdown(isDark),
        const SizedBox(height: 10),
        _nextBackButtons(isDark),
      ],
    );
  }

  // PAGE 2 EMAIL OR PHONE TABS
  Widget _pageContactChoice(bool isDark) {
    return _buildPage(
      title: "Verify your contact",
      isDark: isDark,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => useEmail = true),
                  child: Text(
                    "Email",
                    style: TextStyle(
                      color: useEmail ? Colors.deepOrange : Colors.grey,
                      fontWeight:
                      useEmail ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => useEmail = false),
                  child: Text(
                    "Phone",
                    style: TextStyle(
                      color: !useEmail ? Colors.deepOrange : Colors.grey,
                      fontWeight:
                      !useEmail ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        if (useEmail)
          _textField(
            "Email Address",
            emailController,
            isDark,
            keyboardType: TextInputType.emailAddress,
          )
        else
          _textField(
            "Phone Number",
            phoneController,
            isDark,
            keyboardType: TextInputType.phone,
          ),

        const SizedBox(height: 15),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            minimumSize: const Size(double.infinity, 55),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _gotoOtpScreen,
          child: const Text("Send Code"),
        )
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
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            minimumSize: const Size(double.infinity, 55),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _verifyOtp,
          child: const Text(
            "Continue",
            style: TextStyle(
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  // COMMON BUILDERS BELOW

  Widget _buildPage({
    required String title,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _textField(
      String label,
      TextEditingController controller,
      bool isDark, {
        TextInputType? keyboardType,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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
      value: selectedGender,
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

  Widget _nextBackButtons(bool isDark) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepOrange,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: _nextPage,
      child: const Text(
        "Next",
        style: TextStyle(
          color: Colors.black,
        ),
      ),
    );
  }
}
