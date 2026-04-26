// report_fraud_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../provider/user_provider.dart'; // adjust path

class ReportFraudPage extends StatefulWidget {
  const ReportFraudPage({super.key});

  @override
  State<ReportFraudPage> createState() => _ReportFraudPageState();
}

class _ReportFraudPageState extends State<ReportFraudPage> {
  String? _selectedIssue;
  final List<String> _issues = [
    "Fraudulent Transaction",
    "Locked Account",
    "Unauthorized Access",
    "Card Stolen/Lost",
    "Suspicious Login",
  ];

  double s(BuildContext context, double value) {
    final sw = MediaQuery.of(context).size.width;
    return (sw / 375 * value).clamp(value * 0.85, value * 1.25);
  }

  void _goToDetails() {
    if (_selectedIssue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an issue type.")),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FraudDetailsPage(issue: _selectedIssue!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Report Fraud"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(s(context, 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Step 1: Select Issue Type",
              style: TextStyle(
                  fontSize: s(context, 18), fontWeight: FontWeight.bold),
            ),
            SizedBox(height: s(context, 16)),
            Wrap(
              spacing: s(context, 12),
              runSpacing: s(context, 12),
              children: _issues.map((issue) {
                final selected = _selectedIssue == issue;
                return ChoiceChip(
                  label: Text(issue),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedIssue = issue),
                  selectedColor: Colors.deepOrange,
                  backgroundColor:
                  isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  labelStyle: TextStyle(
                    color: selected
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black),
                    fontWeight: FontWeight.w600,
                  ),
                  padding: EdgeInsets.symmetric(
                      horizontal: s(context, 14), vertical: s(context, 10)),
                );
              }).toList(),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _goToDetails,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, s(context, 52)),
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(s(context, 14))),
                elevation: 4,
              ),
              child: Text(
                "Next",
                style: TextStyle(
                    fontSize: s(context, 18),
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2: Details Page
// ─────────────────────────────────────────────────────────────────────────────
class FraudDetailsPage extends StatefulWidget {
  final String issue;
  const FraudDetailsPage({super.key, required this.issue});

  @override
  State<FraudDetailsPage> createState() => _FraudDetailsPageState();
}

class _FraudDetailsPageState extends State<FraudDetailsPage> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  double s(BuildContext context, double value) {
    final sw = MediaQuery.of(context).size.width;
    return (sw / 375 * value).clamp(value * 0.85, value * 1.25);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // ── Submit to backend ──────────────────────────────────────────────────────
  Future<void> _submitReport() async {
    final description = _descriptionController.text.trim();

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide details for the report.")),
      );
      return;
    }

    if (description.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide more detail.")),
      );
      return;
    }

    final userId = context.read<UserProvider>().user?.userId ?? '';
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await http.post(
        Uri.parse('https://glopa.org/glo/submit_report.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id':     userId,
          'issue_type':  widget.issue,
          'description': description,
        }),
      );

      if (!mounted) return;

      final map = jsonDecode(res.body) as Map<String, dynamic>;

      if (map['status'] == 'success') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FraudConfirmationPage(
              issue:    widget.issue,
              reportId: map['report_id'] ?? '',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(map['message'] ?? 'Submission failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Step 2: Describe Issue"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(s(context, 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(s(context, 14))),
              color: isDark ? Colors.grey.shade900 : Colors.white,
              child: Padding(
                padding: EdgeInsets.all(s(context, 16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Issue badge ──────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.issue,
                        style: TextStyle(
                          fontSize: s(context, 13),
                          fontWeight: FontWeight.w600,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                    SizedBox(height: s(context, 12)),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: "Provide details about the issue...",
                        filled: true,
                        fillColor: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(s(context, 12)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, s(context, 52)),
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(s(context, 14))),
                elevation: 4,
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
                  : Text(
                "Submit Report",
                style: TextStyle(
                    fontSize: s(context, 18),
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3: Confirmation Page
// ─────────────────────────────────────────────────────────────────────────────
class FraudConfirmationPage extends StatelessWidget {
  final String issue;
  final String reportId;

  const FraudConfirmationPage({
    super.key,
    required this.issue,
    required this.reportId,
  });

  double s(BuildContext context, double value) {
    final sw = MediaQuery.of(context).size.width;
    return (sw / 375 * value).clamp(value * 0.85, value * 1.25);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(s(context, 20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Success icon ───────────────────────────────────────────
              Container(
                width: s(context, 100),
                height: s(context, 100),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_outline,
                    color: Colors.deepOrange, size: s(context, 60)),
              ),
              SizedBox(height: s(context, 20)),
              Text(
                "Report Submitted!",
                style: TextStyle(
                    fontSize: s(context, 22), fontWeight: FontWeight.bold),
              ),
              SizedBox(height: s(context, 12)),
              Text(
                "Your report for \"$issue\" has been submitted successfully. Our team will review it and contact you if necessary.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: s(context, 15), height: 1.5),
              ),

              // ── Report ID badge ────────────────────────────────────────
              if (reportId.isNotEmpty) ...[
                SizedBox(height: s(context, 16)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey.shade900
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Reference ID',
                        style: TextStyle(
                            fontSize: s(context, 11),
                            color: Colors.grey,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reportId,
                        style: TextStyle(
                          fontSize: s(context, 16),
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: s(context, 30)),
              ElevatedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, s(context, 52)),
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(s(context, 14))),
                  elevation: 4,
                ),
                child: Text(
                  "Back to Help Center",
                  style: TextStyle(
                      fontSize: s(context, 18),
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}