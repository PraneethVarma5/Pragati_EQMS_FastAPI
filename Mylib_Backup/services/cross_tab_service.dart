// import '../models/arr_record.dart';
// import '../models/cross_tab_result.dart';
//
// class CrossTabService {
//   CrossTabService._();
//
//   static CrossTabResult generate(
//       List<ArrRecord> records,
//       ) {
//     if (records.length < 2) {
//       throw Exception(
//         "Minimum two candidates required.",
//       );
//     }
//
//     final batchId = records.first.batchId;
//
//     if (!records.every((e) => e.batchId == batchId)) {
//       throw Exception(
//         "Selected candidates belong to different batches.",
//       );
//     }
//
//     final dataEntry = _buildDataEntry(records);
//
//     final calculations =
//     _buildCalculationMatrix(dataEntry);
//
//     final calculationTotals =
//     _buildCalculationTotals(calculations);
//
//     final statisticalReport =
//     _buildStatisticalReport(
//       calculations,
//       calculationTotals,
//     );
//
//     final statistics =
//     _buildStatistics(records);
//
//     final crossTab =
//     _buildCrossTab(
//       calculations,
//       calculationTotals,
//     );
//
//     final summary =
//     _buildSummary(
//       records,
//       statisticalReport,
//       crossTab,
//     );
//
//     return CrossTabResult(
//       candidates: records,
//       dataEntry: dataEntry,
//       calculations: calculations,
//       statisticalReport: statisticalReport,
//       crossTab: crossTab,
//       arrSummary: summary,
//     );
//   }
//
//   static List<DataEntryRow> _buildDataEntry(
//       List<ArrRecord> records,
//       ) {
//
//     final List<DataEntryRow> rows = [];
//
//     if (records.isEmpty) {
//       return rows;
//     }
//
//     final first = records.first;
//
//     final totalParts = first.partNumbers.length;
//
//     for (int part = 0; part < totalParts; part++) {
//
//       final List<OperatorTrials> operators = [];
//
//       for (final candidate in records) {
//
//         operators.add(
//
//           OperatorTrials(
//
//             employeeCode: candidate.employeeCode,
//
//             candidateName: candidate.appraisee,
//
//             trial1: candidate.trail1Answers[part],
//
//             trial2: candidate.trail2Answers[part],
//
//             trial3: candidate.trail3Answers[part],
//
//           ),
//
//         );
//
//       }
//
//       rows.add(
//
//         DataEntryRow(
//
//           partNumber: first.partNumbers[part],
//
//           expert: first.masterAnswers[part],
//
//           operatorTrials: operators,
//
//         ),
//
//       );
//
//     }
//
//     return rows;
//
//   }
//   static List<CalculationRow> _buildCalculationMatrix(
//       List<DataEntryRow> dataEntry,
//       ) {
//     final List<CalculationRow> rows = [];
//
//     int sampleNo = 1;
//
//     for (final row in dataEntry) {
//       final expert = row.expert.toString();
//
//       final List<OperatorCalculation> operators = [];
//
//       for (final operator in row.operatorTrials) {
//         final t1 = operator.trial1.toString();
//         final t2 = operator.trial2.toString();
//         final t3 = operator.trial3.toString();
//         operators.add(
//           OperatorCalculation(
//             employeeCode: operator.employeeCode,
//             candidateName: operator.candidateName,
//
//             trial1: t1,
//             trial2: t2,
//             trial3: t3,
//
//             same: _excelSame(t1, t2, t3),
//             correct: _excelCorrect(expert, t1, t2, t3),
//             overkill: _excelOverkill(expert, t1, t2, t3),
//             escape: _excelEscape(expert, t1, t2, t3),
//           ),
//         );
//       }
//
//       int repeatability = 0;
//       int reproducibility = 0;
//
//       if (operators.isNotEmpty) {
//         final firstSame = operators.first.same;
//         final firstCorrect = operators.first.correct;
//
//         repeatability =
//         operators.every((e) => e.same == firstSame) ? 1 : 0;
//
//         reproducibility =
//         operators.every((e) => e.correct == firstCorrect) ? 1 : 0;
//       }
//
//       rows.add(
//         CalculationRow(
//           sampleNo: sampleNo,
//           expert: expert,
//           operators: operators,
//           overallRepeatability: repeatability,
//           overallReproducibility: reproducibility,
//         ),
//       );
//
//       sampleNo++;
//     }
//
//     return rows;
//   }
//   static Map<String, dynamic> _buildCalculationTotals(
//       List<CalculationRow> calculations,
//       ) {
//     if (calculations.isEmpty) {
//       return {};
//     }
//
//     final operatorCount = calculations.first.operators.length;
//
//     final List<Map<String, dynamic>> operators = [];
//
//     int totalOverkill = 0;
//     int totalEscape = 0;
//
//     for (int i = 0; i < operatorCount; i++) {
//
//       int sameCount = 0;
//       int correctCount = 0;
//       int overkill = 0;
//       int escape = 0;
//
//       int sameTotal = 0;
//       int correctTotal = 0;
//
//       for (final row in calculations) {
//
//         final op = row.operators[i];
//
//         if (op.same == 0 || op.same == 1) {
//           sameTotal++;
//           sameCount += op.same;
//         }
//
//         if (op.correct == 0 || op.correct == 1) {
//           correctTotal++;
//           correctCount += op.correct;
//         }
//
//         overkill += op.overkill;
//         escape += op.escape;
//       }
//
//       totalOverkill += overkill;
//       totalEscape += escape;
//
//       operators.add({
//         "appraiserScore":
//         sameTotal == 0 ? 0.0 : sameCount / sameTotal,
//
//         "attributeScore":
//         correctTotal == 0 ? 0.0 : correctCount / correctTotal,
//
//         "sameCount": sameCount,
//         "sameTotal": sameTotal,
//
//         "correctCount": correctCount,
//         "correctTotal": correctTotal,
//
//         "overkill": overkill,
//         "escape": escape,
//       });
//     }
//
//     // return {
//     //   "operators": operators,
//     //
//     //   "sampleCount": calculations.length,
//     //
//     //   "opsTries": calculations.length * 3,
//     //
//     //   "defects": totalOverkill,
//     //
//     //   "OVERKILL": totalOverkill,
//     //
//     //   "ESCAPE": totalEscape,
//     // };
//
// // Excel:
// // Ops × Tries
// // = Number of Operators × Number of Trials
//
//     const totalTrials = 3;
//
//     return {
//       "operators": operators,
//
//       "sampleCount": calculations.length,
//
//       "operatorCount": operatorCount,
//
//       "trialCount": totalTrials,
//
//       "opsTries": operatorCount * totalTrials,
//
//       "partCount": calculations.length,
//
//       "inspectionCount":
//       calculations.length *
//           operatorCount *
//           totalTrials,
//
//       "defects": totalOverkill,
//
//       "OVERKILL": totalOverkill,
//
//       "ESCAPE": totalEscape,
//     };
//   }
//   static Map<String, dynamic> _buildStatisticalReport(
//       List<CalculationRow> calculations,
//       Map<String, dynamic> calculationTotals,
//       ) {
//     if (calculations.isEmpty) {
//       return {};
//     }
//
//     final operators =
//     calculationTotals["operators"] as List<Map<String, dynamic>>;
//
//     final totalOperators = operators.length;
//
//     // int same = 0;
//     // int sameTotal = 0;
//     //
//     // int correct = 0;
//     // int correctTotal = 0;
//     // ======================================================
// // Excel uses separate totals.
// // Do NOT mix Appraiser and Attribute calculations.
// // ======================================================
//
//     int appraiserMatched = 0;
//     int appraiserInspected = 0;
//
//     int attributeMatched = 0;
//     int attributeInspected = 0;
//     int overkill = 0;
//     int escape = 0;
//
//     for (final op in operators) {
//       //
//       // same += op["sameCount"] as int;
//       // sameTotal += op["sameTotal"] as int;
//       //
//       // correct += op["correctCount"] as int;
//       // correctTotal += op["correctTotal"] as int;
//
//       appraiserMatched += op["sameCount"] as int;
//
//       appraiserInspected += op["sameTotal"] as int;
//
//       attributeMatched += op["correctCount"] as int;
//       attributeInspected += op["correctTotal"] as int;
//       overkill += op["overkill"] as int;
//       escape += op["escape"] as int;
//     }
//
//     // final repeatability =
//     // sameTotal == 0 ? 0.0 : same / sameTotal;
//     final repeatability =
//     appraiserInspected == 0
//         ? 0.0
//         : appraiserMatched /
//         appraiserInspected;
//
//     // final reproducibility =
//     // correctTotal == 0 ? 0.0 : correct / correctTotal;
//     final reproducibility =
//     attributeInspected == 0
//         ? 0.0
//         : attributeMatched /
//         attributeInspected;
//
//     // final falseAlert =
//     // correctTotal == 0 ? 0.0 : overkill / correctTotal;
//     // Excel
// // False Alarm %
// // = Overkill / Attribute Opportunities
//
//     final falseAlert =
//     attributeInspected == 0
//         ? 0.0
//         : overkill /
//         attributeInspected;
//
//     // final missRate =
//     // correctTotal == 0 ? 0.0 : escape / correctTotal;
//
//     // Excel
// // Escape %
// // = Escape / Attribute Opportunities
//
//     final missRate =
//     attributeInspected == 0
//         ? 0.0
//         : escape /
//         attributeInspected;
//
//     final effectiveness =
//         1 - falseAlert - missRate;
//     final operatorStatistics = operators.map((op) {
//
//       final inspected =
//       op["sameTotal"] as int;
//
//       final matched =
//       op["sameCount"] as int;
//
//       final attributeInspected =
//       op["correctTotal"] as int;
//
//       final attributeMatched =
//       op["correctCount"] as int;
//
//       return {
//
//         // Excel row 10
//         "totalInspected": inspected,
//
//         // Excel row 11
//         "matched": matched,
//
//         // Excel row 14
//         "calculatedScore":
//         inspected == 0
//             ? 0.0
//             : matched / inspected,
//
//         // Score vs Attribute
//         "attributeTotal":
//         attributeInspected,
//
//         "attributeMatched":
//         attributeMatched,
//
//         "attributeScore":
//         attributeInspected == 0
//             ? 0.0
//             : attributeMatched / attributeInspected,
//
//         // Excel rows 16 & 17
//         "escape": op["escape"],
//
//         "overkill": op["overkill"],
//
//       };
//
//     }).toList();
//
//     return {
//
//       "sampleCount":
//       calculationTotals["sampleCount"],
//
//       "opsTries":
//       calculationTotals["opsTries"],
//
//       "defects":
//       calculationTotals["defects"],
//
//       "operatorCount":
//       totalOperators,
//
//       "operators": List.generate(
//         operatorStatistics.length,
//             (index) {
//           final op = operatorStatistics[index];
//
//           return {
//             "operatorNo": index + 1,
//
//             // ==========================
//             // Excel Rows 10-17
//             // ==========================
//
//             "totalInspected": op["totalInspected"],
//             "matched": op["matched"],
//             "calculatedScore": op["calculatedScore"],
//
//             "escape": op["escape"],
//             "overkill": op["overkill"],
//
//             // Confidence limits
//             // Filled after BETAINV implementation.
//             "lcl95": null,
//             "ucl95": null,
//           };
//         },
//       ),
//
//       "appraiserScores": operatorStatistics
//           .map(
//             (e) => (e["calculatedScore"] as double) * 100,
//       )
//           .toList(),
//
//       "attributeScores": operatorStatistics
//           .map(
//             (e) => (e["attributeScore"] as double) * 100,
//       )
//           .toList(),
//       "screenEffectiveScores": operatorStatistics
//           .map((e) => (e["calculatedScore"] as double) * 100)
//           .toList(),
//
//       "screenEffectiveScoresVsAttribute": operatorStatistics
//           .map((e) => (e["attributeScore"] as double) * 100)
//           .toList(),
//       "repeatability": repeatability,
//       "repeatabilityPercent": repeatability * 100,
//
//       "reproducibility": reproducibility,
//       "reproducibilityPercent": reproducibility * 100,
//
//       "overkill": {
//         "count": overkill,
//         "percent": falseAlert * 100,
//       },
//
//       "escape": {
//         "count": escape,
//         "percent": missRate * 100,
//       },
//
//       "effectiveness": effectiveness,
//       "effectivenessPercent": effectiveness * 100,
//
//       // ===== DATA ENTRY FOOTER =====
//
//       // Excel -> Calculations!U104
//       "appraiserScore": repeatability * 100,
//
//       // Excel -> Calculations!V104
//       "attributeScore": reproducibility * 100,
//
//       // ===========================================================
//       // EFFECTIVE SCORE (Excel Rows 22-26)
//       // ===========================================================
//
//       // "effectiveScore": {
//       //   "totalInspected": sameTotal,
//       //   "yesCount": same,
//       //   "score":
//       //   sameTotal == 0
//       //       ? 0.0
//       //       : same / sameTotal,
//
//       "effectiveScore": {
//
//         // Excel Row22
//
//         "totalInspected": appraiserInspected,
//
//         // Excel Row23
//
//         "yesCount": appraiserMatched,
//
//         // Excel Row25
//
//         "score":
//         appraiserInspected == 0
//             ? 0.0
//             : appraiserMatched /
//             appraiserInspected,
//
//         // BETAINV later
//         "lcl95": null,
//         "ucl95": null,
//       },
//
//       // ===========================================================
//       // EFFECTIVE SCORE VS ATTRIBUTE
//       // ===========================================================
//
//       // "effectiveScoreVsAttribute": {
//       //   "totalInspected": correctTotal,
//       //   "yesCount": correct,
//       //   "score":
//       //   correctTotal == 0
//       //       ? 0.0
//       //       : (correct / correctTotal) * 100,
//       // },
//       "effectiveScoreVsAttribute": {
//
//         "totalInspected":
//         attributeInspected,
//
//         "yesCount":
//         attributeMatched,
//
//         "score":
//         attributeInspected == 0
//             ? 0.0
//             : attributeMatched /
//             attributeInspected,
//       },
//
//       // ===========================================================
//       // ATTRIBUTE INSPECTION ACCURACY
//       // Excel:
//       // C29 = Total
//       // C30 = Correct
//       // C32 = Correct / Total
//       // ===========================================================
//
//       "attributeInspectionAccuracy": {
//         "total": attributeInspected,
//         "correct": attributeMatched,
//         "score":
//         attributeInspected == 0
//             ? 0.0
//             : attributeMatched / attributeInspected,
//
//         // BETAINV later
//         "lcl95": null,
//         "ucl95": null,
//       },
//     };
//   }
//   static List<OperatorStatistics> _buildStatistics(
//       List<ArrRecord> records,
//       ) {
//
//     final List<OperatorStatistics> statistics = [];
//
//     for (final candidate in records) {
//
//       final agreement = _calculateAgreement(candidate);
//
//       final falseAlert = _calculateFalseAlert(candidate);
//
//       final missRate = _calculateMissRate(candidate);
//
//       final effectiveness = _calculateEffectiveness(candidate);
//
//       final kappa = _calculateKappa(candidate);
//
//       statistics.add(
//
//         OperatorStatistics(
//
//           employeeCode: candidate.employeeCode,
//
//           candidate: candidate.appraisee,
//
//           agreement: agreement,
//
//           falseAlert: falseAlert,
//
//           missRate: missRate,
//
//           effectiveness: effectiveness,
//
//           kappa: kappa,
//
//         ),
//
//       );
//
//     }
//
//     return statistics;
//
//   }
//   static double _calculateAgreement(
//       ArrRecord record,
//       ) {
//
//     int correct = 0;
//
//     int total = record.masterAnswers.length * 3;
//
//     for (int i = 0; i < record.masterAnswers.length; i++) {
//
//       if (record.trail1Answers[i] == record.masterAnswers[i]) {
//         correct++;
//       }
//
//       if (record.trail2Answers[i] == record.masterAnswers[i]) {
//         correct++;
//       }
//
//       if (record.trail3Answers[i] == record.masterAnswers[i]) {
//         correct++;
//       }
//
//     }
//
//     if (total == 0) {
//       return 0;
//     }
//
//     return (correct / total) * 100;
//
//   }
//   static double _calculateFalseAlert(
//       ArrRecord record,
//       ) {
//
//     int falseAlert = 0;
//
//     int okParts = 0;
//
//     for (int i = 0; i < record.masterAnswers.length; i++) {
//
//       if (record.masterAnswers[i] != 1) {
//         continue;
//       }
//
//       okParts++;
//
//       if (record.trail1Answers[i] == 0) {
//         falseAlert++;
//       }
//
//       if (record.trail2Answers[i] == 0) {
//         falseAlert++;
//       }
//
//       if (record.trail3Answers[i] == 0) {
//         falseAlert++;
//       }
//
//     }
//
//     if (okParts == 0) {
//       return 0;
//     }
//
//     return (falseAlert / (okParts * 3)) * 100;
//
//   }
//   static double _calculateMissRate(
//       ArrRecord record,
//       ) {
//
//     int miss = 0;
//
//     int ngParts = 0;
//
//     for (int i = 0; i < record.masterAnswers.length; i++) {
//
//       if (record.masterAnswers[i] != 0) {
//         continue;
//       }
//
//       ngParts++;
//
//       if (record.trail1Answers[i] == 1) {
//         miss++;
//       }
//
//       if (record.trail2Answers[i] == 1) {
//         miss++;
//       }
//
//       if (record.trail3Answers[i] == 1) {
//         miss++;
//       }
//
//     }
//
//     if (ngParts == 0) {
//       return 0;
//     }
//
//     return (miss / (ngParts * 3)) * 100;
//
//   }
//   static double _calculateEffectiveness(
//       ArrRecord record,
//       ) {
//
//     return _calculateAgreement(record);
//
//   }
//   static double _calculateKappa(
//       ArrRecord record,
//       ) {
//
//     final agreement =
//         _calculateAgreement(record) / 100;
//
//     final okCount =
//         record.masterAnswers.where((e) => e == 1).length;
//
//     final ngCount =
//         record.masterAnswers.where((e) => e == 0).length;
//
//     final observedOk =
//
//         record.trail1Answers.where((e) => e == 1).length +
//
//             record.trail2Answers.where((e) => e == 1).length +
//
//             record.trail3Answers.where((e) => e == 1).length;
//
//     final observedNg =
//
//         record.trail1Answers.where((e) => e == 0).length +
//
//             record.trail2Answers.where((e) => e == 0).length +
//
//             record.trail3Answers.where((e) => e == 0).length;
//
//     final total = record.masterAnswers.length * 3;
//
//     if (total == 0) {
//       return 0;
//     }
//
//     final p1 =
//         (okCount / record.masterAnswers.length) *
//             (observedOk / total);
//
//     final p0 =
//         (ngCount / record.masterAnswers.length) *
//             (observedNg / total);
//
//     final chance = p1 + p0;
//
//     if ((1 - chance) == 0) {
//
//       return agreement == 1
//           ? 100
//           : 0;
//
//     }
//
//     return ((agreement - chance) /
//         (1 - chance)) *
//         100;
//
//   }
//   // static int _excelSame(
//   //     String trial1,
//   //     String trial2,
//   //     String trial3,
//   //     ) {
//   //   // Excel:
//   //   // =IF(F4="",IF(AND(D4="",E4=""),"",IF(E4="","N/A",IF(D4=E4,1,0))),IF(AND(D4=E4,E4=F4),1,0))
//   //
//   //   if (trial3.isEmpty) {
//   //     if (trial1.isEmpty && trial2.isEmpty) {
//   //       return 0;
//   //     }
//   //
//   //     if (trial2.isEmpty) {
//   //       return 0;
//   //     }
//   //
//   //     return trial1 == trial2 ? 1 : 0;
//   //   }
//   //
//   //   return (trial1 == trial2 && trial2 == trial3) ? 1 : 0;
//   // }
//   static int _excelSame(
//       String t1,
//       String t2,
//       String t3,
//       ) {
//
//     // Excel:
//     // =IF(F4="",
//     //      IF(AND(D4="",E4=""),"",
//     //         IF(E4="","N/A",
//     //            IF(D4=E4,1,0))),
//     //      IF(AND(D4=E4,E4=F4),1,0))
//
//     if (t1.isEmpty && t2.isEmpty && t3.isEmpty) {
//       return -1;
//     }
//
//     if (t3.isEmpty) {
//
//       if (t2.isEmpty) {
//         return -1;
//       }
//
//       return t1 == t2 ? 1 : 0;
//     }
//
//     return (t1 == t2 && t2 == t3)
//         ? 1
//         : 0;
//   }
//
//   static int _excelCorrect(
//       String expert,
//       String trial1,
//       String trial2,
//       String trial3,
//       ) {
//     // Excel:
//     // =IF($C4="","",IF(AND(F4="",E4=""),IF($C4=D4,1,0),IF(F4="",IF(AND($C4=E4,$C4=D4),1,0),IF(AND($C4=F4,$C4=E4,$C4=D4),1,0))))
//
//     if (expert.isEmpty) {
//       return -1;
//     }
//
//     // if (trial3.isEmpty && trial2.isEmpty) {
//     //   return expert == trial1 ? 1 : 0;
//     // }
//     if (trial2.isEmpty && trial3.isEmpty) {
//       return -1;
//     }
//     // if (trial3.isEmpty) {
//     //   return (expert == trial1 && expert == trial2)
//     //       ? 1
//     //       : 0;
//     // }
//     if (trial3.isEmpty) {
//
//       if (trial2.isEmpty) {
//         return -1;
//       }
//
//       return
//         (expert == trial1 &&
//             expert == trial2)
//             ? 1
//             : 0;
//     }
//     return (expert == trial1 &&
//         expert == trial2 &&
//         expert == trial3)
//         ? 1
//         : 0;
//   }
//
//   static int _excelOverkill(
//       String expert,
//       String trial1,
//       String trial2,
//       String trial3,
//       ) {
//     // Excel:
//     // =IF($C4="fail",0,COUNTIF(D4:F4,"fail"))
//
//     if (expert == "0") {
//       return 0;
//     }
//
//     int count = 0;
//
//     if (trial1 == "0") count++;
//     if (trial2 == "0") count++;
//     if (trial3 == "0") count++;
//
//     return count;
//   }
//
//   static int _excelEscape(
//       String expert,
//       String trial1,
//       String trial2,
//       String trial3,
//       ) {
//     // Excel:
//     // =IF($C4="pass",0,COUNTIF(D4:F4,"pass"))
//
//     if (expert == "1") {
//       return 0;
//     }
//
//     int count = 0;
//
//     if (trial1 == "1") count++;
//     if (trial2 == "1") count++;
//     if (trial3 == "1") count++;
//
//     return count;
//   }
//
//   // static Map<String, dynamic> _buildCrossTab(
//   //     List<CalculationRow> calculations,
//   //     Map<String, dynamic> totals,
//   //     ) {
//   //   int passPass = 0;
//   //   int passFail = 0;
//   //   int failPass = 0;
//   //   int failFail = 0;
//   //
//   //   void process(String expert, String trial) {
//   //     if (expert == "1") {
//   //       if (trial == "1") {
//   //         passPass++;
//   //       } else {
//   //         passFail++;
//   //       }
//   //     } else {
//   //       if (trial == "1") {
//   //         failPass++;
//   //       } else {
//   //         failFail++;
//   //       }
//   //     }
//   //   }
//   //
//   //   for (final row in calculations) {
//   //     for (final op in row.operators) {
//   //       process(row.expert, op.trial1);
//   //       process(row.expert, op.trial2);
//   //       process(row.expert, op.trial3);
//   //     }
//   //   }
//   //
//   //   final total =
//   //       passPass +
//   //           passFail +
//   //           failPass +
//   //           failFail;
//   //
//   //   if (total == 0) {
//   //     return {
//   //       "matrix": {
//   //         "PP": 0,
//   //         "PF": 0,
//   //         "FP": 0,
//   //         "FF": 0,
//   //       },
//   //       "total": 0,
//   //       "observedAgreement": 0.0,
//   //       "chanceAgreement": 0.0,
//   //       "kappa": 0.0,
//   //       "kappaPercent": 0.0,
//   //     };
//   //   }
//   //
//   //   final observed =
//   //       (passPass + failFail) / total;
//   //
//   //   final rowPass =
//   //       (passPass + passFail) / total;
//   //
//   //   final rowFail =
//   //       (failPass + failFail) / total;
//   //
//   //   final columnPass =
//   //       (passPass + failPass) / total;
//   //
//   //   final columnFail =
//   //       (passFail + failFail) / total;
//   //
//   //   final chance =
//   //       (rowPass * columnPass) +
//   //           (rowFail * columnFail);
//   //
//   //   final kappa =
//   //   (1 - chance) == 0
//   //       ? 0.0
//   //       : (observed - chance) /
//   //       (1 - chance);
//   //
//   //   return {
//   //     "matrix": {
//   //       "PP": passPass,
//   //       "PF": passFail,
//   //       "FP": failPass,
//   //       "FF": failFail,
//   //     },
//   //     "total": total,
//   //     "observedAgreement": observed,
//   //     "chanceAgreement": chance,
//   //     "kappa": kappa,
//   //     "kappaPercent": kappa * 100,
//   //     "totals": totals,
//   //   };
//   // }
//
//   static Map<String, dynamic> _buildCrossTab(
//       List<CalculationRow> calculations,
//       Map<String, dynamic> totals,
//       ) {
//     if (calculations.isEmpty) {
//       return {};
//     }
//
//     final operatorCount = calculations.first.operators.length;
//
//     final List<Map<String, dynamic>> operators = [];
//
//     for (int index = 0; index < operatorCount; index++) {
//       int passPass = 0;
//       int passFail = 0;
//       int failPass = 0;
//       int failFail = 0;
//
//       for (final row in calculations) {
//         final op = row.operators[index];
//
//         void process(String trial) {
//           if (row.expert == "1") {
//             if (trial == "1") {
//               passPass++;
//             } else {
//               passFail++;
//             }
//           } else {
//             if (trial == "1") {
//               failPass++;
//             } else {
//               failFail++;
//             }
//           }
//         }
//
//         process(op.trial1);
//         process(op.trial2);
//         process(op.trial3);
//       }
//
//       final total =
//           passPass +
//               passFail +
//               failPass +
//               failFail;
//
//       final observed =
//       total == 0
//           ? 0
//           : (passPass + failFail) / total;
//
//       final rowPass =
//       total == 0
//           ? 0
//           : (passPass + passFail) / total;
//
//       final rowFail =
//       total == 0
//           ? 0
//           : (failPass + failFail) / total;
//
//       final columnPass =
//       total == 0
//           ? 0
//           : (passPass + failPass) / total;
//
//       final columnFail =
//       total == 0
//           ? 0
//           : (passFail + failFail) / total;
//
//       final chance =
//           rowPass * columnPass +
//               rowFail * columnFail;
//
//       final kappa =
//       (1 - chance) == 0
//           ? 0
//           : (observed - chance) /
//           (1 - chance);
//
//       operators.add({
//         "PP": passPass,
//         "PF": passFail,
//         "FP": failPass,
//         "FF": failFail,
//         "total": total,
//         "observedAgreement": observed,
//         "chanceAgreement": chance,
//         "kappa": kappa,
//         "kappaPercent": kappa * 100,
//       });
//     }
//
//     return {
//       "operators": operators,
//       "totals": totals,
//     };
//   }
//   static Map<String, dynamic> _buildSummary(
//       List<ArrRecord> records,
//       Map<String, dynamic> statisticalReport,
//       Map<String, dynamic> crossTab,
//       ){
//     // double avg(List<double> values) {
//     //   if (values.isEmpty) return 0;
//     //   return values.reduce((a, b) => a + b) / values.length;
//     // }
//
//     // final agreement =
//     //     statisticalReport["repeatabilityPercent"] ?? 0.0;
//     //
//     // final falseAlert =
//     //     (statisticalReport["overkill"]?["percent"]) ?? 0.0;
//     //
//     // final missRate =
//     //     (statisticalReport["escape"]?["percent"]) ?? 0.0;
//     //
//     // final effectiveness =
//     //     statisticalReport["effectivenessPercent"] ?? 0.0;
//     final operatorStats =
//     (statisticalReport["operators"] as List)
//         .cast<Map<String, dynamic>>();
//
//     final agreement =
//         statisticalReport["repeatabilityPercent"] ?? 0.0;
//
//     final effectiveness =
//         statisticalReport["effectivenessPercent"] ?? 0.0;
//
//     final falseAlert =
//     (statisticalReport["overkill"]["percent"] as num)
//         .toDouble();
//
//     final missRate =
//     (statisticalReport["escape"]["percent"] as num)
//         .toDouble();
//
//     final List<double> operatorScores =
//     operatorStats
//         .map(
//           (e) =>
//       (e["calculatedScore"] as num).toDouble() * 100,
//     )
//         .toList();
//
//     final List<double> operatorFalseAlarm =
//     operatorStats
//         .map(
//           (e) =>
//           (e["overkill"] as num).toDouble(),
//     )
//         .toList();
//
//     final List<double> operatorEscape =
//     operatorStats
//         .map(
//           (e) =>
//           (e["escape"] as num).toDouble(),
//     )
//         .toList();
//     final kappa =
//         (crossTab["operators"] as List)
//             .cast<Map<String, dynamic>>()
//             .fold<double>(
//           0.0,
//               (sum, e) => sum + (e["kappaPercent"] ?? 0.0),
//         ) /
//             ((crossTab["operators"] as List).isEmpty
//                 ? 1
//                 : (crossTab["operators"] as List).length);
//
//     String classifyAgreement(double value) {
//       final score = value / 100;
//
//       if (score >= 0.90) {
//         return "Acceptable";
//       }
//
//       if (score < 0.80) {
//         return "Unacceptable";
//       }
//
//       return "Marginally acceptable";
//     }
//
//     String classifyOverkill(double value) {
//       if (value <= 2) {
//         return "Acceptable";
//       }
//
//       if (value <= 5) {
//         return "Marginally acceptable";
//       }
//
//       return "Unacceptable";
//     }
//
//     String classifyEscape(double value) {
//       if (value <= 5) {
//         return "Acceptable";
//       }
//
//       if (value <= 10) {
//         return "Marginally acceptable";
//       }
//
//       return "Unacceptable";
//     }
//
//     return {
//
//       "operatorScores": operatorScores,
//
//       "operatorFalseAlarm": operatorFalseAlarm,
//
//       "operatorEscape": operatorEscape,
//       "candidateCount": records.length,
//       "partCount":
//       records.isEmpty ? 0 : records.first.masterAnswers.length,
//
//       "agreement": agreement,
//       "falseAlert": falseAlert,
//       "missRate": missRate,
//       "effectiveness": effectiveness,
//       "kappa": kappa,
//
//       "repeatability":
//       statisticalReport["repeatabilityPercent"] ?? 0.0,
//
//       "reproducibility":
//       statisticalReport["reproducibilityPercent"] ?? 0.0,
//
//       "overallAgreement":
//       effectiveness,
//       //statisticalReport["effectivenessPercent"] ?? 0.0,
//
//       "repeatabilityStatus":
//       classifyAgreement(
//         statisticalReport["repeatabilityPercent"] ?? 0.0,
//       ),
//
//       "reproducibilityStatus":
//       classifyAgreement(
//         statisticalReport["reproducibilityPercent"] ?? 0.0,
//       ),
//
//       // "falseAlertStatus":
//       // classifyOverkill(falseAlert),
//       //
//       // "missRateStatus":
//       // classifyEscape(missRate),
//       "falseAlertStatus":
//       classifyOverkill(falseAlert),
//
//       "missRateStatus":
//       classifyEscape(missRate),
//
//       "overallStatus":
//       classifyAgreement(effectiveness),
//     };
//   }
//   static double _calculateRepeatability(
//       List<ArrRecord> records,
//       ) {
//
//     if (records.isEmpty) {
//       return 0;
//     }
//
//     int same = 0;
//
//     int total = 0;
//
//     for (final candidate in records) {
//
//       for (int i = 0;
//       i < candidate.masterAnswers.length;
//       i++) {
//
//         total++;
//
//         final t1 =
//         candidate.trail1Answers[i];
//
//         final t2 =
//         candidate.trail2Answers[i];
//
//         final t3 =
//         candidate.trail3Answers[i];
//
//         if (t1 == t2 &&
//             t2 == t3) {
//
//           same++;
//
//         }
//
//       }
//
//     }
//
//     if (total == 0) {
//       return 0;
//     }
//
//     return (same / total) * 100;
//
//   }
//   static double _calculateReproducibility(
//       List<ArrRecord> records,
//       ) {
//
//     if (records.length < 2) {
//       return 100;
//     }
//
//     final totalParts =
//         records.first.masterAnswers.length;
//
//     int agree = 0;
//
//     for (int part = 0;
//     part < totalParts;
//     part++) {
//
//       bool same = true;
//
//       final firstAnswer =
//       records.first.trail1Answers[part];
//
//       for (final operator in records) {
//
//         if (operator.trail1Answers[part] !=
//             firstAnswer) {
//
//           same = false;
//
//           break;
//
//         }
//
//       }
//
//       if (same) {
//         agree++;
//       }
//
//     }
//
//     return (agree / totalParts) * 100;
//
//   }
//   static double _calculateOverallAgreement(
//       List<ArrRecord> records,
//       ) {
//
//     if (records.isEmpty) {
//       return 0;
//     }
//
//     double sum = 0;
//
//     for (final candidate in records) {
//
//       sum +=
//           _calculateAgreement(candidate);
//
//     }
//
//     return sum / records.length;
//
//   }
// }





// //This is prev version of code given by chatgpt
// import '../models/arr_record.dart';
// import '../models/cross_tab_result.dart';
// import '../utils/beta_stats.dart';
//
// class CrossTabService {
//   CrossTabService._();
//
//   static CrossTabResult generate(
//       List<ArrRecord> records,
//       ) {
//     if (records.length < 2) {
//       throw Exception(
//         "Minimum two candidates required.",
//       );
//     }
//
//     final batchId = records.first.batchId;
//
//     if (!records.every((e) => e.batchId == batchId)) {
//       throw Exception(
//         "Selected candidates belong to different batches.",
//       );
//     }
//
//     final dataEntry = _buildDataEntry(records);
//
//     final calculations =
//     _buildCalculationMatrix(dataEntry);
//
//     final calculationTotals =
//     _buildCalculationTotals(calculations);
//
//     final statisticalReport =
//     _buildStatisticalReport(
//       calculations,
//       calculationTotals,
//     );
//
//     final statistics =
//     _buildStatistics(records);
//
//     final crossTab =
//     _buildCrossTab(
//       calculations,
//       calculationTotals,
//     );
//
//     final summary =
//     _buildSummary(
//       records,
//       statisticalReport,
//       crossTab,
//     );
//
//     return CrossTabResult(
//       candidates: records,
//       dataEntry: dataEntry,
//       calculations: calculations,
//       statisticalReport: statisticalReport,
//       crossTab: crossTab,
//       arrSummary: summary,
//     );
//   }
//
//   static List<DataEntryRow> _buildDataEntry(
//       List<ArrRecord> records,
//       ) {
//
//     final List<DataEntryRow> rows = [];
//
//     if (records.isEmpty) {
//       return rows;
//     }
//
//     final first = records.first;
//
//     final totalParts = first.partNumbers.length;
//
//     for (int part = 0; part < totalParts; part++) {
//
//       final List<OperatorTrials> operators = [];
//
//       for (final candidate in records) {
//
//         operators.add(
//
//           OperatorTrials(
//
//             employeeCode: candidate.employeeCode,
//
//             candidateName: candidate.appraisee,
//
//             trial1: candidate.trail1Answers[part],
//
//             trial2: candidate.trail2Answers[part],
//
//             trial3: candidate.trail3Answers[part],
//
//           ),
//
//         );
//
//       }
//
//       rows.add(
//
//         DataEntryRow(
//
//           partNumber: first.partNumbers[part],
//
//           expert: first.masterAnswers[part],
//
//           operatorTrials: operators,
//
//         ),
//
//       );
//
//     }
//
//     return rows;
//
//   }
//   static List<CalculationRow> _buildCalculationMatrix(
//       List<DataEntryRow> dataEntry,
//       ) {
//     final List<CalculationRow> rows = [];
//
//     int sampleNo = 1;
//
//     for (final row in dataEntry) {
//       final expert = row.expert.toString();
//
//       final List<OperatorCalculation> operators = [];
//
//       for (final operator in row.operatorTrials) {
//         final t1 = operator.trial1.toString();
//         final t2 = operator.trial2.toString();
//         final t3 = operator.trial3.toString();
//         operators.add(
//           OperatorCalculation(
//             employeeCode: operator.employeeCode,
//             candidateName: operator.candidateName,
//
//             trial1: t1,
//             trial2: t2,
//             trial3: t3,
//
//             same: _excelSame(t1, t2, t3),
//             correct: _excelCorrect(expert, t1, t2, t3),
//             overkill: _excelOverkill(expert, t1, t2, t3),
//             escape: _excelEscape(expert, t1, t2, t3),
//           ),
//         );
//       }
//
//       int repeatability = 0;
//       int reproducibility = 0;
//
//       if (operators.isNotEmpty) {
//         // Excel: Calculations!Y4
//         //   =IF(SUM(G4,N4,U4)>0, IF(G4=N4,IF(N4=U4,IF(U4=G4,1,0),0),0), 0)
//         // Because G/N/U are each 0 or 1, "SUM>0 AND all mutually equal"
//         // reduces to "all three equal 1" — so we test that directly.
//         repeatability = operators.every((e) => e.same == 1) ? 1 : 0;
//
//         // Excel: Calculations!Z4 (same shape, using H/O/V "correct")
//         reproducibility = operators.every((e) => e.correct == 1) ? 1 : 0;
//       }
//
//       rows.add(
//         CalculationRow(
//           sampleNo: sampleNo,
//           expert: expert,
//           operators: operators,
//           overallRepeatability: repeatability,
//           overallReproducibility: reproducibility,
//         ),
//       );
//
//       sampleNo++;
//     }
//
//     return rows;
//   }
//   static Map<String, dynamic> _buildCalculationTotals(
//       List<CalculationRow> calculations,
//       ) {
//     if (calculations.isEmpty) {
//       return {};
//     }
//
//     final operatorCount = calculations.first.operators.length;
//
//     final List<Map<String, dynamic>> operators = [];
//
//     int totalOverkill = 0;
//     int totalEscape = 0;
//
//     for (int i = 0; i < operatorCount; i++) {
//
//       int sameCount = 0;
//       int correctCount = 0;
//       int overkill = 0;
//       int escape = 0;
//
//       int sameTotal = 0;
//       int correctTotal = 0;
//
//       for (final row in calculations) {
//
//         final op = row.operators[i];
//
//         if (op.same == 0 || op.same == 1) {
//           sameTotal++;
//           sameCount += op.same;
//         }
//
//         if (op.correct == 0 || op.correct == 1) {
//           correctTotal++;
//           correctCount += op.correct;
//         }
//
//         overkill += op.overkill;
//         escape += op.escape;
//       }
//
//       totalOverkill += overkill;
//       totalEscape += escape;
//
//       operators.add({
//         "appraiserScore":
//         sameTotal == 0 ? 0.0 : sameCount / sameTotal,
//
//         "attributeScore":
//         correctTotal == 0 ? 0.0 : correctCount / correctTotal,
//
//         "sameCount": sameCount,
//         "sameTotal": sameTotal,
//
//         "correctCount": correctCount,
//         "correctTotal": correctTotal,
//
//         "overkill": overkill,
//         "escape": escape,
//       });
//     }
//
//     // Excel: Calculations!C106 = 'Data Entry'!F9*'Data Entry'!F10
//     // i.e. operator count * trial count (a per-study constant — NOT
//     // sample count * 3, which is what this used to compute).
//     const int trialsPerSample = 3;
//     final int opsTries = operatorCount * trialsPerSample;
//
//     // Excel: Calculations!C107 = SUM(I108:X108), i.e. total overkill
//     // trials PLUS total escape trials (this used to only count overkill).
//     final int defects = totalOverkill + totalEscape;
//
//     // Excel: Statistical Report!C29 = Calculations!C105*Calculations!C106
//     final int totalOpportunities = calculations.length * opsTries;
//
//     // Excel: Statistical Report!C30 = C29 - Calculations!C107
//     final int accurateCount = totalOpportunities - defects;
//
//     return {
//       "operators": operators,
//
//       "sampleCount": calculations.length,
//
//       "opsTries": opsTries,
//
//       "defects": defects,
//
//       "totalOpportunities": totalOpportunities,
//
//       "accurateCount": accurateCount,
//
//       "OVERKILL": totalOverkill,
//
//       "ESCAPE": totalEscape,
//     };
//   }
//   static Map<String, dynamic> _buildStatisticalReport(
//       List<CalculationRow> calculations,
//       Map<String, dynamic> calculationTotals,
//       ) {
//     if (calculations.isEmpty) {
//       return {};
//     }
//
//     final operators =
//     calculationTotals["operators"] as List<Map<String, dynamic>>;
//
//     final totalOperators = operators.length;
//
//     int same = 0;
//     int sameTotal = 0;
//
//     int correct = 0;
//     int correctTotal = 0;
//
//     int overkill = 0;
//     int escape = 0;
//
//     for (final op in operators) {
//
//       same += op["sameCount"] as int;
//       sameTotal += op["sameTotal"] as int;
//
//       correct += op["correctCount"] as int;
//       correctTotal += op["correctTotal"] as int;
//
//       overkill += op["overkill"] as int;
//       escape += op["escape"] as int;
//     }
//
//     // Excel: Statistical Report!C22/C23 and !F22/F23 count SAMPLES (not
//     // operator-trials) via Data Entry!O and !P, which read
//     // Calculations!Y and !Z — "did every operator agree with themselves
//     // AND with each other on this sample". This is a per-sample count,
//     // distinct from same/sameTotal and correct/correctTotal above (which
//     // are summed per-operator trial counts).
//     final int sampleCount = calculations.length;
//
//     final int agreementSamples =
//         calculations.where((row) => row.overallRepeatability == 1).length;
//
//     final int effectiveSamples =
//         calculations.where((row) => row.overallReproducibility == 1).length;
//
//     final repeatability =
//     sameTotal == 0 ? 0.0 : same / sameTotal;
//
//     final reproducibility =
//     correctTotal == 0 ? 0.0 : correct / correctTotal;
//
//     final falseAlert =
//     correctTotal == 0 ? 0.0 : overkill / correctTotal;
//
//     final missRate =
//     correctTotal == 0 ? 0.0 : escape / correctTotal;
//
//     final effectiveness =
//         1 - falseAlert - missRate;
//     final operatorStatistics = operators.map((op) {
//
//       final inspected =
//       op["sameTotal"] as int;
//
//       final matched =
//       op["sameCount"] as int;
//
//       final attributeInspected =
//       op["correctTotal"] as int;
//
//       final attributeMatched =
//       op["correctCount"] as int;
//
//       return {
//
//         // Excel row 10
//         "totalInspected": inspected,
//
//         // Excel row 11
//         "matched": matched,
//
//         // Excel row 14
//         "calculatedScore":
//         inspected == 0
//             ? 0.0
//             : matched / inspected,
//
//         // Score vs Attribute
//         "attributeTotal":
//         attributeInspected,
//
//         "attributeMatched":
//         attributeMatched,
//
//         "attributeScore":
//         attributeInspected == 0
//             ? 0.0
//             : attributeMatched / attributeInspected,
//
//         // Excel rows 16 & 17
//         "escape": op["escape"],
//
//         "overkill": op["overkill"],
//
//       };
//
//     }).toList();
//
//     return {
//
//       "sampleCount":
//       calculationTotals["sampleCount"],
//
//       "opsTries":
//       calculationTotals["opsTries"],
//
//       "defects":
//       calculationTotals["defects"],
//
//       "operatorCount":
//       totalOperators,
//
//       "operators": List.generate(
//         operatorStatistics.length,
//             (index) {
//           final op = operatorStatistics[index];
//
//           return {
//             "operatorNo": index + 1,
//
//             // ==========================
//             // Excel Rows 10-17
//             // ==========================
//
//             "totalInspected": op["totalInspected"],
//             "matched": op["matched"],
//             "calculatedScore": op["calculatedScore"],
//
//             "escape": op["escape"],
//             "overkill": op["overkill"],
//
//             // Confidence limits
//             // Excel: Statistical Report!B13:G13 (95% UCL) and
//             // Statistical Report!B15:G15 (95% LCL), built on BETAINV.
//             "lcl95": BetaStat.lcl95(
//               op["matched"] as int,
//               op["totalInspected"] as int,
//             ),
//             "ucl95": BetaStat.ucl95(
//               op["matched"] as int,
//               op["totalInspected"] as int,
//             ),
//           };
//         },
//       ),
//
//       "appraiserScores": operatorStatistics
//           .map(
//             (e) => (e["calculatedScore"] as double) * 100,
//       )
//           .toList(),
//
//       "attributeScores": operatorStatistics
//           .map(
//             (e) => (e["attributeScore"] as double) * 100,
//       )
//           .toList(),
//       "repeatability": repeatability,
//       "repeatabilityPercent": repeatability * 100,
//
//       "reproducibility": reproducibility,
//       "reproducibilityPercent": reproducibility * 100,
//
//       "overkill": {
//         "count": overkill,
//         "percent": falseAlert * 100,
//       },
//
//       "escape": {
//         "count": escape,
//         "percent": missRate * 100,
//       },
//
//       "effectiveness": effectiveness,
//       "effectivenessPercent": effectiveness * 100,
//
//       // ===== DATA ENTRY FOOTER =====
//
//       // Excel -> Calculations!U104
//       "appraiserScore": repeatability * 100,
//
//       // Excel -> Calculations!V104
//       "attributeScore": reproducibility * 100,
//
//       // ===========================================================
//       // EFFECTIVE SCORE (Excel Rows 22-26)
//       // Excel: Statistical Report!C22 (total samples), !C23 (# in
//       // agreement, from Data Entry!O -> Calculations!Y)
//       // ===========================================================
//
//       "effectiveScore": {
//         "totalInspected": sampleCount,
//         "yesCount": agreementSamples,
//         "score":
//         sampleCount == 0
//             ? 0.0
//             : agreementSamples / sampleCount,
//
//         // Excel: Statistical Report!C24 (95% UCL) and !C26 (95% LCL)
//         "lcl95": BetaStat.lcl95(agreementSamples, sampleCount),
//         "ucl95": BetaStat.ucl95(agreementSamples, sampleCount),
//       },
//
//       // ===========================================================
//       // EFFECTIVE SCORE VS ATTRIBUTE
//       // Excel: Statistical Report!F22 (total samples), !F23 (# in
//       // agreement, from Data Entry!P -> Calculations!Z)
//       // ===========================================================
//
//       "effectiveScoreVsAttribute": {
//         "totalInspected": sampleCount,
//         "yesCount": effectiveSamples,
//         "score":
//         sampleCount == 0
//             ? 0.0
//             : (effectiveSamples / sampleCount) * 100,
//
//         // Excel: Statistical Report!F24 (95% UCL) and !F26 (95% LCL)
//         "lcl95": BetaStat.lcl95(effectiveSamples, sampleCount),
//         "ucl95": BetaStat.ucl95(effectiveSamples, sampleCount),
//       },
//
//       // ===========================================================
//       // ATTRIBUTE INSPECTION ACCURACY
//       // Excel:
//       // C29 = Total
//       // C30 = Correct
//       // C32 = Correct / Total
//       // ===========================================================
//
//       "attributeInspectionAccuracy": {
//         // Excel: Statistical Report!C29
//         "total": calculationTotals["totalOpportunities"],
//         // Excel: Statistical Report!C30
//         "correct": calculationTotals["accurateCount"],
//         // Excel: Statistical Report!C32
//         "score":
//         (calculationTotals["totalOpportunities"] as int) == 0
//             ? 0.0
//             : (calculationTotals["accurateCount"] as int) /
//             (calculationTotals["totalOpportunities"] as int),
//
//         // Excel: Statistical Report!C31 (95% UCL) / !C33 (95% LCL)
//         "lcl95": BetaStat.lcl95(
//           calculationTotals["accurateCount"] as int,
//           calculationTotals["totalOpportunities"] as int,
//         ),
//         "ucl95": BetaStat.ucl95(
//           calculationTotals["accurateCount"] as int,
//           calculationTotals["totalOpportunities"] as int,
//         ),
//       },
//     };
//   }
//   static List<OperatorStatistics> _buildStatistics(
//       List<ArrRecord> records,
//       ) {
//
//     final List<OperatorStatistics> statistics = [];
//
//     for (final candidate in records) {
//
//       final agreement = _calculateAgreement(candidate);
//
//       final falseAlert = _calculateFalseAlert(candidate);
//
//       final missRate = _calculateMissRate(candidate);
//
//       final effectiveness = _calculateEffectiveness(candidate);
//
//       final kappa = _calculateKappa(candidate);
//
//       statistics.add(
//
//         OperatorStatistics(
//
//           employeeCode: candidate.employeeCode,
//
//           candidate: candidate.appraisee,
//
//           agreement: agreement,
//
//           falseAlert: falseAlert,
//
//           missRate: missRate,
//
//           effectiveness: effectiveness,
//
//           kappa: kappa,
//
//         ),
//
//       );
//
//     }
//
//     return statistics;
//
//   }
//   static double _calculateAgreement(
//       ArrRecord record,
//       ) {
//
//     int correct = 0;
//
//     int total = record.masterAnswers.length * 3;
//
//     for (int i = 0; i < record.masterAnswers.length; i++) {
//
//       if (record.trail1Answers[i] == record.masterAnswers[i]) {
//         correct++;
//       }
//
//       if (record.trail2Answers[i] == record.masterAnswers[i]) {
//         correct++;
//       }
//
//       if (record.trail3Answers[i] == record.masterAnswers[i]) {
//         correct++;
//       }
//
//     }
//
//     if (total == 0) {
//       return 0;
//     }
//
//     return (correct / total) * 100;
//
//   }
//   static double _calculateFalseAlert(
//       ArrRecord record,
//       ) {
//
//     int falseAlert = 0;
//
//     int okParts = 0;
//
//     for (int i = 0; i < record.masterAnswers.length; i++) {
//
//       if (record.masterAnswers[i] != 1) {
//         continue;
//       }
//
//       okParts++;
//
//       if (record.trail1Answers[i] == 0) {
//         falseAlert++;
//       }
//
//       if (record.trail2Answers[i] == 0) {
//         falseAlert++;
//       }
//
//       if (record.trail3Answers[i] == 0) {
//         falseAlert++;
//       }
//
//     }
//
//     if (okParts == 0) {
//       return 0;
//     }
//
//     return (falseAlert / (okParts * 3)) * 100;
//
//   }
//   static double _calculateMissRate(
//       ArrRecord record,
//       ) {
//
//     int miss = 0;
//
//     int ngParts = 0;
//
//     for (int i = 0; i < record.masterAnswers.length; i++) {
//
//       if (record.masterAnswers[i] != 0) {
//         continue;
//       }
//
//       ngParts++;
//
//       if (record.trail1Answers[i] == 1) {
//         miss++;
//       }
//
//       if (record.trail2Answers[i] == 1) {
//         miss++;
//       }
//
//       if (record.trail3Answers[i] == 1) {
//         miss++;
//       }
//
//     }
//
//     if (ngParts == 0) {
//       return 0;
//     }
//
//     return (miss / (ngParts * 3)) * 100;
//
//   }
//   static double _calculateEffectiveness(
//       ArrRecord record,
//       ) {
//
//     return _calculateAgreement(record);
//
//   }
//   static double _calculateKappa(
//       ArrRecord record,
//       ) {
//
//     final agreement =
//         _calculateAgreement(record) / 100;
//
//     final okCount =
//         record.masterAnswers.where((e) => e == 1).length;
//
//     final ngCount =
//         record.masterAnswers.where((e) => e == 0).length;
//
//     final observedOk =
//
//         record.trail1Answers.where((e) => e == 1).length +
//
//             record.trail2Answers.where((e) => e == 1).length +
//
//             record.trail3Answers.where((e) => e == 1).length;
//
//     final observedNg =
//
//         record.trail1Answers.where((e) => e == 0).length +
//
//             record.trail2Answers.where((e) => e == 0).length +
//
//             record.trail3Answers.where((e) => e == 0).length;
//
//     final total = record.masterAnswers.length * 3;
//
//     if (total == 0) {
//       return 0;
//     }
//
//     final p1 =
//         (okCount / record.masterAnswers.length) *
//             (observedOk / total);
//
//     final p0 =
//         (ngCount / record.masterAnswers.length) *
//             (observedNg / total);
//
//     final chance = p1 + p0;
//
//     if ((1 - chance) == 0) {
//
//       return agreement == 1
//           ? 100
//           : 0;
//
//     }
//
//     return ((agreement - chance) /
//         (1 - chance)) *
//         100;
//
//   }
//   static int _excelSame(
//       String trial1,
//       String trial2,
//       String trial3,
//       ) {
//     // Excel:
//     // =IF(F4="",IF(AND(D4="",E4=""),"",IF(E4="","N/A",IF(D4=E4,1,0))),IF(AND(D4=E4,E4=F4),1,0))
//
//     if (trial3.isEmpty) {
//       if (trial1.isEmpty && trial2.isEmpty) {
//         return 0;
//       }
//
//       if (trial2.isEmpty) {
//         return 0;
//       }
//
//       return trial1 == trial2 ? 1 : 0;
//     }
//
//     return (trial1 == trial2 && trial2 == trial3) ? 1 : 0;
//   }
//
//   static int _excelCorrect(
//       String expert,
//       String trial1,
//       String trial2,
//       String trial3,
//       ) {
//     // Excel:
//     // =IF($C4="","",IF(AND(F4="",E4=""),IF($C4=D4,1,0),IF(F4="",IF(AND($C4=E4,$C4=D4),1,0),IF(AND($C4=F4,$C4=E4,$C4=D4),1,0))))
//
//     if (expert.isEmpty) {
//       return 0;
//     }
//
//     if (trial3.isEmpty && trial2.isEmpty) {
//       return expert == trial1 ? 1 : 0;
//     }
//
//     if (trial3.isEmpty) {
//       return (expert == trial1 && expert == trial2)
//           ? 1
//           : 0;
//     }
//
//     return (expert == trial1 &&
//         expert == trial2 &&
//         expert == trial3)
//         ? 1
//         : 0;
//   }
//
//   static int _excelOverkill(
//       String expert,
//       String trial1,
//       String trial2,
//       String trial3,
//       ) {
//     // Excel:
//     // =IF($C4="fail",0,COUNTIF(D4:F4,"fail"))
//
//     if (expert == "0") {
//       return 0;
//     }
//
//     int count = 0;
//
//     if (trial1 == "0") count++;
//     if (trial2 == "0") count++;
//     if (trial3 == "0") count++;
//
//     return count;
//   }
//
//   static int _excelEscape(
//       String expert,
//       String trial1,
//       String trial2,
//       String trial3,
//       ) {
//     // Excel:
//     // =IF($C4="pass",0,COUNTIF(D4:F4,"pass"))
//
//     if (expert == "1") {
//       return 0;
//     }
//
//     int count = 0;
//
//     if (trial1 == "1") count++;
//     if (trial2 == "1") count++;
//     if (trial3 == "1") count++;
//
//     return count;
//   }
//
//   // static Map<String, dynamic> _buildCrossTab(
//   //     List<CalculationRow> calculations,
//   //     Map<String, dynamic> totals,
//   //     ) {
//   //   int passPass = 0;
//   //   int passFail = 0;
//   //   int failPass = 0;
//   //   int failFail = 0;
//   //
//   //   void process(String expert, String trial) {
//   //     if (expert == "1") {
//   //       if (trial == "1") {
//   //         passPass++;
//   //       } else {
//   //         passFail++;
//   //       }
//   //     } else {
//   //       if (trial == "1") {
//   //         failPass++;
//   //       } else {
//   //         failFail++;
//   //       }
//   //     }
//   //   }
//   //
//   //   for (final row in calculations) {
//   //     for (final op in row.operators) {
//   //       process(row.expert, op.trial1);
//   //       process(row.expert, op.trial2);
//   //       process(row.expert, op.trial3);
//   //     }
//   //   }
//   //
//   //   final total =
//   //       passPass +
//   //           passFail +
//   //           failPass +
//   //           failFail;
//   //
//   //   if (total == 0) {
//   //     return {
//   //       "matrix": {
//   //         "PP": 0,
//   //         "PF": 0,
//   //         "FP": 0,
//   //         "FF": 0,
//   //       },
//   //       "total": 0,
//   //       "observedAgreement": 0.0,
//   //       "chanceAgreement": 0.0,
//   //       "kappa": 0.0,
//   //       "kappaPercent": 0.0,
//   //     };
//   //   }
//   //
//   //   final observed =
//   //       (passPass + failFail) / total;
//   //
//   //   final rowPass =
//   //       (passPass + passFail) / total;
//   //
//   //   final rowFail =
//   //       (failPass + failFail) / total;
//   //
//   //   final columnPass =
//   //       (passPass + failPass) / total;
//   //
//   //   final columnFail =
//   //       (passFail + failFail) / total;
//   //
//   //   final chance =
//   //       (rowPass * columnPass) +
//   //           (rowFail * columnFail);
//   //
//   //   final kappa =
//   //   (1 - chance) == 0
//   //       ? 0.0
//   //       : (observed - chance) /
//   //       (1 - chance);
//   //
//   //   return {
//   //     "matrix": {
//   //       "PP": passPass,
//   //       "PF": passFail,
//   //       "FP": failPass,
//   //       "FF": failFail,
//   //     },
//   //     "total": total,
//   //     "observedAgreement": observed,
//   //     "chanceAgreement": chance,
//   //     "kappa": kappa,
//   //     "kappaPercent": kappa * 100,
//   //     "totals": totals,
//   //   };
//   // }
//
//   static Map<String, dynamic> _buildCrossTab(
//       List<CalculationRow> calculations,
//       Map<String, dynamic> totals,
//       ) {
//     if (calculations.isEmpty) {
//       return {};
//     }
//
//     final operatorCount = calculations.first.operators.length;
//
//     final List<Map<String, dynamic>> operators = [];
//
//     for (int index = 0; index < operatorCount; index++) {
//       int passPass = 0;
//       int passFail = 0;
//       int failPass = 0;
//       int failFail = 0;
//
//       for (final row in calculations) {
//         final op = row.operators[index];
//
//         void process(String trial) {
//           if (row.expert == "1") {
//             if (trial == "1") {
//               passPass++;
//             } else {
//               passFail++;
//             }
//           } else {
//             if (trial == "1") {
//               failPass++;
//             } else {
//               failFail++;
//             }
//           }
//         }
//
//         process(op.trial1);
//         process(op.trial2);
//         process(op.trial3);
//       }
//
//       final total =
//           passPass +
//               passFail +
//               failPass +
//               failFail;
//
//       final observed =
//       total == 0
//           ? 0
//           : (passPass + failFail) / total;
//
//       final rowPass =
//       total == 0
//           ? 0
//           : (passPass + passFail) / total;
//
//       final rowFail =
//       total == 0
//           ? 0
//           : (failPass + failFail) / total;
//
//       final columnPass =
//       total == 0
//           ? 0
//           : (passPass + failPass) / total;
//
//       final columnFail =
//       total == 0
//           ? 0
//           : (passFail + failFail) / total;
//
//       final chance =
//           rowPass * columnPass +
//               rowFail * columnFail;
//
//       final kappa =
//       (1 - chance) == 0
//           ? 0
//           : (observed - chance) /
//           (1 - chance);
//
//       operators.add({
//         "PP": passPass,
//         "PF": passFail,
//         "FP": failPass,
//         "FF": failFail,
//         "total": total,
//         "observedAgreement": observed,
//         "chanceAgreement": chance,
//         "kappa": kappa,
//         "kappaPercent": kappa * 100,
//       });
//     }
//
//     return {
//       "operators": operators,
//       "totals": totals,
//     };
//   }
//   static Map<String, dynamic> _buildSummary(
//       List<ArrRecord> records,
//       Map<String, dynamic> statisticalReport,
//       Map<String, dynamic> crossTab,
//       ){
//     double avg(List<double> values) {
//       if (values.isEmpty) return 0;
//       return values.reduce((a, b) => a + b) / values.length;
//     }
//
//     final agreement =
//         statisticalReport["repeatabilityPercent"] ?? 0.0;
//
//     final falseAlert =
//         (statisticalReport["overkill"]?["percent"]) ?? 0.0;
//
//     final missRate =
//         (statisticalReport["escape"]?["percent"]) ?? 0.0;
//
//     final effectiveness =
//         statisticalReport["effectivenessPercent"] ?? 0.0;
//
//     final kappa =
//         (crossTab["operators"] as List)
//             .cast<Map<String, dynamic>>()
//             .fold<double>(
//           0.0,
//               (sum, e) => sum + (e["kappaPercent"] ?? 0.0),
//         ) /
//             ((crossTab["operators"] as List).isEmpty
//                 ? 1
//                 : (crossTab["operators"] as List).length);
//
//     String classifyAgreement(double value) {
//       final score = value / 100;
//
//       if (score >= 0.90) {
//         return "Acceptable";
//       }
//
//       if (score < 0.80) {
//         return "Unacceptable";
//       }
//
//       return "Marginally acceptable";
//     }
//
//     // Excel ARR-Summmary!I18 (False alarm rate row): <=5% / <=10%.
//     String classifyOverkill(double value) {
//       if (value <= 5) {
//         return "Acceptable";
//       }
//
//       if (value <= 10) {
//         return "Marginally acceptable";
//       }
//
//       return "Unacceptable";
//     }
//
//     // Excel ARR-Summmary!I17 (Miss rate row): <=2% / <=5%.
//     // NOTE: this and classifyOverkill above were previously swapped —
//     // the miss-rate thresholds (2/5) were being applied to false alarm,
//     // and the false-alarm thresholds (5/10) to miss rate.
//     String classifyEscape(double value) {
//       if (value <= 2) {
//         return "Acceptable";
//       }
//
//       if (value <= 5) {
//         return "Marginally acceptable";
//       }
//
//       return "Unacceptable";
//     }
//
//     return {
//       "candidateCount": records.length,
//       "partCount":
//       records.isEmpty ? 0 : records.first.masterAnswers.length,
//
//       "agreement": agreement,
//       "falseAlert": falseAlert,
//       "missRate": missRate,
//       "effectiveness": effectiveness,
//       "kappa": kappa,
//
//       "repeatability":
//       statisticalReport["repeatabilityPercent"] ?? 0.0,
//
//       "reproducibility":
//       statisticalReport["reproducibilityPercent"] ?? 0.0,
//
//       "overallAgreement":
//       statisticalReport["effectivenessPercent"] ?? 0.0,
//
//       "repeatabilityStatus":
//       classifyAgreement(
//         statisticalReport["repeatabilityPercent"] ?? 0.0,
//       ),
//
//       "reproducibilityStatus":
//       classifyAgreement(
//         statisticalReport["reproducibilityPercent"] ?? 0.0,
//       ),
//
//       "falseAlertStatus":
//       classifyOverkill(falseAlert),
//
//       "missRateStatus":
//       classifyEscape(missRate),
//     };
//   }
//   static double _calculateRepeatability(
//       List<ArrRecord> records,
//       ) {
//
//     if (records.isEmpty) {
//       return 0;
//     }
//
//     int same = 0;
//
//     int total = 0;
//
//     for (final candidate in records) {
//
//       for (int i = 0;
//       i < candidate.masterAnswers.length;
//       i++) {
//
//         total++;
//
//         final t1 =
//         candidate.trail1Answers[i];
//
//         final t2 =
//         candidate.trail2Answers[i];
//
//         final t3 =
//         candidate.trail3Answers[i];
//
//         if (t1 == t2 &&
//             t2 == t3) {
//
//           same++;
//
//         }
//
//       }
//
//     }
//
//     if (total == 0) {
//       return 0;
//     }
//
//     return (same / total) * 100;
//
//   }
//   static double _calculateReproducibility(
//       List<ArrRecord> records,
//       ) {
//
//     if (records.length < 2) {
//       return 100;
//     }
//
//     final totalParts =
//         records.first.masterAnswers.length;
//
//     int agree = 0;
//
//     for (int part = 0;
//     part < totalParts;
//     part++) {
//
//       bool same = true;
//
//       final firstAnswer =
//       records.first.trail1Answers[part];
//
//       for (final operator in records) {
//
//         if (operator.trail1Answers[part] !=
//             firstAnswer) {
//
//           same = false;
//
//           break;
//
//         }
//
//       }
//
//       if (same) {
//         agree++;
//       }
//
//     }
//
//     return (agree / totalParts) * 100;
//
//   }
//   static double _calculateOverallAgreement(
//       List<ArrRecord> records,
//       ) {
//
//     if (records.isEmpty) {
//       return 0;
//     }
//
//     double sum = 0;
//
//     for (final candidate in records) {
//
//       sum +=
//           _calculateAgreement(candidate);
//
//     }
//
//     return sum / records.length;
//
//   }
// }



//Given Below code By Claude
import '../models/arr_record.dart';
import '../models/cross_tab_result.dart';
import '../utils/beta_stats.dart';

class CrossTabService {
  CrossTabService._();

  static CrossTabResult generate(
      List<ArrRecord> records,
      ) {
    if (records.length < 2) {
      throw Exception(
        "Minimum two candidates required.",
      );
    }

    final batchId = records.first.batchId;

    if (!records.every((e) => e.batchId == batchId)) {
      throw Exception(
        "Selected candidates belong to different batches.",
      );
    }

    final dataEntry = _buildDataEntry(records);

    final calculations =
    _buildCalculationMatrix(dataEntry);

    final calculationTotals =
    _buildCalculationTotals(calculations);

    final statisticalReport =
    _buildStatisticalReport(
      calculations,
      calculationTotals,
    );

    final statistics =
    _buildStatistics(records);

    final crossTab =
    _buildCrossTab(
      calculations,
      calculationTotals,
    );

    final summary =
    _buildSummary(
      records,
      statisticalReport,
      crossTab,
    );

    return CrossTabResult(
      candidates: records,
      dataEntry: dataEntry,
      calculations: calculations,
      statisticalReport: statisticalReport,
      crossTab: crossTab,
      arrSummary: summary,
    );
  }

  static List<DataEntryRow> _buildDataEntry(
      List<ArrRecord> records,
      ) {

    final List<DataEntryRow> rows = [];

    if (records.isEmpty) {
      return rows;
    }

    final first = records.first;

    final totalParts = first.partNumbers.length;

    for (int part = 0; part < totalParts; part++) {

      final List<OperatorTrials> operators = [];

      for (final candidate in records) {

        operators.add(

          OperatorTrials(

            employeeCode: candidate.employeeCode,

            candidateName: candidate.appraisee,

            trial1: candidate.trail1Answers[part],

            trial2: candidate.trail2Answers[part],

            trial3: candidate.trail3Answers[part],

          ),

        );

      }

      rows.add(

        DataEntryRow(

          partNumber: first.partNumbers[part],

          expert: first.masterAnswers[part],

          operatorTrials: operators,

        ),

      );

    }

    return rows;

  }
  static List<CalculationRow> _buildCalculationMatrix(
      List<DataEntryRow> dataEntry,
      ) {
    final List<CalculationRow> rows = [];

    int sampleNo = 1;

    for (final row in dataEntry) {
      final expert = row.expert.toString();

      final List<OperatorCalculation> operators = [];

      for (final operator in row.operatorTrials) {
        final t1 = operator.trial1.toString();
        final t2 = operator.trial2.toString();
        final t3 = operator.trial3.toString();
        operators.add(
          OperatorCalculation(
            employeeCode: operator.employeeCode,
            candidateName: operator.candidateName,

            trial1: t1,
            trial2: t2,
            trial3: t3,

            same: _excelSame(t1, t2, t3),
            correct: _excelCorrect(expert, t1, t2, t3),
            overkill: _excelOverkill(expert, t1, t2, t3),
            escape: _excelEscape(expert, t1, t2, t3),
          ),
        );
      }

      int repeatability = 0;
      int reproducibility = 0;

      if (operators.isNotEmpty) {
        // Excel: Calculations!Y4
        //   =IF(SUM(G4,N4,U4)>0, IF(G4=N4,IF(N4=U4,IF(U4=G4,1,0),0),0), 0)
        // Because G/N/U are each 0 or 1, "SUM>0 AND all mutually equal"
        // reduces to "all three equal 1" — so we test that directly.
        repeatability = operators.every((e) => e.same == 1) ? 1 : 0;

        // Excel: Calculations!Z4 (same shape, using H/O/V "correct")
        reproducibility = operators.every((e) => e.correct == 1) ? 1 : 0;
      }

      rows.add(
        CalculationRow(
          partNumber: row.partNumber,
          sampleNo: sampleNo,
          expert: expert,
          operators: operators,
          overallRepeatability: repeatability,
          overallReproducibility: reproducibility,
        ),
      );

      sampleNo++;
    }

    return rows;
  }
  static Map<String, dynamic> _buildCalculationTotals(
      List<CalculationRow> calculations,
      ) {
    if (calculations.isEmpty) {
      return {};
    }

    final operatorCount = calculations.first.operators.length;

    final List<Map<String, dynamic>> operators = [];

    int totalOverkill = 0;
    int totalEscape = 0;

    for (int i = 0; i < operatorCount; i++) {

      int sameCount = 0;
      int correctCount = 0;
      int overkill = 0;
      int escape = 0;

      int sameTotal = 0;
      int correctTotal = 0;

      for (final row in calculations) {

        final op = row.operators[i];

        if (op.same == 0 || op.same == 1) {
          sameTotal++;
          sameCount += op.same;
        }

        if (op.correct == 0 || op.correct == 1) {
          correctTotal++;
          correctCount += op.correct;
        }

        overkill += op.overkill;
        escape += op.escape;
      }

      totalOverkill += overkill;
      totalEscape += escape;

      operators.add({
        "appraiserScore":
        sameTotal == 0 ? 0.0 : sameCount / sameTotal,

        "attributeScore":
        correctTotal == 0 ? 0.0 : correctCount / correctTotal,

        "sameCount": sameCount,
        "sameTotal": sameTotal,

        "correctCount": correctCount,
        "correctTotal": correctTotal,

        "overkill": overkill,
        "escape": escape,
      });
    }

    // Excel: Calculations!C106 = 'Data Entry'!F9*'Data Entry'!F10
    // i.e. operator count * trial count (a per-study constant — NOT
    // sample count * 3, which is what this used to compute).
    const int trialsPerSample = 3;
    final int opsTries = operatorCount * trialsPerSample;

    // Excel: Calculations!C107 = SUM(I108:X108), i.e. total overkill
    // trials PLUS total escape trials (this used to only count overkill).
    final int defects = totalOverkill + totalEscape;

    // Excel: Statistical Report!C29 = Calculations!C105*Calculations!C106
    final int totalOpportunities = calculations.length * opsTries;

    // Excel: Statistical Report!C30 = C29 - Calculations!C107
    final int accurateCount = totalOpportunities - defects;

    return {
      "operators": operators,

      "sampleCount": calculations.length,

      "opsTries": opsTries,

      "defects": defects,

      "totalOpportunities": totalOpportunities,

      "accurateCount": accurateCount,

      "OVERKILL": totalOverkill,

      "ESCAPE": totalEscape,
    };
  }
  static Map<String, dynamic> _buildStatisticalReport(
      List<CalculationRow> calculations,
      Map<String, dynamic> calculationTotals,
      ) {
    if (calculations.isEmpty) {
      return {};
    }

    final operators =
    calculationTotals["operators"] as List<Map<String, dynamic>>;

    final totalOperators = operators.length;

    int same = 0;
    int sameTotal = 0;

    int correct = 0;
    int correctTotal = 0;

    int overkill = 0;
    int escape = 0;

    for (final op in operators) {

      same += op["sameCount"] as int;
      sameTotal += op["sameTotal"] as int;

      correct += op["correctCount"] as int;
      correctTotal += op["correctTotal"] as int;

      overkill += op["overkill"] as int;
      escape += op["escape"] as int;
    }

    // Excel: Statistical Report!C22/C23 and !F22/F23 count SAMPLES (not
    // operator-trials) via Data Entry!O and !P, which read
    // Calculations!Y and !Z — "did every operator agree with themselves
    // AND with each other on this sample". This is a per-sample count,
    // distinct from same/sameTotal and correct/correctTotal above (which
    // are summed per-operator trial counts).
    final int sampleCount = calculations.length;

    final int agreementSamples =
        calculations.where((row) => row.overallRepeatability == 1).length;

    final int effectiveSamples =
        calculations.where((row) => row.overallReproducibility == 1).length;

    final repeatability =
    sameTotal == 0 ? 0.0 : same / sameTotal;

    final reproducibility =
    correctTotal == 0 ? 0.0 : correct / correctTotal;

    final falseAlert =
    correctTotal == 0 ? 0.0 : overkill / correctTotal;

    final missRate =
    correctTotal == 0 ? 0.0 : escape / correctTotal;

    final effectiveness =
        1 - falseAlert - missRate;
    final operatorStatistics = operators.map((op) {

      final inspected =
      op["sameTotal"] as int;

      final matched =
      op["sameCount"] as int;

      final attributeInspected =
      op["correctTotal"] as int;

      final attributeMatched =
      op["correctCount"] as int;

      return {

        // Excel row 10
        "totalInspected": inspected,

        // Excel row 11
        "matched": matched,

        // Excel row 14
        "calculatedScore":
        inspected == 0
            ? 0.0
            : matched / inspected,

        // Score vs Attribute
        "attributeTotal":
        attributeInspected,

        "attributeMatched":
        attributeMatched,

        "attributeScore":
        attributeInspected == 0
            ? 0.0
            : attributeMatched / attributeInspected,

        // Excel rows 16 & 17
        "escape": op["escape"],

        "overkill": op["overkill"],

      };

    }).toList();

    return {

      "sampleCount":
      calculationTotals["sampleCount"],

      "opsTries":
      calculationTotals["opsTries"],

      "defects":
      calculationTotals["defects"],

      "operatorCount":
      totalOperators,

      "operators": List.generate(
        operatorStatistics.length,
            (index) {
          final op = operatorStatistics[index];

          return {
            "operatorNo": index + 1,

            // ==========================
            // Excel Rows 10-17
            // ==========================

            "totalInspected": op["totalInspected"],
            "matched": op["matched"],
            "calculatedScore": op["calculatedScore"],

            "escape": op["escape"],
            "overkill": op["overkill"],

            // Confidence limits
            // Excel: Statistical Report!B13:D13 (95% UCL) and
            // Statistical Report!B15:D15 (95% LCL) — "% Appraiser"
            // section, built from matched/totalInspected (same-based).
            "lcl95": BetaStat.lcl95(
              op["matched"] as int,
              op["totalInspected"] as int,
            ),
            "ucl95": BetaStat.ucl95(
              op["matched"] as int,
              op["totalInspected"] as int,
            ),

            // Excel: Statistical Report!E9:G9's row 10/11 (attribute
            // totals) feeding E13:G13 (95% UCL) and E15:G15 (95% LCL) —
            // "% Score vs Attribute" section, built from
            // attributeMatched/attributeTotal (correct-based), which is
            // a DIFFERENT pair of counts than the appraiser section
            // above and needs its own confidence limits.
            "attributeTotal": op["attributeTotal"],
            "attributeMatched": op["attributeMatched"],
            "attributeScore": op["attributeScore"],
            "attributeLcl95": BetaStat.lcl95(
              op["attributeMatched"] as int,
              op["attributeTotal"] as int,
            ),
            "attributeUcl95": BetaStat.ucl95(
              op["attributeMatched"] as int,
              op["attributeTotal"] as int,
            ),
          };
        },
      ),

      "appraiserScores": operatorStatistics
          .map(
            (e) => (e["calculatedScore"] as double) * 100,
      )
          .toList(),

      "attributeScores": operatorStatistics
          .map(
            (e) => (e["attributeScore"] as double) * 100,
      )
          .toList(),
      "repeatability": repeatability,
      "repeatabilityPercent": repeatability * 100,

      "reproducibility": reproducibility,
      "reproducibilityPercent": reproducibility * 100,

      "overkill": {
        "count": overkill,
        "percent": falseAlert * 100,
      },

      "escape": {
        "count": escape,
        "percent": missRate * 100,
      },

      "effectiveness": effectiveness,
      "effectivenessPercent": effectiveness * 100,

      // ===== DATA ENTRY FOOTER =====

      // Excel -> Calculations!U104
      "appraiserScore": repeatability * 100,

      // Excel -> Calculations!V104
      "attributeScore": reproducibility * 100,

      // ===========================================================
      // EFFECTIVE SCORE (Excel Rows 22-26)
      // Excel: Statistical Report!C22 (total samples), !C23 (# in
      // agreement, from Data Entry!O -> Calculations!Y)
      // ===========================================================

      "effectiveScore": {
        "totalInspected": sampleCount,
        "yesCount": agreementSamples,
        "score":
        sampleCount == 0
            ? 0.0
            : agreementSamples / sampleCount,

        // Excel: Statistical Report!C24 (95% UCL) and !C26 (95% LCL)
        "lcl95": BetaStat.lcl95(agreementSamples, sampleCount),
        "ucl95": BetaStat.ucl95(agreementSamples, sampleCount),
      },

      // ===========================================================
      // EFFECTIVE SCORE VS ATTRIBUTE
      // Excel: Statistical Report!F22 (total samples), !F23 (# in
      // agreement, from Data Entry!P -> Calculations!Z)
      // ===========================================================

      "effectiveScoreVsAttribute": {
        "totalInspected": sampleCount,
        "yesCount": effectiveSamples,
        "score":
        sampleCount == 0
            ? 0.0
            : (effectiveSamples / sampleCount) * 100,

        // Excel: Statistical Report!F24 (95% UCL) and !F26 (95% LCL)
        "lcl95": BetaStat.lcl95(effectiveSamples, sampleCount),
        "ucl95": BetaStat.ucl95(effectiveSamples, sampleCount),
      },

      // ===========================================================
      // ATTRIBUTE INSPECTION ACCURACY
      // Excel:
      // C29 = Total
      // C30 = Correct
      // C32 = Correct / Total
      // ===========================================================

      "attributeInspectionAccuracy": {
        // Excel: Statistical Report!C29
        "total": calculationTotals["totalOpportunities"],
        // Excel: Statistical Report!C30
        "correct": calculationTotals["accurateCount"],
        // Excel: Statistical Report!C32
        "score":
        (calculationTotals["totalOpportunities"] as int) == 0
            ? 0.0
            : (calculationTotals["accurateCount"] as int) /
            (calculationTotals["totalOpportunities"] as int),

        // Excel: Statistical Report!C31 (95% UCL) / !C33 (95% LCL)
        "lcl95": BetaStat.lcl95(
          calculationTotals["accurateCount"] as int,
          calculationTotals["totalOpportunities"] as int,
        ),
        "ucl95": BetaStat.ucl95(
          calculationTotals["accurateCount"] as int,
          calculationTotals["totalOpportunities"] as int,
        ),
      },
    };
  }
  static List<OperatorStatistics> _buildStatistics(
      List<ArrRecord> records,
      ) {

    final List<OperatorStatistics> statistics = [];

    for (final candidate in records) {

      final agreement = _calculateAgreement(candidate);

      final falseAlert = _calculateFalseAlert(candidate);

      final missRate = _calculateMissRate(candidate);

      final effectiveness = _calculateEffectiveness(candidate);

      final kappa = _calculateKappa(candidate);

      statistics.add(

        OperatorStatistics(

          employeeCode: candidate.employeeCode,

          candidate: candidate.appraisee,

          agreement: agreement,

          falseAlert: falseAlert,

          missRate: missRate,

          effectiveness: effectiveness,

          kappa: kappa,

        ),

      );

    }

    return statistics;

  }
  static double _calculateAgreement(
      ArrRecord record,
      ) {

    int correct = 0;

    int total = record.masterAnswers.length * 3;

    for (int i = 0; i < record.masterAnswers.length; i++) {

      if (record.trail1Answers[i] == record.masterAnswers[i]) {
        correct++;
      }

      if (record.trail2Answers[i] == record.masterAnswers[i]) {
        correct++;
      }

      if (record.trail3Answers[i] == record.masterAnswers[i]) {
        correct++;
      }

    }

    if (total == 0) {
      return 0;
    }

    return (correct / total) * 100;

  }
  static double _calculateFalseAlert(
      ArrRecord record,
      ) {

    int falseAlert = 0;

    int okParts = 0;

    for (int i = 0; i < record.masterAnswers.length; i++) {

      if (record.masterAnswers[i] != 1) {
        continue;
      }

      okParts++;

      if (record.trail1Answers[i] == 0) {
        falseAlert++;
      }

      if (record.trail2Answers[i] == 0) {
        falseAlert++;
      }

      if (record.trail3Answers[i] == 0) {
        falseAlert++;
      }

    }

    if (okParts == 0) {
      return 0;
    }

    return (falseAlert / (okParts * 3)) * 100;

  }
  static double _calculateMissRate(
      ArrRecord record,
      ) {

    int miss = 0;

    int ngParts = 0;

    for (int i = 0; i < record.masterAnswers.length; i++) {

      if (record.masterAnswers[i] != 0) {
        continue;
      }

      ngParts++;

      if (record.trail1Answers[i] == 1) {
        miss++;
      }

      if (record.trail2Answers[i] == 1) {
        miss++;
      }

      if (record.trail3Answers[i] == 1) {
        miss++;
      }

    }

    if (ngParts == 0) {
      return 0;
    }

    return (miss / (ngParts * 3)) * 100;

  }
  static double _calculateEffectiveness(
      ArrRecord record,
      ) {

    return _calculateAgreement(record);

  }
  static double _calculateKappa(
      ArrRecord record,
      ) {

    final agreement =
        _calculateAgreement(record) / 100;

    final okCount =
        record.masterAnswers.where((e) => e == 1).length;

    final ngCount =
        record.masterAnswers.where((e) => e == 0).length;

    final observedOk =

        record.trail1Answers.where((e) => e == 1).length +

            record.trail2Answers.where((e) => e == 1).length +

            record.trail3Answers.where((e) => e == 1).length;

    final observedNg =

        record.trail1Answers.where((e) => e == 0).length +

            record.trail2Answers.where((e) => e == 0).length +

            record.trail3Answers.where((e) => e == 0).length;

    final total = record.masterAnswers.length * 3;

    if (total == 0) {
      return 0;
    }

    final p1 =
        (okCount / record.masterAnswers.length) *
            (observedOk / total);

    final p0 =
        (ngCount / record.masterAnswers.length) *
            (observedNg / total);

    final chance = p1 + p0;

    if ((1 - chance) == 0) {

      return agreement == 1
          ? 100
          : 0;

    }

    return ((agreement - chance) /
        (1 - chance)) *
        100;

  }
  static int _excelSame(
      String trial1,
      String trial2,
      String trial3,
      ) {
    // Excel:
    // =IF(F4="",IF(AND(D4="",E4=""),"",IF(E4="","N/A",IF(D4=E4,1,0))),IF(AND(D4=E4,E4=F4),1,0))

    if (trial3.isEmpty) {
      if (trial1.isEmpty && trial2.isEmpty) {
        return 0;
      }

      if (trial2.isEmpty) {
        return 0;
      }

      return trial1 == trial2 ? 1 : 0;
    }

    return (trial1 == trial2 && trial2 == trial3) ? 1 : 0;
  }

  static int _excelCorrect(
      String expert,
      String trial1,
      String trial2,
      String trial3,
      ) {
    // Excel:
    // =IF($C4="","",IF(AND(F4="",E4=""),IF($C4=D4,1,0),IF(F4="",IF(AND($C4=E4,$C4=D4),1,0),IF(AND($C4=F4,$C4=E4,$C4=D4),1,0))))

    if (expert.isEmpty) {
      return 0;
    }

    if (trial3.isEmpty && trial2.isEmpty) {
      return expert == trial1 ? 1 : 0;
    }

    if (trial3.isEmpty) {
      return (expert == trial1 && expert == trial2)
          ? 1
          : 0;
    }

    return (expert == trial1 &&
        expert == trial2 &&
        expert == trial3)
        ? 1
        : 0;
  }

  static int _excelOverkill(
      String expert,
      String trial1,
      String trial2,
      String trial3,
      ) {
    // Excel:
    // =IF($C4="fail",0,COUNTIF(D4:F4,"fail"))

    if (expert == "0") {
      return 0;
    }

    int count = 0;

    if (trial1 == "0") count++;
    if (trial2 == "0") count++;
    if (trial3 == "0") count++;

    return count;
  }

  static int _excelEscape(
      String expert,
      String trial1,
      String trial2,
      String trial3,
      ) {
    // Excel:
    // =IF($C4="pass",0,COUNTIF(D4:F4,"pass"))

    if (expert == "1") {
      return 0;
    }

    int count = 0;

    if (trial1 == "1") count++;
    if (trial2 == "1") count++;
    if (trial3 == "1") count++;

    return count;
  }

  // static Map<String, dynamic> _buildCrossTab(
  //     List<CalculationRow> calculations,
  //     Map<String, dynamic> totals,
  //     ) {
  //   int passPass = 0;
  //   int passFail = 0;
  //   int failPass = 0;
  //   int failFail = 0;
  //
  //   void process(String expert, String trial) {
  //     if (expert == "1") {
  //       if (trial == "1") {
  //         passPass++;
  //       } else {
  //         passFail++;
  //       }
  //     } else {
  //       if (trial == "1") {
  //         failPass++;
  //       } else {
  //         failFail++;
  //       }
  //     }
  //   }
  //
  //   for (final row in calculations) {
  //     for (final op in row.operators) {
  //       process(row.expert, op.trial1);
  //       process(row.expert, op.trial2);
  //       process(row.expert, op.trial3);
  //     }
  //   }
  //
  //   final total =
  //       passPass +
  //           passFail +
  //           failPass +
  //           failFail;
  //
  //   if (total == 0) {
  //     return {
  //       "matrix": {
  //         "PP": 0,
  //         "PF": 0,
  //         "FP": 0,
  //         "FF": 0,
  //       },
  //       "total": 0,
  //       "observedAgreement": 0.0,
  //       "chanceAgreement": 0.0,
  //       "kappa": 0.0,
  //       "kappaPercent": 0.0,
  //     };
  //   }
  //
  //   final observed =
  //       (passPass + failFail) / total;
  //
  //   final rowPass =
  //       (passPass + passFail) / total;
  //
  //   final rowFail =
  //       (failPass + failFail) / total;
  //
  //   final columnPass =
  //       (passPass + failPass) / total;
  //
  //   final columnFail =
  //       (passFail + failFail) / total;
  //
  //   final chance =
  //       (rowPass * columnPass) +
  //           (rowFail * columnFail);
  //
  //   final kappa =
  //   (1 - chance) == 0
  //       ? 0.0
  //       : (observed - chance) /
  //       (1 - chance);
  //
  //   return {
  //     "matrix": {
  //       "PP": passPass,
  //       "PF": passFail,
  //       "FP": failPass,
  //       "FF": failFail,
  //     },
  //     "total": total,
  //     "observedAgreement": observed,
  //     "chanceAgreement": chance,
  //     "kappa": kappa,
  //     "kappaPercent": kappa * 100,
  //     "totals": totals,
  //   };
  // }

  static Map<String, dynamic> _buildCrossTab(
      List<CalculationRow> calculations,
      Map<String, dynamic> totals,
      ) {
    if (calculations.isEmpty) {
      return {};
    }

    final operatorCount = calculations.first.operators.length;

    final List<Map<String, dynamic>> operators = [];

    for (int index = 0; index < operatorCount; index++) {
      int passPass = 0;
      int passFail = 0;
      int failPass = 0;
      int failFail = 0;

      for (final row in calculations) {
        final op = row.operators[index];

        void process(String trial) {
          if (row.expert == "1") {
            if (trial == "1") {
              passPass++;
            } else {
              passFail++;
            }
          } else {
            if (trial == "1") {
              failPass++;
            } else {
              failFail++;
            }
          }
        }

        process(op.trial1);
        process(op.trial2);
        process(op.trial3);
      }

      final total =
          passPass +
              passFail +
              failPass +
              failFail;

      final observed =
      total == 0
          ? 0
          : (passPass + failFail) / total;

      final rowPass =
      total == 0
          ? 0
          : (passPass + passFail) / total;

      final rowFail =
      total == 0
          ? 0
          : (failPass + failFail) / total;

      final columnPass =
      total == 0
          ? 0
          : (passPass + failPass) / total;

      final columnFail =
      total == 0
          ? 0
          : (passFail + failFail) / total;

      final chance =
          rowPass * columnPass +
              rowFail * columnFail;

      final kappa =
      (1 - chance) == 0
          ? 0
          : (observed - chance) /
          (1 - chance);

      // Excel: Statistical Report!E17:G17 = 'Cross Tab'!D12/D14 (this
      // operator's overkill trials over this operator's expert-Pass
      // trials) — NOT a study-wide aggregate.
      final double overkillRate =
      (passPass + passFail) == 0 ? 0 : passFail / (passPass + passFail);

      // Excel: Statistical Report!E16:G16 = 'Cross Tab'!E10/E14 (this
      // operator's escape trials over this operator's expert-Fail
      // trials).
      final double escapeRate =
      (failPass + failFail) == 0 ? 0 : failPass / (failPass + failFail);

      operators.add({
        "PP": passPass,
        "PF": passFail,
        "FP": failPass,
        "FF": failFail,
        "total": total,
        "observedAgreement": observed,
        "chanceAgreement": chance,
        "kappa": kappa,
        "kappaPercent": kappa * 100,
        "overkillRate": overkillRate,
        "overkillRatePercent": overkillRate * 100,
        "escapeRate": escapeRate,
        "escapeRatePercent": escapeRate * 100,
      });
    }

    return {
      "operators": operators,
      "totals": totals,
    };
  }
  static Map<String, dynamic> _buildSummary(
      List<ArrRecord> records,
      Map<String, dynamic> statisticalReport,
      Map<String, dynamic> crossTab,
      ){
    final statOperators =
        (statisticalReport["operators"] as List?)?.cast<Map<String, dynamic>>() ??
            [];

    final crossTabOperators =
        (crossTab["operators"] as List?)?.cast<Map<String, dynamic>>() ?? [];

    // ---------------------------------------------------------------
    // Per-operator triples — these feed ARR-Summmary!J:L on each row,
    // one entry per operator, NOT a single averaged/maxed number.
    // ---------------------------------------------------------------

    // Row 1: ARR-Summmary!J12:L12 = Statistical Report!B14:D14
    final List<double> repeatabilityByOperator = statOperators
        .map((e) => (e["calculatedScore"] as num).toDouble() * 100)
        .toList();

    // Row 2: ARR-Summmary!J13:L13 = Statistical Report!E14:G14
    final List<double> reproducibilityByOperator = statOperators
        .map((e) => (e["attributeScore"] as num).toDouble() * 100)
        .toList();

    // Row 5: ARR-Summmary!J16:L16 = 'Cross Tab'!M11/M24/M36 (raw kappa,
    // NOT a percent — Excel's own I16 test compares it to 0.9/0.75).
    final List<double> kappaByOperator = crossTabOperators
        .map((e) => (e["kappa"] as num).toDouble())
        .toList();

    // Row 6: ARR-Summmary!J17:L17 = Statistical Report!E16:G16
    final List<double> missRateByOperator = crossTabOperators
        .map((e) => (e["escapeRatePercent"] as num).toDouble())
        .toList();

    // Row 7: ARR-Summmary!J18:L18 = Statistical Report!E17:G17
    final List<double> falseAlertByOperator = crossTabOperators
        .map((e) => (e["overkillRatePercent"] as num).toDouble())
        .toList();

    // Row 3: ARR-Summmary!J14 = Statistical Report!C25 (single value —
    // "did every operator agree with each other on this sample").
    final double agreement =
        (((statisticalReport["effectiveScore"]
        as Map<String, dynamic>?)?["score"] as num?) ?? 0.0)
            .toDouble() *
            100;

    // Row 4: ARR-Summmary!J15 = Statistical Report!F25 (single value —
    // same, but also required to match the known standard). This field
    // is already stored as a 0-100 percent, unlike "agreement" above.
    final double effectiveness =
    (((statisticalReport["effectiveScoreVsAttribute"]
    as Map<String, dynamic>?)?["score"] as num?) ?? 0.0)
        .toDouble();

    // MAX across operators — feeds the single combined falseAlert/
    // missRate scalars kept for backward compatibility elsewhere.
    final double missRate = missRateByOperator.isEmpty
        ? 0.0
        : missRateByOperator.reduce((a, b) => a > b ? a : b);

    final double falseAlert = falseAlertByOperator.isEmpty
        ? 0.0
        : falseAlertByOperator.reduce((a, b) => a > b ? a : b);

    // ---------------------------------------------------------------
    // Status classifiers — each ARR-Summary row has its own logic;
    // they are not interchangeable.
    // ---------------------------------------------------------------

    // Excel: ARR-Summmary!I12/I13 — Acceptable only if EVERY operator
    // clears the bar; Unacceptable if ANY operator falls below it.
    String classifyAllPercent(
        List<double> percents, {
          required double acceptable,
          required double unacceptable,
        }) {
      if (percents.isEmpty) return "";
      if (percents.every((v) => v >= acceptable)) return "Acceptable";
      if (percents.any((v) => v < unacceptable)) return "Unacceptable";
      return "Marginally acceptable";
    }

    // Excel: ARR-Summmary!I14/I15 — single value, >=0.9 / <0.8.
    String classifySingle(double percent) {
      final score = percent / 100;
      if (score >= 0.90) return "Acceptable";
      if (score < 0.80) return "Unacceptable";
      return "Marginally acceptable";
    }

    // Excel: ARR-Summmary!I17 (Miss rate) — MAX(J17:L17)<=2%/<=5%.
    // Excel: ARR-Summmary!I18 (False alarm) — MAX(J18:L18)<=5%/<=10%.
    String classifyMaxPercent(
        List<double> percents, {
          required double acceptable,
          required double marginal,
        }) {
      if (percents.isEmpty) return "";
      final maxV = percents.reduce((a, b) => a > b ? a : b);
      if (maxV <= acceptable) return "Acceptable";
      if (maxV <= marginal) return "Marginally acceptable";
      return "Unacceptable";
    }

    final repeatabilityStatus = classifyAllPercent(
      repeatabilityByOperator,
      acceptable: 90,
      unacceptable: 80,
    );

    final reproducibilityStatus = classifyAllPercent(
      reproducibilityByOperator,
      acceptable: 90,
      unacceptable: 80,
    );

    final agreementStatus = classifySingle(agreement);

    final effectivenessStatus = classifySingle(effectiveness);

    // Excel: ARR-Summmary!I16 — kappa is a raw 0-1 fraction, thresholds
    // 0.9/0.75 (NOT 0.9/0.8 like rows 1/2/3/4).
    final kappaStatus = kappaByOperator.isEmpty
        ? ""
        : kappaByOperator.every((v) => v >= 0.9)
        ? "Acceptable"
        : kappaByOperator.any((v) => v < 0.75)
        ? "Unacceptable"
        : "Marginally acceptable";

    final missRateStatus = classifyMaxPercent(
      missRateByOperator,
      acceptable: 2,
      marginal: 5,
    );

    final falseAlertStatus = classifyMaxPercent(
      falseAlertByOperator,
      acceptable: 5,
      marginal: 10,
    );

    final allStatuses = [
      repeatabilityStatus,
      reproducibilityStatus,
      agreementStatus,
      effectivenessStatus,
      kappaStatus,
      missRateStatus,
      falseAlertStatus,
    ];

    // Excel: ARR-Summmary!I20
    //   =IF(OR(I12:I18=""),"",
    //       IF(AND(I12:I18="Acceptable"),"Acceptable",
    //          IF(OR(I12:I18="Unacceptable"),"Unacceptable",
    //             "Marginally acceptable")))
    final String overallStatus = allStatuses.any((s) => s.isEmpty)
        ? ""
        : allStatuses.every((s) => s == "Acceptable")
        ? "Acceptable"
        : allStatuses.any((s) => s == "Unacceptable")
        ? "Unacceptable"
        : "Marginally acceptable";

    return {
      "candidateCount": records.length,
      "partCount":
      records.isEmpty ? 0 : records.first.masterAnswers.length,

      // Per-operator triples for the summary table's 3 result columns.
      "repeatabilityByOperator": repeatabilityByOperator,
      "reproducibilityByOperator": reproducibilityByOperator,
      "kappaByOperator": kappaByOperator,
      "missRateByOperator": missRateByOperator,
      "falseAlertByOperator": falseAlertByOperator,

      // Single combined values (rows 3 & 4).
      "agreement": agreement,
      "effectiveness": effectiveness,

      // Backward-compatible single scalars (MAX across operators).
      "falseAlert": falseAlert,
      "missRate": missRate,

      "repeatabilityStatus": repeatabilityStatus,
      "reproducibilityStatus": reproducibilityStatus,
      "agreementStatus": agreementStatus,
      "effectivenessStatus": effectivenessStatus,
      "kappaStatus": kappaStatus,
      "falseAlertStatus": falseAlertStatus,
      "missRateStatus": missRateStatus,
      "overallStatus": overallStatus,
    };
  }
  static double _calculateRepeatability(
      List<ArrRecord> records,
      ) {

    if (records.isEmpty) {
      return 0;
    }

    int same = 0;

    int total = 0;

    for (final candidate in records) {

      for (int i = 0;
      i < candidate.masterAnswers.length;
      i++) {

        total++;

        final t1 =
        candidate.trail1Answers[i];

        final t2 =
        candidate.trail2Answers[i];

        final t3 =
        candidate.trail3Answers[i];

        if (t1 == t2 &&
            t2 == t3) {

          same++;

        }

      }

    }

    if (total == 0) {
      return 0;
    }

    return (same / total) * 100;

  }
  static double _calculateReproducibility(
      List<ArrRecord> records,
      ) {

    if (records.length < 2) {
      return 100;
    }

    final totalParts =
        records.first.masterAnswers.length;

    int agree = 0;

    for (int part = 0;
    part < totalParts;
    part++) {

      bool same = true;

      final firstAnswer =
      records.first.trail1Answers[part];

      for (final operator in records) {

        if (operator.trail1Answers[part] !=
            firstAnswer) {

          same = false;

          break;

        }

      }

      if (same) {
        agree++;
      }

    }

    return (agree / totalParts) * 100;

  }
  static double _calculateOverallAgreement(
      List<ArrRecord> records,
      ) {

    if (records.isEmpty) {
      return 0;
    }

    double sum = 0;

    for (final candidate in records) {

      sum +=
          _calculateAgreement(candidate);

    }

    return sum / records.length;

  }
}