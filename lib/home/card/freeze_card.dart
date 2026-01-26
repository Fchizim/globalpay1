import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FreezeCardPage extends StatefulWidget {
  const FreezeCardPage({super.key});

  @override
  State<FreezeCardPage> createState() => _FreezeCardPageState();
}

class _FreezeCardPageState extends State<FreezeCardPage>
    with SingleTickerProviderStateMixin {
  bool isFrozen = false;
  late AnimationController _controller;
  late Animation<double> _overlayAnimation;

  // PIN controllers
  final List<TextEditingController> _pinControllers = List.generate(
      4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _overlayAnimation = Tween<double>(begin: 0, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void _toggleFreeze() async {
    // Ask for PIN before freezing/unfreezing
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _pinDialog(),
    );
  }

  void _handlePinComplete() {
    // Clear PIN fields
    for (var controller in _pinControllers) {
      controller.clear();
    }
    Navigator.of(context).pop();

    // Freeze or unfreeze card
    setState(() {
      isFrozen = !isFrozen;
      if (isFrozen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Widget _pinDialog() {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Enter 4-digit PIN",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 50,
                  child: TextField(
                    controller: _pinControllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      counterText: '',
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                        BorderSide(color: Colors.grey, width: 2),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                        BorderSide(color: Colors.deepOrange, width: 2),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 3) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                      // Check if PIN complete
                      if (_pinControllers.every((c) => c.text.isNotEmpty)) {
                        _handlePinComplete();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"))
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    for (var c in _pinControllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Freeze Card"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// Card Preview
            GestureDetector(
              onTap: _toggleFreeze,
              child: Stack(
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E1E99), Color(0xFF4A00E0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Align(
                          alignment: Alignment.topRight,
                          child:
                          Icon(Icons.credit_card, color: Colors.white, size: 28),
                        ),
                        const Spacer(),
                        const Text("**** **** **** 8321",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                letterSpacing: 2,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text("GOLD EMMANUEL",
                                style: TextStyle(color: Colors.white, fontSize: 14)),
                            Text("12/27",
                                style: TextStyle(color: Colors.white, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  /// Frozen Overlay
                  AnimatedBuilder(
                    animation: _overlayAnimation,
                    builder: (context, child) {
                      return Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.blueGrey.withOpacity(_overlayAnimation.value),
                        ),
                        alignment: Alignment.center,
                        child: isFrozen
                            ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.ac_unit, size: 50, color: Colors.white),
                            SizedBox(height: 12),
                            Text(
                              "Card Frozen",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                            : const SizedBox.shrink(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            /// Description
            Text(
              "Freezing your card will prevent all transactions temporarily. "
                  "You can unfreeze it anytime by tapping the card and entering your PIN.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 40),

            /// Freeze Toggle
            GestureDetector(
              onTap: _toggleFreeze,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 70,
                height: 40,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isFrozen ? Colors.deepOrange : Colors.grey.shade300,
                ),
                child: Align(
                  alignment: isFrozen ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2))
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFrozen ? "Your card is frozen" : "Your card is active",
              style: theme.textTheme.titleMedium!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            /// Action Button
            ElevatedButton(
              onPressed: _toggleFreeze,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: isFrozen ? Colors.green : Colors.deepOrange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              child: Text(
                isFrozen ? "Unfreeze Card" : "Freeze Card",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
