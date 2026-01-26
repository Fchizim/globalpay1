import 'package:flutter/material.dart';

class TargetSavingsPage extends StatefulWidget {
  const TargetSavingsPage({Key? key}) : super(key: key);

  @override
  State<TargetSavingsPage> createState() => _TargetSavingsPageState();
}

class _TargetSavingsPageState extends State<TargetSavingsPage>
    with TickerProviderStateMixin {
  late TabController tabController;

  final List<Map<String, dynamic>> trendingTargets = [
    {"title": "Accommodation", "icon": Icons.home},
    {"title": "Education", "icon": Icons.school},
    {"title": "Business", "icon": Icons.business_center},
    {"title": "Travel", "icon": Icons.flight},
  ];

  final List<Map<String, dynamic>> activeTargets = [
    {"name": "Mini Bus", "saved": 150000, "target": 500000, "daysLeft": 90},
    {"name": "Laptop", "saved": 120000, "target": 300000, "daysLeft": 60},
  ];

  final List<Map<String, dynamic>> endedTargets = [
    {"name": "New Phone", "saved": 200000, "target": 200000, "daysLeft": 0},
  ];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const Color primary = Colors.deepOrange;

    final Color surface = theme.colorScheme.surface; // main container colour
    final Color onSurface = theme.colorScheme.onSurface;
    final Color secondaryText = theme.textTheme.bodyMedium!.color!
        .withOpacity(isDark ? 0.6 : 0.7);

    return Scaffold(
      // 👇 changed here
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade100,
        elevation: 0,
        title: Text(
          'Target Savings',
          style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // target balance container
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Target Balance",
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "₦0.00",
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.lock,
                            color: secondaryText, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "Safe & secure savings",
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // trending targets
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Container(
                padding: const EdgeInsets.only(top: 13, bottom: 13),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text(
                        "Trending Targets",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: onSurface,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 95,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: trendingTargets.length,
                        itemBuilder: (context, index) {
                          final item = trendingTargets[index];
                          return Container(
                            width: 90,
                            margin: EdgeInsets.only(
                              left: index == 0 ? 20 : 8,
                              right: 8,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  height: 55,
                                  width: 55,
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrange.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    item["icon"] as IconData,
                                    color: primary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Flexible(
                                  child: Text(
                                    item["title"],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.deepOrange.shade50,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15)),
                ),
                child: TabBar(
                  controller: tabController,
                  labelColor: primary,
                  unselectedLabelColor: secondaryText,
                  indicatorColor: primary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: "Active Targets"),
                    Tab(text: "Ended Targets"),
                  ],
                ),
              ),
            ),

            // tab views
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: activeTargets.length,
                        itemBuilder: (context, index) {
                          final t = activeTargets[index];
                          return _targetCard(
                            t["name"],
                            t["saved"],
                            t["target"],
                            t["daysLeft"],
                            false,
                            surface,
                            onSurface,
                            primary,
                          );
                        },
                      ),
                      ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: endedTargets.length,
                        itemBuilder: (context, index) {
                          final t = endedTargets[index];
                          return _targetCard(
                            t["name"],
                            t["saved"],
                            t["target"],
                            t["daysLeft"],
                            true,
                            surface,
                            onSurface,
                            primary,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _targetCard(
      String name,
      int saved,
      int target,
      int daysLeft,
      bool ended,
      Color cardColor,
      Color textColor,
      Color primary,
      ) {
    final progress = (saved / target).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: textColor
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ended ? Colors.grey : primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${(progress * 100).toStringAsFixed(0)}%",
                  style: TextStyle(
                    color: ended ? Colors.grey[800] : primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            color: ended ? Colors.grey : primary,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Saved: ₦$saved",
                style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
              ),
              Text(
                "Target: ₦$target",
                style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            ended ? "Completed" : "$daysLeft days left",
            style: TextStyle(
              fontSize: 13,
              color: ended ? Colors.grey : primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
