import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadService {
  static const String folderKey = "download_folder";

  /// Returns saved folder path
  static Future<String?> getFolder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(folderKey);
  }

  /// Save folder path
  static Future<void> saveFolder(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(folderKey, path);
  }

  /// Ask user to choose folder
  static Future<String?> pickFolder() async {
    final selected =
    await FilePicker.platform.getDirectoryPath();

    if (selected == null) return null;

    final root = Directory(
      "$selected/Digital ARR",
    );

    if (!root.existsSync()) {
      root.createSync(recursive: true);
    }

    final folders = [
      "Certificates",
      "Observation Reports",
      "Evaluation Reports",
      "Combined Reports",
      "Cross Tab Reports",
      "Master Data",
    ];

    for (final folder in folders) {
      Directory(
        "${root.path}/$folder",
      ).createSync(recursive: true);
    }

    await saveFolder(root.path);

    return root.path;
  }
}