import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:globalpay/home/sucessful_transfer.dart';
import '../provider/balance_provider.dart';
import '../home/currency_con.dart';

class AmountSend extends StatefulWidget {
  final String image;
  final String name;
  final String account;
  final String bank;
  final double balance;
  final Function(double) onTransaction;

  const AmountSend({
    super.key,
    required this.image,
    required this.name,
    required this.account,
    required this.bank,
    required this.balance,
    required this.onTransaction,
  });

  @override
  State<AmountSend> createState() => _AmountSendState();
}

class _AmountSendState extends State<AmountSend> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _formatter = NumberFormat("#,##0");
  String _paymentMethod = 'Wallet';
  String _unit = "";
  late NumberFormat _currencyFormatter;

  @override
  void initState() {
    super.initState();

    _currencyFormatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: CurrencyConfig().symbol,
      decimalDigits: 2,
    );

    _amountCtrl.addListener(() {
      final raw = _amountCtrl.text.replaceAll(",", "");
      if (raw.isEmpty) {
        if (mounted) setState(() => _unit = "");
        return;
      }

      final value = int.tryParse(raw) ?? 0;
      final formatted = _formatter.format(value);

      if (_amountCtrl.text != formatted) {
        _amountCtrl.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }

      if (value < 100) _unit = "Tens";
      else if (value < 1000) _unit = "Hundreds";
      else if (value < 1000000) _unit = "Thousands";
      else if (value < 1000000000) _unit = "Millions";
      else _unit = "Billions";

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final raw = _amountCtrl.text.trim().replaceAll(',', '');
    final amount = double.tryParse(raw) ?? 0;
    if (amount <= 0) {
      _toast('Enter a valid amount');
      return;
    }
    if (amount > widget.balance) {
      _toast('Insufficient balance');
      return;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _openConfirmSheet(amount, isDark);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------- Confirm Sheet ----------
  void _openConfirmSheet(double amount, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final blurColor =
    isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.8);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: blurColor,
              padding: const EdgeInsets.all(20),
              child: Wrap(
                runSpacing: 18,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: AssetImage(widget.image),
                      radius: 28,
                    ),
                    title: Text(widget.name,
                        style: TextStyle(
                            color: textColor, fontWeight: FontWeight.w700)),
                    subtitle: Text(widget.bank,
                        style: TextStyle(color: textColor.withOpacity(0.6))),
                    trailing: Text(widget.account,
                        style: TextStyle(color: textColor.withOpacity(0.6))),
                  ),
                  _infoRow(
                      "Amount", _currencyFormatter.format(amount), textColor),
                  _infoRow("Payment Method", _paymentMethod, textColor),
                  _infoRow("Fee", "${CurrencyConfig().symbol}1.00", textColor),
                  _infoRow("Available",
                      _currencyFormatter.format(widget.balance), textColor),
                  if (_noteCtrl.text.isNotEmpty)
                    _infoRow("Note", _noteCtrl.text, textColor),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: EdgeInsets.all(40),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _openPinSheet(amount, isDark);
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6A00), Color(0xFFFF3D00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: const Text("Pay",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              // fontWeight: FontWeight.bold
                            )),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.7))),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 16)),
      ],
    );
  }

  // ---------- PIN Entry ----------
  void _openPinSheet(double amount, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hiddenCtrl = TextEditingController();
    final hiddenFocus = FocusNode();
    final pins = List<String>.filled(4, '');

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (sheetContext.mounted) {
            FocusScope.of(sheetContext).requestFocus(hiddenFocus);
          }
        });

        return Padding(
          padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 24,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Enter Transaction Pin",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () =>
                    FocusScope.of(sheetContext).requestFocus(hiddenFocus),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (i) {
                    final filled = pins[i].isNotEmpty;
                    final currentLen =
                        hiddenCtrl.text.replaceAll(RegExp(r'\s+'), '').length;
                    final isCursorBox = currentLen == i;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 55,
                      height: 55,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: filled
                                ? Colors.deepOrange
                                : isCursorBox
                                ? Colors.deepOrange
                                : Colors.grey.shade500,
                            width: isCursorBox ? 2 : 1.2),
                        color: filled
                            ? Colors.deepOrange.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                      child: filled
                          ? Text('•',
                          style: TextStyle(
                              fontSize: 28,
                              color: textColor,
                              fontWeight: FontWeight.bold))
                          : const SizedBox.shrink(),
                    );
                  }),
                ),
              ),
              Opacity(
                opacity: 0,
                child: TextField(
                  controller: hiddenCtrl,
                  focusNode: hiddenFocus,
                  maxLength: 4,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final cleaned = v.replaceAll(RegExp(r'\s+'), '');
                    for (int i = 0; i < 4; i++) {
                      pins[i] = i < cleaned.length ? cleaned[i] : '';
                    }
                    setState(() {});
                    if (cleaned.length == 4) {
                      Future.delayed(const Duration(milliseconds: 200), () {
                        Navigator.pop(sheetContext);
                        _processPayment(amount);
                      });
                    }
                  },
                  decoration: const InputDecoration(counterText: ''),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _processPayment(double amount) {
    UserBalance.instance.balance -= amount;
    widget.onTransaction(amount);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SuccessfulTransfer(
          amount: amount,
          paymentMethod: _paymentMethod,
          recipientName: widget.name,
          bankName: widget.bank,
          accountNumber: widget.account, isGTag: false,
        ),
      ),
    );
  }

  // ---------- MAIN UI ----------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF8F9FB);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final masked = _maskAccount(widget.account);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Send Money",
            style: TextStyle()),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Recipient Info
          Container(
            decoration: BoxDecoration(
              // gradient: const LinearGradient(
              color: cardColor,
              // begin: Alignment.topLeft,
              // end: Alignment.bottomRight,
              // ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(widget.image),
                  radius: 30,
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name,
                        style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 18)),
                    Text(widget.bank,
                        style: TextStyle(
                            color: textColor, fontSize: 13)),
                    Text(masked,
                        style: TextStyle(color: textColor)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Amount Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: false),
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textColor),
                      decoration: InputDecoration(
                        prefixText: '${CurrencyConfig().symbol} ',
                        prefixStyle:
                        TextStyle(fontSize: 22, color: textColor),
                        labelText: 'Enter amount',
                        labelStyle:
                        TextStyle(color: textColor.withOpacity(0.6)),
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        const Icon(IconsaxPlusBold.wallet,
                            color: Colors.deepOrange),
                        const SizedBox(width: 8),
                        Text(
                            "Balance: ${_currencyFormatter.format(widget.balance)}",
                            style: TextStyle(
                                color: textColor.withOpacity(0.7),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                if (_unit.isNotEmpty)
                  Positioned(
                    top: -10,
                    right: 10,
                    child: Chip(
                      label: Text(
                        _unit,
                        style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600),
                      ),
                      avatar: const Icon(IconsaxPlusBold.activity,
                          size: 18, color: Colors.deepOrange),
                      backgroundColor: Colors.deepOrange.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Optional Note
          TextField(
            controller: _noteCtrl,
            maxLength: 50,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: "Add a note (optional)",
              labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),

          // Send Button
          SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6A00), Color(0xFFFF3D00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: const Text("Confirm to Pay",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        // fontWeight: FontWeight.bold
                      )),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _maskAccount(String account) {
    final digits = account.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 6) return account;
    return "${digits.substring(0, 4)} •••• ${digits.substring(digits.length - 2)}";
  }
}
