import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class GiftCardPage extends StatefulWidget {
  const GiftCardPage({super.key});

  @override
  State<GiftCardPage> createState() => _GiftCardPageState();
}

class _GiftCardPageState extends State<GiftCardPage> {
  double selectedAmount = 50;

  final List<Map<String, dynamic>> giftCards = [
    {"name": "Amazon", "image": "assets/images/amazon.png", "color": Colors.deepPurple},
    {"name": "Apple", "image": "assets/images/apple.png", "color": Colors.black},
    {"name": "Netflix", "image": "assets/images/netflix.png", "color": Colors.redAccent},
    {"name": "Google Play", "image": "assets/images/google.png", "color": Colors.green},
  ];

  final List<int> amounts = [2, 5, 10, 20, 25, 50, 100, 200, 500, 1000];

  void _showGiftCardDetails(Map<String, dynamic> card) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: AssetImage(card["image"]),
                        radius: 25,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        card["name"],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Select Amount",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ✅ Amount grid
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.6,
                    physics: const NeverScrollableScrollPhysics(),
                    children: amounts.map((amount) {
                      final isSelected = selectedAmount == amount.toDouble();
                      return GestureDetector(
                        onTap: () {
                          setModalState(() => selectedAmount = amount.toDouble());
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected ? card["color"] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: card["color"].withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              "\$$amount",
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ✅ Buy Button inside modal
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: card["color"],
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(LucideIcons.shoppingBag, color: Colors.white),
                      label: Text(
                        "Buy ${card["name"]} card for \$$selectedAmount",
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Purchased ${card["name"]} Gift Card for \$$selectedAmount",
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGiftCard(Map<String, dynamic> card) {
    return GestureDetector(
      onTap: () => _showGiftCardDetails(card),
      child: Container(
        width: 160,
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: card["color"],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: card["color"].withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                LucideIcons.gift,
                size: 80,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: AssetImage(card["image"]),
                        radius: 16,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        card["name"],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Buy now",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      Icon(
                        LucideIcons.pen,
                        color: Colors.white70,
                        size: 16,
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Gift Cards"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Scrollable Gift Cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: giftCards.map(_buildGiftCard).toList(),
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: Text(
              "Tap a Gift Card to view details",
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
