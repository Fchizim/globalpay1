import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'email_change_verification.dart';

class EmailBinding extends StatefulWidget {
  const EmailBinding({super.key});

  @override
  State<EmailBinding> createState() => _EmailBindingState();
}

class _EmailBindingState extends State<EmailBinding> {
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
      appBar: AppBar(
        backgroundColor: scaffoldColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),

          Center(
            child: SvgPicture.asset(
              'assets/images/svg/Email.svg',
              width: 200,
              height: 200,
              // colorFilter: isDark
              //     ? const ColorFilter.mode(
              //     Colors.white, BlendMode.srcIn)
              //     : null,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Current Email',
            style: TextStyle(color: subText, fontSize: 15),
          ),

          const SizedBox(height: 6),

          Text(
            'g*@gmail.com',
            style: TextStyle(
              color: textColor,
              fontSize: 19,
              fontWeight: FontWeight.w500,
            ),
          ),

          const Spacer(),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const EmailChangeVerification()),
              );
            },
            child: Padding(
              padding:
              const EdgeInsets.only(bottom: 80, left: 40, right: 40),
              child: Container(
                height: 55,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Text(
                    'Change Email',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
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
