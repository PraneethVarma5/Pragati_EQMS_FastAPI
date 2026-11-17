// import 'app_data.dart';
// import 'question_data.dart';
// import 'hive_service.dart';
// import '../models/question.dart';
//
// class EvaluationService {
//   static Map<String, dynamic> calculate() {
//     List<Question> masterQuestions =
//     HiveService.loadBatchQuestions(
//         AppData.selectedBatchId);
//
//     if (masterQuestions.isEmpty) {
//       masterQuestions = List.from(questions);
//     }
//
//     List<int> master = [];
//
//     for (int i = 0; i < 3; i++) {
//       master.addAll(masterQuestions.map((e) => e.initialStatus).toList());
//     }
//
//     List<int> observed = [
//       ...AppData.trail1Answers,
//
//       ...AppData.trail2Answers,
//
//       ...AppData.trail3Answers,
//     ];
//
//     int falseAlert = 0;
//     int missAlert = 0;
//
//     int observedOk = observed.where((e) => e == 1).length;
//
//     int observedNg = observed.where((e) => e == 0).length;
//
//     for (int i = 0; i < observed.length; i++) {
//       if (master[i] == 1 && observed[i] == 0) {
//         falseAlert++;
//       }
//
//       if (master[i] == 0 && observed[i] == 1) {
//         missAlert++;
//       }
//     }
//
//     final int total = observed.length;
//
//     double pEffectiveness =
//     total == 0
//         ? 0
//         : (total - falseAlert - missAlert) / total;
//
//     final int okCount = master.where((e) => e == 1).length;
//
//     final int ngCount = master.where((e) => e == 0).length;
//
//     double p1 =
//     total == 0
//         ? 0
//         : (okCount / total) * (observedOk / total);
//
//     double p0 =
//     total == 0
//         ? 0
//         : (ngCount / total) * (observedNg / total);
//
//     double pChance = p1 + p0;
//
//     double kappa;
//
//     if ((1 - pChance) == 0) {
//
//       if (falseAlert == 0 && missAlert == 0) {
//         kappa = 100;
//       } else {
//         kappa = 0;
//       }
//
//     } else {
//
//       kappa =
//           ((pEffectiveness - pChance) /
//               (1 - pChance)) *
//               100;
//
//     }
//     double effectiveness = pEffectiveness * 100;
//
//     double falseRate =
//     okCount == 0
//         ? 0
//         : (falseAlert / okCount) * 100;
//
//     double missRate =
//     ngCount == 0
//         ? 0
//         : (missAlert / ngCount) * 100;
//     String result;
//
//     if (falseRate < 5 && missRate < 2 && effectiveness >= 90 && kappa >= 80) {
//       result = "ACCEPTABLE";
//     } else if (falseRate < 10 &&
//         missRate < 5 &&
//         effectiveness >= 80 &&
//         kappa >= 60) {
//       result = "MARGINALLY ACCEPTABLE";
//     } else {
//       result = "UNACCEPTABLE";
//     }
//     return {
//       "falseAlert": falseAlert,
//
//       "missAlert": missAlert,
//
//       "falseAlertPercent": falseRate,
//
//       "missRate": missRate,
//
//       "effectiveness": effectiveness,
//
//       "p1": p1,
//
//       "p0": p0,
//
//       "pChance": pChance,
//
//       "kappa": kappa,
//
//       "classification": result,
//     };
//   }
// }

import 'app_data.dart';

class EvaluationService {
  static Map<String, dynamic> calculate({
    required List<Map<String, dynamic>> masterParts,
  }) {
    // ============================================================
    // MASTER DATA
    // ============================================================

    final List<int> masterAnswers =
    masterParts.map((part) {
      final value = part['master_status'];

      if (value is int) {
        return value;
      }

      return int.tryParse(
        value?.toString() ?? '',
      ) ??
          0;
    }).toList();

    // ============================================================
    // OBSERVED DATA
    // ============================================================

    final List<int> trail1 =
    List<int>.from(
      AppData.trail1Answers,
    );

    final List<int> trail2 =
    List<int>.from(
      AppData.trail2Answers,
    );

    final List<int> trail3 =
    List<int>.from(
      AppData.trail3Answers,
    );

    final List<int> observed = [
      ...trail1,
      ...trail2,
      ...trail3,
    ];

    // Master data repeats for all 3 trials.
    final List<int> master = [
      ...masterAnswers,
      ...masterAnswers,
      ...masterAnswers,
    ];

    // ============================================================
    // SAFETY CHECK
    // ============================================================

    if (master.isEmpty ||
        observed.isEmpty ||
        master.length != observed.length) {
      return {
        "falseAlert": 0,
        "missAlert": 0,
        "falseAlertPercent": 0.0,
        "missRate": 0.0,
        "effectiveness": 0.0,
        "p1": 0.0,
        "p0": 0.0,
        "pChance": 0.0,
        "kappa": 0.0,
        "classification": "UNACCEPTABLE",
      };
    }

    // ============================================================
    // ERROR COUNTS
    // ============================================================

    int falseAlert = 0;
    int missAlert = 0;

    for (int i = 0; i < observed.length; i++) {
      if (master[i] == 1 &&
          observed[i] == 0) {
        falseAlert++;
      }

      if (master[i] == 0 &&
          observed[i] == 1) {
        missAlert++;
      }
    }

    // ============================================================
    // TOTAL
    // ============================================================

    final int total =
        observed.length;

    final int observedOk =
        observed.where((e) => e == 1).length;

    final int observedNg =
        observed.where((e) => e == 0).length;

    final int okCount =
        master.where((e) => e == 1).length;

    final int ngCount =
        master.where((e) => e == 0).length;

    // ============================================================
    // EFFECTIVENESS
    // ============================================================

    final double pEffectiveness =
    total == 0
        ? 0
        : (total -
        falseAlert -
        missAlert) /
        total;

    final double effectiveness =
        pEffectiveness * 100;

    // ============================================================
    // P1 / P0 / P CHANCE
    // ============================================================

    final double p1 =
    total == 0
        ? 0
        : (okCount / total) *
        (observedOk / total);

    final double p0 =
    total == 0
        ? 0
        : (ngCount / total) *
        (observedNg / total);

    final double pChance =
        p1 + p0;

    // ============================================================
    // KAPPA
    // ============================================================

    double kappa;

    if ((1 - pChance) == 0) {
      if (falseAlert == 0 &&
          missAlert == 0) {
        kappa = 100;
      } else {
        kappa = 0;
      }
    } else {
      kappa =
          ((pEffectiveness -
              pChance) /
              (1 - pChance)) *
              100;
    }

    // ============================================================
    // FALSE ALERT %
    // ============================================================

    final double falseRate =
    okCount == 0
        ? 0
        : (falseAlert /
        okCount) *
        100;

    // ============================================================
    // MISS RATE %
    // ============================================================

    final double missRate =
    ngCount == 0
        ? 0
        : (missAlert /
        ngCount) *
        100;

    // ============================================================
    // CLASSIFICATION
    // ============================================================

    String classification;

    if (falseRate < 5 &&
        missRate < 2 &&
        effectiveness >= 90 &&
        kappa >= 80) {
      classification = "ACCEPTABLE";
    } else if (falseRate < 10 &&
        missRate < 5 &&
        effectiveness >= 80 &&
        kappa >= 60) {
      classification =
      "MARGINALLY ACCEPTABLE";
    } else {
      classification = "UNACCEPTABLE";
    }

    // ============================================================
    // RESULT
    // ============================================================

    return {
      "falseAlert": falseAlert,
      "missAlert": missAlert,
      "falseAlertPercent": falseRate,
      "missRate": missRate,
      "effectiveness": effectiveness,
      "p1": p1,
      "p0": p0,
      "pChance": pChance,
      "kappa": kappa,
      "classification": classification,
    };
  }
}