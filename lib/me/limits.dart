import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class TransactionLimitPage extends StatefulWidget {
  const TransactionLimitPage({super.key});

  @override
  State<TransactionLimitPage> createState() => _TransactionLimitPageState();
}

class _TransactionLimitPageState extends State<TransactionLimitPage> {
  double dailyLimit = 50000; // default daily limit
  double weeklyLimit = 200000; // default weekly limit
  double dailyUsed = 15000; // example daily usage
  double weeklyUsed = 120000; // example weekly usage

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Transaction Limits"),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 10),

          // Daily Limit Card
          _buildLimitCard(
            title: "Daily Limit",
            icon: IconsaxPlusLinear.calendar,
            used: dailyUsed,
            total: dailyLimit,
            onChanged: (value) {
              setState(() => dailyLimit = value);
            },
          ),
          const SizedBox(height: 20),

          // Weekly Limit Card
          _buildLimitCard(
            title: "Weekly Limit",
            icon: IconsaxPlusLinear.calendar_2,
            used: weeklyUsed,
            total: weeklyLimit,
            onChanged: (value) {
              setState(() => weeklyLimit = value);
            },
          ),
          const SizedBox(height: 40),

          // Save Button
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
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Row(
            children: [
              Icon(icon, color: Colors.deepOrange, size: 26),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "₦${total.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: used / total,
              backgroundColor: Colors.grey.shade300,
              color: Colors.deepOrange,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "₦${used.toStringAsFixed(0)} used of ₦${total.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),

          // Slider with Tooltip
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 14),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 24),
              valueIndicatorShape: PaddleSliderValueIndicatorShape(),
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
              inactiveColor: Colors.grey.shade300,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
