import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// Needed for FilteringTextInputFormatter.digitsOnly, which forces a
// numeric-only keypad and blocks any non-digit even if the OS ever shows
// a full keyboard.

import '../models/user_model.dart';
import '../provider/authprovider.dart';
import '../onboarding_screen/auto_choice_page.dart';
import 'forgot_password.dart';

/// Primary brand color used across interactive elements (cursor, dot,
/// links, loading indicator). Kept as a single source of truth so the
/// whole screen stays visually consistent.
const _primary = Colors.deepOrange;

const _accentGradient = LinearGradient(
  colors: [Color(0xFFFF7A45), Color(0xFFFF4D8D)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Masks a phone number the same way the mockup does: keep the first 3 and
/// last 4 digits, replace the middle with asterisks.
String _maskPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 7) return phone;
  final start = digits.substring(0, 3);
  final end = digits.substring(digits.length - 4);
  return '$start **** $end';
}

class PinLoginPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final UserModel user;

  const PinLoginPage({
    super.key,
    required this.onToggleTheme,
    required this.user,
  });

  @override
  State<PinLoginPage> createState() => _PinLoginPageState();
}

class _PinLoginPageState extends State<PinLoginPage>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final _pins = List.generate(4, (_) => '');
  bool _submitting = false;

  // Drives the blinking text-cursor shown inside the currently active box.
  // Nullable + defensive: if a hot reload ever skips initState on an
  // existing State instance, build() falls back to a steady (non-null)
  // animation instead of throwing a LateInitializationError.
  AnimationController? _cursorAnim;

  double _scale(BuildContext context, double base) {
    final width = MediaQuery.of(context).size.width;
    final factor = (width / 375).clamp(0.85, 1.3);
    return base * factor;
  }

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onChange);
    _cursorAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => FocusScope.of(context).requestFocus(_focus),
    );
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onChange);
    _ctrl.dispose();
    _focus.dispose();
    _cursorAnim?.dispose();
    super.dispose();
  }

  void _onChange() {
    final v = _ctrl.text.replaceAll(RegExp(r'\D'), '');
    final t = v.length > 4 ? v.substring(0, 4) : v;
    setState(() {
      for (int i = 0; i < 4; i++) {
        _pins[i] = i < t.length ? t[i] : '';
      }
    });
    if (t.length == 4) _submit(t);
  }

  Future<void> _submit(String pin) async {
    setState(() => _submitting = true);

    final auth = context.read<AuthProvider>();
    final ok = await auth.unlockWithPin(context, pin);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (!ok) {
      HapticFeedback.mediumImpact();
      setState(() {
        _pins.setAll(0, ['', '', '', '']);
        _ctrl.clear();
      });
    }
    // On success, AuthProvider.notifyListeners() flips isLoggedIn to true
    // and MyApp's Consumer swaps the whole `home:` widget to MyAppsPage —
    // no manual navigation needed here.
  }

  Future<void> _switchAccount() async {
    await context.read<AuthProvider>().switchAccount();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => AuthChoicePage(onToggleTheme: widget.onToggleTheme),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF7F7F7);
    final tc = isDark ? Colors.white : Colors.black87;
    final secondaryTc = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final boxBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final auth = context.watch<AuthProvider>();
    final error = auth.pinError;
    final hasError = error != null;

    final screenWidth = MediaQuery.of(context).size.width;
    final maxContentWidth = screenWidth > 600 ? 480.0 : screenWidth;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: _scale(context, 24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _switchAccount,
                    icon: Icon(
                      Icons.sync_alt_rounded,
                      size: _scale(context, 16),
                      color: secondaryTc,
                    ),
                    label: Text(
                      'Switch Account',
                      style: TextStyle(
                        color: tc,
                        fontSize: _scale(context, 14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: _scale(context, 10),
                        vertical: _scale(context, 4),
                      ),
                    ),
                  ),

                  SizedBox(height: _scale(context, 24)),

                  // Avatar
                  Center(
                    child: Container(
                      width: _scale(context, 64),
                      height: _scale(context, 64),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _accentGradient,
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(2.5),
                      child: ClipOval(
                        child: Container(
                          color: boxBg,
                          child: widget.user.image.isNotEmpty
                              ? Image.network(
                                  widget.user.image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.person,
                                    color: secondaryTc,
                                    size: _scale(context, 34),
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  color: secondaryTc,
                                  size: _scale(context, 34),
                                ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: _scale(context, 16)),

                  Center(
                    child: Text(
                      _maskPhone(widget.user.phone),
                      style: TextStyle(
                        fontSize: _scale(context, 19),
                        fontWeight: FontWeight.w600,
                        color: tc,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),

                  SizedBox(height: _scale(context, 4)),

                  Center(
                    child: Text(
                      widget.user.name,
                      style: TextStyle(
                        fontSize: _scale(context, 13.5),
                        color: secondaryTc,
                      ),
                    ),
                  ),

                  SizedBox(height: _scale(context, 14)),

                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _scale(context, 13),
                        vertical: _scale(context, 6),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_rounded,
                            size: _scale(context, 14),
                            color: Colors.green.shade600,
                          ),
                          SizedBox(width: _scale(context, 6)),
                          Text(
                            'Auto-Logout Protection',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: _scale(context, 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: _scale(context, 28)),

                  Center(
                    child: Text(
                      'Enter 4 digits PIN to login',
                      style: TextStyle(
                        fontSize: _scale(context, 14.5),
                        color: secondaryTc,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  SizedBox(height: _scale(context, 18)),

                  // PIN boxes — width-derived so 4 boxes + gaps never
                  // overflow a narrow phone. Smaller footprint than before,
                  // with a blinking cursor in the active box that turns
                  // into a solid dot once a digit is entered.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => FocusScope.of(context).requestFocus(_focus),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final boxSize = ((constraints.maxWidth - 3 * 10) / 4)
                            .clamp(44.0, 56.0);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (i) {
                            final filled = _pins[i].isNotEmpty;
                            final isCursor = _ctrl.text.length == i;
                            final borderColor = hasError
                                ? Colors.red
                                : (isCursor ? _primary : Colors.transparent);

                            Widget content;
                            if (filled) {
                              content = Container(
                                width: _scale(context, 9),
                                height: _scale(context, 9),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: hasError ? Colors.red : _primary,
                                ),
                              );
                            } else if (isCursor) {
                              content = FadeTransition(
                                opacity:
                                    _cursorAnim ??
                                    const AlwaysStoppedAnimation(1.0),
                                child: Container(
                                  width: 2,
                                  height: _scale(context, 22),
                                  decoration: BoxDecoration(
                                    color: _primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            } else {
                              content = const SizedBox.shrink();
                            }

                            return Padding(
                              padding: EdgeInsets.only(right: i == 3 ? 0 : 10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: boxSize,
                                height: boxSize,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: boxBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 1.4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black.withOpacity(0.3)
                                          : Colors.black.withOpacity(0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: content,
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),

                  if (hasError) ...[
                    SizedBox(height: _scale(context, 10)),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: _scale(context, 14),
                            color: Colors.red.shade400,
                          ),
                          SizedBox(width: _scale(context, 4)),
                          Text(
                            error,
                            style: TextStyle(
                              color: Colors.red.shade400,
                              fontSize: _scale(context, 12.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_submitting) ...[
                    SizedBox(height: _scale(context, 18)),
                    Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: _primary,
                        ),
                      ),
                    ),
                  ],

                  // Invisible-but-real field driving the PIN boxes — the
                  // exact same trick your GDrop PIN sheet already uses
                  // (normal-sized field, styled invisible via a near-zero
                  // font and transparent color). It has to actually be laid
                  // out and painted, not hidden with Offstage, or the OS
                  // never sees a real focused field to bring the keyboard
                  // up for.
                  TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    // Forces digits-only even if a device's numeric
                    // keyboard still exposes other characters.
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 4,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    style: const TextStyle(
                      fontSize: 0.01,
                      color: Colors.transparent,
                    ),
                  ),

                  SizedBox(height: _scale(context, 26)),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordPage(
                              email: '',
                              phoneNumber: '',
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: _primary),
                      child: Text(
                        'Forgot PIN',
                        style: TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w600,
                          fontSize: _scale(context, 15),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: _scale(context, 36)),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(vertical: _scale(context, 14)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shield_rounded,
                size: _scale(context, 15),
                color: Colors.green.shade600,
              ),
              SizedBox(width: _scale(context, 7)),
              Text(
                'Glonest Secure Keypad',
                style: TextStyle(
                  color: tc,
                  fontWeight: FontWeight.w600,
                  fontSize: _scale(context, 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
