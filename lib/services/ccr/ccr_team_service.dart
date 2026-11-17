import 'package:supabase_flutter/supabase_flutter.dart';
import 'ccr_admin_service.dart';
import 'ccr_admin_service.dart';

class CcrTeamService {
  CcrTeamService._();

  static final SupabaseClient _supabase =
      Supabase.instance.client;

  // ============================================================
  // GET TEAMS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getTeams({
    bool activeOnly = false,
  }) async {
    final baseQuery = _supabase.from('ccr_teams').select(
      '''
      id,
      team_leader_name,
      is_active,
      created_at,
      updated_at,
      ccr_team_members(
        id,
        team_id,
        member_name,
        created_at
      )
      ''',
    );

    final response = activeOnly
        ? await baseQuery
        .eq('is_active', true)
        .order(
      'created_at',
      ascending: false,
    )
        : await baseQuery.order(
      'created_at',
      ascending: false,
    );

    return List<Map<String, dynamic>>.from(
      response,
    );
  }

  // ============================================================
  // GET SINGLE TEAM
  // ============================================================

  static Future<Map<String, dynamic>?> getTeam(
      String teamId,
      ) async {
    final response = await _supabase
        .from('ccr_teams')
        .select(
      '''
          id,
          team_leader_name,
          is_active,
          created_at,
          updated_at,
          ccr_team_members(
            id,
            team_id,
            member_name,
            created_at
          )
          ''',
    )
        .eq('id', teamId)
        .maybeSingle();

    return response;
  }

  // ============================================================
  // CREATE TEAM
  // ============================================================

  static Future<String> createTeam({
    required String teamLeaderName,
    required List<String> memberNames,
  }) async {
    final leader = teamLeaderName.trim();

    if (leader.isEmpty) {
      throw Exception(
        'Team leader name is required.',
      );
    }

    final members =
    _cleanMemberNames(
      memberNames,
      leader,
    );

    if (members.isEmpty) {
      throw Exception(
        'At least one team member is required.',
      );
    }

    return CcrAdminService.createTeam(
      teamLeaderName: leader,
      memberNames: members,
    );
  }
  // ============================================================
  // UPDATE TEAM
  // ============================================================

  static Future<void> updateTeam({
    required String teamId,
    required String teamLeaderName,
    required List<String> memberNames,
  }) async {
    final id = teamId.trim();
    final leader = teamLeaderName.trim();

    if (id.isEmpty) {
      throw Exception(
        'Team ID is required.',
      );
    }

    if (leader.isEmpty) {
      throw Exception(
        'Team leader name is required.',
      );
    }

    final members =
    _cleanMemberNames(
      memberNames,
      leader,
    );

    if (members.isEmpty) {
      throw Exception(
        'At least one team member is required.',
      );
    }

    await CcrAdminService.updateTeam(
      teamId: id,
      teamLeaderName: leader,
      memberNames: members,
    );
  }

  // ============================================================
  // ACTIVATE / DEACTIVATE
  // ============================================================

  static Future<void> setTeamActive({
    required String teamId,
    required bool isActive,
  }) async {
    final id = teamId.trim();

    if (id.isEmpty) {
      throw Exception(
        'Team ID is required.',
      );
    }

    await CcrAdminService.setTeamActive(
      teamId: id,
      isActive: isActive,
    );
  }
  // ============================================================
  // GET TEAM MEMBERS
  // ============================================================
  static Future<void> deleteTeam({
    required String teamId,
  }) async {
    final id = teamId.trim();

    if (id.isEmpty) {
      throw Exception(
        'Team ID is required.',
      );
    }

    await CcrAdminService.deleteTeam(
      teamId: id,
    );
  }
  static Future<List<Map<String, dynamic>>>
  getTeamMembers(
      String teamId,
      ) async {
    final response =
    await _supabase
        .from('ccr_team_members')
        .select(
      '''
              id,
              team_id,
              member_name,
              created_at
              ''',
    )
        .eq(
      'team_id',
      teamId,
    )
        .order(
      'created_at',
      ascending: true,
    );

    return List<Map<String, dynamic>>.from(
      response,
    );
  }

  // ============================================================
  // ACTIVE TEAMS FOR REGISTRATION
  // ============================================================

  static Future<List<Map<String, dynamic>>>
  getActiveTeamsForSelection() async {
    final teams =
    await getTeams(
      activeOnly: true,
    );

    return teams.map((team) {
      final members =
      <Map<String, dynamic>>[];

      final raw =
      team['ccr_team_members'];

      if (raw is List) {
        for (final member in raw) {
          if (member is Map) {
            members.add(
              Map<String, dynamic>.from(
                member,
              ),
            );
          }
        }
      }

      return {
        'id':
        team['id'],
        'team_leader_name':
        team['team_leader_name'],
        'is_active':
        team['is_active'],
        'members':
        members,
      };
    }).toList();
  }

  // ============================================================
  // SAVE CCR TEAM SNAPSHOT
  // ============================================================

  static Future<void> saveCcrTeamSnapshot({
    required String ccrId,
    required String teamId,
  }) async {
    final caseId =
    ccrId.trim();

    final selectedTeamId =
    teamId.trim();

    if (caseId.isEmpty) {
      throw Exception(
        'CCR ID is required.',
      );
    }

    if (selectedTeamId.isEmpty) {
      throw Exception(
        'Team ID is required.',
      );
    }

    final team =
    await getTeam(
      selectedTeamId,
    );

    if (team == null) {
      throw Exception(
        'Selected team was not found.',
      );
    }

    final leader =
    team['team_leader_name']
        ?.toString()
        .trim();

    if (leader == null ||
        leader.isEmpty) {
      throw Exception(
        'Selected team has no team leader.',
      );
    }

    final snapshot =
    <String>[];

    // Leader is stored first.
    snapshot.add(leader);

    final rawMembers =
    team['ccr_team_members'];

    if (rawMembers is List) {
      for (final member in rawMembers) {
        if (member is! Map) {
          continue;
        }

        final name =
        member['member_name']
            ?.toString()
            .trim();

        if (name == null ||
            name.isEmpty) {
          continue;
        }

        if (!_containsIgnoreCase(
          snapshot,
          name,
        )) {
          snapshot.add(name);
        }
      }
    }

    // Remove previous snapshot.
    await _supabase
        .from('ccr_case_team_members')
        .delete()
        .eq(
      'ccr_id',
      caseId,
    );

    final rows =
    snapshot.map(
          (name) {
        return {
          'ccr_id': caseId,
          'member_name': name,
        };
      },
    ).toList();

    if (rows.isNotEmpty) {
      await _supabase
          .from(
        'ccr_case_team_members',
      )
          .insert(rows);
    }

    // Save selected team on CCR.
    //
    // team_leader is retained because existing CCR
    // functionality/reporting may still use it.
    await _supabase
        .from('ccr_cases')
        .update({
      'team_id':
      selectedTeamId,
      'team_leader':
      leader,
      'updated_at':
      DateTime.now().toIso8601String(),
    })
        .eq(
      'id',
      caseId,
    );
  }

  // ============================================================
  // GET CCR HISTORICAL TEAM
  // ============================================================

  static Future<List<Map<String, dynamic>>>
  getCcrTeamSnapshot(
      String ccrId,
      ) async {
    final response =
    await _supabase
        .from(
      'ccr_case_team_members',
    )
        .select(
      '''
              id,
              ccr_id,
              member_name,
              created_at
              ''',
    )
        .eq(
      'ccr_id',
      ccrId,
    )
        .order(
      'created_at',
      ascending: true,
    );

    return List<Map<String, dynamic>>.from(
      response,
    );
  }

  // ============================================================
  // INSERT MEMBERS
  // ============================================================

  static Future<void> _insertMembers(
      String teamId,
      List<String> memberNames,
      ) async {
    if (memberNames.isEmpty) {
      return;
    }

    final rows =
    memberNames.map(
          (name) {
        return {
          'team_id':
          teamId,
          'member_name':
          name,
        };
      },
    ).toList();

    await _supabase
        .from('ccr_team_members')
        .insert(rows);
  }

  // ============================================================
  // CLEAN MEMBERS
  // ============================================================

  static List<String> _cleanMemberNames(
      List<String> names,
      String leader,
      ) {
    final result =
    <String>[];

    for (final raw in names) {
      final name =
      raw.trim();

      if (name.isEmpty) {
        continue;
      }

      if (_sameName(
        name,
        leader,
      )) {
        continue;
      }

      if (!_containsIgnoreCase(
        result,
        name,
      )) {
        result.add(name);
      }
    }

    return result;
  }

  // ============================================================
  // STRING HELPERS
  // ============================================================

  static bool _containsIgnoreCase(
      List<String> values,
      String value,
      ) {
    return values.any(
          (existing) =>
      existing.trim().toLowerCase() ==
          value.trim().toLowerCase(),
    );
  }

  static bool _sameName(
      String first,
      String second,
      ) {
    return first.trim().toLowerCase() ==
        second.trim().toLowerCase();
  }
  // ============================================================
// DELETE TEAM
// ============================================================


}