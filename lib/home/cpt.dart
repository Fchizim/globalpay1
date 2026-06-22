import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

// Add optional param to ConfirmPinTransferPage:
class ConfirmPinTransferPage extends StatefulWidget {
  final String senderUserId;
  final double balance;
  final Map<String, dynamic> recipient;
  final Function(double) onTransaction;
  final double? prefilledAmount;

  const ConfirmPinTransferPage({
    super.key,
    required this.senderUserId,
    required this.balance,
    required this.recipient,
    required this.onTransaction,
    this.prefilledAmount,
  });

  @override
  State<ConfirmPinTransferPage> createState() =>
      _ConfirmPinTransferPageState();
}

class _ConfirmPinTransferPageState extends State<ConfirmPinTransferPage> {
  final TextEditingController _amountController = TextEditingController();

  // 4 separate boxes for the PIN — simple, no extra package required.
  final List<TextEditingController> _pinControllers =
  List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());

  bool _submitting = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    if (widget.prefilledAmount != null && widget.prefilledAmount! > 0) {
      _amountController.text = widget.prefilledAmount!.toStringAsFixed(0);
    }
  }
  @override
  void dispose() {
    _amountController.dispose();
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final f in _pinFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _pin => _pinControllers.map((c) => c.text).join();

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;

    if (amount <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }
    if (amount > widget.balance) {
      setState(() => _error = 'Insufficient balance.');
      return;
    }
    if (_pin.length != 4) {
      setState(() => _error = 'Enter your 4-digit PIN.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/tfmg.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_id': widget.senderUserId,
          'receiver_id': widget.recipient['user_id'],
          'amount': amount,
          'pin': _pin,
        }),
      );

      final map = jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (map['status'] == 'success') {
        widget.onTransaction(amount);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Sent ${amount.toStringAsFixed(2)} to ${widget.recipient['name']}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _error = map['message'] as String? ?? 'Transfer failed.';
          // clear PIN on failure so they have to re-enter it
          for (final c in _pinControllers) {
            c.clear();
          }
        });
        _pinFocusNodes.first.requestFocus();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not reach the server. Try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey.shade100;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white38 : Colors.grey.shade600;
    final hintColor = isDark ? Colors.white54 : Colors.grey.shade600;

    final name = (widget.recipient['name'] as String?) ?? 'GlobalPay user';
    final phone = (widget.recipient['phone'] as String?) ?? '';
    final image = (widget.recipient['image'] as String?) ?? '';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Confirm Transfer', style: TextStyle(color: textColor)),
        backgroundColor: bgColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── recipient summary ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.deepOrange.withOpacity(0.15),
                    backgroundImage:
                    image.isNotEmpty ? NetworkImage(image) : null,
                    child: image.isEmpty
                        ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SENDING TO',
                            style: TextStyle(
                                color: subTextColor,
                                fontSize: 11,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Text(name,
                            style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        Text(phone,
                            style: TextStyle(
                                color: subTextColor, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── amount ──
            Text('AMOUNT',
                style: TextStyle(
                    color: subTextColor,
                    fontSize: 11,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _amountController,
                readOnly: widget.prefilledAmount != null,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: TextStyle(color: hintColor),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text('Available balance: ${widget.balance.toStringAsFixed(2)}',
                style: TextStyle(color: subTextColor, fontSize: 12)),

            const SizedBox(height: 28),

            // ── PIN ──
            Text('ENTER YOUR 4-DIGIT PIN',
                style: TextStyle(
                    color: subTextColor,
                    fontSize: 11,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: 52,
                    height: 56,
                    child: TextField(
                      controller: _pinControllers[i],
                      focusNode: _pinFocusNodes[i],
                      textAlign: TextAlign.center,
                      obscureText: true,
                      obscuringCharacter: '●',
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w700),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                          const BorderSide(color: Colors.deepOrange),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && i < 3) {
                          _pinFocusNodes[i + 1].requestFocus();
                        } else if (val.isEmpty && i > 0) {
                          _pinFocusNodes[i - 1].requestFocus();
                        }
                      },
                    ),
                  ),
                );
              }),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ],

            const SizedBox(height: 28),

            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  disabledBackgroundColor: Colors.deepOrange.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'Confirm & Send',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}