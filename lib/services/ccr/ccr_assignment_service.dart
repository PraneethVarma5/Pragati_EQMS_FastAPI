import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/ccr/ccr_assignment.dart';

class CcrAssignmentService {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  // ============================================================
  // LOAD ASSIGNMENTS
  // ============================================================

  Future<List<CcrAssignment>> getAssignments(
      String ccrId,
      ) async {
    final response =
    await _supabase
        .from('ccr_assignments')
        .select('''
              *,
              ccr_assignment_statuses!fk_ccr_assignments_status(
                status_name
              )
            ''')
        .eq(
      'ccr_id',
      ccrId,
    )
        .order(
      'created_at',
      ascending: true,
    );

    return List<Map<String, dynamic>>
        .from(response)
        .map(
      CcrAssignment.fromMap,
    )
        .toList();
  }

  // ============================================================
  // CREATE ASSIGNMENT
  //
  // Status is intentionally omitted.
  // The database default supplies the initial status.
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
    final response = await _supabase
        .from('ccr_assignments')
        .insert({
      'ccr_id': ccrId,
      'activity': _nullable(activity),
      'dri': _nullable(dri),
      'due_date': dueDate == null
          ? null
          : _dateOnly(dueDate),
      'done_date': doneDate == null
          ? null
          : _dateOnly(doneDate),
      'status': statusKey ?? 'pending',
      'remarks': _nullable(remarks),
    })
        .select('''
        *,
        ccr_assignment_statuses!fk_ccr_assignments_status(
          status_name
        )
      ''')
        .single();

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
    final data =
    <String, dynamic>{
      'activity':
      _nullable(activity),
      'dri':
      _nullable(dri),
      'due_date':
      dueDate == null
          ? null
          : _dateOnly(
        dueDate,
      ),
      'done_date':
      doneDate == null
          ? null
          : _dateOnly(
        doneDate,
      ),
      'remarks':
      _nullable(remarks),
      'updated_at':
      DateTime.now()
          .toIso8601String(),
    };

    if (statusKey != null &&
        statusKey.trim().isNotEmpty) {
      data['status'] =
          statusKey.trim();
    }

    final response =
    await _supabase
        .from('ccr_assignments')
        .update(data)
        .eq(
      'id',
      id,
    )
        .select('''
              *,
              ccr_assignment_statuses!fk_ccr_assignments_status(
                status_name
              )
            ''')
        .single();

    return CcrAssignment.fromMap(
      Map<String, dynamic>.from(
        response,
      ),
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteAssignment(
      String id,
      ) async {
    await _supabase
        .from('ccr_assignments')
        .delete()
        .eq(
      'id',
      id,
    );
  }

  // ============================================================
  // COMPLETE WORKFLOW STAGE
  //
  // The next stage is obtained from the workflow master.
  // No workflow stage key is hardcoded.
  // ============================================================

  Future<void> completeAssignment(
      String ccrId,
      ) async {
    final current =
    await _supabase
        .from('ccr_cases')
        .select(
      'current_stage',
    )
        .eq(
      'id',
      ccrId,
    )
        .single();

    final currentStage =
    current['current_stage']
        ?.toString()
        .trim();

    if (currentStage == null ||
        currentStage.isEmpty) {
      throw Exception(
        'Current CCR workflow stage is missing.',
      );
    }

    final currentStageRow =
    await _supabase
        .from(
      'ccr_workflow_stages',
    )
        .select(
      'display_order',
    )
        .eq(
      'stage_key',
      currentStage,
    )
        .single();

    final orderValue =
    currentStageRow[
    'display_order'];

    final currentOrder =
    orderValue is num
        ? orderValue.toInt()
        : int.tryParse(
      orderValue
          .toString(),
    ) ??
        0;

    final nextStage =
    await _supabase
        .from(
      'ccr_workflow_stages',
    )
        .select(
      'stage_key',
    )
        .eq(
      'is_active',
      true,
    )
        .gt(
      'display_order',
      currentOrder,
    )
        .order(
      'display_order',
      ascending: true,
    )
        .limit(1)
        .maybeSingle();

    if (nextStage == null) {
      throw Exception(
        'No next active CCR workflow stage is configured.',
      );
    }

    final nextStageKey =
    nextStage['stage_key']
        ?.toString()
        .trim();

    if (nextStageKey == null ||
        nextStageKey.isEmpty) {
      throw Exception(
        'Next CCR workflow stage is missing.',
      );
    }

    await _supabase
        .from('ccr_cases')
        .update({
      'current_stage':
      nextStageKey,
      'updated_at':
      DateTime.now()
          .toIso8601String(),
    })
        .eq(
      'id',
      ccrId,
    )
        .eq(
      'current_stage',
      currentStage,
    );
  }

  String? _nullable(
      String? value,
      ) {
    final trimmed =
    value?.trim();

    if (trimmed == null ||
        trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  String _dateOnly(
      DateTime value,
      ) {
    final year =
    value.year.toString();

    final month =
    value.month
        .toString()
        .padLeft(2, '0');

    final day =
    value.day
        .toString()
        .padLeft(2, '0');

    return '$year-$month-$day';
  }
}