class AuditSummaryModelNew {
  final int totalCategories;
  final int completedCategories;

  final int totalQuestions;
  final int answeredQuestions;

  final int totalFindings;

  const AuditSummaryModelNew({
    required this.totalCategories,
    required this.completedCategories,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.totalFindings,
  });

  double get categoryCompletion {
    if (totalCategories == 0) {
      return 0;
    }

    return completedCategories / totalCategories;
  }

  double get questionCompletion {
    if (totalQuestions == 0) {
      return 0;
    }

    return answeredQuestions / totalQuestions;
  }

  bool get isComplete {
    return totalQuestions > 0 &&
        answeredQuestions >= totalQuestions;
  }
}