// import 'package:flutter/material.dart';
// import '../services/desktop_camera_service.dart';
//
// class CameraCaptureScreen extends StatefulWidget {
//   const CameraCaptureScreen({super.key});
//
//   @override
//   State<CameraCaptureScreen> createState() =>
//       _CameraCaptureScreenState();
// }
//
// class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
//
//   @override
//   void initState() {
//     super.initState();
//     _openCamera();
//   }
//
//   Future<void> _openCamera() async {
//     final photo = await DesktopCameraService.capturePhoto();
//
//     if (!mounted) return;
//
//     Navigator.pop(context, photo);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: Center(
//         child: CircularProgressIndicator(),
//       ),
//     );
//   }
// }

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() =>
      _CameraCaptureScreenState();
}

class _CameraCaptureScreenState
    extends State<CameraCaptureScreen> {

  @override
  void initState() {
    super.initState();
    _openCamera();
  }

  Future<void> _openCamera() async {
    final picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
    );

    if (image == null) {
      if (!mounted) return;

      Navigator.pop(context, null);
      return;
    }

    final Uint8List bytes = await image.readAsBytes();

    if (!mounted) return;

    Navigator.pop(context, bytes);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}