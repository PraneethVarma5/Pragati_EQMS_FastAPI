import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../controllers/scanner_controller.dart';

class LiveScanner extends StatelessWidget {
  final ScannerController scanner;

  final Function(String barcode) onScan;

  const LiveScanner({super.key, required this.scanner, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),

      child: SizedBox(
        height: 340,

        child: MobileScanner(
          controller: scanner.mobileController,

          onDetect: (capture) async {
            if (scanner.isBusy) return;

            if (capture.barcodes.isEmpty) {
              return;
            }

            final code = capture.barcodes.first.rawValue;

            if (code == null) {
              return;
            }

            await scanner.pause();

            onScan(code);
          },
        ),
      ),
    );
  }
}
