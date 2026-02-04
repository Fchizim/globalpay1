import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:globalpay/business/business_home.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _addressController = TextEditingController();
  final _registrationController = TextEditingController();

  final List<String> _idTypes = ['National ID', 'BVN', 'SSN'];
  String _selectedIdType = 'National ID';
  bool _isLoading = false;
  String _loadingMessage = '';

  void _showLoader({String message = ''}) async {
    setState(() {
      _isLoading = true;
      _loadingMessage = message;
    });

    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isLoading = false;
      _loadingMessage = '';
    });

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) =>  BusinessHome()),
    );
  }

  void _onGetVerified() {
    if (_nameController.text.isEmpty ||
        _idController.text.isEmpty ||
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all mandatory fields.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _showLoader(message: 'Verification will take 24 hours');
  }

  void _onSkip() {
    _showLoader();
  }

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
            onTap: _onSkip,
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
                    "Skip",
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
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Get Verified',
                      style: textTheme.headlineMedium?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Icon(IconsaxPlusBold.verify, color: colorScheme.primary),
                    Text(
                      '!  (optional)',
                      style: textTheme.headlineMedium?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Getting a verified GlobalBiz badge builds trust in the marketplace, '
                      'makes your profile stand out, and gives buyers confidence.\n'
                      'Fill in your information to verify your seller profile.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.2),

                const SizedBox(height: 25),

                // Full Name
                _animatedTextField(
                  controller: _nameController,
                  label: 'Full Name *',
                  hint: 'Enter your full name',
                  delay: 400,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 15),

                // Row with Dropdown + ID Input
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: colorScheme.primary),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedIdType,
                          underline: const SizedBox(),
                          items: _idTypes.map((id) {
                            return DropdownMenuItem(
                              value: id,
                              child: Text(id, style: textTheme.bodyMedium),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedIdType = val!;
                            });
                          },
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 550.ms).slideY(begin: 0.2),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: _animatedTextField(
                        controller: _idController,
                        label: 'Enter $_selectedIdType *',
                        hint: 'Enter your $_selectedIdType number',
                        delay: 600,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Residential Address
                _animatedTextField(
                  controller: _addressController,
                  label: 'Residential Address *',
                  hint: 'Enter your current address',
                  delay: 700,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),

                const SizedBox(height: 15),

                // CAC Registration Number
                _animatedTextField(
                  controller: _registrationController,
                  label: 'CAC Registration Number (optional)',
                  hint: 'Only if you are a registered business',
                  delay: 850,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),

                const SizedBox(height: 40),

                // Get Verified Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: _onGetVerified,
                    child: Container(
                      height: 60,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(
                        child: Text(
                          'Get Verified',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 1000.ms).slideY(begin: 0.2),
                  ),
                ),
              ],
            ),
          ),

          // Loader Overlay
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 12),
                    if (_loadingMessage.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            _loadingMessage,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
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
    return TextField(
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
    ).animate().fadeIn(duration: 500.ms, delay: delay.ms).slideY(begin: 0.2, duration: 500.ms);
  }
}
