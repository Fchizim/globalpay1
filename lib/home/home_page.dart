import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:globalpay/home/fund_wallet/fund_wallet.dart';
import 'package:globalpay/home/send_money.dart';
import 'package:intl/intl.dart';
import 'package:globalpay/home/user_page.dart';
import '../models/user_model.dart';
import '../profile_details/invite.dart';
import '../provider/balance_provider.dart';
import '../provider/user_provider.dart';
import '../qrcode_send/qrcode_send.dart' hide UserBalance;
import '../services/profile_service.dart';
import '../services/secure_storage_service.dart';
import 'airtime_page.dart';
import 'all_asset.dart';
import 'card/card_page.dart';
import 'currency_con.dart';
import 'data_page.dart';
import 'electricity.dart';
import 'finance/create_target_page.dart';
import 'finance/target_save.dart';
import 'g-tag.dart';
import 'giftcard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  // UserModel? _user;
  // bool _loadingUser = true;
  bool isRefreshing = false;
  bool _showFullFormat = false;

  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();

    // Auto-refresh every 10 seconds
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


  // Extracted refresh logic for auto-refresh
  Future<void> _refreshUserData() async {
    final localUser = await SecureStorageService.getUser();
    if (localUser != null) {
      final freshUser = await ProfileService.getProfile(localUser.userId);
      if (freshUser != null) {
        await SecureStorageService.saveUser(freshUser);
        if (mounted) {
          // Update singleton when fresh data arrives
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

    // Refresh profile after returning
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
          child: SpinKitFadingCube(
            color: Colors.deepOrange,
            size: 55,
          ),
        ),
      );
    }
    // Only set initial balance once, to keep singleton in sync
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
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Column(
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => AllAsset()));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                              Colors.deepOrange.shade500,
                              Colors.white12,
                              Colors.deepOrange.shade400
                            ]
                                : [Colors.deepOrange.shade200, Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    IconsaxPlusBold.shield_tick,
                                    color: Colors.green.shade600,
                                    size: 20,
                                  ),
                                  Text(
                                    ' Available Balance ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 22,
                                      letterSpacing: -1,
                                      color: textColor,
                                    ),
                                  ),
                                  Icon(
                                    IconsaxPlusLinear.eye,
                                    size: 20,
                                    color: hintColor,
                                  ),
                                  if (canToggle) ...[
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _showFullFormat = !_showFullFormat;
                                        });
                                      },
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
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () {
                                _navigateWithLoader(const FundWallet());
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    displayedBalance,
                                    style: TextStyle(
                                      fontSize: 37,
                                      letterSpacing: -2,
                                      fontWeight: FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Icon(
                                    IconsaxPlusLinear.add_circle,
                                    color: textColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
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
                            onTap: () => _navigateWithLoader(
                              SendMoney(
                                balance: balance,
                                image: 'assets/images/png/profile.png',
                                name: 'Recipient Name',
                                account: '1234567890',
                                bank: 'Bank Name',
                                onTransaction: (double amount) {
                                  setState(() {
                                    UserBalance.instance.balance -= amount;
                                  });
                                },
                              ),
                            ),
                            child: _buildCard(context,
                                icon: IconsaxPlusBold.bank,
                                label: "To Bank",
                                cardColor: cardColor,
                                textColor: textColor),
                          ),
                          InkWell(
                            onTap: () => _navigateWithLoader(
                              UserPage(
                                balance: balance,
                                image: 'assets/images/png/profile.png',
                                name: 'Recipient Name',
                                account: '1234567890',
                                bank: 'Bank Name',
                                onTransaction: (double amount) {
                                  setState(() {
                                    UserBalance.instance.balance -= amount;
                                  });
                                },
                              ),
                            ),
                            child: _buildCard(context,
                                icon: Icons.diversity_1,
                                label: "To User",
                                cardColor: cardColor,
                                textColor: textColor),
                          ),
                          InkWell(
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context)=> MoneyDropPage()));
                            },
                            child: _buildCard(context,
                                icon: IconsaxPlusBold.coin_1,
                                label: "G-Drop",
                                cardColor: cardColor,
                                textColor: textColor),
                          ),
                          InkWell(
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context)=> GTagPaymentPage()));
                            },
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Container(
                      height: 170,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(15),
                        ),
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
                              dotWidth: 20,
                              dotColor: hintColor,
                              activeDotColor: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),
                  _buildRecentTransactions(
                      context, cardColor, textColor, hintColor),
                  const SizedBox(height: 70),
                ],
              ),
              // if (isRefreshing)
              //   const Positioned(
              //     top: 20,
              //     left: 0,
              //     right: 0,
              //     child: Center(
              //       child: SpinKitCircle(color: Colors.deepOrange, size: 55),
              //     ),
              //   ),
            ],
          ),
        ),

      ),
    );
  }

  Widget _buildCard(BuildContext context,
      {required IconData icon,
        required String label,
        required Color cardColor,
        required Color textColor}) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 49,
            width: 49,
            decoration: BoxDecoration(
              color: Colors.deepOrange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.deepOrange, size: 25),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              )),
        ],
      ),
    );
  }

  Widget _buildPageViewRow(Color cardColor, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AirtimePage()),
            );
          },
          child: _buildSmallCard(LucideIcons.tabletSmartphone400, "Airtime", Colors.deepOrange,
              cardColor, textColor),
        ),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DataPage()),
            );
          },
          child: _buildSmallCard(IconsaxPlusBold.radar_2, "Data", Colors.deepPurple,
              cardColor, textColor),
        ),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ElectricityPage()),
            );
          },
          child: _buildSmallCard(LucideIcons.lightbulb, "Electricity",
              Colors.blueAccent, cardColor, textColor),
        ),
        InkWell(
          onTap: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => GiftCardPage()),
            );
          },
          child: _buildSmallCard(IconsaxPlusBold.ship, "Gift Card", Colors.blue.shade800,
              cardColor, textColor),
        ),
      ],
    );
  }

  Widget _buildPageViewRow2(Color cardColor, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        InkWell(
          onTap: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => InviteFriends()),
            );
          },
          child: _buildSmallCard(LucideIcons.gem, "Earn", Colors.deepOrange,
              cardColor, textColor),
        ),
        InkWell(
            onTap: (){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InviteFriends()),
              );
            },
            child: _buildSmallCard(LucideIcons.tv, "TV", Colors.deepPurple, cardColor, textColor)),
        InkWell(
          onTap: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateTargetPage()),
            );
          },
          child: _buildSmallCard(LucideIcons.target, "T-save", Colors.blueAccent, cardColor,
              textColor),
        ),
        _buildSmallCard(LucideIcons.handCoins, "Loan", Colors.blue.shade800, cardColor,
            textColor),
      ],
    );
  }

  Widget _buildSmallCard(IconData icon, String label, Color color,
      Color cardColor, Color textColor) {
    return Container(
      height: 65,
      width: 75,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
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

  Widget _buildRecentTransactions(
      BuildContext context, Color cardColor, Color textColor, Color hintColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: List.generate(notifications.length, (index) {
            final notification = notifications[index];
            final bool isReceived = notification['type'] == 'received';
            final bool isSuccessful = notification['status'] == 'successful';

            final amount = notification['amount'] ?? 0.0;
            final name = notification['name'] ?? 'Unknown';
            final time = notification['time'] ?? '';

            return Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 55,
                        width: 55,
                        decoration: BoxDecoration(
                          color: isReceived
                              ? Colors.green.withOpacity(0.15)
                              : Colors.red.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isReceived
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: isReceived ? Colors.green : Colors.red,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  color: textColor)),
                          const SizedBox(height: 3),
                          Text(time,
                              style:
                              TextStyle(fontSize: 14, color: hintColor)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSuccessful
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isSuccessful ? 'Successful' : 'Failed',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isSuccessful
                                      ? Colors.green
                                      : Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '${isReceived ? '+' : '-'}₦${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: isReceived ? Colors.green : Colors.red),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  final List<Map<String, dynamic>> notifications = [
    {
      'name': 'Henry Gomez',
      'time': '04/10/2025 . 3:00 pm',
      'amount': 1300.00,
      'type': 'sent',
      'status': 'successful'
    },
    {
      'name': 'Sophia Adams',
      'time': '05/10/2025 . 10:10 am',
      'amount': 2000.00,
      'type': 'received',
      'status': 'successful'
    },
    {
      'name': 'James Doe',
      'time': '06/10/2025 . 11:20 am',
      'amount': 500.00,
      'type': 'sent',
      'status': 'failed'
    },
  ];
}

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
                    child: SpinKitFadingCube(
                      color: Colors.deepOrange,
                      size: 60,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}