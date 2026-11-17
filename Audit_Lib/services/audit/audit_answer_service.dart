import 'package:uuid/uuid.dart';

import '../../models/audit/audit_answer_model_new.dart';
import 'audit_db_service.dart';

class AuditAnswerService {
  AuditAnswerService._();

  static final _db =
      AuditDbService.client;

  static const _uuid = Uuid();

  // ============================================================
  // LOAD ANSWERS
  // ============================================================

  static Future<List<AuditAnswerModel>>
  getAnswers(
      String auditId,
      ) async {
    final response = await _db
        .from(AuditDbService.answers)
        .select()
        .eq(
      'audit_id',
      auditId,
    )
        .order('question_number');

    return List<Map<String, dynamic>>
        .from(response)
        .map(AuditAnswerModel.fromMap)
        .toList();
  }

  // ============================================================
  // LOAD SECTION ANSWERS
  // ============================================================

  static Future<List<AuditAnswerModel>>
  getSectionAnswers({
    required String auditId,
    required String section,
  }) async {
    final response = await _db
        .from(AuditDbService.answers)
        .select()
        .eq(
      'audit_id',
      auditId,
    )
        .eq(
      'section',
      section,
    )
        .order('question_number');

    return List<Map<String, dynamic>>
        .from(response)
        .map(AuditAnswerModel.fromMap)
        .toList();
  }

  // ============================================================
  // SAVE
  // ============================================================

  static Future<AuditAnswerModel>
  saveAnswer({
    required String auditId,
    required String section,
    required String checklistItemId,
    required int questionNumber,
    required String question,
    required String? answer,
    required String? description,
    required String? findingCategory,
  }) async {
    final existing =
    await _db
        .from(
      AuditDbService.answers,
    )
        .select('answer_id')
        .eq(
      'audit_id',
      auditId,
    )
        .eq(
      'checklist_item_id',
      checklistItemId,
    )
        .maybeSingle();

    final answerId =
        existing?['answer_id']
            ?.toString() ??
            _uuid.v4();

    final model =
    AuditAnswerModel(
      answerId: answerId,
      auditId: auditId,
      section: section,
      checklistItemId:
      checklistItemId,
      questionNumber:
      questionNumber,
      question: question,
      answer: answer,
      description: description,
      findingCategory:
      findingCategory,
    );

    await _db
        .from(AuditDbService.answers)
        .upsert(
      model.toMap(),
      onConflict:
      'audit_id,checklist_item_id',
    );

    return model;
  }
}