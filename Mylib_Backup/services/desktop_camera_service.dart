// import 'dart:io';
// import 'package:flutter/foundation.dart';
// class DesktopCameraService {
//   static Future<String?> capturePhoto() async {
//     try {
//       File exe;
//
//       if (Platform.environment.containsKey('FLUTTER_TEST')) {
//         exe = File("DigitalARRCamera.exe");
//       } else {
//         final projectExe = File(
//           "windows/runner/DigitalARRCamera.exe",
//         );
//
//         if (projectExe.existsSync()) {
//           exe = projectExe;
//         } else {
//           final appDir =
//               File(Platform.resolvedExecutable).parent.path;
//
//           exe = File("$appDir/DigitalARRCamera.exe");
//         }
//       }
//
//       if (!exe.existsSync()) {
//         print("Camera EXE not found:");
//         print(exe.path);
//         return null;
//       }
//
//       final process = await Process.start(
//         exe.path,
//         [],
//         mode: ProcessStartMode.normal,
//       );
//
// // Wait until camera closes
//       final stdoutFuture =
//       process.stdout.transform(SystemEncoding().decoder).join();
//
//       final stderrFuture =
//       process.stderr.transform(SystemEncoding().decoder).join();
//
//       final exitCode = await process.exitCode;
//
//       final stdout = await stdoutFuture;
//       final stderr = await stderrFuture;
//
//       if (exitCode != 0) {
//         debugPrint(stderr);
//         return null;
//       }
//
//       return stdout.trim();
//     } catch (e) {
//       print(e);
//       return null;
//     }
//   }
// }

import 'dart:typed_data';

class DesktopCameraService {
  static Future<Uint8List?> capturePhoto() async {
    return null;
  }
}