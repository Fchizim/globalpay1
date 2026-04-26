import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';
// adjust this import to wherever your UserProvider lives
import '../provider/user_provider.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _feedbackController = TextEditingController();
  int _rating = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  // ── Submit to PHP backend ────────────────────────────────────────────────
  Future<void> _submitFeedback() async {
    final feedbackText = _feedbackController.text.trim();

    // ── Client-side validation ──
    if (_rating == 0) {
      _showSnack("Please select a star rating");
      return;
    }
    if (feedbackText.isEmpty) {
      _showSnack("Please write your feedback");
      return;
    }

    final userId = context.read<UserProvider>().user?.userId ?? '';
    if (userId.isEmpty) {
      _showSnack("User not logged in");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://glopa.org/glo/add_feedback.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id':  userId,
          'rating':   _rating,
          'feedback': feedbackText,
        }),
      );

      final map = jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (map['status'] == 'success') {
        // clear form
        setState(() {
          _feedbackController.clear();
          _rating = 0;
        });
        _showSuccessDialog();
      } else {
        _showSnack(map['message'] ?? 'Something went wrong');
      }
    } catch (e) {
      if (mounted) _showSnack('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Thank You! 🎉"),
        content: const Text(
          "Your feedback has been submitted successfully. "
              "We truly appreciate your time.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  // ── Star widget ──────────────────────────────────────────────────────────
  Widget _buildStar(int index) {
    return GestureDetector(
      onTap: () => setState(() => _rating = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(6),
        child: Icon(
          index <= _rating ? IconsaxPlusBold.star : IconsaxPlusLinear.star,
          color: index <= _rating ? Colors.amber : Colors.grey.shade400,
          size: 36,
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Feedback"),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Text(
              "We'd love your feedback",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Tell us what you think about the app. "
                  "Your feedback helps us improve.",
              style: TextStyle(fontSize: 15, color: theme.hintColor),
            ),

            const SizedBox(height: 25),

            // ── Rating card ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Rate your experience",
                    style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(
                        5, (index) => _buildStar(index + 1)),
                  ),
                  // ── Rating label ──────────────────────────────────────
                  if (_rating > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      [
                        '',
                        '😞 Poor',
                        '😕 Fair',
                        '😐 Average',
                        '😊 Good',
                        '🤩 Excellent',
                      ][_rating],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: [
                          Colors.transparent,
                          Colors.red,
                          Colors.orange,
                          Colors.amber,
                          Colors.lightGreen,
                          Colors.green,
                        ][_rating],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ── Feedback text input ───────────────────────────────────────
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _feedbackController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: "Write your feedback here...",
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ── Submit button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(IconsaxPlusBold.send_2,
                    color: Colors.white),
                label: Text(
                  _isLoading ? "Submitting..." : "Submit Feedback",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isLoading ? null : _submitFeedback,
              ),
            ),
          ],
        ),
      ),
    );
  }
}