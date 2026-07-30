import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:globalpay/Market/seller_chart.dart';
import 'package:globalpay/Market/vendort_orders.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:globalpay/Market/business_page.dart';
import 'checkout.dart';
import 'editors_profile.dart';
import 'orders_page.dart';
import 'product_card.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../provider/user_provider.dart';
import 'package:globalpay/Market/StoreSetupPage.dart';

class MarketCategory {
  final String catId;
  final String name;
  const MarketCategory({required this.catId, required this.name});

  factory MarketCategory.fromJson(Map<String, dynamic> j) =>
      MarketCategory(catId: j['cat_id'].toString(), name: j['name'].toString());
}

class MarketProduct {
  final String productId;
  final String name;
  final String productImage;
  final List<String> productImages;
  final String productAmount;
  final String? description;
  final String? categoryName;
  final String? catId;
  final String? vendorId;
  final String? vendorName;
  final String? vendorLocation;
  final String? vendorRating;
  final String? rating;
  final String? featured;

  const MarketProduct({
    required this.productId,
    required this.name,
    required this.productImage,
    required this.productImages,
    required this.productAmount,
    this.description,
    this.categoryName,
    this.catId,
    this.vendorId,
    this.vendorName,
    this.vendorLocation,
    this.vendorRating,
    this.rating,
    this.featured,
  });

  factory MarketProduct.fromJson(Map<String, dynamic> j) {
    final amount = j['product_amount']?.toString()
        ?? j['price']?.toString()
        ?? '0.00';

    final rawImages = j['product_images'] ?? j['images'];
    final imageList = (rawImages as List?)
        ?.map((e) => e.toString())
        .toList()
        ?? [j['product_image']?.toString() ?? ''];

    return MarketProduct(
      productId:      j['product_id'].toString(),
      name:           j['name'].toString(),
      productImage:   j['product_image']?.toString() ?? imageList.first,
      productImages:  imageList,
      productAmount:  amount,
      description:    j['description']?.toString(),
      categoryName:   j['category_name']?.toString(),
      catId:          j['cat_id']?.toString(),
      vendorId:       j['vendor_id']?.toString()
          ?? j['business_id']?.toString(),
      vendorName:     j['vendor_name']?.toString()
          ?? j['business_name']?.toString(),
      vendorLocation: j['vendor_location']?.toString()
          ?? j['business_location']?.toString(),
      vendorRating:   j['vendor_rating']?.toString(),
      rating:         j['rating']?.toString(),
      featured:       j['featured']?.toString(),
    );
  }

  Map<String, dynamic> toDisplayMap() => {
    'image':  productImage,
    'name':   name,
    'price':  '₦$productAmount',
    'seller': vendorName ?? 'Seller',
  };
}

// ─────────────────────────────────────────────────────────────
// Product filters (sort / price / rating)
// ─────────────────────────────────────────────────────────────

enum ProductSort { relevance, priceLowHigh, priceHighLow, ratingHighLow, newest }

class ProductFilters {
  ProductSort sort;
  RangeValues priceRange; // 0..maxPrice, maxPrice means "no upper cap"
  double minRating; // 0 = no minimum

  static const double maxPrice = 500000;

  ProductFilters({
    this.sort = ProductSort.relevance,
    this.priceRange = const RangeValues(0, maxPrice),
    this.minRating = 0,
  });

  bool get isActive =>
      sort != ProductSort.relevance ||
          priceRange.start > 0 ||
          priceRange.end < maxPrice ||
          minRating > 0;

  int get activeCount {
    int c = 0;
    if (sort != ProductSort.relevance) c++;
    if (priceRange.start > 0 || priceRange.end < maxPrice) c++;
    if (minRating > 0) c++;
    return c;
  }

  ProductFilters copy() => ProductFilters(
    sort: sort,
    priceRange: priceRange,
    minRating: minRating,
  );

  String get sortParam {
    switch (sort) {
      case ProductSort.priceLowHigh: return 'price_asc';
      case ProductSort.priceHighLow: return 'price_desc';
      case ProductSort.ratingHighLow: return 'rating_desc';
      case ProductSort.newest: return 'newest';
      case ProductSort.relevance: return '';
    }
  }

  Map<String, String> toQueryParams() {
    final p = <String, String>{};
    if (sortParam.isNotEmpty) p['sort'] = sortParam;
    if (priceRange.start > 0) p['min_price'] = priceRange.start.round().toString();
    if (priceRange.end < maxPrice) p['max_price'] = priceRange.end.round().toString();
    if (minRating > 0) p['min_rating'] = minRating.toString();
    return p;
  }
}

// ─────────────────────────────────────────────────────────────
// CardPage
// ─────────────────────────────────────────────────────────────

class CardPage extends StatefulWidget {
  const CardPage({super.key});

  @override
  State<CardPage> createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _rotationController;
  final ScrollController _scrollController = ScrollController();
  bool _isTabVisible = true;

  // Search state
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _isSearching = false;
  bool _searchLoading = false;
  List<MarketProduct> _searchResults = [];
  String _lastQuery = '';

  List<MarketCategory> _categories = [];
  bool _categoriesLoaded = false;

  final List<List<MarketProduct>> _tabProducts = [];
  final List<int>  _currentPage = [];
  final List<bool> _isLoading   = [];
  final List<bool> _hasMore     = [];

  ProductFilters _filters = ProductFilters();

  static const String _baseUrl  = 'https://glopa.org/glo/get_all_product.php';
  static const int    _pageSize = 20;

  // Small rotating icon set so each category chip gets a distinct, stable icon.
  static final List<IconData> _catIconPool = [
    IconsaxPlusLinear.chart,
    IconsaxPlusLinear.mobile,
    IconsaxPlusLinear.home_2,
    IconsaxPlusLinear.watch,
    IconsaxPlusLinear.bag_2,
    IconsaxPlusLinear.game,
    IconsaxPlusLinear.book,
    IconsaxPlusLinear.heart,
    IconsaxPlusLinear.cup,
    IconsaxPlusLinear.car,
  ];

  IconData _iconForCategory(int index) => _catIconPool[index % _catIconPool.length];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _tabController = TabController(length: 1, vsync: this);
    _scrollController.addListener(_onScroll);
    _fetchInitial();
  }

  double s(double v, BuildContext ctx) {
    final sw = MediaQuery.of(ctx).size.width;
    return (sw / 375 * v).clamp(v * 0.85, v * 1.25);
  }

  void _initTabState(int count) {
    _tabProducts.clear();
    _currentPage.clear();
    _isLoading.clear();
    _hasMore.clear();
    for (int i = 0; i < count; i++) {
      _tabProducts.add([]);
      _currentPage.add(0);
      _isLoading.add(false);
      _hasMore.add(true);
    }
  }

  String _catIdForTab(int tabIndex) {
    if (tabIndex == 0) return '';
    return _categories[tabIndex - 1].catId;
  }

  // ── Search ───────────────────────────────────────────────

  Future<void> _onSearchChanged(String query) async {
    final q = query.trim();
    if (q == _lastQuery) return;
    _lastQuery = q;

    if (q.isEmpty) {
      setState(() { _searchResults = []; _searchLoading = false; });
      return;
    }

    setState(() => _searchLoading = true);

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'page':   '1',
        'limit':  '40',
        'search': q,
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (data['products'] as List? ?? [])
            .map((p) => MarketProduct.fromJson(p))
            .toList();

        // Client-side filter as fallback if backend doesn't support ?search=
        final filtered = list.where((p) =>
        p.name.toLowerCase().contains(q.toLowerCase()) ||
            (p.vendorName?.toLowerCase().contains(q.toLowerCase()) ?? false) ||
            (p.categoryName?.toLowerCase().contains(q.toLowerCase()) ?? false)
        ).toList();

        setState(() {
          _searchResults = filtered;
          _searchLoading = false;
        });
      } else {
        setState(() => _searchLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _searchLoading = false);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _lastQuery = '';
    setState(() {
      _isSearching   = false;
      _searchResults = [];
      _searchLoading = false;
    });
    _searchFocus.unfocus();
  }

  // ── Networking ───────────────────────────────────────────

  Future<void> _fetchInitial() async {
    final result = await _fetchPage(catId: '', page: 1);
    if (!mounted || result == null) return;

    final cats = (result['categories'] as List? ?? [])
        .map((c) => MarketCategory.fromJson(c))
        .toList();
    final products = (result['products'] as List? ?? [])
        .map((p) => MarketProduct.fromJson(p))
        .toList();
    final hasMore  = result['has_more'] as bool? ?? false;
    final tabCount = 1 + cats.length;

    setState(() {
      _categories       = cats;
      _categoriesLoaded = true;
      _tabController.dispose();
      _tabController = TabController(length: tabCount, vsync: this)
        ..addListener(_onTabChanged);
      _initTabState(tabCount);
      _tabProducts[0] = products;
      _currentPage[0] = 1;
      _hasMore[0]     = hasMore;
    });
  }

  Future<Map<String, dynamic>?> _fetchPage({
    required String catId,
    required int page,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'page':  page.toString(),
        'limit': _pageSize.toString(),
        if (catId.isNotEmpty) 'cat_id': catId,
        ..._filters.toQueryParams(),
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  Future<void> _loadMore(int tabIndex) async {
    if (_isLoading[tabIndex] || !_hasMore[tabIndex]) return;
    setState(() => _isLoading[tabIndex] = true);
    final nextPage = _currentPage[tabIndex] + 1;
    final catId    = _catIdForTab(tabIndex);
    final result   = await _fetchPage(catId: catId, page: nextPage);
    if (!mounted) return;
    if (result != null) {
      final newProducts = (result['products'] as List? ?? [])
          .map((p) => MarketProduct.fromJson(p))
          .toList();
      setState(() {
        _tabProducts[tabIndex].addAll(newProducts);
        _currentPage[tabIndex] = nextPage;
        _hasMore[tabIndex]     = result['has_more'] as bool? ?? false;
        _isLoading[tabIndex]   = false;
      });
    } else {
      setState(() => _isLoading[tabIndex] = false);
    }
  }

  Future<void> _ensureTabLoaded(int tabIndex) async {
    if (_tabProducts[tabIndex].isNotEmpty || _isLoading[tabIndex]) return;
    await _loadMore(tabIndex);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    _ensureTabLoaded(_tabController.index);
  }

  void _onScroll() {
    final dir = _scrollController.position.userScrollDirection;
    if (dir == ScrollDirection.reverse && _isTabVisible) {
      setState(() => _isTabVisible = false);
    } else if (dir == ScrollDirection.forward && !_isTabVisible) {
      setState(() => _isTabVisible = true);
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      final tab = _tabController.index;
      if (!_isLoading[tab] && _hasMore[tab]) _loadMore(tab);
    }
  }

  // ── Filters ──────────────────────────────────────────────

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<ProductFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductFilterSheet(initial: _filters.copy()),
    );
    if (result != null) {
      setState(() {
        _filters = result;
        _initTabState(_tabController.length);
      });
      await _loadMore(_tabController.index);
    }
  }

  void _clearFilters() {
    setState(() {
      _filters = ProductFilters();
      _initTabState(_tabController.length);
    });
    _loadMore(_tabController.index);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rotationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Search results grid ──────────────────────────────────

  Widget _buildSearchResults(bool isDarkMode) {
    if (_searchLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.deepOrange),
      );
    }

    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(IconsaxPlusLinear.search_normal,
              size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Search for products, vendors, or categories',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ]),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off_rounded, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No results for "${_searchController.text.trim()}"',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 6),
          Text('Try a different keyword',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ]),
      );
    }

    return Builder(
      builder: (context) => GridView.builder(
        padding: EdgeInsets.fromLTRB(
            s(12, context), s(8, context), s(12, context), s(80, context)),
        itemCount: _searchResults.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:   2,
          mainAxisSpacing:  s(15, context),
          crossAxisSpacing: s(15, context),
          childAspectRatio: 0.68,
        ),
        itemBuilder: (ctx, i) => ProductCard(
          _searchResults[i],
          isDarkMode: isDarkMode,
        ),
      ),
    );
  }

  // ── Regular grid ─────────────────────────────────────────

  Widget _buildGrid(int tabIndex, bool isDarkMode) {
    final items   = _tabProducts.length > tabIndex ? _tabProducts[tabIndex] : <MarketProduct>[];
    final loading = _isLoading.length > tabIndex && _isLoading[tabIndex];
    final more    = _hasMore.length > tabIndex && _hasMore[tabIndex];

    if (items.isEmpty && loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
    }
    if (items.isEmpty && !loading) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.storefront_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            _filters.isActive ? 'No products match these filters' : 'No products yet',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          if (_filters.isActive) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear filters', style: TextStyle(color: Colors.deepOrange)),
            ),
          ],
        ]),
      );
    }

    return Builder(
      builder: (context) => GridView.builder(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(
            s(12, context), s(8, context), s(12, context), s(80, context)),
        itemCount: items.length + (more ? 1 : 0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:   2,
          mainAxisSpacing:  s(15, context),
          crossAxisSpacing: s(15, context),
          childAspectRatio: 0.68,
        ),
        itemBuilder: (ctx, index) {
          if (index >= items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Colors.deepOrange),
              ),
            );
          }
          return ProductCard(items[index], isDarkMode: isDarkMode);
        },
      ),
    );
  }

  // ── Sell button ──────────────────────────────────────────

  Future<void> _onSellTapped() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
      const Center(child: CircularProgressIndicator(color: Colors.deepOrange)),
    );
    try {
      final checkRes  = await http.get(Uri.parse(
          'https://glopa.org/glo/check_subscription.php?user_id=${user.userId}'));
      final checkData = jsonDecode(checkRes.body);
      if (!mounted) return;
      if (checkData['status'] != 'success' || checkData['active'] != true) {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessPage()));
        return;
      }
      final profileRes  = await http.post(
        Uri.parse('https://glopa.org/glo/get_business_profile.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': user.userId}),
      );
      final profileData = jsonDecode(profileRes.body);
      if (!mounted) return;
      Navigator.pop(context);
      if (profileData['status'] == 'success') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerPage()));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreSetupPage()));
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Network error. Please try again.'),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor    = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final textColor  = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: bgColor,
        elevation: 0,
        title: Row(children: [
          GestureDetector(
            onTap: _onSellTapped,
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) => Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(s(22, context)),
                  gradient: SweepGradient(
                    colors: const [
                      Colors.deepOrange, Colors.yellow, Colors.pink,
                      Colors.deepPurple, Colors.blue,
                    ],
                    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                    transform: GradientRotation(
                        _rotationController.value * 2 * 3.14159),
                  ),
                ),
                child: child,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: s(14, context), vertical: s(6, context)),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(s(20, context)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.storefront,
                      color: Colors.deepOrange[500], size: s(18, context)),
                  SizedBox(width: s(6, context)),
                  Text('SELL',
                      style: TextStyle(
                        color: textColor,
                        fontSize: s(13, context),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      )),
                ]),
              ),
            ),
          ),
          SizedBox(width: s(12, context)),
          Text('GlobalBiz',
              style: TextStyle(
                fontSize: s(15, context),
                fontWeight: FontWeight.w600,
                color: textColor,
              )),
        ]),
        actions: [
          Stack(clipBehavior: Clip.none, children: [
            IconButton(
              icon: Icon(IconsaxPlusLinear.shopping_bag, color: textColor),
              tooltip: 'Cart',
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const CartScreen()
              )
              ),
            ),
            Positioned(
              top: 6, right: 6,
              child: FutureBuilder<Map<String, dynamic>?>(
                future: CartService.getCart(
                    context.read<UserProvider>().user?.userId ?? ''),
                builder: (context, snapshot) {
                  final count = (snapshot.data?['count'] as num?)?.toInt() ?? 0;
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: Colors.deepOrange, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 9,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                  );
                },
              ),
            ),
          ]),
          // IconButton(
          //   icon: Icon(IconsaxPlusLinear.message, color: textColor),
          //   tooltip: 'Messages',
          //   onPressed: () => Navigator.push(
          //       context, MaterialPageRoute(builder: (_) => MessagesPage())),
          // ),
          IconButton(
            icon: Icon(IconsaxPlusLinear.bag_2, color: textColor),
            tooltip: 'Orders',
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const OrdersPage())),
          ),
          IconButton(
            icon: Icon(IconsaxPlusLinear.shopping_cart, color: textColor),
            tooltip: 'Vendor Orders',
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => VendorOrdersScreen())),
          ),
        ],
      ),

      body: !_categoriesLoaded
          ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
          : Column(children: [

        // ── Always-visible search bar ──────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(
              s(12, context), s(6, context), s(12, context), s(6, context)),
          child: Container(
            height: s(46, context),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(s(14, context)),
              boxShadow: isDarkMode ? [] : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode:  _searchFocus,
              style: TextStyle(
                  fontSize: s(13, context),
                  color: textColor),
              decoration: InputDecoration(
                hintText: 'Search products, sellers, categories…',
                hintStyle: TextStyle(
                    color: isDarkMode
                        ? Colors.white38
                        : Colors.grey.shade400,
                    fontSize: s(13, context)),
                prefixIcon: Icon(
                    IconsaxPlusLinear.search_normal,
                    size: s(18, context),
                    color: Colors.deepOrange),
                suffixIcon: _isSearching
                    ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: s(18, context), color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                    setState(() => _isSearching = false);
                    _searchFocus.unfocus();
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding:
                EdgeInsets.symmetric(vertical: s(14, context)),
              ),
              onChanged: (v) {
                setState(() => _isSearching = v.trim().isNotEmpty);
                _onSearchChanged(v);
              },
              onTap: () => setState(() {}), // refresh suffix icon
              textInputAction: TextInputAction.search,
            ),
          ),
        ),

        // ── Category chips + filter button — hidden while searching ─────
        if (!_isSearching)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: _isTabVisible ? s(52, context) : 0,
            curve: Curves.easeInOut,
            child: _isTabVisible
                ? _buildCategoryBar(isDarkMode, textColor)
                : const SizedBox.shrink(),
          ),

        if (!_isSearching && _filters.isActive)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: s(16, context)),
            child: Row(
              children: [
                Icon(IconsaxPlusLinear.filter, size: 13, color: Colors.deepOrange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_filters.activeCount} filter${_filters.activeCount > 1 ? 's' : ''} applied',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                  ),
                ),
                GestureDetector(
                  onTap: _clearFilters,
                  child: const Text('Clear',
                      style: TextStyle(
                          color: Colors.deepOrange, fontSize: 11.5, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

        // ── Content area ───────────────────────────────
        Expanded(
          child: _isSearching
              ? _buildSearchResults(isDarkMode)
              : TabBarView(
            controller: _tabController,
            children: List.generate(
                _tabController.length,
                    (i) => _buildGrid(i, isDarkMode)),
          ),
        ),
      ]),
    );
  }

  // ── Category chip bar ────────────────────────────────────

  Widget _buildCategoryBar(bool isDarkMode, Color textColor) {
    final labels = ['All', ..._categories.map((c) => c.name)];

    return Builder(
      builder: (context) => Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: s(12, context)),
              itemCount: labels.length,
              separatorBuilder: (_, __) => SizedBox(width: s(8, context)),
              itemBuilder: (ctx, i) {
                return AnimatedBuilder(
                  animation: _tabController.animation ?? _tabController,
                  builder: (context, _) {
                    final isSelected = _tabController.index == i;
                    return GestureDetector(
                      onTap: () => _tabController.animateTo(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(
                            horizontal: s(14, context), vertical: s(8, context)),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.deepOrange
                              : (isDarkMode
                              ? Colors.white.withOpacity(0.08)
                              : Colors.deepOrange.withOpacity(0.06)),
                          borderRadius: BorderRadius.circular(s(24, context)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              i == 0 ? Icons.grid_view_rounded : _iconForCategory(i - 1),
                              size: s(15, context),
                              color: isSelected
                                  ? Colors.white
                                  : Colors.deepOrange,
                            ),
                            SizedBox(width: s(6, context)),
                            Text(
                              labels[i],
                              style: TextStyle(
                                  fontSize: s(12.5, context),
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDarkMode ? Colors.white70 : Colors.black87)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          GestureDetector(
            onTap: _openFilterSheet,
            child: Container(
              margin: EdgeInsets.only(right: s(12, context)),
              padding: EdgeInsets.all(s(10, context)),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(s(14, context)),
                boxShadow: isDarkMode ? [] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(IconsaxPlusLinear.setting_4,
                      size: s(18, context), color: textColor),
                  if (_filters.isActive)
                    Positioned(
                      right: -2, top: -2,
                      child: Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                            color: Colors.deepOrange, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Filter bottom sheet: sort, price range, minimum rating
// ─────────────────────────────────────────────────────────────

class _ProductFilterSheet extends StatefulWidget {
  final ProductFilters initial;
  const _ProductFilterSheet({required this.initial});

  @override
  State<_ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<_ProductFilterSheet> {
  late ProductFilters _f = widget.initial.copy();

  String _fmtPrice(double v) {
    if (v >= ProductFilters.maxPrice) return '₦${(v ~/ 1000)}k+';
    if (v >= 1000) return '₦${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}k';
    return '₦${v.round()}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sort & Filter',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  GestureDetector(
                    onTap: () => setState(() => _f = ProductFilters()),
                    child: const Text('Reset',
                        style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text('Sort by',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const {
                  ProductSort.relevance: 'Relevance',
                  ProductSort.newest: 'Newest',
                  ProductSort.priceLowHigh: 'Price: Low to High',
                  ProductSort.priceHighLow: 'Price: High to Low',
                  ProductSort.ratingHighLow: 'Top Rated',
                }.entries.map((e) {
                  final selected = _f.sort == e.key;
                  return GestureDetector(
                    onTap: () => setState(() => _f.sort = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: selected ? Colors.deepOrange : Colors.deepOrange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        e.value,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : Colors.deepOrange),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Price Range',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                  Text(
                    '${_fmtPrice(_f.priceRange.start)} - ${_fmtPrice(_f.priceRange.end)}',
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.deepOrange),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.deepOrange,
                  inactiveTrackColor: Colors.deepOrange.withOpacity(0.15),
                  thumbColor: Colors.deepOrange,
                  overlayColor: Colors.deepOrange.withOpacity(0.15),
                  rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: RangeSlider(
                  values: _f.priceRange,
                  min: 0,
                  max: ProductFilters.maxPrice,
                  divisions: 50,
                  onChanged: (v) => setState(() => _f.priceRange = v),
                ),
              ),

              const SizedBox(height: 12),
              Text('Minimum Rating',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [0.0, 4.0, 3.0, 2.0].map((r) {
                  final selected = _f.minRating == r;
                  final label = r == 0 ? 'Any' : '$r ★ & up';
                  return GestureDetector(
                    onTap: () => setState(() => _f.minRating = r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: selected ? Colors.deepOrange : Colors.deepOrange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : Colors.deepOrange),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _f),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Apply',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}