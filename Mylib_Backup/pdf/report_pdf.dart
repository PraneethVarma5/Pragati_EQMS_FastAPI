import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../services/app_data.dart';

class ReportPdf {
  ReportPdf._();

  static Future<Uint8List> generate({
    required Map<String, dynamic> record,
    required List<Map<String, dynamic>> observations,
    Map<String, dynamic>? employee,
  }) async {
    final pdf = pw.Document();

    final logo = await rootBundle.load(
      "assets/full_logo.png",
    );

    final logoImage = pw.MemoryImage(
      logo.buffer.asUint8List(),
    );
    //
    // List<Question> masterQuestions =
    // HiveService.loadBatchQuestions(
    //   record?.batchName == null
    //       ? AppData.selectedBatchId
    //       : AppData.selectedBatchId,
    // );
    //
    // if (masterQuestions.isEmpty) {
    //   masterQuestions = List.from(questions);
    // }
    //
    // final result =
    // EvaluationService.calculate();
    // final totalRows = [
    //   masterQuestions.length,
    //   AppData.trail1Answers.length,
    //   AppData.trail2Answers.length,
    //   AppData.trail3Answers.length,
    // ].reduce((a, b) => a < b ? a : b);

    final partNumbers = observations.map(
          (observation) =>
      observation["part_number_snap"]?.toString() ?? "-",
    ).toList();

    final trail1 = observations.map(
          (observation) =>
          _toInt(
            observation["trail1"],
          ),
    ).toList();

    final trail2 = observations.map(
          (observation) =>
          _toInt(
            observation["trail2"],
          ),
    ).toList();

    final trail3 = observations.map(
          (observation) =>
          _toInt(
            observation["trail3"],
          ),
    ).toList();

    final masterAnswers = observations.map(
          (observation) =>
          _toInt(
            observation["master_status_snapshot"],
          ),
    ).toList();

    final classification =
        record["classification"]
            ?.toString() ??
            "UNACCEPTABLE";

    final falseAlert =
    _toDouble(
      record["false_alert_pct"],
    );

    final missRate =
    _toDouble(
      record["miss_rate_pct"],
    );

    final effectiveness =
    _toDouble(
      record["effectiveness_pct"],
    );

    final kappa =
    _toDouble(
      record["kappa_pct"],
    );

    final totalRows =
        observations.length;

    pdf.addPage(

      pw.MultiPage(

        pageFormat: PdfPageFormat.a4,

        margin: const pw.EdgeInsets.all(20),

        footer: (context) {

          return pw.Align(

            alignment:
            pw.Alignment.centerRight,

            child: pw.Text(

              "Page ${context.pageNumber} of ${context.pagesCount}",

              style: const pw.TextStyle(

                fontSize: 10,

              ),

            ),

          );

        },

        build: (context) {
          return [

            /// COMPANY HEADER
            pw.Row(

              crossAxisAlignment:
              pw.CrossAxisAlignment.center,

              children: [

                pw.Image(
                  logoImage,
                  width: 70,
                  height: 70,
                ),

                pw.SizedBox(width: 15),

                pw.Column(

                  crossAxisAlignment:
                  pw.CrossAxisAlignment.start,

                  children: [

                    pw.Text(

                      "Digital ARR",

                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight:
                        pw.FontWeight.bold,
                      ),
                    ),

                    pw.Text(

                      "Attribute Repeatability and Reproducibility Report",


                      style: const pw.TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            pw.Divider(),
            pw.SizedBox(height: 15),

            // if (AppData.candidatePhoto != null)
            //
            //   pw.Center(
            //
            //     child: pw.Image(
            //
            //       pw.MemoryImage(
            //
            //         AppData.candidatePhoto!
            //             .readAsBytesSync(),
            //
            //       ),
            //
            //       width: 90,
            //
            //       height: 110,
            //
            //     ),
            //
            //   ),
            if (AppData.candidatePhoto != null)
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(
                    AppData.candidatePhoto!,
                  ),
                  width: 90,
                  height: 110,
                ),
              ),
            pw.SizedBox(height: 20),
            pw.SizedBox(height: 15),

            pw.Center(

              child: pw.Text(

                "OBSERVATION REPORT",

                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight:
                  pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 20),

            /// Candidate Details Card
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius:
                pw.BorderRadius.circular(5),
              ),

              padding:
              const pw.EdgeInsets.all(12),

              child: pw.Column(
                children: [

                  _detailRow(
                    "Employee Code",
                    record["employee_code_snap"]
                        ?.toString() ??
                        AppData.employeeCode,
                  ),

                  _detailRow(
                    "Appraisee",
                    employee?["full_name"]
                        ?.toString() ??
                        AppData.appraiseeName,
                  ),

                  _detailRow(
                    "Department",
                    employee?["department"]
                        ?.toString() ??
                        AppData.department,
                  ),

                  _detailRow(
                    "Product",
                    record["product"]
                        ?.toString() ??
                        AppData.productName,
                  ),

                  _detailRow(
                    "Batch",
                    record["batch_name_snap"]
                        ?.toString() ??
                        AppData.selectedBatchName,
                  ),

                  _detailRow(
                    "Certificate No",
                    record["certificate_number"]
                        ?.toString() ??
                        AppData.certificateNo,
                  ),

                  _detailRow(
                    "Total Parts",
                    "$totalRows",
                  ),

                  _detailRow(
                    "Classification",
                    classification,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 25),

            pw.Text(
              "Observation Report",
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 10),

            // pw.TableHelper.fromTextArray(
            //
            //   border: pw.TableBorder.all(),
            //
            //   headerDecoration: const pw.BoxDecoration(
            //     color: PdfColors.grey300,
            //   ),
            //
            //   headerStyle: pw.TextStyle(
            //     fontWeight: pw.FontWeight.bold,
            //     fontSize: 10,
            //   ),
            //
            //   cellStyle: const pw.TextStyle(
            //     fontSize: 9,
            //   ),
            //
            //   cellAlignment:
            //   pw.Alignment.center,
            //
            //   columnWidths: {
            //
            //     0: const pw.FixedColumnWidth(60),
            //
            //     1: const pw.FixedColumnWidth(45),
            //
            //     2: const pw.FixedColumnWidth(45),
            //
            //     3: const pw.FixedColumnWidth(45),
            //
            //     4: const pw.FixedColumnWidth(55),
            //
            //   },
            //   headers: const [
            //
            //     "Part",
            //
            //     "T1",
            //
            //     "T2",
            //
            //     "T3",
            //
            //     "Master",
            //
            //   ],
            //   data: List.generate(
            //
            //     totalRows,
            //
            //         (index) => [
            //
            //       masterQuestions[index].partNo,
            //
            //           "${AppData.trail1Answers[index]}",
            //
            //           "${AppData.trail2Answers[index]}",
            //
            //           "${AppData.trail3Answers[index]}",
            //
            //           "${masterQuestions[index].initialStatus}",
            //
            //     ],
            //
            //   ),
            //
            //
            // ),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: const {
                0: pw.FixedColumnWidth(70),
                1: pw.FixedColumnWidth(45),
                2: pw.FixedColumnWidth(45),
                3: pw.FixedColumnWidth(45),
                4: pw.FixedColumnWidth(55),
              },
              children: [

                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  children: [
                    _pdfCell(
                      "Part No",
                      heading: true,
                    ),
                    _pdfCell(
                      "T1",
                      heading: true,
                    ),
                    _pdfCell(
                      "T2",
                      heading: true,
                    ),
                    _pdfCell(
                      "T3",
                      heading: true,
                    ),
                    _pdfCell(
                      "Master",
                      heading: true,
                    ),
                  ],
                ),

                ...List.generate(totalRows, (index) {

                  final master = masterAnswers[index];

                  return pw.TableRow(
                    children: [

                      _pdfCell(partNumbers[index]),

                      _pdfCell(
                        trail1[index].toString(),
                        wrong: trail1[index] != master,
                      ),

                      _pdfCell(
                        trail2[index].toString(),
                        wrong: trail2[index] != master,
                      ),

                      _pdfCell(
                        trail3[index].toString(),
                        wrong: trail3[index] != master,
                      ),

                      _pdfCell(master.toString()),

                    ],
                  );

                }),

              ],
            ),
            pw.SizedBox(height: 25),

            pw.Text(

              "Observation Summary",

              style: pw.TextStyle(

                fontSize: 16,

                fontWeight:
                pw.FontWeight.bold,

              ),

            ),

            pw.SizedBox(height: 10),

            pw.Row(

              mainAxisAlignment:
              pw.MainAxisAlignment.spaceAround,

              children: [

                // _summaryCard(
                //
                //   "Trail 1",
                //
                //   "${AppData.trail1Answers.where((e) => e == 1).length}",
                //
                //   "${AppData.trail1Answers.where((e) => e == 0).length}",
                //
                // ),
                //
                // _summaryCard(
                //
                //   "Trail 2",
                //
                //   "${AppData.trail2Answers.where((e) => e == 1).length}",
                //
                //   "${AppData.trail2Answers.where((e) => e == 0).length}",
                //
                // ),
                //
                // _summaryCard(
                //
                //   "Trail 3",
                //
                //   "${AppData.trail3Answers.where((e) => e == 1).length}",
                //
                //   "${AppData.trail3Answers.where((e) => e == 0).length}",
                //
                // ),
                _summaryCard(

                "Trial 1",

                "${trail1.where((e) => e == 1).length}",

          "${trail1.where((e) => e == 0).length}",

          ),

          _summaryCard(

          "Trial 2",

          "${trail2.where((e) => e == 1).length}",

          "${trail2.where((e) => e == 0).length}",

          ),

          _summaryCard(

          "Trial 3",

          "${trail3.where((e) => e == 1).length}",

          "${trail3.where((e) => e == 0).length}",

          ),

              ],

            ),

            pw.SizedBox(height: 20),

            pw.Text(
              "Evaluation Metrics",
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 10),

            // pw.TableHelper.fromTextArray(
            //
            //   border: pw.TableBorder.all(),
            //
            //   columnWidths: {
            //     0: const pw.FlexColumnWidth(2),
            //     1: const pw.FlexColumnWidth(1),
            //     2: const pw.FlexColumnWidth(2),
            //   },
            //
            //   headers: const [
            //     "Metric",
            //     "Value",
            //     "Status",
            //   ],
            //
            //   headerDecoration: const pw.BoxDecoration(
            //     color: PdfColors.grey300,
            //   ),
            //
            //   data: [
            //
            //     [
            //       "False Alert %",
            //       "${result["falseAlertPercent"].toStringAsFixed(2)} %",
            //       AppData.falseAlertStatus(),
            //     ],
            //
            //     [
            //       "Miss Rate %",
            //       "${result["missRate"].toStringAsFixed(2)} %",
            //       AppData.missRateStatus(),
            //     ],
            //
            //     [
            //       "Effectiveness %",
            //       "${result["effectiveness"].toStringAsFixed(2)} %",
            //       AppData.effectivenessStatus(),
            //     ],
            //
            //     [
            //       "Kappa %",
            //       "${result["kappa"].toStringAsFixed(2)} %",
            //       AppData.kappaStatus(),
            //     ],
            //
            //     [
            //       "Final Classification",
            //       "",
            //       result["classification"],
            //     ],
            //
            //   ],
            //
            // ),
            pw.TableHelper.fromTextArray(

            border: pw.TableBorder.all(),

          columnWidths: const {

          0: pw.FlexColumnWidth(2),

          1: pw.FlexColumnWidth(1),

          2: pw.FlexColumnWidth(2),

          },

          headers: const [

          "Metric",

          "Value",

          "Status",

          ],

          headerDecoration: const pw.BoxDecoration(
          color: PdfColors.grey300,
          ),

          data: [

          [

          "False Alert %",

          "${falseAlert.toStringAsFixed(2)} %",

          falseAlert <= 5
          ? "ACCEPTABLE"
              : falseAlert < 10
          ? "MARGINALLY ACCEPTABLE"
              : "NOT ACCEPTABLE",

          ],

          [

          "Miss Rate %",

          "${missRate.toStringAsFixed(2)} %",

          missRate < 2
          ? "ACCEPTABLE"
              : missRate <= 5
          ? "MARGINALLY ACCEPTABLE"
              : "NOT ACCEPTABLE",

          ],

          [

          "Effectiveness %",

          "${effectiveness.toStringAsFixed(2)} %",

          effectiveness >= 90
          ? "ACCEPTABLE"
              : effectiveness >= 80
          ? "MARGINALLY ACCEPTABLE"
              : "NOT ACCEPTABLE",

          ],

          [

          "Kappa %",

          "${kappa.toStringAsFixed(2)} %",

          kappa >= 80
          ? "ACCEPTABLE"
              : kappa >= 60
          ? "MARGINALLY ACCEPTABLE"
              : "NOT ACCEPTABLE",

          ],

          [

          "Final Classification",

          "",

          classification,

          ],

          ],

          ),

            pw.SizedBox(height: 20),

            pw.Container(

              width: double.infinity,

              padding: const pw.EdgeInsets.all(15),

              decoration: pw.BoxDecoration(

                border: pw.Border.all(),

                // color: result["classification"] == "ACCEPTABLE"
                //
                //     ? PdfColors.green100
                //
                //     : result["classification"] ==
                //     "MARGINALLY ACCEPTABLE"
                //
                //     ? PdfColors.orange100
                //
                //     : PdfColors.red100,
                color: classification == "ACCEPTABLE"

                ? PdfColors.green100

              : classification ==
          "MARGINALLY ACCEPTABLE"

          ? PdfColors.orange100

              : PdfColors.red100,

              ),

              child: pw.Column(

                children: [

                  pw.Text(

                    "FINAL CLASSIFICATION",

                    style: pw.TextStyle(

                      fontWeight:
                      pw.FontWeight.bold,

                      fontSize: 16,

                    ),

                  ),

                  pw.SizedBox(height: 10),

                  pw.Text(

          classification,

                    style: pw.TextStyle(

                      fontSize: 20,

                      fontWeight:
                      pw.FontWeight.bold,

                    ),

                  ),

                ],

              ),

            ),

            pw.SizedBox(height: 30),

            pw.Divider(),

            pw.Center(

              child: pw.Text(

                "Digital ARR System",

                style: const pw.TextStyle(

                  fontSize: 12,

                ),

              ),

            ),

            pw.Center(
              child: pw.Text(
                record["assessment_date"] != null
                    ? "Assessment Date : ${record["assessment_date"]}"
                    : "Generated on : ${DateTime.now()}",

                style: const pw.TextStyle(
                  fontSize: 10,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
  static pw.Widget _summaryCard(
      String title,
      String pass,
      String fail,
      ) {

    return pw.Container(

      width: 140,

      padding: const pw.EdgeInsets.all(8),

      decoration: pw.BoxDecoration(

        border: pw.Border.all(),

        borderRadius:
        pw.BorderRadius.circular(4),

      ),

      child: pw.Column(

        children: [

          pw.Text(

            title,

            style: pw.TextStyle(

              fontWeight:
              pw.FontWeight.bold,

            ),

          ),

          pw.SizedBox(height: 8),

          pw.Text("1 : $pass"),

          pw.Text("0 : $fail"),

        ],

      ),

    );

  }
  static pw.Widget _detailRow(
      String title,
      String value,
      ) {
    return pw.Padding(
      padding:
      const pw.EdgeInsets.symmetric(
        vertical: 4,
      ),

      child: pw.Row(

        children: [

          pw.SizedBox(

            width: 120,

            child: pw.Text(

              title,

              style: pw.TextStyle(
                fontWeight:
                pw.FontWeight.bold,
              ),
            ),
          ),

          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }
static pw.Widget _pdfCell(
String text, {
bool heading = false,
bool wrong = false,
}) {
return pw.Padding(
padding: const pw.EdgeInsets.all(6),
child: pw.Text(
text,
textAlign: pw.TextAlign.center,
style: pw.TextStyle(
fontSize: heading ? 10 : 9,
fontWeight:
heading || wrong
? pw.FontWeight.bold
    : pw.FontWeight.normal,
color: wrong
? PdfColors.red
    : PdfColors.black,
),
),
);
}
  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
      value?.toString() ?? "",
    ) ??
        0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? "",
    ) ??
        0.0;
  }
}