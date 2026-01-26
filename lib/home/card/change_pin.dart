import 'package:flutter/material.dart';

class ChangePinPage extends StatefulWidget {
  const ChangePinPage({super.key});

  @override
  State<ChangePinPage> createState() => _ChangePinPageState();
}

class _ChangePinPageState extends State<ChangePinPage> {
  final List<TextEditingController> _currentPinControllers =
  List.generate(4, (index) => TextEditingController());
  final List<TextEditingController> _newPinControllers =
  List.generate(4, (index) => TextEditingController());
  final List<TextEditingController> _confirmPinControllers =
  List.generate(4, (index) => TextEditingController());

  final List<FocusNode> _currentFocusNodes =
  List.generate(4, (index) => FocusNode());
  final List<FocusNode> _newFocusNodes =
  List.generate(4, (index) => FocusNode());
  final List<FocusNode> _confirmFocusNodes =
  List.generate(4, (index) => FocusNode());

  void _handlePinInput(List<TextEditingController> controllers,
      List<FocusNode> focusNodes, int index, String value) {
    if (value.isNotEmpty && index < 3) {
      focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
    setState(() {}); // To update active box highlight
  }

  void _submitPinChange() {
    String currentPin = _currentPinControllers.map((c) => c.text).join();
    String newPin = _newPinControllers.map((c) => c.text).join();
    String confirmPin = _confirmPinControllers.map((c) => c.text).join();

    if (newPin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("New PIN and confirm PIN do not match!")),
      );
      return;
    }

    // API call can be placed here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("PIN changed successfully!")),
    );

    for (var c
    in _currentPinControllers + _newPinControllers + _confirmPinControllers) {
      c.clear();
    }
    FocusScope.of(context).unfocus();
  }

  Widget _buildPinRow(String title, List<TextEditingController> controllers,
      List<FocusNode> focusNodes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            bool isActive = focusNodes[index].hasFocus;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                  colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : LinearGradient(
                  colors: [
                    Colors.grey.shade200,
                    Colors.grey.shade300,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: isActive
                    ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: controllers[index],
                focusNode: focusNodes[index],
                textAlign: TextAlign.center,
                maxLength: 1,
                keyboardType: TextInputType.number,
                obscureText: true,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.black87),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
                onChanged: (value) =>
                    _handlePinInput(controllers, focusNodes, index, value),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  void dispose() {
    for (var c
    in _currentPinControllers + _newPinControllers + _confirmPinControllers) {
      c.dispose();
    }
    for (var f in _currentFocusNodes + _newFocusNodes + _confirmFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Change PIN"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildPinRow(
                "Current PIN", _currentPinControllers, _currentFocusNodes),
            _buildPinRow("New PIN", _newPinControllers, _newFocusNodes),
            _buildPinRow(
                "Confirm New PIN", _confirmPinControllers, _confirmFocusNodes),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitPinChange,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: const Color(0xFFFF7043),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                shadowColor: Colors.orangeAccent.withOpacity(0.5),
              ),
              child: const Text(
                "Change PIN",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
