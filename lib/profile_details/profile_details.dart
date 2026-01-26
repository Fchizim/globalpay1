import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:globalpay/me/profile_upgrade.dart';
import 'package:globalpay/profile_details/email_binding.dart';
import 'package:globalpay/profile_details/invite.dart';
import 'package:globalpay/profile_details/kyc_level.dart';

/// Helper class for storing user name
class LocalUser {
  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  static Future<void> setName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', name);
  }
}

class ProfileDetails extends StatefulWidget {
  const ProfileDetails({super.key});

  @override
  State<ProfileDetails> createState() => _ProfileDetailsState();
}

class _ProfileDetailsState extends State<ProfileDetails> {
  String? userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    userName = await LocalUser.getName();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final scaffoldColor = isDark ? const Color(0xFF121212) : Colors.grey.shade100;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: scaffoldColor,
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _openPhotoSheet(context, theme),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundImage: const AssetImage('assets/images/png/gold.jpg'),
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        ),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.primary,
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Hi, ${userName ?? 'Gold'}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 6),
                          Icon(IconsaxPlusBold.verify, color: theme.colorScheme.primary, size: 20),
                        ],
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const KycLevelsPage()));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'President',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Invite Friends
            _sectionCard(
              theme,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InviteFriends())),
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: theme.colorScheme.primary,
                child: const Icon(IconsaxPlusBold.add, color: Colors.white),
              ),
              title: "Invite friends",
              subtitle: "Get ₦10,000 reward",
            ),

            const SizedBox(height: 30),

            // Profile Info - Top
            _profileInfoCard(
              context,
              cardColor: cardColor,
              items: [
                _infoRow("Account Number", "1234567890"),
                _infoRow("Email", "Add Email", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmailBinding()))),
                _infoRow("Full Name", userName ?? "GOLD EMMANUEL"),
                _infoRow("Nickname", "Goldy"),
                _infoRow("Mobile Number", "+1 234 567 8900"),
                _infoRow("Gender", "Male"),
              ],
            ),

            const SizedBox(height: 15),

            // Profile Info - Bottom
            _profileInfoCard(
              context,
              cardColor: cardColor,
              items: [
                _infoRow("Date of Birth", "2005-05-17"),
                _infoRow("Address", "123, Enugu, Nigeria"),
                _infoRow("Location", "USA"),
                _infoRow("KYC Level", "President", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KycLevel()))),
              ],
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  /// --- Helper Widgets ---
  Widget _profileInfoCard(BuildContext context, {required Color cardColor, required List<Widget> items}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: theme.shadowColor.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: items.map((item) => Column(children: [item, _divider(theme)])).toList(),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final textColor = theme.hintColor;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Row(
              children: [
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
                if (onTap != null) const SizedBox(width: 4),
                if (onTap != null) Icon(Icons.arrow_forward_ios_rounded, size: 16, color: textColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Divider(color: isDark ? Colors.grey[800] : Colors.grey[200], indent: 16, endIndent: 16);
  }

  Widget _sectionCard(ThemeData theme, {required VoidCallback onTap, required Widget leading, required String title, String? subtitle}) {
    final bool isDark = theme.brightness == Brightness.dark;
    final Color customCardColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFF0EB);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 85,
          decoration: BoxDecoration(
            color: customCardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: theme.shadowColor.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  leading,
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                      if (subtitle != null)
                        Text(subtitle, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: theme.hintColor)),
                    ],
                  ),
                ],
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: theme.hintColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _openPhotoSheet(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      backgroundColor: theme.cardColor,
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetOption(icon: Icons.camera_alt, label: 'Take a Photo', onTap: () {}),
              Divider(color: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100]),
              _sheetOption(icon: Icons.photo_library, label: 'Choose from Albums', onTap: () {}),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                  child: const Icon(Icons.close, color: Colors.red, size: 26),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetOption({required IconData icon, required String label, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(radius: 20, backgroundColor: theme.colorScheme.primary.withOpacity(0.1), child: Icon(icon, color: theme.colorScheme.primary)),
      title: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}