import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class UsersPages extends StatefulWidget {
  const UsersPages({super.key});

  @override
  State<UsersPages> createState() => _UsersPagesState();
}

class _UsersPagesState extends State<UsersPages> {
  bool isFollowing = false; // Track if user tapped notification bell

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
    final secondaryTextColor = isDarkMode ? Colors.white60 : Colors.grey.shade600;
    final dividerColor = isDarkMode ? Colors.white24 : Colors.grey.shade300;
    final buttonGradient = isDarkMode
        ? LinearGradient(
      colors: [
        Colors.blueGrey.shade700,
        Colors.blueGrey.shade900,
      ],
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
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.deepOrange.shade50,
                    backgroundImage: const AssetImage("assets/images/png/temu.jpeg"),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Temu',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(IconsaxPlusBold.verify, color: Colors.deepOrange),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('4.9', style: TextStyle(fontSize: 17, color: textColor)),
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
                            child: const Icon(Icons.star, color: Color(0xFFFFD700), size: 22),
                          ),
                        ),
                      ),
                      Text(
                        ' 153 Reviews',
                        style: TextStyle(fontSize: 16, color: secondaryTextColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Notification / Follow button
                      InkWell(
                        onTap: () {
                          setState(() {
                            isFollowing = !isFollowing;
                          });
                        },
                        borderRadius: BorderRadius.circular(40),
                        child: Container(
                          height: 47,
                          width: 170,
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                IconsaxPlusLinear.notification,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isFollowing ? 'Following' : 'Notify',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Message button
                      Container(
                        height: 47,
                        width: 170,
                        decoration: BoxDecoration(
                          border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Center(
                          child: Text(
                            'Message',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(width: 17),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '67.3K\n',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      TextSpan(
                        text: 'Followers',
                        style: TextStyle(fontSize: 15, color: secondaryTextColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 17),
                Container(height: 40, width: 1, color: dividerColor),
                const SizedBox(width: 17),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '120\n',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
                      ),
                      TextSpan(
                        text: 'Products',
                        style: TextStyle(fontSize: 15, color: secondaryTextColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 17),
                Container(height: 40, width: 1, color: dividerColor),
                const SizedBox(width: 17),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '2019\n',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
                      ),
                      TextSpan(
                        text: 'Est. 2019',
                        style: TextStyle(fontSize: 15, color: secondaryTextColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(height: 40, width: 1, color: dividerColor),
                const SizedBox(width: 17),
                Column(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.red),
                    Text("USA, Florida", style: TextStyle(fontSize: 15, color: textColor)),
                  ],
                ),
              ],
            ),
            Divider(color: dividerColor),
          ],
        ),
      ),
    );
  }
}
