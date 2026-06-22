import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../provider/user_provider.dart';

// ─────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────

class VendorOrderItem {
  final String productId;
  final String productName;
  final String productImage;
  final String unitPrice;
  final int    quantity;
  final String subtotal;

  const VendorOrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory VendorOrderItem.fromJson(Map<String, dynamic> j) => VendorOrderItem(
    productId:    j['product_id'].toString(),
    productName:  j['product_name'].toString(),
    productImage: j['product_image']?.toString() ?? '',
    unitPrice:    j['unit_price'].toString(),
    quantity:     int.tryParse(j['quantity'].toString()) ?? 1,
    subtotal:     j['subtotal'].toString(),
  );
}

class VendorOrder {
  final String orderId;
  String orderStatus;
  final String paymentMethod;
  final String paymentStatus;
  final String deliveryAddress;
  final String note;
  final String vendorSubtotal;
  final String deliveryFee;
  final String createdAt;
  final String buyerName;
  final String buyerPhone;
  final String buyerEmail;
  final List<VendorOrderItem> items;

  VendorOrder({
    required this.orderId,
    required this.orderStatus,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.deliveryAddress,
    required this.note,
    required this.vendorSubtotal,
    required this.deliveryFee,
    required this.createdAt,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerEmail,
    required this.items,
  });

  factory VendorOrder.fromJson(Map<String, dynamic> j) => VendorOrder(
    orderId:         j['order_id'].toString(),
    orderStatus:     j['order_status'].toString(),
    paymentMethod:   j['payment_method'].toString(),
    paymentStatus:   j['payment_status'].toString(),
    deliveryAddress: j['delivery_address']?.toString() ?? '',
    note:            j['note']?.toString()             ?? '',
    vendorSubtotal:  j['vendor_subtotal'].toString(),
    deliveryFee:     j['delivery_fee'].toString(),
    createdAt:       j['created_at'].toString(),
    buyerName:       j['buyer_name']?.toString()  ?? 'Customer',
    buyerPhone:      j['buyer_phone']?.toString() ?? '',
    buyerEmail:      j['buyer_email']?.toString() ?? '',
    items: (j['items'] as List? ?? [])
        .map((i) => VendorOrderItem.fromJson(i))
        .toList(),
  );

  String get formattedDate {
    try {
      return DateFormat('dd MMM yyyy • hh:mm a').format(DateTime.parse(createdAt));
    } catch (_) { return createdAt; }
  }
}

// ─────────────────────────────────────────────────────────────
// Vendor Orders Screen
// ─────────────────────────────────────────────────────────────

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _filters = ['all', 'pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'];
  static const _labels  = ['All',  'Pending',  'Confirmed',  'Processing',  'Shipped',  'Delivered',  'Cancelled'];

  final List<List<VendorOrder>> _tabOrders   = List.generate(_filters.length, (_) => []);
  final List<int>  _pages     = List.generate(_filters.length, (_) => 1);
  final List<bool> _loading   = List.generate(_filters.length, (_) => false);
  final List<bool> _hasMore   = List.generate(_filters.length, (_) => true);
  final List<bool> _loaded    = List.generate(_filters.length, (_) => false);

  static const String _base = 'https://glopa.org/glo/get_vendor_orders.php';

  double s(double v) {
    final sw = MediaQuery.of(context).size.width;
    return (sw / 375 * v).clamp(v * 0.85, v * 1.25);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) return;
        final i = _tabController.index;
        if (!_loaded[i]) _fetch(i);
      });
    _fetch(0); // load "All" on start
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetch(int tabIndex, {bool refresh = false}) async {
    if (_loading[tabIndex]) return;
    if (refresh) {
      setState(() {
        _tabOrders[tabIndex].clear();
        _pages[tabIndex]  = 1;
        _hasMore[tabIndex] = true;
        _loaded[tabIndex]  = false;
      });
    }

    setState(() => _loading[tabIndex] = true);

    final user   = context.read<UserProvider>().user;
    if (user == null) { setState(() => _loading[tabIndex] = false); return; }

    final filter = _filters[tabIndex] == 'all' ? '' : _filters[tabIndex];

    try {
      final res = await http.post(
        Uri.parse(_base),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user.userId,
          'action':  'get',
          'page':    _pages[tabIndex],
          'limit':   20,
          if (filter.isNotEmpty) 'filter': filter,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);
      if (data['status'] == 'success' && mounted) {
        final list = (data['orders'] as List)
            .map((o) => VendorOrder.fromJson(o))
            .toList();
        setState(() {
          _tabOrders[tabIndex].addAll(list);
          _hasMore[tabIndex] = data['has_more'] as bool? ?? false;
          _pages[tabIndex]++;
          _loaded[tabIndex] = true;
        });
      }
    } catch (_) {}

    if (mounted) setState(() => _loading[tabIndex] = false);
  }

  Future<void> _updateStatus(VendorOrder order, String newStatus) async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    try {
      final res = await http.post(
        Uri.parse(_base),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id':  user.userId,
          'action':   'update_status',
          'order_id': order.orderId,
          'status':   newStatus,
        }),
      );
      final data = jsonDecode(res.body);
      if (data['status'] == 'success' && mounted) {
        setState(() => order.orderStatus = newStatus);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Order marked as ${_cap(newStatus)}'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (_) {}
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final textColor = isDark ? Colors.white : Colors.black;

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
        title: Text('My Orders',
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: TabBar(
            controller:   _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color:        Colors.deepOrange,
              borderRadius: BorderRadius.circular(20),
            ),
            indicatorSize:        TabBarIndicatorSize.tab,
            labelColor:           Colors.white,
            unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 12),
            tabs: _labels.map((l) => Tab(text: l)).toList(),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_filters.length,
                (i) => _buildTab(i, isDark)),
      ),
    );
  }

  Widget _buildTab(int i, bool isDark) {
    final orders  = _tabOrders[i];
    final loading = _loading[i];
    final more    = _hasMore[i];
    final loaded  = _loaded[i];

    if (!loaded && loading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.deepOrange));
    }

    if (loaded && orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(IconsaxPlusLinear.box, size: 64,
                color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No orders here',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.deepOrange,
      onRefresh: () => _fetch(i, refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: orders.length + (more ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          if (index >= orders.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: TextButton(
                  onPressed: loading ? null : () => _fetch(i),
                  child: loading
                      ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.deepOrange))
                      : const Text('Load more',
                      style: TextStyle(color: Colors.deepOrange)),
                ),
              ),
            );
          }
          return _buildOrderCard(orders[index], isDark);
        },
      ),
    );
  }

  Widget _buildOrderCard(VendorOrder order, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final status    = order.orderStatus.toLowerCase();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VendorOrderDetailScreen(
            order:  order,
            isDark: isDark,
            onStatusChanged: (s) => _updateStatus(order, s),
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color:        cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            // ── Header ────────────────────────────────────
            Padding(
              padding: EdgeInsets.all(s(14)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.orderId,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:      textColor,
                                fontSize:   s(13))),
                        const SizedBox(height: 3),
                        Text(order.formattedDate,
                            style: TextStyle(
                                color:    Colors.grey.shade500,
                                fontSize: s(11))),
                      ],
                    ),
                  ),
                  _statusChip(status),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 0.4),

            // ── Items preview ─────────────────────────────
            Padding(
              padding: EdgeInsets.all(s(12)),
              child: Column(
                children: order.items.take(2).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(s(8)),
                        child: Image.network(
                          item.productImage,
                          width: s(44), height: s(44),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: s(44), height: s(44),
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported_outlined,
                                color: Colors.grey, size: 20),
                          ),
                        ),
                      ),
                      SizedBox(width: s(10)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: textColor, fontSize: s(13),
                                    fontWeight: FontWeight.w500)),
                            Text('×${item.quantity}  •  ₦${item.subtotal}',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: s(11))),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),

            if (order.items.length > 2)
              Padding(
                padding: EdgeInsets.only(bottom: s(8)),
                child: Text('+${order.items.length - 2} more item(s)',
                    style: TextStyle(
                        color: Colors.deepOrange, fontSize: s(12))),
              ),

            const Divider(height: 1, thickness: 0.4),

            // ── Footer ────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: s(14), vertical: s(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(IconsaxPlusLinear.user, size: s(14),
                          color: Colors.grey.shade500),
                      SizedBox(width: s(4)),
                      Text(order.buyerName,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: s(12))),
                    ],
                  ),
                  Text('₦${order.vendorSubtotal}',
                      style: TextStyle(
                          color:      Colors.deepOrange,
                          fontWeight: FontWeight.w800,
                          fontSize:   s(15))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'delivered':  color = Colors.green;        break;
      case 'shipped':    color = Colors.blue;         break;
      case 'processing': color = Colors.purple;       break;
      case 'confirmed':  color = Colors.teal;         break;
      case 'cancelled':  color = Colors.red;          break;
      default:           color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(_cap(status),
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Vendor Order Detail Screen
// ─────────────────────────────────────────────────────────────

class VendorOrderDetailScreen extends StatefulWidget {
  final VendorOrder order;
  final bool isDark;
  final Future<void> Function(String status) onStatusChanged;

  const VendorOrderDetailScreen({
    super.key,
    required this.order,
    required this.onStatusChanged,
    this.isDark = false,
  });

  @override
  State<VendorOrderDetailScreen> createState() =>
      _VendorOrderDetailScreenState();
}

class _VendorOrderDetailScreenState extends State<VendorOrderDetailScreen> {
  bool _updating = false;

  static const _statusFlow = [
    'pending', 'confirmed', 'processing', 'shipped', 'delivered'
  ];

  String get _nextStatus {
    final idx = _statusFlow.indexOf(widget.order.orderStatus.toLowerCase());
    if (idx == -1 || idx >= _statusFlow.length - 1) return '';
    return _statusFlow[idx + 1];
  }

  String _nextLabel() {
    switch (_nextStatus) {
      case 'confirmed':  return 'Confirm Order';
      case 'processing': return 'Mark Processing';
      case 'shipped':    return 'Mark as Shipped';
      case 'delivered':  return 'Mark as Delivered';
      default:           return '';
    }
  }

  Future<void> _advance() async {
    if (_nextStatus.isEmpty || _updating) return;
    setState(() => _updating = true);
    await widget.onStatusChanged(_nextStatus);
    if (mounted) setState(() { _updating = false; });
  }

  double s(double v) {
    final sw = MediaQuery.of(context).size.width;
    return (sw / 375 * v).clamp(v * 0.85, v * 1.25);
  }

  @override
  Widget build(BuildContext context) {
    final o         = widget.order;
    final isDark    = widget.isDark;
    final bgColor   = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white54 : Colors.grey.shade500;
    final status    = o.orderStatus.toLowerCase();

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
        title: Text('Order Details',
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          IconButton(
            icon: Icon(IconsaxPlusLinear.copy, color: textColor, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: o.orderId));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Order ID copied'),
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                s(16), s(12), s(16),
                _nextStatus.isNotEmpty ? s(90) : s(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Status tracker ───────────────────────
                _buildStatusTracker(status, cardColor, textColor),

                SizedBox(height: s(16)),

                // ── Order info card ──────────────────────
                _section(cardColor, [
                  _row('Order ID',      o.orderId,        textColor, hintColor, copyable: true, context: context),
                  _divider(),
                  _row('Date',          o.formattedDate,  textColor, hintColor),
                  _divider(),
                  _row('Payment',       '${_cap(o.paymentMethod)} • ${_cap(o.paymentStatus)}',
                      textColor, hintColor),
                  _divider(),
                  _row('Your Earnings', '₦${o.vendorSubtotal}',
                      textColor, hintColor,
                      valueColor: Colors.deepOrange),
                  if (o.deliveryFee != '0.00') ...[
                    _divider(),
                    _row('Delivery Fee', '₦${o.deliveryFee}', textColor, hintColor),
                  ],
                ]),

                SizedBox(height: s(14)),

                // ── Buyer info ───────────────────────────
                _sectionTitle('Buyer', textColor),
                SizedBox(height: s(8)),
                _section(cardColor, [
                  _row('Name',  o.buyerName,  textColor, hintColor),
                  if (o.buyerPhone.isNotEmpty) ...[
                    _divider(),
                    _row('Phone', o.buyerPhone, textColor, hintColor,
                        copyable: true, context: context),
                  ],
                  if (o.deliveryAddress.isNotEmpty) ...[
                    _divider(),
                    _row('Address', o.deliveryAddress, textColor, hintColor),
                  ],
                  if (o.note.isNotEmpty) ...[
                    _divider(),
                    _row('Note', o.note, textColor, hintColor),
                  ],
                ]),

                SizedBox(height: s(14)),

                // ── Items ────────────────────────────────
                _sectionTitle('Items (${o.items.length})', textColor),
                SizedBox(height: s(8)),
                Container(
                  decoration: BoxDecoration(
                    color:        cardColor,
                    borderRadius: BorderRadius.circular(s(14)),
                  ),
                  child: Column(
                    children: o.items.asMap().entries.map((e) {
                      final item = e.value;
                      final last = e.key == o.items.length - 1;
                      return Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(s(12)),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(s(10)),
                                  child: Image.network(
                                    item.productImage,
                                    width: s(60), height: s(60),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: s(60), height: s(60),
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                          Icons.image_not_supported_outlined,
                                          color: Colors.grey),
                                    ),
                                  ),
                                ),
                                SizedBox(width: s(12)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(item.productName,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color:      textColor,
                                              fontSize:   s(14))),
                                      SizedBox(height: s(4)),
                                      Text(
                                        '₦${item.unitPrice}  ×  ${item.quantity}',
                                        style: TextStyle(
                                            color:    hintColor,
                                            fontSize: s(12)),
                                      ),
                                    ],
                                  ),
                                ),
                                Text('₦${item.subtotal}',
                                    style: TextStyle(
                                        color:      Colors.deepOrange,
                                        fontWeight: FontWeight.w700,
                                        fontSize:   s(14))),
                              ],
                            ),
                          ),
                          if (!last)
                            const Divider(height: 1, thickness: 0.4,
                                indent: 12, endIndent: 12),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                SizedBox(height: s(16)),
              ],
            ),
          ),

          // ── Advance status button ────────────────────
          if (_nextStatus.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: s(20), vertical: s(14)),
                decoration: BoxDecoration(
                  color: cardColor,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06),
                        blurRadius: 10, offset: const Offset(0, -3)),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: s(50),
                    child: ElevatedButton(
                      onPressed: _updating ? null : _advance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                        Colors.deepOrange.withOpacity(0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(s(14))),
                      ),
                      child: _updating
                          ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                          : Text(_nextLabel(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize:   s(15))),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Status tracker widget ──────────────────────────────────

  Widget _buildStatusTracker(
      String current, Color card, Color text) {
    const steps   = ['pending', 'confirmed', 'processing', 'shipped', 'delivered'];
    const labels  = ['Pending', 'Confirmed', 'Processing', 'Shipped', 'Delivered'];
    final curIdx  = steps.indexOf(current);

    return Container(
      padding: EdgeInsets.all(s(16)),
      decoration: BoxDecoration(
        color:        card,
        borderRadius: BorderRadius.circular(s(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Progress',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: text, fontSize: s(14))),
          SizedBox(height: s(16)),
          Row(
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                // connector line
                final filled = (i ~/ 2) < curIdx;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: filled ? Colors.deepOrange : Colors.grey.shade300,
                  ),
                );
              }
              final stepIdx  = i ~/ 2;
              final done     = stepIdx <= curIdx;
              final active   = stepIdx == curIdx;
              return Column(
                children: [
                  Container(
                    width: s(28), height: s(28),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? Colors.deepOrange
                          : Colors.grey.shade200,
                      border: active
                          ? Border.all(color: Colors.deepOrange, width: 2)
                          : null,
                    ),
                    child: Icon(
                      done ? Icons.check_rounded : Icons.circle,
                      size:  done ? s(16) : s(8),
                      color: done
                          ? Colors.white
                          : Colors.grey.shade400,
                    ),
                  ),
                  SizedBox(height: s(4)),
                  Text(labels[stepIdx],
                      style: TextStyle(
                          fontSize: s(9),
                          fontWeight: active
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: done
                              ? Colors.deepOrange
                              : Colors.grey.shade400)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── UI helpers ─────────────────────────────────────────────

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _sectionTitle(String t, Color c) => Text(t,
      style: TextStyle(
          fontWeight: FontWeight.bold, color: c, fontSize: s(14)));

  Widget _section(Color card, List<Widget> children) => Container(
    decoration: BoxDecoration(
        color: card, borderRadius: BorderRadius.circular(s(14))),
    child: Column(children: children),
  );

  Widget _divider() =>
      const Divider(height: 1, thickness: 0.4, indent: 16, endIndent: 16);

  Widget _row(
      String label,
      String value,
      Color text,
      Color hint, {
        Color? valueColor,
        bool copyable = false,
        BuildContext? context,
      }) =>
      Padding(
        padding: EdgeInsets.symmetric(
            horizontal: s(16), vertical: s(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: hint, fontSize: s(13))),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      color:      valueColor ?? text,
                      fontSize:   s(13),
                      fontWeight: FontWeight.w600)),
            ),
            if (copyable && context != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('$label copied'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ));
                },
                child:
                Icon(IconsaxPlusLinear.copy, size: s(15), color: hint),
              ),
            ],
          ],
        ),
      );
}