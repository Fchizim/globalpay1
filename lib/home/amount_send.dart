import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:globalpay/home/sucessful_transfer.dart';
import '../provider/balance_provider.dart';
import '../home/currency_con.dart';
import 'withdrawal_service.dart'; // adjust path if needed

class AmountSend extends StatefulWidget {
  final String image;
  final String name; // display label, e.g. "Bank Transfer"
  final String account;
  final String bank;
  final double balance;
  final Function(double) onTransaction;

  // ── Required for the actual backend withdrawal call ──
  final String userId;
  final String bankCode;
  final String accountHolderName; // the flutterwave-verified name, not `name`

  const AmountSend({
    super.key,
    required this.image,
    required this.name,
    required this.account,
    required this.bank,
    required this.balance,
    required this.onTransaction,
    required this.userId,
    required this.bankCode,
    required this.accountHolderName,
  });

  @override
  State<AmountSend> createState() => _AmountSendState();
}

class _AmountSendState extends State<AmountSend> {
  static const _accent = Colors.deepOrange;
  static const _gradientStart = Color(0xFFFF6A00);
  static const _gradientEnd = Color(0xFFFF3D00);

  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _formatter = NumberFormat("#,##0");
  final String _paymentMethod = 'Wallet';
  String _unit = "";
  late NumberFormat _currencyFormatter;
  bool _isProcessing = false;

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

      if (value < 100) {
        _unit = "Tens";
      } else if (value < 1000) {
        _unit = "Hundreds";
      } else if (value < 1000000) {
        _unit = "Thousands";
      } else if (value < 1000000000) {
        _unit = "Millions";
      } else {
        _unit = "Billions";
      }

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
    if (amount < 100) {
      _toast('Minimum withdrawal is ${CurrencyConfig().symbol}100');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  Widget _payButton({required VoidCallback? onPressed, required String label}) {
    final disabled = onPressed == null;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        child: Opacity(
          opacity: disabled ? 0.6 : 1,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_gradientStart, _gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _gradientEnd.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Confirm Sheet ----------
  void _openConfirmSheet(double amount, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? Colors.white38 : Colors.grey.shade600;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.97),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Text(
                    'Confirm Transfer',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: subTextColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: AssetImage(widget.image),
                          radius: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.accountHolderName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.bank,
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          widget.account,
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _infoRow(
                    "Amount",
                    _currencyFormatter.format(amount),
                    textColor,
                    subTextColor,
                    emphasize: true,
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    "Payment method",
                    _paymentMethod,
                    textColor,
                    subTextColor,
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    "Available balance",
                    _currencyFormatter.format(widget.balance),
                    textColor,
                    subTextColor,
                  ),
                  if (_noteCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _infoRow("Note", _noteCtrl.text, textColor, subTextColor),
                  ],
                  const SizedBox(height: 22),
                  _payButton(
                    label: "Pay ${_currencyFormatter.format(amount)}",
                    onPressed: () {
                      Navigator.pop(context);
                      _openPinSheet(amount, isDark);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(
    String label,
    String value,
    Color textColor,
    Color subTextColor, {
    bool emphasize = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: subTextColor, fontSize: 13.5)),
        Text(
          value,
          style: TextStyle(
            color: emphasize ? _accent : textColor,
            fontWeight: FontWeight.w700,
            fontSize: emphasize ? 17 : 14,
          ),
        ),
      ],
    );
  }

  // ---------- PIN Entry ----------
  void _openPinSheet(double amount, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? Colors.white38 : Colors.grey.shade600;
    final hiddenCtrl = TextEditingController();
    final hiddenFocus = FocusNode();
    final pins = List<String>.filled(4, '');

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (sheetContext.mounted) {
            FocusScope.of(sheetContext).requestFocus(hiddenFocus);
          }
        });

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 22),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded, color: _accent, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                "Enter Transaction PIN",
                style: TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Confirm ${_currencyFormatter.format(amount)} to ${widget.accountHolderName}",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: subTextColor),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () =>
                    FocusScope.of(sheetContext).requestFocus(hiddenFocus),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (i) {
                    final filled = pins[i].isNotEmpty;
                    final currentLen = hiddenCtrl.text
                        .replaceAll(RegExp(r'\s+'), '')
                        .length;
                    final isCursorBox = currentLen == i;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: filled || isCursorBox
                              ? _accent
                              : (isDark
                                    ? Colors.white24
                                    : Colors.grey.shade300),
                          width: isCursorBox ? 2 : 1.2,
                        ),
                        color: filled
                            ? _accent.withOpacity(0.1)
                            : (isDark
                                  ? Colors.white.withOpacity(0.03)
                                  : Colors.grey.shade50),
                      ),
                      child: filled
                          ? Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _accent,
                                shape: BoxShape.circle,
                              ),
                            )
                          : const SizedBox.shrink(),
                    );
                  }),
                ),
              ),
              Opacity(
                opacity: 0,
                child: SizedBox(
                  height: 1,
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
                          // ── The actual fix: PIN is now passed through ──
                          _processPayment(amount, cleaned);
                        });
                      }
                    },
                    decoration: const InputDecoration(counterText: ''),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- Actual backend call ----------
  Future<void> _processPayment(double amount, String pin) async {
    if (_isProcessing) return; // guard against double-submit
    setState(() => _isProcessing = true);

    // Blocking loader while the withdrawal request is in flight.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: _accent)),
    );

    try {
      final result = await WithdrawalService.withdraw(
        userId: widget.userId,
        accountNumber: widget.account.replaceAll(RegExp(r'\D'), ''),
        bankCode: widget.bankCode,
        bankName: widget.bank,
        accountName: widget.accountHolderName,
        amount: amount,
        pin: pin,
      );

      if (!mounted) return;
      Navigator.pop(context); // close loader

      final status = result['status'] as String?;
      final message =
          (result['message'] as String?) ??
          'Withdrawal could not be processed.';

      if (status == 'success') {
        UserBalance.instance.balance -= amount;
        widget.onTransaction(amount);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SuccessfulTransfer(
              amount: amount,
              paymentMethod: _paymentMethod,
              recipientName: widget.accountHolderName,
              bankName: widget.bank,
              accountNumber: widget.account,
              isGTag: false,
            ),
          ),
        );
      } else {
        _toast(message);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loader
      _toast('Could not process withdrawal. Please try again.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ---------- MAIN UI ----------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFAFAFA);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? Colors.white38 : Colors.grey.shade600;
    final fieldFill = isDark
        ? const Color(0xFF232323)
        : const Color(0xFFF5F5F5);
    final masked = _maskAccount(widget.account);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "Send Money",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // ── Recipient card ──
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.4)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(widget.image),
                  radius: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.accountHolderName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.bank,
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        masked,
                        style: TextStyle(color: subTextColor, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF22C55E),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Amount card ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.4)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AMOUNT',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                      ),
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        prefixText: '${CurrencyConfig().symbol} ',
                        prefixStyle: TextStyle(
                          fontSize: 24,
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: subTextColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: subTextColor.withOpacity(0.15), height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            IconsaxPlusBold.wallet,
                            color: _accent,
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Balance: ${_currencyFormatter.format(widget.balance)}",
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_unit.isNotEmpty)
                  Positioned(
                    top: -8,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            IconsaxPlusBold.activity,
                            size: 13,
                            color: _accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _unit,
                            style: const TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _noteCtrl,
            maxLength: 50,
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              labelText: "Add a note (optional)",
              labelStyle: TextStyle(color: subTextColor, fontSize: 13.5),
              filled: true,
              fillColor: fieldFill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _accent, width: 1.5),
              ),
              counterStyle: TextStyle(color: subTextColor, fontSize: 11),
            ),
          ),
          const SizedBox(height: 22),

          _payButton(
            label: "Confirm to Pay",
            onPressed: _isProcessing ? null : _send,
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
