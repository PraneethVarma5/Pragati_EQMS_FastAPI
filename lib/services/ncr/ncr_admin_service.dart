import 'package:supabase_flutter/supabase_flutter.dart';

import 'ncr_session.dart';

class NcrAdminDashboardData {
  final int totalNcrs;
  final int inProgress;
  final int pendingHod;
  final int pendingDcc;
  final int closed;

  const NcrAdminDashboardData({
    required this.totalNcrs,
    required this.inProgress,
    required this.pendingHod,
    required this.pendingDcc,
    required this.closed,
  });

  factory NcrAdminDashboardData.fromMap(
      Map<String, dynamic> map,
      ) {
    return NcrAdminDashboardData(
      totalNcrs: _toInt(map['total_ncrs']),
      inProgress: _toInt(map['in_progress']),
      pendingHod: _toInt(map['pending_hod']),
      pendingDcc: _toInt(map['pending_dcc']),
      closed: _toInt(map['closed']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }
}

class NcrAdminUser {
  final String id;
  final String fullName;
  final String email;
  final String roleId;
  final String roleKey;
  final String roleName;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NcrAdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.roleId,
    required this.roleKey,
    required this.roleName,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory NcrAdminUser.fromMap(
      Map<String, dynamic> map,
      ) {
    return NcrAdminUser(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      roleId: map['role_id']?.toString() ?? '',
      roleKey: map['role_key']?.toString() ?? '',
      roleName: map['role_name']?.toString() ?? '',
      isActive: map['is_active'] == true,
      createdAt: DateTime.tryParse(
        map['created_at']?.toString() ?? '',
      ),
      updatedAt: DateTime.tryParse(
        map['updated_at']?.toString() ?? '',
      ),
    );
  }
}

class NcrRoleOption {
  final String id;
  final String roleKey;
  final String roleName;
  final String description;
  final bool isActive;

  const NcrRoleOption({
    required this.id,
    required this.roleKey,
    required this.roleName,
    required this.description,
    required this.isActive,
  });

  factory NcrRoleOption.fromMap(
      Map<String, dynamic> map,
      ) {
    return NcrRoleOption(
      id: map['id']?.toString() ?? '',
      roleKey: map['role_key']?.toString() ?? '',
      roleName: map['role_name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      isActive: map['is_active'] == true,
    );
  }
}

class NcrAdminService {
  NcrAdminService._();

  static final SupabaseClient _supabase =
      Supabase.instance.client;

  // ============================================================
  // DASHBOARD STATISTICS
  // ============================================================

  static Future<NcrAdminDashboardData>
  getDashboardData() async {
    final response = await _supabase.rpc(
      'ncr_admin_dashboard_data',
    );

    if (response == null) {
      throw Exception(
        'NCR dashboard data could not be loaded.',
      );
    }

    if (response is! Map) {
      throw Exception(
        'Invalid NCR dashboard response.',
      );
    }

    return NcrAdminDashboardData.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  // ============================================================
  // ALL NCR USERS
  // ============================================================

  static Future<List<NcrAdminUser>>
  getUsers() async {
    final currentUser =
        NcrSession.currentUser;

    if (currentUser == null ||
        !NcrSession.isAdmin) {
      throw Exception(
        'Only an NCR Admin can view NCR users.',
      );
    }

    final response =
    await _supabase.rpc(
      'ncr_admin_users',
      params: {
        'p_user_id': currentUser.id,
      },
    );

    if (response == null) {
      return [];
    }

    if (response is! List) {
      throw Exception(
        'Invalid NCR users response.',
      );
    }

    return response
        .whereType<Map>()
        .map(
          (item) =>
          NcrAdminUser.fromMap(
            Map<String, dynamic>.from(
              item,
            ),
          ),
    )
        .toList();
  }

  // ============================================================
  // ACTIVE NCR ROLES
  // ============================================================

  static Future<List<NcrRoleOption>>
  getRoles() async {
    final response =
    await _supabase.rpc(
      'ncr_roles_list',
    );

    if (response == null) {
      return [];
    }

    if (response is! List) {
      throw Exception(
        'Invalid NCR roles response.',
      );
    }

    return response
        .whereType<Map>()
        .map(
          (item) =>
          NcrRoleOption.fromMap(
            Map<String, dynamic>.from(
              item,
            ),
          ),
    )
        .toList();
  }

  // ============================================================
  // UPDATE NCR USER
  // ============================================================

  static Future<NcrAdminUser>
  updateUser({
    required String userId,
    required String fullName,
    required String email,
    required String roleId,
  }) async {
    final currentUser =
        NcrSession.currentUser;

    if (currentUser == null ||
        !NcrSession.isAdmin) {
      throw Exception(
        'Only an NCR Admin can update NCR users.',
      );
    }

    final response =
    await _supabase.rpc(
      'ncr_admin_update_user',
      params: {
        'p_admin_id': currentUser.id,
        'p_user_id': userId,
        'p_full_name':
        fullName.trim(),
        'p_email':
        email.trim().toLowerCase(),
        'p_role_id': roleId,
      },
    );

    if (response == null) {
      throw Exception(
        'NCR user could not be updated.',
      );
    }

    if (response is! Map) {
      throw Exception(
        'Invalid NCR user update response.',
      );
    }

    return NcrAdminUser.fromMap(
      Map<String, dynamic>.from(
        response,
      ),
    );
  }

  // ============================================================
  // ACTIVATE / DEACTIVATE NCR USER
  // ============================================================

  static Future<void>
  setUserActive({
    required String userId,
    required bool isActive,
  }) async {
    final currentUser =
        NcrSession.currentUser;

    if (currentUser == null ||
        !NcrSession.isAdmin) {
      throw Exception(
        'Only an NCR Admin can change NCR user status.',
      );
    }

    final response =
    await _supabase.rpc(
      'ncr_admin_set_user_active',
      params: {
        'p_admin_id': currentUser.id,
        'p_user_id': userId,
        'p_is_active': isActive,
      },
    );

    if (response == null) {
      throw Exception(
        'NCR user status could not be updated.',
      );
    }
  }

  // ============================================================
  // DELETE NCR USER
  // ============================================================

  static Future<void>
  deleteUser({
    required String userId,
  }) async {
    final currentUser =
        NcrSession.currentUser;

    if (currentUser == null ||
        !NcrSession.isAdmin) {
      throw Exception(
        'Only an NCR Admin can delete NCR users.',
      );
    }

    final response =
    await _supabase.rpc(
      'ncr_admin_delete_user',
      params: {
        'p_admin_id': currentUser.id,
        'p_user_id': userId,
      },
    );

    if (response == null) {
      throw Exception(
        'NCR user could not be deleted.',
      );
    }
  }

  // ============================================================
  // DELETE NCR RECORD
  // ============================================================

  static Future<void>
  deleteNcr({
    required String ncrId,
  }) async {
    final currentUser =
        NcrSession.currentUser;

    if (currentUser == null) {
      throw Exception(
        'NCR Admin session is required.',
      );
    }

    if (!NcrSession.isAdmin) {
      throw Exception(
        'Only an NCR Admin can delete NCR records.',
      );
    }

    final cleanNcrId =
    ncrId.trim();

    if (cleanNcrId.isEmpty) {
      throw Exception(
        'NCR ID is required.',
      );
    }

    try {
      final response =
      await _supabase.rpc(
        'ncr_admin_delete_ncr',
        params: {
          'p_user_id':
          currentUser.id,
          'p_ncr_id':
          cleanNcrId,
        },
      );

      if (response != true) {
        throw Exception(
          'NCR record could not be deleted.',
        );
      }
    } on PostgrestException catch (e) {
      throw Exception(
        e.message,
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to delete NCR record.',
      );
    }
  }
}