import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // Sample notifications
  List<Map<String, dynamic>> notifications = [
    {
      'icon': IconsaxPlusBold.wallet_1,
      'title': 'Payment Received',
      'subtitle': 'You received \$50 from John',
      'time': DateTime.now().subtract(Duration(hours: 2)),
      'unread': true,
    },
    {
      'icon': IconsaxPlusBold.warning_2,
      'title': 'Security Alert',
      'subtitle': 'Login from a new device',
      'time': DateTime.now().subtract(Duration(hours: 5)),
      'unread': true,
    },
    {
      'icon': IconsaxPlusBold.gift,
      'title': 'Special Offer',
      'subtitle': 'Earn 5% cashback today',
      'time': DateTime.now().subtract(Duration(days: 1)),
      'unread': false,
    },
  ];

  Future<void> _refreshNotifications() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      notifications.insert(0, {
        'icon': IconsaxPlusBold.wallet_1,
        'title': 'Payment Sent',
        'subtitle': 'You sent \$20 to Mary',
        'time': DateTime.now(),
        'unread': true,
      });
    });
  }

  String formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inMinutes < 60) {
      return '${now.difference(time).inMinutes} min ago';
    } else if (now.difference(time).inHours < 24) {
      return '${now.difference(time).inHours}h ago';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bgColor = isDark ? Colors.grey.shade900 : Colors.grey.shade50;
    Color cardColorUnread = isDark ? Colors.grey.shade800 : Colors.deepOrange.shade50;
    Color cardColorRead = isDark ? Colors.grey.shade50 : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.grey.shade900;
    Color subtitleColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    Color trailingColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    Color iconBgColor = isDark ? Colors.grey.shade800 : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var n in notifications) {
                  n['unread'] = false;
                }
              });
            },
            child: Text(
              'Mark all read',
              style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
      body: RefreshIndicator(
        color: Colors.deepOrange,
        onRefresh: _refreshNotifications,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          physics: BouncingScrollPhysics(),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final item = notifications[index];
            final bool unread = item['unread'] as bool;
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: unread ? cardColorUnread : cardColorRead,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : Colors.grey.shade200,
                    blurRadius: 20,
                    offset: Offset(0, 5),
                  )
                ],
              ),
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item['icon'], size: 28, color: Colors.deepOrange),
                ),
                title: Text(
                  item['title'],
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
                ),
                subtitle: Text(
                  item['subtitle'],
                  style: TextStyle(fontSize: 14, color: subtitleColor),
                ),
                trailing: Text(
                  formatTime(item['time']),
                  style: TextStyle(fontSize: 12, color: trailingColor),
                ),
                onTap: () {
                  setState(() {
                    item['unread'] = false;
                  });
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
