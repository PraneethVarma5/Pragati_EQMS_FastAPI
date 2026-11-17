import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class FileHelper {
  static const _folderKey = "download_folder";

  static Future<File> saveFile({
    required String subFolder,
    required String fileName,
    required List<int> bytes,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    String? root = prefs.getString(_folderKey);

    if (root == null) {
      final selected =
      await FilePicker.platform.getDirectoryPath();

      if (selected == null) {
        throw Exception("Folder selection cancelled.");
      }

      root = p.join(selected, "Digital ARR");

      await prefs.setString(_folderKey, root);
    }

    final folder = Directory(
      p.join(root, subFolder),
    );

    if (!folder.existsSync()) {
      folder.createSync(recursive: true);
    }

    final file = File(
      p.join(folder.path, fileName),
    );

    await file.writeAsBytes(bytes);

    return file;
  }
}