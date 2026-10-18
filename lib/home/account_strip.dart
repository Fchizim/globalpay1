import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// The strip attached to the bottom edge of the balance card on the home page.
///
/// It sits directly BELOW the card (no overlap), so the balance card's own
/// colours are never affected by it.
///
/// Animations:
///  1. Reveal: fades in when the page opens.
///  2. Shimmer + nudging arrow: while the user has no account number, a light
///     sweep passes over the strip and the arrow gently moves, so it draws
///     the eye to "Get a free account number".
///  3. Copy feedback: the copy icon turns into a tick and says "Copied" for
///     two seconds after tapping.
///  Content changes (loading -> account number, etc.) fade and slide in.
class AccountStrip extends StatefulWidget {
  final bool isGuest;
  final bool isDark;
  final bool loading;
  final bool pending;
  final String bank;
  final String number;
  final VoidCallback onCopy;
  final VoidCallback onGetAccount;

  const AccountStrip({
    super.key,
    required this.isGuest,
    required this.isDark,
    required this.loading,
    required this.pending,
    required this.bank,
    required this.number,
    required this.onCopy,
    required this.onGetAccount,
  });

  @override
  State<AccountStrip> createState() => _AccountStripState();
}

class _AccountStripState extends State<AccountStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop;
  bool _copied = false;
  Timer? _copiedTimer;

  bool get _hasAccount => !widget.isGuest && widget.number.isNotEmpty;
  bool get _isWaiting =>
      !widget.isGuest && !_hasAccount && (widget.loading || widget.pending);
  bool get _needsAttention => !_hasAccount && !_isWaiting;

  // Text/icon colours: white on the orange strip (light mode), soft white on
  // the dark strip with an orange accent for icons (dark mode).
  Color get _fg => Colors.white;
  Color get _accent =>
      widget.isDark ? Colors.deepOrange.shade300 : Colors.white;

  TextStyle get _label => TextStyle(
    color: _fg,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    letterSpacing: 0.2,
  );

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _syncLoop();
  }

  @override
  void didUpdateWidget(covariant AccountStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncLoop();
  }

  // Only run the repeating animation while it is actually needed.
  void _syncLoop() {
    if (_needsAttention) {
      if (!_loop.isAnimating) _loop.repeat();
    } else {
      _loop.stop();
    }
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    _loop.dispose();
    super.dispose();
  }

  void _handleCopy() {
    widget.onCopy();
    setState(() => _copied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Widget _spinner() => SizedBox(
    width: 12,
    height: 12,
    child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
  );

  Widget _buildContent() {
    if (_hasAccount) {
      final text = widget.bank.isEmpty
          ? widget.number
          : '${widget.bank}  •  ${widget.number}';
      return Row(
        key: const ValueKey('account'),
        children: [
          Icon(Icons.account_balance_rounded, size: 14, color: _accent),
          const SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                maxLines: 1,
                style: _label.copyWith(letterSpacing: 0.4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              _copied ? Icons.check_circle_rounded : Icons.copy_rounded,
              key: ValueKey(_copied),
              size: 14,
              color: _accent,
            ),
          ),
          const SizedBox(width: 4),
          Text(_copied ? 'Copied' : 'Copy', style: _label),
        ],
      );
    }

    if (_isWaiting) {
      return Row(
        key: const ValueKey('waiting'),
        children: [
          _spinner(),
          const SizedBox(width: 8),
          Text(
            widget.pending
                ? 'Setting up your account number…'
                : 'Loading account number…',
            style: _label,
          ),
        ],
      );
    }

    // No account yet (or guest): invite them to get one.
    return Row(
      key: const ValueKey('attention'),
      children: [
        Icon(Icons.account_balance_rounded, size: 14, color: _accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Get a free account number',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _label,
          ),
        ),
        AnimatedBuilder(
          animation: _loop,
          builder: (context, child) => Transform.translate(
            offset: Offset(3 * math.sin(_loop.value * 2 * math.pi), 0),
            child: child,
          ),
          child: Icon(
            IconsaxPlusLinear.arrow_right_3,
            size: 14,
            color: _accent,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> gradient = widget.isDark
        ? [const Color(0xFF2C2C2C), const Color(0xFF232323)]
        : [Colors.deepOrange.shade400, Colors.pink.shade300];

    final VoidCallback? onTap = _hasAccount
        ? _handleCopy
        : (_isWaiting ? null : widget.onGetAccount);

    // Flat top (meets the balance card), rounded bottom.
    const BorderRadius radius = BorderRadius.only(
      bottomLeft: Radius.circular(14),
      bottomRight: Radius.circular(14),
    );

    // 1. Reveal: fades in on first show.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedBuilder(
          animation: _loop,
          builder: (context, child) {
            final double t = _loop.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(colors: gradient),
                // Thin accent line in dark mode for a crisp, finished edge.
                border: widget.isDark
                    ? Border.all(
                        color: Colors.deepOrange.withOpacity(0.35),
                        width: 0.8,
                      )
                    : null,
              ),
              // 2. Shimmer: a light band sweeping left to right.
              foregroundDecoration: _needsAttention
                  ? BoxDecoration(
                      borderRadius: radius,
                      gradient: LinearGradient(
                        begin: Alignment(-2.0 + 4.0 * t, -0.3),
                        end: Alignment(-1.0 + 4.0 * t, 0.3),
                        colors: [
                          Colors.white.withOpacity(0),
                          Colors.white.withOpacity(widget.isDark ? 0.10 : 0.22),
                          Colors.white.withOpacity(0),
                        ],
                      ),
                    )
                  : null,
              child: child,
            );
          },
          // Fades/slides between loading, account number, and "get one".
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }
}
