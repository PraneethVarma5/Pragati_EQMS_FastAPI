
import 'ccr_api_client.dart';
import 'ccr_admin_service.dart';

class CcrTeamService {
  CcrTeamService._();

  // ============================================================
  // GET TEAMS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getTeams({
    bool activeOnly = false,
  }) async {
    final response = await CcrApiClient.get(
      '/teams',
      query: {
        'active_only': activeOnly.toString(),
      },
    );

    if (response is! List) {
      throw Exception('Invalid response received while loading CCR teams.');
    }

    final teams = response
        .whereType<Map>()
        .map((team) => Map<String, dynamic>.from(team))
        .toList();

    // Preserve the original Supabase ordering:
    // newest teams first.
    teams.sort((a, b) {
      final dateA = DateTime.tryParse(
        a['created_at']?.toString() ?? '',
      );

      final dateB = DateTime.tryParse(
        b['created_at']?.toString() ?? '',
      );

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateB.compareTo(dateA);
    });

    return teams;
  }

  // ============================================================
  // GET SINGLE TEAM
  // ============================================================

  static Future<Map<String, dynamic>?> getTeam(
      String teamId,
      ) async {
    final id = teamId.trim();

    if (id.isEmpty) {
      throw Exception('Team ID is required.');
    }

    final response = await CcrApiClient.get(
      '/teams/$id',
    );

    if (response is! Map) {
      return null;
    }

    return Map<String, dynamic>.from(response);
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
      throw Exception('Team leader name is required.');
    }

    final members = _cleanMemberNames(
      memberNames,
      leader,
    );

    if (members.isEmpty) {
      throw Exception('At least one team member is required.');
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
      throw Exception('Team ID is required.');
    }

    if (leader.isEmpty) {
      throw Exception('Team leader name is required.');
    }

    final members = _cleanMemberNames(
      memberNames,
      leader,
    );

    if (members.isEmpty) {
      throw Exception('At least one team member is required.');
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
      throw Exception('Team ID is required.');
    }

    await CcrAdminService.setTeamActive(
      teamId: id,
      isActive: isActive,
    );
  }

  // ============================================================
  // DELETE TEAM
  // ============================================================

  static Future<void> deleteTeam({
    required String teamId,
  }) async {
    final id = teamId.trim();

    if (id.isEmpty) {
      throw Exception('Team ID is required.');
    }

    await CcrAdminService.deleteTeam(
      teamId: id,
    );
  }

  // ============================================================
  // GET TEAM MEMBERS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getTeamMembers(
      String teamId,
      ) async {
    final id = teamId.trim();

    if (id.isEmpty) {
      throw Exception('Team ID is required.');
    }

    final response = await CcrApiClient.get(
      '/teams/$id/members',
    );

    if (response is! List) {
      throw Exception(
        'Invalid response received while loading team members.',
      );
    }

    return response
        .whereType<Map>()
        .map((member) => Map<String, dynamic>.from(member))
        .toList();
  }

  // ============================================================
  // ACTIVE TEAMS FOR REGISTRATION
  // ============================================================

  static Future<List<Map<String, dynamic>>>
  getActiveTeamsForSelection() async {
    final teams = await getTeams(
      activeOnly: true,
    );

    // FastAPI's GET /teams returns the team records.
    // Fetch each team's members separately.
    final result = await Future.wait(
      teams.map((team) async {
        final teamId = team['id']?.toString() ?? '';

        if (teamId.isEmpty) {
          return {
            'id': team['id'],
            'team_leader_name': team['team_leader_name'],
            'is_active': team['is_active'],
            'members': <Map<String, dynamic>>[],
          };
        }

        final details = await getTeam(teamId);

        final rawMembers = details?['ccr_team_members'];

        final members = rawMembers is List
            ? rawMembers
            .whereType<Map>()
            .map(
              (member) => Map<String, dynamic>.from(member),
        )
            .toList()
            : <Map<String, dynamic>>[];

        return {
          'id': team['id'],
          'team_leader_name': team['team_leader_name'],
          'is_active': team['is_active'],
          'members': members,
        };
      }),
    );

    return result;
  }

  // ============================================================
  // SAVE CCR TEAM SNAPSHOT
  // ============================================================

  static Future<void> saveCcrTeamSnapshot({
    required String ccrId,
    required String teamId,
  }) async {
    final caseId = ccrId.trim();
    final selectedTeamId = teamId.trim();

    if (caseId.isEmpty) {
      throw Exception('CCR ID is required.');
    }

    if (selectedTeamId.isEmpty) {
      throw Exception('Team ID is required.');
    }

    final team = await getTeam(selectedTeamId);

    if (team == null) {
      throw Exception('Selected team was not found.');
    }

    final leader = team['team_leader_name']
        ?.toString()
        .trim();

    if (leader == null || leader.isEmpty) {
      throw Exception('Selected team has no team leader.');
    }

    final snapshot = <String>[];

    // Leader is stored first.
    snapshot.add(leader);

    final rawMembers = team['ccr_team_members'];

    if (rawMembers is List) {
      for (final member in rawMembers) {
        if (member is! Map) {
          continue;
        }

        final name = member['member_name']
            ?.toString()
            .trim();

        if (name == null || name.isEmpty) {
          continue;
        }

        if (!_containsIgnoreCase(snapshot, name)) {
          snapshot.add(name);
        }
      }
    }

    // Save the historical team snapshot through FastAPI.
    await CcrApiClient.put(
      '/cases/$caseId/team-snapshot',
      body: {
        'data': {
          'team_id': selectedTeamId,
          'team_leader_name': leader,
          'members': snapshot,
        },
      },
    );
  }

  // ============================================================
  // GET CCR HISTORICAL TEAM
  // ============================================================

  static Future<List<Map<String, dynamic>>>
  getCcrTeamSnapshot(String ccrId) async {
    final caseId = ccrId.trim();

    if (caseId.isEmpty) {
      throw Exception('CCR ID is required.');
    }

    final response = await CcrApiClient.get(
      '/cases/$caseId/team-snapshot',
    );

    if (response is! List) {
      throw Exception(
        'Invalid response received while loading CCR team snapshot.',
      );
    }

    return response
        .whereType<Map>()
        .map(
          (member) => Map<String, dynamic>.from(member),
    )
        .toList();
  }

  // ============================================================
  // CLEAN MEMBERS
  // ============================================================

  static List<String> _cleanMemberNames(
      List<String> names,
      String leader,
      ) {
    final result = <String>[];

    for (final raw in names) {
      final name = raw.trim();

      if (name.isEmpty) {
        continue;
      }

      if (_sameName(name, leader)) {
        continue;
      }

      if (!_containsIgnoreCase(result, name)) {
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
}
