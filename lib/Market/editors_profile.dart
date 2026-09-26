import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:globalpay/Market/store_settings.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../home/vendor_sales_analytics_page.dart';
import '../provider/user_provider.dart';
import 'add_listings.dart';
import 'edit_listing_page.dart';

class OwnerPage extends StatefulWidget {
  const OwnerPage({super.key});

  @override
  State<OwnerPage> createState() => _OwnerPageState();
}

class _OwnerPageState extends State<OwnerPage> {
  Map<String, dynamic>? _business;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> listings = [];

  @override
  void initState() {
    super.initState();
    _fetchBusinessThenListings(); // single entry point
  }

  String _formatAmount(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '') ?? 0;
    return amount.toStringAsFixed(2);
  }

  Future<void> _fetchBusinessThenListings() async {
    await _fetchBusiness();
    await _loadListings();
  }

  Future<void> _fetchBusiness() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await http.post(
        Uri.parse('https://glopa.org/glo/get_business_profile.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': user.userId}),
      );

      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        setState(() {
          _business = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = data['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error. Pull to refresh.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadListings() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    // Wait for business data if not yet loaded
    final businessId = _business?['business_id'] ?? '';
    if (businessId.isEmpty) return;

    try {
      final res = await http.get(
        Uri.parse(
          'https://glopa.org/glo/get_user_products.php?user_id=${user.userId}',
        ),
        headers: {'Accept': 'application/json'},
      );

      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        setState(() {
          listings = List<Map<String, dynamic>>.from(data['products']);
        });
      }
    } catch (e) {
      debugPrint('Listings fetch error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // RESPONSIVE HELPERS
  // Everything below scales off the current screen width instead
  // of using fixed pixel numbers, so layout holds up on small
  // phones, big phones, and tablets alike.
  // ─────────────────────────────────────────────────────────────

  /// Scales a base size (designed for a ~390px-wide phone) up or down
  /// depending on the device's actual width, clamped so it never gets
  /// absurdly small or large.
  double _scale(
    BuildContext context,
    double base, {
    double min = 0.85,
    double max = 1.6,
  }) {
    final width = MediaQuery.of(context).size.width;
    final factor = (width / 390.0).clamp(min, max);
    return base * factor;
  }

  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 700;

  int _gridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1000) return 4;
    if (width >= 700) return 3;
    return 2;
  }

  double _gridAspectRatio(BuildContext context) {
    // Tablets get a bit taller/shorter cards so text never gets squeezed.
    return _isTablet(context) ? 0.82 : 0.72;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final horizontalPadding = _scale(context, 20);
    final maxContentWidth = _isTablet(context) ? 720.0 : double.infinity;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
        title: Text(
          'Store Dashboard',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: _scale(context, 18),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              if (_business == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoreSettingsPage(business: _business!),
                ),
              ).then((updated) {
                if (updated == true) _fetchBusinessThenListings();
              });
            },
            icon: Icon(
              IconsaxPlusLinear.setting_2,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const VendorSalesAnalyticsPage(),
              ),
            ),
            icon: Icon(
              IconsaxPlusLinear.chart_2,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _fetchBusiness,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchBusinessThenListings,
              child: Center(
                // Caps the width on tablets so content doesn't stretch edge to
                // edge into an ugly, over-wide layout.
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(horizontalPadding),
                          child: Column(
                            children: [
                              // ── Profile row ───────────────────────────────
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Avatar ──────────────────────────────────
                                  CircleAvatar(
                                    radius: _scale(context, 40),
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage:
                                        _business?['Business_img'] != null
                                        ? NetworkImage(
                                            _business!['Business_img'],
                                          )
                                        : null,
                                    child: _business?['Business_img'] == null
                                        ? Icon(
                                            Icons.store,
                                            size: _scale(context, 30),
                                            color: Colors.grey,
                                          )
                                        : null,
                                  ),
                                  SizedBox(width: _scale(context, 15)),

                                  // ── Info ─────────────────────────────────────
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                _business?['business_name'] ??
                                                    '',
                                                style: TextStyle(
                                                  fontSize: _scale(context, 18),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            const Icon(
                                              IconsaxPlusBold.verify,
                                              color: Colors.blue,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _business?['business_type'] ?? '',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: _scale(context, 13),
                                          ),
                                        ),
                                        Text(
                                          _business?['business_location'] ?? '',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: _scale(context, 12),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: _scale(context, 16)),

                              // ── Business details strip ────────────────────
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(_scale(context, 14)),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  children: [
                                    _detailRow(
                                      context,
                                      Icons.email_outlined,
                                      _business?['business_email'] ?? '',
                                    ),
                                    const SizedBox(height: 8),
                                    _detailRow(
                                      context,
                                      Icons.phone_outlined,
                                      _business?['business_phone'] ?? '',
                                    ),
                                    const SizedBox(height: 8),
                                    _detailRow(
                                      context,
                                      Icons.badge_outlined,
                                      'RC: ${_business?['rc_number'] ?? ''}',
                                    ),
                                    const SizedBox(height: 8),
                                    // Bio can be long free text, so let it wrap
                                    // onto multiple lines instead of forcing a
                                    // single-line ellipsis that hides content.
                                    _detailRow(
                                      context,
                                      Icons.badge_outlined,
                                      'Bio: ${_business?['business_bio'] ?? ''}',
                                      maxLines: 3,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: _scale(context, 20)),

                              // ── Pending payout (escrow) balance ───────────
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(_scale(context, 16)),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.deepOrange.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                        _scale(context, 10),
                                      ),
                                      decoration: const BoxDecoration(
                                        color: Colors.deepOrange,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        IconsaxPlusBold.wallet_2,
                                        color: Colors.white,
                                        size: _scale(context, 18),
                                      ),
                                    ),
                                    SizedBox(width: _scale(context, 12)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Pending Payout',
                                            style: TextStyle(
                                              fontSize: _scale(context, 12),
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '₦${_formatAmount(_business?['wait_wallet'])}',
                                            style: TextStyle(
                                              fontSize: _scale(context, 18),
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: _scale(context, 16)),

                              // ── Stats ─────────────────────────────────────
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                    context,
                                    'Listings',
                                    listings.length.toString(),
                                  ),
                                  _buildStatDivider(),
                                  _buildStatItem(
                                    context,
                                    'Sold',
                                    listings
                                        .where((i) => i['sold'] == true)
                                        .length
                                        .toString(),
                                  ),
                                  _buildStatDivider(),
                                  _buildStatItem(context, 'Rating', '5.0'),
                                ],
                              ),
                              SizedBox(height: _scale(context, 20)),

                              // ── Add listing button ────────────────────────
                              SizedBox(
                                width: double.infinity,
                                height: _scale(
                                  context,
                                  50,
                                  min: 0.9,
                                  max: 1.25,
                                ),
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddListingPage(
                                          businessId:
                                              _business?['business_id'] ?? '',
                                        ),
                                      ),
                                    );
                                    _loadListings();
                                  },
                                  icon: const Icon(
                                    IconsaxPlusLinear.add_square,
                                    color: Colors.deepOrange,
                                  ),
                                  label: Text(
                                    'Create New Listing',
                                    style: TextStyle(
                                      fontSize: _scale(
                                        context,
                                        14,
                                        min: 0.9,
                                        max: 1.2,
                                      ),
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.deepOrange,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Listings header ───────────────────────────────────
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Active Listings',
                                style: TextStyle(
                                  fontSize: _scale(context, 16),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text(
                                  'View All',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Listings grid ─────────────────────────────────────
                      listings.isEmpty
                          ? SliverFillRemaining(
                              hasScrollBody: false,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: _scale(context, 40),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        IconsaxPlusLinear.shop,
                                        size: _scale(context, 50),
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'No active listings yet',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding: EdgeInsets.all(horizontalPadding),
                              sliver: SliverGrid(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: _gridColumns(context),
                                      mainAxisSpacing: _scale(context, 15),
                                      crossAxisSpacing: _scale(context, 15),
                                      childAspectRatio: _gridAspectRatio(
                                        context,
                                      ),
                                    ),
                                delegate: SliverChildBuilderDelegate(
                                  (_, i) => _buildListingCard(
                                    context,
                                    listings[i],
                                    i,
                                    isDark,
                                  ),
                                  childCount: listings.length,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    IconData icon,
    String value, {
    int maxLines = 1,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: _scale(context, 15), color: Colors.grey),
      SizedBox(width: _scale(context, 8)),
      Expanded(
        child: Text(
          value,
          style: TextStyle(fontSize: _scale(context, 13)),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  Widget _buildStatItem(BuildContext context, String label, String value) =>
      Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: _scale(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: _scale(context, 12), color: Colors.grey),
          ),
        ],
      );

  Widget _buildStatDivider() =>
      Container(height: 20, width: 1, color: Colors.grey.withOpacity(0.3));

  Widget _buildListingCard(
    BuildContext context,
    Map<String, dynamic> item,
    int index,
    bool isDark,
  ) {
    final images = List<String>.from(item['images'] ?? []);
    final isSold = item['prod_status'] == 'out_of_stock';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      color: Colors.grey.shade200,
                      image: images.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(images[0]),
                              fit: BoxFit.cover,
                              onError: (_, __) {},
                            )
                          : null,
                    ),
                  ),
                ),
                if (isSold)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'OUT OF STOCK',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: _scale(context, 12),
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                // ── Edit pencil badge ──
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditListingPage(product: item),
                        ),
                      );
                      _loadListings(); // refresh in case it changed
                    },
                    child: Container(
                      padding: EdgeInsets.all(_scale(context, 6)),
                      decoration: const BoxDecoration(
                        color: Colors.deepOrange,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: _scale(context, 14),
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
              padding: EdgeInsets.all(_scale(context, 12)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? 'No Title',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: _scale(context, 13),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: _scale(context, 4)),
                  Text(
                    '₦${item['price']}',
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: _scale(context, 14),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().scale(delay: (index * 50).ms);
  }
}
