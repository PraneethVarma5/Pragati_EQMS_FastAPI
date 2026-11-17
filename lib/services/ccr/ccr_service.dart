import '../../models/ccr/ccr_case.dart';
import '../../repositories/ccr/ccr_repository.dart';

class CcrService {
  CcrService({
    CcrRepository? repository,
  }) : _repository = repository ?? CcrRepository();

  final CcrRepository _repository;

  // ============================================================
  // GET ALL CCRs
  // ============================================================

  Future<List<CcrCase>> getCcrCases() async {
    final rows = await _repository.getCcrCases();

    return rows
        .map(CcrCase.fromMap)
        .toList();
  }

  // ============================================================
  // CREATE CCR
  // ============================================================

  Future<CcrCase> createCcr() async {
    final row = await _repository.createCcr();

    final ccr = await _repository.getCcrById(
      row['id'].toString(),
    );

    if (ccr == null) {
      throw Exception(
        'CCR was created but could not be loaded.',
      );
    }

    return CcrCase.fromMap(ccr);
  }

  // ============================================================
  // GET ONE CCR
  // ============================================================

  Future<CcrCase?> getCcrById(
      String ccrId,
      ) async {
    final row = await _repository.getCcrById(ccrId);

    if (row == null) {
      return null;
    }

    return CcrCase.fromMap(row);
  }

  // ============================================================
  // SAVE REGISTRATION
  // ============================================================

  Future<void> saveRegistration({
    required String ccrId,
    DateTime? complaintDate,
    String? complaintSource,
    String? customerName,
    String? teamLeader,
    String? groupName,
    String? customerContactName,
    String? customerContactPosition,
    String? customerContactCompany,
    String? customerPartNumber,
    String? supplierPartNumber,
    String? problemDescription,
    String? customerLocation,
    DateTime? detectedDate,
    String? detectedBy,
  }) {
    return _repository.updateRegistration(
      ccrId: ccrId,
      complaintDate: complaintDate,
      complaintSource: complaintSource,
      customerName: customerName,
      teamLeader: teamLeader,
      groupName: groupName,
      customerContactName: customerContactName,
      customerContactPosition: customerContactPosition,
      customerContactCompany: customerContactCompany,
      customerPartNumber: customerPartNumber,
      supplierPartNumber: supplierPartNumber,
      problemDescription: problemDescription,
      customerLocation: customerLocation,
      detectedDate: detectedDate,
      detectedBy: detectedBy,
    );
  }

  // ============================================================
  // STAGE
  // ============================================================

  Future<void> saveCurrentStage({
    required String ccrId,
    required String stageKey,
  }) {
    return _repository.updateCurrentStage(
      ccrId: ccrId,
      stageKey: stageKey,
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Future<void> saveStatus({
    required String ccrId,
    required String statusKey,
  }) {
    return _repository.updateStatus(
      ccrId: ccrId,
      statusKey: statusKey,
    );
  }
}