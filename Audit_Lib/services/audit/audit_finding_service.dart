import 'package:uuid/uuid.dart';

import '../../models/audit/audit_finding_model.dart';
import 'audit_db_service.dart';

class AuditFindingService {
  AuditFindingService._();

  static final _db =
      AuditDbService.client;

  static const _uuid = Uuid();

  static Future<List<AuditFindingModel>>
  getFindings(
      String auditId,
      ) async {
    final response = await _db
        .from(AuditDbService.findings)
        .select()
        .eq(
      'audit_id',
      auditId,
    )
        .order(
      'question_number',
    );

    return List<Map<String, dynamic>>
        .from(response)
        .map(AuditFindingModel.fromMap)
        .toList();
  }

  static Future<void>
  saveFinding(
      AuditFindingModel finding,
      ) async {
    await _db
        .from(AuditDbService.findings)
        .upsert(
      finding.toMap(),
    );
  }

  static Future<void>
  deleteForAnswer({
    required String auditId,
    required String checklistItemId,
  }) async {
    await _db
        .from(AuditDbService.findings)
        .delete()
        .eq(
      'audit_id',
      auditId,
    )
        .eq(
      'checklist_item_id',
      checklistItemId,
    );
  }

  static AuditFindingModel
  createFromAnswer({
    required String auditId,
    required String answerId,
    required String section,
    required String checklistItemId,
    required int questionNumber,
    required String question,
    required String issue,
    required String findingCategory,
  }) {
    return AuditFindingModel(
      findingId:
      _uuid.v4(),
      auditId:
      auditId,
      answerId:
      answerId,
      section:
      section,
      checklistItemId:
      checklistItemId,
      questionNumber:
      questionNumber,
      question:
      question,
      issue:
      issue,
      findingCategory:
      findingCategory,
      overallStatus:
      null,
    );
  }
}