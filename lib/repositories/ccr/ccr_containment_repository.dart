
import '../../models/ccr/ccr_containment.dart';
import '../../services/ccr/ccr_api_client.dart';

class CcrContainmentRepository {
  CcrContainmentRepository();

  // ============================================================
  // GET CONTAINMENT
  // ============================================================

  Future<CcrContainment?> getContainment(
      String ccrId,
      ) async {
    final cleanId = ccrId.trim();

    if (cleanId.isEmpty) {
      throw Exception('CCR ID is missing.');
    }

    final response = await CcrApiClient.get(
      '/cases/$cleanId/containment',
    );

    if (response == null) {
      return null;
    }

    if (response is! Map) {
      throw Exception(
        'Invalid response received while loading containment.',
      );
    }

    return CcrContainment.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  // ============================================================
  // GET SORTING RESULTS
  // ============================================================

  Future<List<CcrContainmentSorting>> getSortingResults(
      String containmentId,
      ) async {
    final cleanId = containmentId.trim();

    if (cleanId.isEmpty) {
      throw Exception('Containment ID is missing.');
    }

    final response = await CcrApiClient.get(
      '/containment/$cleanId/sorting',
    );

    if (response is! List) {
      throw Exception(
        'Invalid response received while loading sorting results.',
      );
    }

    return response
        .whereType<Map>()
        .map(
          (item) => CcrContainmentSorting.fromMap(
        Map<String, dynamic>.from(item),
      ),
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
      throw Exception('CCR ID is missing.');
    }

    final data = <String, dynamic>{
      'ccr_id': cleanId,
      'sorting_activity': _nullableText(sortingActivity),
      'sorting_learnings': _nullableText(sortingLearnings),
      'customer_protection_action':
      _nullableText(customerProtectionAction),
      'recover_prq_schedule': _nullableText(recoverPrqSchedule),
      'first_certified_good_shipment':
      _nullableText(firstCertifiedGoodShipment),
      'target_eta': targetEta?.toIso8601String().split('T').first,
    };

    if (status != null && status.trim().isNotEmpty) {
      data['status'] = status.trim();
    }

    final response = await CcrApiClient.put(
      '/cases/$cleanId/containment',
      body: {
        'data': data,
      },
    );

    if (response is! Map) {
      throw Exception(
        'Invalid response received while saving containment.',
      );
    }

    return CcrContainment.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  // ============================================================
  // SAVE SORTING ROW
  // ============================================================

  Future<CcrContainmentSorting> saveSortingRow({
    required String containmentId,
    required String? location,
    required double? qtyNg,
    required double? qtySorted,
    required DateTime? sortingDate,
    required String? dri,
  }) async {
    final cleanId = containmentId.trim();

    if (cleanId.isEmpty) {
      throw Exception('Containment ID is missing.');
    }

    final response = await CcrApiClient.post(
      '/sorting',
      body: {
        'data': {
          'containment_id': cleanId,
          'location': _nullableText(location),
          'qty_ng': qtyNg,
          'qty_sorted': qtySorted,
          'sorting_date':
          sortingDate?.toIso8601String().split('T').first,
          'dri': _nullableText(dri),
        },
      },
    );

    if (response is! Map) {
      throw Exception(
        'Invalid response received while saving sorting record.',
      );
    }

    return CcrContainmentSorting.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  // ============================================================
  // UPDATE SORTING ROW
  // ============================================================

  Future<CcrContainmentSorting> updateSortingRow({
    required String id,
    required String? location,
    required double? qtyNg,
    required double? qtySorted,
    required DateTime? sortingDate,
    required String? dri,
  }) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      throw Exception('Sorting row ID is missing.');
    }

    final response = await CcrApiClient.patch(
      '/sorting/$cleanId',
      body: {
        'data': {
          'location': _nullableText(location),
          'qty_ng': qtyNg,
          'qty_sorted': qtySorted,
          'sorting_date':
          sortingDate?.toIso8601String().split('T').first,
          'dri': _nullableText(dri),
        },
      },
    );

    if (response is! Map) {
      throw Exception(
        'Invalid response received while updating sorting record.',
      );
    }

    return CcrContainmentSorting.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  // ============================================================
  // DELETE SORTING ROW
  // ============================================================

  Future<void> deleteSortingRow(String id) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      throw Exception('Sorting row ID is missing.');
    }

    await CcrApiClient.delete(
      '/sorting/$cleanId',
    );
  }

  // ============================================================
  // COMPLETE CONTAINMENT
  // ============================================================

  Future<void> completeContainment(String ccrId) async {
    final cleanId = ccrId.trim();

    if (cleanId.isEmpty) {
      throw Exception('CCR ID is missing.');
    }

    await CcrApiClient.post(
      '/cases/$cleanId/containment/complete',
    );
  }

  // ============================================================
  // STRING HELPER
  // ============================================================

  String? _nullableText(String? value) {
    final clean = value?.trim();

    if (clean == null || clean.isEmpty) {
      return null;
    }

    return clean;
  }
}
