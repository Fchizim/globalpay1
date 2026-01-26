import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

// =================== SUCCESS PAGE ===================
class GTagSuccessfulPayment extends StatefulWidget {
  final double amount;
  final String gTagID;
  final String recipientTag; // ← added properly

  const GTagSuccessfulPayment({
    super.key,
    required this.amount,
    required this.gTagID,
    required this.recipientTag,
  });

  @override
  State<GTagSuccessfulPayment> createState() => _GTagSuccessfulPaymentState();
}

class _GTagSuccessfulPaymentState extends State<GTagSuccessfulPayment>
    with TickerProviderStateMixin {
  late AnimationController _tickController;
  late AnimationController _cardSlideController;
  late Animation<double> _tickScale;
  late Animation<double> _tickOpacity;
  late Animation<Offset> _cardSlide;
  late ConfettiController _confettiController;
  final _formatter = NumberFormat.currency(locale: 'en_NG', symbol: '₦');

  @override
  void initState() {
    super.initState();

    _tickController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _tickScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _tickController, curve: Curves.elasticOut),
    );

    _tickOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _tickController, curve: Curves.easeIn),
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    _cardSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _cardSlideController, curve: Curves.easeOutCubic),
    );

    Future.delayed(const Duration(milliseconds: 250), () {
      _tickController.forward();
      _cardSlideController.forward();
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _tickController.dispose();
    _cardSlideController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0E0E0E) : Colors.grey[100];
    final cardColor = isDark ? const Color(0xFF1C1C1C) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        alignment: Alignment.center,
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: 25,
            gravity: 0.4,
            colors: const [
              Colors.deepOrange,
              Colors.greenAccent,
              Colors.blueAccent,
              Colors.amber,
            ],
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _tickOpacity,
                      child: ScaleTransition(
                        scale: _tickScale,
                        child: Container(
                          height: 130,
                          width: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.deepOrange.shade400,
                                Colors.orange.shade700
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepOrange.withOpacity(0.3),
                                blurRadius: 25,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            IconsaxPlusBold.tick_circle,
                            size: 85,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      "Payment Successful ✔️",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Transaction completed securely",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Animated transaction card
                    SlideTransition(
                      position: _cardSlide,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 24),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _formatter.format(widget.amount),
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Divider(thickness: 0.7),
                            const SizedBox(height: 10),
                            _infoRow("GTag", widget.recipientTag, theme),
                            const SizedBox(height: 10),
                            _infoRow(
                              "Date",
                              DateFormat("MMM d, yyyy • hh:mm a")
                                  .format(DateTime.now()),
                              theme,
                            ),
                          ],
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 80, vertical: 15),
                        elevation: 6,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Done",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey[600],
            fontSize: 15,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
