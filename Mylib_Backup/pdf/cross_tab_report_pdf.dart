  // import 'dart:typed_data';
  //
  // import 'package:pdf/pdf.dart';
  // import 'package:pdf/widgets.dart' as pw;
  //
  // import '../models/cross_tab_result.dart';
  //
  // class CrossTabReportPdf {
  // CrossTabReportPdf._();
  //
  // static Future<Uint8List> generate({
  // required CrossTabResult result,
  // }) async {
  // final pdf = pw.Document();
  //
  // pdf.addPage(
  //   pw.Page(
  //     pageFormat: PdfPageFormat.a3.landscape,
  //     margin: const pw.EdgeInsets.all(18),
  //     build: (_) => pw.Column(
  //       crossAxisAlignment: pw.CrossAxisAlignment.start,
  //       children: [
  //         pw.Container(
  //           padding: const pw.EdgeInsets.all(10),
  //           decoration: pw.BoxDecoration(
  //             color: PdfColors.blue100,
  //             border: pw.Border.all(),
  //           ),
  //           child: _title(),
  //         ),
  //         pw.SizedBox(height: 15),
  //         _dataEntryTable(result),
  //       ],
  //     ),
  //   ),
  // );
  //
  // pdf.addPage(
  //   pw.Page(
  //     pageFormat: PdfPageFormat.a3.landscape,
  //     margin: const pw.EdgeInsets.all(18),
  //     build: (_) => pw.Column(
  //       crossAxisAlignment: pw.CrossAxisAlignment.start,
  //       children: [
  //         _title(),
  //         pw.SizedBox(height: 15),
  //         _calculationTable(result),
  //       ],
  //     ),
  //   ),
  // );
  //
  // pdf.addPage(
  //   pw.Page(
  //     pageFormat: PdfPageFormat.a3.landscape,
  //     margin: const pw.EdgeInsets.all(18),
  //     build: (_) => pw.Column(
  //       crossAxisAlignment: pw.CrossAxisAlignment.start,
  //       children: [
  //         _title(),
  //         pw.SizedBox(height: 15),
  //         _statisticsTable(result),
  //       ],
  //     ),
  //   ),
  // );
  //
  // pdf.addPage(
  //   pw.Page(
  //     pageFormat: PdfPageFormat.a3.landscape,
  //     margin: const pw.EdgeInsets.all(18),
  //     build: (_) => pw.Column(
  //       crossAxisAlignment: pw.CrossAxisAlignment.start,
  //       children: [
  //         _title(),
  //         pw.SizedBox(height: 15),
  //         _crossTabTable(result),
  //       ],
  //     ),
  //   ),
  // );
  //
  // pdf.addPage(
  //   pw.Page(
  //     pageFormat: PdfPageFormat.a3.landscape,
  //     margin: const pw.EdgeInsets.all(18),
  //     build: (_) => pw.Column(
  //       crossAxisAlignment: pw.CrossAxisAlignment.start,
  //       children: [
  //         _title(),
  //         pw.SizedBox(height: 15),
  //         _summaryTable(result),
  //       ],
  //     ),
  //   ),
  // );
  // return pdf.save();
  // }
  //
  // static pw.Widget _title() {
  // return pw.Column(
  // crossAxisAlignment: pw.CrossAxisAlignment.start,
  // children: [
  //
  // pw.Text(
  // "DIGITAL ARR",
  // style: pw.TextStyle(
  // fontSize: 24,
  // fontWeight: pw.FontWeight.bold,
  // ),
  // ),
  //
  // pw.Text(
  // "Cross Tab Report",
  // style: const pw.TextStyle(
  // fontSize: 16,
  // ),
  // ),
  //
  // ],
  // );
  // }
  //
  // static pw.Widget _sectionTitle(String title) {
  // return pw.Container(
  // width: double.infinity,
  // padding: const pw.EdgeInsets.all(6),
  // color: PdfColors.grey300,
  // child: pw.Text(
  // title,
  // style: pw.TextStyle(
  // fontWeight: pw.FontWeight.bold,
  // fontSize: 14,
  // ),
  // ),
  // );
  // }
  //
  // static pw.Widget _cell(
  // String text, {
  // bool header = false,
  // }) {
  // return pw.Container(
  // padding: const pw.EdgeInsets.all(4),
  // alignment: pw.Alignment.center,
  // decoration: pw.BoxDecoration(
  // color: header
  // ? PdfColors.grey300
  // : PdfColors.white,
  // border: pw.Border.all(),
  // ),
  // child: pw.Text(
  // text,
  // textAlign: pw.TextAlign.center,
  // style: pw.TextStyle(
  // fontSize: 8,
  // fontWeight:
  // header
  // ? pw.FontWeight.bold
  // : pw.FontWeight.normal,
  // ),
  // ),
  // );
  // }
  // static pw.Widget _dataEntryTable(
  // CrossTabResult result,
  // ) {
  //
  // if (result.dataEntry.isEmpty) {
  // return pw.Container();
  // }
  //
  // final headers = <String>[
  // "Part",
  // "Master",
  // ];
  //
  // for (final op in result.dataEntry.first.operatorTrials) {
  // headers.add("${op.employeeCode}\nT1");
  // headers.add("${op.employeeCode}\nT2");
  // headers.add("${op.employeeCode}\nT3");
  // }
  //
  // final data = <List<String>>[];
  //
  // data.add(headers);
  //
  // for (final row in result.dataEntry) {
  //
  // final r = <String>[
  // row.partNumber,
  // row.expert.toString(),
  // ];
  //
  // for (final op in row.operatorTrials) {
  // r.add(op.trial1.toString());
  // r.add(op.trial2.toString());
  // r.add(op.trial3.toString());
  // }
  //
  // data.add(r);
  // }
  //
  // return pw.Column(
  // crossAxisAlignment: pw.CrossAxisAlignment.start,
  // children: [
  //
  // _sectionTitle("DATA ENTRY"),
  //   pw.Center(
  //   child: pw.TableHelper.fromTextArray(
  // border: pw.TableBorder.all(),
  //   headerStyle: pw.TextStyle(
  //     fontWeight: pw.FontWeight.bold,
  //     fontSize: 9,
  //     color: PdfColors.black,
  //   ),
  //   headerDecoration: const pw.BoxDecoration(
  //     color: PdfColors.blue100,
  //   ),
  // cellStyle: const pw.TextStyle(
  // fontSize: 8,
  // ),
  // headers: data.first,
  // data: data.skip(1).toList(),
  // ),
  //   ),
  // ],
  //
  // );
  // }
  // static pw.Widget _calculationTable(
  // CrossTabResult result,
  // ) {
  //
  // if (result.calculations.isEmpty) {
  // return pw.Container();
  // }
  //
  // final headers = <String>[
  // "Sample",
  // "Expert",
  // ];
  //
  // for (final op in result.calculations.first.operators) {
  //
  // headers.add("${op.employeeCode} T1");
  // headers.add("${op.employeeCode} T2");
  // headers.add("${op.employeeCode} T3");
  // headers.add("${op.employeeCode} Same");
  // headers.add("${op.employeeCode} Correct");
  // headers.add("${op.employeeCode} Over");
  // headers.add("${op.employeeCode} Escape");
  //
  // }
  //
  // headers.add("Repeat");
  // headers.add("Reprod");
  //
  // final rows = <List<String>>[];
  //
  // for (final row in result.calculations) {
  //
  // final r = <String>[
  // row.sampleNo.toString(),
  // row.expert,
  // ];
  //
  // for (final op in row.operators) {
  //
  // r.add(op.trial1);
  // r.add(op.trial2);
  // r.add(op.trial3);
  // r.add(op.same.toString());
  // r.add(op.correct.toString());
  // r.add(op.overkill.toString());
  // r.add(op.escape.toString());
  //
  // }
  //
  // r.add(row.overallRepeatability.toString());
  // r.add(row.overallReproducibility.toString());
  //
  // rows.add(r);
  //
  // }
  //
  // return pw.Column(
  // crossAxisAlignment: pw.CrossAxisAlignment.start,
  // children: [
  //
  // _sectionTitle("CALCULATIONS"),
  //
  //   pw.Center(
  //   child: pw.TableHelper.fromTextArray(border: pw.TableBorder.all(),
  // headers: headers,
  // data: rows,
  // headerStyle: pw.TextStyle(
  // fontWeight: pw.FontWeight.bold,
  // fontSize: 7,
  // ),
  //   headerDecoration: const pw.BoxDecoration(
  //     color: PdfColors.blue100,
  //   ),
  // cellStyle: const pw.TextStyle(
  // fontSize: 7,
  // ),
  // ),
  //   ),
  // ],
  // );
  // }
  // static pw.Widget _statisticsTable(
  // CrossTabResult result,
  // ) {
  // if (result.statisticalReport.isEmpty) {
  // return pw.Container();
  // }
  //
  // final rows = <List<String>>[];
  //
  // final operators =
  // (result.statisticalReport["operators"] as List)
  //     .cast<Map<String, dynamic>>();
  //
  // rows.add([
  //   "Operator",
  //   "Inspected",
  //   "Matched",
  //   "Score",
  //   "Overkill",
  //   "Escape",
  // ]);
  //
  // for (int i = 0; i < operators.length; i++) {
  //
  //   final op = operators[i];
  //
  //   rows.add([
  //
  //     "Operator ${i + 1}",
  //
  //     "${op["totalInspected"]}",
  //
  //     "${op["matched"]}",
  //
  //     "${((op["calculatedScore"] as num) * 100).toStringAsFixed(2)}%",
  //
  //     "${op["overkill"]}",
  //
  //     "${op["escape"]}",
  //
  //   ]);
  //
  // }
  // return pw.Column(
  // crossAxisAlignment: pw.CrossAxisAlignment.start,
  // children: [
  //
  // _sectionTitle("STATISTICAL REPORT"),
  //
  //   pw.Center(
  //   child: pw.TableHelper.fromTextArray(
  //   border: pw.TableBorder.all(),
  //
  //   headerDecoration:
  //   const pw.BoxDecoration(
  //   color: PdfColors.blue100,
  //   ),
  //
  //   headerStyle: pw.TextStyle(
  //   fontWeight: pw.FontWeight.bold,
  //   fontSize: 9,
  //   ),
  //
  //   cellStyle:
  //   const pw.TextStyle(
  //   fontSize: 8,
  //   ),
  //
  //   headers: rows.first,
  //
  //   data: rows.skip(1).toList(),
  //
  //   )
  // // headerStyle: pw.TextStyle(
  // // fontWeight: pw.FontWeight.bold,
  // // ),
  // // ),
  //   ),
  // ],
  // );
  // }
  // static pw.Widget _crossTabTable(
  //     CrossTabResult result,
  //     ) {
  //
  //   if (result.crossTab.isEmpty) {
  //     return pw.Container();
  //   }
  //
  //   final operators =
  //   (result.crossTab["operators"] as List)
  //       .cast<Map<String, dynamic>>();
  //
  //   return pw.Column(
  //
  //     crossAxisAlignment: pw.CrossAxisAlignment.start,
  //
  //     children: [
  //
  //       _sectionTitle("CROSS TAB"),
  //
  //       ...List.generate(
  //         operators.length,
  //             (index) {
  //
  //           final op = operators[index];
  //
  //           return pw.Column(
  //
  //             crossAxisAlignment:
  //             pw.CrossAxisAlignment.start,
  //
  //             children: [
  //
  //               pw.SizedBox(height: 12),
  //
  //               pw.Text(
  //                 "Operator ${index + 1}",
  //                 style: pw.TextStyle(
  //                   fontWeight:
  //                   pw.FontWeight.bold,
  //                   fontSize: 11,
  //                 ),
  //               ),
  //
  //               pw.SizedBox(height: 6),
  //
  //               pw.TableHelper.fromTextArray(
  //
  //                 border: pw.TableBorder.all(),
  //
  //                 headers: const [
  //
  //                   "",
  //
  //                   "Observed PASS",
  //
  //                   "Observed FAIL",
  //
  //                 ],
  //
  //                 data: [
  //
  //                   [
  //
  //                     "Expert PASS",
  //
  //                     "${op["PP"]}",
  //
  //                     "${op["PF"]}",
  //
  //                   ],
  //
  //                   [
  //
  //                     "Expert FAIL",
  //
  //                     "${op["FP"]}",
  //
  //                     "${op["FF"]}",
  //
  //                   ],
  //
  //                 ],
  //
  //               ),
  //
  //               pw.SizedBox(height: 8),
  //
  //               pw.TableHelper.fromTextArray(
  //
  //                 border: pw.TableBorder.all(),
  //
  //                 headers: const [
  //
  //                   "Metric",
  //
  //                   "Value",
  //
  //                 ],
  //
  //                 data: [
  //
  //                   [
  //
  //                     "Observed Agreement",
  //
  //                     "${((op["observedAgreement"] as num) * 100).toStringAsFixed(2)}%",
  //
  //                   ],
  //
  //                   [
  //
  //                     "Chance Agreement",
  //
  //                     "${((op["chanceAgreement"] as num) * 100).toStringAsFixed(2)}%",
  //
  //                   ],
  //
  //                   [
  //
  //                     "Kappa",
  //
  //                     "${(op["kappaPercent"] as num).toStringAsFixed(2)}%",
  //
  //                   ],
  //
  //                 ],
  //
  //               ),
  //
  //             ],
  //
  //           );
  //
  //         },
  //
  //       ),
  //
  //     ],
  //
  //   );
  //
  // }
  // static pw.Widget _summaryTable(
  //     CrossTabResult result,
  //     ) {
  //   if (result.arrSummary.isEmpty) {
  //     return pw.Container();
  //   }
  //
  //   final summary = result.arrSummary;
  //
  //   double value(dynamic v) {
  //     if (v == null) return 0.0;
  //     if (v is num) return v.toDouble();
  //     return double.tryParse(v.toString()) ?? 0.0;
  //   }
  //
  //   String text(dynamic v) => v?.toString() ?? "";
  //
  //   final data = <List<String>>[
  //     [
  //       "Repeatability",
  //       "${value(summary["repeatability"]).toStringAsFixed(2)}%",
  //       text(summary["repeatabilityStatus"]),
  //     ],
  //     [
  //       "Reproducibility",
  //       "${value(summary["reproducibility"]).toStringAsFixed(2)}%",
  //       text(summary["reproducibilityStatus"]),
  //     ],
  //     [
  //       "False Alarm",
  //       "${value(summary["falseAlert"]).toStringAsFixed(2)}%",
  //       text(summary["falseAlertStatus"]),
  //     ],
  //     [
  //       "Miss Rate",
  //       "${value(summary["missRate"]).toStringAsFixed(2)}%",
  //       text(summary["missRateStatus"]),
  //     ],
  //     [
  //       "Overall Agreement",
  //       "${value(summary["overallAgreement"]).toStringAsFixed(2)}%",
  //       "",
  //     ],
  //     [
  //       "Kappa",
  //       "${value(summary["kappa"]).toStringAsFixed(2)}%",
  //       "",
  //     ],
  //   ];
  //
  //   return pw.Column(
  //     crossAxisAlignment: pw.CrossAxisAlignment.start,
  //     children: [
  //       _sectionTitle("ARR SUMMARY"),
  //
  //       pw.TableHelper.fromTextArray(
  //         border: pw.TableBorder.all(),
  //
  //         headers: const [
  //           "Parameter",
  //           "Value",
  //           "Status",
  //         ],
  //
  //         data: data,
  //
  //         headerDecoration: const pw.BoxDecoration(
  //           color: PdfColors.blue100,
  //         ),
  //
  //         headerStyle: pw.TextStyle(
  //           fontWeight: pw.FontWeight.bold,
  //           fontSize: 9,
  //         ),
  //
  //         cellStyle: const pw.TextStyle(
  //           fontSize: 8,
  //         ),
  //       ),
  //     ],
  //   );
  // }
  // }
  
  //Below is V2 of claude(not working)
  // import 'dart:typed_data';
  //
  // import 'package:pdf/pdf.dart';
  // import 'package:pdf/widgets.dart' as pw;
  //
  // import '../models/cross_tab_result.dart';
  //
  // class CrossTabReportPdf {
  //   CrossTabReportPdf._();
  //
  //   static Future<Uint8List> generate({
  //     required CrossTabResult result,
  //   }) async {
  //     final pdf = pw.Document();
  //
  //     pdf.addPage(
  //       pw.Page(
  //         pageFormat: PdfPageFormat.a3.landscape,
  //         margin: const pw.EdgeInsets.all(18),
  //         build: (_) => pw.Column(
  //           crossAxisAlignment: pw.CrossAxisAlignment.start,
  //           children: [
  //             pw.Container(
  //               padding: const pw.EdgeInsets.all(10),
  //               decoration: pw.BoxDecoration(
  //                 color: PdfColors.blue100,
  //                 border: pw.Border.all(),
  //               ),
  //               child: _title(),
  //             ),
  //             pw.SizedBox(height: 15),
  //             _dataEntryTable(result),
  //           ],
  //         ),
  //       ),
  //     );
  //
  //     pdf.addPage(
  //       pw.Page(
  //         pageFormat: PdfPageFormat.a3.landscape,
  //         margin: const pw.EdgeInsets.all(18),
  //         build: (_) => pw.Column(
  //           crossAxisAlignment: pw.CrossAxisAlignment.start,
  //           children: [
  //             _title(),
  //             pw.SizedBox(height: 15),
  //             _calculationTable(result),
  //           ],
  //         ),
  //       ),
  //     );
  //
  //     pdf.addPage(
  //       pw.Page(
  //         pageFormat: PdfPageFormat.a3.landscape,
  //         margin: const pw.EdgeInsets.all(18),
  //         build: (_) => pw.Column(
  //           crossAxisAlignment: pw.CrossAxisAlignment.start,
  //           children: [
  //             _title(),
  //             pw.SizedBox(height: 15),
  //             _statisticsTable(result),
  //           ],
  //         ),
  //       ),
  //     );
  //
  //     pdf.addPage(
  //       pw.Page(
  //         pageFormat: PdfPageFormat.a3.landscape,
  //         margin: const pw.EdgeInsets.all(18),
  //         build: (_) => pw.Column(
  //           crossAxisAlignment: pw.CrossAxisAlignment.start,
  //           children: [
  //             _title(),
  //             pw.SizedBox(height: 15),
  //             _crossTabTable(result),
  //           ],
  //         ),
  //       ),
  //     );
  //
  //     pdf.addPage(
  //       pw.Page(
  //         pageFormat: PdfPageFormat.a3.landscape,
  //         margin: const pw.EdgeInsets.all(18),
  //         build: (_) => pw.Column(
  //           crossAxisAlignment: pw.CrossAxisAlignment.start,
  //           children: [
  //             _title(),
  //             pw.SizedBox(height: 15),
  //             _summaryTable(result),
  //           ],
  //         ),
  //       ),
  //     );
  //     return pdf.save();
  //   }
  //
  //   static pw.Widget _title() {
  //     return pw.Column(
  //       crossAxisAlignment: pw.CrossAxisAlignment.start,
  //       children: [
  //
  //         pw.Text(
  //           "DIGITAL ARR",
  //           style: pw.TextStyle(
  //             fontSize: 24,
  //             fontWeight: pw.FontWeight.bold,
  //           ),
  //         ),
  //
  //         pw.Text(
  //           "Cross Tab Report",
  //           style: const pw.TextStyle(
  //             fontSize: 16,
  //           ),
  //         ),
  //
  //       ],
  //     );
  //   }
  //
  //   static pw.Widget _sectionTitle(String title) {
  //     return pw.Container(
  //       width: double.infinity,
  //       padding: const pw.EdgeInsets.all(6),
  //       color: PdfColors.grey300,
  //       child: pw.Text(
  //         title,
  //         style: pw.TextStyle(
  //           fontWeight: pw.FontWeight.bold,
  //           fontSize: 14,
  //         ),
  //       ),
  //     );
  //   }
  //
  //   static pw.Widget _cell(
  //       String text, {
  //         bool header = false,
  //       }) {
  //     return pw.Container(
  //       padding: const pw.EdgeInsets.all(4),
  //       alignment: pw.Alignment.center,
  //       decoration: pw.BoxDecoration(
  //         color: header
  //             ? PdfColors.grey300
  //             : PdfColors.white,
  //         border: pw.Border.all(),
  //       ),
  //       child: pw.Text(
  //         text,
  //         textAlign: pw.TextAlign.center,
  //         style: pw.TextStyle(
  //           fontSize: 8,
  //           fontWeight:
  //           header
  //               ? pw.FontWeight.bold
  //               : pw.FontWeight.normal,
  //         ),
  //       ),
  //     );
  //   }
  //   static pw.Widget _dataEntryTable(
  //       CrossTabResult result,
  //       ) {
  //
  //     if (result.dataEntry.isEmpty) {
  //       return pw.Container();
  //     }
  //
  //     final headers = <String>[
  //       "Part",
  //       "Master",
  //     ];
  //
  //     for (final op in result.dataEntry.first.operatorTrials) {
  //       headers.add("${op.employeeCode}\nT1");
  //       headers.add("${op.employeeCode}\nT2");
  //       headers.add("${op.employeeCode}\nT3");
  //     }
  //
  //     final data = <List<String>>[];
  //
  //     data.add(headers);
  //
  //     for (final row in result.dataEntry) {
  //
  //       final r = <String>[
  //         row.partNumber,
  //         row.expert.toString(),
  //       ];
  //
  //       for (final op in row.operatorTrials) {
  //         r.add(op.trial1.toString());
  //         r.add(op.trial2.toString());
  //         r.add(op.trial3.toString());
  //       }
  //
  //       data.add(r);
  //     }
  //
  //     return pw.Column(
  //       crossAxisAlignment: pw.CrossAxisAlignment.start,
  //       children: [
  //
  //         _sectionTitle("DATA ENTRY"),
  //         pw.Center(
  //           child: pw.TableHelper.fromTextArray(
  //             border: pw.TableBorder.all(),
  //             headerStyle: pw.TextStyle(
  //               fontWeight: pw.FontWeight.bold,
  //               fontSize: 9,
  //               color: PdfColors.black,
  //             ),
  //             headerDecoration: const pw.BoxDecoration(
  //               color: PdfColors.blue100,
  //             ),
  //             cellStyle: const pw.TextStyle(
  //               fontSize: 8,
  //             ),
  //             headers: data.first,
  //             data: data.skip(1).toList(),
  //           ),
  //         ),
  //       ],
  //
  //     );
  //   }
  //   static pw.Widget _calculationTable(
  //       CrossTabResult result,
  //       ) {
  //
  //     if (result.calculations.isEmpty) {
  //       return pw.Container();
  //     }
  //
  //     final headers = <String>[
  //       "Sample",
  //       "Expert",
  //     ];
  //
  //     for (final op in result.calculations.first.operators) {
  //
  //       headers.add("${op.employeeCode} T1");
  //       headers.add("${op.employeeCode} T2");
  //       headers.add("${op.employeeCode} T3");
  //       headers.add("${op.employeeCode} Same");
  //       headers.add("${op.employeeCode} Correct");
  //       headers.add("${op.employeeCode} Over");
  //       headers.add("${op.employeeCode} Escape");
  //
  //     }
  //
  //     headers.add("Repeat");
  //     headers.add("Reprod");
  //
  //     final rows = <List<String>>[];
  //
  //     for (final row in result.calculations) {
  //
  //       final r = <String>[
  //         row.sampleNo.toString(),
  //         row.expert,
  //       ];
  //
  //       for (final op in row.operators) {
  //
  //         r.add(op.trial1);
  //         r.add(op.trial2);
  //         r.add(op.trial3);
  //         r.add(op.same.toString());
  //         r.add(op.correct.toString());
  //         r.add(op.overkill.toString());
  //         r.add(op.escape.toString());
  //
  //       }
  //
  //       r.add(row.overallRepeatability.toString());
  //       r.add(row.overallReproducibility.toString());
  //
  //       rows.add(r);
  //
  //     }
  //
  //     return pw.Column(
  //       crossAxisAlignment: pw.CrossAxisAlignment.start,
  //       children: [
  //
  //         _sectionTitle("CALCULATIONS"),
  //
  //         pw.Center(
  //           child: pw.TableHelper.fromTextArray(border: pw.TableBorder.all(),
  //             headers: headers,
  //             data: rows,
  //             headerStyle: pw.TextStyle(
  //               fontWeight: pw.FontWeight.bold,
  //               fontSize: 7,
  //             ),
  //             headerDecoration: const pw.BoxDecoration(
  //               color: PdfColors.blue100,
  //             ),
  //             cellStyle: const pw.TextStyle(
  //               fontSize: 7,
  //             ),
  //           ),
  //         ),
  //       ],
  //     );
  //   }
  //   static pw.Widget _statisticsTable(
  //       CrossTabResult result,
  //       ) {
  //     if (result.statisticalReport.isEmpty) {
  //       return pw.Container();
  //     }
  //
  //     final rows = <List<String>>[];
  //
  //     final operators =
  //     (result.statisticalReport["operators"] as List)
  //         .cast<Map<String, dynamic>>();
  //
  //     rows.add([
  //       "Operator",
  //       "Inspected",
  //       "Matched",
  //       "Score",
  //       "LCL95",
  //       "UCL95",
  //       "Attr Total",
  //       "Attr Matched",
  //       "Attr Score",
  //       "Attr LCL95",
  //       "Attr UCL95",
  //       "Overkill",
  //       "Escape",
  //     ]);
  //
  //     for (int i = 0; i < operators.length; i++) {
  //
  //       final op = operators[i];
  //
  //       String pct(dynamic v) => v == null ? "-" : "${((v as num) * 100).toStringAsFixed(2)}%";
  //
  //       rows.add([
  //
  //         "Operator ${i + 1}",
  //
  //         "${op["totalInspected"]}",
  //
  //         "${op["matched"]}",
  //
  //         pct(op["calculatedScore"]),
  //
  //         pct(op["lcl95"]),
  //
  //         pct(op["ucl95"]),
  //
  //         "${op["attributeTotal"]}",
  //
  //         "${op["attributeMatched"]}",
  //
  //         pct(op["attributeScore"]),
  //
  //         pct(op["attributeLcl95"]),
  //
  //         pct(op["attributeUcl95"]),
  //
  //         "${op["overkill"]}",
  //
  //         "${op["escape"]}",
  //
  //       ]);
  //
  //     }
  //     return pw.Column(
  //       crossAxisAlignment: pw.CrossAxisAlignment.start,
  //       children: [
  //
  //         _sectionTitle("STATISTICAL REPORT"),
  //
  //         pw.Center(
  //             child: pw.TableHelper.fromTextArray(
  //               border: pw.TableBorder.all(),
  //
  //               headerDecoration:
  //               const pw.BoxDecoration(
  //                 color: PdfColors.blue100,
  //               ),
  //
  //               headerStyle: pw.TextStyle(
  //                 fontWeight: pw.FontWeight.bold,
  //                 fontSize: 9,
  //               ),
  //
  //               cellStyle:
  //               const pw.TextStyle(
  //                 fontSize: 8,
  //               ),
  //
  //               headers: rows.first,
  //
  //               data: rows.skip(1).toList(),
  //
  //             )
  // // headerStyle: pw.TextStyle(
  // // fontWeight: pw.FontWeight.bold,
  // // ),
  // // ),
  //         ),
  //       ],
  //     );
  //   }
  //   static pw.Widget _crossTabTable(
  //       CrossTabResult result,
  //       ) {
  //
  //     if (result.crossTab.isEmpty) {
  //       return pw.Container();
  //     }
  //
  //     final operators =
  //     (result.crossTab["operators"] as List)
  //         .cast<Map<String, dynamic>>();
  //
  //     return pw.Column(
  //
  //       crossAxisAlignment: pw.CrossAxisAlignment.start,
  //
  //       children: [
  //
  //         _sectionTitle("CROSS TAB"),
  //
  //         ...List.generate(
  //           operators.length,
  //               (index) {
  //
  //             final op = operators[index];
  //
  //             return pw.Column(
  //
  //               crossAxisAlignment:
  //               pw.CrossAxisAlignment.start,
  //
  //               children: [
  //
  //                 pw.SizedBox(height: 12),
  //
  //                 pw.Text(
  //                   "Operator ${index + 1}",
  //                   style: pw.TextStyle(
  //                     fontWeight:
  //                     pw.FontWeight.bold,
  //                     fontSize: 11,
  //                   ),
  //                 ),
  //
  //                 pw.SizedBox(height: 6),
  //
  //                 pw.TableHelper.fromTextArray(
  //
  //                   border: pw.TableBorder.all(),
  //
  //                   headers: const [
  //
  //                     "",
  //
  //                     "Observed PASS",
  //
  //                     "Observed FAIL",
  //
  //                   ],
  //
  //                   data: [
  //
  //                     [
  //
  //                       "Expert PASS",
  //
  //                       "${op["PP"]}",
  //
  //                       "${op["PF"]}",
  //
  //                     ],
  //
  //                     [
  //
  //                       "Expert FAIL",
  //
  //                       "${op["FP"]}",
  //
  //                       "${op["FF"]}",
  //
  //                     ],
  //
  //                   ],
  //
  //                 ),
  //
  //                 pw.SizedBox(height: 8),
  //
  //                 pw.TableHelper.fromTextArray(
  //
  //                   border: pw.TableBorder.all(),
  //
  //                   headers: const [
  //
  //                     "Metric",
  //
  //                     "Value",
  //
  //                   ],
  //
  //                   data: [
  //
  //                     [
  //
  //                       "Observed Agreement",
  //
  //                       "${((op["observedAgreement"] as num) * 100).toStringAsFixed(2)}%",
  //
  //                     ],
  //
  //                     [
  //
  //                       "Chance Agreement",
  //
  //                       "${((op["chanceAgreement"] as num) * 100).toStringAsFixed(2)}%",
  //
  //                     ],
  //
  //                     [
  //
  //                       "Kappa",
  //
  //                       "${(op["kappaPercent"] as num).toStringAsFixed(2)}%",
  //
  //                     ],
  //
  //                     [
  //
  //                       "Overkill Rate (False Alarm)",
  //
  //                       "${((op["overkillRatePercent"] as num?) ?? 0).toStringAsFixed(2)}%",
  //
  //                     ],
  //
  //                     [
  //
  //                       "Escape Rate (Miss Rate)",
  //
  //                       "${((op["escapeRatePercent"] as num?) ?? 0).toStringAsFixed(2)}%",
  //
  //                     ],
  //
  //                   ],
  //
  //                 ),
  //
  //               ],
  //
  //             );
  //
  //           },
  //
  //         ),
  //
  //       ],
  //
  //     );
  //
  //   }
  //   static pw.Widget _summaryTable(
  //       CrossTabResult result,
  //       ) {
  //     if (result.arrSummary.isEmpty) {
  //       return pw.Container();
  //     }
  //
  //     final summary = result.arrSummary;
  //
  //     String text(dynamic v) => v?.toString() ?? "";
  //
  //     List<double> nums(String key) =>
  //         (summary[key] as List?)?.cast<num>().map((e) => e.toDouble()).toList() ??
  //             [];
  //
  //     String opVals(List<double> vals, {bool percent = true}) =>
  //         vals.isEmpty
  //             ? "-"
  //             : vals
  //             .map((v) => percent ? "${v.toStringAsFixed(2)}%" : v.toStringAsFixed(3))
  //             .join(" / ");
  //
  //     final repeatability = nums("repeatabilityByOperator");
  //     final reproducibility = nums("reproducibilityByOperator");
  //     final kappa = nums("kappaByOperator");
  //     final missRate = nums("missRateByOperator");
  //     final falseAlert = nums("falseAlertByOperator");
  //
  //     final data = <List<String>>[
  //       [
  //         "Repeatability (by operator)",
  //         opVals(repeatability),
  //         text(summary["repeatabilityStatus"]),
  //       ],
  //       [
  //         "Reproducibility (by operator)",
  //         opVals(reproducibility),
  //         text(summary["reproducibilityStatus"]),
  //       ],
  //       [
  //         "Agreement",
  //         "${(summary["agreement"] as num? ?? 0).toStringAsFixed(2)}%",
  //         text(summary["agreementStatus"]),
  //       ],
  //       [
  //         "Effectiveness (vs Attribute)",
  //         "${(summary["effectiveness"] as num? ?? 0).toStringAsFixed(2)}%",
  //         text(summary["effectivenessStatus"]),
  //       ],
  //       [
  //         "Kappa (by operator)",
  //         opVals(kappa, percent: false),
  //         text(summary["kappaStatus"]),
  //       ],
  //       [
  //         "Miss Rate (by operator)",
  //         opVals(missRate),
  //         text(summary["missRateStatus"]),
  //       ],
  //       [
  //         "False Alarm (by operator)",
  //         opVals(falseAlert),
  //         text(summary["falseAlertStatus"]),
  //       ],
  //       [
  //         "Overall Status",
  //         "",
  //         text(summary["overallStatus"]),
  //       ],
  //     ];
  //
  //     return pw.Column(
  //       crossAxisAlignment: pw.CrossAxisAlignment.start,
  //       children: [
  //         _sectionTitle("ARR SUMMARY"),
  //
  //         pw.Text(
  //           "Candidates: ${summary["candidateCount"]}   Parts: ${summary["partCount"]}",
  //           style: const pw.TextStyle(fontSize: 9),
  //         ),
  //         pw.SizedBox(height: 6),
  //
  //         pw.TableHelper.fromTextArray(
  //           border: pw.TableBorder.all(),
  //
  //           headers: const [
  //             "Parameter",
  //             "Value",
  //             "Status",
  //           ],
  //
  //           data: data,
  //
  //           headerDecoration: const pw.BoxDecoration(
  //             color: PdfColors.blue100,
  //           ),
  //
  //           headerStyle: pw.TextStyle(
  //             fontWeight: pw.FontWeight.bold,
  //             fontSize: 9,
  //           ),
  //
  //           cellStyle: const pw.TextStyle(
  //             fontSize: 8,
  //           ),
  //         ),
  //       ],
  //     );
  //   }
  // }
  
  
  // This is v2 code by claude
  import 'dart:math' as math;
  import 'dart:typed_data';
  
  import 'package:pdf/pdf.dart';
  import 'package:pdf/widgets.dart' as pw;
  
  import '../models/cross_tab_result.dart';
  
  /// Renders the Cross Tab Report PDF so it is visually equivalent to the
  /// Flutter `CrossTabResultScreen` (Data Entry / Calculations / Statistics /
  /// Cross Tab / ARR Summary tabs).
  ///
  /// This file only lays the existing [CrossTabResult] values out on the
  /// page. Every number here is read directly from `result.dataEntry`,
  /// `result.calculations`, `result.statisticalReport`, `result.crossTab` and
  /// `result.arrSummary` — nothing is recalculated or hardcoded.
  class CrossTabReportPdf {
    CrossTabReportPdf._();
  
    // ---------------------------------------------------------------------
    // Shared colors / sizes
    // ---------------------------------------------------------------------
  
    // Built with the plain const PdfColor(red, green, blue) constructor
    // (0-1 per channel) rather than PdfColor.fromInt, whose const-ness has
    // varied across releases of the pdf package.
    static const PdfColor _borderColor = PdfColor(0.843137, 0.843137, 0.843137); // #d7d7d7
    static const PdfColor _headerColor = PdfColor(0.956863, 0.956863, 0.956863); // #f4f4f4
  
    // Same series colors used on the Flutter Statistics tab.
    static const PdfColor _uclLclColor = PdfColor(0.866667, 0.031373, 0.023529); // #dd0806
    static const PdfColor _scoreColor = PdfColor(0.121569, 0.717647, 0.078431); // #1fb714
  
    static Future<Uint8List> generate({
      required CrossTabResult result,
    }) async {
      final pdf = pw.Document();
  
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a3.landscape,
          margin: const pw.EdgeInsets.all(18),
          header: (_) => _pageHeader(),
          footer: (context) => _pageFooter(context),
          build: (_) => [
            _sectionTitle("DATA ENTRY"),
            pw.SizedBox(height: 10),
            ..._dataEntryWidgets(result),
          ],
        ),
      );
  
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a3.landscape,
          margin: const pw.EdgeInsets.all(18),
          header: (_) => _pageHeader(),
          footer: (context) => _pageFooter(context),
          build: (_) => [
            _sectionTitle("CALCULATIONS"),
            pw.SizedBox(height: 10),
            ..._calculationsWidgets(result),
          ],
        ),
      );
  
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a3.landscape,
          margin: const pw.EdgeInsets.all(18),
          header: (_) => _pageHeader(),
          footer: (context) => _pageFooter(context),
          build: (_) => [
            _sectionTitle("STATISTICAL REPORT"),
            pw.SizedBox(height: 10),
            ..._statisticsWidgets(result),
          ],
        ),
      );
  
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a3.landscape,
          margin: const pw.EdgeInsets.all(18),
          header: (_) => _pageHeader(),
          footer: (context) => _pageFooter(context),
          build: (_) => [
            _sectionTitle("CROSS TAB"),
            pw.SizedBox(height: 10),
            ..._crossTabWidgets(result),
          ],
        ),
      );
  
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a3.landscape,
          margin: const pw.EdgeInsets.all(18),
          header: (_) => _pageHeader(),
          footer: (context) => _pageFooter(context),
          build: (_) => [
            _sectionTitle("ARR SUMMARY"),
            pw.SizedBox(height: 10),
            ..._summaryWidgets(result),
          ],
        ),
      );
  
      return pdf.save();
    }
  
    // =====================================================================
    // Shared chrome
    // =====================================================================
  
    static pw.Widget _pageHeader() {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "DIGITAL ARR",
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            "Cross Tab Report",
            style: const pw.TextStyle(fontSize: 13),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(thickness: 1, color: _borderColor),
        ],
      );
    }
  
    static pw.Widget _pageFooter(pw.Context context) {
      return pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          "Page ${context.pageNumber} of ${context.pagesCount}",
          style: const pw.TextStyle(fontSize: 8),
        ),
      );
    }
  
    static pw.Widget _sectionTitle(String title) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        color: PdfColors.grey300,
        child: pw.Text(
          title,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
        ),
      );
    }
  
    static pw.Widget _cell(
        String text, {
          double width = 30,
          double height = 22,
          bool header = false,
          bool bold = false,
          PdfColor textColor = PdfColors.black,
          double fontSize = 7,
        }) {
      return pw.Container(
        width: width,
        height: height,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          color: header ? _headerColor : PdfColors.white,
          border: pw.Border.all(color: _borderColor, width: 0.5),
        ),
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: textColor,
            fontSize: fontSize,
          ),
        ),
      );
    }
  
    static PdfColor _tint(PdfColor color, double alpha) {
      return PdfColor(
        color.red * alpha + (1 - alpha),
        color.green * alpha + (1 - alpha),
        color.blue * alpha + (1 - alpha),
      );
    }
  
    // =====================================================================
    // DATA ENTRY
    // =====================================================================
  
    static const double _partW = 55;
    static const double _masterW = 42;
    static const double _trialW = 28;
    static const double _sameW = 46;
    static const double _correctW = 54;
  
    static List<pw.Widget> _dataEntryWidgets(CrossTabResult result) {
      if (result.dataEntry.isEmpty) {
        return [pw.Text("No Data")];
      }
  
      final operators = result.dataEntry.first.operatorTrials;
  
      final widgets = <pw.Widget>[
        _dataEntryHeaderRow(operators),
      ];
  
      for (final row in result.dataEntry) {
        widgets.add(_dataEntryRow(row));
      }
  
      widgets.add(pw.SizedBox(height: 18));
      widgets.addAll(_dataEntryFooter(result, operators));
  
      return widgets;
    }
  
    static pw.Widget _dataEntryHeaderRow(List<OperatorTrials> operators) {
      return pw.Row(
        children: [
          _cell(
            "Part",
            width: _partW,
            height: 46,
            header: true,
            bold: true,
            fontSize: 8,
          ),
          _cell(
            "Master",
            width: _masterW,
            height: 46,
            header: true,
            bold: true,
            fontSize: 8,
          ),
          ...operators.expand(
                (op) => [
              pw.Container(
                width: _trialW * 3,
                height: 46,
                decoration: pw.BoxDecoration(
                  color: _headerColor,
                  border: pw.Border.all(color: _borderColor, width: 0.5),
                ),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      op.candidateName,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 7,
                      ),
                    ),
                    pw.Text(
                      op.employeeCode,
                      style: const pw.TextStyle(fontSize: 6),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Center(
                            child: pw.Text(
                              "T1",
                              style: const pw.TextStyle(fontSize: 6),
                            ),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Center(
                            child: pw.Text(
                              "T2",
                              style: const pw.TextStyle(fontSize: 6),
                            ),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Center(
                            child: pw.Text(
                              "T3",
                              style: const pw.TextStyle(fontSize: 6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          _cell(
            "All Same",
            width: _sameW,
            height: 46,
            header: true,
            bold: true,
            fontSize: 7,
          ),
          _cell(
            "All Correct",
            width: _correctW,
            height: 46,
            header: true,
            bold: true,
            fontSize: 7,
          ),
        ],
      );
    }
  
    static pw.Widget _dataEntryRow(DataEntryRow row) {
      final allSame = row.operatorTrials.every(
            (e) => e.trial1 == e.trial2 && e.trial2 == e.trial3,
      );
  
      final allCorrect = row.operatorTrials.every(
            (e) =>
        e.trial1 == row.expert &&
            e.trial2 == row.expert &&
            e.trial3 == row.expert,
      );
  
      return pw.Row(
        children: [
          _cell(row.partNumber, width: _partW, bold: true),
          _cell(row.expert.toString(), width: _masterW, bold: true),
          ...row.operatorTrials.expand(
                (op) => [
              _cell(
                op.trial1.toString(),
                width: _trialW,
                textColor:
                op.trial1 == row.expert ? PdfColors.black : PdfColors.red,
              ),
              _cell(
                op.trial2.toString(),
                width: _trialW,
                textColor:
                op.trial2 == row.expert ? PdfColors.black : PdfColors.red,
              ),
              _cell(
                op.trial3.toString(),
                width: _trialW,
                textColor:
                op.trial3 == row.expert ? PdfColors.black : PdfColors.red,
              ),
            ],
          ),
          _cell(
            allSame ? "1" : "0",
            width: _sameW,
            bold: true,
            textColor: allSame ? PdfColors.green : PdfColors.red,
          ),
          _cell(
            allCorrect ? "1" : "0",
            width: _correctW,
            bold: true,
            textColor: allCorrect ? PdfColors.green : PdfColors.red,
          ),
        ],
      );
    }
  
    static List<pw.Widget> _dataEntryFooter(
        CrossTabResult result,
        List<OperatorTrials> operators,
        ) {
      pw.Widget footerOperatorRow(String title, List values) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: _partW + _masterW,
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
              ...List.generate(
                operators.length,
                    (i) => pw.SizedBox(
                  width: _trialW * 3,
                  child: pw.Center(
                    child: pw.Text(
                      "${(values[i] as num).toStringAsFixed(2)}%",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
  
      pw.Widget footerSingleRow(
          String title,
          double value, {
            PdfColor titleColor = PdfColors.black,
          }) {
        return pw.Row(
          children: [
            pw.Expanded(child: pw.SizedBox()),
            pw.Text(
              title,
              style: pw.TextStyle(
                color: titleColor,
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Text(
              "${value.toStringAsFixed(2)}%",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            ),
          ],
        );
      }
  
      final screenEffScore =
          ((result.statisticalReport["effectiveScore"]["score"] as num)
              .toDouble()) *
              100;
  
      final screenEffScoreVsAttr =
      (result.statisticalReport["effectiveScoreVsAttribute"]["score"]
      as num)
          .toDouble();
  
      final attrInspectionAcc =
          ((result.statisticalReport["attributeInspectionAccuracy"]["score"]
          as num)
              .toDouble()) *
              100;
  
      return [
        footerOperatorRow(
          "% APPRAISER SCORE",
          result.statisticalReport["appraiserScores"] as List,
        ),
        pw.SizedBox(height: 4),
        footerOperatorRow(
          "% SCORE VS. ATTRIBUTE",
          result.statisticalReport["attributeScores"] as List,
        ),
        pw.SizedBox(height: 14),
        footerSingleRow("SCREEN % EFFECTIVE SCORE", screenEffScore),
        pw.SizedBox(height: 4),
        footerSingleRow(
          "SCREEN % EFFECTIVE SCORE VS. ATTRIBUTE",
          screenEffScoreVsAttr,
        ),
        pw.SizedBox(height: 4),
        footerSingleRow(
          "ATTRIBUTE INSPECTION ACCURACY %",
          attrInspectionAcc,
          titleColor: PdfColors.amber700,
        ),
      ];
    }
  
    // =====================================================================
    // CALCULATIONS
    // =====================================================================
  
    static const double _sampleW = 50;
    static const double _expertW = 42;
    static const double _calcSubW = 26;
    static const double _calcSameW = 56;
    static const double _calcCorrectW = 62;
  
    static List<pw.Widget> _calculationsWidgets(CrossTabResult result) {
      if (result.calculations.isEmpty) {
        return [pw.Text("No Calculation Data")];
      }
  
      final operators = result.calculations.first.operators;
  
      final widgets = <pw.Widget>[
        _calculationHeaderRow(operators),
      ];
  
      for (final row in result.calculations) {
        widgets.add(_calculationRow(row));
      }
  
      widgets.add(pw.SizedBox(height: 18));
      widgets.addAll(_calculationFooter(result, operators));
  
      return widgets;
    }
  
    static pw.Widget _calculationHeaderRow(List<OperatorCalculation> operators) {
      const subLabels = ["T1", "T2", "T3", "Same", "Correct", "OverKill", "Escape"];
  
      return pw.Row(
        children: [
          _cell(
            "Sample",
            width: _sampleW,
            height: 46,
            header: true,
            bold: true,
            fontSize: 8,
          ),
          _cell(
            "Expert",
            width: _expertW,
            height: 46,
            header: true,
            bold: true,
            fontSize: 8,
          ),
          ...operators.map(
                (op) => pw.Container(
              width: _calcSubW * 7,
              height: 46,
              decoration: pw.BoxDecoration(
                color: _headerColor,
                border: pw.Border.all(color: _borderColor, width: 0.5),
              ),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    op.candidateName,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 7,
                    ),
                  ),
                  pw.Text(
                    op.employeeCode,
                    style: const pw.TextStyle(fontSize: 6),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    children: subLabels
                        .map(
                          (l) => pw.Expanded(
                        child: pw.Center(
                          child: pw.Text(
                            l,
                            style: const pw.TextStyle(fontSize: 5),
                          ),
                        ),
                      ),
                    )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          _cell(
            "All Same",
            width: _calcSameW,
            height: 46,
            header: true,
            bold: true,
            fontSize: 7,
          ),
          _cell(
            "All Correct",
            width: _calcCorrectW,
            height: 46,
            header: true,
            bold: true,
            fontSize: 7,
          ),
        ],
      );
    }
  
    static pw.Widget _calculationRow(CalculationRow row) {
      final allSame = row.operators.every((e) => e.same == 1);
      final allCorrect = row.operators.every((e) => e.correct == 1);
  
      return pw.Row(
        children: [
          _cell(row.sampleNo.toString(), width: _sampleW, bold: true),
          _cell(row.expert, width: _expertW, bold: true),
          ...row.operators.expand(
                (op) => [
              _cell(op.trial1, width: _calcSubW),
              _cell(op.trial2, width: _calcSubW),
              _cell(op.trial3, width: _calcSubW),
              _cell(
                op.same.toString(),
                width: _calcSubW,
                textColor: op.same == 1 ? PdfColors.green : PdfColors.red,
              ),
              _cell(
                op.correct.toString(),
                width: _calcSubW,
                textColor: op.correct == 1 ? PdfColors.green : PdfColors.red,
              ),
              _cell(
                op.overkill.toString(),
                width: _calcSubW,
                textColor: op.overkill > 0 ? PdfColors.red : PdfColors.black,
              ),
              _cell(
                op.escape.toString(),
                width: _calcSubW,
                textColor: op.escape > 0 ? PdfColors.red : PdfColors.black,
              ),
            ],
          ),
          _cell(
            allSame ? "1" : "0",
            width: _calcSameW,
            bold: true,
            textColor: allSame ? PdfColors.green : PdfColors.red,
          ),
          _cell(
            allCorrect ? "1" : "0",
            width: _calcCorrectW,
            bold: true,
            textColor: allCorrect ? PdfColors.green : PdfColors.red,
          ),
        ],
      );
    }
  
    static List<pw.Widget> _calculationFooter(
        CrossTabResult result,
        List<OperatorCalculation> operators,
        ) {
      pw.Widget row(String title, String Function(int index) valueFor) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 110,
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
              ),
              ...List.generate(
                operators.length,
                    (i) => pw.SizedBox(
                  width: _calcSubW * 7,
                  child: pw.Center(
                    child: pw.Text(
                      valueFor(i),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 8,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
  
      final appraiserScores =
      result.statisticalReport["appraiserScores"] as List;
      final samples = result.statisticalReport["sampleCount"].toString();
      final opsTries = result.statisticalReport["opsTries"].toString();
      final defects = result.statisticalReport["defects"].toString();
  
      return [
        row(
          "Appraiser Score",
              (i) => "${(appraiserScores[i] as num).toStringAsFixed(2)}%",
        ),
        row("Samples", (_) => samples),
        row("Ops*Tries", (_) => opsTries),
        row("Defects", (_) => defects),
      ];
    }
  
    // =====================================================================
    // STATISTICS
    // =====================================================================
  
    static pw.Widget _statBlockTitle(String title) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        color: PdfColors.grey300,
        child: pw.Text(
          title,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
        ),
      );
    }
  
    static pw.Widget _statTable(List<String> headers, List<List<String>> rows) {
      return pw.TableHelper.fromTextArray(
        border: pw.TableBorder.all(color: _borderColor, width: 0.5),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
        cellStyle: const pw.TextStyle(fontSize: 8),
        headers: headers,
        data: rows,
      );
    }
  
    static List<pw.Widget> _statisticsWidgets(CrossTabResult result) {
      final widgets = <pw.Widget>[];
  
      widgets.addAll(_appraiserStatBlock(result));
      widgets.add(pw.SizedBox(height: 22));
      widgets.addAll(_scoreVsAttributeBlock(result));
      widgets.add(pw.SizedBox(height: 22));
      widgets.addAll(_effectiveScoreBlock(result));
      widgets.add(pw.SizedBox(height: 22));
      widgets.addAll(_effectiveScoreVsAttributeBlock(result));
      widgets.add(pw.SizedBox(height: 22));
      widgets.addAll(_inspectionAccuracyBlock(result));
  
      return widgets;
    }
  
    static List<pw.Widget> _appraiserStatBlock(CrossTabResult result) {
      final operators = result.dataEntry.first.operatorTrials;
      final operatorStats = result.statisticalReport["operators"] as List;
  
      final headers = <String>["Parameter"];
      for (final op in operators) {
        headers.add("${op.candidateName}\n(${op.employeeCode})");
      }
  
      final rows = <List<String>>[
        [
          "Total Inspected",
          ...operators.map((_) => result.dataEntry.length.toString()),
        ],
        [
          "# Matched",
          ...operatorStats.map((e) => e["matched"].toString()),
        ],
        [
          "95% UCL",
          ...operatorStats.map(
                (e) => "${((e["ucl95"] as num) * 100).toStringAsFixed(2)}%",
          ),
        ],
        [
          "Calculated Score",
          ...operatorStats.map(
                (e) =>
            "${(((e["calculatedScore"] ?? 0) as num).toDouble() * 100).toStringAsFixed(2)}%",
          ),
        ],
        [
          "95% LCL",
          ...operatorStats.map(
                (e) => "${((e["lcl95"] as num) * 100).toStringAsFixed(2)}%",
          ),
        ],
      ];
  
      final scores = (result.statisticalReport["appraiserScores"] as List)
          .map((e) => (e as num).toDouble())
          .toList();
      final ucl = operatorStats
          .map((e) => ((e["ucl95"] as num).toDouble()) * 100)
          .toList();
      final lcl = operatorStats
          .map((e) => ((e["lcl95"] as num).toDouble()) * 100)
          .toList();
  
      return [
        _statBlockTitle("% Appraiser"),
        pw.SizedBox(height: 8),
        _statTable(headers, rows),
        pw.SizedBox(height: 14),
        _lineChart(
          title: "% Appraiser",
          categories: operators.map((o) => o.candidateName).toList(),
          scores: scores,
          ucl: ucl,
          lcl: lcl,
        ),
        _chartLegend(),
      ];
    }
  
    static List<pw.Widget> _scoreVsAttributeBlock(CrossTabResult result) {
      final operators = result.dataEntry.first.operatorTrials;
      final operatorStats = result.statisticalReport["operators"] as List;
      final attributeScores = result.statisticalReport["attributeScores"] as List;
  
      final headers = <String>["Parameter"];
      for (final op in operators) {
        headers.add("${op.candidateName}\n(${op.employeeCode})");
      }
  
      final rows = <List<String>>[
        [
          "Total Inspected",
          ...operators.map((_) => result.dataEntry.length.toString()),
        ],
        [
          "95% UCL",
          ...operatorStats.map(
                (e) =>
            "${((e["attributeUcl95"] as num) * 100).toStringAsFixed(2)}%",
          ),
        ],
        [
          "95% LCL",
          ...operatorStats.map(
                (e) =>
            "${((e["attributeLcl95"] as num) * 100).toStringAsFixed(2)}%",
          ),
        ],
        [
          "# Matched",
          ...operatorStats.map((e) => e["matched"].toString()),
        ],
        [
          "Calculated Score",
          ...List.generate(
            operatorStats.length,
                (i) => "${(attributeScores[i] as num).toStringAsFixed(2)}%",
          ),
        ],
        [
          "Escape / Miss Rate",
          ...operatorStats.map((e) => e["escape"].toString()),
        ],
        [
          "False Alarm Rate",
          ...operatorStats.map((e) => e["overkill"].toString()),
        ],
      ];
  
      final scores = attributeScores.map((e) => (e as num).toDouble()).toList();
      final ucl = operatorStats
          .map((e) => ((e["attributeUcl95"] as num).toDouble()) * 100)
          .toList();
      final lcl = operatorStats
          .map((e) => ((e["attributeLcl95"] as num).toDouble()) * 100)
          .toList();
  
      return [
        _statBlockTitle("% Score vs Attribute"),
        pw.SizedBox(height: 8),
        _statTable(headers, rows),
        pw.SizedBox(height: 14),
        _lineChart(
          title: "% Score vs Attribute",
          categories: operators.map((o) => o.candidateName).toList(),
          scores: scores,
          ucl: ucl,
          lcl: lcl,
        ),
        _chartLegend(),
      ];
    }
  
    static List<pw.Widget> _effectiveScoreBlock(CrossTabResult result) {
      final data = result.statisticalReport["effectiveScore"];
  
      final rows = <List<String>>[
        ["Total Inspected", result.dataEntry.length.toString()],
        ["# Agreement", data["yesCount"].toString()],
        [
          "95% UCL",
          "${(((data["ucl95"] as num).toDouble()) * 100).toStringAsFixed(2)}%",
        ],
        [
          "Calculated Score",
          "${(((data["score"] as num).toDouble()) * 100).toStringAsFixed(2)}%",
        ],
        [
          "95% LCL",
          "${(((data["lcl95"] as num).toDouble()) * 100).toStringAsFixed(2)}%",
        ],
      ];
  
      return [
        _statBlockTitle("% Effective Score"),
        pw.SizedBox(height: 8),
        _statTable(["Parameter", "Value"], rows),
      ];
    }
  
    static List<pw.Widget> _effectiveScoreVsAttributeBlock(
        CrossTabResult result,
        ) {
      final data = result.statisticalReport["effectiveScoreVsAttribute"];
  
      final rows = <List<String>>[
        ["Total Inspected", result.dataEntry.length.toString()],
        ["# Agreement", data["yesCount"].toString()],
        [
          "95% UCL",
          "${(((data["ucl95"] as num).toDouble()) * 100).toStringAsFixed(2)}%",
        ],
        [
          "Calculated Score",
          "${((data["score"] ?? 0) as num).toStringAsFixed(2)}%",
        ],
        [
          "95% LCL",
          "${(((data["lcl95"] as num).toDouble()) * 100).toStringAsFixed(2)}%",
        ],
      ];
  
      return [
        _statBlockTitle("% Effective Score vs Attribute"),
        pw.SizedBox(height: 8),
        _statTable(["Parameter", "Value"], rows),
      ];
    }
  
    static List<pw.Widget> _inspectionAccuracyBlock(CrossTabResult result) {
      final data = result.statisticalReport["attributeInspectionAccuracy"];
  
      final rows = <List<String>>[
        ["Total Opportunities", data["total"].toString()],
        ["# Accurate", data["correct"].toString()],
        [
          "95% UCL",
          "${(((data["ucl95"] as num).toDouble()) * 100).toStringAsFixed(2)}%",
        ],
        [
          "Calculated Score",
          "${(((data["score"] as num).toDouble()) * 100).toStringAsFixed(2)}%",
        ],
        [
          "95% LCL",
          "${(((data["lcl95"] as num).toDouble()) * 100).toStringAsFixed(2)}%",
        ],
      ];
  
      return [
        _statBlockTitle("Attribute Inspection Accuracy"),
        pw.SizedBox(height: 8),
        _statTable(["Parameter", "Value"], rows),
      ];
    }
  
    // ---- line chart --------------------------------------------------------
    // Built from plain, well-supported layout widgets (Stack / Positioned /
    // Transform) instead of the pdf package's Chart widget, which is still
    // marked "in preview" upstream. This gives full control over the axes so
    // every tick is an exact, single, unambiguous label — one operator name
    // per x position and one fixed value per y gridline (80/90/100/110),
    // matching the intent of the Flutter Statistics tab without repeating
    // its garbled/duplicated auto-generated tick labels.
  
    static pw.Widget _chartLegend() {
      pw.Widget swatch(PdfColor color, String label) {
        return pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Container(width: 10, height: 10, color: color),
            pw.SizedBox(width: 4),
            pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          ],
        );
      }
  
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 6, left: 8),
        child: pw.Row(
          children: [
            swatch(_uclLclColor, "95% UCL / LCL"),
            pw.SizedBox(width: 18),
            swatch(_scoreColor, "Calculated Score"),
          ],
        ),
      );
    }
  
    static pw.Widget _lineChart({
      required String title,
      required List<String> categories,
      required List<double> scores,
      required List<double> ucl,
      required List<double> lcl,
    }) {
      const double minY = 80;
      const double maxY = 110;
  
      const double chartWidth = 720;
      const double chartHeight = 250;
      const double leftSpace = 42;
      const double bottomSpace = 38;
  
      final count = categories.length;
  
      double x(double index) {
        if (count <= 1) {
          return chartWidth / 2;
        }
  
        return index * chartWidth / (count - 1);
      }
  
      // PDF CustomPaint uses a bottom-up coordinate system.
      // 110% must therefore be at the TOP and 80% at the BOTTOM.
      double y(double value) {
        final v = value.clamp(minY, maxY).toDouble();
  
        return chartHeight -
            ((v - minY) / (maxY - minY)) * chartHeight;
      }
  
      void drawLine(
          dynamic canvas,
          double x1,
          double y1,
          double x2,
          double y2,
          PdfColor color, {
            double width = 1.5,
            bool dashed = false,
          }) {
        canvas.setColor(color);
        canvas.setLineWidth(width);
  
        if (!dashed) {
          canvas.drawLine(
            x1,
            y1,
            x2,
            y2,
          );
          return;
        }
  
        final dx = x2 - x1;
        final dy = y2 - y1;
  
        final length =
        math.sqrt(dx * dx + dy * dy);
  
        if (length <= 0) {
          return;
        }
  
        final ux = dx / length;
        final uy = dy / length;
  
        const double dashLength = 7;
        const double gapLength = 5;
  
        double distance = 0;
  
        while (distance < length) {
          final start = distance;
  
          final end = math.min(
            distance + dashLength,
            length,
          );
  
          canvas.drawLine(
            x1 + ux * start,
            y1 + uy * start,
            x1 + ux * end,
            y1 + uy * end,
          );
  
          distance += dashLength + gapLength;
        }
      }
  
      void drawPoint(
          dynamic canvas,
          double px,
          double py,
          PdfColor color,
          ) {
        canvas.setColor(color);
        canvas.setLineWidth(5.0);

        // Use a tiny stroked line instead of fillPath().
        // This prevents the PDF graphics path from filling the entire chart.
        canvas.drawLine(
          px - 2.5,
          py,
          px + 2.5,
          py,
        );
      }
  
      pw.Widget chart = pw.SizedBox(
        width: leftSpace + chartWidth,
        height: chartHeight + bottomSpace,
        child: pw.Stack(
          children: [
  
            // =============================================================
            // PLOT AREA
            // =============================================================
  
            pw.Positioned(
              left: leftSpace,
              top: 0,
              child: pw.CustomPaint(
                size: const PdfPoint(
                  chartWidth,
                  chartHeight,
                ),
                painter: (
                    dynamic canvas,
                    PdfPoint size,
                    ) {
  
                  // -------------------------------------------------------
                  // HORIZONTAL GRID
                  // -------------------------------------------------------
  
                  for (
                  double value = minY;
                  value <= maxY;
                  value += 5.0
                  ) {
                    final double py = y(value);
  
                    canvas.setColor(
                      PdfColors.grey300,
                    );
  
                    canvas.setLineWidth(0.5);
  
                    canvas.drawLine(
                      0.0,
                      py,
                      chartWidth,
                      py,
                    );
                  }
  
                  // -------------------------------------------------------
                  // VERTICAL GRID
                  // -------------------------------------------------------
  
                  for (
                  int i = 0;
                  i < count;
                  i++
                  ) {
                    final double px = x(i.toDouble());
  
                    canvas.setColor(
                      PdfColors.grey300,
                    );
  
                    canvas.setLineWidth(0.5);
  
                    canvas.drawLine(
                      px,
                      0.0,
                      px,
                      chartHeight,
                    );
                  }
  
                  // -------------------------------------------------------
                  // BORDER
                  // -------------------------------------------------------
  
                  canvas.setColor(
                    _borderColor,
                  );
  
                  canvas.setLineWidth(0.75);
  
                  canvas.drawLine(
                    0.0,
                    0.0,
                    chartWidth,
                    0.0,
                  );
  
                  canvas.drawLine(
                    0.0,
                    chartHeight,
                    chartWidth,
                    chartHeight,
                  );
  
                  canvas.drawLine(
                    0.0,
                    0.0,
                    0.0,
                    chartHeight,
                  );
  
                  canvas.drawLine(
                    chartWidth,
                    0.0,
                    chartWidth,
                    chartHeight,
                  );
  
                  // -------------------------------------------------------
                  // UCL
                  // -------------------------------------------------------
  
                  for (
                  int i = 0;
                  i < ucl.length - 1;
                  i++
                  ) {
                    drawLine(
                      canvas,
                      x(i.toDouble()),
                      y(ucl[i]),
                      x((i + 1).toDouble()),
                      y(ucl[i + 1]),
                      _uclLclColor,
                      width: 1.5,
                    );
                  }
  
                  // -------------------------------------------------------
                  // CALCULATED SCORE
                  // -------------------------------------------------------
  
                  for (
                  int i = 0;
                  i < scores.length - 1;
                  i++
                  ) {
                    drawLine(
                      canvas,
                      x(i.toDouble()),
                      y(scores[i]),
                      x((i + 1).toDouble()),
                      y(scores[i + 1]),
                      _scoreColor,
                      width: 1.5,
                    );
                  }
  
                  // -------------------------------------------------------
                  // LCL
                  // -------------------------------------------------------
  
                  for (
                  int i = 0;
                  i < lcl.length - 1;
                  i++
                  ) {
                    drawLine(
                      canvas,
                      x(i.toDouble()),
                      y(lcl[i]),
                      x((i + 1).toDouble()),
                      y(lcl[i + 1]),
                      _uclLclColor,
                      width: 1.5,
                      dashed: true,
                    );
                  }
  
                  // -------------------------------------------------------
                  // POINTS
                  // -------------------------------------------------------
  
                  for (
                  int i = 0;
                  i < ucl.length;
                  i++
                  ) {
                    drawPoint(
                      canvas,
                      x(i.toDouble()),
                      y(ucl[i]),
                      _uclLclColor,
                    );
                  }
  
                  for (
                  int i = 0;
                  i < scores.length;
                  i++
                  ) {
                    drawPoint(
                      canvas,
                      x(i.toDouble()),
                      y(scores[i]),
                      _scoreColor,
                    );
                  }
  
                  for (
                  int i = 0;
                  i < lcl.length;
                  i++
                  ) {
                    drawPoint(
                      canvas,
                      x(i.toDouble()),
                      y(lcl[i]),
                      _uclLclColor,
                    );
                  }
                },
              ),
            ),
  
            // =============================================================
            // Y AXIS LABELS
            // =============================================================
  
            for (
            double value = minY;
            value <= maxY;
            value += 5
            )
              pw.Positioned(
                left: 0,
                top: y(value) - 4,
                child: pw.SizedBox(
                  width: leftSpace - 7,
                  child: pw.Text(
                    value.toStringAsFixed(0),
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(
                      fontSize: 7,
                    ),
                  ),
                ),
              ),
  
            // =============================================================
            // X AXIS LABELS
            // =============================================================
  
            for (
            int i = 0;
            i < count;
            i++
            )
              pw.Positioned(
                left:
                leftSpace +
                    x(i.toDouble()) -
                    35,
                top: chartHeight + 5,
                child: pw.SizedBox(
                  width: 70,
                  child: pw.Text(
                    categories[i],
                    textAlign:
                    pw.TextAlign.center,
                    maxLines: 2,
                    style: const pw.TextStyle(
                      fontSize: 6.5,
                    ),
                  ),
                ),
              ),
  
            // =============================================================
            // Y AXIS TITLE
            // =============================================================
  
            pw.Positioned(
              left: 0,
              top: chartHeight / 2 - 35,
              child: pw.Transform.rotate(
                angle: -math.pi / 2,
                child: pw.SizedBox(
                  width: 70,
                  child: pw.Text(
                    "% Efficiency",
                    textAlign:
                    pw.TextAlign.center,
                    style: const pw.TextStyle(
                      fontSize: 7,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  
      return pw.Column(
        crossAxisAlignment:
        pw.CrossAxisAlignment.start,
        children: [
          chart,
  
          pw.SizedBox(height: 4),
  
          pw.Center(
            child: pw.SizedBox(
              width:
              leftSpace +
                  chartWidth,
              child: pw.Text(
                title,
                textAlign:
                pw.TextAlign.center,
                style: pw.TextStyle(
                  fontWeight:
                  pw.FontWeight.bold,
                  fontSize: 9,
                ),
              ),
            ),
          ),
        ],
      );
    }
  
    // =====================================================================
    // CROSS TAB
    // CROSS TAB
    // =====================================================================
  
    static List<pw.Widget> _crossTabWidgets(CrossTabResult result) {
      final operators =
      (result.crossTab["operators"] as List).cast<Map<String, dynamic>>();
  
      final widgets = <pw.Widget>[];
  
      for (int i = 0; i < operators.length; i++) {
        widgets.add(_crossTabCard(i, operators[i]));
        if (i != operators.length - 1) {
          widgets.add(pw.SizedBox(height: 20));
        }
      }
  
      return widgets;
    }
  
    static pw.Widget _crossTabCard(int index, Map<String, dynamic> operator) {
      final letter = String.fromCharCode(65 + index);
  
      // cross_tab_service.dart builds PP/PF/FP/FF using an [expert][trial]
      // convention (e.g. "PF" = expert Pass & trial Fail). This matrix shows
      // rows = trial (operator) classification and columns = Expert
      // classification, so the off-diagonal cells are swapped when read here
      // — matching the same fix already applied on the Flutter screen.
      final pp = operator["PP"] as int;
      final pf = operator["FP"] as int;
      final fp = operator["PF"] as int;
      final ff = operator["FF"] as int;
      final total = operator["total"] as int;
  
      final rowPass = pp + pf;
      final rowFail = fp + ff;
      final colPass = pp + fp;
      final colFail = pf + ff;
  
      final expPP = total == 0 ? 0.0 : (rowPass * colPass) / total;
      final expPF = total == 0 ? 0.0 : (rowPass * colFail) / total;
      final expFP = total == 0 ? 0.0 : (rowFail * colPass) / total;
      final expFF = total == 0 ? 0.0 : (rowFail * colFail) / total;
  
      final expColPassTotal = expPP + expFP;
      final expColFailTotal = expPF + expFF;
      final expGrandTotal = expColPassTotal + expColFailTotal;
  
      pw.Widget cell(String text, {bool bold = false}) {
        return pw.Container(
          alignment: pw.Alignment.center,
          height: 22,
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: 8,
            ),
          ),
        );
      }
  
      pw.TableRow row(
          String c1,
          String c2,
          String c3,
          String c4,
          String c5,
          ) {
        return pw.TableRow(
          children: [cell(c1), cell(c2), cell(c3), cell(c4), cell(c5)],
        );
      }
  
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "$letter to Expert Crosstabulation",
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.SizedBox(
            width: 420,
            child: pw.Table(
              border: pw.TableBorder.all(color: _borderColor, width: 0.5),
              columnWidths: const {
                0: pw.FixedColumnWidth(55),
                1: pw.FixedColumnWidth(150),
                2: pw.FixedColumnWidth(65),
                3: pw.FixedColumnWidth(65),
                4: pw.FixedColumnWidth(60),
              },
              children: [
                row("", "", "Expert", "", "Total"),
                row("", "", "Pass", "Fail", ""),
                row(letter, "Pass", "$pp", "$pf", "$rowPass"),
                row(
                  "",
                  "Expected Count",
                  expPP.toStringAsFixed(2),
                  expPF.toStringAsFixed(2),
                  rowPass.toString(),
                ),
                row("", "Fail", "$fp", "$ff", "$rowFail"),
                row(
                  "",
                  "Expected Count",
                  expFP.toStringAsFixed(2),
                  expFF.toStringAsFixed(2),
                  rowFail.toString(),
                ),
                row("Total", "Count", "$colPass", "$colFail", "$total"),
                row(
                  "",
                  "Expected Count",
                  expColPassTotal.toStringAsFixed(2),
                  expColFailTotal.toStringAsFixed(2),
                  expGrandTotal.toStringAsFixed(2),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          _kappaBox(letter, operator),
        ],
      );
    }
  
    static pw.Widget _kappaBox(String letter, Map<String, dynamic> operator) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: _borderColor)),
        width: 260,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "Kappa $letter - Expert",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                pw.Text("Po =", style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(width: 20),
                pw.Text(
                  (operator["observedAgreement"] as num).toStringAsFixed(4),
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Text("Pe =", style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(width: 20),
                pw.Text(
                  (operator["chanceAgreement"] as num).toStringAsFixed(4),
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                // Plain ASCII (no kappa glyph / unicode minus): the base
                // PDF fonts used here don't ship Greek letters, so this
                // avoids missing-glyph rendering.
                "K = (Po - Pe) / (1 - Pe)",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                (operator["kappa"] as num).toStringAsFixed(4),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }
  
    // =====================================================================
    // ARR SUMMARY
    // =====================================================================
  
    static List<pw.Widget> _summaryWidgets(CrossTabResult result) {
      final summary = result.arrSummary;
      final operators = result.dataEntry.first.operatorTrials;
  
      String opHeader(int i) {
        if (i >= operators.length) return "-";
        final op = operators[i];
        return "${op.candidateName}\n(${op.employeeCode})";
      }
  
      PdfColor statusColor(String value) {
        switch (value.toLowerCase()) {
          case "acceptable":
            return PdfColors.green;
          case "marginally acceptable":
            return PdfColors.orange;
          default:
            return PdfColors.red;
        }
      }
  
      pw.Widget headerCell(String text) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(6),
          alignment: pw.Alignment.center,
          color: PdfColors.grey300,
          child: pw.Text(
            text,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
        );
      }
  
      pw.Widget dataCell(String text, {bool alignLeft = false}) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(6),
          alignment: alignLeft ? pw.Alignment.centerLeft : pw.Alignment.center,
          child: pw.Text(
            text,
            textAlign: alignLeft ? pw.TextAlign.left : pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 9),
          ),
        );
      }
  
      pw.Widget resultCell(String text) {
        final color = statusColor(text);
        return pw.Container(
          color: _tint(color, 0.18),
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            text,
            style: pw.TextStyle(color: color, fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
        );
      }
  
      pw.TableRow row(
          String sl,
          String criteria,
          String resultText,
          String op1,
          String op2,
          String op3,
          ) {
        return pw.TableRow(
          children: [
            dataCell(sl),
            dataCell(criteria, alignLeft: true),
            resultCell(resultText),
            dataCell(op1),
            dataCell(op2),
            dataCell(op3),
          ],
        );
      }
  
      List a(String key) => summary[key] as List;
  
      final table = pw.Table(
        border: pw.TableBorder.all(color: _borderColor, width: 0.5),
        columnWidths: const {
          0: pw.FixedColumnWidth(45),
          1: pw.FixedColumnWidth(320),
          2: pw.FixedColumnWidth(110),
          3: pw.FixedColumnWidth(90),
          4: pw.FixedColumnWidth(90),
          5: pw.FixedColumnWidth(90),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              headerCell("Sl. No."),
              headerCell("Criteria"),
              headerCell("Result"),
              headerCell(opHeader(0)),
              headerCell(opHeader(1)),
              headerCell(opHeader(2)),
            ],
          ),
          row(
            "1",
            "Agreement within appraisers on all trials",
            summary["repeatabilityStatus"].toString(),
            "${(a("repeatabilityByOperator")[0] as num).toStringAsFixed(2)}%",
            "${(a("repeatabilityByOperator")[1] as num).toStringAsFixed(2)}%",
            "${(a("repeatabilityByOperator")[2] as num).toStringAsFixed(2)}%",
          ),
          row(
            "2",
            "Agreement within appraisers & with known Std.",
            summary["reproducibilityStatus"].toString(),
            "${(a("reproducibilityByOperator")[0] as num).toStringAsFixed(2)}%",
            "${(a("reproducibilityByOperator")[1] as num).toStringAsFixed(2)}%",
            "${(a("reproducibilityByOperator")[2] as num).toStringAsFixed(2)}%",
          ),
          row(
            "3",
            "Agreement within & between appraisers",
            summary["agreementStatus"].toString(),
            "",
            "${(summary["agreement"] as num).toStringAsFixed(2)}%",
            "",
          ),
          row(
            "4",
            "Agreement within & between appraisers AND with known Std.",
            summary["effectivenessStatus"].toString(),
            "",
            "${(summary["effectiveness"] as num).toStringAsFixed(2)}%",
            "",
          ),
          row(
            "5",
            "Kappa [Individual Appraiser w.r.t. known Std.]",
            summary["kappaStatus"].toString(),
            "${(a("kappaByOperator")[0] as num).toStringAsFixed(2)}",
            "${(a("kappaByOperator")[1] as num).toStringAsFixed(2)}",
            "${(a("kappaByOperator")[2] as num).toStringAsFixed(2)}",
          ),
          row(
            "6",
            "Miss rate",
            summary["missRateStatus"].toString(),
            "${(a("missRateByOperator")[0] as num).toStringAsFixed(2)}%",
            "${(a("missRateByOperator")[1] as num).toStringAsFixed(2)}%",
            "${(a("missRateByOperator")[2] as num).toStringAsFixed(2)}%",
          ),
          row(
            "7",
            "False alarm rate",
            summary["falseAlertStatus"].toString(),
            "${(a("falseAlertByOperator")[0] as num).toStringAsFixed(2)}%",
            "${(a("falseAlertByOperator")[1] as num).toStringAsFixed(2)}%",
            "${(a("falseAlertByOperator")[2] as num).toStringAsFixed(2)}%",
          ),
          pw.TableRow(
            children: [
              pw.Container(),
              pw.Container(
                color: PdfColors.grey300,
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  "Conclusion",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                ),
              ),
              resultCell(summary["overallStatus"].toString()),
              pw.Container(),
              pw.Container(),
              pw.Container(),
            ],
          ),
        ],
      );
  
      return [table];
    }
  }