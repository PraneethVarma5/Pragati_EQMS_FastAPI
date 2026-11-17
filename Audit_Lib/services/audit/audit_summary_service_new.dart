import '../../models/audit/audit_question_model_new.dart';
import '../../models/audit/audit_section_model_new.dart';
import '../../models/audit/audit_summary_model_new.dart';
import 'audit_service_new.dart';

class AuditSummaryServiceNew {
  final AuditServiceNew _auditService;

  AuditSummaryServiceNew({
    AuditServiceNew? auditService,
  }) : _auditService = auditService ?? AuditServiceNew();

  Future<AuditSummaryModelNew> buildSummary({
    required dynamic auditId,
    required String auditType,
  }) async {
    final sections = await _auditService.getSections(
      auditType,
    );

    final answers = await _auditService.getAnswers(
      auditId,
    );

    int totalQuestions = 0;

    for (final AuditSectionModelNew section in sections) {
      final List<AuditQuestionModelNew> questions =
      await _auditService.getQuestions(
        section.sectionId,
      );

      totalQuestions += questions.length;
    }

    final answeredQuestions = answers
        .where(
          (answer) => answer.answer.trim().isNotEmpty,
    )
        .length;

    final completedCategories =
    await _calculateCompletedCategories(
      sections,
      auditId,
    );

    final findings =
    await _auditService.getFindings(auditId);

    return AuditSummaryModelNew(
      totalCategories: sections.length,
      completedCategories: completedCategories,
      totalQuestions: totalQuestions,
      answeredQuestions: answeredQuestions,
      totalFindings: findings.length,
    );
  }

  Future<int> _calculateCompletedCategories(
      List<AuditSectionModelNew> sections,
      dynamic auditId,
      ) async {
    final answers = await _auditService.getAnswers(
      auditId,
    );

    int completed = 0;

    for (final section in sections) {
      final questions = await _auditService.getQuestions(
        section.sectionId,
      );

      if (questions.isEmpty) {
        continue;
      }

      final questionIds = questions
          .map(
            (question) =>
            question.questionId.toString(),
      )
          .toSet();

      final answeredForCategory = answers.where(
            (answer) =>
        answer.category ==
            section.sectionName &&
            questionIds.contains(
              answer.checklistItemId.toString(),
            ) &&
            answer.answer.trim().isNotEmpty,
      );

      if (answeredForCategory.length >= questions.length) {
        completed++;
      }
    }

    return completed;
  }
}