import 'package:supabase_flutter/supabase_flutter.dart';

import 'ccr_session.dart';

class CcrAdminService {
  CcrAdminService._();

  static final SupabaseClient _supabase =
      Supabase.instance.client;

  static String _token() {
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

    final token =
        CcrSession.sessionToken;

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'CCR admin session token is missing.',
      );
    }

    return token.trim();
  }

  // ============================================================
  // DELETE CCR
  // ============================================================

  static Future<void> deleteCcr({
    required String ccrId,
  }) async {
    final token = _token();

    final id = ccrId.trim();

    if (id.isEmpty) {
      throw Exception(
        'CCR ID is required.',
      );
    }

    await _supabase.rpc(
      'ccr_admin_delete_case',
      params: {
        'p_session_token': token,
        'p_ccr_id': id,
      },
    );
  }

  // ============================================================
  // CREATE TEAM
  // ============================================================

  static Future<String> createTeam({
    required String teamLeaderName,
    required List<String> memberNames,
  }) async {
    final token = _token();

    final leader =
    teamLeaderName.trim();

    final members = memberNames
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final response =
    await _supabase.rpc(
      'ccr_admin_create_team',
      params: {
        'p_session_token': token,
        'p_team_leader_name': leader,
        'p_member_names': members,
      },
    );

    return response.toString();
  }

  // ============================================================
  // UPDATE TEAM
  // ============================================================

  static Future<void> updateTeam({
    required String teamId,
    required String teamLeaderName,
    required List<String> memberNames,
  }) async {
    final token = _token();

    await _supabase.rpc(
      'ccr_admin_update_team',
      params: {
        'p_session_token': token,
        'p_team_id': teamId.trim(),
        'p_team_leader_name':
        teamLeaderName.trim(),
        'p_member_names': memberNames
            .map((e) => e.trim())
            .where(
              (e) => e.isNotEmpty,
        )
            .toList(),
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
    final token = _token();

    await _supabase.rpc(
      'ccr_admin_set_team_active',
      params: {
        'p_session_token': token,
        'p_team_id': teamId.trim(),
        'p_is_active': isActive,
      },
    );
  }

  // ============================================================
  // DELETE TEAM
  // ============================================================

  static Future<void> deleteTeam({
    required String teamId,
  }) async {
    final token = _token();

    await _supabase.rpc(
      'ccr_admin_delete_team',
      params: {
        'p_session_token': token,
        'p_team_id': teamId.trim(),
      },
    );
  }
  // ============================================================
// DELETE TEAM
// ============================================================


}