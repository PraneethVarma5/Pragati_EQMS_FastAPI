
import '../../services/ccr/ccr_api_client.dart';

class CcrRepository {
  CcrRepository();

  // ============================================================
  // CCR LIST
  // ============================================================

  Future<List<Map<String, dynamic>>> getCcrCases() async {
    final response = await CcrApiClient.get('/cases');

    if (response is! List) {
      throw Exception(
        'Invalid response received while loading CCR cases.',
      );
    }

    return response
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
    )
        .toList();
  }

  // ============================================================
  // CREATE NEW CCR
  // ============================================================

  Future<Map<String, dynamic>> createCcr() async {
    final response = await CcrApiClient.post(
      '/cases',
      body: {
        'data': {
          'status': 'draft',
          'current_stage': 'registration',
        },
      },
    );

    if (response is! Map) {
      throw Exception(
        'Invalid response received while creating CCR.',
      );
    }

    return Map<String, dynamic>.from(response);
  }

  // ============================================================
  // GET ONE CCR
  // ============================================================

  Future<Map<String, dynamic>?> getCcrById(
      String ccrId,
      ) async {
    final cleanId = ccrId.trim();

    if (cleanId.isEmpty) {
      return null;
    }

    try {
      final response = await CcrApiClient.get(
        '/cases/$cleanId',
      );

      if (response is! Map) {
        return null;
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      // Supabase maybeSingle() previously returned null when
      // the requested case did not exist. Preserve that behavior.
      if (e.toString().contains('CCR case not found')) {
        return null;
      }

      rethrow;
    }
  }

  // ============================================================
  // UPDATE REGISTRATION
  // ============================================================

  Future<Map<String, dynamic>> updateRegistration({
    required String ccrId,
    DateTime? complaintDate,
    String? complaintSource,
    String? customerName,
    String? teamLeader,
    String? groupName,
    String? customerContactName,
    String? customerContactPosition,
    String? customerContactCompany,
    String? customerPartNumber,
    String? supplierPartNumber,
    String? problemDescription,
    String? customerLocation,
    DateTime? detectedDate,
    String? detectedBy,
  }) async {
    final cleanId = ccrId.trim();

    if (cleanId.isEmpty) {
      throw Exception('CCR ID is missing.');
    }

    final response = await CcrApiClient.patch(
      '/cases/$cleanId',
      body: {
        'data': {
          'complaint_date':
          complaintDate?.toIso8601String().split('T').first,
          'complaint_source': _cleanNullable(complaintSource),
          'customer_name': _cleanNullable(customerName),
          'team_leader': _cleanNullable(teamLeader),
          'group_name': _cleanNullable(groupName),
          'customer_contact_name':
          _cleanNullable(customerContactName),
          'customer_contact_position':
          _cleanNullable(customerContactPosition),
          'customer_contact_company':
          _cleanNullable(customerContactCompany),
          'customer_part_number':
          _cleanNullable(customerPartNumber),
          'supplier_part_number':
          _cleanNullable(supplierPartNumber),
          'problem_description':
          _cleanNullable(problemDescription),
          'customer_location':
          _cleanNullable(customerLocation),
          'detected_date':
          detectedDate?.toIso8601String().split('T').first,
          'detected_by': _cleanNullable(detectedBy),
        },
      },
    );

    if (response is! Map) {
      throw Exception(
        'Invalid response received while updating CCR registration.',
      );
    }

    return Map<String, dynamic>.from(response);
  }

  // ============================================================
  // SAVE / UPDATE CURRENT STAGE
  // ============================================================

  Future<void> updateCurrentStage({
    required String ccrId,
    required String stageKey,
  }) async {
    final cleanId = ccrId.trim();
    final cleanStage = stageKey.trim();

    if (cleanId.isEmpty) {
      throw Exception('CCR ID is missing.');
    }

    if (cleanStage.isEmpty) {
      throw Exception('CCR stage is missing.');
    }

    await CcrApiClient.patch(
      '/cases/$cleanId/stage',
      query: {
        'stage_key': cleanStage,
      },
    );
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> updateStatus({
    required String ccrId,
    required String statusKey,
  }) async {
    final cleanId = ccrId.trim();
    final cleanStatus = statusKey.trim();

    if (cleanId.isEmpty) {
      throw Exception('CCR ID is missing.');
    }

    if (cleanStatus.isEmpty) {
      throw Exception('CCR status is missing.');
    }

    await CcrApiClient.patch(
      '/cases/$cleanId/status',
      query: {
        'status_key': cleanStatus,
      },
    );
  }

  // ============================================================
  // STRING HELPER
  // ============================================================

  String? _cleanNullable(String? value) {
    if (value == null) {
      return null;
    }

    final cleaned = value.trim();

    if (cleaned.isEmpty) {
      return null;
    }

    return cleaned;
  }
}
