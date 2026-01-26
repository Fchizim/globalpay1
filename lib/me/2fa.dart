import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class TwoFAPage extends StatefulWidget {
  const TwoFAPage({super.key});

  @override
  State<TwoFAPage> createState() => _TwoFAPageState();
}

class _TwoFAPageState extends State<TwoFAPage> {
  final TextEditingController _otpController = TextEditingController();
  int _secondsRemaining = 30;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  void _verifyCode() {
    if (_otpController.text.length == 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Verification Successful"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid code. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey.shade900 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final inputBgColor = isDark ? Colors.grey.shade800 : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Two-Factor Authentication"),
        centerTitle: true,
        elevation: 0.3,
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        foregroundColor: textColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Icon(IconsaxPlusBold.security, size: 70, color: Colors.deepOrange),
            const SizedBox(height: 20),
            Text(
              "Enter Verification Code",
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              "We sent a 6-digit code to your registered email/phone.",
              textAlign: TextAlign.center,
              style: TextStyle(color: secondaryTextColor, fontSize: 14),
            ),
            const SizedBox(height: 30),

            // OTP Input Field
            TextField(
              controller: _otpController,
              maxLength: 6,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: textColor,
              ),
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: inputBgColor,
                hintText: "••••••",
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                  fontSize: 22,
                  letterSpacing: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.deepOrange, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Resend Code with Countdown
            _canResend
                ? TextButton(
              onPressed: () {
                _startTimer();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("New code sent."),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: const Text(
                "Resend Code",
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
                : Text(
              "Resend available in $_secondsRemaining s",
              style: TextStyle(color: secondaryTextColor, fontSize: 14),
            ),

            const Spacer(),

            // Verify Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: Colors.deepOrange,
                  elevation: 0,
                ),
                onPressed: _verifyCode,
                child: const Text(
                  "Verify",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}
