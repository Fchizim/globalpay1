import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
class RecentNumber {
  final String phone; // digits only, e.g. 08036583723
  final String network; // MTN | AIRTEL | GLO | 9MOBILE
  final DateTime time;

  const RecentNumber({
    required this.phone,
    required this.network,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'network': network,
    'time': time.millisecondsSinceEpoch,
  };

  factory RecentNumber.fromJson(Map<String, dynamic> j) => RecentNumber(
    phone: j['phone'].toString(),
    network: j['network'].toString(),
    time: DateTime.fromMillisecondsSinceEpoch(j['time'] as int),
  );
}

// ─── Storage (per user, max 7, shared by Airtime + Data) ──────────────────────
class RecentNumbersService {
  static const int maxItems = 7;
  static String _key(String userId) => 'recent_numbers_$userId';

  static Future<List<RecentNumber>> load(String userId) async {
    if (userId.isEmpty) return [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId));
      if (raw == null) return [];
      final list = (jsonDecode(raw) as List)
          .map((e) => RecentNumber.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      list.sort((a, b) => b.time.compareTo(a.time));
      return list;
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save(String userId, List<RecentNumber> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(userId),
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  /// Call after a successful (or pending) purchase.
  static Future<void> add(String userId, String phone, String network) async {
    if (userId.isEmpty || phone.isEmpty) return;
    final items = await load(userId);
    items.removeWhere((e) => e.phone == phone); // dedupe, move to top
    items.insert(
      0,
      RecentNumber(phone: phone, network: network, time: DateTime.now()),
    );
    await _save(userId, items.take(maxItems).toList());
  }

  static Future<void> remove(String userId, String phone) async {
    final items = await load(userId);
    items.removeWhere((e) => e.phone == phone);
    await _save(userId, items);
  }
}

// ─── Panel widget ─────────────────────────────────────────────────────────────
class RecentNumbersPanel extends StatelessWidget {
  final List<RecentNumber> items;
  final String myPhone;
  final bool isDark;
  final ValueChanged<RecentNumber> onSelect;
  final ValueChanged<RecentNumber> onDelete;

  const RecentNumbersPanel({
    super.key,
    required this.items,
    required this.myPhone,
    required this.isDark,
    required this.onSelect,
    required this.onDelete,
  });

  static const _logos = {
    'MTN': 'assets/images/png/mtn.jpeg',
    'AIRTEL': 'assets/images/png/airtel.jpeg',
    'GLO': 'assets/images/png/glo.jpeg',
    '9MOBILE': 'assets/images/png/9mobile.jpeg',
  };

  static String formatPhone(String p) {
    if (p.length != 11) return p;
    return '${p.substring(0, 3)} ${p.substring(3, 7)} ${p.substring(7)}';
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final mq = MediaQuery.of(context);
    // Fit above the keyboard; scroll when the list is taller than this.
    final maxH = (mq.size.height * 0.34).clamp(120.0, 320.0);
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.white54 : Colors.grey.shade600;
    final fmt = DateFormat('h:mm a, MMM dd');

    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: items.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            indent: 14,
            endIndent: 14,
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
          itemBuilder: (_, i) {
            final r = items[i];
            final isMe = myPhone.isNotEmpty && r.phone == myPhone;
            final logo = _logos[r.network];

            return InkWell(
              onTap: () => onSelect(r),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.deepOrange.withOpacity(0.1),
                      backgroundImage: logo != null ? AssetImage(logo) : null,
                      child: logo == null
                          ? Text(
                              r.network.isEmpty ? '?' : r.network[0],
                              style: const TextStyle(
                                color: Colors.deepOrange,
                                fontSize: 12,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatPhone(r.phone),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Me',
                          style: TextStyle(
                            color: Colors.deepOrange,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      fmt.format(r.time),
                      style: TextStyle(fontSize: 11, color: mutedColor),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close, size: 20, color: mutedColor),
                      onPressed: () => onDelete(r), // no confirmation
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
