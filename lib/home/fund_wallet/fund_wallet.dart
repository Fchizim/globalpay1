import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:globalpay/home/fund_wallet/via_bank_transfer.dart';

import 'bank_card.dart';

class FundWallet extends StatefulWidget {
  const FundWallet({super.key});

  @override
  State<FundWallet> createState() => _FundWalletState();
}

class _FundWalletState extends State<FundWallet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // your account number + name would normally come from backend/provider
  final String accountNumber = '1234567890';
  final String userName = 'John Doe';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(_controller);

    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color scaffoldColor =
    isDark ? const Color(0xFF121212) : Colors.grey.shade100;
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color hintColor = isDark ? Colors.white38 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: scaffoldColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onBackground),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Big title at top
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Text(
                    'Fund Wallet',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                ),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Text(
                    'Choose a method below',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: hintColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Account Number Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account number',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: hintColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              accountNumber,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 15),

                            // copy icon with clipboard
                            GestureDetector(
                              onTap: () async {
                                await Clipboard.setData(
                                    ClipboardData(text: accountNumber));
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                      const Text('Account number copied'),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: _circleIcon(theme, IconsaxPlusLinear.copy),
                            ),
                            const SizedBox(width: 10),

                            // share button with system share sheet
                            GestureDetector(
                              onTap: () {
                                Share.share(
                                  'Here is my account number: $accountNumber',
                                  subject: 'My Account Number',
                                );
                              },
                              child: _circleIcon(
                                  theme, IconsaxPlusLinear.direct_send),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // Funding options
                _fundOption(
                  theme,
                  cardColor: cardColor,
                  hintColor: hintColor,
                  icon: IconsaxPlusBold.card,
                  label: 'Via Bank Transfer',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BankTransferPage(
                          accountNumber: accountNumber,
                          userName: userName,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 15),
                _fundOption(
                  theme,
                  cardColor: cardColor,
                  hintColor: hintColor,
                  icon: IconsaxPlusBold.hashtag,
                  label: 'Via USSD Codes',
                  // add your ussd logic here
                ),
                const SizedBox(height: 15),
                _fundOption(
                  theme,
                  cardColor: cardColor,
                  hintColor: hintColor,
                  icon: IconsaxPlusBold.bank,
                  label: 'Top-up with Card / Account',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TopUpCardPage(), // <— nav here
                      ),
                    );
                  },
                ),
                const SizedBox(height: 25),

                // Info text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Funds deposited via bank transfer to the listed\n'
                        'account number will be added to your wallet.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: hintColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Small circle action button
  Widget _circleIcon(ThemeData theme, IconData icon) {
    return Container(
      height: 35,
      width: 35,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary.withOpacity(0.1),
      ),
      child: Icon(
        icon,
        color: theme.colorScheme.primary,
        size: 18,
      ),
    );
  }

  /// Fund option card
  Widget _fundOption(
      ThemeData theme, {
        required Color cardColor,
        required Color hintColor,
        required IconData icon,
        required String label,
        VoidCallback? onTap,
      }) {
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: colorScheme.primary.withOpacity(0.1),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: hintColor,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
