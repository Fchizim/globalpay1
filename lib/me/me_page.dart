import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:globalpay/me/feedback.dart';

import '../home/all_asset.dart';
import '../home/home_page.dart';
import 'app_settings.dart';
import 'notification_page.dart';
import 'profile_upgrade.dart';
import '../help_page/help_screen.dart';
import '../profile_details/profile_details.dart';
import '../profile_details/invite.dart';
import '../provider/balance_provider.dart';
import '../home/currency_con.dart'; // ✅ Import CurrencyConfig

/// Helper class for storing user name
class LocalUser {
  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  static Future<void> setName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', name);
  }
}

class MePage extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const MePage({super.key, required this.onToggleTheme});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  Future<void> _navigateWithLoader(Widget page) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoaderWrapper(child: page)),
    );
  }

  bool _showFullFormat = false;
  String? userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    userName = await LocalUser.getName();
    if (mounted) setState(() {});
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
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPage()));
        break;
      case 'Help & Support':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()));
        break;
      case 'Refer & Earn':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const InviteFriends()));
        break;
      case 'Profile Upgrade':
      case 'Linked Accounts':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const KycLevelsPage()));
        break;
      case 'Feedback':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackPage()));
        break;
      case 'Dark Mode':
        widget.onToggleTheme();
        break;
      default:
        break;
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 💡 Use fintech-friendly dark/light colours
    final bgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF7F7F7);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    final bool canToggle = balance >= 1000000;
    final String displayedBalance =
    (balance < 1000000 || _showFullFormat) ? formatFull(balance) : formatBalance(balance);

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
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileDetails()));
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: isDark
                          ? Colors.deepOrange.shade700
                          : Colors.deepOrange.shade100,
                      backgroundImage: const AssetImage('assets/images/png/gold.jpg'),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Hi, ${userName ?? 'GOLD'}",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: textColor),
                            ),
                            const SizedBox(width: 5),
                            const Icon(IconsaxPlusBold.verify,
                                color: Colors.deepOrange, size: 18),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "President",
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.grey.shade400 : Colors.deepOrange),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(IconsaxPlusLinear.setting_2, color: Colors.deepOrange),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AppSettingsPage()));
                  },
                ),
              ],
            ),

            // 🟧 Balance card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=> AllAsset()));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: cardColor,
                      gradient: isDark
                          ? null
                          : LinearGradient(
                        colors: [Colors.deepOrange.shade50, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black
                              : Colors.grey.shade400,
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(IconsaxPlusBold.wallet_1,
                              size: 40, color: Colors.deepOrange),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("Total Balance",
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: textColor)),
                                  const SizedBox(width: 6),
                                  Icon(IconsaxPlusLinear.eye,
                                      size: 18, color: textColor),
                                  if (canToggle) ...[
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() => _showFullFormat = !_showFullFormat);
                                      },
                                      child: Icon(
                                        _showFullFormat ? Icons.toggle_on : Icons.toggle_off,
                                        size: 26,
                                        color: _showFullFormat
                                            ? Colors.deepOrange
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 16),
                                  Container(
                                    height: 25,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange,
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        _navigateWithLoader(const AllAsset());
                                      },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Text(
                                            "Assets ",
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Icon(Icons.wallet, size: 12, color: Colors.white),
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(displayedBalance,
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.deepOrange.shade900)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 🟧 Settings list
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildSectionHeader("General"),
                    _buildSetting("Transaction History", IconsaxPlusLinear.activity, cardColor, textColor),

                    const SizedBox(height: 10),
                    _buildSectionHeader("Account"),
                    _buildSetting("Profile Upgrade", IconsaxPlusLinear.user_add, cardColor, textColor),
                    _buildSetting("Linked Accounts", IconsaxPlusLinear.wallet_2, cardColor, textColor),


                    const SizedBox(height: 20),
                    _buildSectionHeader("More"),
                    _buildSetting("Refer & Earn", IconsaxPlusLinear.money_recive, cardColor, textColor),
                    _buildSetting("Help & Support", IconsaxPlusLinear.message_question, cardColor, textColor),
                    _buildSetting("Feedback", IconsaxPlusLinear.message_tick, cardColor, textColor),

                    const SizedBox(height: 20),
                    _buildDarkModeSwitch(isDark, cardColor, textColor),
                    const SizedBox(height: 30),
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
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
      ),
    );
  }

  Widget _buildSetting(String title, IconData icon, Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: cardColor == Colors.white ? Colors.grey.shade200 : Colors.black45,
              blurRadius: 15,
              offset: const Offset(0, 6)),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, size: 26, color: Colors.deepOrange),
        title: Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor)),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            size: 16, color: textColor),
        onTap: () => _onSettingTap(title),
      ),
    );
  }

  Widget _buildDarkModeSwitch(bool isDark, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: cardColor == Colors.white ? Colors.grey.shade200 : Colors.black45,
              blurRadius: 15,
              offset: const Offset(0, 6)),
        ],
      ),
      child: SwitchListTile(
        value: isDark,
        onChanged: (val) => widget.onToggleTheme(),
        title: Text(isDark ? "Enable Light Mode" : "Enable Dark Mode",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor)),
        secondary: Icon(isDark ? Icons.wb_sunny : IconsaxPlusLinear.moon,
            size: 26, color: Colors.deepOrange),
        activeColor: Colors.deepOrange,
      ),
    );
  }
}
