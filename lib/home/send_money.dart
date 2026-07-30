import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'amount_send.dart';
import 'withdrawal_service.dart';

class SendMoney extends StatefulWidget {
  final double balance;
  final Function(double) onTransaction;
  final String userId;

  const SendMoney({
    super.key,
    required this.balance,
    required this.onTransaction,
    required this.userId,
  });

  @override
  State<SendMoney> createState() => _SendMoneyState();
}

class _SendMoneyState extends State<SendMoney> {
  final TextEditingController _accountController = TextEditingController();

  // ── Banks: fetched from the backend ───────────────────────────────────
  List<BankOption> banks = [];
  bool bankListLoading = true;
  String? bankListError;
  BankOption? selectedBank;

  // ── Account verification state ────────────────────────────────────────
  String? verifiedAccountName;
  bool verifying = false;
  String? verifyError;
  Timer? _debounce;

  // ── Recent + Favorites: fetched from the backend ──────────────────────
  List<RecipientInfo> recentRecipients = [];
  bool recentLoading = true;
  String? recentError;

  List<RecipientInfo> favoriteRecipients = [];
  bool favoritesLoading = true;
  String? favoritesError;

  // Keys ("accountNumber|bankCode") currently favorited, so both the
  // Recent and Favorites tiles can show the correct heart state.
  Set<String> favoriteKeys = {};

  @override
  void initState() {
    super.initState();
    _loadBanks();
    _loadRecent();
    _loadFavorites();
    _accountController.addListener(_onAccountChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _loadBanks() async {
    setState(() {
      bankListLoading = true;
      bankListError = null;
    });
    try {
      final result = await WithdrawalService.getBanks();
      if (!mounted) return;
      setState(() => banks = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => bankListError = 'Could not load banks. Check your connection.');
    } finally {
      if (mounted) setState(() => bankListLoading = false);
    }
  }

  Future<void> _loadRecent() async {
    setState(() {
      recentLoading = true;
      recentError = null;
    });
    try {
      final result = await WithdrawalService.getRecentRecipients(widget.userId);
      if (!mounted) return;
      setState(() => recentRecipients = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => recentError = 'Could not load recent transfers.');
    } finally {
      if (mounted) setState(() => recentLoading = false);
    }
  }

  Future<void> _loadFavorites() async {
    setState(() {
      favoritesLoading = true;
      favoritesError = null;
    });
    try {
      final result = await WithdrawalService.getFavoriteRecipients(widget.userId);
      if (!mounted) return;
      setState(() {
        favoriteRecipients = result;
        favoriteKeys = result.map((r) => r.key).toSet();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => favoritesError = 'Could not load favorites.');
    } finally {
      if (mounted) setState(() => favoritesLoading = false);
    }
  }

  Future<void> _toggleFavorite(RecipientInfo r) async {
    // Optimistic update so the heart responds instantly.
    final wasFavorite = favoriteKeys.contains(r.key);
    setState(() {
      if (wasFavorite) {
        favoriteKeys.remove(r.key);
      } else {
        favoriteKeys.add(r.key);
      }
    });

    try {
      final isFavoriteNow = await WithdrawalService.toggleFavorite(
        userId: widget.userId,
        recipient: r,
      );
      if (!mounted) return;
      // Re-sync the actual favorites list with the backend's truth.
      if (isFavoriteNow) {
        if (!favoriteRecipients.any((f) => f.key == r.key)) {
          setState(() => favoriteRecipients = [...favoriteRecipients, r]);
        }
      } else {
        setState(() =>
        favoriteRecipients = favoriteRecipients.where((f) => f.key != r.key).toList());
      }
    } catch (e) {
      // Roll back the optimistic update on failure.
      if (!mounted) return;
      setState(() {
        if (wasFavorite) {
          favoriteKeys.add(r.key);
        } else {
          favoriteKeys.remove(r.key);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update favorite. Try again.")),
      );
    }
  }

  // ── Re-verify whenever a full 10-digit account number + bank are present ──
  void _onAccountChanged() {
    setState(() {
      verifiedAccountName = null;
      verifyError = null;
    });
    _debounce?.cancel();
    final digits = _accountController.text.trim();
    if (digits.length != 10 || selectedBank == null) return;

    _debounce = Timer(const Duration(milliseconds: 500), () => _verifyAccount());
  }

  Future<void> _verifyAccount() async {
    if (selectedBank == null || _accountController.text.trim().length != 10) return;
    setState(() {
      verifying = true;
      verifyError = null;
    });
    try {
      final name = await WithdrawalService.verifyAccount(
        accountNumber: _accountController.text.trim(),
        bankCode: selectedBank!.code,
      );
      if (!mounted) return;
      setState(() => verifiedAccountName = name);
    } catch (e) {
      if (!mounted) return;
      setState(() => verifyError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => verifying = false);
    }
  }

  // ── Prefill the form from a tapped Recent/Favorite tile ───────────────
  void _selectRecipient(RecipientInfo r) {
    FocusManager.instance.primaryFocus?.unfocus();
    final match = banks.firstWhere(
          (b) => b.code == r.bankCode,
      orElse: () => BankOption(name: r.bankName, code: r.bankCode),
    );
    setState(() {
      selectedBank = match;
      _accountController.text = r.accountNumber;
      // Trust the previously-verified name rather than re-hitting Paystack —
      // details for an existing recipient don't change.
      verifiedAccountName = r.accountName;
      verifyError = null;
      verifying = false;
    });
  }

  void _goNext() {
    if (_accountController.text.trim().length != 10 || selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid account number and select a bank")),
      );
      return;
    }
    if (verifiedAccountName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(verifying
            ? "Still verifying the account, please wait"
            : "Please wait for account verification to complete")),
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
          bank: selectedBank!.name,
          balance: widget.balance,
          onTransaction: widget.onTransaction,
          // NOTE: AmountSend needs to accept these two additional params
          // (bankCode + the verified account holder name) and pass them
          // through to WithdrawalService.withdraw(...) — see chat notes,
          // since that file wasn't shared here yet.
          // bankCode: selectedBank!.code,
          // accountName: verifiedAccountName!,
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
                        maxLength: 10,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          counterText: '',
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
                      const SizedBox(height: 8),

                      // ── Verification status ──
                      if (verifying)
                        Row(children: [
                          const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text('Verifying account...',
                              style: TextStyle(color: subTextColor, fontSize: 12)),
                        ])
                      else if (verifiedAccountName != null)
                        Row(children: [
                          const Icon(Icons.check_circle,
                              color: Color(0xFF22C55E), size: 15),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(verifiedAccountName!,
                                style: const TextStyle(
                                    color: Color(0xFF22C55E),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ),
                        ])
                      else if (verifyError != null)
                          Text(verifyError!,
                              style: const TextStyle(color: Colors.red, fontSize: 12)),

                      const SizedBox(height: 12),

                      /// BANK DROPDOWN
                      if (bankListError != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(children: [
                            Expanded(
                                child: Text(bankListError!,
                                    style: const TextStyle(color: Colors.red, fontSize: 12))),
                            TextButton(onPressed: _loadBanks, child: const Text('Retry')),
                          ]),
                        )
                      else
                        DropdownSearch<BankOption>(
                          enabled: !bankListLoading,
                          items: banks,
                          selectedItem: selectedBank,
                          itemAsString: (b) => b.name,
                          compareFn: (a, b) => a.code == b.code,

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
                              prefixIcon: bankListLoading
                                  ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                                  : Icon(IconsaxPlusBold.bank, color: accentColor),
                              hintText: bankListLoading ? 'Loading banks...' : 'Select bank',
                              filled: true,
                              fillColor: isDark ? const Color(0xFF202020) : Colors.grey.shade100,
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
                            setState(() {
                              selectedBank = value;
                              verifiedAccountName = null;
                              verifyError = null;
                            });
                            if (_accountController.text.trim().length == 10) {
                              _verifyAccount();
                            }
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
                                color: Colors.white,
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
            _buildRecentSection(cardColor, textColor, subTextColor, accentColor),

            const SizedBox(height: 20),

            /// ================= FAVORITES =================
            _sectionHeader("Favorites", textColor, subTextColor, () {}),
            _buildFavoritesSection(cardColor, textColor, subTextColor, accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSection(
      Color cardColor, Color textColor, Color subTextColor, Color accent) {
    if (recentLoading) {
      return const SizedBox(
        height: 110,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (recentError != null) {
      return SizedBox(
        height: 60,
        child: Row(children: [
          Expanded(
              child: Text(recentError!,
                  style: TextStyle(color: subTextColor, fontSize: 13))),
          TextButton(onPressed: _loadRecent, child: const Text('Retry')),
        ]),
      );
    }
    if (recentRecipients.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('No recent transfers yet.',
            style: TextStyle(color: subTextColor, fontSize: 13)),
      );
    }
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recentRecipients.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final r = recentRecipients[i];
          return _quickTile(r, cardColor, textColor, subTextColor);
        },
      ),
    );
  }

  Widget _buildFavoritesSection(
      Color cardColor, Color textColor, Color subTextColor, Color accent) {
    if (favoritesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (favoritesError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          Expanded(
              child: Text(favoritesError!,
                  style: TextStyle(color: subTextColor, fontSize: 13))),
          TextButton(onPressed: _loadFavorites, child: const Text('Retry')),
        ]),
      );
    }
    if (favoriteRecipients.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('No favorites yet — tap the heart on any recipient to save it.',
            style: TextStyle(color: subTextColor, fontSize: 13)),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: favoriteRecipients.length,
      itemBuilder: (_, i) {
        final r = favoriteRecipients[i];
        return _favoriteTile(r, cardColor, textColor, subTextColor, accent);
      },
    );
  }

  Widget _initialsAvatar(String label, {double radius = 22}) {
    final initial = label.isNotEmpty ? label[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.deepOrange.withOpacity(0.12),
      child: Text(initial,
          style: TextStyle(
              color: Colors.deepOrange,
              fontWeight: FontWeight.bold,
              fontSize: radius * 0.7)),
    );
  }

  Widget _quickTile(RecipientInfo r, Color card, Color text, Color sub) {
    final isFav = favoriteKeys.contains(r.key);
    return GestureDetector(
      onTap: () => _selectRecipient(r),
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(10),
        decoration:
        BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            _initialsAvatar(r.bankName),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.accountName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: text, fontWeight: FontWeight.w600)),
                  Text(r.accountNumber, style: TextStyle(color: sub, fontSize: 12)),
                  Text(r.bankName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: sub, fontSize: 11)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _toggleFavorite(r),
              child: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                size: 18,
                color: isFav ? Colors.deepOrange : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _favoriteTile(
      RecipientInfo r, Color card, Color text, Color sub, Color accent) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration:
      BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: () => _selectRecipient(r),
        leading: _initialsAvatar(r.bankName, radius: 23),
        title: Text(r.accountName,
            style: TextStyle(color: text, fontWeight: FontWeight.w600)),
        subtitle: Text('${r.accountNumber} · ${r.bankName}',
            style: TextStyle(color: sub)),
        trailing: IconButton(
          icon: const Icon(Icons.favorite, color: Colors.deepOrange),
          onPressed: () => _toggleFavorite(r),
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