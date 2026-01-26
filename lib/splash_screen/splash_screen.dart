import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../onboarding_screen/auto_choice_page.dart';
import '../provider/authprovider.dart';
import '../home/home_page.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const SplashScreen({super.key, required this.onToggleTheme});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startSplash();
  }

  void _startSplash() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Navigate based on login state
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
        auth.isLoggedIn
            ? const HomePage()
            : AuthChoicePage(onToggleTheme: widget.onToggleTheme),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepOrange.shade700,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset("assets/images/png/background.png", fit: BoxFit.cover),

          // Centered logo and text
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Rectangle behind circle
                    Container(
                      margin: const EdgeInsets.only(left: 80),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(20),
                        ),
                      ),
                      padding: const EdgeInsets.only(right: 20),
                      child: const Text(
                        " lobalPay",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    // Circular logo
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/images/png/logo_transparent.png',
                        width: 90,
                        height: 90,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}