import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:globalpay/me/feedback.dart';

import '../home/all_asset.dart';
import '../home/home_page.dart';
import '../provider/user_provider.dart';
import 'app_settings.dart';
import 'notification_page.dart';
import '../profile_details/profile_upgrade.dart';
import '../help_page/help_screen.dart';
import '../profile_details/profile_details.dart';
import '../profile_details/invite.dart';
import '../provider/balance_provider.dart';
import '../home/currency_con.dart';

class MePage extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const MePage({super.key, required this.onToggleTheme});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  bool _showFullFormat = false;

  Future<void> _navigateWithLoader(Widget page) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoaderWrapper(child: page)),
    );
  }

  double get balance => UserBalance.instance.balance;

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

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {});
  }

  void _onSettingTap(String title) {
    switch (title) {
      case 'Notification':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationPage()),
        );
        break;
      case 'Help & Support':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HelpScreen()),
        );
        break;
      case 'Refer & Earn':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InviteFriends()),
        );
        break;
      case 'Profile Upgrade':
      case 'Linked Accounts':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KycLevelsPage()),
        );
        break;
      case 'Feedback':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FeedbackPage()),
        );
        break;
      case 'Dark Mode':
        widget.onToggleTheme();
        break;
      default:
        break;
    }
  }

  double s(double value) {
    final sw = MediaQuery.of(context).size.width;
    return (sw / 375 * value).clamp(value * 0.85, value * 1.25);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final theme = Theme.of(context);
    final imageUrl = user?.image ?? '';
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF7F7F7);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    double balance = UserBalance.instance.balance;
    final bool canToggle = balance >= 1000000;
    final String displayedBalance = (balance < 1000000 || _showFullFormat)
        ? formatFull(balance)
        : formatBalance(balance);

    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: Colors.deepOrange,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              scrolledUnderElevation: 0,
              pinned: true,
              elevation: 0,
              backgroundColor: bgColor,
              title: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileDetails(onToggleTheme: () {}),
                    ),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: s(24),
                      backgroundColor: isDark
                          ? Colors.deepOrange.shade900
                          : Colors.deepOrange.shade100,
                      backgroundImage: imageUrl.isNotEmpty
                          ? NetworkImage(imageUrl)
                          : const AssetImage('assets/images/png/gold.jpg')
                                as ImageProvider,
                    ),
                    SizedBox(width: s(12)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Hi, ${user?.name ?? 'Guest'}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: s(16),
                                color: textColor,
                              ),
                            ),
                            SizedBox(width: s(4)),
                            Icon(
                              IconsaxPlusBold.verify,
                              color: Colors.deepOrange,
                              size: s(17),
                            ),
                          ],
                        ),
                        Text(
                          user?.kycLevel ?? 'none',
                          style: TextStyle(
                            fontSize: s(12),
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    IconsaxPlusLinear.setting_2,
                    color: Colors.deepOrange,
                    size: s(24),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AppSettingsPage()),
                  ),
                ),
                SizedBox(width: s(10)),
              ],
            ),

            // 🟧 BALANCE CARD
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: s(20),
                  vertical: s(15),
                ),
                child: Container(
                  padding: EdgeInsets.all(s(16)),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(s(20)),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black26
                            : Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(s(12)),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black
                              : Colors.deepOrange.shade50,
                          borderRadius: BorderRadius.circular(s(14)),
                        ),
                        child: Icon(
                          IconsaxPlusBold.wallet_1,
                          size: s(32),
                          color: Colors.deepOrange,
                        ),
                      ),
                      SizedBox(width: s(16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "Total Balance",
                                      style: TextStyle(
                                        fontSize: s(14),
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(width: s(6)),
                                    Icon(
                                      IconsaxPlusLinear.eye,
                                      size: s(14),
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      _navigateWithLoader(const AllAsset()),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: s(10),
                                      vertical: s(4),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange,
                                      borderRadius: BorderRadius.circular(
                                        s(20),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          "Assets ",
                                          style: TextStyle(
                                            fontSize: s(10),
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Icon(
                                          Icons.wallet,
                                          size: s(10),
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: s(6)),
                            Row(
                              children: [
                                Text(
                                  displayedBalance,
                                  style: TextStyle(
                                    fontSize: s(22),
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                if (canToggle) ...[
                                  SizedBox(width: s(8)),
                                  GestureDetector(
                                    onTap: () => setState(
                                      () => _showFullFormat = !_showFullFormat,
                                    ),
                                    child: Icon(
                                      _showFullFormat
                                          ? Icons.toggle_on
                                          : Icons.toggle_off,
                                      size: s(24),
                                      color: _showFullFormat
                                          ? Colors.deepOrange
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 🟧 SETTINGS LIST
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: s(20)),
                child: Column(
                  children: [
                    _buildSectionHeader("General"),
                    _buildSetting(
                      "Transaction History",
                      IconsaxPlusLinear.activity,
                      cardColor,
                      textColor,
                    ),

                    SizedBox(height: s(15)),
                    _buildSectionHeader("Account"),
                    _buildSetting(
                      "Profile Upgrade",
                      IconsaxPlusLinear.user_add,
                      cardColor,
                      textColor,
                    ),
                    _buildSetting(
                      "Linked Accounts",
                      IconsaxPlusLinear.wallet_2,
                      cardColor,
                      textColor,
                    ),

                    SizedBox(height: s(15)),
                    _buildSectionHeader("More"),
                    _buildSetting(
                      "Refer & Earn",
                      IconsaxPlusLinear.money_recive,
                      cardColor,
                      textColor,
                    ),
                    _buildSetting(
                      "Help & Support",
                      IconsaxPlusLinear.message_question,
                      cardColor,
                      textColor,
                    ),
                    _buildSetting(
                      "Feedback",
                      IconsaxPlusLinear.message_tick,
                      cardColor,
                      textColor,
                    ),

                    SizedBox(height: s(15)),
                    _buildDarkModeSwitch(isDark, cardColor, textColor),
                    SizedBox(height: s(30)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(left: s(4), bottom: s(8)),
        child: Text(
          title,
          style: TextStyle(
            fontSize: s(13),
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildSetting(
    String title,
    IconData icon,
    Color cardColor,
    Color textColor,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: s(10)),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(s(16)),
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: s(24), color: Colors.deepOrange),
        title: Text(
          title,
          style: TextStyle(
            fontSize: s(15),
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: s(14),
          color: Colors.grey,
        ),
        onTap: () => _onSettingTap(title),
      ),
    );
  }

  Widget _buildDarkModeSwitch(bool isDark, Color cardColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(s(16)),
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
      ),
      child: SwitchListTile(
        dense: true,
        value: isDark,
        onChanged: (val) => widget.onToggleTheme(),
        title: Text(
          isDark ? "Enable Light Mode" : "Enable Dark Mode",
          style: TextStyle(
            fontSize: s(15),
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        secondary: Icon(
          isDark ? Icons.wb_sunny : IconsaxPlusLinear.moon,
          size: s(24),
          color: Colors.deepOrange,
        ),
        activeColor: Colors.deepOrange,
      ),
    );
  }
}
