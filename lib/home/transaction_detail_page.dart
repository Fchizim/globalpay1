import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
// import '../../../../res/app_colors.dart';
import 'airtime_receipt.dart';

class TransactionDetailScreen extends StatelessWidget {
  final int amount;
  final String network;
  final String action;
  final String phone;
  final String transactionId;
  final String ref;
  final double newBalance;

  // ── Real status from the backend (bill_transactions.payment_status) ──────
  // Expected values: 'success', 'failed', 'pending', 'partial' (case-insensitive).
  // 'partial' = a finished bulk batch with some successes and some failures —
  // distinct from 'pending', which means still processing.
  final String paymentStatus;
  // Optional — bill_transactions.response_message, shown when not successful
  // so the user knows *why* (e.g. "Invaild Amount", "Your API request is
  // yet to be approve").
  final String? responseMessage;

  // ── Optional electricity fields ──────────────────────────
  final String? eleToken;
  final String? eleUnits;
  final String? eleMeter;
  final String? customerName;
  final String? customerAddress;
  final String? billType;
  final String? examPin;
  final String? examSerial;

  const TransactionDetailScreen({
    super.key,
    required this.amount,
    required this.network,
    required this.action,
    required this.phone,
    required this.transactionId,
    required this.ref,
    required this.newBalance,
    required this.paymentStatus,
    this.responseMessage,
    this.eleToken,
    this.eleUnits,
    this.eleMeter,
    this.customerName,
    this.customerAddress,
    this.billType,
    this.examPin,
    this.examSerial,
  });

  String get _transactionTypeLabel {
    switch (action.toUpperCase()) {
      case 'DATA':    return 'Data Purchase';
      case 'ELE':     return 'Electricity';
      case 'AIRTIME': return 'Airtime Top-up';
      case 'CABLE':   return 'Cable TV';
      case 'BETTING': return 'Betting';
      case 'EXAM':    return 'Exam Card';
      case 'A2C':     return 'Airtime to Cash';
      default:        return action;
    }
  }

  bool get _isSuccess => paymentStatus.toLowerCase() == 'success';
  bool get _isFailed  => paymentStatus.toLowerCase() == 'failed';
  bool get _isPartial => paymentStatus.toLowerCase() == 'partial';
  // Anything that's neither success, failed, nor partial (e.g. 'pending',
  // 'processing') falls into pending.

  @override
  Widget build(BuildContext context) {
    final String time         = DateFormat('HH:mm, MMM dd, yyyy').format(DateTime.now());
    final numFormat           = NumberFormat.decimalPattern('en_US');
    final bool isDark         = Theme.of(context).brightness == Brightness.dark;
    final Color primary       = Colors.deepOrange;
    final Color textPrimary   = isDark ? Colors.white : const Color(0xFF111827);
    final Color textSecondary = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final Color cardColor     = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final Color background    = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF9FAFB);
    final Color borderColor   = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.grey.shade300.withOpacity(0.7);

    final bool isEle = action.toUpperCase() == 'ELE';
    final bool isExam = action.toUpperCase() == 'EXAM';

    // ── Status presentation (this is the actual fix) ────────────────────────
    final Color statusColor = _isSuccess
        ? const Color(0xFF22C55E)
        : _isFailed
        ? const Color(0xFFEF4444)
        : _isPartial
        ? const Color(0xFFF97316) // finished, mixed results
        : const Color(0xFF3B82F6); // still processing
    final IconData statusIcon = _isSuccess
        ? Icons.check_circle
        : _isFailed
        ? Icons.cancel
        : _isPartial
        ? Icons.warning_amber_rounded
        : Icons.access_time_filled;
    final String statusLabel = _isSuccess
        ? 'Successful'
        : _isFailed
        ? 'Failed'
        : _isPartial
        ? 'Partially Successful'
        : 'Pending';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text('Transaction Detail',
            style: TextStyle(color: textPrimary,
                fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? Colors.white70 : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: SingleChildScrollView(
          child: Column(children: [

            // ── Summary card ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(color: Colors.black.withOpacity(0.05),
                        blurRadius: 6, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(children: [
                Text(network.toUpperCase(),
                    style: TextStyle(fontSize: 15, color: textPrimary)),
                const SizedBox(height: 8),
                Text('₦${numFormat.format(amount)}',
                    style: TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 26, color: textPrimary)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 18),
                    const SizedBox(width: 5),
                    Text(statusLabel,
                        style: TextStyle(color: statusColor,
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
                // Show the failure reason from the backend when it's not a
                // success, instead of leaving the user guessing.
                if (!_isSuccess && (responseMessage?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 6),
                  Text(
                    responseMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textSecondary, fontSize: 12.5),
                  ),
                ],
                const SizedBox(height: 5),
                Divider(color: borderColor),
                const SizedBox(height: 5),
                _buildRow('Order Amount',
                    '₦${numFormat.format(amount)}', isDark),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Details card ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(children: [
                if (isEle) ...[
                  if (customerName?.isNotEmpty == true)
                    _buildRow('Customer Name', customerName!, isDark),
                  if (customerAddress?.isNotEmpty == true)
                    _buildRow('Address', customerAddress!, isDark),
                  _buildRow('Meter Number', eleMeter ?? phone, isDark),
                  _buildRow('Bill Type', billType ?? 'Prepaid', isDark),
                ] else
                  _buildRow('Recipient', phone, isDark),
                _buildRow('Network',          network,               isDark),
                _buildRow('Transaction Type', _transactionTypeLabel, isDark),
                if (isExam) ...[
                  if (examPin?.isNotEmpty == true)
                    _buildRow('Exam PIN', examPin!, isDark),

                  if (examSerial?.isNotEmpty == true)
                    _buildRow('Serial', examSerial!, isDark),
                ],

                // Electricity token/units only make sense on a successful
                // transaction — a failed ELE purchase has none.
                if (isEle && _isSuccess && eleUnits?.isNotEmpty == true)
                  _buildRow('Units', '${eleUnits}kWh', isDark),
                _buildCopyRow(context, 'Transaction ID', transactionId, isDark),
                _buildCopyRow(context, 'Reference',      ref,           isDark),
                _buildRow('Date & Time',     time,     isDark),
                _buildRow('Payment Method', 'Wallet',  isDark),
              ]),
            ),

            // ── Electricity token box (only shown on success) ─────────
            if (isEle && _isSuccess && eleToken?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.green.withOpacity(0.3), width: 1.5),
                ),
                child: Column(children: [
                  Text('ELECTRICITY TOKEN',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade700,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  Text(eleToken!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                          color: Colors.black87)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: eleToken!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Token copied to clipboard'),
                              duration: Duration(seconds: 1)),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy Token'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: BorderSide(color: Colors.green.shade400),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 20),

            // ── View Receipt Button (only meaningful for a real success) ─
            if (_isSuccess)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TransactionReceiptScreen(
                          amount: amount,
                          action: action,
                          network: network,
                          recipientPhone: phone,
                          payerPhone: phone,
                          transactionId: transactionId,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.receipt_long, color: primary),
                  label: Text('View Receipt',
                      style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            const SizedBox(height: 80),
          ]),
        ),
      ),
    );
  }

  static Widget _buildRow(String title, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 14)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  static Widget _buildCopyRow(BuildContext context,
      String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Text(label,
            style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14)),
        const Spacer(),
        Flexible(
          child: Text(value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label copied'),
                  duration: const Duration(seconds: 1)),
            );
          },
          child: Icon(Icons.copy, size: 16,
              color: isDark ? Colors.grey[400] : Colors.grey),
        ),
      ]),
    );
  }
}