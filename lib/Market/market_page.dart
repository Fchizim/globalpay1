import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:globalpay/Market/seller_chart.dart';
import 'chat.dart';
import 'editors_profile.dart';

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

  // Responsive scale function
  double s(double value, BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return (sw / 375 * value).clamp(value * 0.85, value * 1.25);
  }

  Widget buildGrid(List<Map> items, bool isDarkMode, BuildContext context) {
    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: s(4, context), vertical: s(8, context)),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: s(8, context),
        crossAxisSpacing: s(8, context),
        childAspectRatio: 0.73,
      ),
      itemBuilder: (context, index) {
        return ProductCard(items[index], isDarkMode: isDarkMode, context: context);
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
                radius: s(18, context),
                backgroundImage: const AssetImage('assets/images/png/temu.jpeg'),
                backgroundColor: Colors.deepOrange.shade100,
              ),
            ),
            SizedBox(width: s(10, context)),
            Text(
              'Marketplace',
              style: TextStyle(
                fontSize: s(24, context),
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        actions: [
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
            height: _isTabVisible ? s(56, context) : 0,
            curve: Curves.easeInOut,
            child: _isTabVisible
                ? Container(
              margin: EdgeInsets.symmetric(horizontal: s(12, context), vertical: s(6, context)),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white10
                    : Colors.deepOrange.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(s(30, context)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(s(25, context)),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.black54,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
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
                buildGrid(products, isDarkMode, context),
                buildGrid(products, isDarkMode, context),
                buildGrid(products, isDarkMode, context),
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
  final BuildContext context;
  const ProductCard(this.p, {super.key, this.isDarkMode = false, required this.context});

  double s(double value) {
    final sw = MediaQuery.of(context).size.width;
    return (sw / 375 * value).clamp(value * 0.85, value * 1.25);
  }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(s(12))),
        elevation: 3,
        color: cardColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(s(12))),
                child: Image.asset(p['image'], fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(s(6)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['name'],
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontSize: s(14))),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p['price'],
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: s(14))),
                      IconButton(
                        icon: Icon(IconsaxPlusLinear.add_circle, size: s(22)),
                        color: Colors.deepOrange,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  Text(p['seller'],
                      style: TextStyle(color: Colors.grey.shade400, fontSize: s(12))),
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
    double s(double value) {
      final sw = MediaQuery.of(context).size.width;
      return (sw / 375 * value).clamp(value * 0.85, value * 1.25);
    }

    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.grey.shade100;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(name, style: TextStyle(color: textColor, fontSize: s(20))),
        backgroundColor: bgColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: s(15)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: s(350),
                padding: EdgeInsets.all(s(16)),
                child: Image.asset(image, fit: BoxFit.contain),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: TextStyle(
                              fontSize: s(22),
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                      Text(price,
                          style: TextStyle(
                              fontSize: s(20),
                              color: Colors.green,
                              fontWeight: FontWeight.w600)),
                      Text("Sold by: $seller",
                          style: TextStyle(fontSize: s(16), color: textColor)),
                    ],
                  ),
                  Row(
                    children: [
                      _actionButton(context, IconsaxPlusLinear.message, 'Message', () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => ChatScreen()));
                      }, s),
                      SizedBox(width: s(20)),
                      _actionButton(context, IconsaxPlusLinear.coin_1, 'Send offer', () {}, s),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton(
      BuildContext context, IconData icon, String label, VoidCallback onTap, double Function(double) s) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
              height: s(40),
              width: s(40),
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: Colors.blue.shade100),
              child: Icon(icon, size: s(22))),
          SizedBox(height: s(4)),
          Text(label, style: TextStyle(fontSize: s(12))),
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
