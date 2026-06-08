import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:globalpay/home/transaction_detail_page.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';

class AirtimeHistoryScreen extends StatefulWidget {
  const AirtimeHistoryScreen({super.key});

  @override
  State<AirtimeHistoryScreen> createState() => _AirtimeHistoryScreenState();
}

class _AirtimeHistoryScreenState extends State<AirtimeHistoryScreen> {
  final NumberFormat _numFormat = NumberFormat.decimalPattern('en_US');

  List<Map<String, dynamic>> _transactions = [];
  bool    _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() { _isLoading = true; _error = null; });

    final userId = context.read<UserProvider>().user?.userId ?? '';
    if (userId.isEmpty) {
      setState(() { _error = 'Session expired.'; _isLoading = false; });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://glopa.org/glo/get_bill_history.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'action':  'AIRTIME',
        }),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      final decoded = jsonDecode(response.body);
      final status  = (decoded['status'] ?? '').toString();

      if (status == 'success') {
        final List data = decoded['data'] ?? [];
        setState(() {
          _transactions = data.cast<Map<String, dynamic>>();
          _isLoading    = false;
        });
      } else {
        setState(() {
          _error     = decoded['message'] ?? 'Could not load history.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _error     = 'Network error. Please try again.';
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':  return const Color(0xFF22C55E);
      case 'pending':  return Colors.orange;
      case 'failed':   return Colors.red;
      default:         return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'success':  return Icons.check_circle_rounded;
      case 'pending':  return Icons.hourglass_bottom_rounded;
      case 'failed':   return Icons.cancel_rounded;
      default:         return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bgColor  = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF9FAFB);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor  = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text('Airtime History',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            onPressed: _fetchHistory,
            icon: Icon(Icons.refresh_rounded, color: Colors.deepOrange),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off_rounded,
              size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(_error!,
              style: TextStyle(color: subColor),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchHistory,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
      )
          : _transactions.isEmpty
          ? Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.history_rounded,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No airtime transactions yet',
              style: TextStyle(color: subColor, fontSize: 15)),
        ]),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final trx     = _transactions[i];
          final status  = (trx['payment_status'] ?? '').toString();
          final amount  = double.tryParse(trx['amount']?.toString() ?? '0') ?? 0;
          final network = trx['network']?.toString() ?? '';
          final number  = trx['number']?.toString() ?? '';
          final ref     = trx['ref']?.toString() ?? '';
          final date    = trx['created_at']?.toString() ?? '';
          final action    = trx['action']?.toString() ?? '';
          final transactionId = trx['transaction_id']?.toString() ?? ref; // 👈 use ref as fallback

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
                    newBalance: double.tryParse(
                        trx['new_balance']?.toString() ?? '0') ?? 0.0,
                    action: action,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2)),
                ],
              ),
              child: Row(children: [

                // ── Status icon ──────────────────────────────
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_statusIcon(status),
                      color: _statusColor(status), size: 22),
                ),
                const SizedBox(width: 12),

                // ── Details ──────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(network.isNotEmpty ? network : 'Airtime',
                          style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(number,
                          style: TextStyle(
                              color: subColor, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(ref,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: subColor, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(date,
                          style: TextStyle(
                              color: subColor, fontSize: 11)),
                    ],
                  ),
                ),

                // ── Amount & status ──────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₦${_numFormat.format(amount)}',
                        style: TextStyle(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(status.toUpperCase(),
                          style: TextStyle(
                              color: _statusColor(status),
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}