import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:http/http.dart' as http;
import '../Market/product_details_page.dart';
import 'market_page.dart';

class VendorStorePage extends StatefulWidget {
  final String vendorId;
  final String vendorName;
  final double vendorRating;
  final String? vendorLocation;
  final String? vendorImage;

  const VendorStorePage({
    super.key,
    required this.vendorId,
    required this.vendorName,
    this.vendorRating = 0,
    this.vendorLocation,
    this.vendorImage,
  });

  @override
  State<VendorStorePage> createState() => _VendorStorePageState();
}

class _VendorStorePageState extends State<VendorStorePage> {
  List<MarketProduct> _products = [];
  bool _isLoading = true;
  String? _error;

  // ── Search ───────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<MarketProduct> get _filtered {
    if (_searchQuery.isEmpty) return _products;
    final q = _searchQuery.toLowerCase();
    return _products.where((p) =>
    p.name.toLowerCase().contains(q) ||
        (p.categoryName?.toLowerCase().contains(q) ?? false) ||
        (p.description?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchVendorProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchVendorProducts() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await http.get(Uri.parse(
        'https://glopa.org/glo/get_vendor_products.php?vendor_id=${Uri.encodeQueryComponent(widget.vendorId)}',
      ));
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        final list = data['products'] as List;
        setState(() {
          _products  = list.map((e) => MarketProduct.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() { _error = data['message'] ?? 'Failed to load.'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Network error. Pull to refresh.'; _isLoading = false; });
    }
  }

  double s(double value) {
    final sw = MediaQuery.of(context).size.width;
    return (sw / 375 * value).clamp(value * 0.85, value * 1.25);
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? const Color(0xFF121212) : Colors.white;
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50;
    final textColor = isDark ? Colors.white : Colors.black;

    final double topInset = MediaQuery.of(context).padding.top;
    final bool hasLocation = widget.vendorLocation?.isNotEmpty == true;

    // Header height: avatar row + stats strip + search bar
    final double headerContentHeight =
        (hasLocation ? s(82) : s(64))
            + s(12)   // gap
            + s(40)   // stats strip
            + s(16)   // gap
            + s(44)   // search bar
            + s(12)   // bottom padding
            + 12;
    final double expandedH = topInset + 56 + headerContentHeight;

    final filtered = _filtered;

    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        onRefresh: _fetchVendorProducts,
        color: Colors.deepOrange,
        child: CustomScrollView(
          slivers: [

            // ── Sticky collapsible header ──────────────────────
            SliverAppBar(
              pinned: true,
              expandedHeight: expandedH,
              backgroundColor: bgColor,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: Icon(IconsaxPlusLinear.arrow_left_2, color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: bgColor,
                  padding: EdgeInsets.only(
                      top: topInset + 56,
                      left: s(20), right: s(20), bottom: s(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Avatar + name row ──────────────────
                      Row(children: [
                        CircleAvatar(
                          radius: s(30),
                          backgroundColor: Colors.deepOrange,
                          backgroundImage: widget.vendorImage != null
                              ? NetworkImage(widget.vendorImage!) : null,
                          child: widget.vendorImage == null
                              ? Text(widget.vendorName[0].toUpperCase(),
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: s(20)))
                              : null,
                        ),
                        SizedBox(width: s(14)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Flexible(
                                  child: Text(widget.vendorName,
                                      style: TextStyle(
                                          fontSize: s(18),
                                          fontWeight: FontWeight.bold,
                                          color: textColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                SizedBox(width: s(5)),
                                const Icon(IconsaxPlusBold.verify,
                                    color: Colors.blue, size: 16),
                              ]),
                              SizedBox(height: s(4)),
                              Row(children: [
                                ...List.generate(5, (i) => Icon(
                                  i < widget.vendorRating.round()
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: Colors.amber, size: s(14),
                                )),
                                SizedBox(width: s(5)),
                                Text(
                                  widget.vendorRating > 0
                                      ? widget.vendorRating.toStringAsFixed(1)
                                      : 'New Seller',
                                  style: TextStyle(fontSize: s(12), color: Colors.grey),
                                ),
                              ]),
                              if (hasLocation) ...[
                                SizedBox(height: s(3)),
                                Row(children: [
                                  Icon(IconsaxPlusLinear.location,
                                      size: s(12), color: Colors.grey),
                                  SizedBox(width: s(4)),
                                  Text(widget.vendorLocation!,
                                      style: TextStyle(fontSize: s(12), color: Colors.grey)),
                                ]),
                              ],
                            ],
                          ),
                        ),
                      ]),

                      SizedBox(height: s(12)),

                      // ── Stats strip ────────────────────────
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: s(16), vertical: s(10)),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(s(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _stat(
                              _isLoading ? '–' : '${_products.length}',
                              'Products', textColor,
                            ),
                            Container(height: 24, width: 1,
                                color: Colors.grey.withOpacity(0.3)),
                            _stat(
                              widget.vendorRating > 0
                                  ? widget.vendorRating.toStringAsFixed(1) : '–',
                              'Rating', textColor,
                            ),
                            Container(height: 24, width: 1,
                                color: Colors.grey.withOpacity(0.3)),
                            _stat('Active', 'Status', Colors.green),
                          ],
                        ),
                      ),

                      SizedBox(height: s(16)),

                      // ── Search bar ─────────────────────────
                      Container(
                        height: s(44),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(s(14)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(
                              fontSize: s(13),
                              color: textColor),
                          decoration: InputDecoration(
                            hintText: 'Search in ${widget.vendorName}\'s store…',
                            hintStyle: TextStyle(
                                fontSize: s(13),
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey.shade400),
                            prefixIcon: Icon(
                                IconsaxPlusLinear.search_normal,
                                size: s(18),
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey.shade400),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                              icon: Icon(Icons.close_rounded,
                                  size: s(18), color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                                : null,
                            border: InputBorder.none,
                            contentPadding:
                            EdgeInsets.symmetric(vertical: s(12)),
                          ),
                          onChanged: (v) =>
                              setState(() => _searchQuery = v.trim()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              title: Text('${widget.vendorName}\'s Store',
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: s(16))),
            ),

            // ── "Products" heading ─────────────────────────────
            SliverPadding(
              padding: EdgeInsets.symmetric(
                  horizontal: s(20), vertical: s(8)),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _searchQuery.isEmpty
                          ? 'All Products'
                          : '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                      style: TextStyle(
                          fontSize: s(15),
                          fontWeight: FontWeight.bold,
                          color: textColor),
                    ),
                  ],
                ),
              ),
            ),

            // ── Body states ────────────────────────────────────
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(
                    color: Colors.deepOrange)),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _fetchVendorProducts,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange),
                      child: const Text('Retry',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ]),
                ),
              )
            else if (filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        _searchQuery.isEmpty
                            ? IconsaxPlusLinear.shop
                            : Icons.search_off_rounded,
                        size: s(50), color: Colors.grey.shade300,
                      ),
                      SizedBox(height: s(10)),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No products yet'
                            : 'No results for "$_searchQuery"',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (_searchQuery.isNotEmpty) ...[
                        SizedBox(height: s(6)),
                        Text('Try a different keyword',
                            style: TextStyle(
                                fontSize: s(12), color: Colors.grey.shade400)),
                      ],
                    ]),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                      horizontal: s(16), vertical: s(4)),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:   2,
                      mainAxisSpacing:  s(14),
                      crossAxisSpacing: s(14),
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                          (_, i) => _ProductCard(
                        product:   filtered[i],
                        isDark:    isDark,
                        cardColor: cardColor,
                        textColor: textColor,
                        s:         s,
                      ),
                      childCount: filtered.length,
                    ),
                  ),
                ),

            SliverToBoxAdapter(child: SizedBox(height: s(30))),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, Color valueColor) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
              color: valueColor)),
      Text(label,
          style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ],
  );
}

// ── Reusable product card ──────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final MarketProduct product;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final double Function(double) s;

  const _ProductCard({
    required this.product,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final images = product.productImages.isNotEmpty
        ? product.productImages
        : [product.productImage];

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ProductDetailsPage(
            product: product, isDarkMode: isDark),
      )),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(s(18)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(s(18))),
              child: Image.network(
                images[0],
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: Icon(Icons.image_not_supported_outlined,
                      color: Colors.grey.shade400, size: s(30)),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(s(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name,
                  style: TextStyle(fontWeight: FontWeight.bold,
                      fontSize: s(13), color: textColor),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: s(4)),
              Text('₦${product.productAmount}',
                  style: TextStyle(color: Colors.deepOrange,
                      fontWeight: FontWeight.bold, fontSize: s(14))),
            ]),
          ),
        ]),
      ),
    );
  }
}