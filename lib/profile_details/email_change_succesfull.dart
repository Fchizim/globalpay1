import 'dart:async';
import 'package:flutter/material.dart';

import '../apps/apps.dart';
import '../home/home_page.dart';
import 'profile_details.dart'; // adjust path if needed

class VerificationSuccess extends StatefulWidget {
  const VerificationSuccess({super.key});

  @override
  State<VerificationSuccess> createState() => _VerificationSuccessState();
}

class _VerificationSuccessState extends State<VerificationSuccess> {
  @override
  void initState() {
    super.initState();

    // Auto redirect after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => MyAppsPage(onToggleTheme: () {  },)),
            (route) => false,
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfileDetails(onToggleTheme: () {  },)),
      );
    }
);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scaffoldColor =
    isDark ? const Color(0xFF121212) : Colors.white;

    final textColor =
    isDark ? Colors.white : Colors.black87;

    final subText =
    isDark ? Colors.white70 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.deepOrange.withOpacity(.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 90,
                color: Colors.deepOrange,
              ),
            ),

            const SizedBox(height: 30),

             Text(
              "Email Changed Successful",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor
              ),
            ),

            const SizedBox(height: 10),

             Text(
              "Your Email has been verified successfully.",
              style: TextStyle(
                color: subText,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 40),

            const CircularProgressIndicator(
              color: Colors.deepOrange,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
