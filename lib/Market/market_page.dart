import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:globalpay/Market/seller_chart.dart';
import 'package:globalpay/Market/vendort_orders.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:globalpay/Market/business_page.dart';
import 'checkout.dart';
import 'editors_profile.dart';
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
    this.vendorName,
    this.vendorLocation,
    this.vendorRating,
    this.rating,
    this.featured,
  });

  factory MarketProduct.fromJson(Map<String, dynamic> j) => MarketProduct(
    productId:     j['product_id'].toString(),
    name:          j['name'].toString(),
    productImage:  j['product_image']?.toString() ?? '',
    productImages: (j['product_images'] as List?)
        ?.map((e) => e.toString())
        .toList() ??
        [j['product_image']?.toString() ?? ''],
    productAmount:   j['product_amount']?.toString() ?? '0.00',
    description:     j['description']?.toString(),
    categoryName:    j['category_name']?.toString(),
    catId:           j['cat_id']?.toString(),
    vendorName:      j['vendor_name']?.toString(),
    vendorLocation:  j['vendor_location']?.toString(),
    vendorRating:    j['vendor_rating']?.toString(),
    rating:          j['rating']?.toString(),
    featured:        j['featured']?.toString(),
  );

  Map<String, dynamic> toDisplayMap() => {
    'image':  productImage,
    'name':   name,
    'price':  '₦$productAmount',
    'seller': vendorName ?? 'Seller',
  };
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
  // Tab / scroll state
  late TabController _tabController;
  late AnimationController _rotationController;
  final ScrollController _scrollController = ScrollController();
  bool _isTabVisible = true;

  // Category data
  List<MarketCategory> _categories = [];
  bool _categoriesLoaded = false;

  // Per-tab pagination state
  // Index 0 = "All", index 1+ = category tabs
  final List<List<MarketProduct>> _tabProducts  = [];
  final List<int>  _currentPage  = [];
  final List<bool> _isLoading    = [];
  final List<bool> _hasMore      = [];

  static const String _baseUrl = 'https://glopa.org/glo/get_all_product.php';
  static const int _pageSize   = 20;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Temporary 1-tab controller until categories load
    _tabController = TabController(length: 1, vsync: this);

    _scrollController.addListener(_onScroll);
    _fetchInitial();
  }

  // ── Helpers ──────────────────────────────────────────────

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
    if (tabIndex == 0) return '';                          // "All"
    return _categories[tabIndex - 1].catId;               // real category
  }

  // ── Networking ───────────────────────────────────────────

  Future<void> _fetchInitial() async {
    // Page 1 of "All" — also returns categories list
    final result = await _fetchPage(catId: '', page: 1);
    if (!mounted || result == null) return;

    final cats = (result['categories'] as List? ?? [])
        .map((c) => MarketCategory.fromJson(c))
        .toList();

    final products = (result['products'] as List? ?? [])
        .map((p) => MarketProduct.fromJson(p))
        .toList();

    final hasMore = result['has_more'] as bool? ?? false;
    final tabCount = 1 + cats.length; // "All" + each category

    setState(() {
      _categories        = cats;
      _categoriesLoaded  = true;
      _tabController.dispose();
      _tabController = TabController(
        length: tabCount,
        vsync: this,
      )..addListener(_onTabChanged);

      _initTabState(tabCount);

      // Seed "All" tab (index 0) with page-1 results
      _tabProducts[0]  = products;
      _currentPage[0]  = 1;
      _hasMore[0]      = hasMore;
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
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
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

  // ── Listeners ────────────────────────────────────────────

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

    // Trigger next page when near bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      final tab = _tabController.index;
      if (!_isLoading[tab] && _hasMore[tab]) {
        _loadMore(tab);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rotationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Grid ─────────────────────────────────────────────────

  Widget _buildGrid(int tabIndex, bool isDarkMode) {
    final items      = _tabProducts.length > tabIndex ? _tabProducts[tabIndex] : <MarketProduct>[];
    final loading    = _isLoading.length > tabIndex && _isLoading[tabIndex];
    final more       = _hasMore.length > tabIndex && _hasMore[tabIndex];

    if (items.isEmpty && loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.deepOrange),
      );
    }

    if (items.isEmpty && !loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_outlined,
                size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No products yet',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return Builder(
      builder: (context) => GridView.builder(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(
          s(12, context), s(8, context), s(12, context), s(80, context),
        ),
        itemCount: items.length + (more ? 1 : 0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:    2,
          mainAxisSpacing:   s(15, context),
          crossAxisSpacing:  s(15, context),
          childAspectRatio:  0.68,
        ),
        itemBuilder: (ctx, index) {
          if (index >= items.length) {
            // Footer loader
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Colors.deepOrange),
              ),
            );
          }
          return ProductCard(
            items[index],
            isDarkMode: isDarkMode,
          );
        },
      ),
    );
  }

  // ── Sell button logic (unchanged) ───────────────────────

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
      final checkRes = await http.get(Uri.parse(
          'https://glopa.org/glo/check_subscription.php?user_id=${user.userId}'));
      final checkData = jsonDecode(checkRes.body);

      if (!mounted) return;

      if (checkData['status'] != 'success' || checkData['active'] != true) {
        Navigator.pop(context);
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const BusinessPage()));
        return;
      }

      final profileRes = await http.post(
        Uri.parse('https://glopa.org/glo/get_business_profile.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': user.userId}),
      );
      final profileData = jsonDecode(profileRes.body);

      if (!mounted) return;
      Navigator.pop(context);

      if (profileData['status'] == 'success') {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const OwnerPage()));
      } else {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const StoreSetupPage()));
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
    final bgColor =
    isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA);

    final tabLabels = [
      'All',
      ..._categories.map((c) => c.name),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: bgColor,
        elevation: 0,
        title: Row(
          children: [
            // ── SELL button ──────────────────────────────
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
                        Colors.deepOrange,
                        Colors.yellow,
                        Colors.pink,
                        Colors.deepPurple,
                        Colors.blue,
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
                    horizontal: s(14, context),
                    vertical: s(6, context),
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(s(20, context)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.storefront,
                          color: Colors.deepOrange[500], size: s(18, context)),
                      SizedBox(width: s(6, context)),
                      Text(
                        'SELL',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: s(13, context),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: s(12, context)),
            Text(
              'GlobalBiz',
              style: TextStyle(
                fontSize: s(22, context),
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          // ── Cart icon with badge ──
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(IconsaxPlusLinear.shopping_bag,
                    color: isDarkMode ? Colors.white : Colors.black),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: CartService.getCart(
                      context.read<UserProvider>().user?.userId ?? ''),
                  builder: (context, snapshot) {
                    final count = (snapshot.data?['count'] as num?)?.toInt() ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.deepOrange,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(IconsaxPlusLinear.message,
                color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => MessagesPage())),
          ),
          IconButton(
            icon: Icon(IconsaxPlusLinear.shopping_cart,
                color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => VendorOrdersScreen())),
          ),
        ],
      ),
      body: !_categoriesLoaded
          ? const Center(
          child: CircularProgressIndicator(color: Colors.deepOrange))
          : Column(
        children: [
          // ── Animated category tab bar ──────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isTabVisible ? s(56, context) : 0,
            curve: Curves.easeInOut,
            child: _isTabVisible
                ? Container(
              margin: EdgeInsets.symmetric(
                horizontal: s(12, context),
                vertical:   s(6, context),
              ),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white10
                    : Colors.deepOrange.shade50.withOpacity(0.5),
                borderRadius:
                BorderRadius.circular(s(30, context)),
              ),
              child: TabBar(
                controller:    _tabController,
                isScrollable:  true,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor:  Colors.transparent,
                indicator: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius:
                  BorderRadius.circular(s(25, context)),
                ),
                labelColor:         Colors.white,
                unselectedLabelColor:
                isDarkMode ? Colors.white70 : Colors.black54,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize:   s(13, context),
                ),
                tabAlignment: TabAlignment.start,
                tabs: tabLabels
                    .map((l) => Tab(text: l))
                    .toList(),
              ),
            )
                : const SizedBox.shrink(),
          ),

          // ── Product grids ──────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(
                tabLabels.length,
                    (i) => _buildGrid(i, isDarkMode),
              ),
            ),
          ),
        ],
      ),
    );
  }
}