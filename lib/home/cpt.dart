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
  State<ConfirmPinTransferPage> createState() => _ConfirmPinTransferPageState();
}

class _ConfirmPinTransferPageState extends State<ConfirmPinTransferPage> {
  final TextEditingController _amountController = TextEditingController();

  // 4 separate boxes for the PIN — simple, no extra package required.
  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
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
              'Sent ${amount.toStringAsFixed(2)} to ${widget.recipient['name']}',
            ),
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

    // Screen-size aware scaling so this page looks right on small and
    // large phones/tablets instead of using fixed pixel values everywhere.
    final double screenWidth = MediaQuery.of(context).size.width;
    final double scale = (screenWidth / 390.0).clamp(0.85, 1.15);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Confirm Transfer', style: TextStyle(color: textColor)),
        backgroundColor: bgColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20 * scale),
        child: ConstrainedBox(
          // Caps the form width on tablets/large screens instead of
          // stretching edge-to-edge.
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── recipient summary ──
              Container(
                padding: EdgeInsets.all(16 * scale),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26 * scale,
                      backgroundColor: Colors.deepOrange.withOpacity(0.15),
                      backgroundImage: image.isNotEmpty
                          ? NetworkImage(image)
                          : null,
                      child: image.isEmpty
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.w700,
                                fontSize: 18 * scale,
                              ),
                            )
                          : null,
                    ),
                    SizedBox(width: 14 * scale),
                    // FIX: name/phone had no maxLines/overflow, so a long
                    // recipient name could wrap unpredictably. Added
                    // ellipsis so it clips cleanly on narrow screens.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SENDING TO',
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 11 * scale,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 2 * scale),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 13 * scale,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20 * scale),

              // ── amount ──
              Text(
                'AMOUNT',
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 11 * scale,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8 * scale),
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                child: TextField(
                  controller: _amountController,
                  readOnly: widget.prefilledAmount != null,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22 * scale,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(color: hintColor),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 16 * scale),
                  ),
                ),
              ),
              SizedBox(height: 4 * scale),
              Text(
                'Available balance: ${widget.balance.toStringAsFixed(2)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: subTextColor, fontSize: 12 * scale),
              ),

              SizedBox(height: 28 * scale),

              // ── PIN ──
              Text(
                'ENTER YOUR 4-DIGIT PIN',
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 11 * scale,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12 * scale),
              // FIX: 4 boxes at a fixed 52px width + 16px horizontal
              // padding each (272px total) had no safeguard for very
              // narrow phones (~320dp wide) where that plus the page's
              // own padding can exceed the available width and overflow.
              // LayoutBuilder now sizes each box from the actual
              // available width instead of a fixed constant.
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 12.0;
                  final maxBoxSize = 56.0 * scale;
                  final boxSize = ((constraints.maxWidth - gap * 3) / 4).clamp(
                    40.0,
                    maxBoxSize,
                  );
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: gap / 2),
                        child: SizedBox(
                          width: boxSize,
                          height: boxSize + 4,
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
                              fontSize: 22 * scale,
                              fontWeight: FontWeight.w700,
                            ),
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
                                borderSide: const BorderSide(
                                  color: Colors.deepOrange,
                                ),
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
                  );
                },
              ),

              if (_error != null) ...[
                SizedBox(height: 16 * scale),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14 * scale,
                    vertical: 12 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13 * scale,
                    ),
                  ),
                ),
              ],

              SizedBox(height: 28 * scale),

              SizedBox(
                height: 50 * scale,
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
                      : Text(
                          'Confirm & Send',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18 * scale,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
