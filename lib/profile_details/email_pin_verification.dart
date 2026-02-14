import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'email_code_page.dart';

class EmailPinVerification extends StatefulWidget {
  const EmailPinVerification({super.key});

  @override
  State<EmailPinVerification> createState() => _EmailPinVerificationState();
}

class _EmailPinVerificationState extends State<EmailPinVerification> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scaffoldColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subText = isDark ? Colors.white70 : Colors.grey.shade600;
    final fieldColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(backgroundColor: scaffoldColor, elevation: 0),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Enter Your New Email ',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                Icon(LucideIcons.mail, color: textColor),
              ],
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                'Provide the email address you would like to\nuse to login, receive notifications, and more.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: subText),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 30, left: 40, right: 40),
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: "Enter Your New Email",
                  filled: true,
                  fillColor: fieldColor,
                  hintStyle: TextStyle(color: subText),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.only(bottom: 80, left: 40, right: 40),
              child: GestureDetector(
                onTap: () {
                  if (_emailController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter email")),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmailCodePage(userId: '', email: '',)),
                  );
                },
                child: Container(
                  height: 55,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
