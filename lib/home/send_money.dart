import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'amount_send.dart';

class SendMoney extends StatefulWidget {
  final double balance;
  final Function(double) onTransaction;

  const SendMoney({
    super.key,
    required this.balance,
    required this.onTransaction,
    required String bank,
    required String account,
    required String name,
    required String image,
  });

  @override
  State<SendMoney> createState() => _SendMoneyState();
}

class _SendMoneyState extends State<SendMoney> {
  final TextEditingController _accountController = TextEditingController();

  List<bool> favoriteStates = [];
  String? selectedBank;

  final List<Map<String, String>> recentTransactions = [
    {
      'image': 'assets/images/png/boa.jpeg',
      'name': 'James Anderson',
      'account': '223-655-8830',
      'date': 'Aug 13, 2025',
      'bank': 'Chase Bank',
    },
    {
      'image': 'assets/images/png/paypal.jpeg',
      'name': 'Maria Smith',
      'account': '987-123-4567',
      'date': 'Aug 12, 2025',
      'bank': 'PayPal',
    },
  ];

  final List<Map<String, String>> favoriteContacts = [
    {
      'image': 'assets/images/png/boa.jpeg',
      'name': 'James Anderson',
      'account': '223-655-8830',
      'bank': 'Chase Bank',
    },
    {
      'image': 'assets/images/png/paypal.jpeg',
      'name': 'Maria Smith',
      'account': '987-123-4567',
      'bank': 'PayPal',
    },
  ];

  final List<String> banks = [
    "Chase Bank",
    "Bank of America",
    "PayPal",
    "Citi Bank",
    "Wells Fargo",
  ];

  @override
  void initState() {
    super.initState();
    favoriteStates = List<bool>.filled(favoriteContacts.length, true);
  }

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_accountController.text.isEmpty || selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter account number and select bank")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AmountSend(
          image: 'assets/images/png/bank.png',
          name: 'Bank Transfer',
          account: _accountController.text.trim(),
          bank: selectedBank!,
          balance: widget.balance,
          onTransaction: widget.onTransaction,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
    isDark ? const Color(0xFF121212) : const Color(0xFFFFFBFA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final subTextColor = isDark ? Colors.white38 : Colors.grey.shade600;
    final accentColor = Colors.deepOrange;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Send to Bank"),
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ================= RECIPIENT =================
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Recipient Details",
                          style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),

                      /// ACCOUNT NUMBER
                      TextField(
                        controller: _accountController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          prefixIcon: Icon(IconsaxPlusBold.user_tag,
                              color: accentColor),
                          hintText: 'Account number',
                          hintStyle: TextStyle(color: subTextColor),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF202020)
                              : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      /// BANK DROPDOWN
                      DropdownSearch<String>(
                        items: banks,
                        selectedItem: selectedBank,

                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              hintText: 'Search bank...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            prefixIcon: Icon(
                              IconsaxPlusBold.bank,
                              color: accentColor,
                            ),
                            hintText: 'Select bank',
                            filled: true,
                            fillColor:
                            isDark ? const Color(0xFF202020) : Colors.grey.shade100,
                            contentPadding:
                            const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: accentColor, width: 1.5),
                            ),
                          ),
                        ),

                        onChanged: (value) {
                          setState(() => selectedBank = value);
                        },
                      ),




                      const SizedBox(height: 18),

                      /// NEXT
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _goNext,
                          child: const Text(
                            "Next",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            /// ================= RECENT =================
            _sectionHeader("Recent", textColor, subTextColor, () {}),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recentTransactions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final tx = recentTransactions[i];
                  return _quickTile(tx, cardColor, textColor, subTextColor);
                },
              ),
            ),

            const SizedBox(height: 20),

            /// ================= FAVORITES =================
            _sectionHeader("Favorites", textColor, subTextColor, () {}),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: favoriteContacts.length,
              itemBuilder: (_, i) {
                final fav = favoriteContacts[i];
                return _favoriteTile(
                    fav, i, cardColor, textColor, subTextColor, accentColor);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickTile(Map<String, String> tx, Color card, Color text,
      Color sub) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(10),
      decoration:
      BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          CircleAvatar(backgroundImage: AssetImage(tx['image']!), radius: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['name']!,
                    style: TextStyle(color: text, fontWeight: FontWeight.w600)),
                Text(tx['account']!, style: TextStyle(color: sub)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _favoriteTile(Map<String, String> fav, int index, Color card,
      Color text, Color sub, Color accent) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration:
      BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading:
        CircleAvatar(backgroundImage: AssetImage(fav['image']!), radius: 23),
        title: Text(fav['name']!,
            style: TextStyle(color: text, fontWeight: FontWeight.w600)),
        subtitle: Text(fav['account']!, style: TextStyle(color: sub)),
        trailing: IconButton(
          icon: Icon(
            favoriteStates[index] ? Icons.favorite : Icons.favorite_border,
            color: favoriteStates[index] ? accent : Colors.grey,
          ),
          onPressed: () =>
              setState(() => favoriteStates[index] = !favoriteStates[index]),
        ),
      ),
    );
  }

  Widget _sectionHeader(
      String title, Color text, Color sub, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
              TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.w600)),
          GestureDetector(
            onTap: onTap,
            child: Text("View All", style: TextStyle(color: sub)),
          ),
        ],
      ),
    );
  }
}

class AllItemsPage extends StatelessWidget {
  final String title;
  final bool isDark;

  const AllItemsPage({super.key, required this.title, this.isDark = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
        isDark ? const Color(0xFF121212) : Colors.grey.shade100,
        title: Text(title),
      ),
      body: const Center(child: Text("List of all items goes here")),
    );
  }
}
