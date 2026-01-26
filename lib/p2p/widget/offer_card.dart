import 'package:flutter/material.dart';
import '../models/offer.dart';
import 'package:intl/intl.dart';

class OfferCard extends StatelessWidget {
  final P2POffer offer;
  final VoidCallback onTap;

  const OfferCard({super.key, required this.offer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final NumberFormat f = NumberFormat("#,##0.00", "en_US");

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            // Currency Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: offer.isBuy
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                offer.isBuy ? "Buy" : "Sell",
                style: TextStyle(
                  color: offer.isBuy ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Offer Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${offer.isBuy ? 'Buy' : 'Sell'} ${offer.currencyWant}",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${f.format(offer.amountHave)} ${offer.currencyHave} @ ${offer.rate.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Trader: ${offer.user} (${offer.rating})",
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 18, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}
