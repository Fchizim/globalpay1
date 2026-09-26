import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:globalpay/home/transaction_detail_page.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../provider/user_provider.dart';
import 'package:provider/provider.dart';

class BetHistoryScreen extends StatefulWidget {
  const BetHistoryScreen({super.key});

  @override
  State<BetHistoryScreen> createState() => _BetHistoryScreenState();
}

class _BetHistoryScreenState extends State<BetHistoryScreen> {
  final NumberFormat _numFormat = NumberFormat.decimalPattern('en_US');

  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final userId = context.read<UserProvider>().user?.userId ?? '';
    if (userId.isEmpty) {
      setState(() {
        _error = 'Session expired.';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse('https://glopa.org/glo/get_bill_history.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': userId, 'action': 'BETTING'}),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      final decoded = jsonDecode(response.body);
      final status = (decoded['status'] ?? '').toString();

      if (status == 'success') {
        final List data = decoded['data'] ?? [];
        setState(() {
          _transactions = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = decoded['message'] ?? 'Could not load history.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = 'Network error. Please try again.';
          _isLoading = false;
        });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return const Color(0xFF22C55E);
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.hourglass_bottom_rounded;
      case 'failed':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF9FAFB);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    // Screen-size aware scaling so rows look right on small and large
    // phones/tablets instead of using fixed pixel values everywhere.
    final double screenWidth = MediaQuery.of(context).size.width;
    final double scale = (screenWidth / 390.0).clamp(0.85, 1.15);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          'Bet History',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            onPressed: _fetchHistory,
            icon: const Icon(Icons.refresh_rounded, color: Colors.deepOrange),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _error!,
                      style: TextStyle(color: subColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _fetchHistory,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : _transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 56,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No bet transactions yet',
                    style: TextStyle(color: subColor, fontSize: 15),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.all(16 * scale),
              itemCount: _transactions.length,
              separatorBuilder: (_, __) => SizedBox(height: 10 * scale),
              itemBuilder: (_, i) {
                final trx = _transactions[i];
                final status = (trx['payment_status'] ?? '').toString();
                final amount =
                    double.tryParse(trx['amount']?.toString() ?? '0') ?? 0;
                final network = trx['network']?.toString() ?? '';
                final number = trx['number']?.toString() ?? '';
                final ref = trx['ref']?.toString() ?? '';
                final date = trx['created_at']?.toString() ?? '';
                final action = trx['action']?.toString() ?? '';
                final transactionId = trx['transaction_id']?.toString() ?? ref;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TransactionDetailScreen(
                          amount: amount.toInt(),
                          network: network,
                          phone: number,
                          transactionId: transactionId,
                          ref: ref,
                          newBalance:
                              double.tryParse(
                                trx['new_balance']?.toString() ?? '0',
                              ) ??
                              0.0,
                          action: action,
                          paymentStatus: status,
                          responseMessage: trx['response_message']?.toString(),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(14 * scale),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Status icon ──────────────────────────────
                        Container(
                          width: 44 * scale,
                          height: 44 * scale,
                          decoration: BoxDecoration(
                            color: _statusColor(status).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _statusIcon(status),
                            color: _statusColor(status),
                            size: 22 * scale,
                          ),
                        ),
                        SizedBox(width: 12 * scale),

                        // ── Details ──────────────────────────────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                network.isNotEmpty ? network : 'Bet',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14 * scale,
                                ),
                              ),
                              SizedBox(height: 2 * scale),
                              Text(
                                number,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: subColor,
                                  fontSize: 12 * scale,
                                ),
                              ),
                              SizedBox(height: 2 * scale),
                              Text(
                                ref,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: subColor,
                                  fontSize: 11 * scale,
                                ),
                              ),
                              SizedBox(height: 2 * scale),
                              Text(
                                date,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: subColor,
                                  fontSize: 11 * scale,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8 * scale),

                        // ── Amount & status ──────────────────────────
                        // FIX: this trailing Column had no width constraint. In a
                        // Row, a non-flex child gets an unbounded width to lay
                        // itself out at its intrinsic size — so a large amount
                        // (e.g. "₦1,000,000.00") or a long status string (e.g.
                        // "PARTIALLY_SUCCESSFUL") could push the row's total
                        // width past the screen and throw a real overflow error.
                        // Constrained to a max width + ellipsis so it shrinks
                        // instead.
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 120 * scale),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₦${_numFormat.format(amount)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15 * scale,
                                ),
                              ),
                              SizedBox(height: 4 * scale),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8 * scale,
                                  vertical: 3 * scale,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontSize: 10 * scale,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
