import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/ccr/ccr_root_cause_validation.dart';

class CcrRootCauseValidationService {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  // ============================================================
  // LOAD ALL VALIDATIONS FOR CCR
  //
  // Every Fishbone cause is returned.
  // Existing validation rows are joined when available.
  // ============================================================

  Future<List<CcrRootCauseValidation>> getValidations(
      String ccrId,
      ) async {
    final cleanCcrId = ccrId.trim();

    if (cleanCcrId.isEmpty) {
      throw Exception('CCR ID is missing.');
    }

    // ----------------------------------------------------------
    // STEP 1: Load every Fishbone cause for this CCR.
    // ----------------------------------------------------------

    final causeResponse = await _supabase
        .from('ccr_fishbone_causes')
        .select('''
        id,
        ccr_id,
        category_id,
        cause_text,
        display_order,
        ccr_fishbone_categories (
          name
        )
      ''')
        .eq('ccr_id', cleanCcrId)
        .order('display_order', ascending: true);

    final causes = List<Map<String, dynamic>>.from(
      causeResponse,
    );

    if (causes.isEmpty) {
      return [];
    }

    // ----------------------------------------------------------
    // STEP 2: Collect all Fishbone cause IDs.
    // ----------------------------------------------------------

    final causeIds = causes
        .map((cause) => cause['id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();

    if (causeIds.isEmpty) {
      return [];
    }

    // ----------------------------------------------------------
    // STEP 3: Load saved validations separately.
    // ----------------------------------------------------------

    final validationResponse = await _supabase
        .from('ccr_root_cause_validations')
        .select('''
        id,
        fishbone_cause_id,
        validation_text,
        relevance,
        validated_by,
        validated_at,
        created_at,
        updated_at
      ''')
        .inFilter('fishbone_cause_id', causeIds);

    final validationRows = List<Map<String, dynamic>>.from(
      validationResponse,
    );

    // ----------------------------------------------------------
    // STEP 4: Index saved validations by Fishbone cause ID.
    // ----------------------------------------------------------

    final validationMap = <String, Map<String, dynamic>>{};

    for (final validation in validationRows) {
      final causeId = validation['fishbone_cause_id']?.toString();

      if (causeId != null && causeId.isNotEmpty) {
        validationMap[causeId] = validation;
      }
    }

    // ----------------------------------------------------------
    // STEP 5: Combine causes with their saved validations.
    //
    // Causes without saved validation records are still returned.
    // ----------------------------------------------------------

    final result = <CcrRootCauseValidation>[];

    for (final cause in causes) {
      final causeId = cause['id']?.toString() ?? '';

      final savedValidation = validationMap[causeId];

      final categoryData = cause['ccr_fishbone_categories'];

      final merged = <String, dynamic>{
        if (savedValidation != null)
          ...savedValidation,

        // Always use the actual Fishbone cause ID.
        'fishbone_cause_id': causeId,

        // Preserve the cause and category information.
        'ccr_fishbone_causes': {
          'ccr_id': cause['ccr_id'],
          'category_id': cause['category_id'],
          'cause_text': cause['cause_text'],
          'ccr_fishbone_categories': categoryData,
        },

        // Keep missing validation records as unanswered.
        'validation_text':
        savedValidation?['validation_text'] ?? '',

        'relevance': savedValidation?['relevance'],
      };

      result.add(
        CcrRootCauseValidation.fromMap(merged),
      );
    }

    return result;
  }

  // ============================================================
  // SAVE VALIDATION
  //
  // Uses upsert so the same Fishbone cause has only one
  // validation record.
  // ============================================================

  Future<void> saveValidation({
    required String fishboneCauseId,
    required String validationText,
    required bool relevance,
  }) async {
    final userId =
        _supabase.auth.currentUser?.id;

    final data =
    <String, dynamic>{
      'fishbone_cause_id':
      fishboneCauseId,
      'validation_text':
      validationText.trim(),
      'relevance':
      relevance,
      'validated_at':
      DateTime.now()
          .toIso8601String(),
    };

    if (userId != null) {
      data['validated_by'] =
          userId;
    }

    await _supabase
        .from(
      'ccr_root_cause_validations',
    )
        .upsert(
      data,
      onConflict:
      'fishbone_cause_id',
    );
  }

  // ============================================================
  // SAVE ALL VALIDATIONS
  //
  // Useful for Save Draft.
  // ============================================================

  Future<void> saveAll(
      List<CcrRootCauseValidation>
      validations,
      ) async {
    for (final item in validations) {
      if (item.relevance == null) {
        continue;
      }

      await saveValidation(
        fishboneCauseId:
        item.fishboneCauseId,
        validationText:
        item.validationText,
        relevance:
        item.relevance!,
      );
    }
  }

  // ============================================================
  // COMPLETE VALIDATION
  //
  // All Fishbone causes must have Yes/No selected.
  // ============================================================

  Future<void> completeValidation(
      String ccrId,
      ) async {
    final causes = await _supabase
        .from('ccr_fishbone_causes')
        .select('id')
        .eq(
      'ccr_id',
      ccrId,
    );

    if (causes.isEmpty) {
      throw Exception(
        'No Fishbone causes are available for validation.',
      );
    }

    final causeIds =
    List<Map<String, dynamic>>.from(
      causes,
    )
        .map(
          (row) =>
          row['id']?.toString(),
    )
        .whereType<String>()
        .toList();

    final validations =
    await _supabase
        .from(
      'ccr_root_cause_validations',
    )
        .select(
      'fishbone_cause_id, relevance',
    )
        .inFilter(
      'fishbone_cause_id',
      causeIds,
    );

    final validationRows =
    List<Map<String, dynamic>>.from(
    validations,
    );

    final validatedIds =
    validationRows
        .where(
    (row) =>
    row['relevance'] != null,
    )
        .map(
    (row) =>
    row['fishbone_cause_id']
        ?.toString(),
    )
        .whereType<String>()
        .toSet();

    final missing =
    causeIds
        .where(
    (id) =>
    !validatedIds.contains(id),
    )
        .toList();

    if (missing.isNotEmpty) {
    throw Exception(
    'Select Yes or No for every Fishbone cause before completing validation.',
    );
    }

    // ----------------------------------------------------------
    // Determine next workflow stage from DB.
    // No workflow stage is hardcoded.
    // ----------------------------------------------------------

    final currentCase =
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
    )
        .select('id');

    if (updated.isEmpty) {
    throw Exception(
    'CCR workflow stage was changed by another operation. Reload the CCR and try again.',
    );
    }
  }
}