import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:globalpay/Market/business_page.dart';
import 'package:globalpay/Market/seller_chart.dart'; // Ensure correct casing

// Custom File Imports
import 'product_card.dart';
import 'product_data.dart';

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

  final products = List.generate(
    10,
    (i) => {
      "image": productImages[i % productImages.length],
      "name": "Premium Item $i",
      "price": "₦${(i + 1) * 5000}",
      "seller": "Gold Store $i",
    },
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_scrollListener);

    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isTabVisible) setState(() => _isTabVisible = false);
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isTabVisible) setState(() => _isTabVisible = true);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rotationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  double s(double value, BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return (sw / 375 * value).clamp(value * 0.85, value * 1.25);
  }

  Widget buildGrid(List<Map> items, bool isDarkMode, BuildContext context) {
    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        s(12, context),
        s(8, context),
        s(12, context),
        s(80, context),
      ),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: s(15, context),
        crossAxisSpacing: s(15, context),
        childAspectRatio: 0.68,
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
        : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: bgColor,
        elevation: 0,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BusinessPage()),
                );
              },
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Container(
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
                          _rotationController.value * 2 * 3.14159,
                        ),
                      ),
                    ),
                    child: child,
                  );
                },
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
                      Icon(
                        Icons.storefront,
                        color: Colors.deepOrange[500],
                        size: s(18, context),
                      ),
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
          IconButton(
            icon: Icon(
              IconsaxPlusLinear.shopping_bag,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MessagesPage()),
              );
            },
          ),

          IconButton(
            icon: Icon(
              IconsaxPlusLinear.message,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MessagesPage()),
              );
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
                    margin: EdgeInsets.symmetric(
                      horizontal: s(12, context),
                      vertical: s(6, context),
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white10
                          : Colors.deepOrange.shade50.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(s(30, context)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize
                          .tab, // Makes the pill full width of the tab
                      dividerColor:
                          Colors.transparent, // REMOVES THE BLACK LINE
                      indicator: BoxDecoration(
                        color: Colors.deepOrange,
                        borderRadius: BorderRadius.circular(s(25, context)),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: isDarkMode
                          ? Colors.white70
                          : Colors.black54,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: s(13, context),
                      ),
                      tabs: const [
                        Tab(text: 'Versatile'),
                        Tab(text: 'Clothing'),
                        Tab(text: 'Food'),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
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
