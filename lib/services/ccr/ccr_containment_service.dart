import '../../models/ccr/ccr_containment.dart';
import '../../repositories/ccr/ccr_containment_repository.dart';

class CcrContainmentService {
  CcrContainmentService({
    CcrContainmentRepository? repository,
  }) : _repository =
      repository ?? CcrContainmentRepository();

  final CcrContainmentRepository _repository;

  Future<CcrContainment?> getContainment(
      String ccrId) {
    return _repository.getContainment(ccrId);
  }

  Future<List<CcrContainmentSorting>>
  getSortingResults(
      String containmentId,
      ) {
    return _repository.getSortingResults(
      containmentId,
    );
  }

  Future<CcrContainment> saveContainment({
    required String ccrId,
    String? sortingActivity,
    String? sortingLearnings,
    String? customerProtectionAction,
    String? recoverPrqSchedule,
    String? firstCertifiedGoodShipment,
    DateTime? targetEta,
    String? status,
  }) {
    return _repository.saveContainment(
      ccrId: ccrId,
      sortingActivity: sortingActivity,
      sortingLearnings: sortingLearnings,
      customerProtectionAction:
      customerProtectionAction,
      recoverPrqSchedule:
      recoverPrqSchedule,
      firstCertifiedGoodShipment:
      firstCertifiedGoodShipment,
      targetEta: targetEta,
      status: status,
    );
  }

  Future<CcrContainmentSorting>
  saveSortingRow({
    required String containmentId,
    required String? location,
    required double? qtyNg,
    required double? qtySorted,
    required DateTime? sortingDate,
    required String? dri,
  }) {
    return _repository.saveSortingRow(
      containmentId: containmentId,
      location: location,
      qtyNg: qtyNg,
      qtySorted: qtySorted,
      sortingDate: sortingDate,
      dri: dri,
    );
  }

  Future<CcrContainmentSorting>
  updateSortingRow({
    required String id,
    required String? location,
    required double? qtyNg,
    required double? qtySorted,
    required DateTime? sortingDate,
    required String? dri,
  }) {
    return _repository.updateSortingRow(
      id: id,
      location: location,
      qtyNg: qtyNg,
      qtySorted: qtySorted,
      sortingDate: sortingDate,
      dri: dri,
    );
  }

  Future<void> deleteSortingRow(
      String id) {
    return _repository.deleteSortingRow(id);
  }

  Future<void> completeContainment(
      String ccrId) {
    return _repository.completeContainment(ccrId);
  }
}