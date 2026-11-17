
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/dcc/dcc_user.dart';
import '../session_activity.dart';

class DccSession {
  static DccUser? currentUser;

  static const String _sessionKey = 'dcc_active_session';
  static const String _tokenKey = 'dcc_server_session_token';

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<void> setUser(DccUser user) async {
    if (user.sessionToken.isEmpty) {
      throw Exception('Cannot save DCC session without server token.');
    }

    currentUser = user;

    final prefs = await SharedPreferences.getInstance();

    // Store the token separately from the profile.
    await prefs.setString(_tokenKey, user.sessionToken);

    await prefs.setString(
      _sessionKey,
      jsonEncode({
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'role': user.role,
        'hodName': user.hodName,
        'hodEmail': user.hodEmail,
        'active': user.active,
      }),
    );

    await SessionActivity.reset();
  }

  static Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final rawProfile = prefs.getString(_sessionKey);
      final token = prefs.getString(_tokenKey);

      if (rawProfile == null ||
          rawProfile.trim().isEmpty ||
          token == null ||
          token.isEmpty) {
        await clear();
        return false;
      }

      // Preserve the existing local idle timeout.
      if (await SessionActivity.isExpired()) {
        await clear();
        return false;
      }

      // Ask PostgreSQL to validate the actual session.
      final response = await _client.rpc(
        'dcc_validate_session',
        params: {
          'p_session_token': token,
        },
      );

      final rows = List<Map<String, dynamic>>.from(response ?? []);

      if (rows.isEmpty) {
        await clear();
        return false;
      }

      final row = rows.first;

      final user = DccUser(
        id: row['id']?.toString() ?? '',
        name: row['name']?.toString() ?? '',
        email: row['email']?.toString() ?? '',
        role: row['role']?.toString() ?? '',
        hodName: row['hod_name']?.toString() ?? '',
        hodEmail: row['hod_email']?.toString() ?? '',
        password: '',
        active: row['active'] == true,
        sessionToken: token,
      );

      if (user.id.isEmpty ||
          user.email.isEmpty ||
          user.role.isEmpty ||
          !user.active) {
        await clear();
        return false;
      }

      // Use the database profile, not the cached browser role.
      currentUser = user;

      // Refresh cached profile with authoritative values.
      await prefs.setString(
        _sessionKey,
        jsonEncode({
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'role': user.role,
          'hodName': user.hodName,
          'hodEmail': user.hodEmail,
          'active': user.active,
        }),
      );

      return true;
    } catch (_) {
      await clear();
      return false;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    // Attempt server-side revocation before removing local credentials.
    if (token != null && token.isNotEmpty) {
      try {
        await _client.rpc(
          'dcc_logout',
          params: {
            'p_session_token': token,
          },
        );
      } catch (_) {
        // Always clear local credentials even if the network is unavailable.
      }
    }

    currentUser = null;

    await prefs.remove(_sessionKey);
    await prefs.remove(_tokenKey);
  }

  static bool get isLoggedIn => currentUser != null;

  static Future<bool> validateCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token == null || token.isEmpty) {
      await clear();
      return false;
    }

    try {
      final response = await _client.rpc(
        'dcc_validate_session',
        params: {
          'p_session_token': token,
        },
      );

      final rows = List<Map<String, dynamic>>.from(response ?? []);

      if (rows.isEmpty) {
        await clear();
        return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}
