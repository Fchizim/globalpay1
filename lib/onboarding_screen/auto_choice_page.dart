import 'package:flutter/material.dart';
import 'package:globalpay/registration_page/signup_page.dart';
import '../registration_page/login_page.dart';

class AuthChoicePage extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const AuthChoicePage({super.key, required this.onToggleTheme});

  // Clamp sizing so it scales down on small phones and doesn't
  // look tiny/cramped on tablets, same baseline as SignupPage.
  double _scale(BuildContext context, double base) {
    final width = MediaQuery.of(context).size.width;
    final factor = (width / 375).clamp(0.85, 1.25);
    return base * factor;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final scaffoldColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.grey.shade700;

    final screenWidth = MediaQuery.of(context).size.width;
    // Cap content width on tablets so buttons/text don't stretch too wide.
    final maxContentWidth = screenWidth > 600 ? 480.0 : screenWidth;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: _scale(context, 30),
                    vertical: _scale(context, 30),
                  ),
                  child: ConstrainedBox(
                    // Fills the screen height when there's room, but never
                    // forces it, so short phones don't overflow.
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          Image.asset(
                            'assets/images/png/Smiley face.png',
                            height: _scale(context, 100),
                          ),
                          SizedBox(height: _scale(context, 25)),

                          // Welcome Text
                          Text(
                            "Welcome to Glonest",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: _scale(context, 24),
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: _scale(context, 8)),
                          Text(
                            "Send money, pay bills & manage business",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: _scale(context, 15),
                              color: subTextColor,
                            ),
                          ),
                          SizedBox(height: _scale(context, 32)),

                          // Login Button
                          _authButton(
                            context: context,
                            icon: Icons.login,
                            label: "Login",
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
                          ),
                          SizedBox(height: _scale(context, 12)),

                          // Signup Button
                          _authButton(
                            context: context,
                            icon: Icons.person_add,
                            label: "Sign Up",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SignupPage(
                                    onToggleTheme: onToggleTheme,
                                    onLoginSuccess: () {},
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: _scale(context, 32)),

                          // Theme Toggle (compact pill)
                          _themeToggle(context, isDark),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Small, sleek light/dark toggle.
  Widget _themeToggle(BuildContext context, bool isDark) {
    final width = _scale(context, 76);
    final height = _scale(context, 34);
    final thumbSize = height - 6;

    return Semantics(
      button: true,
      label: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      child: GestureDetector(
        onTap: onToggleTheme,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: width,
          height: height,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(height),
          ),
          child: Stack(
            children: [
              // Faint icon on the empty side
              Align(
                alignment: isDark
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _scale(context, 8),
                  ),
                  child: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    size: _scale(context, 14),
                    color: Colors.grey.withOpacity(0.6),
                  ),
                ),
              ),
              // Sliding thumb
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: isDark
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: thumbSize,
                  height: thumbSize,
                  decoration: const BoxDecoration(
                    color: Colors.deepOrange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: Colors.white,
                    size: _scale(context, 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _authButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    // Narrower than full width so the buttons don't look like big boxes.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: SizedBox(
        width: double.infinity,
        height: _scale(context, 44),
        child: ElevatedButton.icon(
          icon: Icon(icon, color: Colors.white, size: _scale(context, 18)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            shadowColor: Colors.deepOrange.withOpacity(0.3),
            padding: EdgeInsets.symmetric(horizontal: _scale(context, 16)),
          ),
          onPressed: onPressed,
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: _scale(context, 14),
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}