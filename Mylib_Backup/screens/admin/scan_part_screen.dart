// // import 'package:flutter/material.dart';
// // import 'package:mobile_scanner/mobile_scanner.dart';
// //
// // import '../../models/question.dart';
// // import '../../services/hive_service.dart';
// // import 'part_editor_screen.dart';
// //
// // class ScanPartScreen extends StatefulWidget {
// //   const ScanPartScreen({super.key});
// //
// //   @override
// //   State<ScanPartScreen> createState() => _ScanPartScreenState();
// // }
// //
// // class _ScanPartScreenState extends State<ScanPartScreen> {
// //   bool scanned = false;
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xFF111318),
// //
// //       appBar: AppBar(
// //         backgroundColor: const Color(0xFF111318),
// //         surfaceTintColor: Colors.transparent,
// //         elevation: 0,
// //
// //         leading: IconButton(
// //           icon: const Icon(
// //             Icons.arrow_back_rounded,
// //             color: Colors.white,
// //           ),
// //           onPressed: () => Navigator.pop(context),
// //         ),
// //
// //         title: const Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Text(
// //               "Scan Part QR",
// //               style: TextStyle(
// //                 fontSize: 19,
// //                 fontWeight: FontWeight.w700,
// //                 color: Colors.white,
// //               ),
// //             ),
// //
// //             Text(
// //               "Scan a registered part to edit its details",
// //               style: TextStyle(
// //                 fontSize: 11,
// //                 color: Color(0xFFB8BDC5),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //
// //       body: Stack(
// //         children: [
// //
// //           // CAMERA
// //           Positioned.fill(
// //             child: MobileScanner(
// //               onDetect: (capture) {
// //                 if (scanned) return;
// //
// //                 final barcode =
// //                     capture.barcodes.first.rawValue;
// //
// //                 if (barcode == null ||
// //                     barcode.trim().isEmpty) {
// //                   return;
// //                 }
// //
// //                 scanned = true;
// //
// //                 final part =
// //                 HiveService.findPartByBarcode(
// //                   barcode,
// //                 );
// //
// //                 if (part == null) {
// //                   ScaffoldMessenger.of(
// //                     context,
// //                   ).showSnackBar(
// //                     const SnackBar(
// //                       content: Text(
// //                         "Part not found. Please scan a registered QR code.",
// //                       ),
// //                     ),
// //                   );
// //
// //                   Future.delayed(
// //                     const Duration(seconds: 2),
// //                         () {
// //                       if (mounted) {
// //                         setState(() {
// //                           scanned = false;
// //                         });
// //                       }
// //                     },
// //                   );
// //
// //                   return;
// //                 }
// //
// //                 Navigator.pushReplacement(
// //                   context,
// //                   MaterialPageRoute(
// //                     builder: (_) =>
// //                         PartEditorScreen(
// //                           batchId: part.batchId,
// //                           part: part,
// //                         ),
// //                   ),
// //                 );
// //               },
// //             ),
// //           ),
// //
// //           // DARK OVERLAY
// //           Positioned.fill(
// //             child: IgnorePointer(
// //               child: Container(
// //                 color: Colors.black.withValues(
// //                   alpha: 0.20,
// //                 ),
// //               ),
// //             ),
// //           ),
// //
// //           // TOP INSTRUCTION
// //           Positioned(
// //             top: 28,
// //             left: 0,
// //             right: 0,
// //
// //             child: Center(
// //               child: Container(
// //                 padding:
// //                 const EdgeInsets.symmetric(
// //                   horizontal: 18,
// //                   vertical: 11,
// //                 ),
// //
// //                 decoration: BoxDecoration(
// //                   color: Colors.black.withValues(
// //                     alpha: 0.60,
// //                   ),
// //
// //                   borderRadius:
// //                   BorderRadius.circular(12),
// //                 ),
// //
// //                 child: const Row(
// //                   mainAxisSize: MainAxisSize.min,
// //
// //                   children: [
// //
// //                     Icon(
// //                       Icons.qr_code_scanner_rounded,
// //                       color: Colors.white,
// //                       size: 21,
// //                     ),
// //
// //                     SizedBox(width: 9),
// //
// //                     Text(
// //                       "Position the QR code inside the frame",
// //                       style: TextStyle(
// //                         color: Colors.white,
// //                         fontSize: 13,
// //                         fontWeight:
// //                         FontWeight.w600,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //
// //           // SCAN FRAME
// //           Center(
// //             child: SizedBox(
// //               width: 330,
// //               height: 330,
// //
// //               child: Stack(
// //                 children: [
// //
// //                   // CORNER BRACKETS
// //                   Positioned(
// //                     top: 0,
// //                     left: 0,
// //                     child: _scanCorner(
// //                       top: true,
// //                       left: true,
// //                     ),
// //                   ),
// //
// //                   Positioned(
// //                     top: 0,
// //                     right: 0,
// //                     child: _scanCorner(
// //                       top: true,
// //                       left: false,
// //                     ),
// //                   ),
// //
// //                   Positioned(
// //                     bottom: 0,
// //                     left: 0,
// //                     child: _scanCorner(
// //                       top: false,
// //                       left: true,
// //                     ),
// //                   ),
// //
// //                   Positioned(
// //                     bottom: 0,
// //                     right: 0,
// //                     child: _scanCorner(
// //                       top: false,
// //                       left: false,
// //                     ),
// //                   ),
// //
// //                   Center(
// //                     child: Container(
// //                       width: 290,
// //                       height: 290,
// //
// //                       decoration: BoxDecoration(
// //                         border: Border.all(
// //                           color: Colors.white.withValues(
// //                             alpha: 0.12,
// //                           ),
// //                         ),
// //
// //                         borderRadius:
// //                         BorderRadius.circular(12),
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //
// //           // BOTTOM INFORMATION
// //           Positioned(
// //             left: 24,
// //             right: 24,
// //             bottom: 28,
// //
// //             child: Center(
// //               child: Container(
// //                 constraints:
// //                 const BoxConstraints(
// //                   maxWidth: 520,
// //                 ),
// //
// //                 padding:
// //                 const EdgeInsets.symmetric(
// //                   horizontal: 20,
// //                   vertical: 15,
// //                 ),
// //
// //                 decoration: BoxDecoration(
// //                   color: Colors.black.withValues(
// //                     alpha: 0.65,
// //                   ),
// //
// //                   borderRadius:
// //                   BorderRadius.circular(14),
// //
// //                   border: Border.all(
// //                     color: Colors.white.withValues(
// //                       alpha: 0.10,
// //                     ),
// //                   ),
// //                 ),
// //
// //                 child: const Row(
// //                   children: [
// //
// //                     Icon(
// //                       Icons.info_outline_rounded,
// //                       color: Color(0xFFD8DCE2),
// //                       size: 20,
// //                     ),
// //
// //                     SizedBox(width: 11),
// //
// //                     Expanded(
// //                       child: Text(
// //                         "Scanning will automatically open the matching part for editing.",
// //                         style: TextStyle(
// //                           color: Color(0xFFD8DCE2),
// //                           fontSize: 12.5,
// //                           height: 1.35,
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //   Widget _scanCorner({
// //     required bool top,
// //     required bool left,
// //   }) {
// //     const length = 42.0;
// //     const thickness = 4.0;
// //     const radius = 8.0;
// //
// //     return SizedBox(
// //       width: length,
// //       height: length,
// //       child: Stack(
// //         children: [
// //
// //           // Horizontal corner line
// //           Positioned(
// //             top: top ? 0 : null,
// //             bottom: top ? null : 0,
// //             left: left ? 0 : null,
// //             right: left ? null : 0,
// //
// //             child: Container(
// //               width: length,
// //               height: thickness,
// //
// //               decoration: BoxDecoration(
// //                 color: const Color(0xFF5B8DEF),
// //
// //                 borderRadius: BorderRadius.only(
// //                   topLeft: top && left
// //                       ? const Radius.circular(radius)
// //                       : Radius.zero,
// //
// //                   topRight: top && !left
// //                       ? const Radius.circular(radius)
// //                       : Radius.zero,
// //
// //                   bottomLeft: !top && left
// //                       ? const Radius.circular(radius)
// //                       : Radius.zero,
// //
// //                   bottomRight: !top && !left
// //                       ? const Radius.circular(radius)
// //                       : Radius.zero,
// //                 ),
// //               ),
// //             ),
// //           ),
// //
// //           // Vertical corner line
// //           Positioned(
// //             top: top ? 0 : null,
// //             bottom: top ? null : 0,
// //             left: left ? 0 : null,
// //             right: left ? null : 0,
// //
// //             child: Container(
// //               width: thickness,
// //               height: length,
// //
// //               decoration: BoxDecoration(
// //                 color: const Color(0xFF5B8DEF),
// //
// //                 borderRadius: BorderRadius.only(
// //                   topLeft: top && left
// //                       ? const Radius.circular(radius)
// //                       : Radius.zero,
// //
// //                   topRight: top && !left
// //                       ? const Radius.circular(radius)
// //                       : Radius.zero,
// //
// //                   bottomLeft: !top && left
// //                       ? const Radius.circular(radius)
// //                       : Radius.zero,
// //
// //                   bottomRight: !top && !left
// //                       ? const Radius.circular(radius)
// //                       : Radius.zero,
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import '../../services/supabase_service.dart';
// import 'part_editor_screen.dart';
//
// class ScanPartScreen extends StatefulWidget {
//   const ScanPartScreen({super.key});
//
//   @override
//   State<ScanPartScreen> createState() =>
//       _ScanPartScreenState();
// }
//
// class _ScanPartScreenState
//     extends State<ScanPartScreen> {
//
//   final MobileScannerController scannerController =
//   MobileScannerController();
//
//   bool scanned = false;
//   bool loading = false;
//
//   @override
//   void dispose() {
//     scannerController.dispose();
//     super.dispose();
//   }
//
//   Future<void> handleBarcode(
//       String barcode,
//       ) async {
//
//     if (scanned || loading) return;
//
//     final value = barcode.trim();
//
//     if (value.isEmpty) return;
//
//     setState(() {
//       scanned = true;
//       loading = true;
//     });
//
//     try {
//
//       await scannerController.stop();
//
//       final part =
//       await SupabaseService.getPartByBarcode(
//         value,
//       );
//
//       if (!mounted) return;
//
//       if (part == null) {
//
//         setState(() {
//           scanned = false;
//           loading = false;
//         });
//
//         await scannerController.start();
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               "Part not found. Please scan a registered QR code.",
//             ),
//           ),
//         );
//
//         return;
//       }
//
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => PartEditorScreen(
//             batchId:
//             part['batch_id']?.toString() ?? '',
//           ),
//         ),
//       );
//
//     } catch (e) {
//
//       if (!mounted) return;
//
//       setState(() {
//         scanned = false;
//         loading = false;
//       });
//
//       await scannerController.start();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             "Unable to find part: $e",
//           ),
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     return Scaffold(
//       backgroundColor:
//       const Color(0xFF111318),
//
//       appBar: AppBar(
//         backgroundColor:
//         const Color(0xFF111318),
//
//         surfaceTintColor:
//         Colors.transparent,
//
//         elevation: 0,
//
//         leading: IconButton(
//           icon: const Icon(
//             Icons.arrow_back_rounded,
//             color: Colors.white,
//           ),
//           onPressed: () =>
//               Navigator.pop(context),
//         ),
//
//         title: const Text(
//           "Scan Part QR",
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 19,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),
//
//       body: Stack(
//         children: [
//
//           Positioned.fill(
//             child: MobileScanner(
//               controller:
//               scannerController,
//
//               onDetect: (capture) {
//
//                 if (scanned || loading) {
//                   return;
//                 }
//
//                 if (capture.barcodes.isEmpty) {
//                   return;
//                 }
//
//                 final barcode =
//                     capture.barcodes.first.rawValue;
//
//                 if (barcode == null ||
//                     barcode.trim().isEmpty) {
//                   return;
//                 }
//
//                 handleBarcode(barcode);
//               },
//             ),
//           ),
//
//           Positioned.fill(
//             child: IgnorePointer(
//               child: Container(
//                 color: Colors.black.withValues(
//                   alpha: 0.20,
//                 ),
//               ),
//             ),
//           ),
//
//           Positioned(
//             top: 28,
//             left: 0,
//             right: 0,
//
//             child: Center(
//               child: Container(
//                 padding:
//                 const EdgeInsets.symmetric(
//                   horizontal: 18,
//                   vertical: 11,
//                 ),
//
//                 decoration: BoxDecoration(
//                   color:
//                   Colors.black.withValues(
//                     alpha: 0.65,
//                   ),
//
//                   borderRadius:
//                   BorderRadius.circular(12),
//                 ),
//
//                 child: const Row(
//                   mainAxisSize:
//                   MainAxisSize.min,
//
//                   children: [
//
//                     Icon(
//                       Icons.qr_code_scanner_rounded,
//                       color: Colors.white,
//                       size: 21,
//                     ),
//
//                     SizedBox(width: 9),
//
//                     Text(
//                       "Position the QR code inside the frame",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 13,
//                         fontWeight:
//                         FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//
//           Center(
//             child: SizedBox(
//               width: 330,
//               height: 330,
//
//               child: Stack(
//                 children: [
//
//                   Positioned(
//                     top: 0,
//                     left: 0,
//                     child: _scanCorner(
//                       top: true,
//                       left: true,
//                     ),
//                   ),
//
//                   Positioned(
//                     top: 0,
//                     right: 0,
//                     child: _scanCorner(
//                       top: true,
//                       left: false,
//                     ),
//                   ),
//
//                   Positioned(
//                     bottom: 0,
//                     left: 0,
//                     child: _scanCorner(
//                       top: false,
//                       left: true,
//                     ),
//                   ),
//
//                   Positioned(
//                     bottom: 0,
//                     right: 0,
//                     child: _scanCorner(
//                       top: false,
//                       left: false,
//                     ),
//                   ),
//
//                   Center(
//                     child: Container(
//                       width: 290,
//                       height: 290,
//
//                       decoration:
//                       BoxDecoration(
//                         border: Border.all(
//                           color:
//                           Colors.white.withValues(
//                             alpha: 0.12,
//                           ),
//                         ),
//
//                         borderRadius:
//                         BorderRadius.circular(12),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           if (loading)
//             Positioned.fill(
//               child: Container(
//                 color:
//                 Colors.black.withValues(
//                   alpha: 0.55,
//                 ),
//
//                 child: const Center(
//                   child: CircularProgressIndicator(
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _scanCorner({
//     required bool top,
//     required bool left,
//   }) {
//
//     const double size = 35;
//     const double thickness = 4;
//
//     return SizedBox(
//       width: size,
//       height: size,
//
//       child: Stack(
//         children: [
//
//           Positioned(
//             top: 0,
//             left: left ? 0 : null,
//             right: left ? null : 0,
//
//             child: Container(
//               width: size,
//               height: thickness,
//               color: Colors.white,
//             ),
//           ),
//
//           Positioned(
//             top: top ? 0 : null,
//             bottom: top ? null : 0,
//             left: left ? 0 : null,
//             right: left ? null : 0,
//
//             child: Container(
//               width: thickness,
//               height: size,
//               color: Colors.white,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/supabase_service.dart';
import '../../models/question.dart';
import 'part_editor_screen.dart';
import '../../services/supabase_service.dart';
import 'part_editor_screen.dart';

class ScanPartScreen extends StatefulWidget {
  const ScanPartScreen({super.key});

  @override
  State<ScanPartScreen> createState() =>
      _ScanPartScreenState();
}

class _ScanPartScreenState
    extends State<ScanPartScreen> {

  final TextEditingController barcodeController =
  TextEditingController();

  final FocusNode barcodeFocusNode =
  FocusNode();

  bool loading = false;

  String? errorMessage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
          (_) {
        _focusScanner();
      },
    );
  }

  void _focusScanner() {
    if (!mounted) {
      return;
    }

    FocusScope.of(context).requestFocus(
      barcodeFocusNode,
    );
  }

  @override
  void dispose() {
    barcodeController.dispose();
    barcodeFocusNode.dispose();

    super.dispose();
  }

  Future<void> _openManualBarcodeDialog() async {
    if (loading || !mounted) {
      return;
    }

    String enteredBarcode = '';

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,

      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Enter Part QR / Barcode',
          ),

          content: SizedBox(
            width: 360,

            child: TextFormField(
              autofocus: true,

              textInputAction:
              TextInputAction.done,

              initialValue:
              enteredBarcode,

              decoration:
              const InputDecoration(
                hintText:
                'Enter or paste QR code',

                border:
                OutlineInputBorder(),
              ),

              onChanged: (value) {
                enteredBarcode = value;
              },

              onFieldSubmitted: (value) {
                Navigator.pop(
                  dialogContext,
                  value.trim(),
                );
              },
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },

              child:
              const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  enteredBarcode.trim(),
                );
              },

              child:
              const Text('Search'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    final barcode =
        result?.trim() ?? '';

    if (barcode.isEmpty) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (mounted) {
          _focusScanner();
        }
      });

      return;
    }

    await handleBarcode(barcode);

    if (!mounted) {
      return;
    }

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (mounted) {
        _focusScanner();
      }
    });
  }
  Future<void> handleBarcode(
      String barcode,
      ) async {

    final value = barcode.trim();

    if (value.isEmpty || loading) {
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {

      final response =
      await SupabaseService.getPartByBarcode(
        value,
      );

      if (!mounted) return;

      // --------------------------------------------------
      // PART NOT FOUND
      // --------------------------------------------------

      if (response == null) {

        barcodeController.clear();

        setState(() {
          loading = false;
          errorMessage =
          'Part not found. Please enter a registered QR/barcode.';
        });

        WidgetsBinding.instance.addPostFrameCallback(
              (_) {
            if (!mounted) return;

            _focusScanner();
          },
        );

        return;
      }

      // --------------------------------------------------
      // CREATE EXISTING PART OBJECT
      // --------------------------------------------------

      final part = Question(
        partNo:
        response['part_number']?.toString() ??
            response['part_no']?.toString() ??
            '',

        partName:
        response['part_name']?.toString() ??
            '',

        initialStatus:
        response['master_status'] is int
            ? response['master_status'] as int
            : int.tryParse(
          response['master_status']
              ?.toString() ??
              response['initial_status']
                  ?.toString() ??
              '',
        ) ??
            1,

        barcode:
        response['barcode_value']?.toString() ??
            response['barcode']?.toString() ??
            value,

        batchId:
        response['batch_id']?.toString() ??
            '',
      );

      // --------------------------------------------------
      // INVALID / INCOMPLETE DATABASE RECORD
      // --------------------------------------------------

      if (part.partNo.isEmpty ||
          part.batchId.isEmpty) {

        barcodeController.clear();

        setState(() {
          loading = false;
          errorMessage =
          'Part data is incomplete. Please check the database record.';
        });

        WidgetsBinding.instance.addPostFrameCallback(
              (_) {
            if (!mounted) return;

            _focusScanner();
          },
        );

        return;
      }

      // --------------------------------------------------
      // OPEN EXISTING PART
      // --------------------------------------------------

      barcodeController.clear();

      setState(() {
        loading = false;
        errorMessage = null;
      });

      await Navigator.push(
        context,

        MaterialPageRoute(
          builder: (_) =>
              PartEditorScreen(
                batchId: part.batchId,
                part: part,
              ),
        ),
      );

      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback(
            (_) {
          if (!mounted) return;

          _focusScanner();
        },
      );

    } catch (e) {

      if (!mounted) return;

      barcodeController.clear();

      setState(() {
        loading = false;
        errorMessage =
        'Unable to search for the part.';
      });

      WidgetsBinding.instance.addPostFrameCallback(
            (_) {
          if (!mounted) return;

          _focusScanner();
        },
      );
    }
  }
@override
Widget build(BuildContext context) {
  return CallbackShortcuts(
    bindings: <ShortcutActivator, VoidCallback>{
      const SingleActivator(
        LogicalKeyboardKey.keyM,
        control: true,
      ): _openManualBarcodeDialog,
    },
    child: Focus(
      autofocus: true,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),

        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F7FB),
          surfaceTintColor: Colors.transparent,
          elevation: 0,

          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),

          title: const Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Scan Part',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF20242A),
                ),
              ),
              Text(
                'Use the connected handheld scanner',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF747B86),
                ),
              ),
            ],
          ),
        ),

        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 620,
            ),

            child: Padding(
              padding: const EdgeInsets.all(28),

              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,

                children: [
                  Container(
                    width: 100,
                    height: 100,

                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF0FF),
                      borderRadius:
                      BorderRadius.circular(24),
                    ),

                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 52,
                      color: Color(0xFF3155C6),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'READY TO SCAN',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: Color(0xFF3155C6),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Use the connected handheld scanner to scan the part QR/barcode.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF747B86),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(20),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                      BorderRadius.circular(14),

                      border: Border.all(
                        color: const Color(
                          0xFFD9DEE8,
                        ),
                      ),
                    ),

                    child: Column(
                      children: [
                        Icon(
                          loading
                              ? Icons.sync_rounded
                              : Icons.barcode_reader,

                          size: 42,

                          color: const Color(
                            0xFF3155C6,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          loading
                              ? 'Checking part...'
                              : errorMessage != null
                              ? 'Part Not Found'
                              : 'Scanner Ready',

                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(
                              0xFF20242A,
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          loading
                              ? 'Searching the database'
                              : errorMessage ??
                              'Scan a registered part to open it',

                          textAlign: TextAlign.center,

                          style: TextStyle(
                            fontSize: 12,

                            color: errorMessage != null
                                ? const Color(0xFFD32F2F)
                                : const Color(
                              0xFF747B86,
                            ),
                          ),
                        ),

                        if (loading) ...[
                          const SizedBox(height: 16),

                          const SizedBox(
                            width: 26,
                            height: 26,

                            child:
                            CircularProgressIndicator(
                              strokeWidth: 2.5,
                            ),
                          ),
                        ],

                        if (errorMessage != null &&
                            !loading) ...[
                          const SizedBox(height: 14),

                          const Icon(
                            Icons.error_outline_rounded,
                            size: 24,
                            color: Color(0xFFD32F2F),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

// Hidden input used by
// USB/Bluetooth handheld scanners.
// The scanner behaves like a keyboard
// and sends the barcode followed by Enter.
                  SizedBox(
                    width: 1,
                    height: 1,

                    child: Opacity(
                      opacity: 0.01,

                      child: TextField(
                        controller:
                        barcodeController,

                        focusNode:
                        barcodeFocusNode,

                        autofocus: true,

                        textInputAction:
                        TextInputAction.done,

                        onSubmitted:
                        handleBarcode,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),

                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}