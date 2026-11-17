import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/ccr/ccr_why_analysis.dart';

class CcrWhyService {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  // ============================================================
  // LOAD ALL 5-WHY ANALYSES FOR A CCR
  //
  // IMPORTANT:
  // Only ROOT CAUSE VALIDATIONS marked relevance = true are
  // loaded into this stage.
  //
  // Each Yes validation gets:
  //
  //   occurrence
  //   non_detection
  //
  // analyses.
  // ============================================================

  Future<List<CcrWhyAnalysis>> getAnalyses(
      String ccrId,
      ) async {
    final cleanCcrId = ccrId.trim();

    if (cleanCcrId.isEmpty) {
      throw Exception(
        'CCR ID is missing.',
      );
    }

    final validations =
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
                category_id,
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

    final yesValidations =
    List<Map<String, dynamic>>.from(
      validations,
    ).where((row) {
      final cause =
      row['ccr_fishbone_causes'];

      if (cause is! Map) {
        return false;
      }

      return cause['ccr_id']?.toString() ==
          cleanCcrId;
    }).toList();

    if (yesValidations.isEmpty) {
      return [];
    }

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
      return [];
    }

    final analysesResponse =
    await _supabase
        .from(
      'ccr_why_analyses',
    )
        .select('''
              *,
              ccr_root_cause_validations!ccr_why_analyses_validation_id_fkey(
                fishbone_cause_id,
                validation_text,
                relevance,
                ccr_fishbone_causes(
                  id,
                  ccr_id,
                  category_id,
                  cause_text,
                  ccr_fishbone_categories(
                    id,
                    name
                  )
                )
              ),
              ccr_why_steps(
                id,
                analysis_id,
                why_number,
                why_text,
                verification_text,
                evidence_available,
                created_at,
                updated_at
              )
            ''')
        .inFilter(
      'validation_id',
      validationIds,
    )
        .order(
      'created_at',
      ascending: true,
    );

    final analyses =
    List<Map<String, dynamic>>.from(
      analysesResponse,
    );

    final result =
    <CcrWhyAnalysis>[];

    for (final validation
    in yesValidations) {
      final validationId =
      validation['id']?.toString();

      if (validationId == null ||
          validationId.isEmpty) {
        continue;
      }

      final cause =
      validation['ccr_fishbone_causes'];

      if (cause is! Map) {
        continue;
      }

      final causeMap =
      Map<String, dynamic>.from(cause);

      final category =
      causeMap[
      'ccr_fishbone_categories'];

      final categoryMap =
      category is Map
          ? Map<String, dynamic>.from(
        category,
      )
          : <String, dynamic>{};

      final matchingAnalyses =
      analyses.where((analysis) {
        return analysis['validation_id']
            ?.toString() ==
            validationId;
      }).toList();

      // --------------------------------------------------------
      // Ensure both analysis types exist.
      // Existing records are reused.
      // Missing records are created automatically.
      // --------------------------------------------------------

      for (final type in [
        'occurrence',
        'non_detection',
      ]) {
        Map<String, dynamic>? existing;

        for (final analysis
        in matchingAnalyses) {
          if (analysis['analysis_type']
              ?.toString()
              .trim()
              .toLowerCase() ==
              type) {
            existing = analysis;
            break;
          }
        }

        if (existing == null) {
          final inserted =
          await _supabase
              .from(
            'ccr_why_analyses',
          )
              .upsert(
            {
              'validation_id':
              validationId,
              'analysis_type':
              type,
              'potential_root_cause':
              causeMap[
              'cause_text']
                  ?.toString() ??
                  '',
            },
            onConflict:
            'validation_id,analysis_type',
          )
              .select('''
                    *,
                    ccr_root_cause_validations!ccr_why_analyses_validation_id_fkey(
                      fishbone_cause_id,
                      validation_text,
                      relevance,
                      ccr_fishbone_causes(
                        id,
                        ccr_id,
                        category_id,
                        cause_text,
                        ccr_fishbone_categories(
                          id,
                          name
                        )
                      )
                    ),
                    ccr_why_steps(
                      id,
                      analysis_id,
                      why_number,
                      why_text,
                      verification_text,
                      evidence_available,
                      created_at,
                      updated_at
                    )
                  ''')
              .single();

          existing =
          Map<String, dynamic>.from(
            inserted,
          );
        }

        final enriched =
        Map<String, dynamic>.from(
          existing,
        );

        // ------------------------------------------------------
        // Make sure the nested validation information exists.
        // ------------------------------------------------------

        enriched[
        'ccr_root_cause_validations'] ??=
            validation;

        final nestedValidation =
        enriched[
        'ccr_root_cause_validations'];

        if (nestedValidation is Map) {
          final nestedValidationMap =
          Map<String, dynamic>.from(
            nestedValidation,
          );

          nestedValidationMap[
          'ccr_fishbone_causes'] ??=
              causeMap;

          enriched[
          'ccr_root_cause_validations'] =
              nestedValidationMap;
        }

        result.add(
          CcrWhyAnalysis.fromMap(
            enriched,
          ),
        );
      }
    }

    result.sort(
          (a, b) {
        final causeCompare =
        a.categoryName.compareTo(
          b.categoryName,
        );

        if (causeCompare != 0) {
          return causeCompare;
        }

        return a.analysisType.compareTo(
          b.analysisType,
        );
      },
    );

    return result;
  }

  // ============================================================
  // SAVE POTENTIAL ROOT CAUSE
  // ============================================================

  Future<void> savePotentialRootCause({
    required String analysisId,
    required String potentialRootCause,
  }) async {
    final cleanId =
    analysisId.trim();

    if (cleanId.isEmpty) {
      throw Exception(
        '5-Why analysis ID is missing.',
      );
    }

    await _supabase
        .from(
      'ccr_why_analyses',
    )
        .update({
      'potential_root_cause':
      potentialRootCause.trim(),
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
  // SAVE ONE WHY STEP
  //
  // Uses UPSERT so the same Why can be saved repeatedly.
  // ============================================================

  Future<CcrWhyStep> saveStep({
    required String analysisId,
    required int whyNumber,
    required String whyText,
    required String verificationText,
    required bool? evidenceAvailable,
  }) async {
    final cleanAnalysisId =
    analysisId.trim();

    if (cleanAnalysisId.isEmpty) {
      throw Exception(
        '5-Why analysis ID is missing.',
      );
    }

    if (whyNumber < 1 ||
        whyNumber > 5) {
      throw Exception(
        'Why number must be between 1 and 5.',
      );
    }

    final response =
    await _supabase
        .from(
      'ccr_why_steps',
    )
        .upsert(
      {
        'analysis_id':
        cleanAnalysisId,
        'why_number':
        whyNumber,
        'why_text':
        whyText.trim(),
        'verification_text':
        verificationText.trim(),
        'evidence_available':
        evidenceAvailable,
        'updated_at':
        DateTime.now()
            .toIso8601String(),
      },
      onConflict:
      'analysis_id,why_number',
    )
        .select()
        .single();

    return CcrWhyStep.fromMap(
      Map<String, dynamic>.from(
        response,
      ),
    );
  }

  // ============================================================
  // DELETE WHY STEP
  // ============================================================

  Future<void> deleteStep(
      String stepId,
      ) async {
    final cleanId =
    stepId.trim();

    if (cleanId.isEmpty) {
      return;
    }

    await _supabase
        .from(
      'ccr_why_steps',
    )
        .delete()
        .eq(
      'id',
      cleanId,
    );
  }

  // ============================================================
  // COMPLETE 5-WHY STAGE
  //
  // This validates that each YES root cause has usable
  // Occurrence and Non-Detection analyses.
  //
  // The user is allowed to stop before Why 5, matching the
  // supplied FACA format.
  // ============================================================

  Future<void> completeWhyStage(
      String ccrId,
      ) async {
    final cleanCcrId =
    ccrId.trim();

    if (cleanCcrId.isEmpty) {
      throw Exception(
        'CCR ID is missing.',
      );
    }

    final analyses =
    await getAnalyses(
      cleanCcrId,
    );

    if (analyses.isEmpty) {
      throw Exception(
        'No Yes root causes are available for 5-Why analysis.',
      );
    }

    for (final analysis in analyses) {
      if (analysis.potentialRootCause
          .trim()
          .isEmpty) {
        throw Exception(
          'Potential root cause is required for every 5-Why analysis.',
        );
      }

      final hasAtLeastOneWhy =
      analysis.steps.any(
            (step) =>
        step.whyText.trim().isNotEmpty,
      );

      if (!hasAtLeastOneWhy) {
        throw Exception(
          'At least one Why is required for ${analysis.analysisTitle}.',
        );
      }
    }

    // ----------------------------------------------------------
    // Determine the next configured workflow stage.
    // ----------------------------------------------------------

    final currentCase =
    await _supabase
        .from(
      'ccr_cases',
    )
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

    final rawOrder =
    currentStageRow[
    'display_order'];

    final currentOrder =
    rawOrder is num
        ? rawOrder.toInt()
        : int.tryParse(
      rawOrder?.toString() ??
          '',
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

    final updated =
    await _supabase
        .from(
      'ccr_cases',
    )
        .update({
      'current_stage':
      nextStageKey,
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
        'CCR workflow stage was changed by another operation. '
            'Reload the CCR and try again.',
      );
    }
  }
}