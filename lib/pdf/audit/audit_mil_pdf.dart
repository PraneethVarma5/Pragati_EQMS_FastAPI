// // import 'dart:typed_data';
// //
// // import 'package:pdf/pdf.dart';
// // import 'package:pdf/widgets.dart' as pw;
// // import 'package:printing/printing.dart';
// //
// // import '../../models/audit/audit.dart';
// // import '../../models/audit/audit_finding.dart';
// //
// // /// Builds the Major Issue List (MIL) PDF for one audit and immediately
// // /// hands it to the platform share/print sheet (works for web download,
// // /// desktop save, and mobile share — via the `printing` package).
// // ///
// // /// Written independently of the sample MIL PDF code supplied by the user.
// // class AuditMilPdf {
// //   AuditMilPdf._();
// //
// //   static final _accent = PdfColor.fromInt(0xFF6C4FD1);
// //
// //   static Future<Uint8List> _build({
// //     required Audit audit,
// //     required List<AuditFinding> findings,
// //     required String milNumber,
// //   }) async {
// //     final doc = pw.Document();
// //
// //     doc.addPage(
// //       pw.MultiPage(
// //         pageFormat: PdfPageFormat.a4.landscape,
// //         margin: const pw.EdgeInsets.all(24),
// //         header: (context) => pw.Column(
// //           crossAxisAlignment: pw.CrossAxisAlignment.start,
// //           children: [
// //             pw.Row(
// //               mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
// //               children: [
// //                 pw.Text(
// //                   'Major Issue List',
// //                   style: pw.TextStyle(
// //                     fontSize: 20,
// //                     fontWeight: pw.FontWeight.bold,
// //                     color: _accent,
// //                   ),
// //                 ),
// //                 pw.Text('MIL Number: $milNumber',
// //                     style: const pw.TextStyle(fontSize: 11)),
// //               ],
// //             ),
// //             pw.SizedBox(height: 4),
// //             pw.Text(
// //               '${audit.auditType} • ${audit.vendor} • ${_fmtDate(audit.auditDate)}',
// //               style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
// //             ),
// //             pw.SizedBox(height: 12),
// //           ],
// //         ),
// //         build: (context) {
// //           if (findings.isEmpty) {
// //             return [
// //               pw.Padding(
// //                 padding: const pw.EdgeInsets.symmetric(vertical: 40),
// //                 child: pw.Center(
// //                   child: pw.Text('No findings recorded for this audit.'),
// //                 ),
// //               ),
// //             ];
// //           }
// //
// //           return [
// //             pw.TableHelper.fromTextArray(
// //               border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
// //               headerDecoration: pw.BoxDecoration(color: _accent),
// //               headerStyle: pw.TextStyle(
// //                 color: PdfColors.white,
// //                 fontWeight: pw.FontWeight.bold,
// //                 fontSize: 8,
// //               ),
// //               cellStyle: const pw.TextStyle(fontSize: 8),
// //               cellPadding: const pw.EdgeInsets.all(5),
// //               headers: const [
// //                 'No.',
// //                 'Section',
// //                 'Finding',
// //                 'Severity',
// //                 'Root Cause',
// //                 'Corrective Action',
// //                 'DRI',
// //                 'Mail ID',
// //                 'Deadline',
// //                 'Status',
// //               ],
// //               data: findings.asMap().entries.map((entry) {
// //                 final i = entry.key;
// //                 final f = entry.value;
// //                 return [
// //                   '${i + 1}',
// //                   f.section,
// //                   f.issue.isNotEmpty ? f.issue : f.question,
// //                   f.category?.value ?? '-',
// //                   f.rootCause,
// //                   f.correctiveAction,
// //                   f.driName,
// //                   f.mailId,
// //                   f.deadline != null ? _fmtDate(f.deadline!) : '-',
// //                   f.overallStatus,
// //                 ];
// //               }).toList(),
// //             ),
// //           ];
// //         },
// //       ),
// //     );
// //
// //     return doc.save();
// //   }
// //
// //   static Future<void> generate({
// //     required Audit audit,
// //     required List<AuditFinding> findings,
// //     required String milNumber,
// //   }) async {
// //     final bytes = await _build(
// //       audit: audit,
// //       findings: findings,
// //       milNumber: milNumber,
// //     );
// //     await Printing.sharePdf(
// //       bytes: bytes,
// //       filename: 'MIL_${milNumber}.pdf',
// //     );
// //   }
// //
// //   static String _fmtDate(DateTime date) =>
// //       '${date.day.toString().padLeft(2, '0')}/'
// //       '${date.month.toString().padLeft(2, '0')}/'
// //       '${date.year}';
// // }
//
//
// import 'dart:typed_data';
//
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
//
// import '../../models/audit/audit.dart';
// import '../../models/audit/audit_finding.dart';
//
// /// Builds the Major Issue List (MIL) PDF for one audit.
// ///
// /// PDF columns:
// /// SNo | Issue | Finding category | Root cause | Corrective action
// /// | DRI Name | Mail ID | Deadline | Overall Status
// class AuditMilPdf {
//   AuditMilPdf._();
//
//   static final _accent =
//   PdfColor.fromInt(0xFF6C4FD1);
//
//   static Future<Uint8List> _build({
//     required Audit audit,
//     required List<AuditFinding> findings,
//     required String milNumber,
//   }) async {
//     final doc = pw.Document();
//
//     doc.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a3.landscape,
//         margin: const pw.EdgeInsets.all(24),
//
//         header: (context) => pw.Column(
//           crossAxisAlignment:
//           pw.CrossAxisAlignment.start,
//           children: [
//             pw.Row(
//               mainAxisAlignment:
//               pw.MainAxisAlignment.spaceBetween,
//               children: [
//                 pw.Text(
//                   'Major Issue List',
//                   style: pw.TextStyle(
//                     fontSize: 20,
//                     fontWeight:
//                     pw.FontWeight.bold,
//                     color: _accent,
//                   ),
//                 ),
//
//                 pw.Text(
//                   'MIL Number: $milNumber',
//                   style: const pw.TextStyle(
//                     fontSize: 11,
//                   ),
//                 ),
//               ],
//             ),
//
//             pw.SizedBox(height: 4),
//
//             pw.Text(
//               '${audit.auditType} • '
//                   '${audit.vendor} • '
//                   '${_fmtDate(audit.auditDate)}',
//               style: pw.TextStyle(
//                 fontSize: 10,
//                 color: PdfColors.grey700,
//               ),
//             ),
//
//             pw.SizedBox(height: 12),
//           ],
//         ),
//
//         build: (context) {
//           if (findings.isEmpty) {
//             return [
//               pw.Padding(
//                 padding:
//                 const pw.EdgeInsets.symmetric(
//                   vertical: 40,
//                 ),
//                 child: pw.Center(
//                   child: pw.Text(
//                     'No findings recorded for this audit.',
//                   ),
//                 ),
//               ),
//             ];
//           }
//
//           return [
//             pw.TableHelper.fromTextArray(
//               border: pw.TableBorder.all(
//                 color: PdfColors.grey400,
//                 width: 0.5,
//               ),
//
//               headerDecoration:
//               pw.BoxDecoration(
//                 color: _accent,
//               ),
//
//               headerStyle: pw.TextStyle(
//                 color: PdfColors.white,
//                 fontWeight:
//                 pw.FontWeight.bold,
//                 fontSize: 8,
//               ),
//
//               cellStyle:
//               const pw.TextStyle(
//                 fontSize: 8,
//               ),
//
//               cellPadding:
//               const pw.EdgeInsets.all(5),
//
//               columnWidths: const {
//                 0: pw.FixedColumnWidth(35),
//                 1: pw.FlexColumnWidth(1.8),
//                 2: pw.FlexColumnWidth(1.1),
//                 3: pw.FlexColumnWidth(1.8),
//                 4: pw.FlexColumnWidth(1.8),
//                 5: pw.FlexColumnWidth(1.2),
//                 6: pw.FlexColumnWidth(1.5),
//                 7: pw.FlexColumnWidth(1.0),
//                 8: pw.FlexColumnWidth(1.1),
//               },
//
//               headers: const [
//                 'SNo',
//                 'Issue',
//                 'Finding category',
//                 'Root cause',
//                 'Corrective action',
//                 'DRI Name',
//                 'Mail ID',
//                 'Deadline',
//                 'Overall Status',
//               ],
//
//               data: findings
//                   .asMap()
//                   .entries
//                   .map(
//                     (entry) {
//                   final index =
//                       entry.key;
//
//                   final finding =
//                       entry.value;
//
//                   return [
//                     '${index + 1}',
//
//                     finding.issue.isNotEmpty
//                         ? finding.issue
//                         : finding.question,
//
//                     finding.category?.value ??
//                         '-',
//
//                     finding.rootCause
//                         .isNotEmpty
//                         ? finding.rootCause
//                         : '-',
//
//                     finding.correctiveAction
//                         .isNotEmpty
//                         ? finding
//                         .correctiveAction
//                         : '-',
//
//                     finding.driName
//                         .isNotEmpty
//                         ? finding.driName
//                         : '-',
//
//                     finding.mailId
//                         .isNotEmpty
//                         ? finding.mailId
//                         : '-',
//
//                     finding.deadline != null
//                         ? _fmtDate(
//                       finding.deadline!,
//                     )
//                         : '-',
//
//                     finding.overallStatus
//                         .isNotEmpty
//                         ? finding.overallStatus
//                         : '-',
//                   ];
//                 },
//               ).toList(),
//             ),
//           ];
//         },
//       ),
//     );
//
//     return doc.save();
//   }
//
//   static Future<void> generate({
//     required Audit audit,
//     required List<AuditFinding> findings,
//     required String milNumber,
//   }) async {
//     final bytes = await _build(
//       audit: audit,
//       findings: findings,
//       milNumber: milNumber,
//     );
//
//     await Printing.sharePdf(
//       bytes: bytes,
//       filename: 'MIL_$milNumber.pdf',
//     );
//   }
//
//   static String _fmtDate(
//       DateTime date,
//       ) =>
//       '${date.day.toString().padLeft(2, '0')}/'
//           '${date.month.toString().padLeft(2, '0')}/'
//           '${date.year}';
// }

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/audit/audit.dart';
import '../../models/audit/audit_finding.dart';

/// Generates the Major Issue List (MIL) PDF.
///
/// Columns:
/// SNo | Issue | Finding category | Root cause | Corrective action
/// | DRI Name | Mail ID | Deadline | Overall Status
class AuditMilPdf {
  AuditMilPdf._();

  static final PdfColor _accent =
  PdfColor.fromInt(0xFF6C4FD1);

  // ============================================================
  // BUILD PDF
  // ============================================================

  static Future<Uint8List> _build({
    required Audit audit,
    required List<AuditFinding> findings,
    required String milNumber,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a3.landscape,
        margin: const pw.EdgeInsets.fromLTRB(
          28,
          24,
          28,
          24,
        ),

        // Repeat a small header on every page.
        header: (context) {
          return pw.Column(
            crossAxisAlignment:
            pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment:
                pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment:
                pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'MIL REPORT',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight:
                      pw.FontWeight.bold,
                      color: _accent,
                    ),
                  ),
                  pw.Text(
                    'MIL Number: $milNumber',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight:
                      pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 8),

              pw.Text(
                '${audit.auditType}  |  '
                    '${audit.vendor}  |  '
                    '${_fmtDate(audit.auditDate)}',
                style: pw.TextStyle(
                  fontSize: 9,
                  color:
                  PdfColors.grey700,
                ),
              ),

              pw.SizedBox(height: 10),
            ],
          );
        },

        build: (context) {
          final widgets =
          <pw.Widget>[];

          // ======================================================
          // AUDIT INFORMATION
          // ======================================================

          widgets.add(
            _buildAuditInfoTable(
              audit: audit,
              milNumber: milNumber,
            ),
          );

          widgets.add(
            pw.SizedBox(height: 18),
          );

          // ======================================================
          // MIL FINDINGS TITLE
          // ======================================================

          widgets.add(
            pw.Text(
              'MIL FINDINGS',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight:
                pw.FontWeight.bold,
              ),
            ),
          );

          widgets.add(
            pw.SizedBox(height: 7),
          );

          // ======================================================
          // NO FINDINGS
          // ======================================================

          if (findings.isEmpty) {
            widgets.add(
              pw.Container(
                width: double.infinity,
                padding:
                const pw.EdgeInsets.all(
                  12,
                ),
                decoration:
                pw.BoxDecoration(
                  border:
                  pw.Border.all(
                    color:
                    PdfColors.grey400,
                    width: 0.5,
                  ),
                ),
                child: pw.Text(
                  'No findings recorded for this audit.',
                  style:
                  const pw.TextStyle(
                    fontSize: 9,
                  ),
                ),
              ),
            );

            return widgets;
          }

          // ======================================================
          // FINDINGS TABLE
          // ======================================================

          // ======================================================
// FINDINGS TABLE
// ======================================================

          widgets.add(
            pw.TableHelper.fromTextArray(
              headers: const [
                'SNo',
                'Question',
                'Description',
                'Defect Type',
                'Root Cause',
                'Corrective Action',
                'DRI Name',
                'Mail ID',
                'Deadline',
                'Status',
              ],

              data: findings
                  .asMap()
                  .entries
                  .map(
                    (entry) {
                  final index = entry.key;
                  final finding = entry.value;

                  return [
                    '${index + 1}',

                    // Question
                    _valueOrFallback(
                      finding.question,
                      finding.issue,
                    ),

                    // Description
                    _value(
                      finding.issue,
                    ),

                    // Defect Type
                    finding.category?.value ?? '-',

                    // Root Cause
                    _value(
                      finding.rootCause,
                    ),

                    // Corrective Action
                    _value(
                      finding.correctiveAction,
                    ),

                    // DRI Name
                    _value(
                      finding.driName,
                    ),

                    // Mail ID
                    _value(
                      finding.mailId,
                    ),

                    // Deadline
                    finding.deadline != null
                        ? _fmtDate(
                      finding.deadline!,
                    )
                        : '-',

                    // Status
                    _value(
                      finding.overallStatus,
                    ),
                  ];
                },
              )
                  .toList(),

              border: pw.TableBorder.all(
                color: PdfColors.grey500,
                width: 0.5,
              ),

              headerDecoration: pw.BoxDecoration(
                color: _accent,
              ),

              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
              ),

              cellStyle: const pw.TextStyle(
                fontSize: 6.5,
              ),

              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 3,
              ),

              cellAlignment: pw.Alignment.topLeft,

              headerAlignment: pw.Alignment.center,

              columnWidths: const {
                // SNo
                0: pw.FixedColumnWidth(28),

                // Question
                1: pw.FlexColumnWidth(2.4),

                // Description
                2: pw.FlexColumnWidth(1.8),

                // Defect Type
                3: pw.FlexColumnWidth(0.9),

                // Root Cause
                4: pw.FlexColumnWidth(1.7),

                // Corrective Action
                5: pw.FlexColumnWidth(1.8),

                // DRI Name
                6: pw.FlexColumnWidth(1.1),

                // Mail ID
                7: pw.FlexColumnWidth(1.5),

                // Deadline
                8: pw.FlexColumnWidth(0.9),

                // Status
                9: pw.FlexColumnWidth(0.9),
              },
            ),
          );
          return widgets;
        },
      ),
    );

    return doc.save();
  }

  // ============================================================
  // AUDIT INFORMATION TABLE
  // ============================================================

  static pw.Widget _buildAuditInfoTable({
    required Audit audit,
    required String milNumber,
  }) {
    return pw.Table(
      border:
      pw.TableBorder.all(
        color: PdfColors.grey500,
        width: 0.5,
      ),

      columnWidths: const {
        0: pw.FlexColumnWidth(1.0),
        1: pw.FlexColumnWidth(2.0),
        2: pw.FlexColumnWidth(1.0),
        3: pw.FlexColumnWidth(2.0),
      },

      children: [
        _infoRow(
          'MIL Number',
          milNumber,
          'Audit Type',
          _value(
            audit.auditType,
          ),
        ),

        _infoRow(
          'Audit Date',
          _fmtDate(
            audit.auditDate,
          ),
          'Vendor',
          _value(
            audit.vendor,
          ),
        ),

        _infoRow(
          'Site',
          _value(
            audit.site,
          ),
          'Auditor',
          _value(
            audit.auditorName,
          ),
        ),

        _infoRow(
          'Status',
          _value(
            audit.status,
          ),
          '',
          '',
        ),
      ],    );
  }

  static pw.TableRow _infoRow(
      String label1,
      String value1,
      String label2,
      String value2,
      ) {
    return pw.TableRow(
      children: [
        _infoCell(
          label1,
          bold: true,
        ),
        _infoCell(
          value1,
        ),
        _infoCell(
          label2,
          bold: true,
        ),
        _infoCell(
          value2,
        ),
      ],
    );
  }

  static pw.Widget _infoCell(
      String value, {
        bool bold = false,
      }) {
    return pw.Padding(
      padding:
      const pw.EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 5,
      ),
      child: pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // ============================================================
  // VALUE HELPERS
  // ============================================================

  static String _value(
      String? value,
      ) {
    if (value == null) {
      return '-';
    }

    final trimmed =
    value.trim();

    if (trimmed.isEmpty) {
      return '-';
    }

    return trimmed;
  }

  static String _valueOrFallback(
      String? primary,
      String? fallback,
      ) {
    final first =
    primary?.trim();

    if (first != null &&
        first.isNotEmpty) {
      return first;
    }

    final second =
    fallback?.trim();

    if (second != null &&
        second.isNotEmpty) {
      return second;
    }

    return '-';
  }

  // ============================================================
  // DATE
  // ============================================================

  static String _fmtDate(
      DateTime date,
      ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // GENERATE
  // ============================================================

  static Future<void> generate({
    required Audit audit,
    required List<AuditFinding> findings,
    required String milNumber,
  }) async {
    final bytes =
    await _build(
      audit: audit,
      findings: findings,
      milNumber: milNumber,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename:
      'MIL_$milNumber.pdf',
    );
  }
}