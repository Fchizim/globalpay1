import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'airtime_successful_page.dart';
import 'fund_wallet/fund_wallet.dart';

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> with TickerProviderStateMixin {
  late TabController tabController;
  final phoneController = TextEditingController();

  final banners = [
    'assets/images/png/oppp.PNG',
    'assets/images/png/ooopJPG.JPG',
  ];

  final List<Map<String, String>> networks = [
    {'name': 'MTN', 'logo': 'assets/images/png/mtn.jpeg'},
    {'name': 'Airtel', 'logo': 'assets/images/png/airtel.jpeg'},
    {'name': 'Glo', 'logo': 'assets/images/png/glo.jpeg'},
    {'name': '9Mobile', 'logo': 'assets/images/png/9mobile.jpeg'},
  ];

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  /// PIN SHEET
  void _showPinBottomSheet({
    required void Function(String pin) onConfirmed,
    int? customAmount,
  }) {
    final controllers =
    List.generate(4, (_) => TextEditingController());
    final nodes = List.generate(4, (_) => FocusNode());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Input PIN',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),
                Text(
                  '₦260.00',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (i) {
                    return SizedBox(
                      width: 55,
                      child: TextField(
                        controller: controllers[i],
                        focusNode: nodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        decoration: const InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) async {
                          if (v.isNotEmpty) {
                            if (i < 3) {
                              FocusScope.of(sheetCtx)
                                  .requestFocus(nodes[i + 1]);
                            } else {
                              await Future.delayed(
                                  const Duration(milliseconds: 100));

                              final pin =
                              controllers.map((e) => e.text).join();

                              Navigator.pop(sheetCtx);
                              onConfirmed(pin);

                              if (mounted) {
                                final phone = phoneController.text.trim();
                                final amount = (customAmount ?? 0);

                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => AirtimeSuccessScreen(
                                      amount: amount,
                                      network:
                                      networks[selectedIndex]['name']!,
                                      phone: phone,
                                    ),
                                  ),
                                );
                              }
                            }
                          } else if (i > 0) {
                            FocusScope.of(sheetCtx)
                                .requestFocus(nodes[i - 1]);
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(sheetCtx).pop();
                    _showSnack('Forgot PIN tapped');
                  },
                  child: const Text('Forgot PIN?'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) FocusScope.of(context).requestFocus(nodes.first);
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFFFBFA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final tabBar = isDark ? Colors.grey.shade500 : Colors.black54;

    final primary = Colors.deepOrange;

    final selectedNetworkName = networks[selectedIndex]['name']!;
    final selectedNetworkLogo = networks[selectedIndex]['logo']!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Mobile Data',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'History',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// BANNER
            CarouselSlider(
              items: banners
                  .map(
                    (path) => ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(path, fit: BoxFit.cover, width: 1000),
                ),
              )
                  .toList(),
              options: CarouselOptions(
                height: 100,
                autoPlay: true,
                viewportFraction: 0.9,
                enlargeCenterPage: true,
              ),
            ),
            const SizedBox(height: 10),

            /// NETWORK + PHONE
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      dropdownColor: cardColor,
                      value: selectedIndex,
                      items: List.generate(networks.length, (index) {
                        final net = networks[index];
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 17,
                                backgroundImage: AssetImage(net['logo']!),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                net['name']!,
                                style: TextStyle(fontSize: 12, color: textColor),
                              ),
                            ],
                          ),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedIndex = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      style: TextStyle(color: textColor),
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Enter mobile number',
                        hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// TABS + GRID
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 36,
                        child: TabBar(
                          controller: tabController,
                          isScrollable: true,
                          labelColor: primary,
                          unselectedLabelColor: tabBar,
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'HOT'),
                            Tab(text: 'Daily'),
                            Tab(text: 'Weekly'),
                            Tab(text: 'Monthly'),
                            Tab(text: 'XtraValue'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TabBarView(
                          controller: tabController,
                          children: List.generate(
                            5,
                                (index) => GridView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: 8,
                              gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 0.85,
                              ),
                              itemBuilder: (context, i) {
                                return GestureDetector(
                                  onTap: () {
                                    _showConfirmSheet(
                                      context,
                                      biller: '$selectedNetworkName Data Bundle',
                                      logo: selectedNetworkLogo,
                                      plan: '500MB',
                                      duration: '1 Day',
                                      recipient: phoneController.text,
                                      price: 150,
                                      oldPrice: 200,
                                    );
                                  },
                                  child: _planCard(),
                                );
                              },
                            ),
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
      ),
    );
  }

  Widget _planCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            '500MB',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: textColor),
          ),
          Text('1 Day', style: TextStyle(color: textColor.withOpacity(0.6))),
          const Spacer(),
          Text(
            '₦350',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textColor),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  /// MODAL WITH PAYMENT METHODS
  void _showConfirmSheet(
      BuildContext context, {
        required String biller,
        required String logo,
        required String plan,
        required String duration,
        required String recipient,
        required int price,
        required int oldPrice,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = Colors.deepOrange;

    final sheetColor = isDark ? const Color(0xFF1C1C1C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subText = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final paymentBg = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            runSpacing: 12,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: subText,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Data Purchase',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '₦$price.00',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),

              /// BILLER
              ListTile(
                leading: CircleAvatar(backgroundImage: AssetImage(logo)),
                title: Text(
                  biller,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                ),
                subtitle: Text('$plan - $duration Plan', style: TextStyle(color: subText)),
              ),

              /// RECIPIENT
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: primary.withOpacity(0.15),
                  child: Icon(Icons.phone_iphone, color: primary, size: 20),
                ),
                title: Text('Recipient Mobile', style: TextStyle(color: textColor)),
                subtitle: Text(recipient.isEmpty ? 'Not entered' : recipient, style: TextStyle(color: subText)),
              ),

              ListTile(
                leading: CircleAvatar(
                  backgroundColor: primary.withOpacity(0.15),
                  child: Icon(Icons.wallet, color: primary, size: 20),
                ),
                title: Row(
                  children: [
                    Text('Balance', style: TextStyle(color: textColor)),
                    const SizedBox(width: 10),
                    const Icon(Icons.remove_red_eye_outlined, color: Colors.grey, size: 22),
                  ],
                ),
                subtitle: const Text('(₦0.00)', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ),

              /// PAYMENT METHODS
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: paymentBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Method',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.account_balance_wallet, size: 16),
                            label: const Text('Balance', style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(38),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Money', style: TextStyle(fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(38),
                              side: BorderSide(color: primary),
                              foregroundColor: primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => FundWallet()));
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              /// CONFIRM BUTTON
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(sheetCtx).pop();
                    _showPinBottomSheet(onConfirmed: (pin) {});
                  },
                  child: const Text(
                    'Confirm Purchase',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        );
      },
    );
  }
}