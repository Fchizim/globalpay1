import 'dart:async';
import 'package:flutter/material.dart';

class Provider {
  final String name;
  final String logo;
  bool isSelected;

  Provider({required this.name, required this.logo, this.isSelected = false});
}

class ElectricityPage extends StatefulWidget {
  const ElectricityPage({super.key});

  @override
  State<ElectricityPage> createState() => _ElectricityPageState();
}

class _ElectricityPageState extends State<ElectricityPage> {
  final TextEditingController meterController = TextEditingController();
  final TextEditingController customAmountController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  String billType = 'Prepaid';
  int selectedAmount = 1000;
  bool showProviders = false;

  List<Provider> providers = [
    Provider(name: 'Ibadan Electricity', logo: 'assets/images/png/ibedc.png'),
    Provider(name: 'Jos Electricity', logo: 'assets/images/png/jos.png'),
    Provider(name: 'Ikeja Electricity', logo: 'assets/images/png/ikeja.png'),
    Provider(name: 'Port Harcourt Electricity', logo: 'assets/images/png/portharcourt.JPG'),
    Provider(name: 'Kaduna Electricity', logo: 'assets/images/png/kaduna.JPG'),
    Provider(name: 'Abuja Electricity', logo: 'assets/images/png/abuja.jpg'),
    Provider(name: 'Eko Electricity', logo: 'assets/images/png/eko.JPG'),
    Provider(name: 'Enugu Electricity', logo: 'assets/images/png/enugu.JPG', isSelected: true),
    Provider(name: 'Kano Electricity', logo: 'assets/images/png/kano.JPG'),
    Provider(name: 'Benin Electricity', logo: 'assets/images/png/benin.jpg'),
    Provider(name: 'Yola Electricity', logo: 'assets/images/png/yola.JPG'),
    Provider(name: 'Aba Electricity', logo: 'assets/images/png/aba.PNG'),
  ];

  List<Provider> filteredProviders = [];
  final List<int> amounts = [1000, 2000, 3000, 5000, 10000, 20000];

  final PageController _bannerController = PageController();
  int _currentBanner = 0;
  late Timer _bannerTimer;

  @override
  void initState() {
    super.initState();
    filteredProviders = List.from(providers);

    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_bannerController.hasClients) {
        _currentBanner = (_currentBanner + 1) % 2;
        _bannerController.animateToPage(
          _currentBanner,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _bannerTimer.cancel();
    super.dispose();
  }

  void filterProviders(String query) {
    setState(() {
      filteredProviders = providers
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey.shade100;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final fillColor = isDark ? Colors.grey[850]! : Colors.grey[100]!;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey[700]!;

    Provider? selectedProvider = providers.firstWhere(
          (p) => p.isSelected,
      orElse: () => providers.first,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text('Electricity', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider selector
            GestureDetector(
              onTap: () => setState(() => showProviders = !showProviders),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (selectedProvider.logo.isNotEmpty)
                          CircleAvatar(
                            backgroundImage: AssetImage(selectedProvider.logo),
                            radius: 22,
                            backgroundColor: Colors.transparent,
                          ),
                        if (selectedProvider.logo.isNotEmpty) const SizedBox(width: 12),
                        Text(selectedProvider.name,
                            style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 16)),
                      ],
                    ),
                    Icon(
                      showProviders ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: secondaryTextColor,
                      size: 28,
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TextField(
                        controller: searchController,
                        onChanged: filterProviders,
                        decoration: InputDecoration(
                          hintText: 'Search Provider',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: fillColor,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredProviders.length,
                        itemBuilder: (context, index) {
                          Provider provider = filteredProviders[index];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                for (var p in providers) p.isSelected = false;
                                provider.isSelected = true;
                                showProviders = false;
                                searchController.clear();
                                filteredProviders = List.from(providers);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                color: provider.isSelected
                                    ? Colors.deepOrange.withOpacity(0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: AssetImage(provider.logo),
                                    radius: 20,
                                    backgroundColor: Colors.transparent,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(provider.name,
                                        style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15)),
                                  ),
                                  Icon(
                                    provider.isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                    color: provider.isSelected ? Colors.deepOrange : secondaryTextColor,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: showProviders ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
            const SizedBox(height: 24),
            // Banner slider
            SizedBox(
              height: 120,
              child: PageView(
                controller: _bannerController,
                children: [
                  _bannerWidget('assets/images/png/slide1.PNG'),
                  _bannerWidget('assets/images/png/slide2.JPG'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Meter input + Prepaid/Postpaid + Amount container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meter input
                  TextField(
                    controller: meterController,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Enter Meter / Account Number',
                      labelStyle: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w500),
                      filled: true,
                      fillColor: fillColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Prepaid/Postpaid with tick
                  Row(
                    children: ['Prepaid', 'Postpaid'].map((type) {
                      bool isSelected = billType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => billType = type);
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                      colors: [Colors.deepOrange, Colors.orangeAccent],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight)
                                      : null,
                                  color: isSelected ? null : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: isSelected
                                      ? [
                                    BoxShadow(
                                      color: Colors.deepOrange.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                      : [],
                                  border: Border.all(
                                      color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
                                      width: 1.5),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : secondaryTextColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  top: 4,
                                  right: 8,
                                  child: Icon(
                                    Icons.check_circle, // replace with IconsaxPlusBold.tick_circle if using package
                                    color: Colors.white,
                                    size: 25,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Amount selection container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: amounts.map((amount) {
                            bool isSelected = selectedAmount == amount;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedAmount = amount;
                                  customAmountController.text = '';
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 100,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.deepOrange : cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: isSelected
                                      ? [
                                    BoxShadow(
                                        color: Colors.deepOrange.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 4))
                                  ]
                                      : [],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '₦$amount',
                                  style: TextStyle(
                                      color: isSelected ? Colors.white : secondaryTextColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: customAmountController,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            int? val = int.tryParse(value);
                            if (val != null) selectedAmount = val;
                          },
                          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            labelText: 'Enter Custom Amount',
                            labelStyle: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w500),
                            filled: true,
                            fillColor: fillColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Pay button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        shadowColor: Colors.deepOrangeAccent,
                        elevation: 6,
                      ),
                      child: Text('Pay ₦$selectedAmount',
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bannerWidget(String imagePath) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
