import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class UserBalance {
  UserBalance._private();
  static final UserBalance instance = UserBalance._private();
  double balance = 5_000_000.0;
}

class MoneyDropPage extends StatefulWidget {
  const MoneyDropPage({super.key});
  @override
  State<MoneyDropPage> createState() => _MoneyDropPageState();
}

class _MoneyDropPageState extends State<MoneyDropPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String qrData = "";
  DateTime? lastGeneratedTime;
  bool showOnlyQR = false;
  int selectedDesignIndex = 0;

  double get availableBalance => UserBalance.instance.balance;

  Future<void> _confirmAndGenerateQR() async {
    final amountText = _amountController.text.trim();
    final now = DateTime.now();

    if (lastGeneratedTime != null &&
        now.difference(lastGeneratedTime!).inMinutes < 5) {
      final remaining = 5 - now.difference(lastGeneratedTime!).inMinutes;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You can generate a new QR in $remaining min")),
      );
      return;
    }

    if (amountText.isEmpty ||
        double.tryParse(amountText) == null ||
        double.parse(amountText) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid amount")),
      );
      return;
    }

    final amountValue = double.parse(amountText);
    if (amountValue > availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Amount exceeds available balance")),
      );
      return;
    }

    final bool? ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PinBottomSheet(),
    );

    if (ok == true) {
      final data = {
        "amount": amountValue,
        "note": _noteController.text.trim(),
        "design": selectedDesignIndex,
        "id": DateTime.now().millisecondsSinceEpoch.toString(),
      };

      setState(() {
        qrData = jsonEncode(data);
        lastGeneratedTime = now;
        showOnlyQR = true;
      });
    }
  }

  void _shareQR() {
    if (qrData.isEmpty) return;
    Share.share('MoneyDrop QR: $qrData');
  }

  void _scanQR() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerPage()),
    );
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Scanned QR: $result")),
      );
    }
  }

  Color get _qrForegroundColor {
    switch (selectedDesignIndex) {
      case 1:
        return Colors.deepOrange;
      case 2:
        return Colors.purple;
      default:
        return Colors.black;
    }
  }

  BoxDecoration get _qrBoxDecoration {
    switch (selectedDesignIndex) {
      case 1:
        return BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.deepOrange, width: 2),
        );
      case 2:
        return BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.purple, width: 2),
        );
      default:
        return BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final textColor =
    brightness == Brightness.dark ? Colors.white : Colors.grey.shade900;

    final backgroundImage = brightness == Brightness.dark
        ? const AssetImage("assets/images/png/bckdark.PNG")
        : const AssetImage("assets/images/png/bcklight.PNG");

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(image: backgroundImage, fit: BoxFit.cover),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              children: [
                // AppBar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: textColor),
                      onPressed: () {
                        if (showOnlyQR) {
                          setState(() {
                            showOnlyQR = false;
                            qrData = "";
                          });
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    Text(
                      "MoneyDrop",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.qr_code_scanner, color: textColor),
                      onPressed: _scanQR,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Balance + Marquee
                if (!showOnlyQR)
                  Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepOrange.shade600,
                          Colors.purple.shade200
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 26,
                          child: Marquee(
                            text:
                            "💸 Surprise your loved ones with QR cash gifts! 💸    ",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                            blankSpace: 40.0,
                            velocity: 40.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Available balance: ",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                            Text(
                              "₦${availableBalance.toStringAsFixed(0)}",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 22),

                // Design Selector
                if (!showOnlyQR)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return GestureDetector(
                        onTap: () => setState(() => selectedDesignIndex = index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selectedDesignIndex == index
                                ? Colors.deepOrange.withOpacity(0.2)
                                : Colors.white,
                            border: Border.all(
                              color: selectedDesignIndex == index
                                  ? Colors.deepOrange
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              QrImageView(
                                data: "preview",
                                version: QrVersions.auto,
                                size: 60,
                                foregroundColor: index == 0
                                    ? Colors.black
                                    : index == 1
                                    ? Colors.deepOrange
                                    : Colors.purple,
                                backgroundColor: Colors.white,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                index == 1
                                    ? "Love"
                                    : index == 2
                                    ? "Gift"
                                    : "Plain",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                if (!showOnlyQR) const SizedBox(height: 14),

                // Inputs
                if (!showOnlyQR) ...[
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontSize: 20),
                    decoration: InputDecoration(
                      prefixText: "₦ ",
                      prefixStyle: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 20),
                      hintText: "Min ₦100 - Max ₦50,000,000",
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: Colors.grey.shade300, width: 1.1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Colors.deepOrange, width: 1.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _noteController,
                    style:
                    TextStyle(color: Colors.grey.shade900, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: "Add a note (optional)",
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: Colors.grey.shade300, width: 1.1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Colors.deepOrange, width: 1.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _confirmAndGenerateQR,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Generate QR",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                  ),
                ],

                // QR Section with frames
                if (showOnlyQR && qrData.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (selectedDesignIndex == 1)
                        Image.asset(
                          "assets/images/png/love1.PNG",
                          width: 300,
                          height: 300,
                          fit: BoxFit.cover,
                        ),
                      if (selectedDesignIndex == 2)
                        Image.asset(
                          "assets/images/png/gold.jpg",
                          width: 300,
                          height: 300,
                          fit: BoxFit.cover,
                        ),
                      Container(
                        decoration: _qrBoxDecoration,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 220,
                              foregroundColor: _qrForegroundColor,
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            const Text("Scan to claim",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _shareQR,
                                icon: const Icon(Icons.share,
                                    color: Colors.deepOrange),
                                label: const Text("Share QR Code",
                                    style: TextStyle(
                                        color: Colors.deepOrange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// PIN BottomSheet (same as before)
class PinBottomSheet extends StatefulWidget {
  const PinBottomSheet({super.key});
  @override
  State<PinBottomSheet> createState() => _PinBottomSheetState();
}

class _PinBottomSheetState extends State<PinBottomSheet> {
  final TextEditingController hiddenCtrl = TextEditingController();
  final FocusNode hiddenFocus = FocusNode();
  final List<String> pins = List.generate(4, (_) => '');
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    hiddenCtrl.addListener(_onHiddenChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(hiddenFocus);
    });
  }

  @override
  void dispose() {
    hiddenCtrl.removeListener(_onHiddenChanged);
    hiddenCtrl.dispose();
    hiddenFocus.dispose();
    super.dispose();
  }

  void _onHiddenChanged() {
    final cleaned = hiddenCtrl.text.replaceAll(RegExp(r'\s+'), '');
    final take = cleaned.length > 4 ? cleaned.substring(0, 4) : cleaned;
    for (int i = 0; i < 4; i++) {
      pins[i] = i < take.length ? take[i] : '';
    }
    setState(() {});
    if (take.length == 4 && !_loading) _autoSubmit();
  }

  void _autoSubmit() {
    setState(() => _loading = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : Colors.white;
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return SafeArea(
      child: Padding(
        padding:
        EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const SizedBox(width: 40),
              Text("Enter Payment PIN",
                  style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              IconButton(
                  icon: Icon(Icons.close, color: textColor),
                  onPressed: () => Navigator.pop(context, false)),
            ]),
            const SizedBox(height: 14),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).requestFocus(hiddenFocus),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (i) {
                  final filled = pins[i].isNotEmpty;
                  final currentLen =
                      hiddenCtrl.text.replaceAll(RegExp(r'\s+'), '').length;
                  final isCursorBox = currentLen == i && !_loading;
                  final borderColor = filled
                      ? Colors.deepOrange
                      : isCursorBox
                      ? Colors.deepOrange
                      : Colors.grey.shade400;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: filled ? Colors.deepOrange.withOpacity(0.06) : null,
                      borderRadius: BorderRadius.circular(12),
                      border:
                      Border.all(color: borderColor, width: filled ? 1.6 : 1.0),
                    ),
                    child: filled
                        ? const Icon(Icons.circle,
                        size: 14, color: Colors.deepOrange)
                        : (isCursorBox
                        ? Container(
                      width: 2,
                      height: 16,
                      color: Colors.deepOrange,
                    )
                        : null),
                  );
                }),
              ),
            ),
            TextField(
              controller: hiddenCtrl,
              focusNode: hiddenFocus,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: "",
              ),
              style: const TextStyle(fontSize: 0.01, color: Colors.transparent),
            ),
            const SizedBox(height: 12),
            if (_loading) const CircularProgressIndicator(),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }
}

class QRScannerPage extends StatelessWidget {
  const QRScannerPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR")),
      body: MobileScanner(
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          if (barcode.rawValue != null) {
            Navigator.pop(context, barcode.rawValue);
          }
        },
      ),
    );
  }
}
