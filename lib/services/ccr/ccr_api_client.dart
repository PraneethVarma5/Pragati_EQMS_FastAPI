
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'ccr_session.dart';

class CcrApiClient {
  CcrApiClient._();

  static String get baseUrl {
    final value = (dotenv.env['EQMS_API_BASE_URL'] ?? '').trim();

    if (value.isEmpty) {
      throw Exception(
        'EQMS_API_BASE_URL is missing from the Flutter root .env file.',
      );
    }

    return value.replaceAll(RegExp(r'/+$'), '');
  }

  // Public CCR requests do not require a session.
  // Admin requests must explicitly pass authenticated: true.
  static Map<String, String> _headers({
    bool authenticated = false,
  }) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (authenticated) {
      final token = CcrSession.sessionToken ?? '';

      if (token.trim().isEmpty) {
        throw Exception(
          'Admin session has expired. Please login again.',
        );
      }

      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    return headers;
  }

  static Uri _uri(
      String path, {
        Map<String, String>? query,
      }) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    final uri = Uri.parse(
      '$baseUrl/api/v1/ccr$normalizedPath',
    );

    return uri.replace(
      queryParameters: query == null || query.isEmpty ? null : query,
    );
  }

  // ============================================================
  // GET
  // ============================================================

  static Future<dynamic> get(
      String path, {
        bool authenticated = false,
        Map<String, String>? query,
      }) async {
    final response = await http.get(
      _uri(path, query: query),
      headers: _headers(authenticated: authenticated),
    );

    return _decode(response);
  }

  // ============================================================
  // POST
  // ============================================================

  static Future<dynamic> post(
      String path, {
        Object? body,
        bool authenticated = false,
      }) async {
    final headers = _headers(authenticated: authenticated);
    headers['Content-Type'] = 'application/json';

    final response = await http.post(
      _uri(path),
      headers: headers,
      body: jsonEncode(body ?? {}),
    );

    return _decode(response);
  }

  // ============================================================
  // PUT
  // ============================================================

  static Future<dynamic> put(
      String path, {
        Object? body,
        bool authenticated = false,
      }) async {
    final headers = _headers(authenticated: authenticated);
    headers['Content-Type'] = 'application/json';

    final response = await http.put(
      _uri(path),
      headers: headers,
      body: jsonEncode(body ?? {}),
    );

    return _decode(response);
  }

  // ============================================================
  // PATCH
  // ============================================================

  static Future<dynamic> patch(
      String path, {
        Object? body,
        Map<String, String>? query,
        bool authenticated = false,
      }) async {
    final headers = _headers(authenticated: authenticated);
    headers['Content-Type'] = 'application/json';

    final response = await http.patch(
      _uri(path, query: query),
      headers: headers,
      body: jsonEncode(body ?? {}),
    );

    return _decode(response);
  }

  // ============================================================
  // DELETE
  // ============================================================

  static Future<dynamic> delete(
      String path, {
        bool authenticated = false,
      }) async {
    final response = await http.delete(
      _uri(path),
      headers: _headers(authenticated: authenticated),
    );

    return _decode(response);
  }

  // ============================================================
  // MULTIPART FILE UPLOAD
  // ============================================================

  static Future<dynamic> uploadFileBytes({
    required String path,
    required Uint8List bytes,
    required String fileName,
    required Map<String, String> fields,
    String fileFieldName = 'file',
    bool authenticated = false,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('The selected file is empty.');
    }

    final request = http.MultipartRequest(
      'POST',
      _uri(path),
    );

    request.headers.addAll(
      _headers(authenticated: authenticated),
    );

    request.fields.addAll(fields);

    request.files.add(
      http.MultipartFile.fromBytes(
        fileFieldName,
        bytes,
        filename: fileName,
      ),
    );

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    return _decode(response);
  }

  // ============================================================
  // FILE DOWNLOAD
  // ============================================================

  static Future<Uint8List> downloadFileBytes(
      String path, {
        Map<String, String>? query,
        bool authenticated = false,
      }) async {
    final response = await http.get(
      _uri(path, query: query),
      headers: _headers(authenticated: authenticated),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      _decode(response);
    }

    return response.bodyBytes;
  }

  // ============================================================
  // RESPONSE DECODER
  // ============================================================

  static dynamic _decode(http.Response response) {
    dynamic data;

    try {
      final responseBody = utf8.decode(
        response.bodyBytes,
        allowMalformed: true,
      );

      data = responseBody.trim().isEmpty
          ? null
          : jsonDecode(responseBody);
    } catch (_) {
      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return response.bodyBytes;
      }

      throw Exception(
        'FastAPI returned an invalid response '
            '(${response.statusCode}).',
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      final detail = data is Map
          ? data['detail'] ?? data['message']
          : null;

      if (response.statusCode == 401) {
        throw Exception(
          detail?.toString() ??
              'Admin authentication is required. Please login again.',
        );
      }

      if (response.statusCode == 403) {
        throw Exception(
          detail?.toString() ??
              'You do not have permission to perform this operation.',
        );
      }

      if (response.statusCode == 404) {
        throw Exception(
          detail?.toString() ??
              'The requested CCR record or attachment was not found.',
        );
      }

      if (response.statusCode == 413) {
        throw Exception(
          detail?.toString() ??
              'The selected file is too large.',
        );
      }

      throw Exception(
        detail?.toString() ??
            'CCR API request failed (${response.statusCode}).',
      );
    }

    return data;
  }
}
