import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../apps/apps.dart';
import 'signup_page.dart';
import '../models/user_model.dart';
import '../services/secure_storage_service.dart';
import 'package:provider/provider.dart';
import '../provider/authprovider.dart'; // your AuthProvider file

class LoginPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onLoginSuccess;

  const LoginPage({
    super.key,
    required this.onToggleTheme,
    required this.onLoginSuccess,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final pinController = TextEditingController();

  bool isLoading = false;

  Future<void> _login() async {
    final email = emailController.text.trim();
    final pin = pinController.text.trim();

    if (email.isEmpty || pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid email and 4-digit PIN")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await http.post(
        Uri.parse("https://glopa.org/glo/userlogin.php"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "pin": pin,
        }),
      );

      final data = jsonDecode(res.body);

      if (data['status'] != 'success') {
        throw data['message'];
      }

      /// ✅ Parse user
      final user = UserModel.fromJson(data['user']);

      /// 🔐 Save securely
      /// 🔐 Save securely
      await SecureStorageService.saveUser(user);

      /// 🔥 UPDATE PROVIDER
      if (!mounted) return;
      context.read<AuthProvider>().setUser(user);

      /// OPTIONAL callback
      widget.onLoginSuccess();

      /// 🚀 Navigate
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MyAppsPage(
              onToggleTheme: widget.onToggleTheme),
        ),
            (_) => false
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
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
        title: const Text("Login"),
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 60),
            child: Column(
              children: [
                const Icon(Icons.lock_outline,
                    size: 60, color: Colors.deepOrange),

                const SizedBox(height: 20),

                Text(
                  "Welcome Back 👋",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),

                const SizedBox(height: 40),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    "Email Address",
                    Icons.email,
                    isDark,
                  ),
                ),

                const SizedBox(height: 18),

                TextField(
                  controller: pinController,
                  obscureText: true,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    "4-digit PIN",
                    Icons.lock,
                    isDark,
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isLoading ? null : _login,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don’t have an account?",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SignupPage(
                              onLoginSuccess: () {},
                              onToggleTheme: widget.onToggleTheme,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      counterText: "",
      prefixIcon: Icon(icon, color: Colors.deepOrange),
      filled: true,
      fillColor: isDark ? Colors.grey[850] : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}
