class AuditAnswerModelNew {
  final dynamic answerId;
  final dynamic auditId;
  final dynamic checklistItemId;

  final String auditType;
  final String category;
  final String question;

  final String answer;
  final String description;
  final String defect;
  final String finding;
  final String findingType;

  const AuditAnswerModelNew({
    this.answerId,
    required this.auditId,
    required this.checklistItemId,
    required this.auditType,
    required this.category,
    required this.question,
    required this.answer,
    required this.description,
    required this.defect,
    required this.finding,
    required this.findingType,
  });

  factory AuditAnswerModelNew.fromMap(
      Map<String, dynamic> map,
      ) {
    return AuditAnswerModelNew(
      answerId: map['answer_id'],
      auditId: map['audit_id'],
      checklistItemId:
      map['checklist_item_id'],
      auditType:
      (map['audit_type'] ?? '')
          .toString(),
      category:
      (map['category'] ?? '')
          .toString(),
      question:
      (map['question'] ?? '')
          .toString(),
      answer:
      (map['answer'] ?? '')
          .toString(),
      description:
      (map['description'] ?? '')
          .toString(),
      defect:
      (map['defect'] ?? '')
          .toString(),
      finding:
      (map['finding'] ?? '')
          .toString(),
      findingType:
      (map['finding_type'] ?? '')
          .toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'answer_id': answerId,
      'audit_id': auditId,
      'checklist_item_id':
      checklistItemId,
      'audit_type': auditType,
      'category': category,
      'question': question,
      'answer': answer,
      'description': description,
      'defect': defect,
      'finding': finding,
      'finding_type': findingType,
    };
  }
}