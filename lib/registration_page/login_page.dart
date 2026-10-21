import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../Market/cart_provider.dart';
import '../apps/apps.dart';
import '../provider/user_provider.dart';
import '../services/push_notification_service.dart';
import 'forgot_password.dart';
import 'signup_page.dart';
import '../models/user_model.dart';
import '../services/secure_storage_service.dart';
import 'package:provider/provider.dart';
import '../provider/authprovider.dart'; // your AuthProvider file

class LoginPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onLoginSuccess;
  final String? prefillEmail;

  const LoginPage({
    super.key,
    required this.onToggleTheme,
    required this.onLoginSuccess,
    this.prefillEmail,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final pinController = TextEditingController();

  bool isLoading = false;

  // Scales a value with screen width, kept within a modest range.
  double s(double value) {
    final sw = MediaQuery.of(context).size.width;
    return (sw / 375 * value).clamp(value * 0.85, value * 1.2);
  }

  @override
  void initState() {
    super.initState();
    if (widget.prefillEmail != null) {
      emailController.text = widget.prefillEmail!;
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    pinController.dispose();
    super.dispose();
  }

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
      // ── Get the FCM token for this device before logging in ──
      // If this fails for any reason (permissions denied, etc.), fall back
      // to null rather than blocking login entirely.
      String? fcmToken;
      try {
        fcmToken = await PushNotificationService.getToken();
      } catch (e) {
        debugPrint('Could not get FCM token: $e');
      }

      final res = await http.post(
        Uri.parse("https://glopa.org/glo/userlogin.php"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "pin": pin,
          "fcm_token": fcmToken,
          "platform": Platform.isIOS ? "ios" : "android",
        }),
      );

      final data = jsonDecode(res.body);

      if (data['status'] != 'success') {
        throw data['message'];
      }

      /// ✅ Parse user
      final user = UserModel.fromJson(data['user']);

      await SecureStorageService.saveUser(user);
      if (!mounted) return;
      context.read<AuthProvider>().setUser(user);
      context.read<UserProvider>().setUser(user);
      context.read<CartProvider>().fetchCount(user.userId);

      /// OPTIONAL callback
      widget.onLoginSuccess();

      /// 🚀 Navigate
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MyAppsPage(onToggleTheme: widget.onToggleTheme),
        ),
        (_) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lightBg = const Color(0xFFF5F6F8);
    final darkBg = const Color(0xFF121212);

    // Keeps the form at a comfortable width on tablets.
    const maxFormWidth = 420.0;

    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Login",
          style: TextStyle(fontSize: s(18), fontWeight: FontWeight.w600),
        ),
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
            padding: EdgeInsets.fromLTRB(s(24), topInset + s(16), s(24), s(32)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxFormWidth),
              child: Column(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: s(52),
                    color: Colors.deepOrange,
                  ),

                  SizedBox(height: s(16)),

                  Text(
                    "Welcome Back 👋",
                    style: TextStyle(
                      fontSize: s(24),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),

                  SizedBox(height: s(6)),

                  Text(
                    "Login to continue",
                    style: TextStyle(
                      fontSize: s(14),
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),

                  SizedBox(height: s(30)),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(fontSize: s(15)),
                    decoration: _inputDecoration(
                      "Email Address",
                      Icons.email_outlined,
                      isDark,
                    ),
                  ),

                  SizedBox(height: s(16)),

                  TextField(
                    controller: pinController,
                    obscureText: true,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: s(15)),
                    decoration: _inputDecoration(
                      "4-digit PIN",
                      Icons.lock_outline,
                      isDark,
                    ),
                  ),

                  // 🔹 FORGOT PIN BUTTON ----------------------------------
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordPage(
                              email: '',
                              phoneNumber: '',
                            ),
                          ),
                        );
                      },
                      child: Text(
                        "Forgot PIN?",
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w600,
                          fontSize: s(14),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: s(8)),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: Size(double.infinity, s(52)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: isLoading ? null : _login,
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            "Login",
                            style: TextStyle(
                              fontSize: s(16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),

                  SizedBox(height: s(18)),

                  // Wrap lets this fall onto a second line on narrow phones
                  // instead of overflowing.
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Don’t have an account?",
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: s(14),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SignupPage(
                                onLoginSuccess: () {},
                                onToggleTheme: widget.onToggleTheme,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          "Click to sign Up!",
                          style: TextStyle(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.w600,
                            fontSize: s(14),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: s(4)),

                  // ── Guest entry point — intentionally does NOT touch
                  // AuthProvider / UserProvider / CartProvider, since none of
                  // them have a real user to work with here. Screens that
                  // assume a logged-in user (cart, wallet, anything reading
                  // UserProvider's user as non-null) will need their own
                  // guest handling wherever that assumption lives. ──
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            widget.onLoginSuccess();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MyAppsPage(
                                  onToggleTheme: widget.onToggleTheme,
                                ),
                              ),
                              (_) => false,
                            );
                          },
                    child: Text(
                      "Continue as Guest",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w600,
                        fontSize: s(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: s(14)),
      counterText: "",
      contentPadding: EdgeInsets.symmetric(horizontal: s(16), vertical: s(16)),
      prefixIcon: Icon(icon, color: Colors.deepOrange, size: s(22)),
      filled: true,
      fillColor: isDark ? Colors.grey[850] : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.deepOrange, width: 1.2),
      ),
    );
  }
}
