import '../../models/dcc/dcc_user.dart';
import 'dcc_api_client.dart';
import 'dcc_session.dart';

class DccUserService {
  static String _text(Map<String, dynamic> row, String key) => row[key]?.toString() ?? '';

  static DccUser _fromRow(Map<String, dynamic> row) => DccUser(
    id: _text(row, 'id'),
    name: _text(row, 'name'),
    email: _text(row, 'email'),
    role: _text(row, 'role'),
    hodName: _text(row, 'hod_name'),
    hodEmail: _text(row, 'hod_email'),
    password: '',
    active: row['active'] == true,
    deletedAt: row['deleted_at'] == null ? null : DateTime.tryParse(row['deleted_at'].toString()),
  );

  static Future<void> addUser(DccUser user) async {
    await DccApiClient.post('/users', body: {
      'id': user.id, 'name': user.name, 'email': user.email.trim().toLowerCase(),
      'role': user.role.trim().toUpperCase(), 'hod_name': user.hodName,
      'hod_email': user.hodEmail.trim().toLowerCase(), 'password': user.password,
      'active': user.active,
    });
  }

  static Future<DccUser?> verifyLogin({required String email, required String password}) async {
    final response = await DccApiClient.post('/auth/login', authenticated: false,
      body: {'email': email.trim().toLowerCase(), 'password': password});
    if (response is! Map) throw Exception('Unexpected login response from FastAPI.');
    final result = Map<String, dynamic>.from(response);
    final status = result['status']?.toString();
    if (status == 'DISABLED') throw Exception('Your account is disabled by Admin. Please contact management.');
    if (status == 'DELETED') throw Exception('Your account has been deleted by Admin. Please contact management.');
    if (status != 'SUCCESS') return null;
    final data = result['user'];
    if (data is! Map) throw Exception('Invalid user information received from server.');
    final token = result['session_token']?.toString() ?? '';
    if (token.isEmpty) throw Exception('FastAPI did not return a session token.');
    return DccUser(
      id: _text(Map<String,dynamic>.from(data), 'id'),
      name: _text(Map<String,dynamic>.from(data), 'name'),
      email: _text(Map<String,dynamic>.from(data), 'email'),
      role: _text(Map<String,dynamic>.from(data), 'role'),
      hodName: _text(Map<String,dynamic>.from(data), 'hod_name'),
      hodEmail: _text(Map<String,dynamic>.from(data), 'hod_email'),
      password: '', active: data['active'] == true, sessionToken: token,
    );
  }

  static Future<List<DccUser>> getUsers() async {
    final response = await DccApiClient.get('/users');
    if (response is! List) throw Exception('Unexpected user-list response from FastAPI.');
    return response.map((e) => _fromRow(Map<String,dynamic>.from(e as Map))).toList();
  }

  static Future<DccUser?> findByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    for (final user in await getUsers()) {
      if (user.email.toLowerCase() == normalized && user.isActive) return user;
    }
    return null;
  }

  static Future<bool> emailExists(String email) async {
    final normalized = email.trim().toLowerCase();
    return (await getUsers()).any((u) => u.email.toLowerCase() == normalized);
  }

  static Future<void> setUserActive(String id, bool active) async {
    await DccApiClient.patch('/users/$id/active?active=$active');
  }

  static Future<void> deleteUser(String id) async {
    await DccApiClient.delete('/users/$id');
  }

  static Future<void> restoreUser(String id) async {
    await DccApiClient.post('/users/$id/restore');
  }

  static Future<bool> changePassword({
    required String email, required String currentPassword, required String newPassword,
  }) async {
    final response = await DccApiClient.post('/auth/change-password', body: {
      'current_password': currentPassword, 'new_password': newPassword,
    });
    if (response is Map && response['success'] == true) {
      await DccSession.clear(revokeServerSession: false);
      return true;
    }
    return false;
  }
}
