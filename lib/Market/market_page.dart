import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:globalpay/Market/seller_chart.dart';
import 'chat.dart';
import 'editors_profile.dart';
import 'package:globalpay/Market/users_pages.dart';

class CardPage extends StatefulWidget {
  const CardPage({super.key});

  @override
  State<CardPage> createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isTabVisible = true;

  final products = List.generate(
    10,
        (i) => {
      "image": productImages[i % productImages.length],
      "name": "Product $i",
      "price": "₦${(i + 1) * 5000}",
      "seller": "Seller $i",
    },
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isTabVisible) setState(() => _isTabVisible = false);
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isTabVisible) setState(() => _isTabVisible = true);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget buildGrid(List<Map> items, bool isDarkMode) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.73,
      ),
      itemBuilder: (context, index) {
        return ProductCard(items[index], isDarkMode: isDarkMode);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode
        ? const Color(0xFF121212)
        : Colors.deepOrange.shade50.withOpacity(0.2);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => OwnerPage()));
              },
              child: CircleAvatar(
                radius: 18,
                backgroundImage: const AssetImage('assets/images/png/temu.jpeg'),
                backgroundColor: Colors.deepOrange.shade100,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Marketplace',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          // Small cart icon
          IconButton(
            icon: Icon(IconsaxPlusLinear.shopping_cart,
                color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const CartPage()));
            },
          ),
          IconButton(
            icon: Icon(IconsaxPlusLinear.message,
                color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => MessagesPage()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isTabVisible ? 56 : 0,
            curve: Curves.easeInOut,
            child: _isTabVisible
                ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white10
                    : Colors.deepOrange.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(25),
                ),
                labelColor: Colors.white,
                unselectedLabelColor:
                isDarkMode ? Colors.white70 : Colors.black54,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Versatile'),
                  Tab(text: 'Clothing'),
                  Tab(text: 'Food'),
                ],
              ),
            )
                : null,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildGrid(products, isDarkMode),
                buildGrid(products, isDarkMode),
                buildGrid(products, isDarkMode),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Map p;
  final bool isDarkMode;
  const ProductCard(this.p, {super.key, this.isDarkMode = false});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(
              image: p['image'],
              name: p['name'],
              price: p['price'],
              seller: p['seller'],
              isDarkMode: isDarkMode,
            ),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        color: cardColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.asset(p['image'], fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['name'],
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: textColor)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p['price'],
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600)),
                      IconButton(
                        icon: const Icon(IconsaxPlusLinear.add_circle),
                        color: Colors.deepOrange,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  Text(p['seller'],
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final productImages = [
  "assets/images/png/airpods.jpeg",
  "assets/images/png/lamp.jpeg",
  "assets/images/png/reality.jpeg",
  "assets/images/png/headset.jpeg",
  "assets/images/png/ps5.png",
  "assets/images/png/jacket.jpeg",
  "assets/images/png/headphones.jpeg",
];

class ProductDetailsPage extends StatelessWidget {
  final String image;
  final String name;
  final String price;
  final String seller;
  final bool isDarkMode;

  const ProductDetailsPage({
    super.key,
    required this.image,
    required this.name,
    required this.price,
    required this.seller,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.grey.shade100;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(name, style: TextStyle(color: textColor)),
        backgroundColor: bgColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 350,
              padding: const EdgeInsets.all(16.0),
              child: Image.asset(image, fit: BoxFit.contain),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                      Text(price,
                          style: const TextStyle(
                              fontSize: 20,
                              color: Colors.green,
                              fontWeight: FontWeight.w600)),
                      Text("Sold by: $seller",
                          style: TextStyle(fontSize: 16, color: textColor)),
                    ],
                  ),
                  Row(
                    children: [
                      _actionButton(context, IconsaxPlusLinear.message, 'Message', () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => ChatScreen()));
                      }),
                      const SizedBox(width: 20),
                      _actionButton(context, IconsaxPlusLinear.coin_1, 'Send offer', () {}),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: Colors.blue.shade100),
              child: Icon(icon)),
          Text(label),
        ],
      ),
    );
  }
}

// Dummy cart page
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: Colors.deepOrange,
      ),
      body: const Center(
        child: Text('No items in your cart yet!'),
      ),
    );
  }
}
