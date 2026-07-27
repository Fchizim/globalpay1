import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';

class VendorSalesAnalyticsPage extends StatefulWidget {
  const VendorSalesAnalyticsPage({super.key});

  @override
  State<VendorSalesAnalyticsPage> createState() => _VendorSalesAnalyticsPageState();
}

class _VendorSalesAnalyticsPageState extends State<VendorSalesAnalyticsPage> {
  bool _loading = true;
  String? _error;

  double _pendingPayout = 0;
  Map<String, Map<String, dynamic>> _summary = {};
  List<Map<String, dynamic>> _trend = [];
  List<Map<String, dynamic>> _topProducts = [];

  double s(double v) {
    final sw = MediaQuery.of(context).size.width;
    return (sw / 375 * v).clamp(v * 0.85, v * 1.25);
  }

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    setState(() { _loading = true; _error = null; });

    try {
      final res = await http.post(
        Uri.parse('https://glopa.org/glo/get_vendor_sales_analytics.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': user.userId}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);
      if (data['status'] == 'success' && mounted) {
        setState(() {
          _pendingPayout = double.tryParse(data['pending_payout'].toString()) ?? 0;
          _summary       = Map<String, Map<String, dynamic>>.from(
              (data['summary'] as Map).map((k, v) => MapEntry(k, Map<String, dynamic>.from(v))));
          _trend         = List<Map<String, dynamic>>.from(data['trend'] ?? []);
          _topProducts   = List<Map<String, dynamic>>.from(data['top_products'] ?? []);
          _loading = false;
        });
      } else if (mounted) {
        setState(() { _error = data['message'] ?? 'Failed to load analytics'; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _error = 'Network error. Pull to refresh.'; _loading = false; });
    }
  }

  double _amount(String bucket) => double.tryParse(_summary[bucket]?['amount']?.toString() ?? '') ?? 0;
  int _orders(String bucket) => int.tryParse(_summary[bucket]?['orders']?.toString() ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(IconsaxPlusLinear.arrow_left_2, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Sales Analytics',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
          : _error != null
          ? Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchAnalytics,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ]),
      )
          : RefreshIndicator(
        color: Colors.deepOrange,
        onRefresh: _fetchAnalytics,
        child: ListView(
          padding: EdgeInsets.all(s(16)),
          children: [

            // ── Pending payout banner ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(s(16)),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(s(14)),
                border: Border.all(color: Colors.deepOrange.withOpacity(0.2)),
              ),
              child: Row(children: [
                Container(
                  padding: EdgeInsets.all(s(10)),
                  decoration: const BoxDecoration(color: Colors.deepOrange, shape: BoxShape.circle),
                  child: Icon(IconsaxPlusBold.wallet_2, color: Colors.white, size: s(18)),
                ),
                SizedBox(width: s(12)),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Pending Payout',
                        style: TextStyle(fontSize: s(12), color: isDark ? Colors.white70 : Colors.grey.shade600)),
                    SizedBox(height: s(2)),
                    Text('₦${_pendingPayout.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: s(18), fontWeight: FontWeight.bold, color: textColor)),
                  ]),
                ),
              ]),
            ),

            SizedBox(height: s(16)),

            // ── Delivered / Cancelled / Pending summary cards ──
            Row(children: [
              Expanded(child: _summaryCard('Delivered', _orders('delivered'), _amount('delivered'),
                  Colors.green, Icons.check_circle_rounded, cardColor, textColor, isDark)),
              SizedBox(width: s(10)),
              Expanded(child: _summaryCard('Cancelled', _orders('cancelled'), _amount('cancelled'),
                  Colors.red, Icons.cancel_rounded, cardColor, textColor, isDark)),
            ]),
            SizedBox(height: s(10)),
            _summaryCard('Pending / In Progress', _orders('pending'), _amount('pending'),
                Colors.orange, Icons.schedule_rounded, cardColor, textColor, isDark, fullWidth: true),

            SizedBox(height: s(20)),

            // ── 7-day delivered revenue trend ──
            Text('Last 7 Days (Delivered)',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: s(14))),
            SizedBox(height: s(10)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(s(16)),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(s(14))),
              child: _trend.isEmpty
                  ? Padding(
                padding: EdgeInsets.symmetric(vertical: s(20)),
                child: Center(
                  child: Text('No delivered sales in the last 7 days',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: s(12))),
                ),
              )
                  : _buildTrendChart(isDark),
            ),

            SizedBox(height: s(20)),

            // ── Top products ──
            Text('Top Products (Delivered)',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: s(14))),
            SizedBox(height: s(10)),
            _topProducts.isEmpty
                ? Container(
              width: double.infinity,
              padding: EdgeInsets.all(s(20)),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(s(14))),
              child: Center(
                child: Text('No delivered sales yet',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: s(12))),
              ),
            )
                : Container(
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(s(14))),
              child: Column(
                children: _topProducts.asMap().entries.map((e) {
                  final item = e.value;
                  final last = e.key == _topProducts.length - 1;
                  final amount = double.tryParse(item['amount'].toString()) ?? 0;
                  return Column(children: [
                    Padding(
                      padding: EdgeInsets.all(s(14)),
                      child: Row(children: [
                        Container(
                          width: s(28), height: s(28),
                          decoration: BoxDecoration(
                              color: Colors.deepOrange.withOpacity(0.1), shape: BoxShape.circle),
                          child: Center(
                            child: Text('${e.key + 1}',
                                style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: s(12))),
                          ),
                        ),
                        SizedBox(width: s(12)),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item['product_name'] ?? '',
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: s(13))),
                            Text('${item['quantity']} sold',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: s(11))),
                          ]),
                        ),
                        Text('₦${amount.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: s(13))),
                      ]),
                    ),
                    if (!last) const Divider(height: 1, thickness: 0.4, indent: 14, endIndent: 14),
                  ]);
                }).toList(),
              ),
            ),

            SizedBox(height: s(20)),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, int orders, double amount, Color color, IconData icon,
      Color cardColor, Color textColor, bool isDark, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: EdgeInsets.all(s(14)),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(s(14))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: s(15), color: color),
            SizedBox(width: s(6)),
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: s(11.5))),
          ]),
          SizedBox(height: s(8)),
          Text('₦${amount.toStringAsFixed(2)}',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: s(16))),
          SizedBox(height: s(2)),
          Text('$orders order${orders == 1 ? '' : 's'}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: s(11))),
        ],
      ),
    );
  }

  Widget _buildTrendChart(bool isDark) {
    final maxAmount = _trend.map((t) => (t['amount'] as num).toDouble())
        .fold<double>(0, (a, b) => a > b ? a : b);
    final safeMax = maxAmount == 0 ? 1.0 : maxAmount;

    return SizedBox(
      height: s(140),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _trend.map((t) {
          final amount = (t['amount'] as num).toDouble();
          final barHeight = (amount / safeMax) * s(90);
          final day = DateTime.tryParse(t['day'].toString());
          final label = day != null ? DateFormat('E').format(day) : '';

          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: s(4)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('₦${amount.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: s(9), color: Colors.grey.shade500)),
                  SizedBox(height: s(4)),
                  Container(
                    height: barHeight < 4 ? 4 : barHeight,
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.circular(s(4)),
                    ),
                  ),
                  SizedBox(height: s(6)),
                  Text(label,
                      style: TextStyle(fontSize: s(10), color: isDark ? Colors.white54 : Colors.grey.shade600)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}