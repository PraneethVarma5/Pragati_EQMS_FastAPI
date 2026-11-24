
import '../../models/ccr/ccr_why_analysis.dart';
import 'ccr_api_client.dart';

class CcrWhyService {
  // ============================================================
  // LOAD ALL 5-WHY ANALYSES FOR A CCR
  //
  // Only root-cause validations marked relevance = true
  // participate in the 5-Why stage.
  //
  // Each relevant validation must have:
  //   1. occurrence
  //   2. non_detection
  //
  // Missing analysis records are created automatically.
  // ============================================================

  Future<List<CcrWhyAnalysis>> getAnalyses(
      String ccrId,
      ) async {
    final cleanCcrId = ccrId.trim();

    if (cleanCcrId.isEmpty) {
      throw Exception('CCR ID is missing.');
    }

    // Load root-cause validations for this CCR.
    final validationResponse = await CcrApiClient.get(
      '/cases/$cleanCcrId/root-cause-validations',
    );

    if (validationResponse is! List) {
      throw Exception(
        'Invalid response received while loading root-cause validations.',
      );
    }

    final validations = validationResponse
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((row) => row['relevance'] == true)
        .toList();

    if (validations.isEmpty) {
      return [];
    }

    // Load existing 5-Why analyses.
    final analysisResponse = await CcrApiClient.get(
      '/cases/$cleanCcrId/why-analyses',
    );

    if (analysisResponse is! List) {
      throw Exception(
        'Invalid response received while loading 5-Why analyses.',
      );
    }

    final analyses = analysisResponse
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    // Ensure both analysis types exist for every relevant
    // root-cause validation.
    for (final validation in validations) {
      final validationId =
          validation['id']?.toString() ?? '';

      if (validationId.isEmpty) {
        continue;
      }

      final cause = _extractCause(validation);

      final causeText =
          cause['cause_text']?.toString() ?? '';

      for (final type in [
        'occurrence',
        'non_detection',
      ]) {
        final existing = analyses.where((analysis) {
          return analysis['validation_id']?.toString() ==
              validationId &&
              analysis['analysis_type']
                  ?.toString()
                  .trim()
                  .toLowerCase() ==
                  type;
        }).toList();

        if (existing.isNotEmpty) {
          continue;
        }

        final inserted = await CcrApiClient.post(
          '/why-analyses',
          body: {
            'data': {
              'validation_id': validationId,
              'analysis_type': type,
              'potential_root_cause': causeText,
            },
          },
        );

        if (inserted is! Map) {
          throw Exception(
            'Invalid response received while creating $type analysis.',
          );
        }

        analyses.add(
          Map<String, dynamic>.from(inserted),
        );
      }
    }

    // Enrich the analysis response with the nested relationships
    // expected by CcrWhyAnalysis.fromMap().
    final result = <CcrWhyAnalysis>[];

    for (final analysis in analyses) {
      final validationId =
          analysis['validation_id']?.toString() ?? '';

      final matchingValidations = validations.where(
            (validation) =>
        validation['id']?.toString() == validationId,
      );

      if (matchingValidations.isEmpty) {
        continue;
      }

      final validation = matchingValidations.first;

      final cause = _extractCause(validation);

      final enrichedValidation =
      Map<String, dynamic>.from(validation);

      enrichedValidation['ccr_fishbone_causes'] = cause;

      final enrichedAnalysis =
      Map<String, dynamic>.from(analysis);

      enrichedAnalysis['ccr_root_cause_validations'] =
          enrichedValidation;

      enrichedAnalysis['ccr_why_steps'] ??= [];

      result.add(
        CcrWhyAnalysis.fromMap(enrichedAnalysis),
      );
    }

    result.sort((a, b) {
      final categoryCompare =
      a.categoryName.compareTo(b.categoryName);

      if (categoryCompare != 0) {
        return categoryCompare;
      }

      return a.analysisType.compareTo(b.analysisType);
    });

    return result;
  }

  // ============================================================
  // SAVE POTENTIAL ROOT CAUSE
  // ============================================================

  Future<void> savePotentialRootCause({
    required String analysisId,
    required String potentialRootCause,
  }) async {
    final cleanId = analysisId.trim();

    if (cleanId.isEmpty) {
      throw Exception('5-Why analysis ID is missing.');
    }

    await CcrApiClient.patch(
      '/why-analyses/$cleanId',
      body: {
        'data': {
          'potential_root_cause':
          potentialRootCause.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      },
    );
  }

  // ============================================================
  // SAVE ONE WHY STEP
  //
  // IMPORTANT:
  // The backend POST /why-steps endpoint must implement
  // UPSERT using the unique key:
  // analysis_id + why_number.
  // ============================================================

  Future<CcrWhyStep> saveStep({
    required String analysisId,
    required int whyNumber,
    required String whyText,
    required String verificationText,
    required bool? evidenceAvailable,
  }) async {
    final cleanAnalysisId = analysisId.trim();

    if (cleanAnalysisId.isEmpty) {
      throw Exception('5-Why analysis ID is missing.');
    }

    if (whyNumber < 1 || whyNumber > 5) {
      throw Exception(
        'Why number must be between 1 and 5.',
      );
    }

    final response = await CcrApiClient.post(
      '/why-steps',
      body: {
        'data': {
          'analysis_id': cleanAnalysisId,
          'why_number': whyNumber,
          'why_text': whyText.trim(),
          'verification_text': verificationText.trim(),
          'evidence_available': evidenceAvailable,
          'updated_at': DateTime.now().toIso8601String(),
        },
      },
    );

    if (response is! Map) {
      throw Exception(
        'Invalid response received while saving Why step.',
      );
    }

    return CcrWhyStep.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  // ============================================================
  // DELETE WHY STEP
  // ============================================================

  Future<void> deleteStep(String stepId) async {
    final cleanId = stepId.trim();

    if (cleanId.isEmpty) {
      return;
    }

    await CcrApiClient.delete(
      '/why-steps/$cleanId',
    );
  }

  // ============================================================
  // COMPLETE 5-WHY STAGE
  //
  // Every analysis must have:
  //   1. Potential root cause
  //   2. At least one completed Why
  //
  // Users are allowed to stop before Why 5.
  // ============================================================

  Future<void> completeWhyStage(String ccrId) async {
    final cleanCcrId = ccrId.trim();

    if (cleanCcrId.isEmpty) {
      throw Exception('CCR ID is missing.');
    }

    final analyses = await getAnalyses(cleanCcrId);

    if (analyses.isEmpty) {
      throw Exception(
        'No Yes root causes are available for 5-Why analysis.',
      );
    }

    for (final analysis in analyses) {
      if (analysis.potentialRootCause.trim().isEmpty) {
        throw Exception(
          'Potential root cause is required for every 5-Why analysis.',
        );
      }

      final hasAtLeastOneWhy = analysis.steps.any(
            (step) => step.whyText.trim().isNotEmpty,
      );

      if (!hasAtLeastOneWhy) {
        throw Exception(
          'At least one Why is required for ${analysis.analysisTitle}.',
        );
      }
    }

    // FastAPI handles workflow advancement.
    await CcrApiClient.post(
      '/cases/$cleanCcrId/why/complete',
    );
  }

  // ============================================================
  // EXTRACT FISHBONE CAUSE RELATIONSHIP
  // ============================================================

  Map<String, dynamic> _extractCause(
      Map<String, dynamic> validation,
      ) {
    final rawCause =
    validation['ccr_fishbone_causes'];

    final cause = rawCause is Map
        ? Map<String, dynamic>.from(rawCause)
        : <String, dynamic>{};

    // Support flattened API responses as well.
    cause['id'] ??= validation['fishbone_cause_id'];
    cause['cause_text'] ??= validation['cause_text'] ?? '';
    cause['category_id'] ??= validation['category_id'];

    cause['ccr_fishbone_categories'] ??= {
      'name': validation['category_name'] ?? '',
    };

    return cause;
  }
}
