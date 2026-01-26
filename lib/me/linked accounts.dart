import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
<<<<<<< HEAD
import 'package:untitle1/me/profile_upgrade.dart';
=======
import 'package:globalpay/me/profile_upgrade.dart';
>>>>>>> c30d5f6 (initial commit)

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  bool darkMode = false;
  bool notifications = true;
  bool biometric = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- Themed Colors ---
    final bgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF7F7F7);
    final containerColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
<<<<<<< HEAD
    final secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
=======
    final secondaryTextColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade600;
>>>>>>> c30d5f6 (initial commit)
    final dividerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text("App Settings", style: TextStyle(color: textColor)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const SizedBox(height: 8),

          // ACCOUNT SECTION
          _buildSectionTitle("Account", secondaryTextColor),
          _buildContainer(containerColor, [
<<<<<<< HEAD
            _buildTile(IconsaxPlusBold.link, "Linked Accounts", textColor, onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KycLevelsPage()),
              );
            }),
            _divider(dividerColor),
            _buildTile(Icons.block, "Freeze Account", textColor, onTap: () {}),
            _divider(dividerColor),
            _buildTile(Icons.warning, "Report Suspicious Activities", textColor, onTap: () {}),
=======
            _buildTile(
              IconsaxPlusBold.link,
              "Linked Accounts",
              textColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KycLevelsPage()),
                );
              },
            ),
            _divider(dividerColor),
            _buildTile(Icons.block, "Freeze Account", textColor, onTap: () {}),
            _divider(dividerColor),
            _buildTile(
              Icons.warning,
              "Report Suspicious Activities",
              textColor,
              onTap: () {},
            ),
>>>>>>> c30d5f6 (initial commit)
          ]),

          const SizedBox(height: 20),

          // SECURITY SECTION
          _buildSectionTitle("Security", secondaryTextColor),
          _buildContainer(containerColor, [
<<<<<<< HEAD
            _buildSwitchTile(Icons.fingerprint, "Use Biometrics", biometric, (val) => setState(() => biometric = val), isDark),
            _divider(dividerColor),
            _buildTile(IconsaxPlusBold.lock, "Change Password / Pin", textColor, onTap: () {}),
            _divider(dividerColor),
            _buildTile(IconsaxPlusBold.security_safe, "Two-Factor Auth (2FA)", textColor, onTap: () {}),
            _divider(dividerColor),
            _buildTile(Icons.history, "Login history / Active session", textColor, onTap: () {}),
=======
            _buildSwitchTile(
              Icons.fingerprint,
              "Use Biometrics",
              biometric,
              (val) => setState(() => biometric = val),
              isDark,
            ),
            _divider(dividerColor),
            _buildTile(
              IconsaxPlusBold.lock,
              "Change Password / Pin",
              textColor,
              onTap: () {},
            ),
            _divider(dividerColor),
            _buildTile(
              IconsaxPlusBold.security_safe,
              "Two-Factor Auth (2FA)",
              textColor,
              onTap: () {},
            ),
            _divider(dividerColor),
            _buildTile(
              Icons.history,
              "Login history / Active session",
              textColor,
              onTap: () {},
            ),
>>>>>>> c30d5f6 (initial commit)
          ]),

          const SizedBox(height: 20),

          // TRANSACTION SECURITY
          _buildSectionTitle("Transaction Security", secondaryTextColor),
          _buildContainer(containerColor, [
<<<<<<< HEAD
            _buildTile(IconsaxPlusBold.password_check, "Transaction Pin", textColor, onTap: () {}),
            _divider(dividerColor),
            _buildTile(Icons.timelapse, "Limit daily/Weekly transactions", textColor, onTap: () {}),
            _divider(dividerColor),
            _buildTile(Icons.public, "Enable / Disable\nInternational Transactions", textColor, onTap: () {}),
=======
            _buildTile(
              IconsaxPlusBold.password_check,
              "Transaction Pin",
              textColor,
              onTap: () {},
            ),
            _divider(dividerColor),
            _buildTile(
              Icons.timelapse,
              "Limit daily/Weekly transactions",
              textColor,
              onTap: () {},
            ),
            _divider(dividerColor),
            _buildTile(
              Icons.public,
              "Enable / Disable\nInternational Transactions",
              textColor,
              onTap: () {},
            ),
>>>>>>> c30d5f6 (initial commit)
          ]),

          const SizedBox(height: 20),

          // NOTIFICATIONS
          _buildSectionTitle("Notifications", secondaryTextColor),
          _buildContainer(containerColor, [
<<<<<<< HEAD
            _buildSwitchTile(IconsaxPlusBold.notification, "App Notifications", notifications, (val) => setState(() => notifications = val), isDark),
=======
            _buildSwitchTile(
              IconsaxPlusBold.notification,
              "App Notifications",
              notifications,
              (val) => setState(() => notifications = val),
              isDark,
            ),
>>>>>>> c30d5f6 (initial commit)
          ]),

          const SizedBox(height: 20),

          // APP
          _buildSectionTitle("App", secondaryTextColor),
          _buildContainer(containerColor, [
<<<<<<< HEAD
            _buildTile(IconsaxPlusBold.language_circle, "Language", textColor, onTap: () {}),
            _divider(dividerColor),
            _buildTile(IconsaxPlusBold.info_circle, "About App", textColor, onTap: () {}),
            _divider(dividerColor),
            _buildTile(IconsaxPlusBold.clipboard_close, "Close Account", textColor, onTap: () {}),
            _divider(dividerColor),
            _buildTile(IconsaxPlusBold.logout, "Logout", textColor, onTap: () {}),
=======
            _buildTile(
              IconsaxPlusBold.language_circle,
              "Language",
              textColor,
              onTap: () {},
            ),
            _divider(dividerColor),
            _buildTile(
              IconsaxPlusBold.info_circle,
              "About App",
              textColor,
              onTap: () {},
            ),
            _divider(dividerColor),
            _buildTile(
              IconsaxPlusBold.clipboard_close,
              "Close Account",
              textColor,
              onTap: () {},
            ),
            _divider(dividerColor),
            _buildTile(
              IconsaxPlusBold.logout,
              "Logout",
              textColor,
              onTap: () {},
            ),
>>>>>>> c30d5f6 (initial commit)
          ]),
        ],
      ),
    );
  }

  Widget _divider(Color color) {
    return Divider(
      height: 1,
      color: color,
      thickness: 0.8,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
<<<<<<< HEAD
      child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
=======
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
>>>>>>> c30d5f6 (initial commit)
    );
  }

  Widget _buildContainer(Color bgColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
<<<<<<< HEAD
            color: bgColor == Colors.white ? Colors.grey.shade200 : Colors.black.withOpacity(0.2),
=======
            color: bgColor == Colors.white
                ? Colors.grey.shade200
                : Colors.black.withOpacity(0.2),
>>>>>>> c30d5f6 (initial commit)
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

<<<<<<< HEAD
  Widget _buildTile(IconData icon, String title, Color textColor, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepOrange),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: Icon(IconsaxPlusLinear.arrow_right_3, color: textColor.withOpacity(0.5)),
=======
  Widget _buildTile(
    IconData icon,
    String title,
    Color textColor, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepOrange),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: Icon(
        IconsaxPlusLinear.arrow_right_3,
        color: textColor.withOpacity(0.5),
      ),
>>>>>>> c30d5f6 (initial commit)
      onTap: onTap,
    );
  }

<<<<<<< HEAD
  Widget _buildSwitchTile(IconData icon, String title, bool value, Function(bool) onChanged, bool isDark) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.deepOrange),
      title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
=======
  Widget _buildSwitchTile(
    IconData icon,
    String title,
    bool value,
    Function(bool) onChanged,
    bool isDark,
  ) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.deepOrange),
      title: Text(
        title,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      ),
>>>>>>> c30d5f6 (initial commit)
      value: value,
      activeColor: Colors.deepOrange,
      onChanged: onChanged,
    );
  }
}
