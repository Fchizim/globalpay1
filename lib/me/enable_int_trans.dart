import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class InternationalTransactionPage extends StatefulWidget {
  const InternationalTransactionPage({super.key});

  @override
  State<InternationalTransactionPage> createState() =>
      _InternationalTransactionPageState();
}

class _InternationalTransactionPageState
    extends State<InternationalTransactionPage> {
  bool isInternationalEnabled = false; // default: disabled

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey.shade900 : Colors.grey.shade200;
    final cardColor = isDark ? Colors.grey.shade800 : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("International Transactions"),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        foregroundColor: textColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(IconsaxPlusLinear.global,
                      size: 30, color: Colors.deepOrange),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "International Transactions",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isInternationalEnabled
                              ? "You can use your account for payments abroad."
                              : "Currently disabled. Enable to allow international use.",
                          style: TextStyle(
                            fontSize: 13,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    activeThumbColor: Colors.deepOrange,
                    value: isInternationalEnabled,
                    onChanged: (value) {
                      setState(() => isInternationalEnabled = value);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? "International transactions enabled"
                                : "International transactions disabled",
                          ),
                          backgroundColor:
                          value ? Colors.green : Colors.redAccent,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Info section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(IconsaxPlusLinear.information,
                    color: Colors.deepOrange, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Turn this on only when you need to make payments abroad. "
                        "We recommend keeping it disabled to protect your account from unauthorized usage.",
                    style: TextStyle(
                      fontSize: 13,
                      color: secondaryTextColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
