import 'package:flutter/material.dart';
import 'package:globalpay/business/verify_page.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _categoryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  VerifyPage()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Container(
                height: 30,
                width: 60,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    "Next",
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Title
            Center(
              child: Text(
                'Set Up Your GlobalBiz Profile',
                style: textTheme.headlineMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.2, duration: 600.ms),

            const SizedBox(height: 15),

            // Subtitle
            Center(
              child: Text(
                'Fill in your seller info to start listing products in the marketplace.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  fontSize: 18,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 200.ms)
                .slideY(begin: 0.2, duration: 600.ms),

            const SizedBox(height: 30),

            // Name Field
            _animatedTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              delay: 400,
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),

            const SizedBox(height: 15),

            // Email Field
            _animatedTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'Enter your email address',
              delay: 550,
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),

            const SizedBox(height: 15),

            // Category Field
            _animatedTextField(
              controller: _categoryController,
              label: 'Store Category',
              hint: 'E.g., Fashion, Electronics, Food',
              delay: 700,
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _animatedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int delay,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: TextField(
        controller: controller,
        cursorColor: colorScheme.primary,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: textTheme.titleLarge?.copyWith(
            fontSize: 20,
            color: colorScheme.onSurface,
          ),
          hintText: hint,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colorScheme.primary),
          ),
          border: OutlineInputBorder(),
        ),
      )
          .animate()
          .fadeIn(duration: 500.ms, delay: delay.ms)
          .slideY(begin: 0.2, duration: 500.ms),
    );
  }
}
