// bank_transfer_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BankTransferPage extends StatelessWidget {
  final String accountNumber;
  final String userName;

  const BankTransferPage({
    super.key,
    required this.accountNumber,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scaffoldColor =
    isDark ? const Color(0xFF121212) : Colors.grey.shade100;
    final hintColor = isDark ? Colors.white38 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        elevation: 0,
        backgroundColor: scaffoldColor,
        // bring title closer to back arrow
        titleSpacing: 4,
        title: Text(
          'Bank Transfer to GlobalPay',
          style: theme.textTheme.titleLarge?.copyWith( // slightly bigger
            fontWeight: FontWeight.w500,               // lighter than bold
            color: theme.colorScheme.onBackground,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              // TODO: navigate to history page
            },
            icon: Icon(Icons.history,
                size: 18, color: theme.colorScheme.primary),
            label: Text(
              'History',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Glass-like account card
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GlobalPay Account Number',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: hintColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    accountNumber,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onBackground,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    await Clipboard.setData(
                                        ClipboardData(text: accountNumber));
                                    HapticFeedback.lightImpact();
                                    if (ScaffoldMessenger.maybeOf(context) != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Account number copied'),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    height: 36,
                                    width: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: theme.colorScheme.primary.withOpacity(0.12),
                                    ),
                                    child: Icon(IconsaxPlusLinear.copy,
                                        color: theme.colorScheme.primary, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _infoRow(theme, 'Bank', 'GlobalPay'),
                    const SizedBox(height: 10),
                    _infoRow(theme, 'Account Name', userName),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.16),

          const SizedBox(height: 18),

          // Share action (opens bottom sheet)
          GestureDetector(
            onTap: () => _showShareSheet(context, accountNumber, userName),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(IconsaxPlusLinear.direct_send,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Share account information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

          const SizedBox(height: 26),

          // Transfer Guide header
          Text(
            'How to transfer to your GlobalPay account',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          // Guide steps (animated)
          _guideStep(theme, 1, 'Copy the GlobalPay account number above.').animate(delay: 80.ms).fadeIn(),
          const SizedBox(height: 12),
          _guideStep(theme, 2, 'Open the bank app you want to transfer from.').animate(delay: 160.ms).fadeIn(),
          const SizedBox(height: 12),
          _guideStep(theme, 3, 'Select GlobalPay as the bank and paste the account number.').animate(delay: 240.ms).fadeIn(),
          const SizedBox(height: 12),
          _guideStep(theme, 4, 'Enter the amount and confirm the transfer.').animate(delay: 320.ms).fadeIn(),
          const SizedBox(height: 12),
          _guideStep(theme, 5, 'Wait for instant credit into your wallet.').animate(delay: 400.ms).fadeIn(),

          const SizedBox(height: 26),
          Text(
            'Note: Transfers may take a few seconds to a few minutes depending on your bank. If funds don\'t reflect, check your bank transaction history or contact support.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _guideStep(ThemeData theme, int step, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 26,
          width: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withOpacity(0.14),
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        )
      ],
    );
  }

  void _showShareSheet(BuildContext context, String accountNumber, String userName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            runSpacing: 6,
            children: [
              ListTile(
                leading: const Icon(Icons.chat),
                title: const Text('Share via Chat/WhatsApp'),
                onTap: () {
                  Navigator.pop(ctx);
                  Share.share(
                      'Transfer to GlobalPay\nAccount: $accountNumber\nName: $userName',
                      subject: 'My GlobalPay Account Info');
                },
              ),
              ListTile(
                leading: const Icon(Icons.sms),
                title: const Text('Share via SMS'),
                onTap: () {
                  Navigator.pop(ctx);
                  Share.share(
                      'Transfer to GlobalPay\nAccount: $accountNumber\nName: $userName');
                },
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Share via Email'),
                onTap: () {
                  Navigator.pop(ctx);
                  Share.share(
                      'Transfer to GlobalPay\nAccount: $accountNumber\nName: $userName',
                      subject: 'My GlobalPay Account Info');
                },
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Or copy and paste the details manually.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).hintColor),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }
}
