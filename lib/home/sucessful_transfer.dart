import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:screenshot/screenshot.dart';
import 'receipt_page.dart';
import '../home/currency_con.dart'; // ✅ CurrencyConfig

class SuccessfulTransfer extends StatefulWidget {
  final double amount;
  final String paymentMethod;
  final String recipientName;
  final String bankName;
  final String accountNumber;
  final bool hideBankDetails; // ✅ used for GTag

  const SuccessfulTransfer({
    super.key,
    required this.amount,
    required this.paymentMethod,
    required this.recipientName,
    required this.bankName,
    required this.accountNumber,
    this.hideBankDetails = false,
    required bool isGTag, // ✅ fixed constructor
  });

  @override
  State<SuccessfulTransfer> createState() => _SuccessfulTransferState();
}

class _SuccessfulTransferState extends State<SuccessfulTransfer>
    with TickerProviderStateMixin {
  static const _success = Color(0xFF22C55E);
  static const _accent = Colors.deepOrange;

  late NumberFormat _formatter;
  late AnimationController _tickController;
  late AnimationController _cardSlideController;
  late Animation<double> _tickScale;
  late Animation<double> _tickOpacity;
  late Animation<Offset> _cardSlide;
  late ConfettiController _confettiController;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();

    _formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '',
      decimalDigits: 2,
    );

    _tickController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _tickScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _tickController, curve: Curves.elasticOut),
    );

    _tickOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _tickController, curve: Curves.easeIn));

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    _cardSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _cardSlideController,
            curve: Curves.easeOutCubic,
          ),
        );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _tickController.forward();
        _cardSlideController.forward();
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _tickController.dispose();
    _cardSlideController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  String _maskAccount(String account) {
    final digits = account.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 6) return account;
    return "${digits.substring(0, 4)} •••• ${digits.substring(digits.length - 2)}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subTextColor = isDark ? Colors.white38 : Colors.grey.shade600;
    final date = DateFormat("MMM d, yyyy • hh:mm a").format(DateTime.now());
    final ref = "#${Random().nextInt(99999999).toString().padLeft(8, '0')}";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        alignment: Alignment.center,
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 28,
            maxBlastForce: 50,
            minBlastForce: 8,
            gravity: 0.3,
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                // ── Tablet fix: cap width so the success card reads
                // as a tidy centered card instead of stretching ──
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeTransition(
                          opacity: _tickOpacity,
                          child: ScaleTransition(
                            scale: _tickScale,
                            child: Container(
                              height: 128,
                              width: 128,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [_success, Color(0xFF16A34A)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _success.withOpacity(0.35),
                                    blurRadius: 32,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                IconsaxPlusBold.tick_circle,
                                size: 78,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          "Payment Successful",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Your money is on its way",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13.5, color: subTextColor),
                        ),
                        const SizedBox(height: 28),

                        Screenshot(
                          controller: _screenshotController,
                          child: SlideTransition(
                            position: _cardSlide,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 24,
                              ),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.black.withOpacity(0.4)
                                        : Colors.black.withOpacity(0.06),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'AMOUNT',
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Shrinks to fit instead of overflowing
                                  // for large formatted amounts.
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "${CurrencyConfig().symbol}${_formatter.format(widget.amount)}",
                                      maxLines: 1,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: _success,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: subTextColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "Paid via ${widget.paymentMethod}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: subTextColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: subTextColor.withOpacity(0.12),
                                  ),
                                  const SizedBox(height: 14),

                                  // ✅ Conditionally show info
                                  _infoRow(
                                    widget.hideBankDetails
                                        ? "GTag ID"
                                        : "Recipient",
                                    widget.recipientName,
                                    theme,
                                    subTextColor,
                                  ),

                                  if (!widget.hideBankDetails) ...[
                                    _infoRow(
                                      "Bank",
                                      widget.bankName,
                                      theme,
                                      subTextColor,
                                    ),
                                    _infoRow(
                                      "Account No.",
                                      _maskAccount(widget.accountNumber),
                                      theme,
                                      subTextColor,
                                    ),
                                  ],

                                  _infoRow("Date", date, theme, subTextColor),

                                  if (!widget.hideBankDetails)
                                    _infoRow(
                                      "Ref No",
                                      ref,
                                      theme,
                                      subTextColor,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {
                                if (mounted) Navigator.pop(context);
                              },
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "Done",
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ✅ Hide receipt for GTag
                        if (!widget.hideBankDetails) ...[
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.black12,
                                    width: 1.2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () {
                                  if (!mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReceiptPage(
                                        amount: widget.amount,
                                        paymentMethod: widget.paymentMethod,
                                        recipientName: widget.recipientName,
                                        bankName: widget.bankName,
                                        accountNumber: widget.accountNumber,
                                        date: DateTime.now(),
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      IconsaxPlusBold.receipt_1,
                                      size: 17,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        "View Receipt",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String title,
    String value,
    ThemeData theme,
    Color subTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: subTextColor, fontSize: 13.5),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
