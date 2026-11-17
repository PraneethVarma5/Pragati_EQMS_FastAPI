import 'finding_category.dart';

class AuditFinding {
  final String findingId;
  final String auditId;
  final String? answerId;
  final String section;
  final String checklistItemId;
  final int questionNumber;
  final String question;
  final String issue; // description entered on the checklist for this "No"
  final FindingCategory? category;
  final String rootCause;
  final String correctiveAction;
  final String driName;
  final String mailId;
  final DateTime? deadline;
  final String overallStatus; // 'Open' | 'Closed'

  AuditFinding({
    required this.findingId,
    required this.auditId,
    this.answerId,
    required this.section,
    required this.checklistItemId,
    required this.questionNumber,
    required this.question,
    required this.issue,
    this.category,
    this.rootCause = '',
    this.correctiveAction = '',
    this.driName = '',
    this.mailId = '',
    this.deadline,
    this.overallStatus = 'Open',
  });

  bool get isClosed => overallStatus.trim().toLowerCase() == 'closed';

  factory AuditFinding.fromMap(Map<String, dynamic> map) {
    return AuditFinding(
      findingId: map['finding_id'] as String,
      auditId: map['audit_id'] as String,
      answerId: map['answer_id'] as String?,
      section: map['section'] as String? ?? '',
      checklistItemId: map['checklist_item_id'] as String? ?? '',
      questionNumber: (map['question_number'] as num?)?.toInt() ?? 0,
      question: map['question'] as String? ?? '',
      issue: map['issue'] as String? ?? '',
      category: FindingCategory.fromString(map['finding_category'] as String?),
      rootCause: map['root_cause'] as String? ?? '',
      correctiveAction: map['corrective_action'] as String? ?? '',
      driName: map['dri_name'] as String? ?? '',
      mailId: map['mail_id'] as String? ?? '',
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'] as String)
          : null,
      overallStatus: map['overall_status'] as String? ?? 'Open',
    );
  }

  Map<String, dynamic> toInsertMap() => {
        'audit_id': auditId,
        'answer_id': answerId,
        'section': section,
        'checklist_item_id': checklistItemId,
        'question_number': questionNumber,
        'question': question,
        'issue': issue,
        'finding_category': category?.value,
        'root_cause': rootCause,
        'corrective_action': correctiveAction,
        'dri_name': driName,
        'mail_id': mailId,
        'deadline': deadline?.toIso8601String().split('T').first,
        'overall_status': overallStatus,
      };

  Map<String, dynamic> toUpdateMap() => {
        'root_cause': rootCause,
        'corrective_action': correctiveAction,
        'dri_name': driName,
        'mail_id': mailId,
        'deadline': deadline?.toIso8601String().split('T').first,
        'overall_status': overallStatus,
      };
}
