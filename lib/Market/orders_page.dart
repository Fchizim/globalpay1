import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;
  late TabController _tabController;

  final List<String> _tabs = ['All', 'Ongoing', 'Delivered', 'Cancelled'];

  double s(double v) {
    final sw = MediaQuery.of(context).size.width;
    return (sw / 375 * v).clamp(v * 0.85, v * 1.25);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredOrders {
    final tab = _tabs[_tabController.index];
    if (tab == 'All') return _orders;
    if (tab == 'Ongoing') {
      return _orders.where((o) {
        final s = (o['order_status'] ?? '').toLowerCase();
        return s != 'delivered' && s != 'cancelled';
      }).toList();
    }
    if (tab == 'Delivered') {
      return _orders
          .where((o) =>
      (o['order_status'] ?? '').toLowerCase() == 'delivered')
          .toList();
    }
    if (tab == 'Cancelled') {
      return _orders
          .where((o) =>
      (o['order_status'] ?? '').toLowerCase() == 'cancelled')
          .toList();
    }
    return _orders;
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final user = context.read<UserProvider>().user;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final res = await http.post(
        Uri.parse('https://glopa.org/glo/get_orders.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': user.userId}),
      );
      final data = jsonDecode(res.body);
      if (!mounted) return;
      if (data['status'] == 'success') {
        setState(() {
          _orders =
          List<Map<String, dynamic>>.from(data['orders']);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load orders';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Network error';
          _loading = false;
        });
      }
    }
  }

  Future<void> _markReceived(String orderId) async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Receipt'),
        content: const Text(
            'Are you sure you have received this order? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Received',
                  style: TextStyle(color: Colors.green))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final res = await http.post(
        Uri.parse('https://glopa.org/glo/get_orders.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'mark_received',
          'user_id': user.userId,
          'order_id': orderId,
        }),
      );
      final data = jsonDecode(res.body);
      if (!mounted) return;
      if (data['status'] == 'success') {
        setState(() {
          final index =
          _orders.indexWhere((o) => o['order_id'] == orderId);
          if (index != -1) {
            _orders[index]['order_status'] = 'delivered';
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Order marked as received!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['message'] ?? 'Failed to update order'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Network error. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':  return Colors.green;
      case 'cancelled':  return Colors.red;
      case 'processing': return Colors.blue;
      case 'shipped':    return Colors.orange;
      default:           return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':  return Icons.check_circle_rounded;
      case 'cancelled':  return Icons.cancel_rounded;
      case 'processing': return Icons.sync_rounded;
      case 'shipped':    return Icons.local_shipping_rounded;
      default:           return Icons.schedule_rounded;
    }
  }

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
        title: Text('My Orders',
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: s(18))),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: EdgeInsets.symmetric(
                horizontal: s(16), vertical: s(6)),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white10
                  : Colors.deepOrange.shade50.withOpacity(0.6),
              borderRadius: BorderRadius.circular(s(30)),
            ),
            child: TabBar(
              controller: _tabController,
              onTap: (_) => setState(() {}),
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: BorderRadius.circular(s(25)),
              ),
              labelColor: Colors.white,
              unselectedLabelColor:
              isDark ? Colors.white70 : Colors.black54,
              labelStyle: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: s(13)),
              tabAlignment: TabAlignment.start,
              tabs: _tabs.map((t) {
                // Count badge for each tab
                int count = 0;
                if (t == 'All') {
                  count = _orders.length;
                } else if (t == 'Ongoing') {
                  count = _orders.where((o) {
                    final st = (o['order_status'] ?? '').toLowerCase();
                    return st != 'delivered' && st != 'cancelled';
                  }).length;
                } else if (t == 'Delivered') {
                  count = _orders
                      .where((o) =>
                  (o['order_status'] ?? '').toLowerCase() ==
                      'delivered')
                      .length;
                } else if (t == 'Cancelled') {
                  count = _orders
                      .where((o) =>
                  (o['order_status'] ?? '').toLowerCase() ==
                      'cancelled')
                      .length;
                }
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t),
                      if (count > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('$count',
                              style: const TextStyle(fontSize: 10)),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(
          child: CircularProgressIndicator(color: Colors.deepOrange))
          : _error != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrders,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white),
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        color: Colors.deepOrange,
        onRefresh: _loadOrders,
        child: _filteredOrders.isEmpty
            ? ListView(
          children: [
            SizedBox(height: s(80)),
            _buildEmpty(textColor),
          ],
        )
            : ListView.builder(
          padding: EdgeInsets.all(s(16)),
          itemCount: _filteredOrders.length,
          itemBuilder: (_, i) => _buildOrderCard(
              _filteredOrders[i], cardColor, textColor, isDark),
        ),
      ),
    );
  }

  Widget _buildEmpty(Color textColor) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(IconsaxPlusLinear.bag_2,
            size: 72, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('No orders here',
            style: TextStyle(
                fontSize: s(18),
                fontWeight: FontWeight.bold,
                color: textColor)),
        const SizedBox(height: 8),
        Text('Your orders will appear here',
            style: TextStyle(color: Colors.grey.shade500)),
      ],
    ),
  );

  Widget _buildOrderCard(
      Map<String, dynamic> order, Color card, Color text, bool isDark) {
    final status      = order['order_status'] ?? 'pending';
    final items       = List<Map<String, dynamic>>.from(order['items'] ?? []);
    final total       = double.tryParse(order['total_amount'].toString()) ?? 0;
    final deliveryFee = double.tryParse(order['delivery_fee'].toString()) ?? 0;
    final date        = order['created_at'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: s(14)),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(s(16)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Order header ──
          Padding(
            padding: EdgeInsets.all(s(14)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order['order_id'] ?? '',
                          style: TextStyle(
                              fontSize: s(12),
                              color: Colors.grey.shade500,
                              fontFamily: 'monospace')),
                      const SizedBox(height: 2),
                      Text(
                          date.toString().substring(
                              0,
                              date.length > 16
                                  ? 16
                                  : date.length),
                          style: TextStyle(
                              fontSize: s(11),
                              color: Colors.grey.shade400)),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: s(10), vertical: s(5)),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(s(20)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(status),
                          size: s(13), color: _statusColor(status)),
                      SizedBox(width: s(4)),
                      Text(
                        status[0].toUpperCase() + status.substring(1),
                        style: TextStyle(
                            fontSize: s(11),
                            fontWeight: FontWeight.w700,
                            color: _statusColor(status)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.withOpacity(0.1)),

          // ── Order items ──
          ...items.map((item) {
            final qty      = item['quantity'] ?? 1;
            final subtotal =
                double.tryParse(item['subtotal'].toString()) ?? 0;
            return Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: s(14), vertical: s(10)),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(s(8)),
                    child: Image.network(
                      item['product_image'] ?? '',
                      width: s(50),
                      height: s(50),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: s(50),
                        height: s(50),
                        color: Colors.grey.shade200,
                        child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey,
                            size: 20),
                      ),
                    ),
                  ),
                  SizedBox(width: s(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['product_name'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: s(13),
                                fontWeight: FontWeight.w600,
                                color: text)),
                        SizedBox(height: s(3)),
                        Text('Qty: $qty',
                            style: TextStyle(
                                fontSize: s(11),
                                color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Text('₦${subtotal.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: s(13),
                          fontWeight: FontWeight.w700,
                          color: Colors.deepOrange)),
                ],
              ),
            );
          }),

          Divider(height: 1, color: Colors.grey.withOpacity(0.1)),

          // ── Order footer ──
          Padding(
            padding: EdgeInsets.all(s(14)),
            child: Column(
              children: [
                if (deliveryFee > 0)
                  Padding(
                    padding: EdgeInsets.only(bottom: s(6)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Delivery Fee',
                            style: TextStyle(
                                fontSize: s(12),
                                color: Colors.grey.shade500)),
                        Text('₦${deliveryFee.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: s(12),
                                color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total',
                        style: TextStyle(
                            fontSize: s(14),
                            fontWeight: FontWeight.bold,
                            color: text)),
                    Text('₦${total.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: s(15),
                            fontWeight: FontWeight.w900,
                            color: Colors.deepOrange)),
                  ],
                ),
                if ((order['delivery_address'] ?? '').isNotEmpty) ...[
                  SizedBox(height: s(8)),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: s(13), color: Colors.grey.shade400),
                      SizedBox(width: s(4)),
                      Expanded(
                        child: Text(order['delivery_address'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: s(11),
                                color: Colors.grey.shade400)),
                      ),
                    ],
                  ),
                ],

                // ── Mark received button ──
                if (status != 'delivered' && status != 'cancelled') ...[
                  SizedBox(height: s(12)),
                  SizedBox(
                    width: double.infinity,
                    height: s(44),
                    child: ElevatedButton.icon(
                      onPressed: () => _markReceived(order['order_id']),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Mark as Received',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(s(12))),
                      ),
                    ),
                  ),
                ],

                // ── Already delivered label ──
                if (status == 'delivered') ...[
                  SizedBox(height: s(12)),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: s(10)),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(s(12)),
                      border: Border.all(
                          color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.green, size: 16),
                        SizedBox(width: s(6)),
                        const Text('Order Received',
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}