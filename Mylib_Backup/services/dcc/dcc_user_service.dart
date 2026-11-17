import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/dcc/dcc_user.dart';

class DccUserService {
  static const String tableName = 'dcc_users';

  static SupabaseClient get _client {
    return Supabase.instance.client;
  }

  static DccUser _fromRow(Map<String, dynamic> row) {
    return DccUser(
      id: row['id']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      email: row['email']?.toString() ?? '',
      role: row['role']?.toString() ?? '',
      hodName: row['hod_name']?.toString() ?? '',
      hodEmail: row['hod_email']?.toString() ?? '',
      password: row['password']?.toString() ?? '',
      active: row['active'] == true,
    );
  }

  static Map<String, dynamic> _toRow(DccUser user) {
    return {
      'id': user.id,
      'name': user.name,
      'email': user.email.trim().toLowerCase(),
      'role': user.role.trim().toUpperCase(),
      'hod_name': user.hodName,
      'hod_email': user.hodEmail.trim().toLowerCase(),
      'password': user.password,
      'active': user.active,
    };
  }

  static Future<void> addUser(DccUser user) async {
    await _client
        .from(tableName)
        .upsert(_toRow(user));
  }

  static Future<List<DccUser>> getUsers() async {
    final response = await _client
        .from(tableName)
        .select()
        .order('created_at', ascending: true);

    return (response as List)
        .map(
          (row) => _fromRow(
        Map<String, dynamic>.from(row),
      ),
    )
        .toList();
  }

  static Future<DccUser?> findByEmail(String email) async {
    final normalizedEmail =
    email.trim().toLowerCase();

    final response = await _client
        .from(tableName)
        .select()
        .eq('email', normalizedEmail)
        .eq('active', true)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return _fromRow(
      Map<String, dynamic>.from(response),
    );
  }

  static Future<bool> emailExists(String email) async {
    final user = await findByEmail(email);

    return user != null;
  }

  static Future<void> deleteUser(String id) async {
    await _client
        .from(tableName)
        .delete()
        .eq('id', id);
  }

  static Future<void> setUserActive(
      String id,
      bool active,
      ) async {
    await _client
        .from(tableName)
        .update({
      'active': active,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', id);
  }
}