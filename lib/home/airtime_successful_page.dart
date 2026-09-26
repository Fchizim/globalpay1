import 'package:flutter/material.dart';
import 'package:globalpay/home/transaction_detail_page.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';

class AirtimeSuccessScreen extends StatefulWidget {
  final int amount;
  final String network;
  final String phone;
  final String transactionId;
  final String ref;
  final double newBalance;
  final String action;

  // ── Real status from the backend (bill_transactions.payment_status) ──────
  // Expected values: 'success', 'failed', 'pending', 'partial' (case-insensitive).
  // 'partial' is distinct from 'pending' — it means the batch is FINISHED
  // and some items succeeded while others failed (bulk airtime), not that
  // something is still processing.
  // This screen is reachable even when the purchase failed or is pending, so
  // it must reflect that instead of always showing a success celebration.
  final String paymentStatus;
  final String? responseMessage;

  const AirtimeSuccessScreen({
    super.key,
    required this.amount,
    required this.network,
    required this.phone,
    required this.transactionId,
    required this.ref,
    required this.newBalance,
    required this.action,
    required this.paymentStatus,
    this.responseMessage,
  });

  @override
  State<AirtimeSuccessScreen> createState() => _AirtimeSuccessScreenState();
}

class _AirtimeSuccessScreenState extends State<AirtimeSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late ConfettiController _confettiController;

  bool get _isSuccess => widget.paymentStatus.toLowerCase() == 'success';
  bool get _isFailed => widget.paymentStatus.toLowerCase() == 'failed';
  bool get _isPartial => widget.paymentStatus.toLowerCase() == 'partial';
  // anything else (e.g. 'pending', 'processing') is treated as still-pending

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    // Only celebrate an actual success.
    if (_isSuccess) {
      Future.delayed(const Duration(milliseconds: 400), () {
        _confettiController.play();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // Reusable info-card row that never overflows: label stays fixed/flexible
  // on the left, value is wrapped in Flexible + ellipsis on the right so
  // long phone numbers, network names, or IDs shrink instead of pushing
  // past the card edge.
  static Widget _infoRow(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
    double scale, {
    FontWeight valueWeight = FontWeight.w600,
    double valueFontSize = 14,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(color: labelColor, fontSize: 13 * scale),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: valueFontSize * scale,
              fontWeight: valueWeight,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color greenSuccess = const Color(0xFF22C55E);
    final Color redFailed = const Color(0xFFEF4444);
    final Color orangePartial = const Color(
      0xFFF97316,
    ); // finished, mixed results
    final Color bluePending = const Color(0xFF3B82F6); // still processing
    final Color statusColor = _isSuccess
        ? greenSuccess
        : _isFailed
        ? redFailed
        : _isPartial
        ? orangePartial
        : bluePending;
    final IconData statusIcon = _isSuccess
        ? Icons.check
        : _isFailed
        ? Icons.close
        : _isPartial
        ? Icons.warning_amber_rounded
        : Icons.access_time_filled;
    final String statusHeading = _isSuccess
        ? 'Payment Successful'
        : _isFailed
        ? 'Payment Failed'
        : _isPartial
        ? 'Partially Successful'
        : 'Payment Pending';

    final Color primary = Colors.deepOrange;
    final Color bgColor = isDark ? const Color(0xFF0D0D0D) : Colors.white;
    final Color cardColor = isDark
        ? Colors.grey[900]!.withOpacity(0.6)
        : Colors.white.withOpacity(0.95);
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final numFormat = NumberFormat.decimalPattern('en_US');

    // Screen-size aware scaling so this screen looks right on small and
    // large phones/tablets instead of using fixed pixel values everywhere.
    final double screenWidth = MediaQuery.of(context).size.width;
    final double scale = (screenWidth / 390.0).clamp(0.85, 1.15);
    // Icon circle and confetti radius should also shrink a bit on small
    // screens so they never crowd the status heading below them.
    final double iconCircleSize = 60 * scale;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Confetti only plays on an actual success (see initState), but
            // keep the widget in the tree either way so its controller is
            // always valid to dispose.
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 25,
              maxBlastForce: 25,
              minBlastForce: 5,
              gravity: 0.2,
              colors: const [
                Colors.deepOrange,
                Colors.green,
                Colors.amber,
                Colors.orangeAccent,
                Colors.white,
              ],
            ),
            // SingleChildScrollView so that on small phones (or with large
            // system text scale) the content can scroll instead of
            // overflowing vertically off the bottom of the screen.
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 24 * scale,
                vertical: 16 * scale,
              ),
              child: ConstrainedBox(
                // Keeps the whole column centered and capped in width on
                // tablets/large screens rather than stretching edge to edge.
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Status icon ────────────────────────────────────────
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Container(
                        padding: EdgeInsets.all(20 * scale),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [statusColor, statusColor.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withOpacity(0.4),
                              blurRadius: 25,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Icon(
                          statusIcon,
                          color: Colors.white,
                          size: iconCircleSize,
                        ),
                      ),
                    ),
                    SizedBox(height: 15 * scale),

                    Text(
                      statusHeading,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20 * scale,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 5 * scale),

                    // FittedBox so a very large amount never overflows the
                    // screen width, it just scales down instead.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '₦${numFormat.format(widget.amount)}',
                        style: TextStyle(
                          fontSize: 30 * scale,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),

                    // Show the backend's failure/pending reason when available.
                    if (!_isSuccess &&
                        (widget.responseMessage?.isNotEmpty ?? false)) ...[
                      SizedBox(height: 8 * scale),
                      Text(
                        widget.responseMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 13 * scale,
                        ),
                      ),
                    ],
                    SizedBox(height: 30 * scale),

                    // ── Info card ──────────────────────────────────────────
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(22 * scale),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          children: [
                            // Recipient — FIX: value was a bare Text with no
                            // Expanded/ellipsis, so a long phone number or
                            // formatted number could overflow past the card.
                            _infoRow(
                              'Recipient',
                              widget.phone,
                              subTextColor,
                              primary,
                              scale,
                              valueFontSize: 15,
                            ),
                            SizedBox(height: 16 * scale),

                            // Network
                            _infoRow(
                              'Network',
                              widget.network,
                              subTextColor,
                              textColor,
                              scale,
                            ),
                            SizedBox(height: 16 * scale),

                            // Transaction ID (already had Flexible, kept but
                            // unified with the shared scale + ellipsis logic)
                            _infoRow(
                              'Transaction ID',
                              widget.transactionId,
                              subTextColor,
                              textColor,
                              scale,
                              valueFontSize: 13,
                            ),
                            SizedBox(height: 16 * scale),

                            // New balance
                            _infoRow(
                              'New Balance',
                              '₦${numFormat.format(widget.newBalance)}',
                              subTextColor,
                              greenSuccess,
                              scale,
                            ),
                            SizedBox(height: 16 * scale),

                            // View details
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TransactionDetailScreen(
                                    amount: widget.amount,
                                    network: widget.network,
                                    phone: widget.phone,
                                    transactionId: widget.transactionId,
                                    ref: widget.ref,
                                    newBalance: widget.newBalance,
                                    action: widget.action,
                                    paymentStatus: widget.paymentStatus,
                                    responseMessage: widget.responseMessage,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'View Details',
                                    style: TextStyle(
                                      fontSize: 14 * scale,
                                      color: primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_right_outlined,
                                    color: primary,
                                    size: 20 * scale,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 50 * scale),

                    // ── Done button ────────────────────────────────────────
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                            minimumSize: Size.fromHeight(52 * scale),
                          ),
                          child: Text(
                            'Done',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17 * scale,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
