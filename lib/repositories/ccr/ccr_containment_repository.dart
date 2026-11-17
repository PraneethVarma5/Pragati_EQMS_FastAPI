import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/ccr/ccr_containment.dart';

class CcrContainmentRepository {
  CcrContainmentRepository({
    SupabaseClient? client,
  }) : _client =
      client ?? Supabase.instance.client;

  final SupabaseClient _client;

  // ============================================================
  // GET CONTAINMENT
  // ============================================================

  Future<CcrContainment?> getContainment(
      String ccrId) async {
    final cleanId = ccrId.trim();

    if (cleanId.isEmpty) {
      throw Exception(
        'CCR ID is missing.',
      );
    }

    final response = await _client
        .from('ccr_containment')
        .select()
        .eq('ccr_id', cleanId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return CcrContainment.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  // ============================================================
  // GET SORTING RESULTS
  // ============================================================

  Future<List<CcrContainmentSorting>>
  getSortingResults(
      String containmentId,
      ) async {
    final cleanId = containmentId.trim();

    if (cleanId.isEmpty) {
      throw Exception(
        'Containment ID is missing.',
      );
    }

    final response = await _client
        .from('ccr_containment_sorting')
        .select()
        .eq('containment_id', cleanId)
        .order(
      'created_at',
      ascending: true,
    );

    return List<Map<String, dynamic>>
        .from(response)
        .map(
      CcrContainmentSorting.fromMap,
    )
        .toList();
  }

  // ============================================================
  // CREATE OR UPDATE CONTAINMENT
  // ============================================================

  Future<CcrContainment> saveContainment({
    required String ccrId,
    String? sortingActivity,
    String? sortingLearnings,
    String? customerProtectionAction,
    String? recoverPrqSchedule,
    String? firstCertifiedGoodShipment,
    DateTime? targetEta,
    String? status,
  }) async {
    final cleanId = ccrId.trim();

    if (cleanId.isEmpty) {
      throw Exception(
        'CCR ID is missing.',
      );
    }

    final existing = await _client
        .from('ccr_containment')
        .select('id')
        .eq('ccr_id', cleanId)
        .maybeSingle();

    final data = <String, dynamic>{
      'ccr_id': cleanId,
      'sorting_activity':
      _nullableText(sortingActivity),
      'sorting_learnings':
      _nullableText(sortingLearnings),
      'customer_protection_action':
      _nullableText(customerProtectionAction),
      'recover_prq_schedule':
      _nullableText(recoverPrqSchedule),
      'first_certified_good_shipment':
      _nullableText(
        firstCertifiedGoodShipment,
      ),
      'target_eta':
      targetEta?.toIso8601String().split('T').first,
    };

    if (status != null &&
        status.trim().isNotEmpty) {
      data['status'] = status.trim();
    }

    final response = existing == null
        ? await _client
        .from('ccr_containment')
        .insert(data)
        .select()
        .single()
        : await _client
        .from('ccr_containment')
        .update(data)
        .eq(
      'id',
      existing['id'].toString(),
    )
        .select()
        .single();

    return CcrContainment.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  // ============================================================
  // SAVE SORTING ROW
  // ============================================================

  Future<CcrContainmentSorting>
  saveSortingRow({
    required String containmentId,
    required String? location,
    required double? qtyNg,
    required double? qtySorted,
    required DateTime? sortingDate,
    required String? dri,
  }) async {
    final cleanId = containmentId.trim();

    if (cleanId.isEmpty) {
      throw Exception(
        'Containment ID is missing.',
      );
    }

    final response = await _client
        .from('ccr_containment_sorting')
        .insert({
      'containment_id': cleanId,
      'location': _nullableText(location),
      'qty_ng': qtyNg,
      'qty_sorted': qtySorted,
      'sorting_date':
      sortingDate
          ?.toIso8601String()
          .split('T')
          .first,
      'dri': _nullableText(dri),
    })
        .select()
        .single();

    return CcrContainmentSorting.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  // ============================================================
  // UPDATE SORTING ROW
  // ============================================================

  Future<CcrContainmentSorting>
  updateSortingRow({
    required String id,
    required String? location,
    required double? qtyNg,
    required double? qtySorted,
    required DateTime? sortingDate,
    required String? dri,
  }) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      throw Exception(
        'Sorting row ID is missing.',
      );
    }

    final response = await _client
        .from('ccr_containment_sorting')
        .update({
      'location': _nullableText(location),
      'qty_ng': qtyNg,
      'qty_sorted': qtySorted,
      'sorting_date':
      sortingDate
          ?.toIso8601String()
          .split('T')
          .first,
      'dri': _nullableText(dri),
    })
        .eq('id', cleanId)
        .select()
        .single();

    return CcrContainmentSorting.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  // ============================================================
  // DELETE SORTING ROW
  // ============================================================

  Future<void> deleteSortingRow(
      String id) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      throw Exception(
        'Sorting row ID is missing.',
      );
    }

    await _client
        .from('ccr_containment_sorting')
        .delete()
        .eq('id', cleanId);
  }

  // ============================================================
  // COMPLETE CONTAINMENT
  //
  // IMPORTANT:
  // The next stage is discovered from the workflow
  // master table. No workflow stage key is hardcoded here.
  // ============================================================

  Future<void> completeContainment(
      String ccrId) async {
    final cleanId = ccrId.trim();

    if (cleanId.isEmpty) {
      throw Exception(
        'CCR ID is missing.',
      );
    }

    final currentCase = await _client
        .from('ccr_cases')
        .select('current_stage')
        .eq('id', cleanId)
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

    final currentStageRecord =
    await _client
        .from('ccr_workflow_stages')
        .select(
      'display_order',
    )
        .eq(
      'stage_key',
      currentStage,
    )
        .single();

    final currentOrder =
    currentStageRecord['display_order'];

    if (currentOrder is! num) {
      throw Exception(
        'Current workflow stage order is invalid.',
      );
    }

    final nextStages = await _client
        .from('ccr_workflow_stages')
        .select(
      'stage_key, display_order',
    )
        .eq('is_active', true)
        .gt(
      'display_order',
      currentOrder.toInt(),
    )
        .order(
      'display_order',
      ascending: true,
    )
        .limit(1);

    if (nextStages.isEmpty) {
      throw Exception(
        'No next workflow stage is configured.',
      );
    }

    final nextStage =
    Map<String, dynamic>.from(
      nextStages.first,
    );

    final nextStageKey =
    nextStage['stage_key']
        ?.toString()
        .trim();

    if (nextStageKey == null ||
        nextStageKey.isEmpty) {
      throw Exception(
        'Next workflow stage is invalid.',
      );
    }

    await _client
        .from('ccr_cases')
        .update({
      'current_stage': nextStageKey,
    }).eq('id', cleanId);
  }

  String? _nullableText(String? value) {
    final clean = value?.trim();

    if (clean == null ||
        clean.isEmpty) {
      return null;
    }

    return clean;
  }
}