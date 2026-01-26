import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _feedbackController = TextEditingController();
  int _rating = 0;

  void _submitFeedback() {
    if (_feedbackController.text.isEmpty || _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide feedback and rating")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Thank You! 🎉"),
        content: const Text(
          "Your feedback has been submitted successfully. We truly appreciate your time.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );

    setState(() {
      _feedbackController.clear();
      _rating = 0;
    });
  }

  Widget _buildStar(int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _rating = index;
        });
      },
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
            // Header
            Text(
              "We’d love your feedback",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Tell us what you think about the app. Your feedback helps us improve.",
              style: TextStyle(
                fontSize: 15,
                color: theme.hintColor,
              ),
            ),

            const SizedBox(height: 25),

            // Rating Card
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
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(5, (index) => _buildStar(index + 1)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Feedback Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(IconsaxPlusBold.send_2, color: Colors.white),
                label: const Text(
                  "Submit Feedback",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _submitFeedback,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
