import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:globalpay/home/bet_screen.dart';
import 'package:globalpay/home/transaction.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:globalpay/home/fund_wallet/fund_wallet.dart';
import 'package:globalpay/home/send_money.dart';
import 'package:intl/intl.dart';
import 'package:globalpay/home/user_page.dart';
import '../profile_details/invite.dart';
import '../provider/balance_provider.dart';
import '../provider/user_provider.dart';
import '../qrcode_send/qrcode_send.dart' hide UserBalance;
import '../services/profile_service.dart';
import '../services/secure_storage_service.dart';
import 'airtime_page.dart';
import 'all_asset.dart';
import 'currency_con.dart';
import 'data_page.dart';
import 'electricity.dart';
import 'finance/create_target_page.dart';
import 'g-tag.dart';
import 'giftcard.dart';
// import 'transactions.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  bool isRefreshing = false;
  bool _showFullFormat = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final userProvider = context.read<UserProvider>();
      final localUser = await SecureStorageService.getUser();
      if (localUser != null) {
        final freshUser = await ProfileService.getProfile(localUser.userId);
        if (freshUser != null) {
          await userProvider.updateUser(freshUser);
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshUserData() async {
    final localUser = await SecureStorageService.getUser();
    if (localUser != null) {
      final freshUser = await ProfileService.getProfile(localUser.userId);
      if (freshUser != null) {
        await SecureStorageService.saveUser(freshUser);
        if (mounted) {
          UserBalance.instance.balance = freshUser.wallet;
          context.read<UserProvider>().updateUser(freshUser);
        }
      }
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => isRefreshing = true);
    await _refreshUserData();
    if (!mounted) return;
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => isRefreshing = false);
  }

  Future<void> _navigateWithLoader(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoaderWrapper(child: page)),
    );
    await _refreshUserData();
  }

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
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: SpinKitFadingCube(color: Colors.deepOrange, size: 55),
        ),
      );
    }

    if (UserBalance.instance.balance == 0) {
      UserBalance.instance.balance = user.wallet ?? 0;
    }

    double balance = UserBalance.instance.balance;
    final bool canToggle = balance >= 1000000;
    final String displayedBalance = (balance < 1000000 || _showFullFormat)
        ? formatFull(balance)
        : formatBalance(balance);

    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final scaffoldColor = isDark
        ? const Color(0xFF121212)
        : Colors.deepOrange.shade50.withOpacity(0.2);
    final hintColor = isDark ? Colors.white : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: Colors.deepOrange,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ── Balance card ───────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AllAsset()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                          Colors.deepOrange.shade500,
                          Colors.white12,
                          Colors.deepOrange.shade400,
                        ]
                            : [Colors.deepOrange.shade200, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(IconsaxPlusBold.shield_tick,
                                color: Colors.green.shade600, size: 20),
                            Text(
                              ' Available Balance ',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize:   22,
                                letterSpacing: -1,
                                color: textColor,
                              ),
                            ),
                            Icon(IconsaxPlusLinear.eye,
                                size: 20, color: hintColor),
                            if (canToggle) ...[
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => setState(
                                        () => _showFullFormat = !_showFullFormat),
                                child: Icon(
                                  _showFullFormat
                                      ? Icons.toggle_on
                                      : Icons.toggle_off,
                                  size: 32,
                                  color: _showFullFormat
                                      ? Colors.deepOrange
                                      : hintColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _navigateWithLoader(const FundWallet()),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                displayedBalance,
                                style: TextStyle(
                                  fontSize:     37,
                                  letterSpacing: -2,
                                  fontWeight:   FontWeight.w500,
                                  color:        textColor,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Icon(IconsaxPlusLinear.add_circle,
                                  color: textColor),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Quick actions ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: cardColor,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      InkWell(
                        onTap: () => _navigateWithLoader(SendMoney(
                          balance: balance,
                          image:   'assets/images/png/profile.png',
                          name:    'Recipient Name',
                          account: '1234567890',
                          bank:    'Bank Name',
                          onTransaction: (double amount) =>
                              setState(() => UserBalance.instance.balance -= amount),
                        )),
                        child: _buildCard(context,
                            icon: IconsaxPlusBold.bank,
                            label: "To Bank",
                            cardColor: cardColor,
                            textColor: textColor),
                      ),
                      InkWell(
                        onTap: () => _navigateWithLoader(UserPage(
                          balance: balance,
                          onTransaction: (double amount) =>
                              setState(() => UserBalance.instance.balance -= amount),
                        )),
                        child: _buildCard(context,
                            icon: Icons.diversity_1,
                            label: "To User",
                            cardColor: cardColor,
                            textColor: textColor),
                      ),
                      InkWell(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => MoneyDropPage())),
                        child: _buildCard(context,
                            icon: IconsaxPlusBold.coin_1,
                            label: "G-Drop",
                            cardColor: cardColor,
                            textColor: textColor),
                      ),
                      InkWell(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => GTagPaymentPage(balance: balance))),
                        child: _buildCard(context,
                            icon: IconsaxPlusBold.tag_2,
                            label: "G-Tag",
                            cardColor: cardColor,
                            textColor: textColor),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Services page view ─────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  height: 170,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.all(Radius.circular(15)),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 140,
                        child: PageView(
                          controller: _pageController,
                          children: [
                            Column(
                              children: [
                                _buildPageViewRow(cardColor, textColor),
                                _buildPageViewRow2(cardColor, textColor),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: 1,
                        effect: WormEffect(
                          dotHeight: 7,
                          dotWidth:  20,
                          dotColor:  hintColor,
                          activeDotColor: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ── Transactions (dynamic) ─────────────────────
              TransactionListWidget(
                cardColor: cardColor,
                textColor: textColor,
                hintColor: hintColor,
                isDark:    isDark,
              ),

              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  Widget _buildCard(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Color cardColor,
        required Color textColor,
      }) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 49, width: 49,
            decoration: BoxDecoration(
                color: Colors.deepOrange.shade50, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.deepOrange, size: 25),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: TextStyle(
                  color: textColor, fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPageViewRow(Color cardColor, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        InkWell(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => AirtimeScreen())),
          child: _buildSmallCard(LucideIcons.tabletSmartphone400, "Airtime",
              Colors.deepOrange, cardColor, textColor),
        ),
        InkWell(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => DataScreen())),
          child: _buildSmallCard(IconsaxPlusBold.radar_2, "Data",
              Colors.deepPurple, cardColor, textColor),
        ),
        InkWell(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => ElectricityScreen())),
          child: _buildSmallCard(LucideIcons.lightbulb, "Electricity",
              Colors.blueAccent, cardColor, textColor),
        ),
        InkWell(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => GiftCardPage())),
          child: _buildSmallCard(IconsaxPlusBold.ship, "Gift Card",
              Colors.blue.shade800, cardColor, textColor),
        ),
      ],
    );
  }

  Widget _buildPageViewRow2(Color cardColor, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        InkWell(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => InviteFriends())),
          child: _buildSmallCard(LucideIcons.gem, "Earn",
              Colors.deepOrange, cardColor, textColor),
        ),
        InkWell(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => InviteFriends())),
          child: _buildSmallCard(LucideIcons.tv, "TV",
              Colors.deepPurple, cardColor, textColor),
        ),
        InkWell(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => CreateTargetPage())),
          child: _buildSmallCard(LucideIcons.target, "T-save",
              Colors.blueAccent, cardColor, textColor),
        ),
        InkWell(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => BetScreen())),
          child: _buildSmallCard(LucideIcons.handCoins, "Betting",
              Colors.blue.shade800, cardColor, textColor),
        ),
      ],
    );
  }

  Widget _buildSmallCard(
      IconData icon,
      String label,
      Color color,
      Color cardColor,
      Color textColor,
      ) {
    return Container(
      height: 65, width: 75,
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: textColor)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LoaderWrapper
// ─────────────────────────────────────────────────────────────

class LoaderWrapper extends StatefulWidget {
  final Widget child;
  const LoaderWrapper({required this.child, super.key});

  @override
  State<LoaderWrapper> createState() => _LoaderWrapperState();
}

class _LoaderWrapperState extends State<LoaderWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isLoading)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Container(
                  color: Colors.white.withOpacity(0.1),
                  child: const Center(
                    child: SpinKitFadingCube(color: Colors.deepOrange, size: 60),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}