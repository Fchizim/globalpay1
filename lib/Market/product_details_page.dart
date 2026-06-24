import 'package:flutter/material.dart';
import 'package:globalpay/Market/vendor_store_page.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';
import 'checkout.dart';
import 'market_page.dart';         // MarketProduct
import 'chat.dart';
// import 'cart_checkout.dart';       // CartService, CartScreen
import 'cart_provider.dart';
import '../provider/user_provider.dart';

class ProductDetailsPage extends StatefulWidget {
  final MarketProduct product;
  final bool isDarkMode;

  const ProductDetailsPage({
    super.key,
    required this.product,
    this.isDarkMode = false,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int  _currentImageIndex = 0;
  bool _addingToCart      = false;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  double s(double value) {
    final sw = MediaQuery.of(context).size.width;
    return (sw / 375 * value).clamp(value * 0.85, value * 1.25);
  }

  Future<void> _addToCart() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    setState(() => _addingToCart = true);
    final added = await CartService.addToCart(user.userId, widget.product.productId);
    if (!mounted) return;
    setState(() => _addingToCart = false);

    if (added) {
      context.read<CartProvider>().increment();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Text('Added to cart!'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Failed to add. Try again.'),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _goToCart() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CartScreen()),
  );

  @override
  Widget build(BuildContext context) {
    final p          = widget.product;
    final isDark     = widget.isDarkMode;
    final bgColor    = isDark ? const Color(0xFF121212) : Colors.white;
    final cardColor  = isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50;
    final textColor  = isDark ? Colors.white : Colors.black;
    final cartCount  = context.watch<CartProvider>().count;

    final images       = p.productImages.isNotEmpty ? p.productImages : [p.productImage];
    final sellerName   = p.vendorName ?? 'Seller';
    final rating       = double.tryParse(p.rating ?? '0') ?? 0.0;
    final vendorRating = double.tryParse(p.vendorRating ?? '0') ?? 0.0;
    final description  = p.description?.isNotEmpty == true
        ? p.description!
        : 'No description provided for this product.';

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
        actions: [
          IconButton(
            icon: Icon(IconsaxPlusLinear.heart, color: textColor),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(IconsaxPlusLinear.share, color: textColor),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: s(100)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Image carousel ───────────────────────
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width:  double.infinity,
                      height: s(320),
                      margin: EdgeInsets.all(s(15)),
                      decoration: BoxDecoration(
                        color:        cardColor,
                        borderRadius: BorderRadius.circular(s(25)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(s(25)),
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount:  images.length,
                          onPageChanged: (i) =>
                              setState(() => _currentImageIndex = i),
                          itemBuilder: (_, i) => Image.network(
                            images[i],
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) =>
                            progress == null
                                ? child
                                : Center(
                              child: CircularProgressIndicator(
                                color: Colors.deepOrange,
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(Icons.image_not_supported_outlined,
                                  color: Colors.grey.shade400, size: s(48)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (images.length > 1)
                      Positioned(
                        bottom: s(24),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(images.length, (i) {
                            final active = i == _currentImageIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width:  active ? s(18) : s(7),
                              height: s(7),
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.deepOrange
                                    : Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(s(4)),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: s(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Name & price ─────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(p.name,
                                style: TextStyle(
                                    fontSize:   s(22),
                                    fontWeight: FontWeight.bold,
                                    color:      textColor)),
                          ),
                          SizedBox(width: s(12)),
                          Text('₦${p.productAmount}',
                              style: TextStyle(
                                  fontSize:   s(22),
                                  color:      Colors.deepOrange,
                                  fontWeight: FontWeight.w900)),
                        ],
                      ),

                      SizedBox(height: s(8)),

                      // ── Star rating ──────────────────────
                      if (rating > 0) ...[
                        Row(
                          children: [
                            ...List.generate(5, (i) => Icon(
                              i < rating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: Colors.amber,
                              size:  s(16),
                            )),
                            SizedBox(width: s(6)),
                            Text(rating.toStringAsFixed(1),
                                style: TextStyle(
                                    fontSize:   s(13),
                                    color:      Colors.grey.shade600,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        SizedBox(height: s(6)),
                      ],

                      // ── Chips ─────────────────────────────
                      Wrap(
                        spacing: s(8),
                        children: [
                          if (p.categoryName?.isNotEmpty == true)
                            _chip(p.categoryName!, cardColor, textColor),
                          if (p.vendorLocation?.isNotEmpty == true)
                            _chip('📍 ${p.vendorLocation!}', cardColor, textColor),
                        ],
                      ),

                      SizedBox(height: s(20)),


                      GestureDetector(
                        onTap: () {
                          debugPrint('p.vendorId = ${p.vendorId}');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VendorStorePage(
                                vendorId: p.vendorId ?? '',
                                vendorName: sellerName,
                                vendorRating: vendorRating,
                                vendorLocation: p.vendorLocation,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(s(12)),
                          decoration: BoxDecoration(
                            color:        cardColor,
                            borderRadius: BorderRadius.circular(s(15)),
                            border: Border.all(
                                color: Colors.grey.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius:          s(22),
                                backgroundColor: Colors.deepOrange,
                                child: Text(
                                  sellerName[0].toUpperCase(),
                                  style: const TextStyle(
                                      color:      Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              SizedBox(width: s(12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(sellerName,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize:   s(15),
                                            color:      textColor)),
                                    Row(
                                      children: [
                                        Icon(Icons.star_rounded,
                                            color: Colors.amber, size: s(13)),
                                        SizedBox(width: s(3)),
                                        Text(
                                          vendorRating > 0
                                              ? vendorRating.toStringAsFixed(1)
                                              : 'New Seller',
                                          style: TextStyle(
                                              fontSize: s(12),
                                              color:    Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(IconsaxPlusLinear.arrow_right_3,
                                  size: s(18), color: Colors.grey),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: s(25)),

                      // ── Description ──────────────────────
                      Text('Description',
                          style: TextStyle(
                              fontSize:   s(16),
                              fontWeight: FontWeight.bold,
                              color:      textColor)),
                      SizedBox(height: s(8)),
                      Text(description,
                          style: TextStyle(
                              fontSize: s(14),
                              color:    Colors.grey.shade600,
                              height:   1.6)),

                      SizedBox(height: s(25)),

                      // ── Quick actions ─────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _actionButton(
                            icon:  IconsaxPlusLinear.message,
                            label: 'Chat Seller',
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) => ChatScreen())),
                          ),
                          _actionButton(
                            icon:  IconsaxPlusLinear.coin_1,
                            label: 'Make Offer',
                            onTap: () {},
                          ),
                          _actionButton(
                            icon:  IconsaxPlusLinear.info_circle,
                            label: 'Report',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Fixed bottom bar ─────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: s(20), vertical: s(15)),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // ── Cart icon with badge → go to cart ──
                    GestureDetector(
                      onTap: _goToCart,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: s(50),
                            width: s(50),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(s(15)),
                            ),
                            child: const Icon(
                              IconsaxPlusLinear.shopping_cart,
                              color: Colors.deepOrange,
                            ),
                          ),
                          if (cartCount > 0)
                            Positioned(
                              top: -6,
                              right: -6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.deepOrange,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                    minWidth: 18, minHeight: 18),
                                child: Text(
                                  cartCount > 99 ? '99+' : '$cartCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(width: s(15)),

                    // ── Add to Cart button (was "Buy Now") ──
                    Expanded(
                      child: SizedBox(
                        height: s(50),
                        child: ElevatedButton(
                          onPressed: _addingToCart ? null : _addToCart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                            Colors.deepOrange.withOpacity(0.5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(s(15))),
                          ),
                          child: _addingToCart
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(IconsaxPlusLinear.shopping_cart,
                                  size: 18),
                              const SizedBox(width: 8),
                              const Text('Add to Cart',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color bg, Color textColor) => Container(
    padding: EdgeInsets.symmetric(horizontal: s(10), vertical: s(4)),
    decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(s(20))),
    child: Text(label,
        style: TextStyle(
            fontSize: s(11), color: textColor.withOpacity(0.7))),
  );

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Container(
                height: s(45),
                width:  s(45),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepOrange.withOpacity(0.1),
                ),
                child: Icon(icon, size: s(22), color: Colors.deepOrange),
              ),
              SizedBox(height: s(6)),
              Text(label,
                  style: TextStyle(
                      fontSize: s(11), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}