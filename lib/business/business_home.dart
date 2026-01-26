import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class BusinessHome extends StatefulWidget {
  final bool isOwner;
  final String sellerName;
  final double balance;
  final int followers;
  final int following;
  final String bio;

  const BusinessHome({
    super.key,
    this.isOwner = false,
    this.sellerName = "Seller Name",
    this.balance = 0.0,
    this.followers = 0,
    this.following = 0,
    this.bio = '',
  });

  @override
  State<BusinessHome> createState() => _BusinessHomeState();
}

class _BusinessHomeState extends State<BusinessHome> {
  final List<Map<String, dynamic>> _listings = [];
  late String _sellerName;
  late String _bio;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _sellerName = widget.sellerName;
    _bio = widget.bio;

    // Example pre-filled listings
    _listings.addAll([
      {'title': 'Red Shoes', 'desc': 'Comfortable running shoes', 'price': 5000.0},
      {'title': 'Leather Bag', 'desc': 'Stylish leather bag', 'price': 7500.0},
      {'title': 'Smart Watch', 'desc': 'Track your fitness', 'price': 12000.0},
      {'title': 'Headphones', 'desc': 'Noise cancelling', 'price': 8500.0},
    ]);
  }

  // Edit name
  void _editName() {
    final controller = TextEditingController(text: _sellerName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Seller Name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () {
                setState(() => _sellerName = controller.text);
                Navigator.pop(context);
              },
              child: const Text("Save"))
        ],
      ),
    );
  }

  // Edit bio
  void _editBio() {
    final controller = TextEditingController(text: _bio);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Bio"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Bio"),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () {
                setState(() => _bio = controller.text);
                Navigator.pop(context);
              },
              child: const Text("Save"))
        ],
      ),
    );
  }

  // Pick profile image
  Future<void> _editProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  // Post listing
  void _openPostListingModal() {
    final _titleController = TextEditingController();
    final _descController = TextEditingController();
    final _priceController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Post a Listing',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Product Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Product Description', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder(), prefixText: '₦'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_titleController.text.isEmpty ||
                        _descController.text.isEmpty ||
                        _priceController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                      return;
                    }
                    setState(() {
                      _listings.add({
                        'title': _titleController.text,
                        'desc': _descController.text,
                        'price': double.tryParse(_priceController.text) ?? 0.0,
                      });
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Post Listing'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        elevation: 0,
        title: Text(_sellerName, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Row(
              children: [
                GestureDetector(
                  onTap: widget.isOwner ? _editProfileImage : null,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: colorScheme.primary.withOpacity(0.3),
                    backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                    child: _profileImage == null
                        ? Icon(IconsaxPlusBold.user, size: 40, color: colorScheme.primary)
                        : null,
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(_sellerName, style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                        if (widget.isOwner)
                          IconButton(
                              icon: Icon(IconsaxPlusLinear.edit, size: 20, color: colorScheme.primary),
                              onPressed: _editName),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(IconsaxPlusBold.verify, color: Colors.blue, size: 20),
                        const SizedBox(width: 5),
                        Text('Verified Seller', style: textTheme.bodyMedium?.copyWith(color: Colors.blue)),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.bar_chart, color: colorScheme.primary),
                  onPressed: () {
                    // stats / messages
                  },
                ),
              ],
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
            const SizedBox(height: 20),

            // Bio
            Row(
              children: [
                Text('Bio', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (widget.isOwner)
                  IconButton(icon: Icon(IconsaxPlusLinear.edit, size: 20, color: colorScheme.primary), onPressed: _editBio),
              ],
            ),
            const SizedBox(height: 5),
            Text(_bio.isEmpty ? 'No bio yet' : _bio, style: textTheme.bodyMedium),
            const SizedBox(height: 20),

            // Wallet + Withdraw
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _walletCard(colorScheme, 'Balance', widget.balance),
                ElevatedButton(onPressed: () {}, child: const Text('Withdraw')),
              ],
            ),
            const SizedBox(height: 20),

            // Followers / Following
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('${widget.followers}', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const Text('Followers'),
                  ],
                ),
                Column(
                  children: [
                    Text('${widget.following}', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const Text('Following'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Post Listing Button
            if (widget.isOwner)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openPostListingModal,
                  icon: Icon(IconsaxPlusLinear.add_square),
                  label: const Text('Post Listing'),
                ),
              ),
            const SizedBox(height: 20),

            // Listings Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: _listings.length,
              itemBuilder: (context, index) {
                final listing = _listings[index];
                return _listingCard(listing['title'], listing['desc'], listing['price']);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _walletCard(ColorScheme colorScheme, String title, double amount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('₦${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _listingCard(String title, String desc, double price) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(desc, maxLines: 3, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Text('₦${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
