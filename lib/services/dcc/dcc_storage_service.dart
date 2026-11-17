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

  /// Uploads the PDF converted by DCC.
  ///
  /// This is intentionally separate from the user's
  /// revised-document upload so the DCC workflow is explicit.
  static Future<String> uploadDccRevisedPdf({
  required Uint8List fileBytes,
  required String requestId,
  required String originalFileName,
  }) async {
  if (fileBytes.isEmpty) {
  throw Exception(
  'Selected revised PDF is empty.',
  );
  }

  final safeFileName =
  _sanitizeFileName(originalFileName);

  if (!safeFileName.toLowerCase().endsWith('.pdf')) {
  throw Exception(
  'Only PDF files are allowed for DCC revised version upload.',
  );
  }

  final storagePath =
  'revised/$requestId/$safeFileName';

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

  // static Future<String> uploadDccRevisedPdf({
  //   required Uint8List fileBytes,
  //   required String requestId,
  //   required String originalFileName,
  // }) async {
  //   if (fileBytes.isEmpty) {
  //     throw Exception(
  //       'Selected revised PDF is empty.',
  //     );
  //   }
  //
  //   final safeFileName =
  //   _sanitizeFileName(originalFileName);
  //
  //   if (!safeFileName.toLowerCase().endsWith('.pdf')) {
  //     throw Exception(
  //       'Only PDF files are allowed for DCC revised version upload.',
  //     );
  //   }
  //
  //   final storagePath =
  //       'revised/$requestId/$safeFileName';
  //
  //   await _client.storage
  //       .from(bucketName)
  //       .uploadBinary(
  //     storagePath,
  //     fileBytes,
  //     fileOptions: const FileOptions(
  //       contentType: 'application/pdf',
  //       upsert: false,
  //     ),
  //   );
  //
  //   return storagePath;
  // }

  /// Moves/promotes the revised PDF submitted for a DMR
  /// into the released-document area.
  ///
  /// This is used when DCC clicks "Accept Revision".
  /// The revised file is copied from:
  ///
  /// revised/<requestId>/<file>
  ///
  /// to:
  ///
  /// released/<documentId>/rev_<revision>/<file>
  ///
  /// This uses Supabase Storage only, so it works on
  /// Flutter Web as well as desktop/mobile.
  static Future<String> promoteRevisedToReleased({
    required String revisedPath,
    required String documentId,
    required int revision,
    required String originalFileName,
  }) async {
    final sourcePath = revisedPath.trim();

    if (sourcePath.isEmpty) {
      throw Exception(
        'Revised document storage path is empty.',
      );
    }

    if (documentId.trim().isEmpty) {
      throw Exception(
        'Document ID is empty.',
      );
    }

    if (revision < 0) {
      throw Exception(
        'Invalid document revision.',
      );
    }

    final safeFileName =
    _sanitizeFileName(originalFileName);

    if (!safeFileName.toLowerCase().endsWith('.pdf')) {
      throw Exception(
        'Only PDF files can be promoted to released documents.',
      );
    }

    final releasedPath =
        'released/${documentId.trim()}/rev_$revision/$safeFileName';

    try {
      // Download the already-uploaded revised PDF
      // directly from Supabase Storage.
      final fileBytes = await _client.storage
          .from(bucketName)
          .download(sourcePath);

      if (fileBytes.isEmpty) {
        throw Exception(
          'The revised PDF stored for this request is empty.',
        );
      }

      // Upload it into the official released-document
      // location.
      await _client.storage
          .from(bucketName)
          .uploadBinary(
        releasedPath,
        fileBytes,
        fileOptions: const FileOptions(
          contentType: 'application/pdf',
          upsert: false,
        ),
      );

      return releasedPath;
    } catch (e) {
      throw Exception(
        'Unable to promote revised PDF to released storage: $e',
      );
    }
  }

  static Future<void> deleteFile(String storagePath) async {
    final path = storagePath.trim();
    if (path.isEmpty) return;

    await _client.storage
        .from(bucketName)
        .remove([path]);
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

    // VIEW
    //
    // When no downloadFileName is supplied, create a normal
    // signed URL so the browser can render supported files
    // inline.
    if (downloadFileName == null ||
        downloadFileName.trim().isEmpty) {
      return _client.storage
          .from(bucketName)
          .createSignedUrl(
        path,
        expiresIn,
      );
    }

    // DOWNLOAD
    //
    // Only explicitly requested downloads receive a
    // Content-Disposition download filename.
    final downloadBehavior =
    DownloadBehavior.named(
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