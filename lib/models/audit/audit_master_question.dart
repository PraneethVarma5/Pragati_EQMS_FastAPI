class AuditMasterQuestion {
  final String questionId;
  final String sectionId;
  final int questionNumber;
  final String question;
  final int sortOrder;
  final bool active;

  AuditMasterQuestion({
    required this.questionId,
    required this.sectionId,
    required this.questionNumber,
    required this.question,
    required this.sortOrder,
    required this.active,
  });

  factory AuditMasterQuestion.fromMap(Map<String, dynamic> map) {
    return AuditMasterQuestion(
      questionId: map['question_id'] as String,
      sectionId: map['section_id'] as String,
      questionNumber: (map['question_number'] as num).toInt(),
      question: map['question'] as String,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      active: map['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toInsertMap() => {
        'section_id': sectionId,
        'question_number': questionNumber,
        'question': question,
        'sort_order': sortOrder,
        'active': active,
      };
}
