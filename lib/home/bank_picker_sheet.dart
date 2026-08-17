import 'package:flutter/material.dart';
import 'withdrawal_service.dart';

/// Full alphabetical bank picker: letter section headers, an A–Z index
/// rail on the right you can tap or drag along to jump, and a search box.
/// Banks without a logo fall back to a generic bank icon (not initials).
///
/// Usage:
///   final bank = await showModalBottomSheet<BankOption>(
///     context: context,
///     isScrollControlled: true,
///     backgroundColor: Colors.transparent,
///     builder: (_) => BankPickerSheet(banks: banks),
///   );
class BankPickerSheet extends StatefulWidget {
  final List<BankOption> banks;

  const BankPickerSheet({super.key, required this.banks});

  @override
  State<BankPickerSheet> createState() => _BankPickerSheetState();
}

class _Entry {
  final String? header; // set for a section-header row
  final BankOption? bank; // set for a bank row
  const _Entry.header(this.header) : bank = null;
  const _Entry.bank(this.bank) : header = null;
}

const _kAlphabet = [
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z',
  '#',
];

const double _kHeaderHeight = 32;
const double _kRowHeight = 72;

class _BankPickerSheetState extends State<BankPickerSheet> {
  static const _accent = Colors.deepOrange;
  static const _iconBg = Color(0xFFDCF5E3);
  static const _iconColor = Color(0xFF1F8A4C);

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<_Entry> _entries = [];
  Map<String, double> _letterOffsets = {};
  String? _activeLetter;

  @override
  void initState() {
    super.initState();
    _rebuild(widget.banks);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.banks
        : widget.banks
              .where((b) => b.name.toLowerCase().contains(query))
              .toList();
    _rebuild(filtered);
  }

  void _rebuild(List<BankOption> banks) {
    final sorted = [...banks]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final Map<String, List<BankOption>> grouped = {};
    for (final b in sorted) {
      final first = b.name.isNotEmpty ? b.name[0].toUpperCase() : '#';
      final key = RegExp(r'^[A-Z]$').hasMatch(first) ? first : '#';
      grouped.putIfAbsent(key, () => []).add(b);
    }

    final entries = <_Entry>[];
    final offsets = <String, double>{};
    double cursor = 0;
    for (final letter in _kAlphabet) {
      final banksForLetter = grouped[letter];
      if (banksForLetter == null || banksForLetter.isEmpty) continue;
      offsets[letter] = cursor;
      entries.add(_Entry.header(letter));
      cursor += _kHeaderHeight;
      for (final b in banksForLetter) {
        entries.add(_Entry.bank(b));
        cursor += _kRowHeight;
      }
    }

    setState(() {
      _entries = entries;
      _letterOffsets = offsets;
    });
  }

  void _jumpToLetter(String letter) {
    // If this exact letter has no banks, jump to the nearest one after it.
    var target = letter;
    var idx = _kAlphabet.indexOf(letter);
    while (idx < _kAlphabet.length && !_letterOffsets.containsKey(target)) {
      idx++;
      if (idx >= _kAlphabet.length) return;
      target = _kAlphabet[idx];
    }
    final offset = _letterOffsets[target];
    if (offset == null) return;

    setState(() => _activeLetter = letter);
    final max = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      offset.clamp(0, max),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _handleIndexDrag(Offset localPosition, double barHeight) {
    final ratio = (localPosition.dy / barHeight).clamp(0.0, 0.999);
    final letter = _kAlphabet[(ratio * _kAlphabet.length).floor()];
    _jumpToLetter(letter);
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

  /// Generic bank icon — used whenever a bank has no logo at all, instead
  /// of initials, matching a plain "institution" placeholder.
  Widget _genericBankIcon({double radius = 20}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _iconBg,
      child: Icon(
        Icons.account_balance_rounded,
        color: _iconColor,
        size: radius,
      ),
    );
  }

  Widget _bankLogo(BankOption bank, {double size = 40}) {
    if (bank.logoUrl == null || bank.logoUrl!.isEmpty) {
      return _genericBankIcon(radius: size / 2);
    }
    return ClipOval(
      child: Image.network(
        bank.logoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _genericBankIcon(radius: size / 2),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _genericBankIcon(radius: size / 2);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? Colors.white38 : Colors.grey.shade600;
    final fieldFill = isDark
        ? const Color(0xFF232323)
        : const Color(0xFFF5F5F5);
    final headerBg = isDark ? const Color(0xFF222222) : const Color(0xFFF2F2F2);
    final dividerColor = isDark ? Colors.white10 : Colors.grey.shade200;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // ── Top bar: X · Select Bank ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        'Select Bank',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.close_rounded,
                            color: textColor,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Search ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Search Bank Name',
                      hintStyle: TextStyle(color: subTextColor),
                      prefixIcon: Icon(
                        Icons.search,
                        color: subTextColor,
                        size: 22,
                      ),
                      filled: true,
                      fillColor: fieldFill,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── List + A-Z index rail ──
                Expanded(
                  child: _entries.isEmpty
                      ? Center(
                          child: Text(
                            'No banks match your search',
                            style: TextStyle(color: subTextColor, fontSize: 13),
                          ),
                        )
                      : Stack(
                          children: [
                            ListView.builder(
                              controller: _scrollController,
                              itemCount: _entries.length,
                              padding: const EdgeInsets.only(right: 24),
                              itemBuilder: (context, i) {
                                final entry = _entries[i];
                                if (entry.header != null) {
                                  return Container(
                                    width: double.infinity,
                                    height: _kHeaderHeight,
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    color: headerBg,
                                    child: Text(
                                      entry.header!,
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  );
                                }
                                final bank = entry.bank!;
                                return SizedBox(
                                  height: _kRowHeight,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Expanded(
                                        child: ListTile(
                                          onTap: () =>
                                              Navigator.pop(context, bank),
                                          leading: _bankLogo(bank),
                                          title: Text(
                                            bank.name,
                                            style: TextStyle(
                                              color: textColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Divider(
                                        height: 1,
                                        color: dividerColor,
                                        indent: 76,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            // A-Z index rail
                            Positioned(
                              right: 2,
                              top: 0,
                              bottom: 0,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final barHeight = constraints.maxHeight;
                                  return GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onVerticalDragStart: (d) =>
                                        _handleIndexDrag(
                                          d.localPosition,
                                          barHeight,
                                        ),
                                    onVerticalDragUpdate: (d) =>
                                        _handleIndexDrag(
                                          d.localPosition,
                                          barHeight,
                                        ),
                                    onTapDown: (d) => _handleIndexDrag(
                                      d.localPosition,
                                      barHeight,
                                    ),
                                    child: Container(
                                      width: 18,
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: _kAlphabet.map((letter) {
                                          final available = _letterOffsets
                                              .containsKey(letter);
                                          final isActive =
                                              _activeLetter == letter;
                                          return Text(
                                            letter,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: isActive
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              color: available
                                                  ? (isActive
                                                        ? _accent
                                                        : subTextColor)
                                                  : subTextColor.withOpacity(
                                                      0.3,
                                                    ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  );
                                },
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
    );
  }
}
