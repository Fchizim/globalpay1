import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/offer.dart';
import 'models/trade.dart';

class P2PHome extends StatefulWidget {
  const P2PHome({super.key});

  @override
  State<P2PHome> createState() => _P2PHomeState();
}

class _P2PHomeState extends State<P2PHome> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<P2POffer> offers = [
    P2POffer(
      id: "1",
      currencyHave: "USD",
      currencyWant: "NGN",
      amountHave: 100,
      rate: 460,
      isBuy: true,
      user: "Alice",
      rating: 4.8,
    ),
    P2POffer(
      id: "2",
      currencyHave: "NGN",
      currencyWant: "USD",
      amountHave: 46000,
      rate: 0.00217,
      isBuy: false,
      user: "Bob",
      rating: 4.5,
    ),
    P2POffer(
      id: "3",
      currencyHave: "USD",
      currencyWant: "NGN",
      amountHave: 50,
      rate: 455,
      isBuy: true,
      user: "Charlie",
      rating: 4.9,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  List<P2POffer> _getFilteredOffers(bool buyTab) {
    return offers.where((o) => buyTab ? o.isBuy : !o.isBuy).toList();
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat f = NumberFormat("#,##0.00", "en_US");

    return Scaffold(
      appBar: AppBar(
        title: const Text("P2P Marketplace"),
        backgroundColor: Colors.deepOrange,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Buy"),
            Tab(text: "Sell"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOfferList(_getFilteredOffers(true), f),
          _buildOfferList(_getFilteredOffers(false), f),
        ],
      ),
    );
  }

  Widget _buildOfferList(List<P2POffer> offers, NumberFormat f) {
    if (offers.isEmpty) {
      return const Center(child: Text("No offers available"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final offer = offers[index];
        return OfferCard(
          offer: offer,
          format: f,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TradeDetailPage(
                  offer: offer,
                  onTradeCompleted: (trade) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Trade completed!")),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class OfferCard extends StatelessWidget {
  final P2POffer offer;
  final NumberFormat format;
  final VoidCallback onTap;

  const OfferCard({
    super.key,
    required this.offer,
    required this.format,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                offer.isBuy ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                child: Text(
                  offer.currencyHave,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: offer.isBuy ? Colors.green : Colors.red,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${offer.isBuy ? "Buy" : "Sell"} ${offer.currencyWant}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${format.format(offer.amountHave)} ${offer.currencyHave} @ ${offer.rate.toStringAsFixed(2)}",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          "${offer.user} (${offer.rating.toStringAsFixed(1)})",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: offer.isBuy ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  offer.isBuy ? "Buy" : "Sell",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}