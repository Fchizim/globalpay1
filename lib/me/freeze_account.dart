import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class FreezeAccountPage extends StatefulWidget {
  const FreezeAccountPage({super.key});

  @override
  State<FreezeAccountPage> createState() => _FreezeAccountPageState();
}

class _FreezeAccountPageState extends State<FreezeAccountPage> {
  bool isFrozen = false;

  Future<void> _showPinDialog({required bool freezeAction}) async {
    List<FocusNode> focusNodes = List.generate(4, (_) => FocusNode());
    List<TextEditingController> controllers =
    List.generate(4, (_) => TextEditingController());

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            freezeAction ? "Enter PIN to Freeze" : "Enter PIN to Unfreeze",
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),

              // ✅ PIN input boxes (stable layout)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  return SizedBox(
                    width: 50,
                    height: 60,
                    child: TextField(
                      controller: controllers[index],
                      focusNode: focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      obscureText: true,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: "",
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 3) {
                          FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                        }
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    child: const Text("Cancel"),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Confirm"),
                    onPressed: () {
                      String enteredPin =
                      controllers.map((c) => c.text).join(); // ✅ collect PIN

                      if (enteredPin.length == 4) {
                        setState(() {
                          isFrozen = freezeAction;
                        });
                        Navigator.pop(context); // close dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isFrozen
                                  ? "Your account has been frozen."
                                  : "Your account is now active.",
                            ),
                            backgroundColor:
                            isFrozen ? Colors.red : Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please enter a valid 4-digit PIN."),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Freeze Account"),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Icon + Status
            CircleAvatar(
              radius: 50,
              backgroundColor:
              isFrozen ? Colors.red.shade100 : Colors.green.shade100,
              child: Icon(
                isFrozen ? IconsaxPlusBold.lock : IconsaxPlusBold.unlock,
                size: 50,
                color: isFrozen ? Colors.red : Colors.green,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              isFrozen
                  ? "Your account is currently frozen"
                  : "Your account is active",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isFrozen ? Colors.red : Colors.green,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),
            Text(
              isFrozen
                  ? "While frozen, you cannot send or receive money.\nYou can unfreeze anytime."
                  : "You can temporarily freeze your account if you notice any suspicious activities.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Freeze / Unfreeze Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isFrozen ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(
                isFrozen ? IconsaxPlusBold.unlock : IconsaxPlusBold.lock,
              ),
              label: Text(
                isFrozen ? "Unfreeze Account" : "Freeze Account",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                _showPinDialog(freezeAction: !isFrozen);
              },
            ),

            const SizedBox(height: 20),

            // Help Section
            TextButton.icon(
              onPressed: () {
                // Navigate to support/help page
              },
              icon: const Icon(IconsaxPlusLinear.info_circle),
              label: const Text("Need help? Contact Support"),
            ),
          ],
        ),
      ),
    );
  }
}
