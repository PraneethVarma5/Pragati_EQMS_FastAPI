import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final MobileScannerController controller = MobileScannerController();

  bool scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Part"), centerTitle: true),

      body: Column(
        children: [
          Expanded(
            flex: 5,

            child: MobileScanner(
              controller: controller,

              onDetect: (capture) {
                if (scanned) return;

                final barcode = capture.barcodes.first.rawValue;

                if (barcode == null) return;

                scanned = true;

                Navigator.pop(context, barcode);
              },
            ),
          ),

          const Expanded(
            child: Center(
              child: Text(
                "Point the camera towards the Part Barcode",

                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),

                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
