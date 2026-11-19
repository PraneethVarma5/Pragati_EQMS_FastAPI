
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dcc_session.dart';

class DccApiClient {
DccApiClient._();

static String get baseUrl {
final value = (dotenv.env['EQMS_API_BASE_URL'] ?? '').trim();

if (value.isEmpty) {
throw Exception(
'EQMS_API_BASE_URL is missing from the Flutter root .env file.',
);
}

return value.replaceAll(RegExp(r'/+$'), '');
}

// ---------------------------------------------------------------------------
// HEADERS
// ---------------------------------------------------------------------------

static Map<String, String> _headers({
bool authenticated = true,
}) {
final headers = <String, String>{
'Content-Type': 'application/json',
'Accept': 'application/json',
};

if (authenticated) {
final token = DccSession.currentUser?.sessionToken ?? '';

if (token.isEmpty) {
throw Exception(
'Login required. Please log in to your DCC account.',
);
}

headers['Authorization'] = 'Bearer $token';
}

return headers;
}

// ---------------------------------------------------------------------------
// GET
// ---------------------------------------------------------------------------

static Future<dynamic> get(
String path, {
bool authenticated = true,
Map<String, String>? query,
}) async {
final uri = Uri.parse(
'$baseUrl/api/v1/dcc$path',
).replace(
queryParameters: query,
);

final response = await http.get(
uri,
headers: _headers(
authenticated: authenticated,
),
);

return _decode(response);
}

// ---------------------------------------------------------------------------
// POST
// ---------------------------------------------------------------------------

static Future<dynamic> post(
String path, {
Object? body,
bool authenticated = true,
}) async {
final uri = Uri.parse(
'$baseUrl/api/v1/dcc$path',
);

final response = await http.post(
uri,
headers: _headers(
authenticated: authenticated,
),
body: jsonEncode(body ?? {}),
);

return _decode(response);
}

// ---------------------------------------------------------------------------
// PATCH
// ---------------------------------------------------------------------------

static Future<dynamic> patch(
String path, {
Object? body,
}) async {
final uri = Uri.parse(
'$baseUrl/api/v1/dcc$path',
);

final response = await http.patch(
uri,
headers: _headers(),
body: jsonEncode(body ?? {}),
);

return _decode(response);
}

// ---------------------------------------------------------------------------
// DELETE
// ---------------------------------------------------------------------------

static Future<dynamic> delete(
String path,
) async {
final uri = Uri.parse(
'$baseUrl/api/v1/dcc$path',
);

final response = await http.delete(
uri,
headers: _headers(),
);

return _decode(response);
}

// ---------------------------------------------------------------------------
// UPLOAD
// ---------------------------------------------------------------------------

static Future<Map<String, dynamic>> upload(
String path,
Uint8List bytes,
String filename, {
String contentType = 'application/octet-stream',
}) async {
final token = DccSession.currentUser?.sessionToken ?? '';

if (token.isEmpty) {
throw Exception(
'Login required. Please log in to DCC before uploading a document.',
);
}

if (bytes.isEmpty) {
throw Exception(
'Cannot upload an empty file.',
);
}

final uri = Uri.parse(
'$baseUrl/api/v1/dcc$path',
);

final request = http.MultipartRequest(
'POST',
uri,
);

request.headers['Authorization'] = 'Bearer $token';

request.files.add(
http.MultipartFile.fromBytes(
'file',
bytes,
filename: filename,
),
);

final streamedResponse = await request.send();

final response = await http.Response.fromStream(
streamedResponse,
);

if (response.statusCode == 200 ||
response.statusCode == 201) {
dynamic decoded;

try {
decoded = jsonDecode(response.body);
} catch (_) {
throw Exception(
'Upload completed, but the server returned an invalid response.',
);
}

if (decoded is Map) {
return Map<String, dynamic>.from(decoded);
}

throw Exception(
'Upload completed, but the server returned an unexpected response.',
);
}

if (response.statusCode == 401) {
throw Exception(
'Your DCC session has expired. Please log in again before uploading.',
);
}

if (response.statusCode == 403) {
throw Exception(
'You do not have permission to upload this document.',
);
}

if (response.statusCode == 413) {
throw Exception(
'File is too large. Maximum allowed file size is 50 MB.',
);
}

if (response.statusCode == 409) {
throw Exception(
'A file already exists at this location. '
'Please use a different filename or path.',
);
}

throw Exception(
_extractErrorMessage(
response.body,
fallback: 'Document upload failed.',
) +
' (HTTP ${response.statusCode})',
);
}

// ---------------------------------------------------------------------------
// DOWNLOAD FILE
//
// Public:
//   released/*
//
// Private:
//   all other file paths
// ---------------------------------------------------------------------------

static Future<Uint8List> downloadBytes(
String path,
) async {
  final normalizedPath = path
      .replaceAll('\\', '/')
      .trim();
if (normalizedPath.isEmpty) {
throw Exception(
'Cannot download document: file path is empty.',
);
}

final uri = Uri.parse(
'$baseUrl/api/v1/dcc/files/download',
).replace(
queryParameters: {
'path': normalizedPath,
},
);

final isReleasedFile = normalizedPath.startsWith(
'released/',
);

final response = await http.get(
uri,
headers: isReleasedFile
? _headers(authenticated: false)
    : _headers(authenticated: true),
);

if (response.statusCode == 200) {
return response.bodyBytes;
}

if (response.statusCode == 401) {
throw Exception(
isReleasedFile
? 'The released document could not be accessed. '
'Please check the backend public-access configuration.'
    : 'Your DCC session has expired. Please log in again.',
);
}

if (response.statusCode == 403) {
throw Exception(
'You do not have permission to access this document.',
);
}

if (response.statusCode == 404) {
throw Exception(
'The document file was not found on the server.',
);
}

throw Exception(
_extractErrorMessage(
response.body,
fallback: 'Unable to download document.',
) +
' (HTTP ${response.statusCode})',
);
}

// ---------------------------------------------------------------------------
// FILE URL
//
// Released documents:
//   No login token
//
// Private documents:
//   Token included
// ---------------------------------------------------------------------------

static String fileUrl(
String path,
) {
  final normalizedPath = path
      .replaceAll('\\', '/')
      .trim();
if (normalizedPath.isEmpty) {
throw Exception(
'Cannot open document: file path is empty.',
);
}

final uri = Uri.parse(
'$baseUrl/api/v1/dcc/files/download',
);

// -----------------------------------------------------------------------
// PUBLIC RELEASED DOCUMENT
// -----------------------------------------------------------------------

if (normalizedPath.startsWith('released/')) {
return uri.replace(
queryParameters: {
'path': normalizedPath,
},
).toString();
}

// -----------------------------------------------------------------------
// PRIVATE DOCUMENT
// -----------------------------------------------------------------------

final token = DccSession.currentUser?.sessionToken ?? '';

if (token.isEmpty) {
throw Exception(
'Login is required to view this document. '
'Please log in to your DCC account.',
);
}

return uri.replace(
queryParameters: {
'path': normalizedPath,
'access_token': token,
},
).toString();
}

// ---------------------------------------------------------------------------
// ERROR DECODER
// ---------------------------------------------------------------------------

static dynamic _decode(
http.Response response,
) {
dynamic data;

try {
data = response.body.isEmpty
? null
    : jsonDecode(response.body);
} catch (_) {
throw Exception(
'FastAPI returned a non-JSON response '
'(${response.statusCode}). '
'Check EQMS_API_BASE_URL and backend routing.',
);
}

if (response.statusCode < 200 ||
response.statusCode >= 300) {
final detail = data is Map
? (data['detail'] ?? data['message'])
    : null;

if (response.statusCode == 401) {
  throw Exception(
    detail?.toString() ??
        'Your DCC session has expired. Please log in again.',
  );
}

if (response.statusCode == 403) {
throw Exception(
detail?.toString() ??
'You do not have permission to perform this action.',
);
}

throw Exception(
detail?.toString() ??
'DCC API request failed (${response.statusCode}).',
);
}

return data;
}

// ---------------------------------------------------------------------------
// ERROR MESSAGE EXTRACTION
// ---------------------------------------------------------------------------

static String _extractErrorMessage(
String responseBody, {
required String fallback,
}) {
try {
final decoded = jsonDecode(responseBody);

if (decoded is Map) {
final detail = decoded['detail'] ?? decoded['message'];

if (detail != null) {
return detail.toString();
}
}
} catch (_) {
// Server may return plain text.
}

return fallback;
}
}
