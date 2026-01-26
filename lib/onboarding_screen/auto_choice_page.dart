import 'package:flutter/material.dart';
import 'package:globalpay/registration_page/signup_page.dart';
import '../registration_page/login_page.dart';

class AuthChoicePage extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const AuthChoicePage({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final scaffoldColor =
    isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.grey.shade700;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Logo
              Image.asset(
                'assets/images/png/Smiley face.png',
                height: 100,
              ),
              const SizedBox(height: 25),

              // Welcome Text
              Text(
                "Welcome to GlobalPay",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Send money, pay bills & manage business",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: subTextColor,
                ),
              ),
              const SizedBox(height: 40),

              // Login Button
              ElevatedButton.icon(
                icon: const Icon(Icons.login, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 6,
                  shadowColor: Colors.deepOrange.withOpacity(0.4),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LoginPage(
                        onToggleTheme: onToggleTheme,
                        onLoginSuccess: () {},
                      ),
                    ),
                  );
                },
                label: const Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Signup Button
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 6,
                  shadowColor: Colors.deepOrange.withOpacity(0.4),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SignupPage(
                        onToggleTheme: onToggleTheme, onLoginSuccess: () {  },),
                    ),
                        (route) => false,
                  );
                },
                label: const Text(
                  "Sign Up",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Theme Toggle
              GestureDetector(
                onTap: onToggleTheme,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  width: 160,
                  height: 48,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 400),
                        alignment: isDark
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 75,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.deepOrange,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepOrange.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Icon(
                            isDark ? Icons.dark_mode : Icons.light_mode,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      Align(
                        alignment: isDark
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Icon(
                            isDark ? Icons.light_mode : Icons.dark_mode,
                            size: 20,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
