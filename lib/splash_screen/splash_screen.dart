import 'package:flutter/material.dart';
import 'package:globalpay/onboarding_screen/onboarding_page.dart';
import '../onboarding_screen/auto_choice_page.dart';

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

    // Warm up the logo so it's ready the moment the screen shows.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      precacheImage(const AssetImage("assets/images/png/logo222.PNG"), context);
    });

    _startSplash();
  }

  void _startSplash() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) =>
              OnboardingPage(onToggleTheme: widget.onToggleTheme),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  // Clamp sizing so it scales down on small phones and doesn't look
  // tiny on tablets, same baseline used across the app.
  double _scale(BuildContext context, double base) {
    final width = MediaQuery.of(context).size.width;
    final factor = (width / 375).clamp(0.75, 1.3);
    return base * factor;
  }

  @override
  Widget build(BuildContext context) {
    // The logo circle overlaps the left edge of the "lonest" wordmark by
    // design, so its margin scales with the logo size — keeps the same
    // proportions on every screen width.
    final logoSize = _scale(context, 90);
    final overlapMargin = logoSize - _scale(context, 10);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          // Keeps the whole lockup off the screen edges on small phones.
          padding: EdgeInsets.symmetric(horizontal: _scale(context, 16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Wordmark sitting behind the logo
                  Container(
                    margin: EdgeInsets.only(left: overlapMargin),
                    padding: EdgeInsets.only(right: _scale(context, 20)),
                    child: FittedBox(
                      // Guarantees the wordmark never overflows, even on
                      // the smallest phones.
                      fit: BoxFit.scaleDown,
                      child: Text(
                        " lonest",
                        style: TextStyle(
                          fontSize: _scale(context, 32),
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                          letterSpacing: 1.2,
                        ),
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
                      'assets/images/png/logo222.PNG',
                      width: logoSize,
                      height: logoSize,
                    ),
                  ),
                ],
              ),

              SizedBox(height: _scale(context, 20)),

              // Motto
              Text(
                "Your Money. Your Market. One Nest.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _scale(context, 14),
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
