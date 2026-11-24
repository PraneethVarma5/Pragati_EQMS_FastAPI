
import 'ccr_api_client.dart';
import 'ccr_session.dart';

class CcrAdminService {
  CcrAdminService._();

  // ============================================================
  // AUTHORIZATION CHECK
  // ============================================================

  static void _validateAdmin() {
    if (!CcrSession.isLoggedIn) {
      throw Exception(
        'CCR session has expired. Please login again.',
      );
    }

    if (!CcrSession.isAdmin) {
      throw Exception(
        'Only a CCR Admin can perform this operation.',
      );
    }

    final token = CcrSession.sessionToken;

    if (token == null || token.trim().isEmpty) {
      throw Exception(
        'CCR admin session token is missing. Please login again.',
      );
    }
  }

  // ============================================================
  // DELETE CCR
  // ============================================================

  static Future<void> deleteCcr({
    required String ccrId,
  }) async {
    _validateAdmin();

    final id = ccrId.trim();

    if (id.isEmpty) {
      throw Exception('CCR ID is required.');
    }

    await CcrApiClient.delete(
      '/admin/cases/$id',
      authenticated: true,
    );
  }

  // ============================================================
  // USER MANAGEMENT
  // ============================================================

  static Future<List<Map<String, dynamic>>> getUsers() async {
    _validateAdmin();

    final response = await CcrApiClient.get(
      '/admin/users',
      authenticated: true,
    );

    if (response is! List) {
      throw Exception(
        'Invalid response received while loading CCR users.',
      );
    }

    return response.map((item) {
      if (item is! Map) {
        throw Exception(
          'Invalid user record received from the server.',
        );
      }

      return Map<String, dynamic>.from(item);
    }).toList();
  }

  static Future<void> createUser({
    required String fullName,
    required String email,
    required String role,
  }) async {
    _validateAdmin();

    final name = fullName.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedRole = role.trim().toLowerCase();

    if (name.isEmpty) {
      throw Exception('Full name is required.');
    }

    if (!normalizedEmail.contains('@')) {
      throw Exception('A valid email address is required.');
    }

    if (!{'user', 'admin'}.contains(normalizedRole)) {
      throw Exception('Invalid CCR user role.');
    }

    await CcrApiClient.post(
      '/admin/users',
      authenticated: true,
      body: {
        'full_name': name,
        'email': normalizedEmail,
        'role': normalizedRole,
      },
    );
  }

  static Future<void> setUserActive({
    required String userId,
    required bool isActive,
  }) async {
    _validateAdmin();

    final id = userId.trim();

    if (id.isEmpty) {
      throw Exception('User ID is required.');
    }

    await CcrApiClient.patch(
      '/admin/users/$id/active',
      authenticated: true,
      query: {
        'is_active': isActive.toString(),
      },
    );
  }

  static Future<void> deleteUser({
    required String userId,
  }) async {
    _validateAdmin();

    final id = userId.trim();

    if (id.isEmpty) {
      throw Exception('User ID is required.');
    }

    await CcrApiClient.delete(
      '/admin/users/$id',
      authenticated: true,
    );
  }

  // ============================================================
  // CREATE TEAM
  // ============================================================

  static Future<String> createTeam({
    required String teamLeaderName,
    required List<String> memberNames,
  }) async {
    _validateAdmin();

    final leader = teamLeaderName.trim();

    if (leader.isEmpty) {
      throw Exception('Team leader name is required.');
    }

    final members = memberNames
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final response = await CcrApiClient.post(
      '/admin/teams',
      authenticated: true,
      body: {
        'team_leader_name': leader,
        'member_names': members,
      },
    );

    if (response is! Map || response['id'] == null) {
      throw Exception(
        'Invalid response received while creating CCR team.',
      );
    }

    return response['id'].toString();
  }

  // ============================================================
  // UPDATE TEAM
  // ============================================================

  static Future<void> updateTeam({
    required String teamId,
    required String teamLeaderName,
    required List<String> memberNames,
  }) async {
    _validateAdmin();

    final id = teamId.trim();
    final leader = teamLeaderName.trim();

    if (id.isEmpty) {
      throw Exception('Team ID is required.');
    }

    if (leader.isEmpty) {
      throw Exception('Team leader name is required.');
    }

    final members = memberNames
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    await CcrApiClient.put(
      '/admin/teams/$id',
      authenticated: true,
      body: {
        'team_leader_name': leader,
        'member_names': members,
      },
    );
  }

  // ============================================================
  // ACTIVATE / DEACTIVATE TEAM
  // ============================================================

  static Future<void> setTeamActive({
    required String teamId,
    required bool isActive,
  }) async {
    _validateAdmin();

    final id = teamId.trim();

    if (id.isEmpty) {
      throw Exception('Team ID is required.');
    }

    await CcrApiClient.patch(
      '/admin/teams/$id/active',
      authenticated: true,
      query: {
        'is_active': isActive.toString(),
      },
    );
  }

  // ============================================================
  // DELETE TEAM
  // ============================================================

  static Future<void> deleteTeam({
    required String teamId,
  }) async {
    _validateAdmin();

    final id = teamId.trim();

    if (id.isEmpty) {
      throw Exception('Team ID is required.');
    }

    await CcrApiClient.delete(
      '/admin/teams/$id',
      authenticated: true,
    );
  }
}
