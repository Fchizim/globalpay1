import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../provider/balance_provider.dart';
import 'currency_con.dart';

class AllAsset extends StatefulWidget {
  const AllAsset({super.key});

  @override
  State<AllAsset> createState() => _AllAssetState();
}

class _AllAssetState extends State<AllAsset> {
  // Mirrors the same "full number vs M/B abbreviation" toggle used on the
  // Home/Me page balance cards, so tapping the amount here behaves the
  // same way it does everywhere else the balance shows up.
  bool _showFullFormat = false;

  String formatFull(double amount) {
    final formatter = NumberFormat("#,##0.00", "en_US");
    return "${CurrencyConfig().symbol}${formatter.format(amount)}";
  }

  String formatBalance(double amount) {
    if (amount >= 1000000000) {
      return "${CurrencyConfig().symbol}${(amount / 1000000000).toStringAsFixed(2)}B";
    } else if (amount >= 1000000) {
      return "${CurrencyConfig().symbol}${(amount / 1000000).toStringAsFixed(2)}M";
    } else {
      final formatter = NumberFormat("#,##0.00", "en_US");
      return "${CurrencyConfig().symbol}${formatter.format(amount)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark
        ? theme.scaffoldBackgroundColor
        : Colors.grey[100];
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    final subTextColor = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    final accentColor = isDark ? Colors.deepOrange : Colors.deepOrange.shade500;

    // Same balance source the Me page / Home page read from, so this page
    // always shows the real, live wallet balance instead of a hardcoded
    // ₦0.00 — and the hide/show eye here toggles the same shared state,
    // so it stays in sync with the eye icon everywhere else in the app.
    final balanceNotifier = context.watch<UserBalance>();
    final double balance = balanceNotifier.balance;
    final bool canToggle = balance >= 1000000;
    final String displayedBalance = balanceNotifier.isHidden
        ? "* * * *"
        : (balance < 1000000 || _showFullFormat)
        ? formatFull(balance)
        : formatBalance(balance);

    // Screen-size aware scaling so this page looks right on small and large
    // phones/tablets instead of using fixed pixel values everywhere.
    final double screenWidth = MediaQuery.of(context).size.width;
    final double scale = (screenWidth / 390.0).clamp(0.85, 1.15);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "All Assets",
          style: TextStyle(
            fontSize: 20 * scale,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16 * scale),
        child: ConstrainedBox(
          // Caps the whole page width on tablets/large screens instead of
          // letting cards stretch edge-to-edge and look oversized.
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security Banner
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: 8 * scale,
                  horizontal: 12 * scale,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified,
                      color: Colors.green.shade100,
                      size: 20 * scale,
                    ),
                    SizedBox(width: 8 * scale),
                    Expanded(
                      child: Text(
                        'Security Guaranteed',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.green.shade100,
                          fontSize: 14 * scale,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14 * scale,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),

              // Total Assets Card — now wired to the real, live balance.
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16 * scale),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total Assets ',
                          style: TextStyle(
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        // Eye icon toggles the SAME shared isHidden state
                        // the Me page / Home page balance use — hiding it
                        // here hides it everywhere, and vice versa.
                        GestureDetector(
                          onTap: () => balanceNotifier.toggleHidden(),
                          child: Icon(
                            balanceNotifier.isHidden
                                ? IconsaxPlusLinear.eye_slash
                                : IconsaxPlusLinear.eye,
                            size: 20 * scale,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8 * scale),
                    GestureDetector(
                      // Tap the amount to flip between the M/B abbreviation
                      // and the full number — same gesture the Home page
                      // balance card uses, only enabled once it's actually
                      // large enough to abbreviate.
                      onTap: canToggle
                          ? () => setState(
                              () => _showFullFormat = !_showFullFormat,
                            )
                          : null,
                      // FittedBox so a very large balance never overflows,
                      // it scales down instead.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          displayedBalance,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 32 * scale,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16 * scale),

              // Total Balance Section — same live balance, still respects
              // the hide toggle above.
              _sectionCard(context, 'Balance', {
                'Balance': displayedBalance,
              }, scale),
              SizedBox(height: 16 * scale),

              // Savings Section — no backing data source for these yet, so
              // they stay an honest ₦0.00 placeholder rather than fake
              // numbers.
              _sectionCard(context, 'Savings', {
                'Target Savings': '₦0.00',
                'SafeBox': '₦0.00',
                'Spend & Save': '₦0.00',
              }, scale),
              SizedBox(height: 16 * scale),

              // Insurance Section
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: 12 * scale,
                  horizontal: 16 * scale,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Insurance',
                      style: TextStyle(color: textColor, fontSize: 14 * scale),
                    ),
                    Flexible(
                      child: Text(
                        '1 Policy Active',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14 * scale,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context,
    String title,
    Map<String, String> items,
    double scale,
  ) {
    final theme = Theme.of(context);

    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;

    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          SizedBox(height: 12 * scale),
          ...items.entries.map(
            (e) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4 * scale),
              child: Container(
                padding: EdgeInsets.all(9 * scale),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade50.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        e.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14 * scale,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        e.value,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14 * scale,
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
}
