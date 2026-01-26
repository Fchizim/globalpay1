import 'package:flutter/material.dart';

class ReportFraudPage extends StatefulWidget {
  const ReportFraudPage({super.key});

  @override
  State<ReportFraudPage> createState() => _ReportFraudPageState();
}

class _ReportFraudPageState extends State<ReportFraudPage> {
  String? _selectedIssue;
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _issues = [
    "Fraudulent Transaction",
    "Locked Account",
    "Unauthorized Access",
    "Card Stolen/Lost",
  ];

  void _submitReport() {
    if (_selectedIssue == null || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an issue and provide details.")),
      );
      return;
    }

    // Submit report logic here (API call, etc.)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Your report has been submitted: $_selectedIssue"),
        backgroundColor: Colors.deepOrange,
      ),
    );

    _descriptionController.clear();
    setState(() {
      _selectedIssue = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Report Fraud / Locked Account"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Issue Type",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _issues.map((issue) {
                final selected = _selectedIssue == issue;
                return ChoiceChip(
                  label: Text(issue),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedIssue = issue;
                    });
                  },
                  selectedColor: Colors.deepOrange,
                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  labelStyle: TextStyle(
                      color: selected ? Colors.white : (isDark ? Colors.white : Colors.black),
                      fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              "Describe the Issue",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Provide details about the issue...",
                filled: true,
                fillColor: isDark ? Colors.grey.shade900 : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _submitReport,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
              child: const Text(
                "Submit Report",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
