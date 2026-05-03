import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'chat.dart';
// Assuming you have a seller profile page, import it here
// import 'seller_profile_page.dart';

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
    // Scaling function
    double s(double value) {
      final sw = MediaQuery.of(context).size.width;
      return (sw / 375 * value).clamp(value * 0.85, value * 1.25);
    }

    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final cardColor = isDarkMode
        ? Colors.white.withOpacity(0.05)
        : Colors.grey.shade50;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(IconsaxPlusLinear.arrow_left_2, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(IconsaxPlusLinear.heart, color: textColor),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(IconsaxPlusLinear.share, color: textColor),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: s(100),
            ), // Space for bottom buttons
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- PRODUCT IMAGE ---
                Container(
                  width: double.infinity,
                  height: s(320),
                  margin: EdgeInsets.all(s(15)),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(s(25)),
                  ),
                  child: Hero(
                    tag: image, // Added Hero for smooth transition
                    child: Padding(
                      padding: EdgeInsets.all(s(20)),
                      child: Image.asset(image, fit: BoxFit.contain),
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: s(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- TITLE & PRICE ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: s(24),
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                          Text(
                            price,
                            style: TextStyle(
                              fontSize: s(22),
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: s(20)),

                      // --- SELLER PROFILE CARD ---
                      GestureDetector(
                        onTap: () {
                          // Navigate to Seller Profile
                          // Navigator.push(context, MaterialPageRoute(builder: (_) => SellerProfilePage(name: seller)));
                        },
                        child: Container(
                          padding: EdgeInsets.all(s(12)),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(s(15)),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: s(22),
                                backgroundColor: Colors.deepOrange,
                                child: Text(
                                  seller[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // Use this if you have an actual image:
                                // backgroundImage: AssetImage("assets/seller_photo.jpg"),
                              ),
                              SizedBox(width: s(12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      seller,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: s(15),
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      "Top Rated Seller • 4.9 ★",
                                      style: TextStyle(
                                        fontSize: s(12),
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                IconsaxPlusLinear.arrow_right_3,
                                size: s(18),
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: s(25)),

                      // --- DESCRIPTION ---
                      Text(
                        "Description",
                        style: TextStyle(
                          fontSize: s(16),
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: s(8)),
                      Text(
                        "This $name is of the highest quality. It features premium materials and a sleek design suitable for daily use. Limited stock available.",
                        style: TextStyle(
                          fontSize: s(14),
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),

                      SizedBox(height: s(25)),

                      // --- QUICK ACTIONS (Chat & Offer) ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _actionButton(
                            context,
                            IconsaxPlusLinear.message,
                            'Chat Seller',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ChatScreen()),
                            ),
                            s,
                          ),
                          _actionButton(
                            context,
                            IconsaxPlusLinear.coin_1,
                            'Make Offer',
                            () {},
                            s,
                          ),
                          _actionButton(
                            context,
                            IconsaxPlusLinear.info_circle,
                            'Report',
                            () {},
                            s,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- FIXED BOTTOM NAVIGATION ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: s(20), vertical: s(15)),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Container(
                      height: s(50),
                      width: s(50),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(s(15)),
                      ),
                      child: const Icon(
                        IconsaxPlusLinear.shopping_cart,
                        color: Colors.deepOrange,
                      ),
                    ),
                    SizedBox(width: s(15)),
                    Expanded(
                      child: SizedBox(
                        height: s(50),
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(s(15)),
                            ),
                          ),
                          child: const Text(
                            "Buy Now",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
    double Function(double) s,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              height: s(45),
              width: s(45),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepOrange.withOpacity(0.1),
              ),
              child: Icon(icon, size: s(22), color: Colors.deepOrange),
            ),
            SizedBox(height: s(6)),
            Text(
              label,
              style: TextStyle(fontSize: s(11), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
