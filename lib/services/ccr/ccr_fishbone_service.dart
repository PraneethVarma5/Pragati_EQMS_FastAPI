
import '../../models/ccr/ccr_fishbone.dart';
import 'ccr_api_client.dart';

class CcrFishboneService {
  // ============================================================
  // LOAD ACTIVE CATEGORIES
  // ============================================================

  Future<List<CcrFishboneCategory>> getCategories() async {
    final response = await CcrApiClient.get(
      '/fishbone/categories',
    );

    if (response is! List) {
      throw Exception(
        'Invalid response received while loading Fishbone categories.',
      );
    }

    return response
        .whereType<Map>()
        .map(
          (item) => CcrFishboneCategory.fromMap(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }

  // ============================================================
  // LOAD CAUSES FOR CCR
  // ============================================================

  Future<List<CcrFishboneCause>> getCauses(
      String ccrId,
      ) async {
    final cleanCcrId = ccrId.trim();

    if (cleanCcrId.isEmpty) {
      throw Exception('CCR ID is required.');
    }

    final response = await CcrApiClient.get(
      '/cases/$cleanCcrId/fishbone/causes',
    );

    if (response is! List) {
      throw Exception(
        'Invalid response received while loading Fishbone causes.',
      );
    }

    final causes = response
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
    )
        .toList();

    // The model expects the category relationship under
    // ccr_fishbone_categories. Enrich it if the API returns
    // category_id without the nested relationship.
    final needsCategories = causes.any(
          (cause) => cause['ccr_fishbone_categories'] == null,
    );

    Map<String, String> categoryNames = {};

    if (needsCategories) {
      final categories = await getCategories();

      categoryNames = {
        for (final category in categories)
          category.id: category.name,
      };
    }

    for (final cause in causes) {
      if (cause['ccr_fishbone_categories'] != null) {
        continue;
      }

      final categoryId = cause['category_id']?.toString() ?? '';

      cause['ccr_fishbone_categories'] = {
        'name': categoryNames[categoryId] ?? '',
      };
    }

    causes.sort((a, b) {
      final orderA = _toInt(a['display_order']);
      final orderB = _toInt(b['display_order']);
      return orderA.compareTo(orderB);
    });

    return causes
        .map(CcrFishboneCause.fromMap)
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
    final cleanCcrId = ccrId.trim();
    final cleanCategoryId = categoryId.trim();
    final cleanCause = causeText.trim();

    if (cleanCcrId.isEmpty) {
      throw Exception('CCR ID is required.');
    }

    if (cleanCategoryId.isEmpty) {
      throw Exception('Fishbone category is required.');
    }

    if (cleanCause.isEmpty) {
      throw Exception('Cause description is required.');
    }

    // Find the next display order within this CCR/category.
    final existingCauses = await getCauses(cleanCcrId);

    final categoryCauses = existingCauses
        .where((cause) => cause.categoryId == cleanCategoryId)
        .toList();

    final nextOrder = categoryCauses.isEmpty
        ? 1
        : categoryCauses
        .map((cause) => cause.displayOrder)
        .reduce((a, b) => a > b ? a : b) +
        1;

    final response = await CcrApiClient.post(
      '/fishbone/causes',
      body: {
        'data': {
          'ccr_id': cleanCcrId,
          'category_id': cleanCategoryId,
          'cause_text': cleanCause,
          'display_order': nextOrder,
        },
      },
    );

    if (response is! Map) {
      throw Exception(
        'Invalid response received while adding Fishbone cause.',
      );
    }

    final result = Map<String, dynamic>.from(response);

    // Ensure the model receives the category relationship.
    result['ccr_fishbone_categories'] = await _categoryRelation(
      cleanCategoryId,
    );

    return CcrFishboneCause.fromMap(result);
  }

  // ============================================================
  // UPDATE CAUSE
  // ============================================================

  Future<CcrFishboneCause> updateCause({
    required String id,
    required String categoryId,
    required String causeText,
  }) async {
    final cleanId = id.trim();
    final cleanCategoryId = categoryId.trim();
    final cleanCause = causeText.trim();

    if (cleanId.isEmpty) {
      throw Exception('Fishbone cause ID is required.');
    }

    if (cleanCategoryId.isEmpty) {
      throw Exception('Fishbone category is required.');
    }

    if (cleanCause.isEmpty) {
      throw Exception('Cause description is required.');
    }

    final response = await CcrApiClient.patch(
      '/fishbone/causes/$cleanId',
      body: {
        'data': {
          'category_id': cleanCategoryId,
          'cause_text': cleanCause,
          'updated_at': DateTime.now().toIso8601String(),
        },
      },
    );

    if (response is! Map) {
      throw Exception(
        'Invalid response received while updating Fishbone cause.',
      );
    }

    final result = Map<String, dynamic>.from(response);

    result['ccr_fishbone_categories'] = await _categoryRelation(
      cleanCategoryId,
    );

    return CcrFishboneCause.fromMap(result);
  }

  // ============================================================
  // DELETE CAUSE
  // ============================================================

  Future<void> deleteCause(String id) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      throw Exception('Fishbone cause ID is required.');
    }

    await CcrApiClient.delete(
      '/fishbone/causes/$cleanId',
    );
  }

  // ============================================================
  // COMPLETE FISHBONE
  // ============================================================

  Future<void> completeFishbone(String ccrId) async {
    final cleanCcrId = ccrId.trim();

    if (cleanCcrId.isEmpty) {
      throw Exception('CCR ID is required.');
    }

    await CcrApiClient.post(
      '/cases/$cleanCcrId/fishbone/complete',
    );
  }

  // ============================================================
  // CATEGORY RELATIONSHIP HELPER
  // ============================================================

  Future<Map<String, dynamic>> _categoryRelation(
      String categoryId,
      ) async {
    final categories = await getCategories();

    final matchingCategory = categories.where(
          (category) => category.id == categoryId,
    );

    if (matchingCategory.isEmpty) {
      throw Exception(
        'Fishbone category was not found.',
      );
    }

    return {
      'name': matchingCategory.first.name,
    };
  }

  // ============================================================
  // INTEGER HELPER
  // ============================================================

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
