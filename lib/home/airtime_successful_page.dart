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
  bool get _isFailed  => widget.paymentStatus.toLowerCase() == 'failed';
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
    _fadeAnim  = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
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

  @override
  Widget build(BuildContext context) {
    final bool isDark       = Theme.of(context).brightness == Brightness.dark;
    final Color greenSuccess  = const Color(0xFF22C55E);
    final Color redFailed     = const Color(0xFFEF4444);
    final Color orangePartial = const Color(0xFFF97316); // finished, mixed results
    final Color bluePending   = const Color(0xFF3B82F6); // still processing
    final Color statusColor   = _isSuccess
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

    final Color primary      = Colors.deepOrange;
    final Color bgColor      = isDark ? const Color(0xFF0D0D0D) : Colors.white;
    final Color cardColor    = isDark
        ? Colors.grey[900]!.withOpacity(0.6)
        : Colors.white.withOpacity(0.95);
    final Color textColor    = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final numFormat          = NumberFormat.decimalPattern('en_US');

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
                Colors.deepOrange, Colors.green,
                Colors.amber, Colors.orangeAccent, Colors.white,
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // ── Status icon ────────────────────────────────────────
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [statusColor, statusColor.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [BoxShadow(
                            color: statusColor.withOpacity(0.4),
                            blurRadius: 25, spreadRadius: 3)],
                      ),
                      child: Icon(statusIcon, color: Colors.white, size: 60),
                    ),
                  ),
                  const SizedBox(height: 15),

                  Text(statusHeading,
                      style: TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 5),

                  Text('₦${numFormat.format(widget.amount)}',
                      style: TextStyle(fontSize: 30,
                          fontWeight: FontWeight.w600, color: textColor)),

                  // Show the backend's failure/pending reason when available.
                  if (!_isSuccess && (widget.responseMessage?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.responseMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: subTextColor, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 30),

                  // ── Info card ──────────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(children: [

                        // Recipient
                        Row(children: [
                          Text('Recipient',
                              style: TextStyle(color: subTextColor)),
                          const Spacer(),
                          Text(widget.phone,
                              style: TextStyle(fontSize: 15,
                                  fontWeight: FontWeight.w600, color: primary)),
                        ]),
                        const SizedBox(height: 16),

                        // Network
                        Row(children: [
                          Text('Network',
                              style: TextStyle(color: subTextColor)),
                          const Spacer(),
                          Text(widget.network,
                              style: TextStyle(fontSize: 14,
                                  fontWeight: FontWeight.w600, color: textColor)),
                        ]),
                        const SizedBox(height: 16),

                        // Transaction ID
                        Row(children: [
                          Text('Transaction ID',
                              style: TextStyle(color: subTextColor)),
                          const Spacer(),
                          Flexible(
                            child: Text(widget.transactionId,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textColor)),
                          ),
                        ]),
                        const SizedBox(height: 16),

                        // New balance
                        Row(children: [
                          Text('New Balance',
                              style: TextStyle(color: subTextColor)),
                          const Spacer(),
                          Text('₦${numFormat.format(widget.newBalance)}',
                              style: TextStyle(fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: greenSuccess)),
                        ]),
                        const SizedBox(height: 16),

                        // View details
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      TransactionDetailScreen(
                                        amount:        widget.amount,
                                        network:       widget.network,
                                        phone:         widget.phone,
                                        transactionId: widget.transactionId,
                                        ref:           widget.ref,
                                        newBalance:    widget.newBalance,
                                        action: widget.action,
                                        paymentStatus: widget.paymentStatus,
                                        responseMessage: widget.responseMessage,
                                      )
                              )
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('View Details',
                                  style: TextStyle(fontSize: 14,
                                      color: primary,
                                      fontWeight: FontWeight.w500)),
                              Icon(Icons.keyboard_arrow_right_outlined,
                                  color: primary, size: 20),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // ── Done button ────────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: const Text('Done',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}