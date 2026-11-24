
import '../../models/ccr/ccr_assignment.dart';
import 'ccr_api_client.dart';

class CcrAssignmentService {
  // ============================================================
  // LOAD ASSIGNMENTS
  // ============================================================

  Future<List<CcrAssignment>> getAssignments(
      String ccrId,
      ) async {
    final cleanId = ccrId.trim();

    if (cleanId.isEmpty) {
      throw Exception('CCR ID is required.');
    }

    final response = await CcrApiClient.get(
      '/cases/$cleanId/assignments',
    );

    if (response is! List) {
      throw Exception(
        'Invalid response received while loading CCR assignments.',
      );
    }

    return response
        .whereType<Map>()
        .map(
          (item) => CcrAssignment.fromMap(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }

  // ============================================================
  // CREATE ASSIGNMENT
  // ============================================================

  Future<CcrAssignment> createAssignment({
    required String ccrId,
    String? activity,
    String? dri,
    DateTime? dueDate,
    DateTime? doneDate,
    String? statusKey,
    String? remarks,
  }) async {
    final cleanCcrId = ccrId.trim();

    if (cleanCcrId.isEmpty) {
      throw Exception('CCR ID is required.');
    }

    final response = await CcrApiClient.post(
      '/assignments',
      body: {
        'data': {
          'ccr_id': cleanCcrId,
          'activity': _nullable(activity),
          'dri': _nullable(dri),
          'due_date': dueDate == null
              ? null
              : _dateOnly(dueDate),
          'done_date': doneDate == null
              ? null
              : _dateOnly(doneDate),
          'status': statusKey == null || statusKey.trim().isEmpty
              ? 'pending'
              : statusKey.trim(),
          'remarks': _nullable(remarks),
        },
      },
    );

    if (response is! Map) {
      throw Exception(
        'Invalid response received while creating assignment.',
      );
    }

    return CcrAssignment.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  // ============================================================
  // UPDATE ASSIGNMENT
  // ============================================================

  Future<CcrAssignment> updateAssignment({
    required String id,
    String? activity,
    String? dri,
    DateTime? dueDate,
    DateTime? doneDate,
    String? statusKey,
    String? remarks,
  }) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      throw Exception('Assignment ID is required.');
    }

    final data = <String, dynamic>{
      'activity': _nullable(activity),
      'dri': _nullable(dri),
      'due_date': dueDate == null
          ? null
          : _dateOnly(dueDate),
      'done_date': doneDate == null
          ? null
          : _dateOnly(doneDate),
      'remarks': _nullable(remarks),
    };

    if (statusKey != null && statusKey.trim().isNotEmpty) {
      data['status'] = statusKey.trim();
    }

    final response = await CcrApiClient.patch(
      '/assignments/$cleanId',
      body: {
        'data': data,
      },
    );

    if (response is! Map) {
      throw Exception(
        'Invalid response received while updating assignment.',
      );
    }

    return CcrAssignment.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  // ============================================================
  // DELETE ASSIGNMENT
  // ============================================================

  Future<void> deleteAssignment(
      String id,
      ) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      throw Exception('Assignment ID is required.');
    }

    await CcrApiClient.delete(
      '/assignments/$cleanId',
    );
  }

  // ============================================================
  // COMPLETE WORKFLOW STAGE
  // ============================================================

  Future<void> completeAssignment(
      String ccrId,
      ) async {
    final cleanId = ccrId.trim();

    if (cleanId.isEmpty) {
      throw Exception('CCR ID is required.');
    }

    await CcrApiClient.post(
      '/cases/$cleanId/assignments/complete',
    );
  }
  // ============================================================
// GET CURRENT WORKFLOW STAGE
// ============================================================

  Future<String> getCurrentStage(String ccrId) async {
    final cleanId = ccrId.trim();

    if (cleanId.isEmpty) {
      throw Exception('CCR ID is required.');
    }

    final response = await CcrApiClient.get(
      '/cases/$cleanId',
    );

    if (response is! Map) {
      throw Exception(
        'Invalid response received while loading the CCR workflow stage.',
      );
    }

    final caseData = response['case'] ??
        response['data'] ??
        response;

    if (caseData is! Map) {
      throw Exception(
        'CCR case details could not be determined.',
      );
    }

    final stage = caseData['current_stage']
        ?.toString()
        .trim()
        .toLowerCase();

    if (stage == null || stage.isEmpty) {
      throw Exception(
        'The current CCR workflow stage was not returned by the server.',
      );
    }

    return stage;
  }

  // ============================================================
  // STRING HELPER
  // ============================================================

  String? _nullable(String? value) {
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  // ============================================================
  // DATE HELPER
  // ============================================================

  String _dateOnly(DateTime value) {
    final year = value.year.toString();
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
