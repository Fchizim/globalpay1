import 'package:flutter/material.dart';
import 'package:globalpay/Market/StoreSetupPage.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../market/market_page.dart';

class BusinessPage extends StatefulWidget {
  const BusinessPage({super.key});

  @override
  State<BusinessPage> createState() => _BusinessPageState();
}

class _BusinessPageState extends State<BusinessPage> {
  // State for acceptance checkbox
  bool _isAccepted = false;

  final List<Map<String, dynamic>> features = [
    {
      'icon': IconsaxPlusLinear.star_1,
      'title': 'Marketplace Store',
      'subtitle': 'Set up your own store and start listing products to sell.',
    },
    {
      'icon': IconsaxPlusLinear.people,
      'title': 'Customer Connections',
      'subtitle':
          'Easily communicate with buyers and manage orders efficiently.',
    },
    {
      'icon': IconsaxPlusLinear.trend_up,
      'title': 'Sales Insights',
      'subtitle': 'Track your sales, profits, and top-selling items with ease.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = Colors.deepOrange;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Main Title
            Text(
              'Set up your\nGlobalBiz Profile',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                //letterSpacing: 1,
                color: isDark ? Colors.white : Colors.black,
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

            const SizedBox(height: 15),

            Text(
              'Start selling in the marketplace. Manage your sales, earnings, and customers in one professional dashboard.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ).animate(delay: 100.ms).fadeIn(),

            const SizedBox(height: 30),

            // Pricing Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: primaryColor.withOpacity(0.15)),
              ),
              child: Column(
                children: [
                  _pricingRow(
                    IconsaxPlusLinear.card_pos,
                    "Subscription",
                    "₦500 / Year",
                    isDark,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  _pricingRow(
                    IconsaxPlusLinear.percentage_square,
                    "Service Fee",
                    "2% per sale",
                    isDark,
                  ),
                  const SizedBox(height: 15),
                  // Acceptance Checkbox
                  InkWell(
                    onTap: () => setState(() => _isAccepted = !_isAccepted),
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _isAccepted,
                            activeColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            onChanged: (val) {
                              setState(() => _isAccepted = val!);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "I accept the terms and service fees",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate(delay: 200.ms).scale(curve: Curves.easeOutBack),

            const SizedBox(height: 35),

            Text(
              'Key Features',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 15),

            // Features list
            ...features.asMap().entries.map((entry) {
              int index = entry.key;
              var feature = entry.value;

              return _featureItem(
                    theme,
                    feature['icon'] as IconData,
                    feature['title'] as String,
                    feature['subtitle'] as String,
                    isDark,
                  )
                  .animate(delay: (400 + index * 100).ms)
                  .fadeIn()
                  .slideX(begin: 0.1);
            }),

            const SizedBox(height: 40),

            // Main Action Button (Reactive)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isAccepted
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StoreSetupPage(),
                          ),
                        );
                      }
                    : null, // Button is disabled if not accepted
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Get Started",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isAccepted ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ).animate(delay: 800.ms).fadeIn(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _pricingRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepOrange, size: 22),
        const SizedBox(width: 15),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.deepOrange,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _featureItem(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.deepOrange, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                    height: 1.3,
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
