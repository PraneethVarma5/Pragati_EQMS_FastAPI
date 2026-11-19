import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/dcc/dcc_user.dart';
import '../session_activity.dart';
import 'dcc_api_client.dart';

class DccSession {
  static DccUser? currentUser;
  static const String _sessionKey = 'dcc_active_session';
  static const String _tokenKey = 'dcc_server_session_token';

  static Future<void> setUser(DccUser user) async {
    if (user.sessionToken.isEmpty) throw Exception('Cannot save DCC session without server token.');
    currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, user.sessionToken);
    await prefs.setString(_sessionKey, jsonEncode({
      'id': user.id, 'name': user.name, 'email': user.email, 'role': user.role,
      'hodName': user.hodName, 'hodEmail': user.hodEmail, 'active': user.active,
    }));
    await SessionActivity.reset();
  }

  static Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    final token = prefs.getString(_tokenKey);
    if (raw == null || raw.trim().isEmpty || token == null || token.isEmpty) {
      await clear(revokeServerSession: false); return false;
    }
    if (await SessionActivity.isExpired()) {
      await clear(); return false;
    }
    // Load the saved token into memory before making the authenticated
    // validation request. The server, not this cached profile, is authoritative.
    try {
      final cached = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      currentUser = DccUser(
        id: cached['id']?.toString() ?? '',
        name: cached['name']?.toString() ?? '',
        email: cached['email']?.toString() ?? '',
        role: cached['role']?.toString() ?? '',
        hodName: cached['hodName']?.toString() ?? '',
        hodEmail: cached['hodEmail']?.toString() ?? '',
        password: '',
        active: cached['active'] == true,
        sessionToken: token,
      );
      final result = await DccApiClient.get('/auth/session');
      if (result is! Map || result['valid'] != true || result['user'] is! Map) {
        await clear(revokeServerSession: false); return false;
      }
      final row = Map<String,dynamic>.from(result['user'] as Map);
      final user = DccUser(
        id: row['id']?.toString() ?? '', name: row['name']?.toString() ?? '',
        email: row['email']?.toString() ?? '', role: row['role']?.toString() ?? '',
        hodName: row['hod_name']?.toString() ?? '', hodEmail: row['hod_email']?.toString() ?? '',
        password: '', active: row['active'] == true, sessionToken: token,
      );
      if (user.id.isEmpty || user.email.isEmpty || user.role.isEmpty || !user.active) {
        await clear(revokeServerSession: false); return false;
      }
      currentUser = user;
      await prefs.setString(_sessionKey, jsonEncode({
        'id': user.id, 'name': user.name, 'email': user.email, 'role': user.role,
        'hodName': user.hodName, 'hodEmail': user.hodEmail, 'active': user.active,
      }));
      return true;
    } catch (_) {
      await clear(revokeServerSession: false);
      return false;
    }
  }

  static Future<void> clear({bool revokeServerSession = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (revokeServerSession && token != null && token.isNotEmpty) {
      try { await DccApiClient.post('/auth/logout'); } catch (_) {}
    }
    currentUser = null;
    await prefs.remove(_sessionKey);
    await prefs.remove(_tokenKey);
  }

  static bool get isLoggedIn => currentUser != null;

  static Future<bool> validateCurrentSession() async {
    try {
      final result = await DccApiClient.get('/auth/session');
      return result is Map && result['valid'] == true;
    } catch (_) {
      return false;
    }
  }
}
