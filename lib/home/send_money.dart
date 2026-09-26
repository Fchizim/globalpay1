import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'amount_send.dart';
import 'withdrawal_service.dart';
import 'bank_picker_sheet.dart';

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

  // ── Bank auto-detection state ───────────────────────────────────────
  // True while we're racing verify calls against major banks to find
  // which one this account number belongs to.
  bool detectingBank = false;
  // True once auto-detection has run and found no match, so the user
  // knows to pick their bank manually.
  bool detectFailed = false;
  // True if the bank currently shown was found automatically rather
  // than picked by the user — lets a manual pick always win going forward.
  bool bankWasAutoDetected = false;
  // If banks are still loading when the user finishes typing 10 digits,
  // remember to auto-detect as soon as they're ready.
  bool _pendingAutoDetect = false;
  // Bumped every time a new _autoDetectBank() run starts. Each run
  // captures its own value and checks it before applying results, so a
  // stale run (e.g. one left over from before the user deleted a digit
  // and retyped the exact same number) can never overwrite a newer
  // run's results — without this, two overlapping detection calls could
  // race and whichever happened to finish last silently "won", which is
  // why the same account number could show a different number of
  // matched banks on different tries.
  int _detectionGeneration = 0;

  // ── Recent + Favorites: fetched from the backend ──────────────────────
  List<RecipientInfo> recentRecipients = [];
  bool recentLoading = true;
  String? recentError;

  List<RecipientInfo> favoriteRecipients = [];
  bool favoritesLoading = true;
  String? favoritesError;

  Set<String> favoriteKeys = {};

  // Caches a verified "account+bank" -> account name for this screen's
  // lifetime, so re-checking the same combo (e.g. switching bank and back)
  // is instant instead of hitting the network again.
  final Map<String, String> _verifiedCache = {};

  @override
  void initState() {
    super.initState();
    _loadBanks().then((_) {
      // If the user already finished typing an account number while
      // banks were still loading, run auto-detection now.
      if (mounted && _pendingAutoDetect) {
        _pendingAutoDetect = false;
        _autoDetectBank();
      }
    });
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
      setState(
        () => bankListError = 'Could not load banks. Check your connection.',
      );
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
      final result = await WithdrawalService.getFavoriteRecipients(
        widget.userId,
      );
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
        setState(
          () => favoriteRecipients = favoriteRecipients
              .where((f) => f.key != r.key)
              .toList(),
        );
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
      detectFailed = false;
      // A fresh account number invalidates whatever bank was showing,
      // unless the user has explicitly picked one — that pick should
      // stick until they change it themselves.
      if (bankWasAutoDetected) {
        selectedBank = null;
        bankWasAutoDetected = false;
      }
    });
    // Invalidate any in-flight auto-detection immediately. Cancelling the
    // debounce timer alone isn't enough: if a detection call is already
    // running (started before this edit) it would otherwise keep running
    // and could still apply its results afterwards, even though the text
    // has since changed (or changed back to the same digits).
    _detectionGeneration++;
    _debounce?.cancel();
    _pendingAutoDetect = false;
    final digits = _accountController.text.trim();
    if (digits.length != 10) return;

    if (selectedBank != null) {
      // User already has a bank (picked manually or from recent/favorite)
      // — just verify against it as before.
      _debounce = Timer(
        const Duration(milliseconds: 250),
        () => _verifyAccount(),
      );
      return;
    }

    // No bank chosen yet — try to find it automatically.
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (bankListLoading) {
        _pendingAutoDetect = true;
      } else {
        _autoDetectBank();
      }
    });
  }

  /// Checks verification against a priority list of major banks to find
  /// which one(s) this account number belongs to, without the user
  /// picking one first. The same number can be a valid account at more
  /// than one bank at once, so if there's more than one match the user
  /// is asked to pick. Falls back to manual bank selection if nothing
  /// matches.
  ///
  /// Guards every await point with [_detectionGeneration] so a stale run
  /// (superseded by the user editing the field again, even back to the
  /// same digits) can never overwrite a newer run's results.
  Future<void> _autoDetectBank() async {
    final accountNumber = _accountController.text.trim();
    if (accountNumber.length != 10 || banks.isEmpty) return;

    final myGeneration = ++_detectionGeneration;

    setState(() {
      detectingBank = true;
      detectFailed = false;
      verifyError = null;
    });
    try {
      final results = await WithdrawalService.detectBanksForAccount(
        accountNumber: accountNumber,
        banks: banks,
      );
      if (!mounted) return;
      // A newer detection run has since started — discard these results.
      if (myGeneration != _detectionGeneration) return;
      // The account number may have changed while we were waiting.
      if (_accountController.text.trim() != accountNumber) return;

      for (final r in results) {
        _verifiedCache['${r.bank.code}|$accountNumber'] = r.accountName;
      }

      if (results.isEmpty) {
        setState(() => detectFailed = true);
      } else if (results.length == 1) {
        final result = results.first;
        setState(() {
          selectedBank = result.bank;
          bankWasAutoDetected = true;
          verifiedAccountName = result.accountName;
        });
      } else {
        final chosen = await _showMultiMatchSheet(results);
        if (!mounted) return;
        if (myGeneration != _detectionGeneration) return;
        // The account number may have changed while the sheet was open.
        if (_accountController.text.trim() != accountNumber) return;
        if (chosen != null) {
          setState(() {
            selectedBank = chosen.bank;
            bankWasAutoDetected = true;
            verifiedAccountName = chosen.accountName;
          });
        }
        // If dismissed without choosing, leave bank/name unset — the
        // bank field is still tappable for a manual pick, and re-typing
        // the number will bring this picker back up.
      }
    } finally {
      if (mounted && myGeneration == _detectionGeneration) {
        setState(() => detectingBank = false);
      }
    }
  }

  /// Lets the user choose which bank they meant when the same account
  /// number matched more than one.
  Future<DetectedBank?> _showMultiMatchSheet(List<DetectedBank> matches) {
    return showModalBottomSheet<DetectedBank>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BankMatchSheet(matches: matches),
    );
  }

  Future<void> _verifyAccount() async {
    if (selectedBank == null || _accountController.text.trim().length != 10)
      return;

    final accountNumber = _accountController.text.trim();
    final bankCode = selectedBank!.code;
    final cacheKey = '$bankCode|$accountNumber';

    // Already verified this exact account+bank this session — skip the
    // network call entirely.
    final cached = _verifiedCache[cacheKey];
    if (cached != null) {
      setState(() {
        verifiedAccountName = cached;
        verifying = false;
        verifyError = null;
      });
      return;
    }

    setState(() {
      verifying = true;
      verifyError = null;
    });
    try {
      final name = await WithdrawalService.verifyAccount(
        accountNumber: accountNumber,
        bankCode: bankCode,
      );
      if (!mounted) return;
      _verifiedCache[cacheKey] = name;
      setState(() => verifiedAccountName = name);
    } on TimeoutException {
      if (!mounted) return;
      setState(
        () => verifyError = 'Verification is taking too long — tap to retry.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(
        () => verifyError = e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => verifying = false);
    }
  }

  // ── Bank picker ──────────────────────────────────────────────────────
  Future<void> _showBankPicker() async {
    if (banks.isEmpty) return;
    final result = await showModalBottomSheet<BankOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BankPickerSheet(banks: banks),
    );
    if (result == null || !mounted) return;
    setState(() {
      selectedBank = result;
      bankWasAutoDetected = false;
      detectFailed = false;
      verifiedAccountName = null;
      verifyError = null;
    });
    if (_accountController.text.trim().length == 10) {
      _verifyAccount();
    }
  }

  /// Looks up the full BankOption (with logo) matching a recipient's saved
  /// bank code, so recent/favorite tiles can show a logo instead of just
  /// initials whenever possible.
  BankOption? _bankFor(RecipientInfo r) {
    for (final b in banks) {
      if (b.code == r.bankCode) return b;
    }
    return null;
  }

  void _selectRecipient(RecipientInfo r) {
    FocusManager.instance.primaryFocus?.unfocus();
    final match = banks.firstWhere(
      (b) => b.code == r.bankCode,
      orElse: () => BankOption(name: r.bankName, code: r.bankCode),
    );
    setState(() {
      selectedBank = match;
      bankWasAutoDetected = false;
      detectFailed = false;
      _accountController.text = r.accountNumber;
      verifiedAccountName = r.accountName;
      verifyError = null;
      verifying = false;
    });
  }

  void _goNext() {
    if (_accountController.text.trim().length != 10 || selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter a valid account number and select a bank"),
        ),
      );
      return;
    }
    if (verifiedAccountName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            verifying || detectingBank
                ? "Still verifying the account, please wait"
                : "Please wait for account verification to complete",
          ),
        ),
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
          logoUrl: selectedBank!.logoUrl,
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

    final backgroundColor = isDark
        ? const Color(0xFF0D0D0D)
        : const Color(0xFFFAFAFA);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? Colors.white38 : Colors.grey.shade600;
    final fieldFill = isDark
        ? const Color(0xFF232323)
        : const Color(0xFFF5F5F5);
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;

    // ── Responsive helpers ─────────────────────────────────
    final textScale = MediaQuery.of(
      context,
    ).textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.2);

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
      // ── Tablet fix: cap and center the scrollable content so it
      // doesn't stretch edge-to-edge on large screens ──
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScale),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
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
                      border: Border.all(color: borderColor, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.35)
                              : Colors.black.withOpacity(0.035),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
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
                              child: const Icon(
                                IconsaxPlusBold.bank,
                                color: _accent,
                                size: 18,
                              ),
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
                            prefixIcon: Icon(
                              IconsaxPlusBold.user_tag,
                              color: _accent,
                              size: 20,
                            ),
                            hintText: '0123456789',
                            hintStyle: TextStyle(
                              color: subTextColor,
                              fontWeight: FontWeight.w400,
                            ),
                            filled: true,
                            fillColor: fieldFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _accent,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ── Verification status ──
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: detectingBank
                              ? Row(
                                  key: const ValueKey('detecting'),
                                  children: [
                                    const _ActivitySpinner(
                                      size: 15,
                                      color: _accent,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Matching banks…',
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                )
                              : verifying
                              ? Row(
                                  key: const ValueKey('verifying'),
                                  children: [
                                    const _ActivitySpinner(
                                      size: 15,
                                      color: _accent,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Verifying account…',
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                )
                              : verifiedAccountName != null
                              ? Container(
                                  key: const ValueKey('verified'),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: _success,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          verifiedAccountName!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                              : detectFailed
                              ? GestureDetector(
                                  key: const ValueKey('detect_failed'),
                                  onTap: _showBankPicker,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        color: subTextColor,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "Couldn't find your bank automatically — tap to select it",
                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : verifyError != null
                              ? GestureDetector(
                                  key: const ValueKey('error'),
                                  onTap: _verifyAccount,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: Colors.redAccent,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          verifyError!,
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.refresh_rounded,
                                        color: Colors.redAccent,
                                        size: 15,
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(key: ValueKey('empty')),
                        ),

                        const SizedBox(height: 5),

                        /// BANK PICKER
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'BANK',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                            // if (bankWasAutoDetected)
                            //   GestureDetector(
                            //     onTap: _showBankPicker,
                            //     child: Text(xs
                            //       'Not right? Change',
                            //       style: TextStyle(
                            //         color: _accent,
                            //         fontSize: 11,
                            //         fontWeight: FontWeight.w600,
                            //       ),
                            //     ),
                            //   ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (bankListError != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    bankListError!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _loadBanks,
                                  child: const Text(
                                    'Retry',
                                    style: TextStyle(
                                      color: _accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: bankListLoading ? null : _showBankPicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: fieldFill,
                                borderRadius: BorderRadius.circular(14),
                                border: detectFailed
                                    ? Border.all(
                                        color: _accent.withOpacity(0.4),
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  if (bankListLoading || detectingBank)
                                    const _ActivitySpinner(
                                      size: 20,
                                      color: _accent,
                                    )
                                  else if (selectedBank != null)
                                    _bankLogo(selectedBank!, size: 26)
                                  else
                                    const Icon(
                                      IconsaxPlusBold.bank,
                                      color: _accent,
                                      size: 20,
                                    ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      bankListLoading
                                          ? 'Loading banks…'
                                          : detectingBank
                                          ? 'Matching banks…'
                                          : (selectedBank?.name ??
                                                'Select Bank'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: selectedBank != null
                                            ? textColor
                                            : subTextColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: subTextColor,
                                  ),
                                ],
                              ),
                            ),
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
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// ================= RECENT =================
                  _sectionHeader("Recent", textColor, subTextColor, () {}),
                  const SizedBox(height: 8),
                  _buildRecentSection(
                    cardColor,
                    textColor,
                    subTextColor,
                    borderColor,
                  ),

                  const SizedBox(height: 20),

                  /// ================= FAVORITES =================
                  _sectionHeader("Favorites", textColor, subTextColor, () {}),
                  const SizedBox(height: 8),
                  _buildFavoritesSection(
                    cardColor,
                    textColor,
                    subTextColor,
                    borderColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSection(
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color borderColor,
  ) {
    if (recentLoading) {
      return const SizedBox(
        height: 80,
        child: Center(child: _ActivitySpinner(size: 22, color: _accent)),
      );
    }
    if (recentError != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              recentError!,
              style: TextStyle(color: subTextColor, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: _loadRecent,
            child: const Text(
              'Retry',
              style: TextStyle(color: _accent, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
    }
    if (recentRecipients.isEmpty) {
      return _emptyState(
        'No recent transfers yet.',
        Icons.history_rounded,
        subTextColor,
      );
    }
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recentRecipients.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final r = recentRecipients[i];
          return _quickTile(r, cardColor, textColor, subTextColor, borderColor);
        },
      ),
    );
  }

  Widget _buildFavoritesSection(
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color borderColor,
  ) {
    if (favoritesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: _ActivitySpinner(size: 22, color: _accent)),
      );
    }
    if (favoritesError != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              favoritesError!,
              style: TextStyle(color: subTextColor, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: _loadFavorites,
            child: const Text(
              'Retry',
              style: TextStyle(color: _accent, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
    }
    if (favoriteRecipients.isEmpty) {
      return _emptyState(
        'No favorites yet — tap the heart on a recipient to save it.',
        Icons.favorite_border_rounded,
        subTextColor,
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: favoriteRecipients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final r = favoriteRecipients[i];
        return _favoriteTile(
          r,
          cardColor,
          textColor,
          subTextColor,
          borderColor,
        );
      },
    );
  }

  Widget _emptyState(String message, IconData icon, Color subTextColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: subTextColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: subTextColor, size: 20),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: subTextColor, fontSize: 12),
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
      child: Text(
        initial,
        style: TextStyle(
          color: _accent,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }

  /// Shows a bank's logo when available, falling back to the initials
  /// avatar (network failure, missing logo, etc). `bank` may be null if a
  /// recipient's bank code isn't in the loaded bank list — pass a name too
  /// so the fallback still has something to show.
  Widget _bankLogo(BankOption bank, {double size = 20}) {
    if (bank.logoUrl == null || bank.logoUrl!.isEmpty) {
      return _initialsAvatar(bank.name, radius: size / 2);
    }
    return ClipOval(
      child: Image.network(
        bank.logoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _initialsAvatar(bank.name, radius: size / 2),
      ),
    );
  }

  Widget _quickTile(
    RecipientInfo r,
    Color card,
    Color text,
    Color sub,
    Color borderColor,
  ) {
    final isFav = favoriteKeys.contains(r.key);
    final matchedBank = _bankFor(r);
    return GestureDetector(
      onTap: () => _selectRecipient(r),
      child: Container(
        width: 166,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            matchedBank != null
                ? _bankLogo(matchedBank, size: 34)
                : _initialsAvatar(r.bankName, radius: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.accountName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    r.bankName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: sub, fontSize: 10.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 2),
            GestureDetector(
              onTap: () => _toggleFavorite(r),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 15,
                  color: isFav ? _accent : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _favoriteTile(
    RecipientInfo r,
    Color card,
    Color text,
    Color sub,
    Color borderColor,
  ) {
    final matchedBank = _bankFor(r);
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _selectRecipient(r),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                matchedBank != null
                    ? _bankLogo(matchedBank, size: 36)
                    : _initialsAvatar(r.bankName, radius: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        r.accountName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: text,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${r.accountNumber} · ${r.bankName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: sub, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleFavorite(r),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: _accent,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(
    String title,
    Color text,
    Color sub,
    VoidCallback onTap,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            "View All",
            style: TextStyle(
              color: sub,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
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
        backgroundColor: isDark
            ? const Color(0xFF121212)
            : Colors.grey.shade100,
        title: Text(title),
      ),
      body: const Center(child: Text("List of all items goes here")),
    );
  }
}

/// Shown when an account number matches more than one bank at once (e.g.
/// a PalmPay wallet and an Opay wallet sharing the same number) — lets
/// the user pick which one they actually mean to send to.
class _BankMatchSheet extends StatelessWidget {
  final List<DetectedBank> matches;

  const _BankMatchSheet({required this.matches});

  static const _accent = Colors.deepOrange;

  Widget _avatar(BankOption bank) {
    final initial = bank.name.isNotEmpty ? bank.name[0].toUpperCase() : '?';
    final fallback = CircleAvatar(
      radius: 22,
      backgroundColor: _accent.withOpacity(0.12),
      child: Text(
        initial,
        style: const TextStyle(
          color: _accent,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
    if (bank.logoUrl == null || bank.logoUrl!.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        bank.logoUrl!,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? Colors.white38 : Colors.grey.shade600;
    final dividerColor = isDark ? Colors.white10 : Colors.grey.shade200;

    return Container(
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          // ── Tablet fix: cap sheet content width so it doesn't
          // stretch full-width on large screens ──
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This account number matches ${matches.length} banks',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose which one you want to send to.',
                        style: TextStyle(color: subTextColor, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: matches.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: dividerColor, indent: 76),
                    itemBuilder: (context, i) {
                      final m = matches[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        onTap: () => Navigator.pop(context, m),
                        leading: _avatar(m.bank),
                        title: Text(
                          m.bank.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          m.accountName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: subTextColor, fontSize: 12.5),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A modern "iOS activity indicator" style spinner — 12 tapered dashes
/// arranged in a circle with a fading trail, continuously rotating.
/// Used in place of the plain [CircularProgressIndicator] ring throughout
/// this screen for a more current, native-feeling loading state (matches
/// the dashed spinner style used in e.g. bank verification flows).
class _ActivitySpinner extends StatefulWidget {
  final double size;
  final Color color;

  const _ActivitySpinner({required this.size, required this.color});

  @override
  State<_ActivitySpinner> createState() => _ActivitySpinnerState();
}

class _ActivitySpinnerState extends State<_ActivitySpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Transform.rotate(
            angle: _controller.value * 2 * math.pi,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _ActivitySpinnerPainter(color: widget.color),
            ),
          );
        },
      ),
    );
  }
}

class _ActivitySpinnerPainter extends CustomPainter {
  final Color color;
  static const int _dashCount = 12;

  const _ActivitySpinnerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final dashLength = radius * 0.42;
    final dashWidth = (radius * 0.22).clamp(1.4, 3.0);

    for (int i = 0; i < _dashCount; i++) {
      final angle = (2 * math.pi / _dashCount) * i;
      // Fades from fully opaque (the "head") around to nearly transparent
      // (the "tail"), so the rotation reads as a smooth trailing sweep.
      final opacity = 0.12 + 0.88 * (i / (_dashCount - 1));
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..strokeWidth = dashWidth
        ..strokeCap = StrokeCap.round;

      final outer = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final inner = Offset(
        center.dx + (radius - dashLength) * math.cos(angle),
        center.dy + (radius - dashLength) * math.sin(angle),
      );
      canvas.drawLine(inner, outer, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ActivitySpinnerPainter oldDelegate) =>
      oldDelegate.color != color;
}
