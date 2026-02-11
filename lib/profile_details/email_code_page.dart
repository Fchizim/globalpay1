import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'email_change_succesfull.dart';

class EmailCodePage extends StatefulWidget {
  final String userId;
  final String email;

  const EmailCodePage({super.key, required this.userId, required this.email});

  @override
  State<EmailCodePage> createState() => _EmailCodePageState();
}

class _EmailCodePageState extends State<EmailCodePage> {
  final List<TextEditingController> _controllers =
  List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focus = List.generate(4, (_) => FocusNode());

  int seconds = 60;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    seconds = 60;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (seconds == 0) {
        t.cancel();
      } else {
        setState(() => seconds--);
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focus) f.dispose();
    timer?.cancel();
    super.dispose();
  }

  // Combine OTP digits
  String get otp => _controllers.map((c) => c.text).join();

  Future<void> verifyOtp() async {
    if (otp.length != 4) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Enter all 4 digits")));
      return;
    }

    try {
      final url = Uri.parse("https://glopa.org/glo/verify_email_change.php");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "otp": otp,
        }),
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "success") {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const VerificationSuccess()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Verification failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Network error, try again")),
      );
    }
  }

  Future<void> resendOtp() async {
    try {
      final url = Uri.parse("https://glopa.org/glo/change_email.php");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": widget.userId}),
      );

      final data = jsonDecode(response.body);
      if (data["status"] == "success") {
        startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP resent successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Failed to resend OTP")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Network error, try again")),
      );
    }
  }

  Widget otpBox(int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 60,
      height: 60,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focus[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        cursorColor: Colors.deepOrange,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: isDark ? Colors.white12 : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (v) {
          if (v.isNotEmpty) {
            if (index < 3) _focus[index + 1].requestFocus();
          } else {
            if (index > 0) _focus[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subText = isDark ? Colors.white70 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: scaffoldColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              "Please enter verification code",
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 12),
            Text(
              "We've sent a 4 digit code to",
              style: TextStyle(fontSize: 16, color: subText),
            ),
            const SizedBox(height: 4),
            Text(
              widget.email,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (i) => otpBox(i)),
            ),
            const SizedBox(height: 30),
            Center(
              child: seconds > 0
                  ? Text("Resend code in $seconds s", style: TextStyle(color: subText))
                  : GestureDetector(
                onTap: resendOtp,
                child: const Text(
                  "Didn't get the code? Resend",
                  style: TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: verifyOtp,
              child: Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Text(
                    "Continue",
                    style: TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}