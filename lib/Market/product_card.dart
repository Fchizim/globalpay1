import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'checkout.dart';
import 'market_page.dart';
import 'product_details_page.dart';
import 'cart_provider.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';

class ProductCard extends StatelessWidget {
  final MarketProduct product;
  final bool isDarkMode;

  const ProductCard(this.product, {super.key, this.isDarkMode = false});

  double s(double value, BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return (sw / 375 * value).clamp(value * 0.85, value * 1.25);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final rating = double.tryParse(product.rating ?? '0') ?? 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider(
              create: (_) => CartProvider(),
              child: ProductDetailsPage(
                product: product,
                isDarkMode: isDarkMode,
              ),
            ),
          ),
        );
      },
      child: Container(
        // Clips any stray content to the rounded card shape instead
        // of letting it spill out messily if a line ever runs tight.
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(s(16, context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      product.productImage,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Container(
                              color: isDarkMode
                                  ? Colors.white10
                                  : Colors.grey.shade100,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.deepOrange,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                      errorBuilder: (_, __, ___) => Container(
                        color: isDarkMode
                            ? Colors.white10
                            : Colors.grey.shade100,
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey.shade400,
                            size: s(32, context),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: s(8, context),
                    right: s(8, context),
                    child: Container(
                      padding: EdgeInsets.all(s(4, context)),
                      decoration: const BoxDecoration(
                        color: Colors.white70,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite_border,
                        size: s(18, context),
                        color: Colors.black,
                      ),
                    ),
                  ),
                  if (product.featured == 'yes')
                    Positioned(
                      top: s(8, context),
                      left: s(8, context),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: s(7, context),
                          vertical: s(3, context),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange,
                          borderRadius: BorderRadius.circular(s(6, context)),
                        ),
                        child: Text(
                          'Featured',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: s(9, context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(s(10, context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + vendor/rating block. Wrapped in Expanded so
                    // it only ever takes the space left over after the
                    // price row below — if the card is ever squeezed too
                    // short, this compresses instead of throwing a
                    // RenderFlex overflow.
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              fontSize: s(14, context),
                            ),
                          ),
                          SizedBox(height: s(2, context)),
                          // Vendor name and rating share a single line
                          // instead of stacking, so the block needs one
                          // fewer line of height to fit everything.
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product.vendorName ?? 'Seller',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: s(11, context),
                                  ),
                                ),
                              ),
                              if (rating > 0) ...[
                                SizedBox(width: s(4, context)),
                                Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: s(12, context),
                                ),
                                SizedBox(width: s(2, context)),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: s(11, context),
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    Row(
                      children: [
                        // Flexible + ellipsis so a long price string
                        // shrinks/truncates instead of pushing the add
                        // button off the edge of the card.
                        Flexible(
                          child: Text(
                            '₦${product.productAmount}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.w800,
                              fontSize: s(15, context),
                            ),
                          ),
                        ),
                        const Spacer(),

                        // ── + button — add to cart ──
                        GestureDetector(
                          onTap: () async {
                            final user = context.read<UserProvider>().user;
                            if (user == null) return;
                            final added = await CartService.addToCart(
                              user.userId,
                              product.productId,
                            );
                            if (added && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Added to cart!'),
                                    ],
                                  ),
                                  backgroundColor: Colors.green.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(s(4, context)),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              IconsaxPlusLinear.add,
                              size: s(18, context),
                              color: Colors.deepOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
