import 'finding_category.dart';

/// One row per question answered during the checklist, for a given audit.
/// This is the "raw" per-question record (Yes/No + description + severity
/// if No). `audit_findings` is a derived table populated only for the "No"
/// answers, carrying the extra MIL-report fields.
class AuditChecklistAnswer {
  final String answerId;
  final String auditId;
  final String section;
  final String checklistItemId;
  final int questionNumber;
  final String question;
  final String? answer; // 'Yes' | 'No'
  final String? description;
  final FindingCategory? category;

  AuditChecklistAnswer({
    required this.answerId,
    required this.auditId,
    required this.section,
    required this.checklistItemId,
    required this.questionNumber,
    required this.question,
    this.answer,
    this.description,
    this.category,
  });

  factory AuditChecklistAnswer.fromMap(Map<String, dynamic> map) {
    return AuditChecklistAnswer(
      answerId: map['answer_id'] as String,
      auditId: map['audit_id'] as String,
      section: map['section'] as String,
      checklistItemId: map['checklist_item_id'] as String,
      questionNumber: (map['question_number'] as num).toInt(),
      question: map['question'] as String,
      answer: map['answer'] as String?,
      description: map['description'] as String?,
      category: FindingCategory.fromString(map['finding_category'] as String?),
    );
  }

  Map<String, dynamic> toUpsertMap() => {
        'audit_id': auditId,
        'section': section,
        'checklist_item_id': checklistItemId,
        'question_number': questionNumber,
        'question': question,
        'answer': answer,
        'description': description,
        'finding_category': category?.value,
      };
}
