import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Ensure these matches your project file names
import 'add_listings.dart';

class OwnerPage extends StatefulWidget {
  const OwnerPage({super.key});

  @override
  State<OwnerPage> createState() => _OwnerPageState();
}

class _OwnerPageState extends State<OwnerPage> {
  String ownerName = "Loading...";
  String ownerBio = "Welcome to my store";
  String ownerAvatar = "";
  List<Map<String, dynamic>> listings = [];

  @override
  void initState() {
    super.initState();
    _syncAndLoad();
  }

  Future<void> _syncAndLoad() async {
    await _loadOwnerProfile();
    await _loadListings();
  }

  Future<void> _loadOwnerProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      ownerName = prefs.getString('ownerName') ?? "New Merchant";
      ownerBio = prefs.getString('ownerBio') ?? "Top Seller & Curator";
      ownerAvatar = prefs.getString('ownerAvatar') ?? "";
    });
  }

  Future<void> _saveOwnerProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ownerName', ownerName);
    await prefs.setString('ownerBio', ownerBio);
    await prefs.setString('ownerAvatar', ownerAvatar);
  }

  Future<void> _loadListings() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('my_listings');
    if (saved != null) {
      final decoded = jsonDecode(saved) as List;
      setState(() {
        listings = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  // --- UI ACTIONS ---
  void _editName() {
    final controller = TextEditingController(text: ownerName);
    _showEditSheet("Edit Name", controller, (val) {
      setState(() => ownerName = val);
      _saveOwnerProfile();
    });
  }

  void _editBio() {
    final controller = TextEditingController(text: ownerBio);
    _showEditSheet("Edit Bio", controller, (val) {
      setState(() => ownerBio = val);
      _saveOwnerProfile();
    }, maxLines: 3);
  }

  Future<void> _editAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => ownerAvatar = picked.path);
      _saveOwnerProfile();
    }
  }

  void _showEditSheet(
    String title,
    TextEditingController controller,
    Function(String) onSave, {
    int maxLines = 1,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              maxLines: maxLines,
              autofocus: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  onSave(controller.text);
                  Navigator.pop(ctx);
                },
                child: const Text(
                  "Update Profile",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
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
        // BACK ARROW TO GO BACK TO CARD PAGE WITH NAV BAR INTACT
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : Colors.black,
            size: 20,
          ),
          onPressed: () {
            // Using pop ensures we return to the main navigation shell
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        title: Text(
          "Store Dashboard",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              IconsaxPlusLinear.setting_2,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _editAvatar,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: ownerAvatar.isEmpty
                                  ? null
                                  : (ownerAvatar.startsWith('assets/')
                                        ? AssetImage(ownerAvatar)
                                              as ImageProvider
                                        : FileImage(File(ownerAvatar))),
                              child: ownerAvatar.isEmpty
                                  ? const Icon(
                                      IconsaxPlusLinear.user,
                                      size: 30,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.deepOrange,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  ownerName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Icon(
                                  IconsaxPlusBold.verify,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: _editName,
                                  icon: const Icon(
                                    IconsaxPlusLinear.edit,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: _editBio,
                              child: Text(
                                ownerBio,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem("Listings", listings.length.toString()),
                      _buildStatDivider(),
                      _buildStatItem(
                        "Sold",
                        listings
                            .where((it) => it['sold'] == true)
                            .length
                            .toString(),
                      ),
                      _buildStatDivider(),
                      _buildStatItem("Rating", "5.0"),
                    ],
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddListingPage(),
                          ),
                        );
                        _loadListings(); // Sync listings when returning from creation
                      },
                      icon: const Icon(
                        IconsaxPlusLinear.add_square,
                        color: Colors.deepOrange,
                      ),
                      label: const Text(
                        "Create New Listing",
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.deepOrange),
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
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Active Listings",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "View All",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
          listings.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          IconsaxPlusLinear.shop,
                          size: 50,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "No active listings yet",
                          style: TextStyle(color: Colors.grey),
                        ),
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
                      (context, index) =>
                          _buildListingCard(listings[index], index, isDark),
                      childCount: listings.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStatDivider() =>
      Container(height: 20, width: 1, color: Colors.grey.withOpacity(0.3));

  Widget _buildListingCard(Map<String, dynamic> item, int index, bool isDark) {
    final images = List<String>.from(item['images'] ?? []);
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
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    image: images.isNotEmpty
                        ? DecorationImage(
                            image: images[0].startsWith('assets/')
                                ? AssetImage(images[0]) as ImageProvider
                                : FileImage(File(images[0])),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),
                if (item['sold'] == true)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        "SOLD",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? 'No Title',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  "₦${item['price']}",
                  style: const TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().scale(delay: (index * 50).ms);
  }
}
