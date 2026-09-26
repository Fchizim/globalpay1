import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class UsersPages extends StatefulWidget {
  const UsersPages({super.key});

  @override
  State<UsersPages> createState() => _UsersPagesState();
}

class _UsersPagesState extends State<UsersPages> {
  bool isFollowing = false; // Track if user tapped notification bell

  double s(double value, BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return (sw / 375 * value).clamp(value * 0.85, value * 1.25);
  }

  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 700;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final maxContentWidth = _isTablet(context) ? 720.0 : double.infinity;

    // Dimmed dark mode gradient for fintech style
    final bgGradient = isDarkMode
        ? LinearGradient(
            colors: [
              Colors.grey.shade900,
              Colors.grey.shade900,
              Colors.grey.shade900,
              Colors.grey.shade800,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomLeft,
          )
        : LinearGradient(
            colors: [
              Colors.orange.shade50,
              Colors.grey.shade50,
              Colors.grey.shade50,
              Colors.grey.shade50,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomLeft,
          );

    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white60
        : Colors.grey.shade600;
    final dividerColor = isDarkMode ? Colors.white24 : Colors.grey.shade300;
    final buttonGradient = isDarkMode
        ? LinearGradient(
            colors: [Colors.blueGrey.shade700, Colors.blueGrey.shade900],
            begin: Alignment.topLeft,
          )
        : LinearGradient(
            colors: [
              Colors.blue,
              Colors.blueAccent.shade700,
              Colors.blueAccent.shade700,
            ],
            begin: Alignment.topLeft,
          );

    return Container(
      decoration: BoxDecoration(gradient: bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: textColor),
        ),
        // Wrapped in SingleChildScrollView + tablet width cap so this
        // never overflows vertically on a short/landscape screen, and
        // never stretches too wide on a tablet.
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: s(55, context),
                          backgroundColor: isDarkMode
                              ? Colors.grey.shade800
                              : Colors.deepOrange.shade50,
                          backgroundImage: const AssetImage(
                            "assets/images/png/temu.jpeg",
                          ),
                        ),
                        SizedBox(height: s(10, context)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Temu',
                              style: TextStyle(
                                fontSize: s(25, context),
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                            SizedBox(width: s(5, context)),
                            Icon(
                              IconsaxPlusBold.verify,
                              color: Colors.deepOrange,
                            ),
                          ],
                        ),
                        SizedBox(height: s(5, context)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '4.9',
                              style: TextStyle(
                                fontSize: s(17, context),
                                color: textColor,
                              ),
                            ),
                            Row(
                              children: List.generate(
                                5,
                                (index) => ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: const [
                                      Color(0xFFFFD700),
                                      Color(0xFFFFA500),
                                      Color(0xFFFFFF00),
                                      Color(0xFFFFD700),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  child: Icon(
                                    Icons.star,
                                    color: const Color(0xFFFFD700),
                                    size: s(22, context),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              ' 153 Reviews',
                              style: TextStyle(
                                fontSize: s(16, context),
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: s(20, context)),
                        // Buttons row: the two buttons used to be a fixed
                        // 170px wide each (340px total), which overflows
                        // on almost any phone screen. Now each button is
                        // Expanded so together they always exactly fill
                        // the available width, however narrow or wide
                        // the device is.
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: s(17, context),
                          ),
                          child: Row(
                            children: [
                              // Notification / Follow button
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      isFollowing = !isFollowing;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(40),
                                  child: Container(
                                    height: s(47, context),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(40),
                                      gradient: isFollowing
                                          ? LinearGradient(
                                              colors: [
                                                Colors.green.shade600,
                                                Colors.green.shade800,
                                              ],
                                              begin: Alignment.topLeft,
                                            )
                                          : buttonGradient,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          IconsaxPlusLinear.notification,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: s(8, context)),
                                        Flexible(
                                          child: Text(
                                            isFollowing
                                                ? 'Following'
                                                : 'Notify',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                              fontSize: s(18, context),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(width: s(12, context)),

                              // Message button
                              Expanded(
                                child: Container(
                                  height: s(47, context),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isDarkMode
                                          ? Colors.white24
                                          : Colors.black,
                                    ),
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Message',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: s(20, context),
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: s(10, context)),
                  // Stats row: previously a plain Row with fixed gaps
                  // between four variable-width blocks — the total
                  // easily exceeded any phone's screen width. Now each
                  // block is Expanded so the row always exactly fits
                  // the available width instead of overflowing.
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '67.3K\n',
                                    style: TextStyle(
                                      fontSize: s(20, context),
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Followers',
                                    style: TextStyle(
                                      fontSize: s(15, context),
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        VerticalDivider(
                          color: dividerColor,
                          width: 1,
                          indent: 8,
                          endIndent: 8,
                        ),
                        Expanded(
                          child: Center(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '120\n',
                                    style: TextStyle(
                                      fontSize: s(20, context),
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Products',
                                    style: TextStyle(
                                      fontSize: s(15, context),
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        VerticalDivider(
                          color: dividerColor,
                          width: 1,
                          indent: 8,
                          endIndent: 8,
                        ),
                        Expanded(
                          child: Center(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '2019\n',
                                    style: TextStyle(
                                      fontSize: s(20, context),
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Est. 2019',
                                    style: TextStyle(
                                      fontSize: s(15, context),
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        VerticalDivider(
                          color: dividerColor,
                          width: 1,
                          indent: 8,
                          endIndent: 8,
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: Colors.red,
                              ),
                              Text(
                                "USA, Florida",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: s(15, context),
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: dividerColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
