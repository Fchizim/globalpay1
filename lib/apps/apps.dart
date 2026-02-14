import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';

import 'package:globalpay/help_page/help_screen.dart';
import 'package:globalpay/profile_details/profile_details.dart';

import '../market/market_page.dart';
import '../convert/convert_page.dart';
import '../home/home_page.dart';
import '../me/me_page.dart';
import '../home/card/card_page.dart';

import '../models/user_model.dart';
import '../provider/user_provider.dart';

class MyAppsPage extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const MyAppsPage({super.key, required this.onToggleTheme});

  @override
  State<MyAppsPage> createState() => _MyAppsPageState();
}

class _MyAppsPageState extends State<MyAppsPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final Color darkBackground = const Color(0xFF121212);
  final Color darkCard = const Color(0xFF1E1E1E);
  final Color textPrimary = Colors.white;
  final Color accentColor = Colors.deepOrange;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final List<Widget> pages = [
      const HomePage(),
      const FinancePage(),
      const CardPage(),
      const CardsPage(),
      MePage(onToggleTheme: widget.onToggleTheme),
    ];

    return Scaffold(
      backgroundColor: isDark ? darkBackground : Colors.grey.shade100,
      appBar: _selectedIndex == 0
          ? buildAppBar(isDark: isDark, user: user)
          : null,
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? darkCard : Colors.white,
          border: const Border(
            top: BorderSide(color: Colors.black12, width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            unselectedItemColor: isDark ? Colors.white54 : Colors.grey,
            selectedItemColor: accentColor,
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            iconSize: 24,
            items: [
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 0
                      ? IconsaxPlusBold.home
                      : IconsaxPlusLinear.home,
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 1
                      ? IconsaxPlusBold.chart_3
                      : IconsaxPlusLinear.chart_3,
                ),
                label: 'Finance',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    IconsaxPlusBold.shop,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 3
                      ? IconsaxPlusBold.card
                      : IconsaxPlusLinear.card,
                ),
                label: 'Cards',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 4
                      ? IconsaxPlusBold.grammerly
                      : IconsaxPlusLinear.grammerly,
                ),
                label: 'Me',
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget buildAppBar({
    required bool isDark,
    required UserModel? user,
  }) {
    final textColor = isDark ? textPrimary : Colors.black87;
    final String? imageUrl = user?.image;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: isDark ? darkBackground : Colors.grey.shade100,
      title: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfileDetails(onToggleTheme: () {  },)),
          );
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: accentColor.withOpacity(0.1),
              backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                  ? NetworkImage(imageUrl)
                  : const AssetImage('assets/images/png/gold.jpg'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Hi, ${user?.name ?? 'Guest'}",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: textColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.verified,
                        color: Colors.deepOrange,
                        size: 16,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 18,
                    child: Marquee(
                      text: user != null
                          ? "🔥 Welcome back, ${user.name}! Check out new updates! 🔥"
                          : "🔥 Welcome! Check out new updates! 🔥",
                      style: TextStyle(color: textColor, fontSize: 14),
                      blankSpace: 30.0,
                      velocity: 30.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpScreen()),
                  );
                },
                child: Container(
                  height: 25,
                  width: 43,
                  decoration: const BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Help",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(IconsaxPlusLinear.scan, color: textColor),
              const SizedBox(width: 10),
              Icon(IconsaxPlusLinear.notification_bing, color: textColor),
            ],
          ),
        ),
      ],
    );
  }
}