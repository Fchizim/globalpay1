import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:globalpay/Market/seller_chart.dart';
import 'add_listings.dart';

class OwnerPage extends StatefulWidget {
  const OwnerPage({super.key});

  @override
  State<OwnerPage> createState() => _OwnerPageState();
}

class _OwnerPageState extends State<OwnerPage> {
  String ownerName = "Temu";
  String ownerBio = "Top Seller & Curator";
  String ownerAvatar = "assets/images/png/gold.jpg";

  List<Map<String, dynamic>> listings = [];

  @override
  void initState() {
    super.initState();
    _loadListings();
    _loadOwnerProfile();
  }

  Future<void> _loadOwnerProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      ownerName = prefs.getString('ownerName') ?? ownerName;
      ownerBio = prefs.getString('ownerBio') ?? ownerBio;
      ownerAvatar = prefs.getString('ownerAvatar') ?? ownerAvatar;
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

  Future<void> _saveListings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('my_listings', jsonEncode(listings));
  }

  void _editName() {
    final controller = TextEditingController(text: ownerName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 24
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Edit Name",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () {
                    setState(() => ownerName = controller.text);
                    _saveOwnerProfile();
                    Navigator.pop(ctx);
                  },
                  child: const Text("Save"))
            ],
          ),
        );
      },
    );
  }

  void _editBio() {
    final controller = TextEditingController(text: ownerBio);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Edit Bio",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () {
                    setState(() => ownerBio = controller.text);
                    _saveOwnerProfile();
                    Navigator.pop(ctx);
                  },
                  child: const Text("Save"))
            ],
          ),
        );
      },
    );
  }

  Future<void> _editAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => ownerAvatar = picked.path);
      _saveOwnerProfile();
    }
  }

  Future<void> _deleteListing(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing?'),
        content: const Text('Are you sure you want to delete this listing?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => listings.removeAt(index));
      _saveListings();
    }
  }

  Future<void> _createListing() async {
    final newListing = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddListingPage()),
    );
    if (newListing != null && newListing is Map<String, dynamic>) {
      newListing['sold'] = false;
      setState(() {
        listings.add(newListing);
      });
      _saveListings();
    }
  }

  void _markSold(int index) {
    setState(() {
      listings[index]['sold'] = !(listings[index]['sold'] ?? false);
    });
    _saveListings();
  }

  void _editListingBottomSheet(int index) {
    final item = Map<String, dynamic>.from(listings[index]);
    final titleCtrl = TextEditingController(text: item['title'] ?? '');
    final priceCtrl = TextEditingController(text: item['price']?.toString() ?? '');
    final descCtrl = TextEditingController(text: item['description'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Edit Listing",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price')),
              TextField(controller: descCtrl, maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    listings[index]['title'] = titleCtrl.text;
                    listings[index]['price'] = priceCtrl.text;
                    listings[index]['description'] = descCtrl.text;
                  });
                  _saveListings();
                  Navigator.pop(ctx);
                },
                child: const Text("Save"),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.white60 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Owner Page", style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                "${listings.length} listings",
                style: TextStyle(color: textColor, fontSize: 15),
              ),
            ),
          ),
          IconButton(
            icon: Icon(IconsaxPlusLinear.message, color:Colors.black),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=> MessagesPage()));
              // Open stats or chart page
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _editAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundImage: ownerAvatar.startsWith('assets/')
                            ? AssetImage(ownerAvatar) as ImageProvider
                            : FileImage(File(ownerAvatar)),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                              color: Colors.black54, shape: BoxShape.circle),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(ownerName,
                        style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w500,
                            color: textColor)),
                    const SizedBox(width: 5),
                    Icon(IconsaxPlusBold.verify, color: Colors.deepOrange),
                    IconButton(
                        onPressed: _editName,
                        icon: Icon(Icons.edit, color: Colors.blue, size: 22)),
                  ],
                ),
                GestureDetector(
                  onTap: _editBio,
                  child: Text(ownerBio,
                      style: TextStyle(fontSize: 16, color: secondaryTextColor)),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: _createListing,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 18, right: 18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 17, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add, color: Colors.white),
                          SizedBox(width: 6),
                          Text("Create listings",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                final item = listings[index];
                final images = List<String>.from(item['images'] ?? []);
                final pageController = PageController();

                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (images.isNotEmpty)
                        Stack(
                          children: [
                            SizedBox(
                              height: 140,
                              width: double.infinity,
                              child: PageView.builder(
                                controller: pageController,
                                itemCount: images.length,
                                itemBuilder: (context, i) {
                                  final imgPath = images[i];
                                  final imgWidget = imgPath.startsWith('assets/')
                                      ? Image.asset(imgPath, fit: BoxFit.cover)
                                      : Image.file(File(imgPath),
                                      fit: BoxFit.cover);
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: imgWidget,
                                  );
                                },
                              ),
                            ),
                            if (item['sold'] == true)
                              Positioned.fill(
                                child: IgnorePointer(
                                  ignoring: true,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "SOLD",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editListingBottomSheet(index),
                              ),
                            ),
                          ],
                        ),
                      if (images.isNotEmpty) const SizedBox(height: 4),
                      if (images.isNotEmpty)
                        StatefulBuilder(builder: (context, setSB) {
                          int currentPage = 0;
                          pageController.addListener(() {
                            final newPage =
                                pageController.page?.round() ?? 0;
                            if (newPage != currentPage) {
                              currentPage = newPage;
                              setSB(() {});
                            }
                          });
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(images.length, (dotIndex) {
                              final active =
                                  (pageController.page?.round() ?? 0) ==
                                      dotIndex;
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 2.0),
                                width: active ? 8 : 6,
                                height: active ? 8 : 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: active
                                      ? Colors.deepOrange
                                      : Colors.grey.shade400,
                                ),
                              );
                            }),
                          );
                        }),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['title'] ?? '',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                            Text("₦${item['price'] ?? ''}",
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                            Text(item['description'] ?? '',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: secondaryTextColor),
                                maxLines: 2),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                InkWell(
                                  onTap: () => _markSold(index),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: item['sold'] == true
                                          ? Colors.green
                                          : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item['sold'] == true
                                          ? 'Unsold'
                                          : 'Sold',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.black),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red, size: 18),
                                  onPressed: () => _deleteListing(index),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
