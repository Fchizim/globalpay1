import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'amount_send.dart';

class UserPage extends StatefulWidget {
  final double balance;
  final Function(double) onTransaction;

  const UserPage({
    super.key,
    required this.balance,
    required this.onTransaction,
    required String image,
    required String name,
    required String account,
    required String bank,
  });

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  List<bool> favoriteStates = [];

  final List<Map<String, String>> recentTransactions = [
    {
      'image': 'assets/images/png/boa.jpeg',
      'name': 'James Anderson',
      'account': '223-655-8830',
      'date': 'Aug 13, 2025',
      'bank': 'GlobalPay',
    },
    {
      'image': 'assets/images/png/paypal.jpeg',
      'name': 'Maria Smith',
      'account': '987-123-4567',
      'date': 'Aug 12, 2025',
      'bank': 'GlobalPay',
    },
  ];

  final List<Map<String, String>> favoriteContacts = [
    {
      'image': 'assets/images/png/boa.jpeg',
      'name': 'James Anderson',
      'account': '223-655-8830',
      'bank': 'GlobalPay',
    },
    {
      'image': 'assets/images/png/paypal.jpeg',
      'name': 'Maria Smith',
      'account': '987-123-4567',
      'bank': 'GlobalPay',
    },
    {
      'image': 'assets/images/png/boa.jpeg',
      'name': 'Chris Evans',
      'account': '543-111-2222',
      'bank': 'GlobalPay',
    },
    {
      'image': 'assets/images/png/paypal.jpeg',
      'name': 'Emma Johnson',
      'account': '765-888-9999',
      'bank': 'GlobalPay',
    },
    {
      'image': 'assets/images/png/boa.jpeg',
      'name': 'Oliver Brown',
      'account': '123-444-5555',
      'bank': 'GlobalPay',
    },
    {
      'image': 'assets/images/png/paypal.jpeg',
      'name': 'Sophia Miller',
      'account': '888-222-7777',
      'bank': 'GlobalPay',
    },
  ];

  @override
  void initState() {
    super.initState();
    favoriteStates = List<bool>.filled(
      favoriteContacts.length,
      true,
      growable: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey.shade100;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white38 : Colors.grey.shade600;
    final hintColor = isDark ? Colors.white54 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Transfer to GlobalPay",
          style: TextStyle(color: textColor),
        ),
        backgroundColor: bgColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// To Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 15,
                        top: 15,
                        bottom: 5,
                      ),
                      child: Text(
                        'To',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    /// Account Number Field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: TextField(
                        cursorColor: Colors.deepOrange,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: '   Enter account number',
                          hintStyle: TextStyle(color: hintColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Colors.deepOrange,
                            ),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    /// GlobalPay Tag Field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          cursorColor: Colors.deepOrange,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 20),
                              child: Icon(
                                IconsaxPlusBold.user,
                                color: Colors.deepOrange,
                                size: 27,
                              ),
                            ),
                            hintText: '  Global Pay – All Your Assets, Anytime',
                            hintStyle: TextStyle(color: hintColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                color: Colors.deepOrange,
                              ),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AmountSend(
                                  image: 'image',
                                  name: 'name',
                                  account: 'account',
                                  bank: 'bank',
                                  balance: widget.balance,
                                  onTransaction: (double amountDeducted) {
                                    widget.onTransaction(amountDeducted);
                                  },
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Next',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    colors: [Colors.deepOrange, Colors.orangeAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Text(
                  '⚡ Instant, Zero-Issue Transactions',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            /// Recent Section
            _sectionHeader('Recent', () {}, textColor, subTextColor),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: recentTransactions.length,
                itemBuilder: (context, index) {
                  final tx = recentTransactions[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AmountSend(
                            image: tx['image']!,
                            name: tx['name']!,
                            account: tx['account']!,
                            bank: tx['bank']!,
                            balance: widget.balance,
                            onTransaction: widget.onTransaction,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: AssetImage(tx['image']!),
                            radius: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  tx['name']!,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  tx['account']!,
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  tx['date']!,
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            /// Favorites Section
            _sectionHeader('Favorites', () {}, textColor, subTextColor),
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  child: Column(
                    children: List.generate(favoriteContacts.length.clamp(0, 6), (
                      index,
                    ) {
                      final fav = favoriteContacts[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AmountSend(
                                image: fav['image']!,
                                name: fav['name']!,
                                account: fav['account']!,
                                bank: fav['bank']!,
                                balance: widget.balance,
                                onTransaction: widget.onTransaction,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: isDark
                                ? LinearGradient(
                                    colors: [
                                      Colors.grey.shade900,
                                      Colors.grey.shade800,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [
                                      Colors.grey.shade200,
                                      Colors.grey.shade100,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
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
                              CircleAvatar(
                                backgroundImage: AssetImage(fav['image']!),
                                radius: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      fav['name']!,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      fav['account']!,
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    favoriteStates[index] =
                                        !favoriteStates[index];
                                  });
                                },
                                child: Icon(
                                  Icons.favorite,
                                  color: favoriteStates[index]
                                      ? Colors.deepOrange
                                      : subTextColor,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      // bottomNavigationBar: Padding(
      //   padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
      //   child: SizedBox(
      //     height: 50,
      //     width: double.infinity,
      //     child: ElevatedButton(
      //       style: ElevatedButton.styleFrom(
      //         backgroundColor: Colors.deepOrange,
      //         shape: RoundedRectangleBorder(
      //           borderRadius: BorderRadius.circular(10),
      //         ),
      //       ),
      //       onPressed: () {},
      //       child: const Text(
      //         'Next',
      //         style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
      //       ),
      //     ),
      //   ),
      // ),
    );
  }

  Widget _sectionHeader(
    String title,
    VoidCallback onViewAll,
    Color textColor,
    Color subTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 21,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              children: [
                Text('View All', style: TextStyle(color: subTextColor)),
                const SizedBox(width: 3),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: subTextColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
