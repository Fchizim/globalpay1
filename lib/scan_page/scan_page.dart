// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
//
// class QrScanPage extends StatefulWidget {
//   const QrScanPage({super.key});
//
//   @override
//   State<QrScanPage> createState() => _QrScanPageState();
// }
//
// class _QrScanPageState extends State<QrScanPage> {
//   final MobileScannerController controller = MobileScannerController();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // Camera preview
//           MobileScanner(
//             controller: controller,
//             onDetect: (capture) {
//               final List<Barcode> barcodes = capture.barcodes;
//               for (final barcode in barcodes) {
//                 debugPrint('QR Code found: ${barcode.rawValue}');
//                 Navigator.pop(context, barcode.rawValue); // return result
//               }
//             },
//           ),
//
//           // Back button
//           Positioned(
//             top: 50,
//             left: 20,
//             child: IconButton(
//               icon: const Icon(Icons.arrow_back, color: Colors.white),
//               onPressed: () => Navigator.pop(context),
//             ),
//           ),
//
//           // Bottom controls
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: Padding(
//               padding: const EdgeInsets.only(bottom: 40),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: const [
//                       Icon(Icons.photo, size: 40, color: Colors.white),
//                       Text("Album", style: TextStyle(color: Colors.white)),
//                     ],
//                   ),
//                   const Text("Scan QR Code",
//                       style: TextStyle(color: Colors.white, fontSize: 16)),
//                   IconButton(
//                     icon: const Icon(Icons.flash_on,
//                         size: 40, color: Colors.white),
//                     onPressed: () => controller.toggleTorch(),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
