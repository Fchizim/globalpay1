import 'dart:async';
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
      if (isFavoriteNow) {
        if (!favoriteRecipients.any((f) => f.key == r.key)) {
          setState(() => favoriteRecipients = [...favoriteRecipients, r]);
        }
      } else {
        setState(() =>
        favoriteRecipients = favoriteRecipients.where((f) => f.key != r.key).toList());
      }
    } catch (e) {
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

  void _selectRecipient(RecipientInfo r) {
    FocusManager.instance.primaryFocus?.unfocus();
    final match = banks.firstWhere(
          (b) => b.code == r.bankCode,
      orElse: () => BankOption(name: r.bankName, code: r.bankCode),
    );
    setState(() {
      selectedBank = match;
      _accountController.text = r.accountNumber;
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
          userId: widget.userId,
          bankCode: selectedBank!.code,
          accountHolderName: verifiedAccountName!,
        ),
      ),
    );
  }

  // ── Theme tokens ───────────────────────────────────────────────────────
  static const _accent = Colors.deepOrange;
  static const _success = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFAFAFA);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? Colors.white38 : Colors.grey.shade600;
    final fieldFill = isDark ? const Color(0xFF232323) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Send to Bank",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ================= RECIPIENT =================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.4)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(IconsaxPlusBold.bank, color: _accent, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Recipient Details",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  /// ACCOUNT NUMBER
                  Text(
                    'ACCOUNT NUMBER',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _accountController,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      prefixIcon: Icon(IconsaxPlusBold.user_tag, color: _accent, size: 20),
                      hintText: '0123456789',
                      hintStyle: TextStyle(color: subTextColor, fontWeight: FontWeight.w400),
                      filled: true,
                      fillColor: fieldFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: _accent, width: 1.5),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Verification status ──
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: verifying
                        ? Row(
                            key: const ValueKey('verifying'),
                            children: [
                              const SizedBox(
                                width: 13,
                                height: 13,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _accent,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('Verifying account…',
                                  style: TextStyle(color: subTextColor, fontSize: 12.5)),
                            ],
                          )
                        : verifiedAccountName != null
                            ? Container(
                                key: const ValueKey('verified'),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded,
                                        color: _success, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        verifiedAccountName!,
                                        style: const TextStyle(
                                          color: _success,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : verifyError != null
                                ? Row(
                                    key: const ValueKey('error'),
                                    children: [
                                      const Icon(Icons.error_outline_rounded,
                                          color: Colors.redAccent, size: 15),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(verifyError!,
                                            style: const TextStyle(
                                                color: Colors.redAccent, fontSize: 12.5)),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(key: ValueKey('empty')),
                  ),

                  const SizedBox(height: 16),

                  /// BANK DROPDOWN
                  Text(
                    'BANK',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (bankListError != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        Expanded(
                            child: Text(bankListError!,
                                style: const TextStyle(color: Colors.red, fontSize: 12.5))),
                        TextButton(
                          onPressed: _loadBanks,
                          child: const Text('Retry',
                              style: TextStyle(color: _accent, fontWeight: FontWeight.w700)),
                        ),
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
                        menuProps: MenuProps(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search bank…',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            filled: true,
                            fillColor: fieldFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
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
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: _accent),
                                  ),
                                )
                              : const Icon(IconsaxPlusBold.bank, color: _accent, size: 20),
                          hintText: bankListLoading ? 'Loading banks…' : 'Select bank',
                          hintStyle: TextStyle(color: subTextColor),
                          filled: true,
                          fillColor: fieldFill,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: _accent, width: 1.5),
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

                  const SizedBox(height: 20),

                  /// NEXT
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _goNext,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Continue",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            /// ================= RECENT =================
            _sectionHeader("Recent", textColor, subTextColor, () {}),
            const SizedBox(height: 10),
            _buildRecentSection(cardColor, textColor, subTextColor),

            const SizedBox(height: 24),

            /// ================= FAVORITES =================
            _sectionHeader("Favorites", textColor, subTextColor, () {}),
            const SizedBox(height: 10),
            _buildFavoritesSection(cardColor, textColor, subTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSection(Color cardColor, Color textColor, Color subTextColor) {
    if (recentLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _accent)),
      );
    }
    if (recentError != null) {
      return Row(children: [
        Expanded(
            child:
                Text(recentError!, style: TextStyle(color: subTextColor, fontSize: 13))),
        TextButton(
          onPressed: _loadRecent,
          child: const Text('Retry',
              style: TextStyle(color: _accent, fontWeight: FontWeight.w700)),
        ),
      ]);
    }
    if (recentRecipients.isEmpty) {
      return _emptyState('No recent transfers yet.', Icons.history_rounded, subTextColor);
    }
    return SizedBox(
      height: 104,
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

  Widget _buildFavoritesSection(Color cardColor, Color textColor, Color subTextColor) {
    if (favoritesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _accent)),
      );
    }
    if (favoritesError != null) {
      return Row(children: [
        Expanded(
            child: Text(favoritesError!,
                style: TextStyle(color: subTextColor, fontSize: 13))),
        TextButton(
          onPressed: _loadFavorites,
          child: const Text('Retry',
              style: TextStyle(color: _accent, fontWeight: FontWeight.w700)),
        ),
      ]);
    }
    if (favoriteRecipients.isEmpty) {
      return _emptyState(
        'No favorites yet — tap the heart on a recipient to save it.',
        Icons.favorite_border_rounded,
        subTextColor,
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: favoriteRecipients.length,
      itemBuilder: (_, i) {
        final r = favoriteRecipients[i];
        return _favoriteTile(r, cardColor, textColor, subTextColor);
      },
    );
  }

  Widget _emptyState(String message, IconData icon, Color subTextColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
      decoration: BoxDecoration(
        color: subTextColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: subTextColor, size: 22),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: subTextColor, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _initialsAvatar(String label, {double radius = 20}) {
    final initial = label.isNotEmpty ? label[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: _accent.withOpacity(0.12),
      child: Text(initial,
          style: TextStyle(
              color: _accent, fontWeight: FontWeight.w800, fontSize: radius * 0.7)),
    );
  }

  Widget _quickTile(RecipientInfo r, Color card, Color text, Color sub) {
    final isFav = favoriteKeys.contains(r.key);
    return GestureDetector(
      onTap: () => _selectRecipient(r),
      child: Container(
        width: 188,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
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
                      style: TextStyle(
                          color: text, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(r.accountNumber,
                      style: TextStyle(color: sub, fontSize: 11.5)),
                  Text(r.bankName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: sub, fontSize: 11)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _toggleFavorite(r),
              child: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 17,
                color: isFav ? _accent : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _favoriteTile(RecipientInfo r, Color card, Color text, Color sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: () => _selectRecipient(r),
        leading: _initialsAvatar(r.bankName, radius: 22),
        title: Text(r.accountName,
            style: TextStyle(color: text, fontWeight: FontWeight.w700, fontSize: 13.5)),
        subtitle: Text('${r.accountNumber} · ${r.bankName}',
            style: TextStyle(color: sub, fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.favorite_rounded, color: _accent, size: 20),
          onPressed: () => _toggleFavorite(r),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color text, Color sub, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(color: text, fontSize: 17, fontWeight: FontWeight.w700)),
        GestureDetector(
          onTap: onTap,
          child: Text("View All",
              style: TextStyle(color: sub, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
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
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade100,
        title: Text(title),
      ),
      body: const Center(child: Text("List of all items goes here")),
    );
  }
}