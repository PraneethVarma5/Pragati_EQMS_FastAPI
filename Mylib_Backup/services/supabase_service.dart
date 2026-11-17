import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

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
    await client
        .from('batches')
        .delete()
        .eq('batch_id', batchId.trim());
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

  static Future<List<Map<String, dynamic>>>
  getArrObservations(
      String arrId,
      ) async {
    final response = await client
        .from('arr_observations')
        .select()
        .eq('arr_id', arrId);

    final observations =
    List<Map<String, dynamic>>.from(response);

    // ----------------------------------------------------------
    // Sort observations using the actual part sequence.
    // DO NOT sort by part_id because part_id is a UUID.
    // ----------------------------------------------------------

    if (observations.isEmpty) {
      return observations;
    }

    final partIds = observations
        .map((observation) =>
        observation['part_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();

    if (partIds.isEmpty) {
      return observations;
    }

    final parts = await client
        .from('parts')
        .select(
      'part_id, part_number, sequence_order',
    )
        .inFilter('part_id', partIds);

    final sequenceMap = <String, int>{};

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

    return observations;
  }

  // ============================================================
  // GET COMPLETE ARR
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

    return List<Map<String, dynamic>>.from(response);
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
}