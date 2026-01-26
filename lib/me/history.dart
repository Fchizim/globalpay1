import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class ActiveSessionsPage extends StatefulWidget {
  const ActiveSessionsPage({super.key});

  @override
  State<ActiveSessionsPage> createState() => _TransactionLimitPageState();
}

class _TransactionLimitPageState extends State<ActiveSessionsPage> {
  double dailyLimit = 50000;
  double weeklyLimit = 200000;
  double dailyUsed = 15000;
  double weeklyUsed = 120000;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme colors
    final bgColor = isDark ? Colors.grey.shade900 : Colors.grey.shade200;
    final cardColor = isDark ? Colors.grey.shade800 : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Transaction Limits"),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        foregroundColor: textColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 10),
          _buildLimitCard(
            title: "Daily Limit",
            icon: IconsaxPlusLinear.calendar,
            used: dailyUsed,
            total: dailyLimit,
            onChanged: (value) => setState(() => dailyLimit = value),
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          const SizedBox(height: 20),
          _buildLimitCard(
            title: "Weekly Limit",
            icon: IconsaxPlusLinear.calendar_2,
            used: weeklyUsed,
            total: weeklyLimit,
            onChanged: (value) => setState(() => weeklyLimit = value),
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Transaction limits updated successfully!"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text(
                "Save Changes",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitCard({
    required String title,
    required IconData icon,
    required double used,
    required double total,
    required ValueChanged<double> onChanged,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Row(
            children: [
              Icon(icon, color: Colors.deepOrange, size: 26),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "₦${total.toStringAsFixed(0)}",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.deepOrange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: used / total,
              backgroundColor: borderColor,
              color: Colors.deepOrange,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "₦${used.toStringAsFixed(0)} used of ₦${total.toStringAsFixed(0)}",
            style: TextStyle(fontSize: 13, color: secondaryTextColor),
          ),
          const SizedBox(height: 20),
          // Slider with Tooltip
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
              valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
              valueIndicatorTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Slider(
              min: 10000,
              max: 500000,
              divisions: 49,
              value: total,
              label: "₦${total.toStringAsFixed(0)}",
              activeColor: Colors.deepOrange,
              inactiveColor: borderColor,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
