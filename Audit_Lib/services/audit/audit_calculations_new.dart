class AuditCalculationsNew {
  const AuditCalculationsNew._();

  static int answeredCount({
    required int totalQuestions,
    required int answeredQuestions,
  }) {
    if (answeredQuestions < 0) {
      return 0;
    }

    if (answeredQuestions > totalQuestions) {
      return totalQuestions;
    }

    return answeredQuestions;
  }

  static double completionPercentage({
    required int totalQuestions,
    required int answeredQuestions,
  }) {
    if (totalQuestions <= 0) {
      return 0;
    }

    final value = answeredQuestions / totalQuestions;

    if (value < 0) {
      return 0;
    }

    if (value > 1) {
      return 1;
    }

    return value;
  }

  static bool isComplete({
    required int totalQuestions,
    required int answeredQuestions,
  }) {
    return totalQuestions > 0 &&
        answeredQuestions >= totalQuestions;
  }

  static String percentageText({
    required int totalQuestions,
    required int answeredQuestions,
  }) {
    final percentage = completionPercentage(
      totalQuestions: totalQuestions,
      answeredQuestions: answeredQuestions,
    );

    return '${(percentage * 100).round()}%';
  }

  static Duration duration({
    required DateTime start,
    required DateTime end,
  }) {
    final result = end.difference(start);

    if (result.isNegative) {
      return Duration.zero;
    }

    return result;
  }

  static String durationText(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }

    return '${seconds}s';
  }
}