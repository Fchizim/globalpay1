import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';

class ChangePinPage extends StatefulWidget {
  const ChangePinPage({super.key});

  @override
  State<ChangePinPage> createState() => _ChangePinPageState();
}

class _ChangePinPageState extends State<ChangePinPage> {
  final _formKey             = GlobalKey<FormState>();
  final _currentPinController = TextEditingController();
  final _newPinController     = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _changePin() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPinController.text != _confirmPinController.text) {
      _showSnack('New PIN and Confirm PIN do not match.', Colors.red);
      return;
    }

    final email = context.read<UserProvider>().user?.email;
    if (email == null || email.isEmpty) {
      _showSnack('Could not get your account details. Please log in again.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await http.post(
        Uri.parse('https://glopa.org/glo/change_pin.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email':       email,
          'current_pin': _currentPinController.text,
          'new_pin':     _newPinController.text,
        }),
      );

      if (!mounted) return;
      final data = jsonDecode(res.body);

      if (data['status'] == 'success') {
        _showSnack('Your PIN has been changed successfully.', Colors.green);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      } else {
        _showSnack(data['message'] ?? 'Failed to change PIN.', Colors.red);
      }
    } catch (_) {
      if (mounted) _showSnack('Network error. Please try again.', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Widget _buildPinField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    String? Function(String?)? extraValidator,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: 4,
      obscureText: true,
      keyboardType: TextInputType.number,
      validator: (val) {
        if (val == null || val.isEmpty) return 'Enter $label';
        if (val.length != 4) return '$label must be 4 digits';
        return extraValidator?.call(val);
      },
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? Colors.grey.shade800 : Colors.white,
        labelText: label,
        labelStyle:
        TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        counterText: '',
        prefixIcon: const Icon(IconsaxPlusBold.lock,
            size: 20, color: Colors.deepOrange),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
          const BorderSide(color: Colors.deepOrange, width: 1.5),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark             = Theme.of(context).brightness == Brightness.dark;
    final bgColor            = isDark ? Colors.grey.shade900 : Colors.grey.shade200;
    final textColor          = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Change PIN'),
        centerTitle: true,
        elevation: 0.3,
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        foregroundColor: textColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Secure your account',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              const SizedBox(height: 6),
              Text('Update your transaction PIN in a few steps',
                  style:
                  TextStyle(color: secondaryTextColor, fontSize: 14)),
              const SizedBox(height: 30),

              _buildPinField(
                label: 'Current PIN',
                controller: _currentPinController,
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              _buildPinField(
                label: 'New PIN',
                controller: _newPinController,
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              _buildPinField(
                label: 'Confirm New PIN',
                controller: _confirmPinController,
                isDark: isDark,
                extraValidator: (val) => val != _newPinController.text
                    ? 'PINs do not match'
                    : null,
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    backgroundColor: Colors.deepOrange,
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _changePin,
                  child: _isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                      : const Text('Change PIN',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}