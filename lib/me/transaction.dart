import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class TransactionPinPage extends StatefulWidget {
  const TransactionPinPage({super.key});

  @override
  State<TransactionPinPage> createState() => _TransactionPinPageState();
}

class _TransactionPinPageState extends State<TransactionPinPage> {
  String pin = "";
  int pinLength = 6; // Default PIN length

  void _onKeyTap(String value) {
    if (pin.length < pinLength) {
      setState(() => pin += value);
    }
  }

  void _onBackspace() {
    if (pin.isNotEmpty) {
      setState(() => pin = pin.substring(0, pin.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey.shade900 : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    final isComplete = pin.length == pinLength;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Transaction PIN"),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: bgColor,
        foregroundColor: textColor,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Icon(IconsaxPlusBold.password_check, size: 48, color: Colors.deepOrange),
          const SizedBox(height: 16),
          Text(
            "Enter your $pinLength-digit Transaction PIN",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),

          // Toggle 4-digit or 6-digit PIN
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text("4-Digit"),
                selected: pinLength == 4,
                selectedColor: Colors.deepOrange,
                onSelected: (_) {
                  setState(() {
                    pinLength = 4;
                    pin = "";
                  });
                },
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text("6-Digit"),
                selected: pinLength == 6,
                selectedColor: Colors.deepOrange,
                onSelected: (_) {
                  setState(() {
                    pinLength = 6;
                    pin = "";
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 30),

          // PIN INDICATORS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pinLength,
                  (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: index < pin.length ? Colors.deepOrange : Colors.transparent,
                  border: Border.all(color: Colors.deepOrange, width: 1.4),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          const Spacer(),

          // KEYPAD
          _buildNumberPad(isDark),

          const SizedBox(height: 20),

          // Continue Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isComplete ? Colors.deepOrange : Colors.grey.shade400,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: isComplete
                  ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("PIN Verified!"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
                  : null,
              child: const Text(
                "Continue",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Extra Options
          Column(
            children: [
              TextButton.icon(
                icon: const Icon(IconsaxPlusLinear.repeat, color: Colors.deepOrange),
                label: const Text("Change Payment PIN"),
                onPressed: () {},
              ),
              TextButton.icon(
                icon: const Icon(IconsaxPlusLinear.forbidden_2, color: Colors.red),
                label: const Text("Forgot Payment PIN"),
                onPressed: () {},
              ),
              TextButton.icon(
                icon: const Icon(IconsaxPlusLinear.scan, color: Colors.blue),
                label: const Text("Pay with Face ID"),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Authenticating with Face ID..."),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildNumberPad(bool isDark) {
    final keys = [
      ["1", "2", "3"],
      ["4", "5", "6"],
      ["7", "8", "9"],
      ["", "0", "←"],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Column(
        children: keys.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key == "") {
                return const SizedBox(width: 60, height: 60);
              } else if (key == "←") {
                return _buildKey(
                  child: Icon(IconsaxPlusLinear.backward, size: 26, color: isDark ? Colors.white70 : Colors.black),
                  onTap: _onBackspace,
                  isDark: isDark,
                );
              } else {
                return _buildKey(
                  child: Text(
                    key,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  onTap: () => _onKeyTap(key),
                  isDark: isDark,
                );
              }
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKey({required Widget child, required VoidCallback onTap, required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
