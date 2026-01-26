import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'gtag_transaction_page.dart'; // new success page

// ----------------- PIN bottom sheet -----------------
Future<bool?> showPinBottomSheet(BuildContext context) async {
  final hiddenCtrl = TextEditingController();
  List<String> pins = ["", "", "", ""];
  bool loading = false;

  return await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          void handleChange(String value) async {
            for (int i = 0; i < 4; i++) {
              pins[i] = i < value.length ? value[i] : "";
            }
            setState(() {});
            if (value.length == 4) {
              setState(() => loading = true);
              await Future.delayed(const Duration(seconds: 1));
              if (context.mounted) Navigator.pop(context, true);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Enter 4-digit PIN",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                        (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 50,
                      height: 60,
                      decoration: BoxDecoration(
                        color: pins[i].isNotEmpty
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                            : Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: pins[i].isNotEmpty
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        pins[i].isNotEmpty ? "•" : "",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                if (loading)
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                const SizedBox(height: 20),
                Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: hiddenCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    onChanged: handleChange,
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

// ----------------- GTag Payment Page -----------------
class GTagPaymentPage extends StatefulWidget {
  final String? recipientTag;
  final String? recipientImage;

  const GTagPaymentPage({super.key, this.recipientTag, this.recipientImage});

  @override
  State<GTagPaymentPage> createState() => _GTagPaymentPageState();
}

class _GTagPaymentPageState extends State<GTagPaymentPage> {
  String amount = "";
  final TextEditingController _tagController = TextEditingController();

  void _appendNumber(String number) {
    if (number == ".") return;
    setState(() {
      if (amount.length < 12) amount += number;
    });
  }

  void _deleteNumber() {
    setState(() {
      if (amount.isNotEmpty) amount = amount.substring(0, amount.length - 1);
    });
  }

  String get formattedAmount {
    if (amount.isEmpty) return "₦0";
    final formatter = NumberFormat.currency(locale: "en_US", symbol: "₦", decimalDigits: 0);
    final intVal = int.tryParse(amount) ?? 0;
    return formatter.format(intVal);
  }

  Future<void> _sendMoney() async {
    final tag = _tagController.text.trim();
    final intVal = int.tryParse(amount) ?? 0;
    if (intVal <= 0 || tag.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Payment"),
        content: Text("Send $formattedAmount to $tag?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Continue"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final pinSuccess = await showPinBottomSheet(context);
      if (pinSuccess == true && context.mounted) {
        final double amountValue = (intVal).toDouble();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GTagSuccessfulPayment(
              amount: amountValue,
              gTagID: '', // You can pass a generated ID here
              recipientTag: tag, // Pass the entered GTag ID from the user
            ),
          ),
        );
      }
    }
  }

  Widget _buildKeypadButton(String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () => _appendNumber(label),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.recipientTag != null) {
      _tagController.text = widget.recipientTag!;
    }
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              isDark
                  ? "assets/images/png/bckdark1.PNG"
                  : "assets/images/png/background.png",
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 40,
                  backgroundImage: widget.recipientImage != null
                      ? AssetImage(widget.recipientImage!)
                      : const AssetImage("assets/images/png/gold.jpg"),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      prefixIcon:
                      const Icon(Icons.alternate_email, color: Colors.white),
                      hintText: "Enter Recipient G-Tag",
                      hintStyle: const TextStyle(color: Colors.white70),
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none),
                    ),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 50),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    formattedAmount,
                    key: ValueKey<String>(formattedAmount),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 50),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var row in [
                          ["1", "2", "3"],
                          ["4", "5", "6"],
                          ["7", "8", "9"],
                          [".", "0", "<"]
                        ])
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: row.map((key) {
                                return Expanded(
                                  child: _buildKeypadButton(
                                    key,
                                    onTap: key == "<"
                                        ? _deleteNumber
                                        : () => _appendNumber(key),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: _sendMoney,
                            child: Text(
                              "Send Money",
                              style: TextStyle(
                                  color: Colors.deepOrange.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
