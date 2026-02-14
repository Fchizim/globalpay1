import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';
import 'package:provider/provider.dart';
import '../provider/authprovider.dart'; // make sure path is correct
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:globalpay/me/2fa.dart';
import 'package:globalpay/me/about_app.dart';
import 'package:globalpay/me/change_pin.dart';
import 'package:globalpay/me/close_account.dart';
import 'package:globalpay/me/enable_int_trans.dart';
import 'package:globalpay/me/freeze_account.dart';
import 'package:globalpay/me/history.dart';
import 'package:globalpay/me/limits.dart';
import 'package:globalpay/profile_details/profile_upgrade.dart';
import 'package:globalpay/me/report.dart';
import 'package:globalpay/me/transaction.dart';
import 'package:globalpay/registration_page/login_page.dart'; // ✅ for logout redirect

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  bool darkMode = false;
  bool notifications = true;
  bool biometric = false;
  bool biometric2 = false;

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 💡 New theme colors
    final bgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF7F7F7);
    final containerColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
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

          _buildSectionTitle("Account", secondaryTextColor),
          _buildContainer(
            containerColor,
            [
              _buildTile(IconsaxPlusBold.link, "Linked Accounts", textColor, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const KycLevelsPage()));
              }),
              _divider(dividerColor),
              _buildTile(Icons.block, "Freeze Account", textColor, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FreezeAccountPage()));
              }),
              _divider(dividerColor),
              _buildTile(Icons.warning, "Report Suspicious Activities", textColor, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportSuspiciousActivityPage()));
              }),
            ],
          ),

          const SizedBox(height: 20),
          _buildSectionTitle("Security", secondaryTextColor),
          _buildContainer(
            containerColor,
            [
              _buildSwitchTile(Icons.fingerprint, "Use Biometrics for login", biometric,
                      (val) => setState(() => biometric = val), isDark),
              _divider(dividerColor),
              _buildTile(IconsaxPlusBold.lock, "Change Login Pin", textColor, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePinPage()));
              }),
              _divider(dividerColor),
              _buildTile(IconsaxPlusBold.security_safe, "Two-Factor Auth (2FA)", textColor, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TwoFAPage()));
              }),
              _divider(dividerColor),
              _buildTile(Icons.history, "Active session", textColor, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveSessionsPage()));
              }),
            ],
          ),

          const SizedBox(height: 20),
          _buildSectionTitle("Transaction Security", secondaryTextColor),
          _buildContainer(
            containerColor,
            [
              _buildSwitchTile(Icons.fingerprint, "Use Biometrics for transactions", biometric2,
                      (val) => setState(() => biometric2 = val), isDark),
              _divider(dividerColor),
              _buildTile(IconsaxPlusBold.password_check, "Transaction Pin", textColor, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionPinPage()));
              }),
              _divider(dividerColor),
              _buildTile(Icons.timelapse, "Limit daily/Weekly transactions", textColor, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionLimitPage()));
              }),
              _divider(dividerColor),
              _buildTile(Icons.public, "Enable / Disable\nInternational Transactions", textColor, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InternationalTransactionPage()));
              }),
            ],
          ),

          const SizedBox(height: 20),
          _buildSectionTitle("Notifications", secondaryTextColor),
          _buildContainer(
            containerColor,
            [
              _buildSwitchTile(IconsaxPlusBold.notification, "App Notifications", notifications,
                      (val) => setState(() => notifications = val), isDark),
            ],
          ),

          const SizedBox(height: 20),
          _buildSectionTitle("App", secondaryTextColor),
          _buildContainer(
            containerColor,
            [
              _buildTile(IconsaxPlusBold.language_circle, "Language", textColor, () {}),
              _divider(dividerColor),
              _buildTile(IconsaxPlusBold.info_circle, "About App", textColor, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutAppPage()));
              }),
              _divider(dividerColor),
              _buildTile(IconsaxPlusBold.clipboard_close, "Close Account", textColor, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CloseAccountPage()));
              }),
              _divider(dividerColor),
              _buildTile(IconsaxPlusBold.logout, "Logout", textColor, () {
                _confirmLogout(context);
              }),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // close dialog first

              // 🔐 Clear secure storage
              await SecureStorageService.logout();

              // 🧩 Clear provider state
              final auth = context.read<AuthProvider>();
              auth.logout();

              // 🚀 Navigate to login and remove all previous routes
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginPage(
                    onToggleTheme: () {},
                    onLoginSuccess: () {},
                  ),
                ),
                    (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _divider(Color color) {
    return Divider(height: 1, color: color, thickness: 0.8, indent: 16, endIndent: 16);
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(title,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildContainer(Color bgColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _buildTile(IconData icon, String title, Color textColor, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepOrange),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: Icon(IconsaxPlusLinear.arrow_right_3, color: textColor.withOpacity(0.5)),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
      IconData icon, String title, bool value, Function(bool) onChanged, bool isDark) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.deepOrange),
      title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
      value: value,
      activeThumbColor: Colors.deepOrange,
      onChanged: onChanged,
    );
  }
}
