
import '../../models/ccr/ccr_root_cause_validation.dart';
import 'ccr_api_client.dart';
import 'ccr_session.dart';

class CcrRootCauseValidationService {
  // ============================================================
  // LOAD ALL VALIDATIONS FOR CCR
  //
  // Every Fishbone cause must be returned, including causes
  // that do not yet have a saved validation record.
  // ============================================================

  Future<List<CcrRootCauseValidation>> getValidations(
      String ccrId,
      ) async {
    final cleanCcrId = ccrId.trim();

    if (cleanCcrId.isEmpty) {
      throw Exception('CCR ID is missing.');
    }

    final response = await CcrApiClient.get(
      '/cases/$cleanCcrId/root-cause-validations',
    );

    if (response is! List) {
      throw Exception(
        'Invalid response received while loading root-cause validations.',
      );
    }

    final rows = response
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return rows.map((row) {
      // The model expects the Fishbone cause and category
      // inside nested relationship objects.
      //
      // Preserve an existing nested response. If the API
      // returns flattened fields, construct the relationship.
      if (row['ccr_fishbone_causes'] == null &&
          row['fishbone_cause_id'] != null) {
        row['ccr_fishbone_causes'] = {
          'ccr_id': row['ccr_id'] ?? cleanCcrId,
          'category_id': row['category_id'],
          'cause_text': row['cause_text'] ?? '',
          'ccr_fishbone_categories': {
            'name': row['category_name'] ?? '',
          },
        };
      }

      row['validation_text'] ??= '';
      row['relevance'] ??= null;

      return CcrRootCauseValidation.fromMap(row);
    }).toList();
  }

  // ============================================================
  // SAVE ONE VALIDATION
  //
  // Existing records are updated.
  // New records are inserted.
  // This preserves the original upsert behavior.
  // ============================================================

  Future<void> saveValidation({
    required String ccrId,
    required String fishboneCauseId,
    required String validationText,
    required bool relevance,
  }) async {
    final cleanCcrId = ccrId.trim();

    if (cleanCcrId.isEmpty) {
      throw Exception('CCR ID is missing.');
    }
    final cleanCauseId = fishboneCauseId.trim();

    if (cleanCauseId.isEmpty) {
      throw Exception('Fishbone cause ID is required.');
    }

    final data = <String, dynamic>{
      'fishbone_cause_id': cleanCauseId,
      'validation_text': validationText.trim(),
      'relevance': relevance,
      'validated_at': DateTime.now().toIso8601String(),
    };

    final userId = CcrSession.currentUser?.id;

    if (userId != null && userId.trim().isNotEmpty) {
      data['validated_by'] = userId;
    }

    // Find an existing validation for this Fishbone cause.
    // The endpoint returns validation records alongside causes.
    final existing = await _findExistingValidation(
      cleanCcrId,
      cleanCauseId,
    );

    if (existing != null) {
      await CcrApiClient.put(
        '/root-cause-validations/${existing.id}',
        body: {
          'data': data,
        },
      );
    } else {
      await CcrApiClient.post(
        '/root-cause-validations',
        body: {
          'data': data,
        },
      );
    }
  }

  // ============================================================
  // FIND EXISTING VALIDATION
  // ============================================================

  Future<CcrRootCauseValidation?> _findExistingValidation(
      String ccrId,
      String fishboneCauseId,
      ) async {
    // Reuse the existing endpoint that returns all Fishbone
    // causes together with their saved validation records.
    final validations = await getValidations(ccrId);

    for (final item in validations) {
      if (item.fishboneCauseId == fishboneCauseId &&
          item.id.trim().isNotEmpty) {
        return item;
      }
    }

    return null;
  }
  // ============================================================
  // SAVE ALL VALIDATIONS
  //
  // Useful for Save Draft.
  // Unanswered causes are skipped.
  // ============================================================

  Future<void> saveAll(
      List<CcrRootCauseValidation> validations,
      ) async {
    for (final item in validations) {
      if (item.relevance == null) {
        continue;
      }

      await saveValidation(
        ccrId: item.ccrId,
        fishboneCauseId: item.fishboneCauseId,
        validationText: item.validationText,
        relevance: item.relevance!,
      );
    }
  }

  // ============================================================
  // COMPLETE VALIDATION
  //
  // Every Fishbone cause must have a Yes/No answer.
  // ============================================================

  Future<void> completeValidation(
      String ccrId,
      ) async {
    final cleanCcrId = ccrId.trim();

    if (cleanCcrId.isEmpty) {
      throw Exception('CCR ID is missing.');
    }

    // Load every Fishbone cause and its validation.
    final validations = await getValidations(cleanCcrId);

    if (validations.isEmpty) {
      throw Exception(
        'No Fishbone causes are available for validation.',
      );
    }

    final missing = validations
        .where((item) => item.relevance == null)
        .toList();

    if (missing.isNotEmpty) {
      throw Exception(
        'Select Yes or No for every Fishbone cause before completing validation.',
      );
    }

    // The backend handles workflow stage advancement.
    await CcrApiClient.post(
      '/cases/$cleanCcrId/root-cause-validations/complete',
    );
  }
}
