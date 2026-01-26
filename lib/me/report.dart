import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class ReportSuspiciousActivityPage extends StatefulWidget {
  const ReportSuspiciousActivityPage({super.key});

  @override
  State<ReportSuspiciousActivityPage> createState() =>
      _ReportSuspiciousActivityPageState();
}

class _ReportSuspiciousActivityPageState
    extends State<ReportSuspiciousActivityPage> {
  final TextEditingController _detailsController = TextEditingController();
  String? selectedType;

  final List<String> activityTypes = [
    "Unauthorized login",
    "Unrecognized transaction",
    "Phishing attempt",
    "Account takeover",
    "Other"
  ];

  void _submitReport() {
    if (selectedType == null || _detailsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a type and provide details."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            "Your report has been submitted. Our team will review."),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

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
        title: const Text("Report Suspicious Activity"),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        foregroundColor: textColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "If you notice any unusual activity on your account, please report it below. Our security team will investigate immediately.",
              style: TextStyle(fontSize: 14, color: secondaryTextColor),
            ),
            const SizedBox(height: 20),
            // Dropdown for type
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark ? Colors.white24 : Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: "Select activity type",
                ),
                items: activityTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedType = val;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            // Details textfield
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark ? Colors.white24 : Colors.grey.shade300),
              ),
              child: TextField(
                controller: _detailsController,
                maxLines: 5,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: "Describe what happened",
                  alignLabelWithHint: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Screenshot upload
            GestureDetector(
              onTap: () {},
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark ? Colors.white24 : Colors.grey.shade300),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconsaxPlusLinear.image,
                          size: 40,
                          color: isDark ? Colors.white38 : Colors.grey),
                      const SizedBox(height: 8),
                      Text("Attach screenshot (optional)",
                          style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _submitReport,
                icon: const Icon(IconsaxPlusBold.shield_cross),
                label: const Text(
                  "Submit Report",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
