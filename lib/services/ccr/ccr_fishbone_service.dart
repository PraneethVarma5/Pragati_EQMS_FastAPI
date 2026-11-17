import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/ccr/ccr_fishbone.dart';

class CcrFishboneService {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  // ============================================================
  // LOAD ACTIVE CATEGORIES
  // ============================================================

  Future<List<CcrFishboneCategory>>
  getCategories() async {
    final response = await _supabase
        .from('ccr_fishbone_categories')
        .select()
        .eq(
      'is_active',
      true,
    )
        .order(
      'display_order',
      ascending: true,
    );

    return List<Map<String, dynamic>>
        .from(response)
        .map(
      CcrFishboneCategory.fromMap,
    )
        .toList();
  }

  // ============================================================
  // LOAD CAUSES FOR CCR
  // ============================================================

  Future<List<CcrFishboneCause>>
  getCauses(
      String ccrId,
      ) async {
    final response = await _supabase
        .from('ccr_fishbone_causes')
        .select('''
          *,
          ccr_fishbone_categories(
            name
          )
        ''')
        .eq(
      'ccr_id',
      ccrId,
    )
        .order(
      'display_order',
      ascending: true,
    );

    return List<Map<String, dynamic>>
        .from(response)
        .map(
      CcrFishboneCause.fromMap,
    )
        .toList();
  }

  // ============================================================
  // ADD CAUSE
  // ============================================================

  Future<CcrFishboneCause> addCause({
    required String ccrId,
    required String categoryId,
    required String causeText,
  }) async {
    final cleanCause =
    causeText.trim();

    if (cleanCause.isEmpty) {
      throw Exception(
        'Cause description is required.',
      );
    }

    // ----------------------------------------------------------
    // Find the next display order inside this category
    // for this particular CCR.
    // ----------------------------------------------------------

    final existing = await _supabase
        .from('ccr_fishbone_causes')
        .select('display_order')
        .eq(
      'ccr_id',
      ccrId,
    )
        .eq(
      'category_id',
      categoryId,
    )
        .order(
      'display_order',
      ascending: false,
    )
        .limit(1)
        .maybeSingle();

    int nextOrder = 1;

    if (existing != null) {
      final value =
      existing['display_order'];

      final current = value is num
          ? value.toInt()
          : int.tryParse(
        value?.toString() ?? '',
      ) ??
          0;

      nextOrder = current + 1;
    }

    // ----------------------------------------------------------
    // Insert the cause
    // ----------------------------------------------------------

    final response = await _supabase
        .from('ccr_fishbone_causes')
        .insert({
      'ccr_id': ccrId,
      'category_id': categoryId,
      'cause_text': cleanCause,
      'display_order': nextOrder,
    })
        .select('''
          *,
          ccr_fishbone_categories(
            name
          )
        ''')
        .single();

    return CcrFishboneCause.fromMap(
      Map<String, dynamic>.from(
        response,
      ),
    );
  }

  // ============================================================
  // UPDATE CAUSE
  // ============================================================

  Future<CcrFishboneCause>
  updateCause({
    required String id,
    required String categoryId,
    required String causeText,
  }) async {
    final cleanCause =
    causeText.trim();

    if (cleanCause.isEmpty) {
      throw Exception(
        'Cause description is required.',
      );
    }

    final response = await _supabase
        .from('ccr_fishbone_causes')
        .update({
      'category_id': categoryId,
      'cause_text': cleanCause,
      'updated_at':
      DateTime.now()
          .toIso8601String(),
    })
        .eq(
      'id',
      id,
    )
        .select('''
          *,
          ccr_fishbone_categories(
            name
          )
        ''')
        .single();

    return CcrFishboneCause.fromMap(
      Map<String, dynamic>.from(
        response,
      ),
    );
  }

  // ============================================================
  // DELETE CAUSE
  // ============================================================

  Future<void> deleteCause(
      String id,
      ) async {
    await _supabase
        .from('ccr_fishbone_causes')
        .delete()
        .eq(
      'id',
      id,
    );
  }

  // ============================================================
  // COMPLETE FISHBONE
  //
  // The next workflow stage is obtained from the database
  // workflow master table.
  //
  // No workflow stage names are hardcoded here.
  // ============================================================

  Future<void> completeFishbone(
      String ccrId,
      ) async {
    // ----------------------------------------------------------
    // Get the current stage
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

    // ----------------------------------------------------------
    // Find the current stage order
    // ----------------------------------------------------------

    final currentStageRow =
    await _supabase
        .from('ccr_workflow_stages')
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

    final currentOrder = rawOrder is num
        ? rawOrder.toInt()
        : int.tryParse(
      rawOrder?.toString() ?? '',
    ) ??
        0;

    // ----------------------------------------------------------
    // Find the next active workflow stage
    // ----------------------------------------------------------

    final nextStage =
    await _supabase
        .from('ccr_workflow_stages')
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

    // ----------------------------------------------------------
    // Move CCR to the next stage.
    //
    // The current-stage condition prevents an old screen from
    // accidentally overwriting a newer workflow transition.
    // ----------------------------------------------------------

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
        'CCR workflow stage was changed by another operation. '
            'Reload the CCR and try again.',
      );
    }
  }
}