class AuditFindingModel {
  final String findingId;
  final String auditId;
  final String? answerId;

  final String? section;
  final String? checklistItemId;
  final int? questionNumber;
  final String? question;

  final String? issue;
  final String? findingCategory;
  final String? rootCause;
  final String? correctiveAction;
  final String? driName;
  final String? mailId;
  final DateTime? deadline;
  final String? overallStatus;

  const AuditFindingModel({
    required this.findingId,
    required this.auditId,
    this.answerId,
    this.section,
    this.checklistItemId,
    this.questionNumber,
    this.question,
    this.issue,
    this.findingCategory,
    this.rootCause,
    this.correctiveAction,
    this.driName,
    this.mailId,
    this.deadline,
    this.overallStatus,
  });

  factory AuditFindingModel.fromMap(
      Map<String, dynamic> map,
      ) {
    return AuditFindingModel(
      findingId:
      map['finding_id']?.toString() ?? '',
      auditId:
      map['audit_id']?.toString() ?? '',
      answerId:
      map['answer_id']?.toString(),
      section:
      map['section']?.toString(),
      checklistItemId:
      map['checklist_item_id']?.toString(),
      questionNumber:
      (map['question_number'] as num?)?.toInt(),
      question:
      map['question']?.toString(),
      issue:
      map['issue']?.toString(),
      findingCategory:
      map['finding_category']?.toString(),
      rootCause:
      map['root_cause']?.toString(),
      correctiveAction:
      map['corrective_action']?.toString(),
      driName:
      map['dri_name']?.toString(),
      mailId:
      map['mail_id']?.toString(),
      deadline:
      map['deadline'] == null
          ? null
          : DateTime.tryParse(
        map['deadline'].toString(),
      ),
      overallStatus:
      map['overall_status']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'finding_id': findingId,
      'audit_id': auditId,
      'answer_id': answerId,
      'section': section,
      'checklist_item_id': checklistItemId,
      'question_number': questionNumber,
      'question': question,
      'issue': issue,
      'finding_category': findingCategory,
      'root_cause': rootCause,
      'corrective_action': correctiveAction,
      'dri_name': driName,
      'mail_id': mailId,
      'deadline':
      deadline == null
          ? null
          : _dateOnly(deadline!),
      'overall_status': overallStatus,
    };
  }

  static String _dateOnly(
      DateTime date,
      ) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}