import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> with TickerProviderStateMixin {
  late TabController tabController;
  final phoneController = TextEditingController();

  // Local banners
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFFFBFA) ;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    final primary = Colors.deepOrange;
    final selectedNetworkName = networks[selectedIndex]['name']!;
    final selectedNetworkLogo = networks[selectedIndex]['logo']!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Mobile Data',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
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

            // Banner slider
            CarouselSlider(
              items: banners
                  .map(
                    (path) => ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    path,
                    fit: BoxFit.cover,
                    width: 1000,
                  ),
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

            // Network + Phone
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // dropdown
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
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
                              Text(net['name']!,
                                  style: const TextStyle(fontSize: 12)),
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
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'Enter mobile number',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.deepOrange.shade50,
                      ),
                      child: Icon(Icons.person, color: Colors.deepOrange[600]),
                    ),
                  ),
                ],
              ),
            ),

            // TabBar + Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 15, right: 15),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      // Tab bar
                      SizedBox(
                        height: 36,
                        child: TabBar(
                          controller: tabController,
                          isScrollable: true,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelColor: primary,
                          unselectedLabelColor: Colors.black54,
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
                          children: List.generate(5, (index) {
                            return GridView.builder(
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
                                      biller:
                                      '$selectedNetworkName Data Bundle',
                                      logo: selectedNetworkLogo,
                                      plan: '500MB',
                                      duration: '1 Day',
                                      recipient: phoneController.text,
                                      price: 150,
                                      oldPrice: 200,
                                    );
                                  },
                                  child: _planCard(primary),
                                );
                              },
                            );
                          }),
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

  Widget _planCard(Color primary) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Color(0xFFFFFBFA);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('500MB',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text('1 Day', style: TextStyle(color: Colors.black54, fontSize: 11)),
          Spacer(),
          Text('₦150',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

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
    final primary = Colors.deepOrange;
    bool cashback = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
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
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Confirm Purchase',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  // Biller
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: AssetImage(logo),
                      radius: 20,
                    ),
                    title: Text(
                      biller,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('$plan - $duration'),
                  ),
                  // Recipient
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primary.withOpacity(0.1),
                      child: Icon(Icons.phone_iphone,
                          color: primary, size: 20),
                    ),
                    title: const Text('Recipient Mobile'),
                    subtitle:
                    Text(recipient.isEmpty ? 'Not entered' : recipient),
                  ),
                  // Cashback toggle
                  SwitchListTile(
                    activeThumbColor: primary,
                    value: cashback,
                    onChanged: (val) {
                      setStateSheet(() => cashback = val);
                    },
                    title: const Text('Use Cashback'),
                    subtitle: const Text('Earn cashback on this purchase'),
                  ),
                  // Price
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primary.withOpacity(0.1),
                      child: Icon(Icons.star, color: primary, size: 20),
                    ),
                    title: const Text('GPay Points'),
                    subtitle:
                    const Text('Earn 5 points on this purchase'),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₦$price',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '₦$oldPrice',
                          style: const TextStyle(
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Payment method
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Method',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.account_balance_wallet,
                                    size: 16),
                                label: const Text('Balance',
                                    style: TextStyle(fontSize: 13)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  minimumSize: const Size.fromHeight(38),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {},
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Money',
                                    style: TextStyle(fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(38),
                                  side: BorderSide(color: primary),
                                  foregroundColor: primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {},
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.account_balance,
                                    size: 16),
                                label: const Text('Add Bank',
                                    style: TextStyle(fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(38),
                                  side: BorderSide(color: primary),
                                  foregroundColor: primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        // handle purchase
                      },
                      child: const Text(
                        'Confirm Purchase',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
