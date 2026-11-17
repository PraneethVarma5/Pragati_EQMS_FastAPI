
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/dcc/dcc_user.dart';
import 'dcc_session.dart';

class DccUserService {
  static const String tableName = 'dcc_users';

  static SupabaseClient get _client => Supabase.instance.client;

  static String _requireSessionToken() {
    final token = DccSession.currentUser?.sessionToken ?? '';

    if (token.isEmpty) {
      throw Exception(
        'Your DCC session has expired. Please log in again.',
      );
    }

    return token;
  }

  static DccUser _fromRow(Map<String, dynamic> row) {
    return DccUser(
      id: row['id']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      email: row['email']?.toString() ?? '',
      role: row['role']?.toString() ?? '',
      hodName: row['hod_name']?.toString() ?? '',
      hodEmail: row['hod_email']?.toString() ?? '',
      password: '',
      active: row['active'] == true,
      deletedAt: row['deleted_at'] == null
          ? null
          : DateTime.tryParse(row['deleted_at'].toString()),
    );
  }

  static Future<void> addUser(DccUser user) async {
    await _client.rpc(
      'dcc_create_user',
      params: {
        'p_session_token': _requireSessionToken(),
        'p_id': user.id,
        'p_name': user.name,
        'p_email': user.email.trim().toLowerCase(),
        'p_role': user.role.trim().toUpperCase(),
        'p_hod_name': user.hodName,
        'p_hod_email': user.hodEmail.trim().toLowerCase(),
        'p_password': user.password,
        'p_active': user.active,
      },
    );
  }

  // ---------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------

  static Future<DccUser?> verifyLogin({
    required String email,
    required String password,
  }) async {
    final response = await _client.rpc(
      'dcc_login_with_session_v2',
      params: {
        'p_email': email.trim().toLowerCase(),
        'p_password': password,
      },
    );

    if (response is! Map) {
      throw Exception('Unexpected login response from server.');
    }

    final result = Map<String, dynamic>.from(response);
    final status = result['status']?.toString();

    if (status == 'DISABLED') {
      throw Exception(
        'Your account is disabled by Admin. '
            'Please contact management for further support.',
      );
    }

    if (status == 'DELETED') {
      throw Exception(
        'Your account has been deleted by Admin. '
            'Please contact management for further support.',
      );
    }

    if (status != 'SUCCESS') {
      return null;
    }

    final userData = result['user'];

    if (userData is! Map) {
      throw Exception('Invalid user information received from server.');
    }

    final row = Map<String, dynamic>.from(userData);
    final token = result['session_token']?.toString() ?? '';

    if (token.isEmpty) {
      throw Exception('Server did not return a session token.');
    }

    return DccUser(
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
  }

  // ---------------------------------------------------------
  // ADMIN USER LIST
  // ---------------------------------------------------------

  static Future<List<DccUser>> getUsers() async {
    final response = await _client.rpc(
      'dcc_get_users',
      params: {
        'p_session_token': _requireSessionToken(),
      },
    );

    final rows = List<Map<String, dynamic>>.from(
      response ?? [],
    );

    return rows.map(_fromRow).toList();
  }

  static Future<DccUser?> findByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final users = await getUsers();

    for (final user in users) {
      if (user.email.trim().toLowerCase() == normalizedEmail &&
          user.isActive) {
        return user;
      }
    }

    return null;
  }

  static Future<bool> emailExists(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final users = await getUsers();

    return users.any(
          (user) =>
      user.email.trim().toLowerCase() == normalizedEmail,
    );
  }

  // ---------------------------------------------------------
  // DISABLE / ENABLE
  // ---------------------------------------------------------

  static Future<void> setUserActive(
      String id,
      bool active,
      ) async {
    final response = await _client.rpc(
      'dcc_set_user_active',
      params: {
        'p_session_token': _requireSessionToken(),
        'p_user_id': id,
        'p_active': active,
      },
    );

    if (response != true) {
      throw Exception('Could not update account status.');
    }
  }

  // ---------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------

  static Future<void> deleteUser(String id) async {
    final response = await _client.rpc(
      'dcc_delete_user',
      params: {
        'p_session_token': _requireSessionToken(),
        'p_user_id': id,
      },
    );

    if (response != true) {
      throw Exception('Could not delete this account.');
    }
  }

  // ---------------------------------------------------------
  // RESTORE
  // ---------------------------------------------------------

  static Future<void> restoreUser(String id) async {
    final response = await _client.rpc(
      'dcc_restore_user',
      params: {
        'p_session_token': _requireSessionToken(),
        'p_user_id': id,
      },
    );

    if (response != true) {
      throw Exception('Could not restore this account.');
    }
  }

  // ---------------------------------------------------------
  // PASSWORD CHANGE
  // ---------------------------------------------------------


  static Future<bool> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = _requireSessionToken();

    final response = await _client.rpc(
      'dcc_change_password_v2',
      params: {
        'p_session_token': token,
        'p_current_password': currentPassword,
        'p_new_password': newPassword,
      },
    );

    return response == true;
  }

}
