import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:globalpay/Market/store_settings.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  Future<void> _fetchBusinessThenListings() async {
    await _fetchBusiness();
    await _loadListings();
  }

  Future<void> _fetchBusiness() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    setState(() { _isLoading = true; _error = null; });

    try {
      final res = await http.post(
        Uri.parse('https://glopa.org/glo/get_business_profile.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': user.userId}),
      );

      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        setState(() { _business = data['data']; _isLoading = false; });
      } else {
        setState(() { _error = data['message']; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Network error. Pull to refresh.'; _isLoading = false; });
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
        title: Text('Store Dashboard',
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold, fontSize: 18)),
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
            icon: Icon(IconsaxPlusLinear.setting_2,
                color: isDark ? Colors.white : Colors.black),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchBusiness,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange),
            child: const Text('Retry',
                style: TextStyle(color: Colors.white)),
          ),
        ]),
      )
          : RefreshIndicator(
        onRefresh: _fetchBusinessThenListings,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [

                  // ── Profile row ───────────────────────────────
                  Row(children: [
                    // ── Avatar ──────────────────────────────────
                    Stack(children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _business?['Business_img'] != null
                            ? NetworkImage(_business!['Business_img'])
                            : null,
                        child: _business?['Business_img'] == null
                            ? const Icon(Icons.store,
                            size: 30, color: Colors.grey)
                            : null,
                      ),
                      // Positioned(
                      //   bottom: 0, right: 0,
                      //   child: Container(
                      //     padding: const EdgeInsets.all(4),
                      //     decoration: const BoxDecoration(
                      //         color: Colors.deepOrange,
                      //         shape: BoxShape.circle),
                      //     child: const Icon(Icons.camera_alt,
                      //         color: Colors.white, size: 12),
                      //   ),
                      // ),
                    ]),
                    const SizedBox(width: 15),

                    // ── Info ─────────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Flexible(
                              child: Text(
                                _business?['business_name'] ?? '',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(IconsaxPlusBold.verify,
                                color: Colors.blue, size: 16),
                          ]),
                          const SizedBox(height: 4),
                          Text(
                            _business?['business_type'] ?? '',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13),
                          ),
                          Text(
                            _business?['business_location'] ?? '',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // ── Business details strip ────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white10
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(children: [
                      _detailRow(Icons.email_outlined,
                          _business?['business_email'] ?? ''),
                      const SizedBox(height: 8),
                      _detailRow(Icons.phone_outlined,
                          _business?['business_phone'] ?? ''),
                      const SizedBox(height: 8),
                      _detailRow(Icons.badge_outlined,
                          'RC: ${_business?['rc_number'] ?? ''}'),
                      const SizedBox(height: 8),
                      _detailRow(Icons.badge_outlined,
                          'Bio: ${_business?['business_bio'] ?? ''}'),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // ── Stats ─────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Listings', listings.length.toString()),
                      _buildStatDivider(),
                      _buildStatItem('Sold',
                          listings.where((i) => i['sold'] == true)
                              .length.toString()),
                      _buildStatDivider(),
                      _buildStatItem('Rating', '5.0'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Add listing button ────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => AddListingPage(
                                  businessId: _business?['business_id'] ?? '',
                                )));
                        _loadListings();
                      },
                      icon: const Icon(
                          IconsaxPlusLinear.add_square,
                          color: Colors.deepOrange),
                      label: const Text('Create New Listing',
                          style: TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Colors.deepOrange),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ]),
              ),
            ),

            // ── Listings header ───────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Active Listings',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {},
                      child: const Text('View All',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            ),

            // ── Listings grid ─────────────────────────────────────
            listings.isEmpty
                ? SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(IconsaxPlusLinear.shop,
                        size: 50,
                        color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    const Text('No active listings yet',
                        style:
                        TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
                : SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverGrid(
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildListingCard(
                      listings[i], i, isDark),
                  childCount: listings.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String value) => Row(children: [
    Icon(icon, size: 15, color: Colors.grey),
    const SizedBox(width: 8),
    Flexible(
      child: Text(value,
          style: const TextStyle(fontSize: 13),
          overflow: TextOverflow.ellipsis),
    ),
  ]);

  Widget _buildStatItem(String label, String value) => Column(children: [
    Text(value,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold)),
    Text(label,
        style: const TextStyle(fontSize: 12, color: Colors.grey)),
  ]);

  Widget _buildStatDivider() => Container(
      height: 20, width: 1, color: Colors.grey.withOpacity(0.3));

  Widget _buildListingCard(Map<String, dynamic> item, int index, bool isDark) {
    final images = List<String>.from(item['images'] ?? []);
    final isSold = item['prod_status'] == 'out_of_stock';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 3,
          child: Stack(children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                image: images.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(images[0]), // ← NetworkImage now
                  fit: BoxFit.cover,
                )
                    : null,
              ),
            ),
            if (isSold)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text('OUT OF STOCK',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
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
                      builder: (_) => EditListingPage(
                        product: item,
                      ),
                    ),
                  );
                  _loadListings(); // refresh in case it changed
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.deepOrange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 14),
                ),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['name'] ?? 'No Title',      // ← 'name' not 'title'
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('₦${item['price']}',
                style: const TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ]),
        ),
      ]),
    ).animate().scale(delay: (index * 50).ms);
  }
}