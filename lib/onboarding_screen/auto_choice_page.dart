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
                    // forces it — this is what was causing overflow on
                    // short/small phones with the fixed 40px gaps.
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
                          SizedBox(height: _scale(context, 40)),

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
                          SizedBox(height: _scale(context, 15)),

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
                          SizedBox(height: _scale(context, 40)),

                          // Theme Toggle
                          GestureDetector(
                            onTap: onToggleTheme,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              width: _scale(context, 160),
                              height: _scale(context, 48),
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[850]
                                    : Colors.grey[300],
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
                                      width: _scale(context, 75),
                                      height: _scale(context, 38),
                                      decoration: BoxDecoration(
                                        color: Colors.deepOrange,
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.deepOrange
                                                .withOpacity(0.5),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        isDark
                                            ? Icons.dark_mode
                                            : Icons.light_mode,
                                        color: Colors.white,
                                        size: _scale(context, 22),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: isDark
                                        ? Alignment.centerLeft
                                        : Alignment.centerRight,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: _scale(context, 20),
                                      ),
                                      child: Icon(
                                        isDark
                                            ? Icons.light_mode
                                            : Icons.dark_mode,
                                        size: _scale(context, 20),
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
              },
            ),
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
    return SizedBox(
      width: double.infinity,
      height: _scale(context, 55),
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 6,
          shadowColor: Colors.deepOrange.withOpacity(0.4),
        ),
        onPressed: onPressed,
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: _scale(context, 16),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
