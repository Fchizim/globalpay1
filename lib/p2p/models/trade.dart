import 'package:flutter/material.dart';
import 'offer.dart';
import '../widget/trade_card.dart';

class TradeDetailPage extends StatelessWidget {
  final P2POffer offer;
  final void Function(P2POffer offer)? onTradeCompleted;

  const TradeDetailPage({
    super.key,
    required this.offer,
    this.onTradeCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${offer.isBuy ? 'Buying' : 'Selling'} ${offer.currencyWant}"),
        backgroundColor: Colors.deepOrange,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Offer Details",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text("Trader: ${offer.user} (${offer.rating})"),
                const SizedBox(height: 4),
                Text("Amount Available: ${offer.amountHave} ${offer.currencyHave}"),
                Text("Rate: ${offer.rate}"),
                Text("Payment Method: ${offer.paymentMethod}"),
                if (offer.terms.isNotEmpty) Text("Terms: ${offer.terms}"),
                Text(
                  "You will get approx: ${(offer.amountHave * offer.rate).toStringAsFixed(2)} ${offer.currencyWant}",
                ),
                const SizedBox(height: 4),
                Text("Trade Limits: ${offer.minLimit} - ${offer.maxLimit} ${offer.currencyHave}"),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Column(
              children: [
                const Expanded(child: TradeChatWidget()),
                Container(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton(
                    onPressed: () {
                      if (onTradeCompleted != null) onTradeCompleted!(offer);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            offer.isBuy
                                ? "Payment sent! Follow instructions to complete."
                                : "Trade confirmed! Send funds as instructed.",
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: Text(
                      offer.isBuy ? "Pay Seller" : "Confirm Payment",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
