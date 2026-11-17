class AuditQuestionModelNew {
  final dynamic questionId;
  final dynamic sectionId;
  final int questionNumber;
  final String question;
  final dynamic sortOrder;
  final bool active;

  const AuditQuestionModelNew({
    required this.questionId,
    required this.sectionId,
    required this.questionNumber,
    required this.question,
    this.sortOrder,
    this.active = true,
  });

  factory AuditQuestionModelNew.fromMap(
      Map<String, dynamic> map,
      ) {
    return AuditQuestionModelNew(
      questionId: map['question_id'],
      sectionId: map['section_id'],
      questionNumber:
      _toInt(map['question_number']),
      question:
      (map['question'] ?? '').toString(),
      sortOrder: map['sort_order'],
      active: map['active'] == null
          ? true
          : map['active'] == true,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  Map<String, dynamic> toMap() {
    return {
      'question_id': questionId,
      'section_id': sectionId,
      'question_number': questionNumber,
      'question': question,
      'sort_order': sortOrder,
      'active': active,
    };
  }
}