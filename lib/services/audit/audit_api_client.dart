import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '/services/audit/audit_admin_session.dart';



/// HTTP client for the FastAPI Audit module.
/// DCC, CCR and NCR continue using their existing Supabase services.
class AuditApiClient {
  AuditApiClient._();

  static const Duration _timeout = Duration(seconds: 30);

  static String get _baseUrl {
    final configured = (dotenv.env['EQMS_API_BASE_URL'] ?? '').trim();
    if (configured.isEmpty) {
      throw Exception(
        'EQMS_API_BASE_URL is missing from your .env file. Example: http://127.0.0.1:8000',
      );
    }
    return configured.replaceFirst(RegExp(r'/+$'), '');
  }

  static Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  static const Set<String> _adminOnlyOperations = {
    'admin_get_audit_types',
    'admin_create_audit_type',
    'admin_update_audit_type',
    'admin_delete_audit_type',
    'admin_get_audit_categories',
    'admin_create_audit_category',
    'admin_update_audit_category',
    'admin_delete_audit_category',
    'admin_get_audit_questions',
    'admin_create_audit_question',
    'admin_update_audit_question',
    'admin_delete_audit_question',
    'admin_get_audit_master_data',
    'admin_create_audit_master_data',
    'admin_update_audit_master_data',
    'admin_delete_audit_master_data',
    'get_all_audit_schedules',
    'create_audit_schedule',
    'update_audit_schedule',
    'update_audit_schedule_status',
    'delete_audit_schedule',
    'delete_admin_audit',
    'repair_missing_mil_numbers',
  };

  static Map<String, String> _headers({bool authenticated = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (authenticated) {
      final token = AuditAdminSession.sessionToken;
      if (token == null || token.isEmpty) {
        throw Exception('Audit admin session has expired. Please log in again.');
      }
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static dynamic _decode(http.Response response) {
    final body = response.body.trim();
    dynamic decoded;
    if (body.isNotEmpty) {
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        decoded = body;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Request failed (${response.statusCode}).';
      if (decoded is Map) {
        message = (decoded['detail'] ?? decoded['message'] ?? message).toString();
      } else if (decoded is String && decoded.isNotEmpty) {
        message = decoded;
      }
      if (response.statusCode == 401) {
        message = 'Audit admin session is invalid or expired. Please log in again.';
      }
      throw Exception(message);
    }
    return decoded;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          _uri('/api/v1/audit/auth/login'),
          headers: _headers(authenticated: false),
          body: jsonEncode({'email': email.trim(), 'password': password}),
        )
        .timeout(_timeout);
    final decoded = _decode(response);
    if (decoded is! Map) {
      throw Exception('Unexpected response from Audit login.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  static Future<void> logout() async {
    final token = AuditAdminSession.sessionToken;
    if (token == null || token.isEmpty) return;
    try {
      final response = await http
          .post(
            _uri('/api/v1/audit/auth/logout'),
            headers: _headers(authenticated: true),
          )
          .timeout(_timeout);
      _decode(response);
    } catch (_) {
      // Local logout must still work if the server is unreachable.
    }
  }

  static Future<dynamic> operation(
    String operation, [
    Map<String, dynamic> payload = const {},
  ]) async {
    final response = await http
        .post(
          _uri('/api/v1/audit/operations/$operation'),
          headers: _headers(authenticated: _adminOnlyOperations.contains(operation)),
          body: jsonEncode(payload),
        )
        .timeout(_timeout);
    return _decode(response);
  }

  static Future<List<Map<String, dynamic>>> listAuditors() async {
    final response = await http
        .get(_uri('/api/v1/audit/auditors'), headers: _headers(authenticated: true))
        .timeout(_timeout);
    final decoded = _decode(response);
    if (decoded is! List) throw Exception('Unexpected auditors response.');
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<Map<String, dynamic>> createAuditor({
    required String auditorName,
    required String employeeId,
    required String email,
    required bool active,
  }) async {
    final response = await http
        .post(
          _uri('/api/v1/audit/auditors'),
          headers: _headers(authenticated: true),
          body: jsonEncode({
            'auditor_name': auditorName.trim(),
            'employee_id': employeeId.trim(),
            'email': email.trim(),
            'active': active,
          }),
        )
        .timeout(_timeout);
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  static Future<Map<String, dynamic>> updateAuditor({
    required String auditorId,
    required String auditorName,
    required String employeeId,
    required String email,
    required bool active,
  }) async {
    final response = await http
        .put(
          _uri('/api/v1/audit/auditors/$auditorId'),
          headers: _headers(authenticated: true),
          body: jsonEncode({
            'auditor_name': auditorName.trim(),
            'employee_id': employeeId.trim(),
            'email': email.trim(),
            'active': active,
          }),
        )
        .timeout(_timeout);
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  static Future<void> deleteAuditor(String auditorId) async {
    final response = await http
        .delete(
          _uri('/api/v1/audit/auditors/$auditorId'),
          headers: _headers(authenticated: true),
        )
        .timeout(_timeout);
    _decode(response);
  }
}
