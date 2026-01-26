import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
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
    this.hideBankDetails = false, required bool isGTag, // ✅ fixed constructor
  });

  @override
  State<SuccessfulTransfer> createState() => _SuccessfulTransferState();
}

class _SuccessfulTransferState extends State<SuccessfulTransfer>
    with TickerProviderStateMixin {
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

    _formatter = NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 2);

    _tickController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _tickScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _tickController, curve: Curves.elasticOut),
    );

    _tickOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _tickController, curve: Curves.easeIn),
    );

    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    _cardSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _cardSlideController, curve: Curves.easeOutCubic),
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
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _tickOpacity,
                    child: ScaleTransition(
                      scale: _tickScale,
                      child: Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00C853), Color(0xFF4CAF50)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.shade200,
                              blurRadius: 30,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          IconsaxPlusBold.tick_circle,
                          size: 95,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    "Payment Successful 🎉",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Screenshot(
                    controller: _screenshotController,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 28),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              "${CurrencyConfig().symbol}${_formatter.format(widget.amount)}",
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Paid via ${widget.paymentMethod}",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const Divider(height: 28, thickness: 0.7),

                            // ✅ Conditionally show info
                            _infoRow(
                              widget.hideBankDetails ? "GTag ID" : "Recipient",
                              widget.recipientName,
                              theme,
                            ),

                            if (!widget.hideBankDetails) ...[
                              _infoRow("Bank", widget.bankName, theme),
                              _infoRow("Account No.", _maskAccount(widget.accountNumber), theme),
                            ],

                            _infoRow("Date", date, theme),

                            if (!widget.hideBankDetails)
                              _infoRow("Ref No", ref, theme),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 45),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
                    ),
                    onPressed: () {
                      if (mounted) Navigator.pop(context);
                    },
                    child: const Text(
                      "Done",
                      style: TextStyle(fontSize: 17, color: Colors.white),
                    ),
                  ),

                  // ✅ Hide receipt for GTag
                  if (!widget.hideBankDetails) ...[
                    const SizedBox(height: 14),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
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
                      child: const Text(
                        "View Receipt",
                        style: TextStyle(fontSize: 17, color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onBackground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
