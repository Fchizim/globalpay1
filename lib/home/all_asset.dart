import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class AllAsset extends StatelessWidget {
  const AllAsset({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark? theme.scaffoldBackgroundColor : Colors.grey[100];
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    final subTextColor = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    final accentColor = isDark? Colors.deepOrange : Colors.deepOrange.shade200;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "All Assets",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Security Banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.green[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified, color: Colors.green.shade100),
                  const SizedBox(width: 8),
                  Text(
                    'Security Guaranteed',
                    style: TextStyle(color: Colors.green.shade100),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.green),
                ],
              ),
            ),
           // const SizedBox(height: 16),

            // Total Assets Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total Assets ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      Icon(IconsaxPlusLinear.eye, size: 20, color: textColor,)
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₦51,060.44',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Yesterday's Earnings: ₦0",
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // August Earnings
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('August Earnings', style: TextStyle(color: textColor)),
                  Text(
                    '+₦40.50',
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Total Balance Section
            _sectionCard(context, 'Balance', {
              'Balance': '₦0.00',
            }),
            const SizedBox(height: 16),

            // Savings Section
            _sectionCard(context, 'Savings', {
              'Target Savings': '₦51,050.00',
              'SafeBox': '₦0.00',
              'Spend & Save': '₦0.00',
            }),
            const SizedBox(height: 16),

            // GlobalPoints Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('GlobalPoints', style: TextStyle(color: textColor)),
                  Text('5', style: TextStyle(color: textColor)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                'Your 0 GlobalPoints will expire on 2025/09/30',
                style: TextStyle(color: accentColor, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Insurance Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Insurance', style: TextStyle(color: textColor)),
                  Text('1 Policy Active', style: TextStyle(color: textColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(BuildContext context, String title, Map<String, String> items) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 12),
          ...items.entries.map(
                (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade50.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10)
                ),
                
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: TextStyle(color: textColor)),
                    Text(e.value, style: TextStyle(color: textColor)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
