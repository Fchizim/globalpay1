import 'package:flutter/material.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      precacheImage(
        const AssetImage("assets/images/png/background.png"),
        context,
      );
    });

    _startSplash();
  }

  void _startSplash() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) =>
              AuthChoicePage(onToggleTheme: widget.onToggleTheme),
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
    // The logo circle overlaps the left edge of the white "GlobalPay"
    // rectangle by design, so its margin needs to scale down on narrow
    // phones — otherwise the fixed 80px margin + 32pt text could push
    // past the screen edge. This keeps the same proportions instead.
    final logoSize = _scale(context, 90);
    final overlapMargin = logoSize - _scale(context, 10);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/png/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            // Keeps the whole lockup off the screen edges on small phones.
            padding: EdgeInsets.symmetric(horizontal: _scale(context, 16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Rectangle behind circle
                    Container(
                      margin: EdgeInsets.only(left: overlapMargin),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(20),
                        ),
                      ),
                      padding: EdgeInsets.only(right: _scale(context, 20)),
                      child: FittedBox(
                        // Guarantees the wordmark never overflows its
                        // rectangle, even on the smallest phones.
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
                        'assets/images/png/logo_transparent.png',
                        width: logoSize,
                        height: logoSize,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: _scale(context, 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
