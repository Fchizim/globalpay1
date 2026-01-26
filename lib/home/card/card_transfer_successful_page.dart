import 'package:flutter/material.dart';

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradient = LinearGradient(
      colors: isDark
          ? [const Color(0xFF0D0D0D), const Color(0xFF1A1A1A)]
          : [Colors.grey.shade100, Colors.white],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final accent = Colors.green;
    final successGreen = Colors.green;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Icon
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withOpacity(0.3),
                          accent.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 85,
                      color: successGreen,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Amount
                  Text(
                    "₦1,998.00",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: successGreen,
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "Payment Successful",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Your GlobalPay card will be delivered\nwithin 3 weeks.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 60),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Text(
                      "Back to Dashboard",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
