import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';

// ─────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────

class CartItem {
  final String cartId;
  final String productId;
  final String productName;
  final String productImage;
  final String vendorName;
  final double unitPrice;
  int quantity;

  CartItem({
    required this.cartId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.vendorName,
    required this.unitPrice,
    required this.quantity,
  });

  double get subtotal => unitPrice * quantity;

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
    cartId:       j['cart_id'].toString(),
    productId:    j['product_id'].toString(),
    productName:  j['product_name'].toString(),
    productImage: j['product_image'].toString(),
    vendorName:   j['vendor_name'].toString(),
    unitPrice:    double.tryParse(j['unit_price'].toString()) ?? 0,
    quantity:     int.tryParse(j['quantity'].toString()) ?? 1,
  );
}

// ─────────────────────────────────────────────────────────────
// Cart Service
// ─────────────────────────────────────────────────────────────

class CartService {
  static const String _base = 'https://glopa.org/glo/cart.php';

  static Future<bool> addToCart(String userId, String productId) async {
    try {
      final res = await http.post(
        Uri.parse('$_base?action=add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'product_id': productId}),
      );
      final data = jsonDecode(res.body);
      return data['status'] == 'success';
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getCart(String userId) async {
    try {
      final res = await http.get(Uri.parse('$_base?action=get&user_id=$userId'));
      return jsonDecode(res.body);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> updateQuantity(String cartId, int quantity) async {
    try {
      final res = await http.post(
        Uri.parse('$_base?action=update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cart_id': cartId, 'quantity': quantity}),
      );
      final data = jsonDecode(res.body);
      return data['status'] == 'success';
    } catch (_) {
      return false;
    }
  }

  static Future<bool> removeItem(String cartId) async {
    try {
      final res = await http.post(
        Uri.parse('$_base?action=remove'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cart_id': cartId}),
      );
      final data = jsonDecode(res.body);
      return data['status'] == 'success';
    } catch (_) {
      return false;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Cart Screen
// ─────────────────────────────────────────────────────────────

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _items = [];
  bool _loading = true;
  double _total = 0;

  double s(double v) {
    final sw = MediaQuery.of(context).size.width;
    return (sw / 375 * v).clamp(v * 0.85, v * 1.25);
  }

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _loading = true);
    final user = context.read<UserProvider>().user;
    if (user == null) { setState(() => _loading = false); return; }

    final data = await CartService.getCart(user.userId);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (data != null && data['status'] == 'success') {
        _items = (data['items'] as List)
            .map((i) => CartItem.fromJson(i))
            .toList();
        _total = double.tryParse(data['total'].toString()) ?? 0;
      }
    });
  }

  void _recalcTotal() {
    setState(() => _total = _items.fold(0, (sum, i) => sum + i.subtotal));
  }

  Future<void> _updateQty(CartItem item, int delta) async {
    final newQty = item.quantity + delta;
    if (newQty < 1) {
      _removeItem(item);
      return;
    }
    setState(() => item.quantity = newQty);
    _recalcTotal();
    await CartService.updateQuantity(item.cartId, newQty);
  }

  Future<void> _removeItem(CartItem item) async {
    setState(() => _items.remove(item));
    _recalcTotal();
    await CartService.removeItem(item.cartId);
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
        title: Text('My Cart',
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.bold, fontSize: s(18))),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: () async {
                final user = context.read<UserProvider>().user;
                if (user == null) return;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content: const Text('Remove all items from cart?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Clear', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await http.post(
                    Uri.parse('https://glopa.org/glo/cart.php?action=clear'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({'user_id': user.userId}),
                  );
                  setState(() { _items.clear(); _total = 0; });
                }
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
          : _items.isEmpty
          ? _buildEmpty(textColor)
          : Stack(
        children: [
          RefreshIndicator(
            color: Colors.deepOrange,
            onRefresh: _loadCart,
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(s(16), s(12), s(16), s(120)),
              itemCount: _items.length,
              separatorBuilder: (_, __) => SizedBox(height: s(12)),
              itemBuilder: (_, i) =>
                  _buildCartItem(_items[i], cardColor, textColor, isDark),
            ),
          ),
          _buildBottomBar(cardColor, textColor, isDark),
        ],
      ),
    );
  }

  Widget _buildEmpty(Color textColor) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(IconsaxPlusLinear.shopping_cart,
            size: 72, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('Your cart is empty',
            style: TextStyle(
                fontSize: s(18),
                fontWeight: FontWeight.bold,
                color: textColor)),
        const SizedBox(height: 8),
        Text('Add products to get started',
            style: TextStyle(color: Colors.grey.shade500)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(s(14))),
            padding: EdgeInsets.symmetric(
                horizontal: s(32), vertical: s(14)),
          ),
          child: const Text('Browse Products'),
        ),
      ],
    ),
  );

  Widget _buildCartItem(
      CartItem item, Color card, Color text, bool isDark) {
    return Dismissible(
      key: Key(item.cartId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: s(20)),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(s(16)),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => _removeItem(item),
      child: Container(
        padding: EdgeInsets.all(s(12)),
        decoration: BoxDecoration(
          color:        card,
          borderRadius: BorderRadius.circular(s(16)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(s(12)),
              child: Image.network(
                item.productImage,
                width: s(75), height: s(75),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: s(75), height: s(75),
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: Colors.grey),
                ),
              ),
            ),
            SizedBox(width: s(12)),

            // Name + vendor + price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: s(14),
                          color: text)),
                  SizedBox(height: s(3)),
                  Text(item.vendorName,
                      style: TextStyle(
                          fontSize: s(11), color: Colors.grey.shade500)),
                  SizedBox(height: s(8)),
                  Text(
                    '₦${item.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.w800,
                        fontSize: 15),
                  ),
                ],
              ),
            ),

            // Quantity controls
            Column(
              children: [
                _qtyButton(Icons.add, () => _updateQty(item, 1)),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: s(6)),
                  child: Text('${item.quantity}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: s(15),
                          color: text)),
                ),
                _qtyButton(Icons.remove, () => _updateQty(item, -1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        color:        Colors.deepOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: Colors.deepOrange),
    ),
  );

  Widget _buildBottomBar(Color card, Color text, bool isDark) => Align(
    alignment: Alignment.bottomCenter,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: s(20), vertical: s(16)),
      decoration: BoxDecoration(
        color: card,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total',
                    style: TextStyle(
                        fontSize: s(16),
                        color: Colors.grey.shade500)),
                Text(
                  '₦${_total.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: s(20),
                      fontWeight: FontWeight.w900,
                      color: Colors.deepOrange),
                ),
              ],
            ),
            SizedBox(height: s(12)),
            SizedBox(
              width: double.infinity,
              height: s(52),
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutScreen(
                      items: _items,
                      total: _total,
                      onOrderPlaced: () {
                        setState(() { _items.clear(); _total = 0; });
                      },
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(s(16))),
                ),
                child: Text('Proceed to Checkout',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: s(16))),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// Checkout Screen
// ─────────────────────────────────────────────────────────────

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> items;
  final double total;
  final VoidCallback onOrderPlaced;

  const CheckoutScreen({
    super.key,
    required this.items,
    required this.total,
    required this.onOrderPlaced,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'wallet'; // 'wallet' | 'paystack'
  final _addressController = TextEditingController();
  final _noteController    = TextEditingController();
  bool _placing = false;
  double _deliveryFee = 0;
  bool _loadingFee = true;

  double s(double v) {
    final sw = MediaQuery.of(context).size.width;
    return (sw / 375 * v).clamp(v * 0.85, v * 1.25);
  }
  @override
  void initState() {
    super.initState();
    _fetchDeliveryFee();
  }
  Future<void> _fetchDeliveryFee() async {
    try {
      final res = await http.get(
        Uri.parse('https://glopa.org/glo/get_fees.php'),
      );
      final data = jsonDecode(res.body);
      if (!mounted) return;
      setState(() {
        _deliveryFee = (data['send_fee'] as num?)?.toDouble() ?? 0;
        _loadingFee  = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingFee = false);
    }
  }

  Future<void> _placeOrder({String paystackRef = ''}) async {
    if (_addressController.text.trim().isEmpty) {
      _snack('Please enter a delivery address.', isError: true);
      return;
    }

    setState(() => _placing = true);
    final user = context.read<UserProvider>().user;
    if (user == null) { setState(() => _placing = false); return; }

    try {
      final res = await http.post(
        Uri.parse('https://glopa.org/glo/checkout.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id':          user.userId,
          'payment_method':   _paymentMethod,
          'paystack_ref':     paystackRef,
          'delivery_address': _addressController.text.trim(),
          'note':             _noteController.text.trim(),
          'delivery_fee':     _deliveryFee,
        }),
      );

      final data = jsonDecode(res.body);
      if (!mounted) return;

      if (data['status'] == 'success') {
        widget.onOrderPlaced();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSuccessScreen(orderId: data['order_id']),
          ),
        );
      } else {
        _snack(data['message'] ?? 'Order failed.', isError: true);
      }
    } catch (_) {
      _snack('Network error. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }


  Future<void> _initiatePaystack() async {
    _snack('Paystack integration: pass the reference here after payment.');
    // Example with flutter_paystack:
    // final ref = await PaystackPlugin.checkout(...);
    // if (ref.status) _placeOrder(paystackRef: ref.reference);
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
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
        title: Text('Checkout',
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.bold, fontSize: s(18))),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(s(16), s(12), s(16), s(140)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Order summary ──────────────────────────
                _sectionTitle('Order Summary', textColor),
                SizedBox(height: s(10)),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(s(16)),
                  ),
                  child: Column(
                    children: [
                      ...widget.items.map((item) => Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: s(16), vertical: s(10)),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(s(8)),
                              child: Image.network(
                                item.productImage,
                                width: s(48), height: s(48),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: s(48), height: s(48),
                                  color: Colors.grey.shade200,
                                ),
                              ),
                            ),
                            SizedBox(width: s(12)),
                            Expanded(
                              child: Text(item.productName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: s(13))),
                            ),
                            Text('×${item.quantity}',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: s(12))),
                            SizedBox(width: s(8)),
                            Text(
                              '₦${item.subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      )),
                      // After the divider in the order summary container:
                      Divider(height: 1, color: Colors.grey.withOpacity(0.1)),

// Delivery fee row
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: s(16), vertical: s(10)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Delivery Fee',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: s(13))),
                            _loadingFee
                                ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.deepOrange))
                                : Text('₦${_deliveryFee.toStringAsFixed(2)}',
                                style: TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.w600,
                                    fontSize: s(13))),
                          ],
                        ),
                      ),

                      Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                      Padding(
                        padding: EdgeInsets.all(s(16)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    fontSize: s(15))),
                            Text(
                              '₦${(widget.total + _deliveryFee).toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.w900,
                                  fontSize: s(18)),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                      Padding(
                        padding: EdgeInsets.all(s(16)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    fontSize: s(15))),
                            Text(
                              '₦${widget.total.toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.w900,
                                  fontSize: s(18)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: s(20)),

                // ── Delivery address ───────────────────────
                _sectionTitle('Delivery Address', textColor),
                SizedBox(height: s(10)),
                _inputField(
                  controller: _addressController,
                  hint:       'Enter your delivery address',
                  icon:       IconsaxPlusLinear.location,
                  cardColor:  cardColor,
                  textColor:  textColor,
                  maxLines:   2,
                ),

                SizedBox(height: s(16)),

                // ── Note ──────────────────────────────────
                _sectionTitle('Note (optional)', textColor),
                SizedBox(height: s(10)),
                _inputField(
                  controller: _noteController,
                  hint:       'Any special instructions?',
                  icon:       IconsaxPlusLinear.message,
                  cardColor:  cardColor,
                  textColor:  textColor,
                ),

                SizedBox(height: s(20)),

                // ── Payment method ─────────────────────────
                _sectionTitle('Payment Method', textColor),
                SizedBox(height: s(10)),
                _paymentOption(
                  value:     'wallet',
                  label:     'Pay with Wallet',
                  subtitle:  'Deducted from your Globalpay wallet',
                  icon:      IconsaxPlusLinear.wallet_1,
                  cardColor: cardColor,
                  textColor: textColor,
                ),
                SizedBox(height: s(10)),
                _paymentOption(
                  value:     'paystack',
                  label:     'Pay with Paystack',
                  subtitle:  'Card, bank transfer, USSD',
                  icon:      IconsaxPlusLinear.card,
                  cardColor: cardColor,
                  textColor: textColor,
                ),
              ],
            ),
          ),

          // ── Place order button ─────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: s(20), vertical: s(16)),
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: s(52),
                  child: ElevatedButton(
                    onPressed: _placing
                        ? null
                        : () {
                      if (_paymentMethod == 'paystack') {
                        _initiatePaystack();
                      } else {
                        _placeOrder();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                      Colors.deepOrange.withOpacity(0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(s(16))),
                    ),
                    child: _placing
                        ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                        : Text(
                      _paymentMethod == 'paystack'
                          ? 'Pay ₦${widget.total.toStringAsFixed(2)} with Paystack'
                          : 'Place Order  ₦${widget.total.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: s(15)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, Color textColor) => Text(
    title,
    style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: s(15),
        color: textColor),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color cardColor,
    required Color textColor,
    int maxLines = 1,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(s(14)),
        ),
        child: TextField(
          controller: controller,
          maxLines:   maxLines,
          style:      TextStyle(color: textColor, fontSize: s(14)),
          decoration: InputDecoration(
            hintText:        hint,
            hintStyle:       TextStyle(color: Colors.grey.shade400),
            prefixIcon:      Icon(icon, color: Colors.deepOrange, size: s(20)),
            border:          InputBorder.none,
            contentPadding:  EdgeInsets.symmetric(
                horizontal: s(16), vertical: s(14)),
          ),
        ),
      );

  Widget _paymentOption({
    required String value,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color cardColor,
    required Color textColor,
  }) {
    final selected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(s(14)),
        decoration: BoxDecoration(
          color:        cardColor,
          borderRadius: BorderRadius.circular(s(14)),
          border: Border.all(
            color: selected ? Colors.deepOrange : Colors.grey.withOpacity(0.15),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(s(10)),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.deepOrange.withOpacity(0.12)
                    : Colors.grey.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: selected ? Colors.deepOrange : Colors.grey,
                  size: s(22)),
            ),
            SizedBox(width: s(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          fontSize: s(14))),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: s(12))),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.deepOrange, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Order Success Screen
// ─────────────────────────────────────────────────────────────

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    double s(double v) {
      final sw = MediaQuery.of(context).size.width;
      return (sw / 375 * v).clamp(v * 0.85, v * 1.25);
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(s(24)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: s(110), height: s(110),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.green, size: 60),
              ),
              SizedBox(height: s(28)),
              Text('Order Placed!',
                  style: TextStyle(
                      fontSize: s(26),
                      fontWeight: FontWeight.w900,
                      color: textColor)),
              SizedBox(height: s(10)),
              Text(
                'Your order has been placed successfully.\nWe\'ll notify you when it\'s confirmed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: s(14),
                    height: 1.5),
              ),
              SizedBox(height: s(16)),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: s(20), vertical: s(12)),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(s(12)),
                ),
                child: Text(
                  'Order ID: $orderId',
                  style: TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: s(13)),
                ),
              ),
              SizedBox(height: s(40)),
              SizedBox(
                width: double.infinity,
                height: s(52),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context)
                      .popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(s(16))),
                  ),
                  child: Text('Continue Shopping',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: s(16))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}