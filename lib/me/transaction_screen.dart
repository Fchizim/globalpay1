import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';

// ─────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────

class TransactionModel {
  final String transactionId;
  final String serviceType;
  final String serviceRefId;
  final String amount;
  final String paymentMethod;
  final String paymentStatus;
  final String purpose;
  final String transactionDate;
  final String referenceCode;
  final String referenceId;
  final String paymentType;
  final String status;
  final Map<String, dynamic>? metadata;

  const TransactionModel({
    required this.transactionId,
    required this.serviceType,
    required this.serviceRefId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.purpose,
    required this.transactionDate,
    required this.referenceCode,
    required this.referenceId,
    required this.paymentType,
    required this.status,
    this.metadata,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> j) => TransactionModel(
    transactionId:   j['transaction_id']?.toString() ?? '',
    serviceType:     j['service_type']?.toString()   ?? '',
    serviceRefId:    j['service_ref_id']?.toString() ?? '',
    amount:          j['amount']?.toString()         ?? '0.00',
    paymentMethod:   j['payment_method']?.toString() ?? '',
    paymentStatus:   j['payment_status']?.toString() ?? '',
    purpose:         j['purpose']?.toString()        ?? '',
    transactionDate: j['transaction_date']?.toString() ?? '',
    referenceCode:   j['reference_code']?.toString() ?? '',
    referenceId:     j['reference_id']?.toString()   ?? '',
    paymentType:     j['payment_type']?.toString()   ?? '',
    status:          j['status']?.toString()         ?? 'active',
    metadata:        j['metadata'] as Map<String, dynamic>?,
  );

  bool get isCredit {
    final type = paymentType.toLowerCase();
    final stype = serviceType.toLowerCase();
    return type == 'credit' ||
        stype.contains('receive') ||
        stype.contains('fund') ||
        stype.contains('top') ||
        stype.contains('refund');
  }

  bool get isSuccessful {
    final s = paymentStatus.toLowerCase();
    return s == 'successful' || s == 'success' || s == 'completed';
  }

  DateTime? get parsedDate {
    try {
      return DateTime.parse(transactionDate);
    } catch (_) {
      return null;
    }
  }

  String get formattedDate {
    final dt = parsedDate;
    if (dt == null) return transactionDate;
    return DateFormat('dd MMM yyyy • hh:mm a').format(dt);
  }

  String get displayTitle {
    if (purpose.isNotEmpty) return purpose;
    if (serviceType.isNotEmpty) return _capitalize(serviceType.replaceAll('_', ' '));
    return 'Transaction';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─────────────────────────────────────────────────────────────
// Filter state
// ─────────────────────────────────────────────────────────────

enum TxTypeFilter {
  all,
  order,
  subscription,
  p2pTransfer,
  gdrop,
  walletFunding,
}
enum TxStatusFilter { all, success, failed, pending }
enum TxDateFilter { all, today, thisWeek, thisMonth, custom }

class TransactionFilters {
  TxTypeFilter type;
  TxStatusFilter status;
  TxDateFilter dateFilter;
  DateTime? customFrom;
  DateTime? customTo;

  TransactionFilters({
    this.type = TxTypeFilter.all,
    this.status = TxStatusFilter.all,
    this.dateFilter = TxDateFilter.all,
    this.customFrom,
    this.customTo,
  });

  bool get isActive =>
      type != TxTypeFilter.all ||
          status != TxStatusFilter.all ||
          dateFilter != TxDateFilter.all;

  int get activeCount {
    int c = 0;
    if (type != TxTypeFilter.all) c++;
    if (status != TxStatusFilter.all) c++;
    if (dateFilter != TxDateFilter.all) c++;
    return c;
  }

  TransactionFilters copy() => TransactionFilters(
    type: type,
    status: status,
    dateFilter: dateFilter,
    customFrom: customFrom,
    customTo: customTo,
  );

  // For 'gdrop' this returns both type values comma-separated — the backend
  // splits on ',' and matches with IN(), since sends and receives are two
  // distinct service_type values that should filter together as one option.
  String get typeParam {
    switch (type) {
      case TxTypeFilter.order: return 'order';
      case TxTypeFilter.subscription: return 'subscription';
      case TxTypeFilter.p2pTransfer: return 'p2p_transfer';
      case TxTypeFilter.gdrop: return 'GDROP_SEND,GDROP_RECEIVE';
      case TxTypeFilter.walletFunding: return 'wallet_funding';
      case TxTypeFilter.all: return '';
    }
  }

  String get statusParam {
    switch (status) {
      case TxStatusFilter.success: return 'success';
      case TxStatusFilter.failed: return 'failed';
      case TxStatusFilter.pending: return 'pending';
      case TxStatusFilter.all: return '';
    }
  }

  DateTime? get resolvedFrom {
    final now = DateTime.now();
    switch (dateFilter) {
      case TxDateFilter.today:
        return DateTime(now.year, now.month, now.day);
      case TxDateFilter.thisWeek:
        return now.subtract(Duration(days: now.weekday - 1));
      case TxDateFilter.thisMonth:
        return DateTime(now.year, now.month, 1);
      case TxDateFilter.custom:
        return customFrom;
      case TxDateFilter.all:
        return null;
    }
  }

  DateTime? get resolvedTo => dateFilter == TxDateFilter.custom ? customTo : null;
}

// ─────────────────────────────────────────────────────────────
// Transaction Screen
// ─────────────────────────────────────────────────────────────

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final List<TransactionModel> _transactions = [];
  bool _loading = true;
  bool _hasMore = true;
  int  _page = 1;
  bool _fetching = false;
  TransactionFilters _filters = TransactionFilters();

  static const String _url = 'https://glopa.org/glo/get_user_trans.php';

  @override
  void initState() {
    super.initState();
    _fetch(refresh: true);
  }

  Future<void> _fetch({bool refresh = false}) async {
    if (_fetching) return;
    if (refresh) {
      setState(() { _transactions.clear(); _page = 1; _hasMore = true; });
    }
    setState(() { _fetching = true; _loading = refresh || _transactions.isEmpty; });

    final user = context.read<UserProvider>().user;
    if (user == null) { setState(() { _loading = false; _fetching = false; }); return; }

    final params = <String, String>{
      'user_id': user.userId,
      'page': '$_page',
      'limit': '20',
    };
    if (_filters.typeParam.isNotEmpty) params['type'] = _filters.typeParam;
    if (_filters.statusParam.isNotEmpty) params['status'] = _filters.statusParam;
    final from = _filters.resolvedFrom;
    final to = _filters.resolvedTo;
    if (from != null) params['date_from'] = DateFormat('yyyy-MM-dd').format(from);
    if (to != null) params['date_to'] = DateFormat('yyyy-MM-dd').format(to);

    try {
      final uri = Uri.parse(_url).replace(queryParameters: params);
      final res = await http.get(uri).timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);
      if (data['status'] == 'success' && mounted) {
        final list = (data['transactions'] as List)
            .map((t) => TransactionModel.fromJson(t))
            .toList();
        setState(() {
          _transactions.addAll(list);
          _hasMore = data['has_more'] as bool? ?? false;
          _page++;
        });
      }
    } catch (_) {}

    if (mounted) setState(() { _loading = false; _fetching = false; });
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<TransactionFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(initial: _filters.copy()),
    );
    if (result != null) {
      setState(() => _filters = result);
      _fetch(refresh: true);
    }
  }

  void _clearFilters() {
    setState(() => _filters = TransactionFilters());
    _fetch(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white54 : Colors.grey.shade500;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(IconsaxPlusLinear.arrow_left_2, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Transactions',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(IconsaxPlusLinear.filter, color: textColor),
                onPressed: _openFilterSheet,
              ),
              if (_filters.isActive)
                Positioned(
                  right: 10, top: 10,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.deepOrange, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_filters.isActive) _buildActiveFilterBar(textColor, hintColor),
          Expanded(
            child: RefreshIndicator(
              color: Colors.deepOrange,
              onRefresh: () => _fetch(refresh: true),
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
                  : _transactions.isEmpty
                  ? _buildEmpty(textColor, hintColor)
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: _transactions.length + (_hasMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  if (i == _transactions.length) {
                    if (!_fetching) {
                      WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
                    }
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.deepOrange),
                        ),
                      ),
                    );
                  }
                  return _buildRow(_transactions[i], cardColor, textColor, hintColor, isDark);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterBar(Color text, Color hint) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
    child: Row(
      children: [
        Icon(IconsaxPlusLinear.filter, size: 14, color: Colors.deepOrange),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${_filters.activeCount} filter${_filters.activeCount > 1 ? 's' : ''} applied',
            style: TextStyle(fontSize: 12, color: hint),
          ),
        ),
        GestureDetector(
          onTap: _clearFilters,
          child: const Text('Clear',
              style: TextStyle(
                  color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );

  Widget _buildEmpty(Color text, Color hint) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(IconsaxPlusLinear.empty_wallet, size: 56, color: hint),
          const SizedBox(height: 12),
          Text(
            _filters.isActive ? 'No transactions match these filters' : 'No transactions yet',
            textAlign: TextAlign.center,
            style: TextStyle(color: hint, fontSize: 14),
          ),
          if (_filters.isActive) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear filters', style: TextStyle(color: Colors.deepOrange)),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _buildRow(TransactionModel t, Color card, Color text, Color hint, bool isDark) {
    final isCredit  = t.isCredit;
    final isSuccess = t.isSuccessful;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(transaction: t, isDark: isDark),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              height: 46, width: 46,
              decoration: BoxDecoration(
                color: isCredit
                    ? Colors.green.withOpacity(0.12)
                    : Colors.red.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: isCredit ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: text)),
                  const SizedBox(height: 3),
                  Text(t.formattedDate, style: TextStyle(fontSize: 11, color: hint)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSuccess
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isSuccess ? 'Successful' : 'Failed',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: isSuccess ? Colors.green : Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isCredit ? '+' : '-'}₦${t.amount}',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: isCredit ? Colors.green : Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Filter Bottom Sheet
// ─────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final TransactionFilters initial;
  const _FilterSheet({required this.initial});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late TransactionFilters _f = widget.initial.copy();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filter Transactions',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  GestureDetector(
                    onTap: () => setState(() => _f = TransactionFilters()),
                    child: const Text('Reset',
                        style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _sectionLabel('Type', textColor),
              const SizedBox(height: 8),
              _chipGroup<TxTypeFilter>(
                current: _f.type,
                options: const {
                  TxTypeFilter.all: 'All',
                  TxTypeFilter.order: 'Orders',
                  TxTypeFilter.subscription: 'Subscription',
                  TxTypeFilter.p2pTransfer: 'P2P Transfer',
                  TxTypeFilter.gdrop: 'GDrop',
                  TxTypeFilter.walletFunding: 'Wallet Funding',
                },
                onSelect: (v) => setState(() => _f.type = v),
              ),

              const SizedBox(height: 20),
              _sectionLabel('Status', textColor),
              const SizedBox(height: 8),
              _chipGroup<TxStatusFilter>(
                current: _f.status,
                options: const {
                  TxStatusFilter.all: 'All',
                  TxStatusFilter.success: 'Successful',
                  TxStatusFilter.failed: 'Failed',
                  TxStatusFilter.pending: 'Pending',
                },
                onSelect: (v) => setState(() => _f.status = v),
              ),

              const SizedBox(height: 20),
              _sectionLabel('Date Range', textColor),
              const SizedBox(height: 8),
              _chipGroup<TxDateFilter>(
                current: _f.dateFilter,
                options: const {
                  TxDateFilter.all: 'All time',
                  TxDateFilter.today: 'Today',
                  TxDateFilter.thisWeek: 'This week',
                  TxDateFilter.thisMonth: 'This month',
                  TxDateFilter.custom: 'Custom',
                },
                onSelect: (v) async {
                  if (v == TxDateFilter.custom) {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: (_f.customFrom != null && _f.customTo != null)
                          ? DateTimeRange(start: _f.customFrom!, end: _f.customTo!)
                          : null,
                    );
                    if (range != null) {
                      setState(() {
                        _f.dateFilter = TxDateFilter.custom;
                        _f.customFrom = range.start;
                        _f.customTo = range.end;
                      });
                    }
                  } else {
                    setState(() => _f.dateFilter = v);
                  }
                },
              ),
              if (_f.dateFilter == TxDateFilter.custom &&
                  _f.customFrom != null && _f.customTo != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${DateFormat('dd MMM yyyy').format(_f.customFrom!)} — ${DateFormat('dd MMM yyyy').format(_f.customTo!)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _f),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Apply Filters',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String s, Color c) =>
      Text(s, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c));

  Widget _chipGroup<T>({
    required T current,
    required Map<T, String> options,
    required void Function(T) onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((e) {
        final selected = e.key == current;
        return GestureDetector(
          onTap: () => onSelect(e.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? Colors.deepOrange : Colors.deepOrange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              e.value,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.deepOrange),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Transaction Detail Screen
// ─────────────────────────────────────────────────────────────

class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;
  final bool isDark;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final t         = transaction;
    final bgColor   = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white54 : Colors.grey.shade500;
    final isCredit  = t.isCredit;
    final isSuccess = t.isSuccessful;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor:      bgColor,
        elevation:            0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(IconsaxPlusLinear.arrow_left_2, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Transaction Details',
            style: TextStyle(
                color:      textColor,
                fontWeight: FontWeight.bold,
                fontSize:   17)),
        actions: [
          IconButton(
            icon: Icon(IconsaxPlusLinear.share, color: textColor),
            onPressed: () => _share(context, t),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color:        cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCredit
                          ? Colors.green.withOpacity(0.12)
                          : Colors.red.withOpacity(0.12),
                    ),
                    child: Icon(
                      isCredit
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: isCredit ? Colors.green : Colors.red,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${isCredit ? '+' : '-'}₦${t.amount}',
                    style: TextStyle(
                        fontSize:   34,
                        fontWeight: FontWeight.w900,
                        color: isCredit ? Colors.green : Colors.red,
                        letterSpacing: -1),
                  ),
                  const SizedBox(height: 6),
                  Text(t.displayTitle,
                      style: TextStyle(
                          color: hintColor, fontSize: 14)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSuccess
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isSuccess ? '✓ Successful' : '✕ Failed',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize:   13,
                          color: isSuccess ? Colors.green : Colors.red),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color:        cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _row('Date & Time',    t.formattedDate,   textColor, hintColor),
                  _divider(),
                  _row('Service',        t.serviceType.isNotEmpty
                      ? _cap(t.serviceType.replaceAll('_', ' '))
                      : '—',             textColor, hintColor),
                  _divider(),
                  _row('Payment Method', t.paymentMethod.isNotEmpty
                      ? _cap(t.paymentMethod)
                      : '—',             textColor, hintColor),
                  _divider(),
                  _row('Payment Type',   t.paymentType.isNotEmpty
                      ? _cap(t.paymentType)
                      : '—',             textColor, hintColor),
                  _divider(),
                  _row('Status',         t.paymentStatus.isNotEmpty
                      ? _cap(t.paymentStatus)
                      : '—',             textColor, hintColor),

                  if (t.referenceCode.isNotEmpty) ...[
                    _divider(),
                    _copyRow('Reference Code', t.referenceCode,
                        textColor, hintColor, context),
                  ],
                  if (t.referenceId.isNotEmpty) ...[
                    _divider(),
                    _copyRow('Reference ID',   t.referenceId,
                        textColor, hintColor, context),
                  ],
                  if (t.transactionId.isNotEmpty) ...[
                    _divider(),
                    _copyRow('Transaction ID', t.transactionId,
                        textColor, hintColor, context),
                  ],
                  if (t.serviceRefId.isNotEmpty) ...[
                    _divider(),
                    _copyRow('Service Ref',    t.serviceRefId,
                        textColor, hintColor, context),
                  ],
                ],
              ),
            ),

            if (t.metadata != null && t.metadata!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color:        cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Text('Additional Info',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:      textColor,
                              fontSize:   14)),
                    ),
                    const Divider(height: 1, thickness: 0.4),
                    ...t.metadata!.entries.map((e) {
                      final key = _cap(e.key.replaceAll('_', ' '));
                      final val = e.value?.toString() ?? '—';
                      return Column(
                        children: [
                          _row(key, val, textColor, hintColor),
                          if (e.key != t.metadata!.keys.last)
                            _divider(),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _share(context, t),
                icon:  const Icon(IconsaxPlusLinear.share,
                    color: Colors.deepOrange),
                label: const Text('Share Receipt',
                    style: TextStyle(
                        color:      Colors.deepOrange,
                        fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.deepOrange),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  Widget _divider() =>
      const Divider(height: 1, thickness: 0.4, indent: 16, endIndent: 16);

  Widget _row(
      String label, String value, Color text, Color hint) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: hint, fontSize: 13)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      color:      text,
                      fontSize:   13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _copyRow(String label, String value, Color text, Color hint,
      BuildContext context) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: hint, fontSize: 13)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      color:      text,
                      fontSize:   13,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('$label copied'),
                  duration:  const Duration(seconds: 1),
                  behavior:  SnackBarBehavior.floating,
                  backgroundColor: Colors.green.shade600,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
              },
              child: Icon(IconsaxPlusLinear.copy, size: 16, color: hint),
            ),
          ],
        ),
      );

  void _share(BuildContext context, TransactionModel t) {
    final text = '''
GlobalPay Transaction Receipt
──────────────────────
${t.displayTitle}
Amount:   ${t.isCredit ? '+' : '-'}₦${t.amount}
Status:   ${t.paymentStatus}
Date:     ${t.formattedDate}
Ref Code: ${t.referenceCode.isNotEmpty ? t.referenceCode : 'N/A'}
Tx ID:    ${t.transactionId}
──────────────────────
Powered by Glonest
''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Receipt copied to clipboard'),
      behavior: SnackBarBehavior.floating,
    ));
  }
}