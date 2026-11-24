
import '../../models/ccr/ccr_corrective_action.dart';
import 'ccr_api_client.dart';

class CcrCorrectiveActionService {
  // ============================================================
  // LOAD CORRECTIVE ACTIONS
  // ============================================================

  Future<List<CcrCorrectiveAction>> getCorrectiveActions(
      String ccrId,
      ) async {
    final cleanCcrId = ccrId.trim();

    if (cleanCcrId.isEmpty) {
      throw Exception('CCR ID is missing.');
    }

    final response = await CcrApiClient.get(
      '/cases/$cleanCcrId/corrective-actions',
    );

    if (response is! List) {
      throw Exception(
        'Invalid response received while loading corrective actions.',
      );
    }

    final rows = response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();

    rows.sort((a, b) {
      final aDate = DateTime.tryParse(
        a['created_at']?.toString() ?? '',
      );

      final bDate = DateTime.tryParse(
        b['created_at']?.toString() ?? '',
      );

      if (aDate == null || bDate == null) {
        return 0;
      }

      return aDate.compareTo(bDate);
    });

    return rows
        .map(CcrCorrectiveAction.fromMap)
        .toList();
  }

  // ============================================================
  // CREATE ACTIONS FROM VALIDATED YES ROOT CAUSES
  //
  // One YES validation = one corrective action plan.
  //
  // Occurrence and Non-Detection analyses are paired using
  // validation_id.
  //
  // The LAST NON-EMPTY WHY becomes the root cause.
  // ============================================================

  Future<void> ensureActionsFromValidatedCauses(
      String ccrId,
      ) async {
    final cleanCcrId = ccrId.trim();

    if (cleanCcrId.isEmpty) {
      throw Exception('CCR ID is missing.');
    }

    // ----------------------------------------------------------
    // Load root-cause validations for this CCR.
    // ----------------------------------------------------------

    final validationResponse = await CcrApiClient.get(
      '/cases/$cleanCcrId/root-cause-validations',
    );

    if (validationResponse is! List) {
      throw Exception(
        'Invalid response received while loading root-cause validations.',
      );
    }

    final yesValidations = validationResponse
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .where((row) => row['relevance'] == true)
        .toList();

    if (yesValidations.isEmpty) {
      return;
    }

    // ----------------------------------------------------------
    // Load CCR problem statement.
    // ----------------------------------------------------------

    final caseResponse = await CcrApiClient.get(
      '/cases/$cleanCcrId',
    );

    if (caseResponse is! Map) {
      throw Exception(
        'Unable to load CCR details.',
      );
    }

    final caseData = Map<String, dynamic>.from(caseResponse);

    final problemStatement =
        caseData['problem_description']?.toString().trim() ?? '';

    // ----------------------------------------------------------
    // Load existing corrective actions.
    //
    // validation_id is the permanent relationship.
    // Do not compare root-cause text to identify duplicates.
    // ----------------------------------------------------------

    final existingResponse = await CcrApiClient.get(
      '/cases/$cleanCcrId/corrective-actions',
    );

    if (existingResponse is! List) {
      throw Exception(
        'Invalid response received while checking existing corrective actions.',
      );
    }

    final existing = existingResponse
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();

    // ----------------------------------------------------------
    // Collect relevant validation IDs.
    // ----------------------------------------------------------

    final validationIds = yesValidations
        .map((row) => row['id']?.toString())
        .whereType<String>()
        .where((id) => id.trim().isNotEmpty)
        .toSet();

    if (validationIds.isEmpty) {
      return;
    }

    // ----------------------------------------------------------
    // Load all 5-Why analyses for this CCR.
    //
    // The API response must include ccr_why_steps.
    // ----------------------------------------------------------

    final analysesResponse = await CcrApiClient.get(
      '/cases/$cleanCcrId/why-analyses',
    );

    if (analysesResponse is! List) {
      throw Exception(
        'Invalid response received while loading 5-Why analyses.',
      );
    }

    final analysisRows = analysesResponse
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();

    // ----------------------------------------------------------
// Create OR update one corrective-action row for every
// Yes validation.
//
// Existing rows must also be updated because their root-cause
// fields may have been empty when they were first created.
// ----------------------------------------------------------

    for (final validation in yesValidations) {
      final validationId = validation['id']?.toString();

      if (validationId == null || validationId.trim().isEmpty) {
        continue;
      }

      // Find an existing corrective-action row using validation_id.
      Map<String, dynamic>? existingAction;

      for (final row in existing) {
        if (row['validation_id']?.toString().trim() ==
            validationId.trim()) {
          existingAction = row;
          break;
        }
      }

      // Find Occurrence analysis.
      final occurrence = _findAnalysis(
        analysisRows,
        validationId,
        'occurrence',
      );

      // Find Non-Detection analysis.
      final detection = _findAnalysis(
        analysisRows,
        validationId,
        'non_detection',
      );

      // Extract the deepest non-empty Why from each analysis.
      final occurrenceRootCause =
      _rootCauseFromAnalysis(occurrence);

      final detectionRootCause =
      _rootCauseFromAnalysis(detection);

      // --------------------------------------------------------
      // UPDATE EXISTING CORRECTIVE ACTION
      // --------------------------------------------------------

      // Existing corrective-action records are retained.
// Root-cause values are derived by the GET endpoint,
// not written into nonexistent database columns.
      if (existingAction != null) {
        continue;
      }
      // --------------------------------------------------------
      // CREATE NEW CORRECTIVE ACTION
      // --------------------------------------------------------

      final inserted = await CcrApiClient.post(
        '/corrective-actions',
        body: {
          'data': {
            'ccr_id': cleanCcrId,
            'validation_id': validationId,
          },
        },
      );

      if (inserted is! Map) {
        throw Exception(
          'Corrective action could not be created for validation $validationId.',
        );
      }

      final insertedRow = Map<String, dynamic>.from(inserted);

      final actionId = insertedRow['id']?.toString();

      if (actionId == null || actionId.isEmpty) {
        throw Exception(
          'Corrective action was created without returning its ID.',
        );
      }

      // Track the new row to prevent duplicate creation.
      existing.add(insertedRow);
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
    final cleanValidationId = validationId.trim();
    final cleanType = analysisType.trim().toLowerCase();

    for (final row in rows) {
      final rowValidationId =
      row['validation_id']?.toString().trim();

      final rowType = row['analysis_type']
          ?.toString()
          .trim()
          .toLowerCase();

      if (rowValidationId == cleanValidationId &&
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
  // If there are no populated Why steps, use the
  // potential_root_cause as a fallback.
  // ============================================================

  String _rootCauseFromAnalysis(
      Map<String, dynamic>? analysis,
      ) {
    if (analysis == null) {
      return '';
    }

    final rawSteps = analysis['ccr_why_steps'];

    if (rawSteps is! List) {
      return analysis['potential_root_cause']
          ?.toString()
          .trim() ??
          '';
    }

    final steps = <Map<String, dynamic>>[];

    for (final raw in rawSteps) {
      if (raw is Map) {
        steps.add(Map<String, dynamic>.from(raw));
      }
    }

    // Sort Why steps numerically.
    steps.sort((a, b) {
      final aNumber = int.tryParse(
        a['why_number']?.toString() ?? '',
      ) ??
          0;

      final bNumber = int.tryParse(
        b['why_number']?.toString() ?? '',
      ) ??
          0;

      return aNumber.compareTo(bNumber);
    });

    // Keep replacing the root cause whenever a non-empty
    // Why is found. The final value is the deepest populated Why.
    String deepest = '';

    for (final step in steps) {
      final whyText = step['why_text']?.toString().trim() ?? '';

      if (whyText.isNotEmpty) {
        deepest = whyText;
      }
    }

    if (deepest.isNotEmpty) {
      return deepest;
    }

    return analysis['potential_root_cause']
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
      throw Exception('Corrective action ID is missing.');
    }

    await CcrApiClient.patch(
      '/corrective-actions/$cleanId',
      body: {
        'data': {
          'problem_statement': _nullable(problemStatement),
          'occurrence_root_cause':
          _nullable(occurrenceRootCause),
          'detection_root_cause':
          _nullable(detectionRootCause),
          'corrective_action': _nullable(correctiveAction),
          'dri': _nullable(dri),
          'result_before': _nullable(resultBefore),
          'result_after': _nullable(resultAfter),
          'due_date': dueDate?.toIso8601String().split('T').first,
          'completion_date':
          completionDate?.toIso8601String().split('T').first,
          'status': status.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      },
    );
  }

  // ============================================================
  // COMPLETE CORRECTIVE ACTION STAGE
  //
  // Verification is intentionally NOT checked here.
  // The backend handles workflow advancement.
  // ============================================================

  Future<void> completeStage(String ccrId) async {
    final cleanCcrId = ccrId.trim();

    if (cleanCcrId.isEmpty) {
      throw Exception('CCR ID is missing.');
    }

    // Reload actions from the API.
    final actions = await getCorrectiveActions(cleanCcrId);

    if (actions.isEmpty) {
      throw Exception(
        'No corrective actions are available.',
      );
    }

    // Validate only fields visible on the Corrective Action stage.
    for (final action in actions) {
      if (action.correctiveAction.trim().isEmpty) {
        throw Exception(
          'Corrective action is required for every action plan.',
        );
      }

      if (action.dri.trim().isEmpty) {
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

      if (action.resultBefore.trim().isEmpty) {
        throw Exception(
          'Result Before CA is required for every action plan.',
        );
      }

      if (action.resultAfter.trim().isEmpty) {
        throw Exception(
          'Result After CA is required for every action plan.',
        );
      }
    }

    // FastAPI validates and advances the workflow.
    await CcrApiClient.post(
      '/cases/$cleanCcrId/corrective-actions/complete',
    );
  }

  // ============================================================
  // NULLABLE STRING HELPER
  // ============================================================

  String? _nullable(String value) {
    final clean = value.trim();

    return clean.isEmpty ? null : clean;
  }
}
