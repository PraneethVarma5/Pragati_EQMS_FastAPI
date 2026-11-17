import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../services/app_data.dart';

class CombinedCertificatePdf {
  CombinedCertificatePdf._();

  static const PdfColor primaryBlue = PdfColor.fromInt(0xFF0B2E63);
  static const PdfColor gold = PdfColor.fromInt(0xFFD6A63A);
  static const PdfColor lightGrey = PdfColor.fromInt(0xFFF4F4F4);
  static const PdfColor darkGrey = PdfColor.fromInt(0xFF555555);
  static const double scale = 0.70;

  static Future<Uint8List> generate({
    required List<Map<String, dynamic>> records,
  }) async {
    final pdf = pw.Document();

    final logo = await rootBundle.load(
      "assets/full_logo.png",
    );

    final logoImage = pw.MemoryImage(
      logo.buffer.asUint8List(),
    );

    if (records.isEmpty) {
      return pdf.save();
    }

    for (final record in records) {
      pw.MemoryImage? candidateImage;

      // Current ARR photo is available in memory.
      if (AppData.candidatePhoto != null) {
        candidateImage = pw.MemoryImage(
          AppData.candidatePhoto!,
        );
      }

      final assessmentDate =
      _parseAssessmentDate(
        record["assessment_date"],
      );

      final classification =
          record["classification"]
              ?.toString() ??
              "UNACCEPTABLE";

      DateTime validTill;

      switch (classification.toUpperCase()) {
        case "ACCEPTABLE":
          validTill = DateTime(
            assessmentDate.year,
            assessmentDate.month + 3,
            assessmentDate.day,
          );
          break;

        case "MARGINALLY ACCEPTABLE":
          validTill = DateTime(
            assessmentDate.year,
            assessmentDate.month + 1,
            assessmentDate.day,
          );
          break;

        default:
          validTill = assessmentDate;
      }

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

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Center(
              child: pw.Row(
                mainAxisAlignment:
                pw.MainAxisAlignment.center,
                children: [

                  _buildFrontCard(
                    logoImage: logoImage,
                    candidateImage:
                    candidateImage,
                    record: record,
                    classification:
                    classification,
                  ),

                  pw.SizedBox(
                    width: 12 * scale,
                  ),

                  _buildBackCard(
                    record: record,
                    assessmentDate:
                    assessmentDate,
                    validTill: validTill,
                    classification:
                    classification,
                    falseAlert:
                    falseAlert,
                    missRate:
                    missRate,
                    effectiveness:
                    effectiveness,
                    kappa: kappa,
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

// static const double cardWidth = 240;
// static const double cardHeight = 380;

  // ATM Card Size
  static const double cardWidth = 240 * scale;
  static const double cardHeight = 380 * scale;

//   static pw.Widget _buildFrontCard({
//     required pw.MemoryImage logoImage,
//     required pw.MemoryImage? candidateImage,
//     required bool isPreviousRecord,
//     ArrRecord? record,
//   }) {
//     return pw.Container(
//       width: cardWidth,
//       height: cardHeight,
//       decoration: pw.BoxDecoration(
//         color: PdfColors.white,
//         borderRadius: pw.BorderRadius.circular(18*scale),
//         border: pw.Border.all(
//           color: primaryBlue,
//           width: 2,
//         ),
//       ),
//       child: pw.Stack(
//         children: [
//
//
//
// // White Cut
// // pw.Positioned(
// // top: -42,
// // right: -42,
// // child: pw.Container(
// // width: 150,
// // height: 150,
// // decoration: const pw.BoxDecoration(
// // color: PdfColors.white,
// // shape: pw.BoxShape.circle,
// // ),
// // ),
// // ),
//
//           pw.Padding(
//             padding: pw.EdgeInsets.all(16 * scale),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//
//                 pw.Image(
//                   logoImage,
//                   width: 95*scale,
//                   height: 40*scale,
//                   fit: pw.BoxFit.contain,
//                 ),
//
//                 pw.SizedBox(height: 8*scale),
//
//                 pw.Center(
//                   child: pw.Text(
//                     "DIGITAL ARR",
//                     style: pw.TextStyle(
//                       color: primaryBlue,
//                       fontSize: 20*scale,
//                       fontWeight: pw.FontWeight.bold,
//                     ),
//                   ),
//                 ),
//
//                 pw.Center(
//                   child: pw.Text(
//                     "ATTRIBUTE REPEATABILITY & REPRODUCIBILITY",
//                     textAlign: pw.TextAlign.center,
//                     style: pw.TextStyle(
//                       fontSize: 7*scale,
//                       color: darkGrey,
//                     ),
//                   ),
//                 ),
//
//                 pw.SizedBox(height: 8*scale),
//
//                 pw.Row(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//
//                     pw.Container(
//                       width: 78*scale,
//                       height: 96*scale,
//                       decoration: pw.BoxDecoration(
//                         borderRadius: pw.BorderRadius.circular(10),
//                         border: pw.Border.all(
//                           color: primaryBlue,
//                           width: 1.5*scale,
//                         ),
//                       ),
//                       child: candidateImage == null
//                           ? pw.Center(
//                         child: pw.Text(
//                           "PHOTO",
//                           style: const pw.TextStyle(
//                             fontSize: 9*scale,
//                           ),
//                         ),
//                       )
//                           : pw.ClipRRect(
//                         horizontalRadius: 8*scale,
//                         verticalRadius: 8*scale,
//                         child: pw.Image(
//                           candidateImage,
//                           fit: pw.BoxFit.cover,
//                         ),
//                       ),
//                     ),
//
//                     pw.SizedBox(width: 12*scale),
//
//                     pw.Expanded(
//                       child: pw.Column(
//                         children: [
//
//                           _infoTile(
//                             "NAME",
//                             isPreviousRecord
//                                 ? record!.appraisee
//                                 : AppData.appraiseeName,
//                           ),
//
//                           _infoTile(
//                             "EMPLOYEE",
//                             isPreviousRecord
//                                 ? record!.employeeCode
//                                 : AppData.employeeCode,
//                           ),
//
//                           _infoTile(
//                             "DEPARTMENT",
//                             isPreviousRecord
//                                 ? record!.department
//                                 : AppData.department,
//                           ),
//
//                           _infoTile(
//                             "PRODUCT",
//                             isPreviousRecord
//                                 ? record!.product
//                                 : AppData.productName,
//                           ),
//
//                           _infoTile(
//                             "BATCH",
//                             isPreviousRecord
//                                 ? record!.batchName
//                                 : AppData.selectedBatchName,
//                           ),
//
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 pw.Spacer(),
//
//                 pw.Center(
//                   child: pw.Text(
//                     "CLASSIFICATION",
//                     style: pw.TextStyle(
//                       color: gold,
//                       fontWeight: pw.FontWeight.bold,
//                       fontSize: 9*scale,
//                     ),
//                   ),
//                 ),
//
//                 pw.SizedBox(height: 5*scale),
//
//                 pw.Container(
//                   width: double.infinity,
//                   padding: const pw.EdgeInsets.symmetric(
//                     vertical: 10*scale,
//                   ),
//                   decoration: pw.BoxDecoration(
//                     color: primaryBlue,
//                     borderRadius: pw.BorderRadius.circular(8*scale),
//                   ),
//                   child: pw.Center(
//                     child: pw.Text(
//                       isPreviousRecord
//                           ? record!.result
//                           : AppData.finalClassification,
//                       style: pw.TextStyle(
//
//                         color: PdfColors.white,
//                         fontWeight: pw.FontWeight.bold,
//                         fontSize: 18*scale,
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 pw.SizedBox(height: 10*scale),
//
//                 pw.Align(
//                   alignment: pw.Alignment.centerRight,
//                   child: pw.Container(
//                     width: 52*scale,
//                     height: 52*scale,
//
// // decoration: pw.BoxDecoration(
// // color: gold,
// // shape: pw.BoxShape.circle,
// // ),
// // child: pw.Center(
// // child: pw.Text(
// // "QUALITY",
// // textAlign: pw.TextAlign.center,
// // style: pw.TextStyle(
// // color: PdfColors.white,
// // fontSize: 7*scale,
// // fontWeight: pw.FontWeight.bold,
// // ),
// // ),
// // ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
  static pw.Widget _buildFrontCard({
    required pw.MemoryImage logoImage,
    required pw.MemoryImage? candidateImage,
    required Map<String, dynamic> record,
    required String classification,
  }) {
    return pw.Container(
      width: cardWidth,
      height: cardHeight,

      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius:
        pw.BorderRadius.circular(
          18 * scale,
        ),
        border: pw.Border.all(
          color: primaryBlue,
          width: 2,
        ),
      ),

      child: pw.Stack(
        children: [

          pw.Padding(
            padding:
            pw.EdgeInsets.all(16 * scale),

            child: pw.Column(
              crossAxisAlignment:
              pw.CrossAxisAlignment.start,

              children: [

                pw.Image(
                  logoImage,
                  width: 95 * scale,
                  height: 40 * scale,
                  fit: pw.BoxFit.contain,
                ),

                pw.SizedBox(
                  height: 8 * scale,
                ),

                pw.Center(
                  child: pw.Text(
                    "DIGITAL ARR",
                    style: pw.TextStyle(
                      color: primaryBlue,
                      fontSize: 20 * scale,
                      fontWeight:
                      pw.FontWeight.bold,
                    ),
                  ),
                ),

                pw.Center(
                  child: pw.Text(
                    "ATTRIBUTE REPEATABILITY & REPRODUCIBILITY",
                    textAlign:
                    pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 7 * scale,
                      color: darkGrey,
                    ),
                  ),
                ),

                pw.SizedBox(
                  height: 8 * scale,
                ),

                pw.Row(
                  crossAxisAlignment:
                  pw.CrossAxisAlignment.start,

                  children: [

                    pw.Container(
                      width: 78 * scale,
                      height: 96 * scale,

                      decoration:
                      pw.BoxDecoration(
                        borderRadius:
                        pw.BorderRadius.circular(
                          10,
                        ),
                        border: pw.Border.all(
                          color: primaryBlue,
                          width: 1.5 * scale,
                        ),
                      ),

                      child:
                      candidateImage == null
                          ? pw.Center(
                        child: pw.Text(
                          "PHOTO",
                          style:
                          pw.TextStyle(
                            fontSize:
                            9 * scale,
                          ),
                        ),
                      )
                          : pw.ClipRRect(
                        horizontalRadius:
                        8 * scale,
                        verticalRadius:
                        8 * scale,
                        child: pw.Image(
                          candidateImage,
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                    ),

                    pw.SizedBox(
                      width: 12 * scale,
                    ),

                    pw.Expanded(
                      child: pw.Column(
                        children: [

                          _infoTile(
                            "NAME",
                            record["appraisee"]
                                ?.toString() ??
                                AppData.appraiseeName,
                          ),

                          _infoTile(
                            "EMPLOYEE",
                            record["employee_code_snap"]
                                ?.toString() ??
                                AppData.employeeCode,
                          ),

                          _infoTile(
                            "DEPARTMENT",
                            record["department"]
                                ?.toString() ??
                                AppData.department,
                          ),

                          _infoTile(
                            "PRODUCT",
                            record["product"]
                                ?.toString() ??
                                AppData.productName,
                          ),

                          _infoTile(
                            "BATCH",
                            record["batch_name_snap"]
                                ?.toString() ??
                                AppData.selectedBatchName,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.Spacer(),

                pw.Center(
                  child: pw.Text(
                    "CLASSIFICATION",
                    style: pw.TextStyle(
                      color: gold,
                      fontWeight:
                      pw.FontWeight.bold,
                      fontSize: 9 * scale,
                    ),
                  ),
                ),

                pw.SizedBox(
                  height: 5 * scale,
                ),

                pw.Container(
                  width: double.infinity,

                  padding:
                  const pw.EdgeInsets.symmetric(
                    vertical: 10 * scale,
                  ),

                  decoration:
                  pw.BoxDecoration(
                    color: primaryBlue,
                    borderRadius:
                    pw.BorderRadius.circular(
                      8 * scale,
                    ),
                  ),

                  child: pw.Center(
                    child: pw.Text(
                      classification,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight:
                        pw.FontWeight.bold,
                        fontSize: 18 * scale,
                      ),
                    ),
                  ),
                ),

                pw.SizedBox(
                  height: 10 * scale,
                ),

                pw.Align(
                  alignment:
                  pw.Alignment.centerRight,
                  child: pw.Container(
                    width: 52 * scale,
                    height: 52 * scale,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  static pw.Widget _buildBackCard({
    required Map<String, dynamic> record,
    required DateTime assessmentDate,
    required DateTime validTill,
    required String classification,
    required double falseAlert,
    required double missRate,
    required double effectiveness,
    required double kappa,
  }) {
    final certificateNo =
        record["certificate_number"]
            ?.toString() ??
            AppData.certificateNo;

    final employeeCode =
        record["employee_code_snap"]
            ?.toString() ??
            AppData.employeeCode;

    final appraisee =
        record["appraisee"]
            ?.toString() ??
            AppData.appraiseeName;

    final department =
        record["department"]
            ?.toString() ??
            AppData.department;

    final product =
        record["product"]
            ?.toString() ??
            AppData.productName;

    final batch =
        record["batch_name_snap"]
            ?.toString() ??
            AppData.selectedBatchName;

    return pw.Container(
      width: cardWidth,
      height: cardHeight,

      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius:
        pw.BorderRadius.circular(
          18 * scale,
        ),
        border: pw.Border.all(
          color: primaryBlue,
          width: 2 * scale,
        ),
      ),

      child: pw.Stack(
        children: [

          pw.Padding(
            padding:
            const pw.EdgeInsets.all(
              10 * scale,
            ),

            child: pw.Column(
              crossAxisAlignment:
              pw.CrossAxisAlignment.start,

              children: [

                pw.Center(
                  child: pw.Text(
                    "CERTIFICATE DETAILS",
                    style: pw.TextStyle(
                      fontWeight:
                      pw.FontWeight.bold,
                      fontSize: 16 * scale,
                      color: primaryBlue,
                    ),
                  ),
                ),

                pw.SizedBox(
                  height: 12 * scale,
                ),

                _detailRow(
                  "Certificate No",
                  certificateNo,
                ),

                _detailRow(
                  "Assessment Date",
                  _formatDate(
                    assessmentDate,
                  ),
                ),

                _detailRow(
                  "Valid Till",
                  _formatDate(
                    validTill,
                  ),
                ),

                pw.SizedBox(
                  height: 15 * scale,
                ),

                pw.Container(
                  width: double.infinity,

                  padding:
                  const pw.EdgeInsets.all(
                    8 * scale,
                  ),

                  decoration:
                  pw.BoxDecoration(
                    color: lightGrey,
                    borderRadius:
                    pw.BorderRadius.circular(
                      8 * scale,
                    ),
                  ),

                  child: pw.Column(
                    children: [

                      pw.Text(
                        "Evaluation Metrics",
                        style: pw.TextStyle(
                          fontWeight:
                          pw.FontWeight.bold,
                          color: primaryBlue,
                          fontSize: 11 * scale,
                        ),
                      ),

                      pw.SizedBox(
                        height: 8 * scale,
                      ),

                      _metricRow(
                        "False Alert (%)",
                        "${falseAlert.toStringAsFixed(2)} %",
                      ),

                      _metricRow(
                        "Miss Rate (%)",
                        "${missRate.toStringAsFixed(2)} %",
                      ),

                      _metricRow(
                        "Effectiveness",
                        "${effectiveness.toStringAsFixed(2)} %",
                      ),

                      _metricRow(
                        "Classification",
                        classification,
                      ),

                      _metricRow(
                        "Kappa",
                        "${kappa.toStringAsFixed(2)} %",
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                pw.Row(
                  mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,

                  children: [

                    pw.Column(
                      children: [

                        pw.Container(
                          width: 80 * scale,
                          height: 1 * scale,
                          color: PdfColors.black,
                        ),

                        pw.SizedBox(
                          height: 4 * scale,
                        ),

                        pw.Text(
                          "Authorized Signatory",
                          style:
                          pw.TextStyle(
                            fontSize: 8 * scale,
                          ),
                        ),
                      ],
                    ),

                    pw.BarcodeWidget(
                      barcode:
                      pw.Barcode.qrCode(),

                      data: '''
DIGITAL ARR CERTIFICATE

Certificate No : $certificateNo

Employee Code : $employeeCode

Candidate : $appraisee

Department : $department

Product : $product

Batch : $batch

Classification : $classification

False Alert : ${falseAlert.toStringAsFixed(2)}%

Miss Rate : ${missRate.toStringAsFixed(2)}%

Effectiveness : ${effectiveness.toStringAsFixed(2)}%

Kappa : ${kappa.toStringAsFixed(2)}%

Issue Date : ${_formatDate(assessmentDate)}

Valid Till : ${_formatDate(validTill)}
''',

                      width: 42 * scale,
                      height: 42 * scale,
                    ),
                  ],
                ),

                pw.SizedBox(
                  height: 10 * scale,
                ),

                pw.Center(
                  child: pw.Text(
                    "Scan QR to Verify Certificate",
                    style: pw.TextStyle(
                      fontSize: 8 * scale,
                      color: darkGrey,
                    ),
                  ),
                ),

                pw.SizedBox(
                  height: 8 * scale,
                ),

                pw.Center(
                  child: pw.Text(
                    "Pragati RRD PVT.LTD",
                    style: pw.TextStyle(
                      fontWeight:
                      pw.FontWeight.bold,
                      fontSize: 9 * scale,
                      color: primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  static pw.Widget _infoTile(
      String title,
      String value,
      ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6*scale),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [

          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 7*scale,
              color: darkGrey,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 6*scale,
              vertical: 4*scale,
            ),
            decoration: pw.BoxDecoration(
              color: lightGrey,
              borderRadius: pw.BorderRadius.circular(4*scale),
            ),
            child: pw.Text(
              value,
              style: const pw.TextStyle(
                fontSize: 9*scale,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _detailRow(
      String title,
      String value,
      ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6*scale),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [

          pw.SizedBox(
            width: 85*scale,
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9*scale,
                color: primaryBlue,
              ),
            ),
          ),

          pw.Text(
            ": ",
            style: const pw.TextStyle(fontSize: 9*scale),
          ),

          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(
                fontSize: 9*scale,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _metricRow(
      String metric,
      String value,
      ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        vertical: 2*scale,
      ),
      child: pw.Row(
        children: [

          pw.Expanded(
            child: pw.Text(
              metric,
              style: const pw.TextStyle(
                fontSize: 8*scale,
              ),
            ),
          ),

          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8*scale,
              fontWeight: pw.FontWeight.bold,
              color: primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
  static DateTime _parseAssessmentDate(
      dynamic value,
      ) {
    if (value is DateTime) {
      return value;
    }

    final text =
        value?.toString().trim() ?? "";

    if (text.isEmpty) {
      return DateTime.now();
    }

    final parsed =
    DateTime.tryParse(text);

    if (parsed != null) {
      return parsed;
    }

    // Supports dd/MM/yyyy if an old record
    // happens to contain that format.
    final parts = text.split('/');

    if (parts.length == 3) {
      final day =
      int.tryParse(parts[0]);

      final month =
      int.tryParse(parts[1]);

      final year =
      int.tryParse(parts[2]);

      if (day != null &&
          month != null &&
          year != null) {
        return DateTime(
          year,
          month,
          day,
        );
      }
    }

    return DateTime.now();
  }

  static String _formatDate(
      DateTime date,
      ) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  static double _toDouble(
      dynamic value,
      ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? "",
    ) ??
        0.0;
  }
}