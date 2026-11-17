import 'arr_record.dart';

class CrossTabResult {
  final List<ArrRecord> candidates;

  final List<DataEntryRow> dataEntry;

  /// Mirrors Excel "Calculations" sheet
  final List<CalculationRow> calculations;

  /// Mirrors Excel "Statistical Report"
  final Map<String, dynamic> statisticalReport;

  /// Mirrors Excel "Cross Tab"
  final Map<String, dynamic> crossTab;

  /// Mirrors Excel "ARR Summary"
  final Map<String, dynamic> arrSummary;

  const CrossTabResult({
    required this.candidates,
    required this.dataEntry,
    required this.calculations,
    required this.statisticalReport,
    required this.crossTab,
    required this.arrSummary,
  });
}
class DataEntryRow {
  final String partNumber;

  /// Master Data (Expert)
  final int expert;

  /// Each candidate has Trial1, Trial2, Trial3
  final List<OperatorTrials> operatorTrials;

  const DataEntryRow({
    required this.partNumber,
    required this.expert,
    required this.operatorTrials,
  });
}

class OperatorTrials {
  final String employeeCode;

  final String candidateName;

  final int trial1;

  final int trial2;

  final int trial3;

  const OperatorTrials({
    required this.employeeCode,
    required this.candidateName,
    required this.trial1,
    required this.trial2,
    required this.trial3,
  });
}
class CalculationRow {
  final String partNumber;

  final int sampleNo;

  final String expert;

  /// One entry for each selected candidate/operator.
  final List<OperatorCalculation> operators;

  /// Excel Overall Repeatability
  final int overallRepeatability;

  /// Excel Overall Reproducibility
  final int overallReproducibility;

  const CalculationRow({
    required this.partNumber,
    required this.sampleNo,
    required this.expert,
    required this.operators,
    required this.overallRepeatability,
    required this.overallReproducibility,
  });
}

// class OperatorCalculation {
//   final String employeeCode;
//
//   final String candidateName;
//
//   final String trial1;
//
//   final String trial2;
//
//   final String trial3;
//
//   final int same;
//
//   final int correct;
//
//   final int overkill;
//
//   final int escape;
//
//   const OperatorCalculation({
//     required this.employeeCode,
//     required this.candidateName,
//     required this.trial1,
//     required this.trial2,
//     required this.trial3,
//     required this.same,
//     required this.correct,
//     required this.overkill,
//     required this.escape,
//   });
// }
class OperatorCalculation {
  final String employeeCode;

  final String candidateName;

  final String trial1;

  final String trial2;

  final String trial3;

  final int same;

  final int correct;

  final int overkill;

  final int escape;

  const OperatorCalculation({
    required this.employeeCode,
    required this.candidateName,
    required this.trial1,
    required this.trial2,
    required this.trial3,
    required this.same,
    required this.correct,
    required this.overkill,
    required this.escape,
  });
}
class OperatorStatistics {

  final String employeeCode;

  final String candidate;

  final double falseAlert;

  final double missRate;

  final double effectiveness;

  final double kappa;

  final double agreement;

  const OperatorStatistics({
    required this.employeeCode,
    required this.candidate,
    required this.falseAlert,
    required this.missRate,
    required this.effectiveness,
    required this.kappa,
    required this.agreement,
  });
}

class CrossTabMatrix {
  final int passPass;
  final int passFail;
  final int failPass;
  final int failFail;

  final int total;

  final double observedAgreement;

  final double chanceAgreement;

  final double kappa;

  const CrossTabMatrix({
    required this.passPass,
    required this.passFail,
    required this.failPass,
    required this.failFail,
    required this.total,
    required this.observedAgreement,
    required this.chanceAgreement,
    required this.kappa,
  });

  Map<String, dynamic> toMap() {
    return {
      "passPass": passPass,
      "passFail": passFail,
      "failPass": failPass,
      "failFail": failFail,
      "total": total,
      "observedAgreement": observedAgreement,
      "chanceAgreement": chanceAgreement,
      "kappa": kappa,
      "kappaPercent": kappa * 100,
    };
  }
}