import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'audit/audit_api_client.dart';


class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  // ============================================================
  // BATCHES
  // ============================================================

  static Future<List<Map<String, dynamic>>> getAllBatches() async {
    final response = await client
        .from('batches')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================================
  // GET ACTIVE BATCHES
  // ============================================================

  static Future<List<Map<String, dynamic>>> getActiveBatches() async {
    final response = await client
        .from('batches')
        .select()
        .eq('is_active', true)
        .order('batch_name');

    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================================
  // CREATE BATCH
  // ============================================================

  static Future<Map<String, dynamic>> createBatch({
    required String batchId,
    required String batchName,
    required String description,
  }) async {
    final response = await client
        .from('batches')
        .insert({
      'batch_id': batchId.trim(),
      'batch_code': batchId.trim(),
      'batch_name': batchName.trim(),
      'description': description.trim(),
      'is_active': true,
    })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }
  // ============================================================
  // UPDATE BATCH
  // ============================================================
  static Future<Map<String, dynamic>> updateBatch({
    required String oldBatchId,
    required String batchId,
    required String batchName,
    required String description,
    required bool isActive,
  }) async {
    final response = await client.rpc(
      'rename_batch',
      params: {
        'p_old_batch_id': oldBatchId.trim(),
        'p_new_batch_id': batchId.trim(),
        'p_batch_name': batchName.trim(),
        'p_description': description.trim(),
        'p_is_active': isActive,
      },
    );

    if (response == null) {
      throw Exception(
        'Batch could not be updated.',
      );
    }

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    throw Exception(
      'Invalid response received while updating batch.',
    );
  }
  // ============================================================
  // UPDATE BATCH STATUS
  // ============================================================

  static Future<void> updateBatchStatus({
    required String batchId,
    required bool isActive,
  }) async {
    await client
        .from('batches')
        .update({
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('batch_id', batchId.trim());
  }

  // ============================================================
  // DELETE BATCH
  // ============================================================

  static Future<void> deleteBatch(
      String batchId,
      ) async {
    final cleanBatchId = batchId.trim();

    if (cleanBatchId.isEmpty) {
      throw Exception(
        'Batch ID cannot be empty.',
      );
    }

    // ----------------------------------------------------------
    // Delete all parts belonging to this batch first.
    //
    // Completed ARR observations are NOT deleted.
    // Their part_id will become NULL because the database FK
    // is configured with ON DELETE SET NULL.
    // ----------------------------------------------------------

    await client
        .from('parts')
        .delete()
        .eq('batch_id', cleanBatchId);

    // ----------------------------------------------------------
    // Delete the batch itself.
    // ----------------------------------------------------------

    final response = await client
        .from('batches')
        .delete()
        .eq('batch_id', cleanBatchId)
        .select('batch_id');

    if (response.isEmpty) {
      throw Exception(
        'Batch "$cleanBatchId" could not be found or deleted.',
      );
    }
  }

  // ============================================================
  // PARTS
  // ============================================================
  // ============================================================
  // PARTS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getActiveParts(
      String batchId,
      ) async {
    final cleanBatchId = batchId.trim();

    if (cleanBatchId.isEmpty) {
      throw Exception(
        'Batch ID cannot be empty.',
      );
    }

    final response = await client
        .from('parts')
        .select()
        .eq('batch_id', cleanBatchId)
        .eq('is_active', true)
        .order('sequence_order', ascending: true);

    return List<Map<String, dynamic>>.from(
      response,
    );
  }

  // static Future<List<Map<String, dynamic>>> getAllParts(
  //     String batchId,
  //     ) async {
  //   final cleanBatchId = batchId.trim();
  //
  //   if (cleanBatchId.isEmpty) {
  //     throw Exception(
  //       'Batch ID cannot be empty.',
  //     );
  //   }
  //
  //   final response = await client
  //       .from('parts')
  //       .select()
  //       .eq('batch_id', cleanBatchId)
  //       .order('sequence_order', ascending: true);
  //
  //   return List<Map<String, dynamic>>.from(
  //     response,
  //   );
  // }
  static Future<List<Map<String, dynamic>>> getAllParts(
      String batchId,
      ) async {
    final response = await client
        .from('parts')
        .select()
        .eq('batch_id', batchId.trim())
        .order('sequence_order');

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> getPartByBarcode(
      String barcode,
      ) async {
    final response = await client
        .from('parts')
        .select()
        .eq('barcode_value', barcode.trim())
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Map<String, dynamic>.from(response);
  }

  static Future<Map<String, dynamic>> createPart({
    required String batchId,
    required String partNumber,
    required int masterStatus,
    required int sequenceOrder,
    required String barcode,
  }) async {
    final cleanBatchId = batchId.trim();
    final cleanPartNumber = partNumber.trim();
    final cleanBarcode = barcode.trim();

    if (cleanBatchId.isEmpty) {
      throw Exception('Batch ID cannot be empty.');
    }

    if (cleanPartNumber.isEmpty) {
      throw Exception('Part number cannot be empty.');
    }

    if (cleanBarcode.isEmpty) {
      throw Exception('Barcode cannot be empty.');
    }

    if (masterStatus != 0 && masterStatus != 1) {
      throw Exception(
        'Master status must be either 0 or 1.',
      );
    }

    if (sequenceOrder < 1) {
      throw Exception(
        'Sequence order must be greater than 0.',
      );
    }

    // ----------------------------------------------------------
    // Prevent duplicate part number inside the same batch
    // ----------------------------------------------------------

    final existingPart = await client
        .from('parts')
        .select('part_id')
        .eq('batch_id', cleanBatchId)
        .eq('part_number', cleanPartNumber)
        .maybeSingle();

    if (existingPart != null) {
      throw Exception(
        'Part number "$cleanPartNumber" already exists in this batch.',
      );
    }

    // ----------------------------------------------------------
    // Prevent duplicate QR / barcode
    // ----------------------------------------------------------

    final existingBarcode = await client
        .from('parts')
        .select('part_id')
        .eq('barcode_value', cleanBarcode)
        .maybeSingle();

    if (existingBarcode != null) {
      throw Exception(
        'QR / barcode "$cleanBarcode" is already assigned to another part.',
      );
    }

    // ----------------------------------------------------------
    // Create part
    // ----------------------------------------------------------

    final response = await client
        .from('parts')
        .insert({
      'batch_id': cleanBatchId,
      'part_number': cleanPartNumber,
      'master_status': masterStatus,
      'sequence_order': sequenceOrder,
      'barcode_value': cleanBarcode,
      'is_active': true,
    })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  static Future<Map<String, dynamic>> updatePart({
    required String partId,
    required String partNo,
    required int initialStatus,
    required String barcode,
    required int sequenceOrder,
    required bool isActive,
  }) async {
    final cleanPartId = partId.trim();
    final cleanPartNo = partNo.trim();
    final cleanBarcode = barcode.trim();

    if (cleanPartId.isEmpty) {
      throw Exception('Part ID cannot be empty.');
    }

    if (cleanPartNo.isEmpty) {
      throw Exception('Part number cannot be empty.');
    }

    if (cleanBarcode.isEmpty) {
      throw Exception('Barcode cannot be empty.');
    }

    if (initialStatus != 0 && initialStatus != 1) {
      throw Exception(
        'Master status must be either 0 or 1.',
      );
    }

    if (sequenceOrder < 1) {
      throw Exception(
        'Sequence order must be greater than 0.',
      );
    }

    // ----------------------------------------------------------
    // Get current part
    // ----------------------------------------------------------

    final currentPart = await client
        .from('parts')
        .select('batch_id')
        .eq('part_id', cleanPartId)
        .maybeSingle();

    if (currentPart == null) {
      throw Exception(
        'Part could not be found.',
      );
    }

    final batchId =
    currentPart['batch_id']?.toString().trim();

    if (batchId == null || batchId.isEmpty) {
      throw Exception(
        'Part batch information is missing.',
      );
    }

    // ----------------------------------------------------------
    // Prevent duplicate part number in same batch
    // ----------------------------------------------------------

    final duplicatePart = await client
        .from('parts')
        .select('part_id')
        .eq('batch_id', batchId)
        .eq('part_number', cleanPartNo)
        .neq('part_id', cleanPartId)
        .maybeSingle();

    if (duplicatePart != null) {
      throw Exception(
        'Part number "$cleanPartNo" already exists in this batch.',
      );
    }

    // ----------------------------------------------------------
    // Prevent duplicate barcode
    // ----------------------------------------------------------

    final duplicateBarcode = await client
        .from('parts')
        .select('part_id')
        .eq('barcode_value', cleanBarcode)
        .neq('part_id', cleanPartId)
        .maybeSingle();

    if (duplicateBarcode != null) {
      throw Exception(
        'QR / barcode "$cleanBarcode" is already assigned to another part.',
      );
    }

    // ----------------------------------------------------------
    // Update part
    // ----------------------------------------------------------

    final response = await client
        .from('parts')
        .update({
      'part_number': cleanPartNo,
        'master_status': initialStatus,
      'barcode_value': cleanBarcode,
      'sequence_order': sequenceOrder,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('part_id', cleanPartId)
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  static Future<void> updatePartStatus({
    required String partId,
    required bool isActive,
  }) async {
    final cleanPartId = partId.trim();

    if (cleanPartId.isEmpty) {
      throw Exception(
        'Part ID cannot be empty.',
      );
    }

    final response = await client
        .from('parts')
        .update({
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('part_id', cleanPartId)
        .select('part_id, is_active')
        .maybeSingle();

    if (response == null) {
      throw Exception(
        'Part could not be found or updated.',
      );
    }
  }
  static Future<void> deletePart(
      String partId,
      ) async {
    final cleanPartId = partId.trim();

    if (cleanPartId.isEmpty) {
      throw Exception(
        'Part ID cannot be empty.',
      );
    }

    final response = await client
        .from('parts')
        .delete()
        .eq('part_id', cleanPartId)
        .select('part_id');

    if (response.isEmpty) {
      throw Exception(
        'Part could not be found or deleted.',
      );
    }
  }
  // ============================================================
// SAVE ARR OBSERVED DEFECTS
//
// Candidate observations are stored separately from master
// part_defects.
//
// Key format received from ScannerAssessmentScreen:
//     "$partId|$trailNo"
// ============================================================

  static Future<void>
  saveArrObservationDefects({
    required String arrId,
    required Map<String, List<Map<String, dynamic>>> selections,
  }) async {
    final cleanArrId = arrId.trim();

    if (cleanArrId.isEmpty) {
      throw Exception(
        'ARR ID cannot be empty.',
      );
    }

    if (selections.isEmpty) {
      return;
    }

    // ============================================================
    // LOAD OBSERVATIONS
    // ============================================================

    final observations = await client
        .from('arr_observations')
        .select('''
        observation_id,
        part_id
      ''')
        .eq(
      'arr_id',
      cleanArrId,
    );

    final observationIdByPart =
    <String, String>{};

    final observationIds =
    <String>[];

    for (final row
    in List<Map<String, dynamic>>.from(
      observations,
    )) {
      final observationId =
          row['observation_id']
              ?.toString()
              .trim() ??
              '';

      final partId =
          row['part_id']
              ?.toString()
              .trim() ??
              '';

      if (observationId.isEmpty ||
          partId.isEmpty) {
        continue;
      }

      observationIdByPart[partId] =
          observationId;

      observationIds.add(
        observationId,
      );
    }

    // ============================================================
    // REMOVE EXISTING OBSERVED DEFECTS
    // ============================================================

    if (observationIds.isNotEmpty) {
      await client
          .from('arr_observation_defects')
          .delete()
          .inFilter(
        'observation_id',
        observationIds,
      );
    }

    final rows =
    <Map<String, dynamic>>[];

    final uniqueKeys =
    <String>{};

    // ============================================================
    // selections key:
    //
    // partId|trailNo
    // ============================================================

    for (final entry
    in selections.entries) {
      final keyParts =
      entry.key.split('|');

      if (keyParts.length != 2) {
        continue;
      }

      final partId =
      keyParts[0].trim();

      final trailNo =
      int.tryParse(
        keyParts[1].trim(),
      );

      if (partId.isEmpty ||
          trailNo == null ||
          trailNo < 1 ||
          trailNo > 3) {
        continue;
      }

      final observationId =
      observationIdByPart[partId];

      if (observationId == null ||
          observationId.isEmpty) {
        continue;
      }

      for (final pair
      in entry.value) {
        final defectId =
            pair['defect_id']
                ?.toString()
                .trim() ??
                '';

        if (defectId.isEmpty) {
          continue;
        }

        final uniqueKey =
            '$observationId|$trailNo|$defectId';

        if (!uniqueKeys.add(
          uniqueKey,
        )) {
          continue;
        }

        rows.add({
          'observation_id':
          observationId,
          'trail_no':
          trailNo,
          'defect_id':
          defectId,
        });
      }
    }

    if (rows.isEmpty) {
      return;
    }

    await client
        .from('arr_observation_defects')
        .insert(rows);
  }
  // ============================================================
  // DEFECT MANAGEMENT
  // ============================================================

  static Future<List<Map<String, dynamic>>>
  getDefectTypes({
    bool activeOnly = false,
  }) async {
    var query = client
        .from('defect_types')
        .select();

    if (activeOnly) {
      query = query.eq(
        'is_active',
        true,
      );
    }

    final response = await query
        .order('defect_name');

    return List<Map<String, dynamic>>.from(
      response,
    );
  }

  static Future<List<Map<String, dynamic>>>
  getDefectLocations({
    bool activeOnly = false,
  }) async {
    var query = client
        .from('defect_locations')
        .select();

    if (activeOnly) {
      query = query.eq(
        'is_active',
        true,
      );
    }

    final response = await query
        .order('location_name');

    return List<Map<String, dynamic>>.from(
      response,
    );
  }

  static Future<Map<String, dynamic>>
  createDefectType({
    required String name,
  }) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception(
        'Defect type cannot be empty.',
      );
    }

    final response = await client
        .from('defect_types')
        .insert({
      'defect_name': cleanName,
      'is_active': true,
    })
        .select()
        .single();

    return Map<String, dynamic>.from(
      response,
    );
  }

  static Future<Map<String, dynamic>>
  createDefectLocation({
    required String name,
  }) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception(
        'Location cannot be empty.',
      );
    }

    final response = await client
        .from('defect_locations')
        .insert({
      'location_name': cleanName,
      'is_active': true,
    })
        .select()
        .single();

    return Map<String, dynamic>.from(
      response,
    );
  }

  static Future<Map<String, dynamic>>
  updateDefectType({
    required String defectId,
    required String name,
  }) async {
    final cleanId = defectId.trim();
    final cleanName = name.trim();

    if (cleanId.isEmpty) {
      throw Exception(
        'Defect ID cannot be empty.',
      );
    }

    if (cleanName.isEmpty) {
      throw Exception(
        'Defect type cannot be empty.',
      );
    }

    final response = await client
        .from('defect_types')
        .update({
      'defect_name': cleanName,
      'updated_at':
      DateTime.now().toIso8601String(),
    })
        .eq('defect_id', cleanId)
        .select()
        .single();

    return Map<String, dynamic>.from(
      response,
    );
  }

  static Future<Map<String, dynamic>>
  updateDefectLocation({
    required String locationId,
    required String name,
  }) async {
    final cleanId = locationId.trim();
    final cleanName = name.trim();

    if (cleanId.isEmpty) {
      throw Exception(
        'Location ID cannot be empty.',
      );
    }

    if (cleanName.isEmpty) {
      throw Exception(
        'Location cannot be empty.',
      );
    }

    final response = await client
        .from('defect_locations')
        .update({
      'location_name': cleanName,
      'updated_at':
      DateTime.now().toIso8601String(),
    })
        .eq('location_id', cleanId)
        .select()
        .single();

    return Map<String, dynamic>.from(
      response,
    );
  }

  static Future<void>
  updateDefectTypeStatus({
    required String defectId,
    required bool isActive,
  }) async {
    final cleanId = defectId.trim();

    if (cleanId.isEmpty) {
      throw Exception(
        'Defect ID cannot be empty.',
      );
    }

    await client
        .from('defect_types')
        .update({
      'is_active': isActive,
      'updated_at':
      DateTime.now().toIso8601String(),
    })
        .eq('defect_id', cleanId);
  }

  static Future<void>
  updateDefectLocationStatus({
    required String locationId,
    required bool isActive,
  }) async {
    final cleanId = locationId.trim();

    if (cleanId.isEmpty) {
      throw Exception(
        'Location ID cannot be empty.',
      );
    }

    await client
        .from('defect_locations')
        .update({
      'is_active': isActive,
      'updated_at':
      DateTime.now().toIso8601String(),
    })
        .eq('location_id', cleanId);
  }
  // ============================================================
  // DEFECT CATEGORIES
  // ============================================================

  static Future<List<Map<String, dynamic>>>
  getDefectCategories({
    bool activeOnly = false,
  }) async {
    var query = client
        .from('defect_categories')
        .select();

    if (activeOnly) {
      query = query.eq(
        'is_active',
        true,
      );
    }

    final response = await query
        .order('category_name');

    return List<Map<String, dynamic>>.from(
      response,
    );
  }

  static Future<Map<String, dynamic>?>
  getDefectCategoryById(
      String categoryId,
      ) async {
    final cleanId = categoryId.trim();

    if (cleanId.isEmpty) {
      throw Exception(
        'Defect category ID cannot be empty.',
      );
    }

    final response = await client
        .from('defect_categories')
        .select()
        .eq(
      'category_id',
      cleanId,
    )
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Map<String, dynamic>.from(
      response,
    );
  }

  static Future<Map<String, dynamic>>
  createDefectCategory({
    required String name,
  }) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception(
        'Defect category name cannot be empty.',
      );
    }

    final response = await client
        .from('defect_categories')
        .insert({
      'category_name': cleanName,
      'is_active': true,
    })
        .select()
        .single();

    return Map<String, dynamic>.from(
      response,
    );
  }

  static Future<Map<String, dynamic>>
  updateDefectCategory({
    required String categoryId,
    required String name,
  }) async {
    final cleanId = categoryId.trim();
    final cleanName = name.trim();

    if (cleanId.isEmpty) {
      throw Exception(
        'Defect category ID cannot be empty.',
      );
    }

    if (cleanName.isEmpty) {
      throw Exception(
        'Defect category name cannot be empty.',
      );
    }

    final response = await client
        .from('defect_categories')
        .update({
      'category_name': cleanName,
      'updated_at':
      DateTime.now().toIso8601String(),
    })
        .eq(
      'category_id',
      cleanId,
    )
        .select()
        .single();

    return Map<String, dynamic>.from(
      response,
    );
  }

  static Future<void>
  updateDefectCategoryStatus({
    required String categoryId,
    required bool isActive,
  }) async {
    final cleanId = categoryId.trim();

    if (cleanId.isEmpty) {
      throw Exception(
        'Defect category ID cannot be empty.',
      );
    }

    await client
        .from('defect_categories')
        .update({
      'is_active': isActive,
      'updated_at':
      DateTime.now().toIso8601String(),
    })
        .eq(
      'category_id',
      cleanId,
    );
  }

  // ============================================================
  // CATEGORY DEFECT / LOCATION PAIRS
  // ============================================================

  static Future<List<Map<String, dynamic>>>
  getCategoryDefectPairs(
      String categoryId,
      ) async {
    final cleanId =
    categoryId.trim();

    if (cleanId.isEmpty) {
      throw Exception(
        'Defect category ID cannot be empty.',
      );
    }

    final response =
    await client
        .from('category_defect_pairs')
        .select('''
          category_defect_pair_id,
          category_id,
          defect_id,
          defect_types (
            defect_id,
            defect_name,
            is_active
          )
        ''')
        .eq(
      'category_id',
      cleanId,
    )
        .order(
      'created_at',
    );

    return List<
        Map<String, dynamic>>.from(
      response,
    );
  }
  static Future<void>
  saveCategoryDefectPairs({
    required String categoryId,
    required List<Map<String, dynamic>> pairs,
  }) async {
    final cleanCategoryId =
    categoryId.trim();

    if (cleanCategoryId.isEmpty) {
      throw Exception(
        'Defect category ID cannot be empty.',
      );
    }

    await client
        .from('category_defect_pairs')
        .delete()
        .eq(
      'category_id',
      cleanCategoryId,
    );

    if (pairs.isEmpty) {
      return;
    }

    final rows = <Map<String, dynamic>>[];

    final uniquePairs = <String>{};

    for (final pair in pairs) {
      final defectId =
          pair['defect_id']?.toString().trim() ?? '';

      if (defectId.isEmpty) {
        throw Exception(
          'Every category pair must contain a defect type.',
        );
      }

      final uniqueKey =
          defectId;

      if (!uniquePairs.add(uniqueKey)) {
        continue;
      }

      rows.add({
        'category_id':
        cleanCategoryId,
        'defect_id':
        defectId,
      });
    }

    if (rows.isEmpty) {
      return;
    }

    await client
        .from('category_defect_pairs')
        .insert(rows);
  }

  static Future<void>
  addCategoryDefectPair({
    required String categoryId,
    required String defectId,
  }) async {

    final cleanCategoryId =
    categoryId.trim();

    final cleanDefectId =
    defectId.trim();

    if (cleanCategoryId.isEmpty) {
      throw Exception(
        'Defect category ID cannot be empty.',
      );
    }

    if (cleanDefectId.isEmpty) {
      throw Exception(
        'Defect ID cannot be empty.',
      );
    }

    await client
        .from('category_defect_pairs')
        .insert({
      'category_id':
      cleanCategoryId,
      'defect_id':
      cleanDefectId,
    });
  }

  static Future<void>
  deleteCategoryDefectPair({
    required String categoryPairId,
  }) async {
    final cleanId =
    categoryPairId.trim();

    if (cleanId.isEmpty) {
      throw Exception(
        'Category pair ID cannot be empty.',
      );
    }

    await client
        .from('category_defect_pairs')
        .delete()
        .eq(
      'category_defect_pair_id',
      cleanId,
    );
  }
  // ============================================================
  // BATCH DEFECT CATEGORY
  // ============================================================

  static Future<Map<String, dynamic>?>
  getBatchDefectCategory(
      String batchId,
      ) async {
    final cleanBatchId =
    batchId.trim();

    if (cleanBatchId.isEmpty) {
      throw Exception(
        'Batch ID cannot be empty.',
      );
    }

    final response = await client
        .from('batch_defect_categories')
        .select('''
          batch_id,
          category_id,
          defect_categories (
            category_id,
            category_name,
            is_active
          )
        ''')
        .eq(
      'batch_id',
      cleanBatchId,
    )
        .maybeSingle();

    if (response == null) {
      return null;
    }

    final result =
    Map<String, dynamic>.from(response);

    final category =
    result['defect_categories'];

    if (category is Map) {
      result['category'] =
      Map<String, dynamic>.from(category);
    }

    result.remove('defect_categories');

    return result;
  }

  static Future<void>
  assignBatchDefectCategory({
    required String batchId,
    required String categoryId,
  }) async {
    final cleanBatchId =
    batchId.trim();

    final cleanCategoryId =
    categoryId.trim();

    if (cleanBatchId.isEmpty) {
      throw Exception(
        'Batch ID cannot be empty.',
      );
    }

    if (cleanCategoryId.isEmpty) {
      throw Exception(
        'Defect category ID cannot be empty.',
      );
    }

    // Remove any existing category assignment
    // because each batch can have one category.
    await client
        .from('batch_defect_categories')
        .delete()
        .eq(
      'batch_id',
      cleanBatchId,
    );

    // Insert the new category assignment.
    await client
        .from('batch_defect_categories')
        .insert({
      'batch_id':
      cleanBatchId,
      'category_id':
      cleanCategoryId,
    });
  }
  static Future<void>
  removeBatchDefectCategory(
      String batchId,
      ) async {
    final cleanBatchId =
    batchId.trim();

    if (cleanBatchId.isEmpty) {
      throw Exception(
        'Batch ID cannot be empty.',
      );
    }

    await client
        .from('batch_defect_categories')
        .delete()
        .eq(
      'batch_id',
      cleanBatchId,
    );
  }

  static Future<List<Map<String, dynamic>>>
  getBatchCategoryPairs(
      String batchId,
      ) async {
    final cleanBatchId =
    batchId.trim();

    if (cleanBatchId.isEmpty) {
      throw Exception(
        'Batch ID cannot be empty.',
      );
    }

    final assignment =
    await getBatchDefectCategory(
      cleanBatchId,
    );

    if (assignment == null) {
      return [];
    }

    final categoryId =
    assignment['category_id']
        ?.toString()
        .trim();

    if (categoryId == null ||
        categoryId.isEmpty) {
      return [];
    }

    return getCategoryDefectPairs(
      categoryId,
    );
  }

  // ============================================================
  // PART DEFECT ASSOCIATIONS
  // ============================================================

  static Future<List<Map<String, dynamic>>>
  getPartDefects(
      String partId,
      ) async {
    final cleanPartId =
    partId.trim();

    if (cleanPartId.isEmpty) {
      throw Exception(
        'Part ID cannot be empty.',
      );
    }

    final response = await client
        .from('part_defects')
        .select('''
        part_defect_id,
        part_id,
        defect_id,
        defect_types (
          defect_id,
          defect_name,
          is_active
        )
      ''')
        .eq(
      'part_id',
      cleanPartId,
    )
        .order('created_at');

    return List<Map<String, dynamic>>.from(
      response,
    );
  }
  static Future<void>
  savePartDefects({
    required String partId,
    required List<Map<String, dynamic>> pairs,
  }) async {
    final cleanPartId =
    partId.trim();

    if (cleanPartId.isEmpty) {
      throw Exception(
        'Part ID cannot be empty.',
      );
    }

    await client
        .from('part_defects')
        .delete()
        .eq(
      'part_id',
      cleanPartId,
    );

    if (pairs.isEmpty) {
      return;
    }

    final rows =
    <Map<String, dynamic>>[];

    for (final pair in pairs) {
      final defectId =
          pair['defect_id']
              ?.toString()
              .trim() ??
              '';

      if (defectId.isEmpty) {
        continue;
      }

      rows.add({
        'part_id':
        cleanPartId,
        'defect_id':
        defectId,
      });
    }

    if (rows.isEmpty) {
      return;
    }

    await client
        .from('part_defects')
        .insert(rows);
  }
  static Future<void>
  savePartDefectPairs({
    required String partId,
    required List<Map<String, dynamic>> pairs,
  }) async {
    final cleanPartId =
    partId.trim();

    if (cleanPartId.isEmpty) {
      throw Exception(
        'Part ID cannot be empty.',
      );
    }

    if (pairs.isEmpty) {
      throw Exception(
        'At least one defect type is required.',
      );
    }

    await savePartDefects(
      partId: cleanPartId,
      pairs: pairs,
    );
  }
  // ============================================================
  // CANDIDATE OBSERVED DEFECTS
  // ============================================================

  static Future<void>
  saveObservationDefects({
    required String observationId,
    required List<Map<String, dynamic>> pairs,
  }) async {
    final cleanObservationId =
    observationId.trim();

    if (cleanObservationId.isEmpty) {
      throw Exception(
        'Observation ID cannot be empty.',
      );
    }

    await client
        .from('arr_observation_defects')
        .delete()
        .eq(
      'observation_id',
      cleanObservationId,
    );

    if (pairs.isEmpty) {
      return;
    }

    final rows = pairs.map((pair) {
      final defectId =
          pair['defect_id']?.toString().trim() ?? '';

      if (defectId.isEmpty) {
        throw Exception(
          'Every observed defect must contain a defect type.',
        );
      }

      return {
        'observation_id': cleanObservationId,
        'defect_id': defectId,
      };
    }).toList();

    await client
        .from('arr_observation_defects')
        .insert(rows);
  }

  static Future<List<Map<String, dynamic>>>
  getObservationDefects(
      String observationId,
      ) async {
    final cleanObservationId =
    observationId.trim();

    if (cleanObservationId.isEmpty) {
      throw Exception(
        'Observation ID cannot be empty.',
      );
    }

    final response = await client
        .from('arr_observation_defects')
        .select('''
        observation_defect_id,
        observation_id,
        defect_id,
        trail_no,
        defect_types (
          defect_id,
          defect_name,
          is_active
        )
      ''')
        .eq(
      'observation_id',
      cleanObservationId,
    )
        .order('trail_no')
        .order('created_at');

    return List<Map<String, dynamic>>.from(
      response,
    );
  }
  // ============================================================
  // EMPLOYEE
  // ============================================================

  static Future<Map<String, dynamic>?> getEmployeeByCode(
      String employeeCode,
      ) async {
    final response = await client
        .from('employees')
        .select()
        .eq('employee_code', employeeCode.trim())
        .maybeSingle();

    return response;
  }

// ============================================================
// GET EMPLOYEE BY ID
// ============================================================

  static Future<Map<String, dynamic>?> getEmployeeById(
      String employeeId,
      ) async {
    final response = await client
        .from('employees')
        .select()
        .eq('employee_id', employeeId)
        .maybeSingle();

    return response;
  }

  // ============================================================
  // CREATE EMPLOYEE
  // ============================================================

  static Future<Map<String, dynamic>> createEmployee({
    required String employeeCode,
    required String fullName,
    String? department,
    String? product,
  }) async {
    final response = await client
        .from('employees')
        .insert({
      'employee_code': employeeCode.trim(),
      'full_name': fullName.trim(),
      'department': department?.trim(),
      'product': product?.trim(),
    })
        .select()
        .single();

    return response;
  }

  // ============================================================
  // UPDATE EMPLOYEE DETAILS
  // ============================================================

  static Future<Map<String, dynamic>> updateEmployee({
    required String employeeId,
    required String fullName,
    String? department,
    String? product,
  }) async {
    final response = await client
        .from('employees')
        .update({
      'full_name': fullName.trim(),
      'department': department?.trim(),
      'product': product?.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('employee_id', employeeId)
        .select()
        .single();

    return response;
  }

  // ============================================================
  // EMPLOYEE PHOTO
  // ============================================================

  static Future<String> uploadEmployeePhoto({
    required String employeeCode,
    required Uint8List bytes,
  }) async {
    final safeCode = employeeCode.trim();

    final path = 'employees/$safeCode.jpg';

    await client.storage
        .from('arr-files')
        .uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(
        upsert: true,
        contentType: 'image/jpeg',
      ),
    );

    return path;
  }

  // ============================================================
  // SAVE EMPLOYEE PHOTO PATH
  // ============================================================

  static Future<void> updateEmployeePhotoPath({
    required String employeeId,
    required String photoPath,
  }) async {
    await client
        .from('employees')
        .update({
      'photo_path': photoPath,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('employee_id', employeeId);
  }

  // ============================================================
  // CREATE OR UPDATE EMPLOYEE PHOTO
  // ============================================================

  static Future<Map<String, dynamic>> saveEmployeePhoto({
    required String employeeId,
    required String employeeCode,
    required Uint8List bytes,
  }) async {
    final photoPath = await uploadEmployeePhoto(
      employeeCode: employeeCode,
      bytes: bytes,
    );

    await updateEmployeePhotoPath(
      employeeId: employeeId,
      photoPath: photoPath,
    );

    final employee = await getEmployeeByCode(employeeCode);

    if (employee == null) {
      throw Exception('Employee not found after saving photo.');
    }

    return employee;
  }

  // ============================================================
  // GET EMPLOYEE PHOTO URL
  // ============================================================

  // ============================================================
  // EMPLOYEE PHOTO URL
  // ============================================================

  static String getEmployeePhotoUrl(String photoPath) {
    return client.storage
        .from('arr-files')
        .getPublicUrl(photoPath);
  }

  /// Downloads the actual photo bytes using the authenticated
  /// Supabase client rather than relying on the public URL. This
  /// works even if the 'arr-files' bucket is private, and avoids
  /// the browser-side CORS/opaque-response issues that can make
  /// Image.network silently fail on Flutter Web. [photoPathOrUrl]
  /// may be either a raw storage path (e.g. "employees/E123.jpg")
  /// or a full public URL previously built by [getEmployeePhotoUrl]
  /// — the storage path is extracted automatically in the latter
  /// case.
  static Future<Uint8List> downloadEmployeePhotoBytes(
      String photoPathOrUrl,
      ) async {
    const marker = '/object/public/arr-files/';

    String path = photoPathOrUrl;

    final markerIndex = photoPathOrUrl.indexOf(marker);

    if (markerIndex != -1) {
      path = photoPathOrUrl.substring(markerIndex + marker.length);
    }

    return client.storage.from('arr-files').download(path);
  }

  // ============================================================
  // COMPLETE ARR
  // ============================================================

  static Future<Map<String, dynamic>> completeArr({
    required String employeeCode,
    required String batchId,
    required String product,
    required DateTime assessmentDate,

    required int falseAlertCount,
    required int missAlertCount,

    required double falseAlertPct,
    required double missRatePct,
    required double effectivenessPct,

    required double p1,
    required double p0,
    required double pChance,
    required double kappaPct,

    required String classification,

    required List<Map<String, dynamic>> observations,
  }) async {
    // ----------------------------------------------------------
    // Find employee
    // ----------------------------------------------------------

    final employee =
    await getEmployeeByCode(employeeCode);

    if (employee == null) {
      throw Exception(
        'Employee ${employeeCode.trim()} was not found.',
      );
    }

    final employeeId =
    employee['employee_id']?.toString();

    if (employeeId == null ||
        employeeId.isEmpty) {
      throw Exception(
        'Employee ID is missing for ${employeeCode.trim()}.',
      );
    }

    // ----------------------------------------------------------
    // Call PostgreSQL transaction
    // ----------------------------------------------------------

    final response = await client.rpc(
      'complete_arr',
      params: {
        'p_employee_id': employeeId,

        'p_batch_id': batchId,

        'p_product': product,

        'p_assessment_date':
        assessmentDate.toIso8601String().split('T').first,

        'p_false_alert_count':
        falseAlertCount,

        'p_miss_alert_count':
        missAlertCount,

        'p_false_alert_pct':
        falseAlertPct,

        'p_miss_rate_pct':
        missRatePct,

        'p_effectiveness_pct':
        effectivenessPct,

        'p_p1':
        p1,

        'p_p0':
        p0,

        'p_p_chance':
        pChance,

        'p_kappa_pct':
        kappaPct,

        'p_classification':
        classification,

        'p_observations':
        observations,
      },
    );

    if (response == null) {
      throw Exception(
        'ARR could not be saved.',
      );
    }

    // ----------------------------------------------------------
    // RPC returns one row because complete_arr()
    // uses RETURNS TABLE.
    // ----------------------------------------------------------

    if (response is List &&
        response.isNotEmpty) {
      return Map<String, dynamic>.from(
        response.first as Map,
      );
    }

    if (response is Map) {
      return Map<String, dynamic>.from(
        response,
      );
    }

    throw Exception(
      'Invalid response received while saving ARR.',
    );
  }


  // ============================================================
  // GET ARR RECORD
  // ============================================================

  static Future<Map<String, dynamic>?> getArrRecord(
      String arrId,
      ) async {
    final response = await client
        .from('arr_records')
        .select()
        .eq('arr_id', arrId)
        .maybeSingle();

    return response;
  }

  // ============================================================
  // GET ARR OBSERVATIONS
  // ============================================================

  // static Future<List<Map<String, dynamic>>>
  // getArrObservations(
  //     String arrId,
  //     ) async {
  //   final response = await client
  //       .from('arr_observations')
  //       .select()
  //       .eq('arr_id', arrId);
  //
  //   final observations =
  //   List<Map<String, dynamic>>.from(response);
  //
  //   // ----------------------------------------------------------
  //   // Sort observations using the actual part sequence.
  //   // DO NOT sort by part_id because part_id is a UUID.
  //   // ----------------------------------------------------------
  //
  //   if (observations.isEmpty) {
  //     return observations;
  //   }
  //
  //   final partIds = observations
  //       .map((observation) =>
  //       observation['part_id']?.toString())
  //       .whereType<String>()
  //       .where((id) => id.isNotEmpty)
  //       .toList();
  //
  //   if (partIds.isEmpty) {
  //     return observations;
  //   }
  //
  //   final parts = await client
  //       .from('parts')
  //       .select(
  //     'part_id, part_number, sequence_order',
  //   )
  //       .inFilter('part_id', partIds);
  //
  //   final sequenceMap = <String, int>{};
  //
  //   for (final part in parts) {
  //     final partId =
  //     part['part_id']?.toString();
  //
  //     final sequence =
  //     part['sequence_order'];
  //
  //     if (partId != null &&
  //         sequence is num) {
  //       sequenceMap[partId] =
  //           sequence.toInt();
  //     }
  //   }
  //
  //   observations.sort((a, b) {
  //     final aId =
  //         a['part_id']?.toString() ?? '';
  //
  //     final bId =
  //         b['part_id']?.toString() ?? '';
  //
  //     final aSequence =
  //         sequenceMap[aId] ?? 999999;
  //
  //     final bSequence =
  //         sequenceMap[bId] ?? 999999;
  //
  //     return aSequence.compareTo(
  //       bSequence,
  //     );
  //   });
  //
  //   return observations;
  // }

  // static Future<List<Map<String, dynamic>>>
  // getArrObservations(
  //     String arrId,
  //     ) async {
  //
  //   final response = await client
  //       .from('arr_observations')
  //       .select()
  //       .eq(
  //     'arr_id',
  //     arrId,
  //   );
  //
  //   final observations =
  //   List<Map<String, dynamic>>.from(
  //     response,
  //   );
  //
  //   if (observations.isEmpty) {
  //     return observations;
  //   }
  //
  //   // ==========================================================
  //   // SORT USING PART SEQUENCE
  //   // ==========================================================
  //
  //   final partIds =
  //   observations
  //       .map(
  //         (observation) =>
  //         observation['part_id']
  //             ?.toString(),
  //   )
  //       .whereType<String>()
  //       .where(
  //         (id) => id.isNotEmpty,
  //   )
  //       .toList();
  //
  //   final sequenceMap =
  //   <String, int>{};
  //
  //   if (partIds.isNotEmpty) {
  //
  //     final parts =
  //     await client
  //         .from('parts')
  //         .select(
  //       'part_id, part_number, sequence_order',
  //     )
  //         .inFilter(
  //       'part_id',
  //       partIds,
  //     );
  //
  //     for (final part
  //     in parts) {
  //
  //       final partId =
  //       part['part_id']
  //           ?.toString();
  //
  //       final sequence =
  //       part['sequence_order'];
  //
  //       if (partId != null &&
  //           sequence is num) {
  //         sequenceMap[partId] =
  //             sequence.toInt();
  //       }
  //     }
  //   }
  //
  //   observations.sort(
  //         (a, b) {
  //
  //       final aId =
  //           a['part_id']
  //               ?.toString() ??
  //               '';
  //
  //       final bId =
  //           b['part_id']
  //               ?.toString() ??
  //               '';
  //
  //       return (
  //           sequenceMap[aId] ??
  //               999999
  //       )
  //           .compareTo(
  //         sequenceMap[bId] ??
  //             999999,
  //       );
  //     },
  //   );
  //
  //   // ==========================================================
  //   // MASTER DEFECT PAIRS
  //   // ==========================================================
  //
  //   final masterDefectsByPart =
  //   <String, List<Map<String, dynamic>>>{};
  //
  //   if (partIds.isNotEmpty) {
  //
  //     final masterRows =
  //     await client
  //         .from('part_defects')
  //         .select('''
  //             part_id,
  //             defect_id,
  //             location_id,
  //             defect_types (
  //               defect_name
  //             ),
  //             defect_locations (
  //               location_name
  //             )
  //           ''')
  //         .inFilter(
  //       'part_id',
  //       partIds,
  //     );
  //
  //     for (final row
  //     in masterRows) {
  //
  //       final partId =
  //       row['part_id']
  //           ?.toString();
  //
  //       if (partId == null ||
  //           partId.isEmpty) {
  //         continue;
  //       }
  //
  //       masterDefectsByPart
  //           .putIfAbsent(
  //         partId,
  //             () => [],
  //       )
  //           .add({
  //         'defect_id':
  //         row['defect_id'],
  //
  //         'location_id':
  //         row['location_id'],
  //
  //         'defect_name':
  //         (row['defect_types']
  //         as Map?)
  //         ?['defect_name']
  //             ?.toString() ??
  //             '',
  //
  //         'location_name':
  //         (row['defect_locations']
  //         as Map?)
  //         ?['location_name']
  //             ?.toString() ??
  //             '',
  //       });
  //     }
  //   }
  //
  //   // ==========================================================
  //   // CANDIDATE OBSERVED DEFECT PAIRS
  //   // ==========================================================
  //
  //   final observationIds =
  //   observations
  //       .map(
  //         (observation) =>
  //         observation[
  //         'observation_id']
  //             ?.toString(),
  //   )
  //       .whereType<String>()
  //       .where(
  //         (id) => id.isNotEmpty,
  //   )
  //       .toList();
  //
  //   final observedDefectsByObservation =
  //   <String, List<Map<String, dynamic>>>{};
  //
  //   if (observationIds.isNotEmpty) {
  //
  //     final observedRows =
  //     await client
  //         .from(
  //       'arr_observation_defects',
  //     )
  //         .select('''
  //             observation_id,
  //             trail_no,
  //             defect_id,
  //             location_id,
  //             defect_types (
  //               defect_name
  //             ),
  //             defect_locations (
  //               location_name
  //             )
  //           ''')
  //         .inFilter(
  //       'observation_id',
  //       observationIds,
  //     );
  //
  //     for (final row
  //     in observedRows) {
  //
  //       final observationId =
  //       row['observation_id']
  //           ?.toString();
  //
  //       if (observationId == null ||
  //           observationId.isEmpty) {
  //         continue;
  //       }
  //
  //       observedDefectsByObservation
  //           .putIfAbsent(
  //         observationId,
  //             () => [],
  //       )
  //           .add({
  //         'trail_no':
  //         row['trail_no'],
  //
  //         'defect_id':
  //         row['defect_id'],
  //
  //         'location_id':
  //         row['location_id'],
  //
  //         'defect_name':
  //         (row['defect_types']
  //         as Map?)
  //         ?['defect_name']
  //             ?.toString() ??
  //             '',
  //
  //         'location_name':
  //         (row['defect_locations']
  //         as Map?)
  //         ?['location_name']
  //             ?.toString() ??
  //             '',
  //       });
  //     }
  //   }
  //
  //   // ==========================================================
  //   // ATTACH DEFECT DATA TO EACH OBSERVATION
  //   // ==========================================================
  //
  //   for (final observation
  //   in observations) {
  //
  //     final partId =
  //         observation['part_id']
  //             ?.toString() ??
  //             '';
  //
  //     final observationId =
  //         observation[
  //         'observation_id']
  //             ?.toString() ??
  //             '';
  //
  //     observation[
  //     'master_defects'] =
  //     List<Map<String, dynamic>>.from(
  //       masterDefectsByPart[
  //       partId] ??
  //           [],
  //     );
  //
  //     observation[
  //     'observed_defects'] =
  //     List<Map<String, dynamic>>.from(
  //       observedDefectsByObservation[
  //       observationId] ??
  //           [],
  //     );
  //   }
  //
  //   return observations;
  // }
  static Future<List<Map<String, dynamic>>>
  getArrObservations(
      String arrId,
      ) async {

    // ============================================================
    // 1. LOAD ARR OBSERVATIONS
    // ============================================================

    final response = await client
        .from('arr_observations')
        .select()
        .eq('arr_id', arrId);

    final observations =
    List<Map<String, dynamic>>.from(response);

    if (observations.isEmpty) {
      return observations;
    }

    // ============================================================
    // 2. GET PART IDS
    // ============================================================

    final partIds = observations
        .map(
          (observation) =>
          observation['part_id']?.toString(),
    )
        .whereType<String>()
        .where(
          (id) => id.isNotEmpty,
    )
        .toList();

    // ============================================================
    // 3. SORT USING PART SEQUENCE
    // ============================================================

    if (partIds.isNotEmpty) {

      final parts = await client
          .from('parts')
          .select(
        'part_id, part_number, sequence_order',
      )
          .inFilter(
        'part_id',
        partIds,
      );

      final sequenceMap =
      <String, int>{};

      for (final part in parts) {

        final partId =
        part['part_id']?.toString();

        final sequence =
        part['sequence_order'];

        if (partId != null &&
            sequence is num) {

          sequenceMap[partId] =
              sequence.toInt();
        }
      }

      observations.sort((a, b) {

        final aId =
            a['part_id']?.toString() ?? '';

        final bId =
            b['part_id']?.toString() ?? '';

        final aSequence =
            sequenceMap[aId] ?? 999999;

        final bSequence =
            sequenceMap[bId] ?? 999999;

        return aSequence.compareTo(
          bSequence,
        );
      });
    }

    // ============================================================
    // 4. LOAD MASTER DEFECT / LOCATION PAIRS
    // ============================================================

    final masterDefectRows =
    <Map<String, dynamic>>[];

    if (partIds.isNotEmpty) {

      final response =
      await client
          .from('part_defects')
          .select('''
            part_id,
            defect_id,
            defect_types (
              defect_name
            )
          ''')
          .inFilter(
        'part_id',
        partIds,
      );

      masterDefectRows.addAll(
        List<Map<String, dynamic>>.from(
          response,
        ),
      );
    }

    // ============================================================
    // 5. GET OBSERVATION IDS
    // ============================================================

    final observationIds = observations
        .map(
          (observation) =>
          observation['observation_id']?.toString(),
    )
        .whereType<String>()
        .where(
          (id) => id.isNotEmpty,
    )
        .toList();

    // ============================================================
    // 6. LOAD CANDIDATE OBSERVED DEFECT / LOCATION PAIRS
    // ============================================================

    final observedDefectRows =
    <Map<String, dynamic>>[];

    if (observationIds.isNotEmpty) {

      final response = await client
          .from('arr_observation_defects')
          .select('''
      observation_defect_id,
      observation_id,
      defect_id,
      trail_no,
      defect_types (
        defect_id,
        defect_name
      )
    ''')
          .inFilter(
        'observation_id',
        observationIds,
      )
          .order('created_at');
      observedDefectRows.addAll(
        List<Map<String, dynamic>>.from(
          response,
        ),
      );
    }

    // ============================================================
    // 7. ATTACH DEFECT DATA TO EACH OBSERVATION
    // ============================================================

    for (final observation in observations) {

      final partId =
          observation['part_id']?.toString() ?? '';

      final observationId =
          observation['observation_id']?.toString() ?? '';

      // ----------------------------------------------------------
      // MASTER PAIRS
      // ----------------------------------------------------------

      final masterPairs =
      masterDefectRows
          .where(
            (row) =>
        row['part_id']?.toString() ==
            partId,
      )
          .map(
            (row) {

              final defect =
              row['defect_types'];

              final defectMap =
              defect is Map
                  ? Map<String, dynamic>.from(
                defect,
              )
                  : <String, dynamic>{};

              return <String, dynamic>{
                'defect_id':
                row['defect_id'],

                'defect_name':
                defectMap['defect_name'],
              };
        },
      )
          .toList();

      // ----------------------------------------------------------
      // CANDIDATE OBSERVED PAIRS
      // ----------------------------------------------------------

      final observedPairs =
      observedDefectRows
          .where(
            (row) =>
        row['observation_id']
            ?.toString() ==
            observationId,
      )
          .map(
            (row) {

              final defect =
              row['defect_types'];

              final defectMap =
              defect is Map
                  ? Map<String, dynamic>.from(
                defect,
              )
                  : <String, dynamic>{};

              return <String, dynamic>{
                'trail_no':
                row['trail_no'],

                'defect_id':
                row['defect_id'],

                'defect_name':
                defectMap['defect_name'],
              };
        },
      )
          .toList();

      // ----------------------------------------------------------
      // ATTACH TO OBSERVATION
      // ----------------------------------------------------------

      observation['master_defects'] =
          masterPairs;

      observation['observed_defects'] =
          observedPairs;
    }

    return observations;
  }
  // ============================================================
  // GET COMPLETE ARR
  // ============================================================
  // ============================================================
  // GET FULL ARR RECORD (with observations + employee, fully
  // populated ArrRecord object). Used anywhere the complete
  // trail/part data is required for an already-completed ARR,
  // e.g. Cross Tab generation.
  // ============================================================
  static Future<Map<String, dynamic>>
  getCompleteArr(
      String arrId,
      ) async {
    final record =
    await getArrRecord(arrId);

    if (record == null) {
      throw Exception(
        'ARR record was not found.',
      );
    }

    final observations =
    await getArrObservations(arrId);

    Map<String, dynamic>? employee;

    final employeeId =
    record['employee_id']?.toString();

    if (employeeId != null &&
        employeeId.isNotEmpty) {
      employee =
      await getEmployeeById(employeeId);
    }

    return {
      'record': record,
      'observations': observations,
      'employee': employee,
    };
  }

  // ============================================================
  // GET ALL PREVIOUS ARR RECORDS
  // ============================================================

  // ============================================================
  // GET EMPLOYEE FOR ARR
  // ============================================================

  static Future<Map<String, dynamic>?> getEmployeeForArr(
      String employeeId,
      ) async {
    final cleanEmployeeId = employeeId.trim();

    if (cleanEmployeeId.isEmpty) {
      return null;
    }

    return await getEmployeeById(cleanEmployeeId);
  }

  // ============================================================
  // GET PREVIOUS ARR RECORDS
  // Lightweight query used by Previous ARR screen.
  //
  // IMPORTANT:
  // - Does NOT load employees individually.
  // - Does NOT load observations.
  // - Does NOT sort by assessment time.
  // - Uses attempt_number + arr_id for stable ordering.
  // - Detailed data is loaded only when an ARR is opened.
  // ============================================================

  static Future<List<Map<String, dynamic>>>
  getPreviousArrs() async {

    final response = await client
        .from('arr_records')
        .select('''
        arr_id,
        certificate_number,
        employee_id,
        employee_code_snap,
        batch_id,
        batch_name_snap,
        product,
        attempt_number,
        assessment_date,
        false_alert_count,
        miss_alert_count,
        false_alert_pct,
        miss_rate_pct,
        effectiveness_pct,
        p1,
        p0,
        p_chance,
        kappa_pct,
        classification
      ''')
        .order(
      'attempt_number',
      ascending: false,
    )
        .order(
      'arr_id',
      ascending: false,
    );

    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================================
  // GET ALL PREVIOUS ARR RECORDS
  // ============================================================
  // ============================================================
// GET ALL PREVIOUS ARR RECORDS
// Lightweight query for Previous ARR list.
// Employee and observation details are loaded only when
// a specific ARR is opened.
// ============================================================

  // ============================================================
// GET LIGHTWEIGHT PREVIOUS ARR LIST
//
// Only fields required to display the Previous ARR list are
// fetched here.
//
// IMPORTANT:
// - No employee query
// - No observation query
// - No complete ARR loading
// - No time-based sorting
//
// Full ARR details are loaded only after the user selects
// one specific record.
// ============================================================

  static Future<List<Map<String, dynamic>>>
  getPreviousArrList() async {

    final response = await client
        .from('arr_records')
        .select('''
        arr_id,
        certificate_number,
        employee_id,
        employee_code_snap,
        batch_id,
        batch_name_snap,
        product,
        attempt_number,
        assessment_date,
        false_alert_pct,
        miss_rate_pct,
        effectiveness_pct,
        kappa_pct,
        classification
      ''')
        .order(
      'attempt_number',
      ascending: true,
    )
        .order(
      'certificate_number',
      ascending: true,
    );

    final records =
    List<Map<String, dynamic>>.from(response);

    // ------------------------------------------------------------
    // LOAD EMPLOYEE NAMES IN ONE QUERY
    // ------------------------------------------------------------

    final employeeIds = records
        .map(
          (record) =>
          record['employee_id']?.toString().trim(),
    )
        .whereType<String>()
        .where(
          (id) => id.isNotEmpty,
    )
        .toSet()
        .toList();

    if (employeeIds.isEmpty) {
      return records
          .map(
            (record) => {
          ...record,
          'employee_name': '',
        },
      )
          .toList();
    }

    final employeeResponse = await client
        .from('employees')
        .select('employee_id, full_name')
        .inFilter(
      'employee_id',
      employeeIds,
    );

    final employeeNameMap =
    <String, String>{};

    for (final employee in employeeResponse) {
      final employeeId =
      employee['employee_id']
          ?.toString()
          .trim();

      final fullName =
          employee['full_name']
              ?.toString()
              .trim() ??
              '';

      if (employeeId != null &&
          employeeId.isNotEmpty) {
        employeeNameMap[employeeId] =
            fullName;
      }
    }

    // ------------------------------------------------------------
    // ATTACH EMPLOYEE NAME TO EACH ARR RECORD
    // ------------------------------------------------------------

    for (final record in records) {
      final employeeId =
          record['employee_id']
              ?.toString()
              .trim() ??
              '';

      record['employee_name'] =
          employeeNameMap[employeeId] ?? '';
    }

    return records;
  }

// ============================================================
// GET ONE COMPLETE ARR
//
// This is intentionally called only when the user opens
// one specific Previous ARR record.
// ============================================================

  static Future<Map<String, dynamic>>
  getPreviousArrDetail(
      String arrId,
      ) async {

    final cleanArrId = arrId.trim();

    if (cleanArrId.isEmpty) {
      throw Exception(
        'ARR ID is missing.',
      );
    }

    final record =
    await getArrRecord(cleanArrId);

    if (record == null) {
      throw Exception(
        'ARR record was not found.',
      );
    }

    final observations =
    await getArrObservations(cleanArrId);

    Map<String, dynamic>? employee;

    final employeeId =
    record['employee_id']?.toString();

    if (employeeId != null &&
        employeeId.isNotEmpty) {

      employee =
      await getEmployeeById(employeeId);
    }

    return {
      'record': record,
      'observations': observations,
      'employee': employee,
    };
  }

// ============================================================
// GET DASHBOARD STATISTICS
//
// Dashboard statistics are completely independent from
// Previous ARR records.
//
// Only aggregate counts are requested from the database.
// ============================================================

  static Future<Map<String, int>>
  getArrDashboardStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {

    var query = client
        .from('arr_records')
        .select('classification');

    if (startDate != null &&
        endDate != null &&
        startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day) {

      final dateString =
          startDate
              .toIso8601String()
              .split('T')
              .first;

      query = query.eq(
        'assessment_date',
        dateString,
      );

    } else {

      if (startDate != null) {
        query = query.gte(
          'assessment_date',
          startDate
              .toIso8601String()
              .split('T')
              .first,
        );
      }

      if (endDate != null) {
        query = query.lte(
          'assessment_date',
          endDate
              .toIso8601String()
              .split('T')
              .first,
        );
      }
    }

    final response = await query;

    final records =
    List<Map<String, dynamic>>.from(response);

    int total = records.length;

    int passed = 0;
    int failed = 0;

    for (final record in records) {

      final classification =
      record['classification']
          ?.toString()
          .trim()
          .toUpperCase();

      if (classification == 'ACCEPTABLE' ||
          classification ==
              'MARGINALLY ACCEPTABLE') {

        passed++;

      } else if (
      classification == 'UNACCEPTABLE' ||
          classification == 'NOT ACCEPTABLE') {

        failed++;
      }
    }

    return {
      'total': total,
      'passed': passed,
      'failed': failed,
    };
  }

  // ============================================================
  // AUDIT MODULE - FastAPI implementation
  // All active Audit screens use this section. Other EQMS modules
  // continue using the Supabase client above.
  // ============================================================

  static Future<dynamic> _auditOperation(
    String operation, [
    Map<String, dynamic> payload = const {},
  ]) => AuditApiClient.operation(operation, payload);

  static Future<Map<String, int>> getAuditDashboardStats() async {
    final result = Map<String, dynamic>.from(
      await _auditOperation('dashboard_stats') as Map,
    );
    return result.map((key, value) => MapEntry(key, (value as num).toInt()));
  }

  static Future<Map<String, dynamic>> createAudit({
    required String typeId,
    required String auditDate,
    required String vendor,
    required String site,
    required String lob,
    String? program,
    String? line,
    String? apn,
    required String auditorName,
    String? auditorEmail,
    required double totalAuditHours,
  }) async {
    if (totalAuditHours <= 0) throw Exception('Total Audit Hours must be greater than 0.');
    return Map<String, dynamic>.from(await _auditOperation('create_audit', {
      'type_id': typeId,
      'audit_date': auditDate,
      'vendor': vendor,
      'site': site,
      'lob': lob,
      'program': program,
      'line': line,
      'apn': apn,
      'auditor_name': auditorName,
      'auditor_email': auditorEmail,
      'total_audit_hours': totalAuditHours,
    }) as Map);
  }

  static Future<Map<String, dynamic>?> getAuditById(String auditId) async {
    final result = await _auditOperation('get_audit_by_id', {'audit_id': auditId});
    return result == null ? null : Map<String, dynamic>.from(result as Map);
  }

  static Future<List<Map<String, dynamic>>> getAuditCategories(String typeId) async =>
      _auditMapList(await _auditOperation('get_audit_categories', {'type_id': typeId}));

  static Future<List<Map<String, dynamic>>> getAuditCategoryProgress(String auditId) async =>
      _auditMapList(await _auditOperation('get_category_progress', {'audit_id': auditId}));

  static Future<Map<String, dynamic>> createAuditCategoryProgress({
    required String auditId,
    required String categoryId,
  }) async => Map<String, dynamic>.from(await _auditOperation('create_category_progress', {
        'audit_id': auditId,
        'category_id': categoryId,
      }) as Map);

  static Future<void> addAuditCategoryTime({
    required String auditId,
    required double additionalHours,
  }) async {
    await _auditOperation('add_category_time', {
      'audit_id': auditId,
      'additional_hours': additionalHours,
    });
  }

  static Future<Map<String, dynamic>?> getAuditCategoryById(String categoryId) async {
    final result = await _auditOperation('get_category_by_id', {'category_id': categoryId});
    return result == null ? null : Map<String, dynamic>.from(result as Map);
  }

  static Future<List<Map<String, dynamic>>> getAuditQuestions(String categoryId) async =>
      _auditMapList(await _auditOperation('get_questions', {'category_id': categoryId}));

  static Future<List<Map<String, dynamic>>> getAuditChecklistAnswers({
    required String auditId,
    required List<String> questionIds,
  }) async => _auditMapList(await _auditOperation('get_checklist_answers', {
        'audit_id': auditId,
        'question_ids': questionIds,
      }));

  static Future<Map<String, dynamic>> saveAuditChecklistAnswer({
    required String auditId,
    required String questionId,
    required String answer,
    String? description,
    String? defectType,
  }) async {
    if (answer != 'Yes' && answer != 'No') throw Exception('Answer must be either Yes or No.');
    if (answer == 'No' && (description == null || description.trim().isEmpty)) {
      throw Exception('Description is required for a No answer.');
    }
    if (answer == 'No' && !['Critical', 'Major', 'Minor'].contains(defectType)) {
      throw Exception('Valid Defect Type is required for a No answer.');
    }
    return Map<String, dynamic>.from(await _auditOperation('save_checklist_answer', {
      'audit_id': auditId,
      'question_id': questionId,
      'answer': answer,
      'description': description,
      'defect_type': answer == 'Yes' ? null : defectType,
    }) as Map);
  }

  static Future<Map<String, dynamic>> completeAuditCategory({
    required String auditId,
    required String categoryId,
  }) async => Map<String, dynamic>.from(await _auditOperation('complete_category', {
        'audit_id': auditId,
        'category_id': categoryId,
      }) as Map);

  static Future<bool> submitAudit(String auditId) async =>
      await _auditOperation('submit_audit', {'audit_id': auditId}) == true;

  static Future<List<Map<String, dynamic>>> getAuditMilItems(String auditId) async =>
      _auditMapList(await _auditOperation('get_mil_items', {'audit_id': auditId}));

  static Future<Map<String, dynamic>> updateAuditMilItem({
    required String milItemId,
    String? rootCause,
    String? correctiveAction,
    String? driName,
    String? driMail,
    String? deadline,
    String? overallStatus,
  }) async => Map<String, dynamic>.from(await _auditOperation('update_mil_item', {
        'mil_item_id': milItemId,
        'root_cause': rootCause,
        'corrective_action': correctiveAction,
        'dri_name': driName,
        'dri_mail': driMail,
        'deadline': deadline,
        'overall_status': overallStatus,
      }) as Map);

  static Future<bool> closeAuditMil(String auditId) async =>
      await _auditOperation('close_mil', {'audit_id': auditId}) == true;

  static Future<Map<String, dynamic>> verifyAuditAdminLogin({
    required String email,
    required String password,
  }) => AuditApiClient.login(email: email, password: password);

  static Future<List<Map<String, dynamic>>> getAdminAuditTypes({
    required String sessionToken,
  }) async => _auditMapList(await _auditOperation('admin_get_audit_types'));

  static Future<Map<String, dynamic>> createAdminAuditType({
    required String sessionToken,
    required String auditType,
    String? description,
    required bool active,
  }) async => Map<String, dynamic>.from(await _auditOperation('admin_create_audit_type', {
        'audit_type': auditType,
        'description': description,
        'active': active,
      }) as Map);

  static Future<Map<String, dynamic>> updateAdminAuditType({
    required String sessionToken,
    required String typeId,
    required String auditType,
    String? description,
    required bool active,
  }) async => Map<String, dynamic>.from(await _auditOperation('admin_update_audit_type', {
        'type_id': typeId,
        'audit_type': auditType,
        'description': description,
        'active': active,
      }) as Map);

  static Future<bool> deleteAdminAuditType({
    required String sessionToken,
    required String typeId,
  }) async => await _auditOperation('admin_delete_audit_type', {'type_id': typeId}) == true;

  static Future<List<Map<String, dynamic>>> getAdminAuditQuestions({
    required String sessionToken,
    required String categoryId,
  }) async => _auditMapList(await _auditOperation('admin_get_audit_questions', {
        'category_id': categoryId,
      }));

  static Future<Map<String, dynamic>> createAdminAuditQuestion({
    required String sessionToken,
    required String categoryId,
    required int questionNumber,
    required String question,
    String? description,
    required bool active,
  }) async => Map<String, dynamic>.from(await _auditOperation('admin_create_audit_question', {
        'category_id': categoryId,
        'question_number': questionNumber,
        'question': question,
        'description': description,
        'sort_order': 0,
        'active': active,
      }) as Map);

  static Future<Map<String, dynamic>> updateAdminAuditQuestion({
    required String sessionToken,
    required String questionId,
    required int questionNumber,
    required String question,
    String? description,
    required bool active,
  }) async => Map<String, dynamic>.from(await _auditOperation('admin_update_audit_question', {
        'question_id': questionId,
        'question_number': questionNumber,
        'question': question,
        'description': description,
        'sort_order': 0,
        'active': active,
      }) as Map);

  static Future<bool> deleteAdminAuditQuestion({
    required String sessionToken,
    required String questionId,
  }) async => await _auditOperation('admin_delete_audit_question', {'question_id': questionId}) == true;

  static Future<List<Map<String, dynamic>>> getAdminAuditCategories({
    required String sessionToken,
    required String typeId,
  }) async => _auditMapList(await _auditOperation('admin_get_audit_categories', {
        'type_id': typeId,
      }));

  static Future<Map<String, dynamic>> createAdminAuditCategory({
    required String sessionToken,
    required String typeId,
    required String categoryName,
    String? description,
    required bool active,
  }) async => Map<String, dynamic>.from(await _auditOperation('admin_create_audit_category', {
        'type_id': typeId,
        'category_name': categoryName,
        'description': description,
        'sort_order': 0,
        'active': active,
      }) as Map);

  static Future<Map<String, dynamic>> updateAdminAuditCategory({
    required String sessionToken,
    required String categoryId,
    required String categoryName,
    String? description,
    required bool active,
  }) async => Map<String, dynamic>.from(await _auditOperation('admin_update_audit_category', {
        'category_id': categoryId,
        'category_name': categoryName,
        'description': description,
        'sort_order': 0,
        'active': active,
      }) as Map);

  static Future<bool> deleteAdminAuditCategory({
    required String sessionToken,
    required String categoryId,
  }) async => await _auditOperation('admin_delete_audit_category', {'category_id': categoryId}) == true;

  static Future<Map<String, dynamic>> getAuditReport(String auditId) async =>
      Map<String, dynamic>.from(await _auditOperation('get_audit_report', {'audit_id': auditId}) as Map);

  static Future<List<Map<String, dynamic>>> getAllAudits() async =>
      _auditMapList(await _auditOperation('get_all_audits'));

  static Future<List<Map<String, dynamic>>> getAdminAuditors({
    required String sessionToken,
  }) => AuditApiClient.listAuditors();

  static Future<Map<String, dynamic>> createAdminAuditor({
    required String sessionToken,
    required String auditorName,
    required String employeeId,
    required String email,
    required bool active,
  }) => AuditApiClient.createAuditor(
        auditorName: auditorName,
        employeeId: employeeId,
        email: email,
        active: active,
      );

  static Future<Map<String, dynamic>> updateAdminAuditor({
    required String sessionToken,
    required String auditorId,
    required String auditorName,
    required String employeeId,
    required String email,
    required bool active,
  }) => AuditApiClient.updateAuditor(
        auditorId: auditorId,
        auditorName: auditorName,
        employeeId: employeeId,
        email: email,
        active: active,
      );

  static Future<bool> deleteAdminAuditor({
    required String sessionToken,
    required String auditorId,
  }) async {
    await AuditApiClient.deleteAuditor(auditorId);
    return true;
  }

  static Future<List<Map<String, dynamic>>> getActiveAuditors() async =>
      _auditMapList(await _auditOperation('get_active_auditors'));

  static Future<List<Map<String, dynamic>>> getAdminAuditMasterData({
    required String sessionToken,
  }) async => _auditMapList(await _auditOperation('admin_get_audit_master_data'));

  static Future<List<Map<String, dynamic>>> getActiveAuditTypes() async =>
      _auditMapList(await _auditOperation('get_active_audit_types'));

  static Future<Map<String, dynamic>> createAdminAuditMasterData({
    required String sessionToken,
    required String masterName,
    required String? auditTypeId,
    required String auditTypeName,
    required bool active,
  }) async => Map<String, dynamic>.from(await _auditOperation('admin_create_audit_master_data', {
        'master_name': masterName,
        'audit_type_id': auditTypeId,
        'audit_type_name': auditTypeName,
        'active': active,
      }) as Map);

  static Future<Map<String, dynamic>> updateAdminAuditMasterData({
    required String sessionToken,
    required String masterId,
    required String masterName,
    required String? auditTypeId,
    required String auditTypeName,
    required bool active,
  }) async => Map<String, dynamic>.from(await _auditOperation('admin_update_audit_master_data', {
        'master_id': masterId,
        'master_name': masterName,
        'audit_type_id': auditTypeId,
        'audit_type_name': auditTypeName,
        'active': active,
      }) as Map);

  static Future<bool> deleteAdminAuditMasterData({
    required String sessionToken,
    required String masterId,
  }) async => await _auditOperation('admin_delete_audit_master_data', {'master_id': masterId}) == true;

  static Future<List<Map<String, dynamic>>> getAllAuditSchedules() async =>
      _auditMapList(await _auditOperation('get_all_audit_schedules'));

  static Future<Map<String, dynamic>> createAuditSchedule({
    required DateTime auditDate,
    String? typeId,
    required String? masterId,
    required String masterDataName,
    required String? auditorId,
    required String auditorName,
    String? auditorEmail,
    required String status,
    String? notes,
  }) async => Map<String, dynamic>.from(await _auditOperation('create_audit_schedule', {
        'audit_date': auditDate.toIso8601String().split('T').first,
        'type_id': typeId,
        'master_id': masterId,
        'master_data_name': masterDataName.trim(),
        'auditor_id': auditorId,
        'auditor_name': auditorName.trim(),
        'auditor_email': auditorEmail,
        'status': status,
        'notes': notes,
      }) as Map);

  static Future<Map<String, dynamic>> updateAuditSchedule({
    required String scheduleId,
    required DateTime auditDate,
    String? typeId,
    required String? masterId,
    required String masterDataName,
    required String? auditorId,
    required String auditorName,
    String? auditorEmail,
    required String status,
    String? notes,
  }) async => Map<String, dynamic>.from(await _auditOperation('update_audit_schedule', {
        'schedule_id': scheduleId,
        'audit_date': auditDate.toIso8601String().split('T').first,
        'type_id': typeId,
        'master_id': masterId,
        'master_data_name': masterDataName.trim(),
        'auditor_id': auditorId,
        'auditor_name': auditorName.trim(),
        'auditor_email': auditorEmail,
        'status': status,
        'notes': notes,
      }) as Map);

  static Future<Map<String, dynamic>> updateAuditScheduleStatus({
    required String scheduleId,
    required String status,
  }) async => Map<String, dynamic>.from(await _auditOperation('update_audit_schedule_status', {
        'schedule_id': scheduleId,
        'status': status,
      }) as Map);

  static Future<bool> deleteAuditSchedule({required String scheduleId}) async =>
      await _auditOperation('delete_audit_schedule', {'schedule_id': scheduleId}) == true;

  static Future<bool> deleteAdminAudit({
    required String sessionToken,
    required String auditId,
  }) async => await _auditOperation('delete_admin_audit', {'audit_id': auditId}) == true;

  static Future<Map<String, dynamic>> getAuditMilStatus(String auditId) async =>
      Map<String, dynamic>.from(await _auditOperation('get_audit_mil_status', {'audit_id': auditId}) as Map);

  static Future<List<Map<String, dynamic>>> repairMissingAuditMilNumbers(
    List<Map<String, dynamic>> audits,
  ) async {
    final response = await _auditOperation('repair_missing_mil_numbers', {'audits': audits});
    final repaired = <String, String>{};
    if (response is Map && response['repaired'] is List) {
      for (final item in response['repaired'] as List) {
        if (item is Map) repaired[item['audit_id'].toString()] = item['mil_number'].toString();
      }
    }
    return audits.map((audit) {
      final copy = Map<String, dynamic>.from(audit);
      final id = copy['audit_id']?.toString();
      if (id != null && repaired.containsKey(id)) copy['mil_number'] = repaired[id];
      return copy;
    }).toList();
  }

  static List<Map<String, dynamic>> _auditMapList(dynamic value) {
    if (value is! List) throw Exception('Unexpected response from Audit API.');
    return value.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }


  static Future<void> adminDeleteArrRecord(
      String arrId,
      ) async {
    final cleanId = arrId.trim();

    if (cleanId.isEmpty) {
      throw Exception(
        'ARR ID is required.',
      );
    }

    final response = await client.rpc(
      'admin_delete_arr_record',
      params: {
        'p_arr_id': cleanId,
      },
    );

    if (response != true) {
      throw Exception(
        'ARR record could not be deleted.',
      );
    }
  }
  static List<Map<String, dynamic>>
  buildArrDefectCorrelationRows(
      List<Map<String, dynamic>> observations,
      ) {
    final rows =
    <Map<String, dynamic>>[];

    for (final observation in observations) {

      final partNo =
          observation['part_number_snap']
              ?.toString() ??
              '-';

      final masterStatus =
          int.tryParse(
            observation[
            'master_status_snapshot']
                ?.toString() ??
                '',
          ) ??
              0;

      final masterDefects =
      List<Map<String, dynamic>>.from(
        observation['master_defects']
        as List? ??
            [],
      );

      final observedDefects =
      List<Map<String, dynamic>>.from(
        observation['observed_defects']
        as List? ??
            [],
      );

      for (int trail = 1;
      trail <= 3;
      trail++) {

        final answerKey =
            'trail$trail';

        final userAnswer =
            int.tryParse(
              observation[answerKey]
                  ?.toString() ??
                  '',
            ) ??
                0;

        final observedForTrail =
        observedDefects
            .where(
              (defect) =>
          int.tryParse(
            defect['trail_no']
                ?.toString() ??
                '',
          ) ==
              trail,
        )
            .toList();

        final selectedDefectNames =
        observedForTrail
            .map(
              (defect) =>
          defect['defect_name']
              ?.toString()
              .trim() ??
              '',
        )
            .where(
              (name) => name.isNotEmpty,
        )
            .toList();

        final masterDefectNames =
        masterDefects
            .map(
              (defect) =>
          defect['defect_name']
              ?.toString()
              .trim() ??
              '',
        )
            .where(
              (name) => name.isNotEmpty,
        )
            .toList();

        // --------------------------------------------------------
        // CASE 1
        //
        // Master = NO
        // User = YES
        // A defect was selected by user
        // --------------------------------------------------------

        if (masterStatus == 0 &&
            userAnswer == 1 &&
            selectedDefectNames.isNotEmpty) {

          rows.add({
            'part_no': partNo,
            'trail': trail,
            'master_status': 0,
            'user_status': 1,
            'selected_defect':
            selectedDefectNames.join(', '),
            'master_defect':
            masterDefectNames.isEmpty
                ? '-'
                : masterDefectNames.join(', '),
            'correlation':
            'User selected YES for Master NO with defect',
          });

          continue;
        }

        // --------------------------------------------------------
        // CASE 2
        //
        // Master = NO
        // User = NO
        //
        // Show only when the selected defect does not match
        // the master defect.
        // --------------------------------------------------------

        if (masterStatus == 0 &&
            userAnswer == 0 &&
            selectedDefectNames.isNotEmpty) {

          final selectedSet =
          selectedDefectNames
              .map(
                (name) =>
                name.toLowerCase(),
          )
              .toSet();

          final masterSet =
          masterDefectNames
              .map(
                (name) =>
                name.toLowerCase(),
          )
              .toSet();

          final correctDefect =
              selectedSet.length ==
                  masterSet.length &&
                  selectedSet
                      .containsAll(
                    masterSet,
                  );

          if (!correctDefect) {
            rows.add({
              'part_no': partNo,
              'trail': trail,
              'master_status': 0,
              'user_status': 0,
              'selected_defect':
              selectedDefectNames.join(', '),
              'master_defect':
              masterDefectNames.isEmpty
                  ? '-'
                  : masterDefectNames.join(', '),
              'correlation':
              'User selected NO with wrong defect compared to Master',
            });
          }

          continue;
        }

        // --------------------------------------------------------
        // CASE 3
        //
        // Master = YES
        // User = NO
        // User selected defect
        // --------------------------------------------------------

        if (masterStatus == 1 &&
            userAnswer == 0 &&
            selectedDefectNames.isNotEmpty) {

          rows.add({
            'part_no': partNo,
            'trail': trail,
            'master_status': 1,
            'user_status': 0,
            'selected_defect':
            selectedDefectNames.join(', '),
            'master_defect':
            masterDefectNames.isEmpty
                ? '-'
                : masterDefectNames.join(', '),
            'correlation':
            'User selected NO with defect for Master YES',
          });
        }
      }
    }

    return rows;
  }
}
