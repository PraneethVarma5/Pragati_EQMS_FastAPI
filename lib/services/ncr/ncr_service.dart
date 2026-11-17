import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/ncr/ncr_record.dart';
import '../../models/ncr/ncr_user.dart';
import 'ncr_session.dart';

class NcrService {
  NcrService._();

  static final SupabaseClient _supabase =
      Supabase.instance.client;

// ============================================================
// ACTIVE NCR USERS
//
// Used for Auditee / Auditor dropdowns.
//
// Admin users are loaded through the same security-definer
// RPC already used by NCR User Management.
//
// Only active NCR users are returned.
// All user and role information comes from the database.
// ============================================================

  static Future<List<NcrUser>> getActiveUsers() async {
    try {
      final currentUser = NcrSession.currentUser;

      if (currentUser == null) {
        throw Exception(
          'NCR Admin session has expired.',
        );
      }

      if (!NcrSession.isAdmin) {
        throw Exception(
          'Only an NCR Admin can load NCR users.',
        );
      }

      final response = await _supabase.rpc(
        'ncr_admin_users',
        params: {
          'p_user_id': currentUser.id,
        },
      );

      if (response == null) {
        throw Exception(
          'No NCR users were returned from the database.',
        );
      }

      if (response is! List) {
        throw Exception(
          'Invalid NCR users response.',
        );
      }

      final users = response
          .whereType<Map>()
          .map(
            (item) {
          final data =
          Map<String, dynamic>.from(item);

          return NcrUser.fromMap({
            'id': data['id'],
            'full_name': data['full_name'],
            'email': data['email'],
            'role_id': data['role_id'],
            'is_active': data['is_active'],
            'created_at': data['created_at'],
            'updated_at': data['updated_at'],
            'ncr_roles': {
              'id': data['role_id'],
              'role_key': data['role_key'],
              'role_name': data['role_name'],
              'description':
              data['description'],
              'is_active':
              data['role_is_active'] ??
                  data['is_active'],
            },
          });
        },
      )
          .where(
            (user) => user.isActive,
      )
          .toList();

      users.sort(
            (a, b) => a.fullName
            .toLowerCase()
            .compareTo(
          b.fullName.toLowerCase(),
        ),
      );

      return users;
    } on PostgrestException catch (e) {
      throw Exception(
        e.message,
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to load NCR users.',
      );
    }
  }

  // ============================================================
  // CREATE NCR
  // ============================================================

  static Future<NcrRecord> createNcr({
    required String processFunction,
    required String clauseSection,
    required String auditeeId,
    required String standard,
    required String iaNo,
    required String auditorId,
    required DateTime auditDate,
    required String findingStatement,
    required String requirementClauseReference,
  }) async {
    final currentUser = NcrSession.currentUser;

    if (currentUser == null) {
      throw Exception(
        'No NCR user is currently logged in.',
      );
    }

    if (!NcrSession.isAdmin) {
      throw Exception(
        'Only an NCR Admin can create an NCR.',
      );
    }

    final response = await _supabase.rpc(
      'ncr_admin_create_ncr',
      params: {
        'p_process_function':
        processFunction.trim(),

        'p_clause_section':
        clauseSection.trim(),

        'p_auditee_id':
        auditeeId,

        'p_standard':
        standard.trim(),

        'p_ia_no':
        iaNo.trim(),

        'p_auditor_id':
        auditorId,

        'p_audit_date':
        auditDate.toIso8601String().split('T').first,

        'p_finding_statement':
        findingStatement.trim(),

        'p_requirement_clause_reference':
        requirementClauseReference.trim(),

        'p_created_by':
        currentUser.id,
      },
    );

    if (response == null) {
      throw Exception(
        'NCR could not be created.',
      );
    }

    if (response is! Map) {
      throw Exception(
        'Invalid NCR creation response.',
      );
    }

    final map =
    Map<String, dynamic>.from(response);

    return NcrRecord.fromMap(map);
  }

  // ============================================================
  // GET NCR BY ID
  // ============================================================

  // ============================================================
  // GET NCR BY ID
  //
  // Admin version uses security-definer RPC.
  // Complete NCR details and approval history are returned
  // from the database.
  // ============================================================

  static Future<NcrRecord?> getNcrById(
      String ncrId,
      ) async {
    final currentUser = NcrSession.currentUser;

    if (ncrId.trim().isEmpty) {
      return null;
    }

    if (currentUser == null || !NcrSession.isAdmin) {
      throw Exception(
        'Only an NCR Admin can view NCR details.',
      );
    }

    try {
      final response = await _supabase.rpc(
        'ncr_admin_ncr_details',
        params: {
          'p_user_id': currentUser.id,
          'p_ncr_id': ncrId,
        },
      );

      if (response == null) {
        return null;
      }

      if (response is! Map) {
        throw Exception(
          'Invalid NCR details response.',
        );
      }

      final map =
      Map<String, dynamic>.from(response);

      return NcrRecord.fromMap(map);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to load NCR details.',
      );
    }
  }
  // ============================================================
  // GET ALL NCR RECORDS
  //
  // Used by:
  // - Admin
  // - User
  // - HOD
  // - DCC
  //
  // This method only reads NCR information.
  // Workflow permissions are handled separately.
  // ============================================================

  // ============================================================
  // GET ALL NCR RECORDS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getAllNcrs() async {
    final currentUser = NcrSession.currentUser;

    if (currentUser == null || !NcrSession.isAdmin) {
      throw Exception(
        'Only an NCR Admin can view all NCR records.',
      );
    }

    try {
      final response = await _supabase.rpc(
        'ncr_admin_all_ncrs',
        params: {
          'p_user_id': currentUser.id,
        },
      );

      if (response == null) {
        return [];
      }

      if (response is! List) {
        throw Exception(
          'Invalid NCR records response.',
        );
      }

      return response
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
      )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to load NCR records.',
      );
    }
  }
  // ============================================================
  // GET ACTIVE NCR STATUSES
  //
  // Status names come from the database.
  // Nothing is hardcoded in the UI.
  // ============================================================

  // ============================================================
  // GET ACTIVE NCR STATUSES
  // ============================================================

  static Future<List<Map<String, dynamic>>>
  getActiveStatuses() async {
    final currentUser = NcrSession.currentUser;

    if (currentUser == null || !NcrSession.isAdmin) {
      throw Exception(
        'Only an NCR Admin can view NCR statuses.',
      );
    }

    try {
      final response = await _supabase.rpc(
        'ncr_admin_statuses',
        params: {
          'p_user_id': currentUser.id,
        },
      );

      if (response == null) {
        return [];
      }

      if (response is! List) {
        throw Exception(
          'Invalid NCR status response.',
        );
      }

      return response
          .whereType<Map>()
          .map(
            (item) =>
        Map<String, dynamic>.from(item),
      )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to load NCR statuses.',
      );
    }
  }
  // ============================================================
  // GET APPROVAL HISTORY
  // ============================================================

  static Future<List<Map<String, dynamic>>>
  getApprovalHistory(
      String ncrId,
      ) async {
    if (ncrId.trim().isEmpty) {
      return [];
    }

    try {
      final response = await _supabase
          .from('ncr_approval_history')
          .select('''
            *,
            action_user:ncr_users!ncr_approval_history_action_by_fkey(
              id,
              full_name,
              email
            ),
            action_role:ncr_roles!ncr_approval_history_action_role_id_fkey(
              id,
              role_key,
              role_name
            ),
            previous_status:ncr_statuses!ncr_approval_history_previous_status_id_fkey(
              id,
              status_key,
              status_name
            ),
            new_status:ncr_statuses!ncr_approval_history_new_status_id_fkey(
              id,
              status_key,
              status_name
            )
          ''')
          .eq(
        'ncr_id',
        ncrId,
      )
          .order(
        'created_at',
        ascending: false,
      );

      if (response is! List) {
        throw Exception(
          'Invalid NCR approval history response.',
        );
      }

      return response
          .whereType<Map>()
          .map((item) {
        final map =
        Map<String, dynamic>.from(item);

        final actionUser =
        map['action_user'];

        if (actionUser is Map) {
          map['action_by_name'] =
          actionUser['full_name'];

          map['action_by_email'] =
          actionUser['email'];
        }

        final actionRole =
        map['action_role'];

        if (actionRole is Map) {
          map['action_role_key'] =
          actionRole['role_key'];

          map['action_role_name'] =
          actionRole['role_name'];
        }

        final previousStatus =
        map['previous_status'];

        if (previousStatus is Map) {
          map['previous_status_key'] =
          previousStatus['status_key'];

          map['previous_status_name'] =
          previousStatus['status_name'];
        }

        final newStatus =
        map['new_status'];

        if (newStatus is Map) {
          map['new_status_key'] =
          newStatus['status_key'];

          map['new_status_name'] =
          newStatus['status_name'];
        }

        return map;
      })
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(
        e.message,
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to load NCR approval history.',
      );
    }
  }
  // ============================================================
  // GET NCRs ASSIGNED TO CURRENT USER
  // ============================================================

  static Future<List<Map<String, dynamic>>>
  getAssignedNcrs() async {
    final currentUser =
        NcrSession.currentUser;

    if (currentUser == null ||
        !NcrSession.isUser) {
      throw Exception(
        'Only an NCR User can access assigned NCRs.',
      );
    }

    try {
      final response =
      await _supabase.rpc(
        'ncr_user_assigned_ncrs',
        params: {
          'p_user_id':
          currentUser.id,
        },
      );

      if (response == null) {
        return [];
      }

      if (response is! List) {
        throw Exception(
          'Invalid assigned NCR response.',
        );
      }

      return response
          .whereType<Map>()
          .map(
            (item) =>
        Map<String, dynamic>.from(item),
      )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to load assigned NCRs.',
      );
    }
  }


  // ============================================================
  // UPDATE ACTION PLAN
  // ============================================================

  static Future<void> updateActionPlan({
    required String ncrId,
    required String rootCauses,
    required String correction,
    DateTime? correctionEffectiveDate,
    required String correctiveAction,
    DateTime? correctiveActionEffectiveDate,
    required String followUpAuditDetails,
    DateTime? followUpAuditDate,
    required String effectivenessOfCorrectiveAction,
    DateTime? effectivenessDate,
  }) async {
    final currentUser =
        NcrSession.currentUser;

    if (currentUser == null ||
        !NcrSession.isUser) {
      throw Exception(
        'Only an NCR User can update an action plan.',
      );
    }

    try {
      await _supabase.rpc(
        'ncr_user_update_action_plan',
        params: {
          'p_user_id':
          currentUser.id,

          'p_ncr_id':
          ncrId,

          'p_root_causes':
          rootCauses.trim(),

          'p_correction':
          correction.trim(),

          'p_correction_effective_date':
          correctionEffectiveDate
              ?.toIso8601String()
              .split('T')
              .first,

          'p_corrective_action':
          correctiveAction.trim(),

          'p_corrective_action_effective_date':
          correctiveActionEffectiveDate
              ?.toIso8601String()
              .split('T')
              .first,

          'p_follow_up_audit_details':
          followUpAuditDetails.trim(),

          'p_follow_up_audit_date':
          followUpAuditDate
              ?.toIso8601String()
              .split('T')
              .first,

          'p_effectiveness_of_corrective_action':
          effectivenessOfCorrectiveAction
              .trim(),

          'p_effectiveness_date':
          effectivenessDate
              ?.toIso8601String()
              .split('T')
              .first,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to update NCR action plan.',
      );
    }
  }


  // ============================================================
  // SUBMIT ACTION PLAN TO HOD
  // ============================================================

  static Future<void> submitActionPlan(
      String ncrId,
      ) async {
    final currentUser =
        NcrSession.currentUser;

    if (currentUser == null ||
        !NcrSession.isUser) {
      throw Exception(
        'Only an NCR User can submit an action plan.',
      );
    }

    try {
      await _supabase.rpc(
        'ncr_user_submit_action_plan',
        params: {
          'p_user_id':
          currentUser.id,
          'p_ncr_id':
          ncrId,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to submit action plan.',
      );
    }
  }
  // ============================================================
  // HOD DASHBOARD DATA
  // ============================================================

  static Future<Map<String, dynamic>>
  getHodDashboardData() async {
    final currentUser =
        NcrSession.currentUser;

    if (currentUser == null ||
        !NcrSession.isHod) {
      throw Exception(
        'Only an NCR HOD can access the HOD dashboard.',
      );
    }

    try {
      final response =
      await _supabase.rpc(
        'ncr_hod_dashboard_data',
        params: {
          'p_user_id':
          currentUser.id,
        },
      );

      if (response == null ||
          response is! Map) {
        throw Exception(
          'Invalid HOD dashboard response.',
        );
      }

      return Map<String, dynamic>.from(
        response,
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to load HOD dashboard.',
      );
    }
  }


  // ============================================================
  // ALL NCRs FOR HOD
  // ============================================================

  static Future<List<Map<String, dynamic>>>
  getHodAllNcrs() async {
    final currentUser =
        NcrSession.currentUser;

    if (currentUser == null ||
        !NcrSession.isHod) {
      throw Exception(
        'Only an NCR HOD can view NCR records.',
      );
    }

    try {
      final response =
      await _supabase.rpc(
        'ncr_hod_all_ncrs',
        params: {
          'p_user_id':
          currentUser.id,
        },
      );

      if (response == null) {
        return [];
      }

      if (response is! List) {
        throw Exception(
          'Invalid HOD NCR response.',
        );
      }

      return response
          .whereType<Map>()
          .map(
            (item) =>
        Map<String, dynamic>.from(
          item,
        ),
      )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to load NCR records.',
      );
    }
  }


  // ============================================================
  // HOD APPROVE
  // ============================================================

  static Future<void> hodApprove({
    required String ncrId,
    String comments = '',
  }) async {
    final currentUser =
        NcrSession.currentUser;

    if (currentUser == null ||
        !NcrSession.isHod) {
      throw Exception(
        'Only an NCR HOD can approve NCRs.',
      );
    }

    try {
      await _supabase.rpc(
        'ncr_hod_approve',
        params: {
          'p_user_id':
          currentUser.id,
          'p_ncr_id':
          ncrId,
          'p_comments':
          comments.trim(),
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to approve NCR.',
      );
    }
  }


  // ============================================================
  // HOD REJECT
  // ============================================================

  static Future<void> hodReject({
    required String ncrId,
    required String comments,
  }) async {
    final currentUser =
        NcrSession.currentUser;

    if (currentUser == null ||
        !NcrSession.isHod) {
      throw Exception(
        'Only an NCR HOD can reject NCRs.',
      );
    }

    if (comments.trim().isEmpty) {
      throw Exception(
        'Rejection comments are required.',
      );
    }

    try {
      await _supabase.rpc(
        'ncr_hod_reject',
        params: {
          'p_user_id':
          currentUser.id,
          'p_ncr_id':
          ncrId,
          'p_comments':
          comments.trim(),
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to reject NCR.',
      );
    }
  }
  // ============================================================
  // DCC DASHBOARD DATA
  // ============================================================

  static Future<Map<String, dynamic>>
  getDccDashboardData() async {
    final currentUser =
        NcrSession.currentUser;

    if (currentUser == null ||
        !NcrSession.isDcc) {
      throw Exception(
        'Only an NCR DCC can access the DCC dashboard.',
      );
    }

    try {
      final response =
      await _supabase.rpc(
        'ncr_dcc_dashboard_data',
        params: {
          'p_user_id': currentUser.id,
        },
      );

      if (response == null ||
          response is! Map) {
        throw Exception(
          'Invalid DCC dashboard response.',
        );
      }

      return Map<String, dynamic>.from(
        response,
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to load DCC dashboard.',
      );
    }
  }

  // ============================================================
  // ALL NCRs FOR DCC
  // ============================================================

  static Future<List<Map<String, dynamic>>>
  getDccAllNcrs() async {
    final currentUser =
        NcrSession.currentUser;

    if (currentUser == null ||
        !NcrSession.isDcc) {
      throw Exception(
        'Only an NCR DCC can view NCR records.',
      );
    }

    try {
      final response =
      await _supabase.rpc(
        'ncr_dcc_all_ncrs',
        params: {
          'p_user_id': currentUser.id,
        },
      );

      if (response == null) {
        return [];
      }

      if (response is! List) {
        throw Exception(
          'Invalid DCC NCR response.',
        );
      }

      return response
          .whereType<Map>()
          .map(
            (item) =>
        Map<String, dynamic>.from(
          item,
        ),
      )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to load DCC NCR records.',
      );
    }
  }

  // ============================================================
  // DCC APPROVE / CLOSE
  // ============================================================

  static Future<void> dccApprove({
    required String ncrId,
    String comments = '',
  }) async {
    final currentUser =
        NcrSession.currentUser;

    if (currentUser == null ||
        !NcrSession.isDcc) {
      throw Exception(
        'Only an NCR DCC can approve NCRs.',
      );
    }

    try {
      await _supabase.rpc(
        'ncr_dcc_approve',
        params: {
          'p_user_id':
          currentUser.id,
          'p_ncr_id':
          ncrId,
          'p_comments':
          comments.trim(),
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to approve NCR.',
      );
    }
  }

  // ============================================================
  // DCC REJECT
  // ============================================================

  static Future<void> dccReject({
    required String ncrId,
    required String comments,
  }) async {
    final currentUser =
        NcrSession.currentUser;

    if (currentUser == null ||
        !NcrSession.isDcc) {
      throw Exception(
        'Only an NCR DCC can reject NCRs.',
      );
    }

    if (comments.trim().isEmpty) {
      throw Exception(
        'Rejection comments are required.',
      );
    }

    try {
      await _supabase.rpc(
        'ncr_dcc_reject',
        params: {
          'p_user_id':
          currentUser.id,
          'p_ncr_id':
          ncrId,
          'p_comments':
          comments.trim(),
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to reject NCR.',
      );
    }
  }
  // ============================================================
  // PUBLIC NCR DASHBOARD
  //
  // This method does NOT require NCR login.
  //
  // It is used by the common NCR home/dashboard screen so that
  // visitors can see the current NCR statistics and records.
  // ============================================================

  static Future<Map<String, dynamic>>
  getPublicDashboardData() async {
    try {
      final response =
      await _supabase.rpc(
        'ncr_public_dashboard_data',
      );

      if (response == null) {
        throw Exception(
          'No public NCR dashboard data was returned.',
        );
      }

      if (response is! Map) {
        throw Exception(
          'Invalid public NCR dashboard response.',
        );
      }

      return Map<String, dynamic>.from(
        response,
      );
    } on PostgrestException catch (e) {
      throw Exception(
        e.message,
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to load public NCR dashboard.',
      );
    }
  }
}