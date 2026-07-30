import 'package:flutter/material.dart';

/// Generic placeholder screen for features that aren't live yet.
///
/// Usage:
///   Navigator.push(context, MaterialPageRoute(
///     builder: (_) => const ComingSoonScreen(
///       title: 'Bill Payments',
///       message: "We're putting the finishing touches on this feature.",
///     ),
///   ));
class ComingSoonScreen extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;

  const ComingSoonScreen({
    super.key,
    this.title = 'Coming Soon',
    this.message,
    this.icon = Icons.rocket_launch_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark    = Theme.of(context).brightness == Brightness.dark;
    final Color primary  = Colors.deepOrange;
    final Color bgColor  = isDark ? const Color(0xFF0D0D0D) : Colors.white;
    final Color textColor    = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color cardColor    = isDark
        ? Colors.grey[900]!.withOpacity(0.6)
        : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cardColor,
                  border: Border.all(
                    color: primary.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: primary, size: 56),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message ??
                    "This feature isn't available yet, but we're working on it. Check back soon!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: subTextColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Go Back',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}