import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';

// ─────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────

class TransactionModel {
  final String transactionId;
  final String serviceType;
  final String serviceRefId;
  final String amount;
  final String paymentMethod;
  final String paymentStatus;
  final String purpose;
  final String transactionDate;
  final String referenceCode;
  final String referenceId;
  final String paymentType;
  final String status;
  final Map<String, dynamic>? metadata;

  const TransactionModel({
    required this.transactionId,
    required this.serviceType,
    required this.serviceRefId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.purpose,
    required this.transactionDate,
    required this.referenceCode,
    required this.referenceId,
    required this.paymentType,
    required this.status,
    this.metadata,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> j) => TransactionModel(
    transactionId:   j['transaction_id']?.toString() ?? '',
    serviceType:     j['service_type']?.toString()   ?? '',
    serviceRefId:    j['service_ref_id']?.toString() ?? '',
    amount:          j['amount']?.toString()         ?? '0.00',
    paymentMethod:   j['payment_method']?.toString() ?? '',
    paymentStatus:   j['payment_status']?.toString() ?? '',
    purpose:         j['purpose']?.toString()        ?? '',
    transactionDate: j['transaction_date']?.toString() ?? '',
    referenceCode:   j['reference_code']?.toString() ?? '',
    referenceId:     j['reference_id']?.toString()   ?? '',
    paymentType:     j['payment_type']?.toString()   ?? '',
    status:          j['status']?.toString()         ?? 'active',
    metadata:        j['metadata'] as Map<String, dynamic>?,
  );

  bool get isCredit {
    final type = paymentType.toLowerCase();
    final stype = serviceType.toLowerCase();
    return type == 'credit' ||
        stype.contains('receive') ||
        stype.contains('fund') ||
        stype.contains('top') ||
        stype.contains('refund');
  }

  bool get isSuccessful {
    final s = paymentStatus.toLowerCase();
    return s == 'successful' || s == 'success' || s == 'completed';
  }

  String get formattedDate {
    try {
      final dt = DateTime.parse(transactionDate);
      return DateFormat('dd MMM yyyy • hh:mm a').format(dt);
    } catch (_) {
      return transactionDate;
    }
  }

  String get displayTitle {
    if (purpose.isNotEmpty) return purpose;
    if (serviceType.isNotEmpty) return _capitalize(serviceType.replaceAll('_', ' '));
    return 'Transaction';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─────────────────────────────────────────────────────────────
// Transaction List Widget  (drop-in replacement for the
// _buildRecentTransactions section in HomePage)
// ─────────────────────────────────────────────────────────────

class TransactionListWidget extends StatefulWidget {
  final Color cardColor;
  final Color textColor;
  final Color hintColor;
  final bool isDark;

  const TransactionListWidget({
    super.key,
    required this.cardColor,
    required this.textColor,
    required this.hintColor,
    required this.isDark,
  });

  @override
  State<TransactionListWidget> createState() => _TransactionListWidgetState();
}

class _TransactionListWidgetState extends State<TransactionListWidget> {
  final List<TransactionModel> _transactions = [];
  bool  _loading  = true;
  bool  _hasMore  = true;
  int   _page     = 1;
  bool  _fetching = false;

  static const String _url = 'https://glopa.org/glo/get_user_transactions.php';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch({bool refresh = false}) async {
    if (_fetching) return;
    if (refresh) {
      setState(() { _transactions.clear(); _page = 1; _hasMore = true; });
    }
    setState(() { _fetching = true; _loading = refresh || _transactions.isEmpty; });

    final user = context.read<UserProvider>().user;
    if (user == null) { setState(() { _loading = false; _fetching = false; }); return; }

    try {
      final res = await http.get(
        Uri.parse('$_url?user_id=${user.userId}&page=$_page&limit=20'),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);
      if (data['status'] == 'success' && mounted) {
        final list = (data['transactions'] as List)
            .map((t) => TransactionModel.fromJson(t))
            .toList();
        setState(() {
          _transactions.addAll(list);
          _hasMore = data['has_more'] as bool? ?? false;
          _page++;
        });
      }
    } catch (_) {}

    if (mounted) setState(() { _loading = false; _fetching = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color:        widget.cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Transactions',
                      style: TextStyle(
                          color:      widget.textColor,
                          fontWeight: FontWeight.w700,
                          fontSize:   16)),
                  GestureDetector(
                    onTap: () => _fetch(refresh: true),
                    child: Icon(IconsaxPlusLinear.refresh,
                        color: widget.hintColor, size: 20),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 0.5),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.deepOrange),
                ),
              )
            else if (_transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(IconsaxPlusLinear.empty_wallet,
                        size: 48, color: widget.hintColor),
                    const SizedBox(height: 12),
                    Text('No transactions yet',
                        style: TextStyle(color: widget.hintColor)),
                  ],
                ),
              )
            else
              Column(
                children: [
                  ..._transactions.take(5).map((t) => _buildRow(t)),
                  if (_hasMore)
                    TextButton(
                      onPressed: _fetching ? null : _fetch,
                      child: _fetching
                          ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.deepOrange))
                          : const Text('See more',
                          style: TextStyle(color: Colors.deepOrange)),
                    )
                  else
                    const SizedBox(height: 8),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(TransactionModel t) {
    final isCredit  = t.isCredit;
    final isSuccess = t.isSuccessful;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(
            transaction: t,
            isDark:      widget.isDark,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: Row(
          children: [
            // Icon
            Container(
              height: 50, width: 50,
              decoration: BoxDecoration(
                color: isCredit
                    ? Colors.green.withOpacity(0.12)
                    : Colors.red.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCredit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: isCredit ? Colors.green : Colors.red,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Title + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize:   15,
                          fontWeight: FontWeight.w500,
                          color:      widget.textColor)),
                  const SizedBox(height: 3),
                  Text(t.formattedDate,
                      style: TextStyle(
                          fontSize: 12, color: widget.hintColor)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSuccess
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isSuccess ? 'Successful' : 'Failed',
                      style: TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.w600,
                          color: isSuccess ? Colors.green : Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),

            // Amount
            Text(
              '${isCredit ? '+' : '-'}₦${t.amount}',
              style: TextStyle(
                  fontSize:   16,
                  fontWeight: FontWeight.w700,
                  color: isCredit ? Colors.green : Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Transaction Detail Screen
// ─────────────────────────────────────────────────────────────

class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;
  final bool isDark;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final t         = transaction;
    final bgColor   = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white54 : Colors.grey.shade500;
    final isCredit  = t.isCredit;
    final isSuccess = t.isSuccessful;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor:      bgColor,
        elevation:            0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(IconsaxPlusLinear.arrow_left_2, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Transaction Details',
            style: TextStyle(
                color:      textColor,
                fontWeight: FontWeight.bold,
                fontSize:   17)),
        actions: [
          IconButton(
            icon: Icon(IconsaxPlusLinear.share, color: textColor),
            onPressed: () => _share(context, t),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // ── Amount hero ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color:        cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCredit
                          ? Colors.green.withOpacity(0.12)
                          : Colors.red.withOpacity(0.12),
                    ),
                    child: Icon(
                      isCredit
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: isCredit ? Colors.green : Colors.red,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${isCredit ? '+' : '-'}₦${t.amount}',
                    style: TextStyle(
                        fontSize:   34,
                        fontWeight: FontWeight.w900,
                        color: isCredit ? Colors.green : Colors.red,
                        letterSpacing: -1),
                  ),
                  const SizedBox(height: 6),
                  Text(t.displayTitle,
                      style: TextStyle(
                          color: hintColor, fontSize: 14)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSuccess
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isSuccess ? '✓ Successful' : '✕ Failed',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize:   13,
                          color: isSuccess ? Colors.green : Colors.red),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Detail rows ──────────────────────────────
            Container(
              decoration: BoxDecoration(
                color:        cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _row('Date & Time',    t.formattedDate,   textColor, hintColor),
                  _divider(),
                  _row('Service',        t.serviceType.isNotEmpty
                      ? _cap(t.serviceType.replaceAll('_', ' '))
                      : '—',             textColor, hintColor),
                  _divider(),
                  _row('Payment Method', t.paymentMethod.isNotEmpty
                      ? _cap(t.paymentMethod)
                      : '—',             textColor, hintColor),
                  _divider(),
                  _row('Payment Type',   t.paymentType.isNotEmpty
                      ? _cap(t.paymentType)
                      : '—',             textColor, hintColor),
                  _divider(),
                  _row('Status',         t.paymentStatus.isNotEmpty
                      ? _cap(t.paymentStatus)
                      : '—',             textColor, hintColor),

                  if (t.referenceCode.isNotEmpty) ...[
                    _divider(),
                    _copyRow('Reference Code', t.referenceCode,
                        textColor, hintColor, context),
                  ],
                  if (t.referenceId.isNotEmpty) ...[
                    _divider(),
                    _copyRow('Reference ID',   t.referenceId,
                        textColor, hintColor, context),
                  ],
                  if (t.transactionId.isNotEmpty) ...[
                    _divider(),
                    _copyRow('Transaction ID', t.transactionId,
                        textColor, hintColor, context),
                  ],
                  if (t.serviceRefId.isNotEmpty) ...[
                    _divider(),
                    _copyRow('Service Ref',    t.serviceRefId,
                        textColor, hintColor, context),
                  ],
                ],
              ),
            ),

            // ── Metadata (extra info from JSON) ──────────
            if (t.metadata != null && t.metadata!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color:        cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Text('Additional Info',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:      textColor,
                              fontSize:   14)),
                    ),
                    const Divider(height: 1, thickness: 0.4),
                    ...t.metadata!.entries.map((e) {
                      final key = _cap(e.key.replaceAll('_', ' '));
                      final val = e.value?.toString() ?? '—';
                      return Column(
                        children: [
                          _row(key, val, textColor, hintColor),
                          if (e.key != t.metadata!.keys.last)
                            _divider(),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            // ── Share receipt button ─────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _share(context, t),
                icon:  const Icon(IconsaxPlusLinear.share,
                    color: Colors.deepOrange),
                label: const Text('Share Receipt',
                    style: TextStyle(
                        color:      Colors.deepOrange,
                        fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.deepOrange),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  Widget _divider() =>
      const Divider(height: 1, thickness: 0.4, indent: 16, endIndent: 16);

  Widget _row(
      String label, String value, Color text, Color hint) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: hint, fontSize: 13)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      color:      text,
                      fontSize:   13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _copyRow(String label, String value, Color text, Color hint,
      BuildContext context) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: hint, fontSize: 13)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      color:      text,
                      fontSize:   13,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('$label copied'),
                  duration:  const Duration(seconds: 1),
                  behavior:  SnackBarBehavior.floating,
                  backgroundColor: Colors.green.shade600,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
              },
              child: Icon(IconsaxPlusLinear.copy, size: 16, color: hint),
            ),
          ],
        ),
      );

  void _share(BuildContext context, TransactionModel t) {
    final text = '''
GlobalPay Transaction Receipt
──────────────────────
${t.displayTitle}
Amount:   ${t.isCredit ? '+' : '-'}₦${t.amount}
Status:   ${t.paymentStatus}
Date:     ${t.formattedDate}
Ref Code: ${t.referenceCode.isNotEmpty ? t.referenceCode : 'N/A'}
Tx ID:    ${t.transactionId}
──────────────────────
Powered by Glonest
''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Receipt copied to clipboard'),
      behavior: SnackBarBehavior.floating,
    ));
  }
}