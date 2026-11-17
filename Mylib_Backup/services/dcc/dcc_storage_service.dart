import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_service.dart';

class DccStorageService {
  static const String bucketName = 'dcc-documents';

  static SupabaseClient get _client =>
      SupabaseService.client;

  static Future<String> uploadSourceDocument({
    required Uint8List fileBytes,
    required String documentId,
    required String originalFileName,
  }) async {
    if (fileBytes.isEmpty) {
      throw Exception(
        'Selected document is empty.',
      );
    }

    final safeFileName =
    _sanitizeFileName(originalFileName);

    final storagePath =
        'source/$documentId/$safeFileName';

    final mimeType =
        lookupMimeType(safeFileName) ??
            'application/octet-stream';

    await _client.storage
        .from(bucketName)
        .uploadBinary(
      storagePath,
      fileBytes,
      fileOptions: FileOptions(
        contentType: mimeType,
        upsert: false,
      ),
    );

    return storagePath;
  }

  static Future<String> uploadConvertedPdf({
    required Uint8List fileBytes,
    required String documentId,
    required int revision,
    required String originalFileName,
  }) async {
    if (fileBytes.isEmpty) {
      throw Exception(
        'Selected PDF is empty.',
      );
    }

    final safeFileName =
    _sanitizeFileName(originalFileName);

    final storagePath =
        'released/$documentId/rev_$revision/$safeFileName';

    await _client.storage
        .from(bucketName)
        .uploadBinary(
      storagePath,
      fileBytes,
      fileOptions: const FileOptions(
        contentType: 'application/pdf',
        upsert: false,
      ),
    );

    return storagePath;
  }

  static Future<String> uploadRevisedDocument({
    required Uint8List fileBytes,
    required String requestId,
    required String originalFileName,
  }) async {
    if (fileBytes.isEmpty) {
      throw Exception(
        'Selected revised document is empty.',
      );
    }

    final safeFileName =
    _sanitizeFileName(originalFileName);

    final storagePath =
        'revised/$requestId/$safeFileName';

    final mimeType =
        lookupMimeType(safeFileName) ??
            'application/octet-stream';

    await _client.storage
        .from(bucketName)
        .uploadBinary(
      storagePath,
      fileBytes,
      fileOptions: FileOptions(
        contentType: mimeType,
        upsert: false,
      ),
    );

    return storagePath;
  }

  static Future<String> createSignedUrl(
      String storagePath, {
        int expiresIn = 3600,
        String? downloadFileName,
      }) async {
    final path = storagePath.trim();

    if (path.isEmpty) {
      throw Exception(
        'File storage path is empty.',
      );
    }

    if (path.startsWith('http://') ||
        path.startsWith('https://')) {
      return path;
    }

    if (_isLegacyLocalPath(path)) {
      throw Exception(
        'This file belongs to the old local-storage workflow. '
            'Please upload the document again so it is stored in Supabase.',
      );
    }

    final DownloadBehavior? downloadBehavior =
    downloadFileName == null ||
        downloadFileName.trim().isEmpty
        ? null
        : DownloadBehavior.named(
      downloadFileName.trim(),
    );

    return _client.storage
        .from(bucketName)
        .createSignedUrl(
      path,
      expiresIn,
      download: downloadBehavior,
    );
  }

  static bool _isLegacyLocalPath(
      String path,
      ) {
    return path.startsWith('C:\\') ||
        path.startsWith('D:\\') ||
        path.startsWith('E:\\') ||
        path.startsWith('F:\\') ||
        path.startsWith('/') ||
        path.contains('\\Downloads\\') ||
        path.contains('/Downloads/');
  }

  static String _sanitizeFileName(
      String fileName,
      ) {
    final cleaned = fileName
        .trim()
        .replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );

    if (cleaned.isEmpty) {
      return 'document';
    }

    return cleaned;
  }
}