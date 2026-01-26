import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool _biometricEnabled = true;
  bool _pushAlerts = true;
  bool _hideBalance = false;
  bool _twoFA = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color textColor = isDark ? Colors.white : Colors.grey.shade900;
    Color subtitleColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    Color cardColor = isDark ? Colors.grey.shade900 : Colors.white;
    Color iconBackground = isDark ? Colors.grey.shade800 : Colors.deepOrange.shade50;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        elevation: 0,
        title: Text(
          "Security",
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
        ),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Authentication Section
            Text(
              "Authentication",
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: subtitleColor),
            ),
            SizedBox(height: 10),
            _buildListTile(
              title: "Change Password / PIN",
              icon: Icons.lock,
              cardColor: cardColor,
              iconBackground: iconBackground,
              textColor: textColor,
              onTap: () {},
            ),
            _buildListTile(
              title: "Enable Biometric Login",
              icon: Icons.fingerprint,
              cardColor: cardColor,
              iconBackground: iconBackground,
              textColor: textColor,
              trailing: Switch(
                value: _biometricEnabled,
                onChanged: (val) {
                  setState(() => _biometricEnabled = val);
                },
                activeColor: Colors.deepOrange,
              ),
            ),
            _buildListTile(
              title: "Two-Factor Authentication (2FA)",
              icon: Icons.verified_user,
              cardColor: cardColor,
              iconBackground: iconBackground,
              textColor: textColor,
              trailing: Switch(
                value: _twoFA,
                onChanged: (val) {
                  setState(() => _twoFA = val);
                },
                activeColor: Colors.deepOrange,
              ),
            ),
            _buildListTile(
              title: "Login History / Active Sessions",
              icon: Icons.history,
              cardColor: cardColor,
              iconBackground: iconBackground,
              textColor: textColor,
              onTap: () {},
            ),

            SizedBox(height: 20),

            // 🔹 Transaction Security
            Text(
              "Transaction Security",
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: subtitleColor),
            ),
            SizedBox(height: 10),
            _buildListTile(
              title: "Transaction PIN / Authorization",
              icon: Icons.pin,
              cardColor: cardColor,
              iconBackground: iconBackground,
              textColor: textColor,
              onTap: () {},
            ),
            _buildListTile(
              title: "Limit Daily/Weekly Transactions",
              icon: Icons.timelapse,
              cardColor: cardColor,
              iconBackground: iconBackground,
              textColor: textColor,
              onTap: () {},
            ),
            _buildListTile(
              title: "Enable / Disable International Transactions",
              icon: Icons.public,
              cardColor: cardColor,
              iconBackground: iconBackground,
              textColor: textColor,
              onTap: () {},
            ),

            SizedBox(height: 20),

            // 🔹 Alerts & Privacy
            Text(
              "Alerts & Privacy",
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: subtitleColor),
            ),
            SizedBox(height: 10),
            _buildListTile(
              title: "Push / SMS Alerts for Transactions",
              icon: Icons.notifications_active,
              cardColor: cardColor,
              iconBackground: iconBackground,
              textColor: textColor,
              trailing: Switch(
                value: _pushAlerts,
                onChanged: (val) {
                  setState(() => _pushAlerts = val);
                },
                activeColor: Colors.deepOrange,
              ),
            ),
            _buildListTile(
              title: "Hide Balance on Home Screen",
              icon: Icons.visibility_off,
              cardColor: cardColor,
              iconBackground: iconBackground,
              textColor: textColor,
              trailing: Switch(
                value: _hideBalance,
                onChanged: (val) {
                  setState(() => _hideBalance = val);
                },
                activeColor: Colors.deepOrange,
              ),
            ),

            SizedBox(height: 20),

            // 🔹 Account Recovery
            Text(
              "Account Recovery",
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: subtitleColor),
            ),
            SizedBox(height: 10),
            _buildListTile(
              title: "Freeze Account",
              icon: Icons.block,
              cardColor: cardColor,
              iconBackground: iconBackground,
              textColor: textColor,
              onTap: () {},
            ),
            _buildListTile(
              title: "Report Suspicious Activity",
              icon: Icons.report,
              cardColor: cardColor,
              iconBackground: iconBackground,
              textColor: textColor,
              onTap: () {},
            ),
            _buildListTile(
              title: "Trusted Contacts",
              icon: Icons.group,
              cardColor: cardColor,
              iconBackground: iconBackground,
              textColor: textColor,
              onTap: () {},
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
    required Color cardColor,
    required Color iconBackground,
    required Color textColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(12),
          child: Icon(icon, size: 28, color: Colors.deepOrange),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: textColor),
        ),
        trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, size: 17, color: textColor),
        onTap: onTap,
      ),
    );
  }
}
