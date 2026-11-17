import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerController {
  final MobileScannerController mobileController = MobileScannerController(
    facing: CameraFacing.back,

    detectionSpeed: DetectionSpeed.normal,

    returnImage: false,
  );

  bool _busy = false;

  bool get isBusy => _busy;

  Future<void> pause() async {
    _busy = true;

    await mobileController.stop();
  }

  Future<void> resume() async {
    _busy = false;

    await mobileController.start();
  }

  Future<void> dispose() async {
    await mobileController.dispose();
  }
}
