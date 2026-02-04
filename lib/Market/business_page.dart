import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../market/market_page.dart';

class BusinessPage extends StatefulWidget {
  const BusinessPage({super.key});

  @override
  State<BusinessPage> createState() => _BusinessPageState();
}

class _BusinessPageState extends State<BusinessPage> {
  final List<Map<String, dynamic>> features = [
    {
      'icon': IconsaxPlusLinear.wallet_1,
      'title': 'Personal Wallet',
      'subtitle': 'Keep your earnings from marketplace sales safe and separate.'
    },
    {
      'icon': IconsaxPlusLinear.star_1,
      'title': 'Marketplace Store',
      'subtitle': 'Set up your own store and start listing products to sell.'
    },
    {
      'icon': IconsaxPlusLinear.people,
      'title': 'Customer Connections',
      'subtitle': 'Easily communicate with buyers and manage orders efficiently.'
    },
    {
      'icon': IconsaxPlusLinear.trend_up,
      'title': 'Sales Insights',
      'subtitle': 'Track your sales, profits, and top-selling items with ease.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CardPage()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Container(
                height: 30,
                width: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    "Next",
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Title
            Text(
              'Welcome, set up your\nGlobalBiz Profile.',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            )
                .animate(delay: 0.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.2, duration: 500.ms),

            const SizedBox(height: 20),

            // Subtitle
            Text(
              'Start selling in the marketplace with your own GlobalBiz profile. '
                  'Manage your sales, earnings, and customer connections seamlessly '
                  'while keeping everything secure in one place.',
              style: theme.textTheme.bodyMedium,
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.2, duration: 500.ms),

            const SizedBox(height: 25),

            // Key Features Header
            Text(
              'Key Features',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            )
                .animate(delay: 400.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.2, duration: 500.ms),

            const SizedBox(height: 10),

            // Features list
            ...features.asMap().entries.map((entry) {
              int index = entry.key;
              var feature = entry.value;

              return _featureItem(
                theme,
                feature['icon'] as IconData,
                feature['title'] as String,
                feature['subtitle'] as String,
              )
                  .animate(delay: (500 + index * 150).ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.2, duration: 500.ms);
            }),
          ],
        ),
      ),
    );
  }

  Widget _featureItem(ThemeData theme, IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 55,
            width: 55,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: theme.colorScheme.onPrimary, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 3),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
