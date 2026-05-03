// help_screen.dart
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
// import '../models/app_settings.dart'; // adjust path
import 'package:url_launcher/url_launcher.dart';

import '../provider/settings_provider.dart';
import 'fraud.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _tabController = TabController(length: 3, vsync: this);

    // ── fetch settings ──
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().fetchSettings();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Responsive sizing
  double s(BuildContext context, double value) {
    final sw = MediaQuery.of(context).size.width;
    return (sw / 375 * value).clamp(value * 0.85, value * 1.25);
  }

  Widget _floating({required Widget child, double offset = 8}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = offset * math.sin((_controller.value * 2 * math.pi));
        return Transform.translate(offset: Offset(0, value), child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double spacing = s(context, 16);

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing,
                vertical: spacing / 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Service Header
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Customer Service Center",
                            style: TextStyle(
                              fontSize: s(context, 18),
                              fontWeight: FontWeight.w700,
                              color: theme.textTheme.headlineMedium?.color,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "24/7 Service for You",
                            style: TextStyle(
                              fontSize: s(context, 12),
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      Container(
                        width: s(context, 50),
                        height: s(context, 50),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // image: DecorationImage(
                          //   image: AssetImage(
                          //       "assets/images/png/friendlyroboticsalesmanager.jpeg"),
                          //   fit: BoxFit.cover,
                          // ),
                        ),
                      ),
                    ],
                  ),

                  // Fraud Card
                  SizedBox(height: s(context, 12)),
                  _floating(
                    offset: s(context, 8),
                    child: ClipPath(
                      clipper: WaveClipperSmall(),
                      child: Container(
                        padding: EdgeInsets.all(s(context, 16)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.shade400,
                              Colors.orange.shade300,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(s(context, 16)),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReportFraudPage(),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(s(context, 10)),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  IconsaxPlusBold.warning_2,
                                  color: Colors.red,
                                  size: s(context, 24),
                                ),
                              ),
                              SizedBox(width: s(context, 12)),
                              Expanded(
                                child: Text(
                                  "Report Fraud",
                                  style: TextStyle(
                                    fontSize: s(context, 14),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Icon(
                                IconsaxPlusLinear.arrow_right_3,
                                color: Colors.white,
                                size: s(context, 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Action Grid: 4 per row, responsive height
                  SizedBox(height: s(context, 16)),
                  LayoutBuilder(
                    builder: (context, gridConstraints) {
                      final cellWidth =
                          (gridConstraints.maxWidth - 3 * s(context, 12)) / 4;
                      return GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 4,
                        crossAxisSpacing: s(context, 12),
                        mainAxisSpacing: s(context, 12),
                        childAspectRatio:
                            cellWidth /
                            (cellWidth + s(context, 24)), // ensures text fits
                        physics: NeverScrollableScrollPhysics(),
                        children: _actionItems(theme, context),
                      );
                    },
                  ),

                  // TabBar
                  SizedBox(height: s(context, 16)),
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.deepOrange,
                    unselectedLabelColor: theme.textTheme.bodyMedium?.color,
                    indicator: UnderlineTabIndicator(
                      borderSide: BorderSide(
                        color: Colors.deepOrange,
                        width: 3,
                      ),
                      insets: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    tabs: const [
                      Tab(text: "Hot Issues"),
                      Tab(text: "Transactions"),
                      Tab(text: "Account"),
                    ],
                  ),

                  // TabBar content
                  SizedBox(
                    height: constraints.maxHeight * 0.6,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTabContent(context, theme, [
                          "What is Stamp Duty",
                          "How to increase limit",
                          "How to change mobile number",
                        ]),
                        _buildTabContent(context, theme, [
                          "Debited for failed transaction",
                          "Why is the transfer still pending",
                          "Transfer successful but not credited",
                          "How to manage card PIN",
                        ]),
                        _buildTabContent(context, theme, [
                          "What is my upgrade process",
                          "How to change PIN",
                          "How to update personal details",
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _actionItems(ThemeData theme, BuildContext context) {
    final settings = context.read<SettingsProvider>().settings;

    final items = [
      {
        'icon': IconsaxPlusLinear.message,
        'title': 'Chat',
        'onTap': () => launchUrl(
          Uri.parse('https://wa.me/${settings.whatsappNumber}'),
          mode: LaunchMode.externalApplication,
        ),
      },
      {
        'icon': IconsaxPlusLinear.call,
        'title': 'Call',
        'onTap': () => launchUrl(Uri(scheme: 'tel', path: settings.callNumber)),
      },
      {
        'icon': IconsaxPlusLinear.security,
        'title': 'Account',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HelpDetailScreen(title: 'Account Help'),
          ),
        ),
      },
      {
        'icon': IconsaxPlusLinear.refresh,
        'title': 'Transactions',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HelpDetailScreen(title: 'Transaction Issues'),
          ),
        ),
      },
      {
        'icon': IconsaxPlusLinear.book,
        'title': 'FAQs',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HelpDetailScreen(title: 'FAQs')),
        ),
      },
      {
        'icon': IconsaxPlusLinear.direct_inbox,
        'title': 'Email',
        'onTap': () =>
            launchUrl(Uri(scheme: 'mailto', path: settings.supportEmail)),
      },
      {
        'icon': IconsaxPlusLinear.profile_tick,
        'title': 'KYC Upgrade',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HelpDetailScreen(title: 'KYC Upgrade'),
          ),
        ),
      },
      {
        'icon': IconsaxPlusLinear.global,
        'title': 'Office',
        'onTap': () {
          // Show address in a snackbar or navigate to a map
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                settings.address.isNotEmpty
                    ? settings.address
                    : 'Address not available',
              ),
            ),
          );
        },
      },
    ];

    return items
        .map(
          (item) => _actionCard(
            item['icon'] as IconData,
            item['title'] as String,
            item['onTap'] as VoidCallback,
            theme,
            context,
          ),
        )
        .toList();
  }

  Widget _actionCard(
    IconData icon,
    String title,
    VoidCallback onTap,
    ThemeData theme,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(s(context, 12)),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(s(context, 16)),
            ),
            child: Icon(icon, color: Colors.deepOrange, size: s(context, 24)),
          ),
          SizedBox(height: s(context, 6)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: s(context, 12),
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    ThemeData theme,
    List<String> items,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView.separated(
          padding: EdgeInsets.symmetric(vertical: s(context, 8)),
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(
                "${index + 1}. ${items[index]}",
                style: TextStyle(
                  fontSize: s(context, 14),
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: s(context, 16)),
              onTap: () {
                if (items[index] == "What is Stamp Duty") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StampDutyPage()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          HelpDetailScreen(title: items[index]),
                    ),
                  );
                }
              },
            );
          },
          separatorBuilder: (_, __) => Divider(color: Colors.grey.shade300),
          itemCount: items.length,
        );
      },
    );
  }
}

// General Help Detail Page
class HelpDetailScreen extends StatelessWidget {
  final String title;
  const HelpDetailScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          "Detailed explanation for '$title' goes here. You can describe steps, FAQs, or any guidance for this topic.",
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
      ),
    );
  }
}

// Well-designed Stamp Duty Page
class StampDutyPage extends StatelessWidget {
  const StampDutyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("What is Stamp Duty")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Understanding Stamp Duty",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              "Stamp duty is a tax charged on legal documents, usually in the transfer of assets or property. It ensures that the transaction is officially recognized by the government and helps fund public services.",
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 12),
            Text(
              "Key Points:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("• Stamp duty applies to property transactions."),
                Text(
                  "• It may also apply to shares and certain legal documents.",
                ),
                Text("• The rate depends on the value of the asset."),
                Text("• Paid to the government, usually during registration."),
              ],
            ),
            SizedBox(height: 16),
            Text(
              "Benefits of Understanding Stamp Duty",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              "Knowing about stamp duty helps you plan financial transactions, avoid penalties, and ensure that your property or assets are legally recognized.",
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// Floating Card Clipper
class WaveClipperSmall extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 16);
    var controlPoint = Offset(size.width / 2, size.height + 16);
    var endPoint = Offset(size.width, size.height - 16);
    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
