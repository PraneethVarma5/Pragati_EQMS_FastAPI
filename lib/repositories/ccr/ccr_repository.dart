import 'package:supabase_flutter/supabase_flutter.dart';

class CcrRepository {
  CcrRepository({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  // ============================================================
  // CCR LIST
  // ============================================================

  Future<List<Map<String, dynamic>>> getCcrCases() async {
    final response = await _client
        .from('ccr_cases')
        .select('''
          id,
          ccr_number,
          status,
          current_stage,
          complaint_date,
          complaint_source,
          customer_name,
          team_leader,
          group_name,
          customer_contact_name,
          customer_contact_position,
          customer_contact_company,
          customer_part_number,
supplier_part_number,
part_description,
part_no,
complaint_description,
qty,
problem_description,
customer_location,

          detected_date,
          detected_by,
          created_at,
          updated_at,
          ccr_statuses!fk_ccr_cases_status (
            status_name
          ),
          ccr_workflow_stages!fk_ccr_cases_stage (
            stage_name
          )
        ''')
        .order(
      'created_at',
      ascending: false,
    );

    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================================
  // CREATE NEW CCR
  // ============================================================

  Future<Map<String, dynamic>> createCcr() async {
    final response = await _client
        .from('ccr_cases')
        .insert({
      'status': 'draft',
      'current_stage': 'registration',
    })
        .select()
        .single();

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

    final response = await _client
        .from('ccr_cases')
        .select('''
      id,
      ccr_number,
      status,
      current_stage,
      complaint_date,
      complaint_source,
      customer_name,
      team_leader,
      group_name,
      customer_contact_name,
      customer_contact_position,
      customer_contact_company,
      customer_part_number,
      supplier_part_number,
      part_description,
      part_no,
      complaint_description,
      qty,
      problem_description,
      customer_location,
      detected_date,
      detected_by,
      created_at,
      updated_at,
      ccr_statuses!fk_ccr_cases_status (
        status_name
      ),
      ccr_workflow_stages!fk_ccr_cases_stage (
        stage_name
      )
    ''')
        .eq('id', cleanId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Map<String, dynamic>.from(response);
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

    final response = await _client
        .from('ccr_cases')
        .update({
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
    })
        .eq('id', cleanId)
        .select()
        .single();

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

    await _client
        .from('ccr_cases')
        .update({
      'current_stage': cleanStage,
    })
        .eq('id', cleanId);
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

    await _client
        .from('ccr_cases')
        .update({
      'status': cleanStatus,
    })
        .eq('id', cleanId);
  }

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