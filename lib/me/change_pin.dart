import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class ChangePinPage extends StatefulWidget {
  const ChangePinPage({super.key});

  @override
  State<ChangePinPage> createState() => _ChangePinPageState();
}

class _ChangePinPageState extends State<ChangePinPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  void _changePin() {
    if (_formKey.currentState!.validate()) {
      if (_newPinController.text != _confirmPinController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("New PIN and Confirm PIN do not match."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Your PIN has been changed successfully."),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    }
  }

  Widget _buildPinField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: 4,
      obscureText: true,
      keyboardType: TextInputType.number,
      validator: (val) {
        if (val == null || val.isEmpty) return "Enter $label";
        if (val.length != 4) return "$label must be 4 digits";
        return null;
      },
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? Colors.grey.shade800 : Colors.white,
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        counterText: "",
        prefixIcon: const Icon(
          IconsaxPlusBold.lock,
          size: 20,
          color: Colors.deepOrange,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.deepOrange, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey.shade900 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Change PIN"),
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
              Text(
                "Secure your account",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 6),
              Text(
                "Update your transaction PIN in a few steps",
                style: TextStyle(color: secondaryTextColor, fontSize: 14),
              ),
              const SizedBox(height: 30),
              _buildPinField(
                  label: "Current PIN",
                  controller: _currentPinController,
                  isDark: isDark),
              const SizedBox(height: 20),
              _buildPinField(
                  label: "New PIN", controller: _newPinController, isDark: isDark),
              const SizedBox(height: 20),
              _buildPinField(
                  label: "Confirm New PIN",
                  controller: _confirmPinController,
                  isDark: isDark),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: Colors.deepOrange,
                    elevation: 0,
                  ),
                  onPressed: _changePin,
                  child: const Text(
                    "Change PIN",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
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
