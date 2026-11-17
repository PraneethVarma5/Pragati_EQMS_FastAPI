import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/ccr/ccr_corrective_action.dart';

class CcrCorrectiveActionService {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  // ============================================================
  // LOAD CORRECTIVE ACTIONS
  //
  // One corrective-action row represents one validated
  // root-cause validation.
  //
  // Verification is NOT part of the Corrective Action stage.
  // ============================================================

  Future<List<CcrCorrectiveAction>>
  getCorrectiveActions(
      String ccrId,
      ) async {
    final cleanCcrId = ccrId.trim();

    if (cleanCcrId.isEmpty) {
      throw Exception(
        'CCR ID is missing.',
      );
    }

    final response = await _supabase
        .from('ccr_corrective_actions')
        .select('*')
        .eq(
      'ccr_id',
      cleanCcrId,
    )
        .order(
      'created_at',
      ascending: true,
    );

    final rows =
    List<Map<String, dynamic>>.from(
      response,
    );

    return rows
        .map(
          (row) =>
          CcrCorrectiveAction.fromMap(
            row,
          ),
    )
        .toList();
  }

  // ============================================================
  // CREATE ACTIONS FROM VALIDATED YES ROOT CAUSES
  //
  // IMPORTANT:
  //
  // One YES validation = one corrective action plan.
  //
  // Occurrence and Non-Detection 5-Why analyses are paired
  // using validation_id.
  //
  // The root cause is the LAST NON-EMPTY WHY.
  //
  // Therefore:
  //
  // Why 3 final value -> root cause
  // Why 4 final value -> root cause
  // Why 5 final value -> root cause
  //
  // It is NOT assumed that Why 5 must always be used.
  // ============================================================

  Future<void> ensureActionsFromValidatedCauses(
      String ccrId,
      ) async {
    final cleanCcrId = ccrId.trim();

    if (cleanCcrId.isEmpty) {
      throw Exception(
        'CCR ID is missing.',
      );
    }

    // ----------------------------------------------------------
    // Get all validations belonging to this CCR.
    // ----------------------------------------------------------

    final validationsResponse =
    await _supabase
        .from(
      'ccr_root_cause_validations',
    )
        .select('''
              id,
              fishbone_cause_id,
              validation_text,
              relevance,
              ccr_fishbone_causes!ccr_root_cause_validations_fishbone_cause_id_fkey(
                id,
                ccr_id,
                cause_text,
                ccr_fishbone_categories(
                  id,
                  name
                )
              )
            ''')
        .eq(
      'relevance',
      true,
    );

    final validations =
    List<Map<String, dynamic>>.from(
      validationsResponse,
    );

    // ----------------------------------------------------------
    // Keep only validations whose fishbone cause belongs to
    // the current CCR.
    // ----------------------------------------------------------

    final yesValidations =
    validations.where(
          (row) {
        final cause =
        row['ccr_fishbone_causes'];

        if (cause is! Map) {
          return false;
        }

        return cause['ccr_id']?.toString() ==
            cleanCcrId;
      },
    ).toList();

    if (yesValidations.isEmpty) {
      return;
    }

    // ----------------------------------------------------------
    // Problem statement comes from CCR registration.
    // ----------------------------------------------------------

    final ccrResponse = await _supabase
        .from('ccr_cases')
        .select('problem_description')
        .eq(
      'id',
      cleanCcrId,
    )
        .single();

    final problemStatement =
        ccrResponse['problem_description']
            ?.toString()
            .trim() ??
            '';

    // ----------------------------------------------------------
    // Existing corrective actions.
    //
    // validation_id is the permanent relationship.
    //
    // DO NOT compare root-cause text because two separate
    // validations may have identical text and still require
    // separate corrective-action rows.
    // ----------------------------------------------------------

    final existingResponse =
    await _supabase
        .from(
      'ccr_corrective_actions',
    )
        .select(
      'id, ccr_id, validation_id',
    )
        .eq(
      'ccr_id',
      cleanCcrId,
    );

    final existing =
    List<Map<String, dynamic>>.from(
      existingResponse,
    );

    // ----------------------------------------------------------
    // Get validation IDs.
    // ----------------------------------------------------------

    final validationIds =
    yesValidations
        .map(
          (row) =>
          row['id']?.toString(),
    )
        .whereType<String>()
        .where(
          (id) => id.isNotEmpty,
    )
        .toList();

    if (validationIds.isEmpty) {
      return;
    }

    // ----------------------------------------------------------
    // Get all 5-Why analyses for those validations.
    // ----------------------------------------------------------

    final analysesResponse =
    await _supabase
        .from(
      'ccr_why_analyses',
    )
        .select('''
              id,
              validation_id,
              analysis_type,
              potential_root_cause,
              ccr_why_steps(
                why_number,
                why_text
              )
            ''')
        .inFilter(
      'validation_id',
      validationIds,
    );

    final analysisRows =
    List<Map<String, dynamic>>.from(
      analysesResponse,
    );

    // ----------------------------------------------------------
    // Create one CA row for EVERY YES validation.
    // ----------------------------------------------------------

    for (final validation
    in yesValidations) {
      final validationId =
      validation['id']?.toString();

      if (validationId == null ||
          validationId.isEmpty) {
        continue;
      }

      // --------------------------------------------------------
      // Find Occurrence 5-Why for this validation.
      // --------------------------------------------------------

      final occurrence =
      _findAnalysis(
        analysisRows,
        validationId,
        'occurrence',
      );

      // --------------------------------------------------------
      // Find Non-Detection 5-Why for this validation.
      // --------------------------------------------------------

      final detection =
      _findAnalysis(
        analysisRows,
        validationId,
        'non_detection',
      );

      // --------------------------------------------------------
      // LAST NON-EMPTY WHY becomes root cause.
      // --------------------------------------------------------

      final occurrenceRootCause =
      _rootCauseFromAnalysis(
        occurrence,
      );

      final detectionRootCause =
      _rootCauseFromAnalysis(
        detection,
      );

      // --------------------------------------------------------
      // Check duplicate using validation_id.
      // --------------------------------------------------------

      final alreadyExists =
      existing.any(
            (row) =>
        row['validation_id']
            ?.toString()
            .trim() ==
            validationId,
      );

      if (alreadyExists) {
        continue;
      }

      // --------------------------------------------------------
      // Create corrective action.
      // --------------------------------------------------------

      final inserted = await _supabase
          .from(
        'ccr_corrective_actions',
      )
          .insert({
        'ccr_id':
        cleanCcrId,

        'validation_id':
        validationId,

        'problem_statement':
        problemStatement.isEmpty
            ? null
            : problemStatement,

        'occurrence_root_cause':
        occurrenceRootCause.isEmpty
            ? null
            : occurrenceRootCause,

        'detection_root_cause':
        detectionRootCause.isEmpty
            ? null
            : detectionRootCause,
      })
          .select('id')
          .single();

      final actionId =
      inserted['id']?.toString();

      if (actionId == null ||
          actionId.isEmpty) {
        throw Exception(
          'Corrective action could not be created.',
        );
      }

      // --------------------------------------------------------
      // DO NOT CREATE A VERIFICATION RECORD HERE.
      //
      // Verification is no longer part of this stage.
      // --------------------------------------------------------
    }
  }

  // ============================================================
  // FIND ANALYSIS
  // ============================================================

  Map<String, dynamic>? _findAnalysis(
      List<Map<String, dynamic>> rows,
      String validationId,
      String analysisType,
      ) {
    final cleanValidationId =
    validationId.trim();

    final cleanType =
    analysisType.trim().toLowerCase();

    for (final row in rows) {
      final rowValidationId =
      row['validation_id']
          ?.toString()
          .trim();

      final rowType =
      row['analysis_type']
          ?.toString()
          .trim()
          .toLowerCase();

      if (rowValidationId ==
          cleanValidationId &&
          rowType == cleanType) {
        return row;
      }
    }

    return null;
  }

  // ============================================================
  // ROOT CAUSE
  //
  // The LAST NON-EMPTY WHY becomes the root cause.
  //
  // Example:
  //
  // Why 1 = A
  // Why 2 = B
  // Why 3 = C
  // Why 4 = empty
  // Why 5 = empty
  //
  // Root cause = C
  //
  // Likewise, if Why 5 is populated, Why 5 becomes the root
  // cause.
  // ============================================================

  String _rootCauseFromAnalysis(
      Map<String, dynamic>? analysis,
      ) {
    if (analysis == null) {
      return '';
    }

    final rawSteps =
    analysis['ccr_why_steps'];

    if (rawSteps is! List) {
      return analysis[
      'potential_root_cause']
          ?.toString()
          .trim() ??
          '';
    }

    final steps =
    <Map<String, dynamic>>[];

    for (final raw in rawSteps) {
      if (raw is Map) {
        steps.add(
          Map<String, dynamic>.from(
            raw,
          ),
        );
      }
    }

    // ----------------------------------------------------------
    // Sort Why steps numerically.
    // ----------------------------------------------------------

    steps.sort(
          (a, b) {
        final aNumber =
            int.tryParse(
              a['why_number']
                  ?.toString() ??
                  '',
            ) ??
                0;

        final bNumber =
            int.tryParse(
              b['why_number']
                  ?.toString() ??
                  '',
            ) ??
                0;

        return aNumber.compareTo(
          bNumber,
        );
      },
    );

    // ----------------------------------------------------------
    // Keep replacing deepest whenever a non-empty Why is found.
    //
    // Therefore the final value is always the LAST non-empty
    // Why.
    // ----------------------------------------------------------

    String deepest = '';

    for (final step in steps) {
      final text =
          step['why_text']
              ?.toString()
              .trim() ??
              '';

      if (text.isNotEmpty) {
        deepest = text;
      }
    }

    if (deepest.isNotEmpty) {
      return deepest;
    }

    // ----------------------------------------------------------
    // Fallback.
    // ----------------------------------------------------------

    return analysis[
    'potential_root_cause']
        ?.toString()
        .trim() ??
        '';
  }

  // ============================================================
  // SAVE CORRECTIVE ACTION
  // ============================================================

  Future<void> saveCorrectiveAction({
    required String actionId,
    required String problemStatement,
    required String occurrenceRootCause,
    required String detectionRootCause,
    required String correctiveAction,
    required String dri,
    required String resultBefore,
    required String resultAfter,
    DateTime? dueDate,
    DateTime? completionDate,
    required String status,
  }) async {
    final cleanId = actionId.trim();

    if (cleanId.isEmpty) {
      throw Exception(
        'Corrective action ID is missing.',
      );
    }

    await _supabase
        .from(
      'ccr_corrective_actions',
    )
        .update({
      'problem_statement':
      _nullable(
        problemStatement,
      ),

      // These two values originate from the final
      // 5-Why values and are therefore kept in the CA
      // record for reporting/history.
      'occurrence_root_cause':
      _nullable(
        occurrenceRootCause,
      ),

      'detection_root_cause':
      _nullable(
        detectionRootCause,
      ),

      'corrective_action':
      _nullable(
        correctiveAction,
      ),

      'dri':
      _nullable(
        dri,
      ),

      'result_before':
      _nullable(
        resultBefore,
      ),

      'result_after':
      _nullable(
        resultAfter,
      ),

      'due_date':
      dueDate
          ?.toIso8601String()
          .split('T')
          .first,

      'completion_date':
      completionDate
          ?.toIso8601String()
          .split('T')
          .first,

      'status':
      status.trim(),

      'updated_at':
      DateTime.now()
          .toIso8601String(),
    })
        .eq(
      'id',
      cleanId,
    );
  }

  // ============================================================
  // COMPLETE CA STAGE
  //
  // Verification is intentionally NOT checked here.
  //
  // The CA stage validates only the fields visible on the CA
  // screen and then advances exactly one configured workflow
  // stage using ccr_workflow_stages.display_order.
  // ============================================================

  Future<void> completeStage(
      String ccrId,
      ) async {
    final cleanCcrId = ccrId.trim();

    if (cleanCcrId.isEmpty) {
      throw Exception(
        'CCR ID is missing.',
      );
    }

    // ----------------------------------------------------------
    // Reload actions from DB.
    // ----------------------------------------------------------

    final actions =
    await getCorrectiveActions(
      cleanCcrId,
    );

    if (actions.isEmpty) {
      throw Exception(
        'No corrective actions are available.',
      );
    }

    // ----------------------------------------------------------
    // Validate CA fields only.
    //
    // NO verification lookup.
    // ----------------------------------------------------------

    for (final action in actions) {
      if (action.correctiveAction
          .trim()
          .isEmpty) {
        throw Exception(
          'Corrective action is required for every action plan.',
        );
      }

      if (action.dri
          .trim()
          .isEmpty) {
        throw Exception(
          'DRI is required for every action plan.',
        );
      }

      if (action.dueDate == null) {
        throw Exception(
          'Due Date is required for every action plan.',
        );
      }

      if (action.completionDate == null) {
        throw Exception(
          'Completion Date is required for every action plan.',
        );
      }

      if (action.resultBefore
          .trim()
          .isEmpty) {
        throw Exception(
          'Result Before CA is required for every action plan.',
        );
      }

      if (action.resultAfter
          .trim()
          .isEmpty) {
        throw Exception(
          'Result After CA is required for every action plan.',
        );
      }
    }

    // ----------------------------------------------------------
    // Read current CCR stage.
    // ----------------------------------------------------------

    final currentCase =
    await _supabase
        .from('ccr_cases')
        .select(
      'current_stage',
    )
        .eq(
      'id',
      cleanCcrId,
    )
        .single();

    final currentStage =
    currentCase['current_stage']
        ?.toString()
        .trim();

    if (currentStage == null ||
        currentStage.isEmpty) {
      throw Exception(
        'Current workflow stage is missing.',
      );
    }

    // ----------------------------------------------------------
    // Get current stage display order from DB.
    // ----------------------------------------------------------

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
        .maybeSingle();

    if (currentStageRow == null) {
      throw Exception(
        'Current workflow stage "$currentStage" is not configured.',
      );
    }

    final rawOrder =
    currentStageRow['display_order'];

    final currentOrder =
    rawOrder is num
        ? rawOrder.toInt()
        : int.tryParse(
      rawOrder?.toString() ??
          '',
    ) ??
        0;

    // ----------------------------------------------------------
    // Find the NEXT active workflow stage.
    //
    // The sequence is NOT hardcoded.
    // ----------------------------------------------------------

    final nextStage =
    await _supabase
        .from(
      'ccr_workflow_stages',
    )
        .select(
      'stage_key, stage_name, display_order',
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

    final nextKey =
    nextStage['stage_key']
        ?.toString()
        .trim();

    if (nextKey == null ||
        nextKey.isEmpty) {
      throw Exception(
        'Next workflow stage is missing.',
      );
    }

    // ----------------------------------------------------------
    // Move CCR forward exactly one stage.
    //
    // Optimistic condition prevents another process from
    // changing the workflow underneath us.
    // ----------------------------------------------------------

    final updated =
    await _supabase
        .from('ccr_cases')
        .update({
      'current_stage':
      nextKey,
      'updated_at':
      DateTime.now()
          .toIso8601String(),
    })
        .eq(
      'id',
      cleanCcrId,
    )
        .eq(
      'current_stage',
      currentStage,
    )
        .select('id');

    if (updated.isEmpty) {
      throw Exception(
        'CCR workflow stage changed during completion. Reload the CCR.',
      );
    }
  }

  // ============================================================
  // NULLABLE STRING HELPER
  // ============================================================

  String? _nullable(
      String value,
      ) {
    final clean = value.trim();

    return clean.isEmpty
        ? null
        : clean;
  }
}