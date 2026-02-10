import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';


import 'email_pin_verification.dart';

class EmailChangeVerification extends StatefulWidget {
  const EmailChangeVerification({super.key});

  @override
  State<EmailChangeVerification> createState() =>
      _EmailChangeVerificationState();
}

class _EmailChangeVerificationState extends State<EmailChangeVerification> {
  final List<TextEditingController> _pinControllers =
  List.generate(4, (_) => TextEditingController());

  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  void _clearPin() {
    for (final c in _pinControllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _openPinSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * .6,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              width: 30,
              height: 4,
              decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4)),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.shieldCheck, color: Colors.green, size: 18),
                const SizedBox(width: 6),
                const Text(
                  "Your security is important to us.",
                  style: TextStyle(color: Colors.deepOrange),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              "Enter 4 Digit PIN",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) => _pinBox(index)),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      /// 🔥 CLEAR PIN WHEN MODAL CLOSES
      _clearPin();
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      _focusNodes[0].requestFocus();
    });
  }

  Widget _pinBox(int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 60,
      height: 60,
      child: TextField(
        controller: _pinControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        obscureText: true,
        style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: isDark ? Colors.white12 : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 3) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _completePin();
            }
          } else {
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
        },
      ),
    );
  }

  void _completePin() {
    final pin = _pinControllers.map((e) => e.text).join();

    if (pin.length == 4) {
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EmailPinVerification()),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scaffoldColor =
    isDark ? const Color(0xFF121212) : Colors.white;

    final textColor =
    isDark ? Colors.white : Colors.black87;

    final subText =
    isDark ? Colors.white70 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: scaffoldColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: Text(
              'Help',
              style: TextStyle(color: Colors.deepOrange, fontSize: 18),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  'Pin Verification',
                  style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                      color: textColor),
                ),
                const SizedBox(height: 10),
                Text(
                  'For account protection, please ensure that\n'
                      'you are the one carrying out this operation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: subText),
                ),
              ],
            ),
          ),

          const SizedBox(height: 60),

          SvgPicture.asset(
            'assets/images/svg/Mypassword.svg',
            width: 200,
            height: 200,
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.only(bottom: 80, left: 40, right: 40),
            child: GestureDetector(
              onTap: _openPinSheet,
              child: Container(
                height: 55,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Text(
                    'Verify',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
