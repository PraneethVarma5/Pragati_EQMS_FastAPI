import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'supabase_service.dart';

class AuditPdfService {
  static String _text(
      dynamic value, {
        String fallback = '-',
      }) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    return text.isEmpty ? fallback : text;
  }

  static String _date(dynamic value) {
    final text = _text(value);

    if (text == '-') {
      return '-';
    }

    if (text.length >= 10) {
      return text.substring(0, 10);
    }

    return text;
  }

  static double _number(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  static String _hours(dynamic value) {
    return _number(value).toStringAsFixed(2);
  }

  static String _safeFilePart(
      String value,
      ) {
    return value
        .replaceAll(
      RegExp(r'[^A-Za-z0-9_-]+'),
      '_',
    )
        .replaceAll(
      RegExp(r'_+'),
      '_',
    )
        .replaceAll(
      RegExp(r'^_|_$'),
      '',
    );
  }

  static pw.Widget _title(
      String text,
      ) {
    return pw.Center(
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight:
          pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _summaryTable(
      List<List<String>> rows,
      ) {
    return pw.Table(
      border:
      pw.TableBorder.all(
        color:
        PdfColors.grey600,
        width: 0.7,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1.5),
      },
      children: rows.map(
            (row) {
          return pw.TableRow(
            children: [
              pw.Container(
                padding:
                const pw.EdgeInsets.all(
                  6,
                ),
                child: pw.Text(
                  row[0],
                  style:
                  pw.TextStyle(
                    fontWeight:
                    pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Container(
                padding:
                const pw.EdgeInsets.all(
                  6,
                ),
                child:
                pw.Text(row[1]),
              ),
            ],
          );
        },
      ).toList(),
    );
  }

  static pw.Widget _sectionTitle(
      String text,
      ) {
    return pw.Container(
      width: double.infinity,
      padding:
      const pw.EdgeInsets.symmetric(
        vertical: 7,
        horizontal: 8,
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight:
          pw.FontWeight.bold,
        ),
      ),
    );
  }

  static Future<Uint8List>
  _buildAuditReportPdf(
      String auditId,
      ) async {
    final data =
    await SupabaseService
        .getAuditReport(
      auditId,
    );

    final audit =
    Map<String, dynamic>.from(
      data['audit'] ?? {},
    );

    final answers =
    List<Map<String, dynamic>>.from(
      data['answers'] ?? [],
    );

    final findings =
    answers.where(
          (item) =>
      item['answer']?.toString() ==
          'No',
    ).toList();

    final critical =
        findings.where(
              (item) =>
          item['defect_type']?.toString() ==
              'Critical',
        ).length;

    final major =
        findings.where(
              (item) =>
          item['defect_type']?.toString() ==
              'Major',
        ).length;

    final minor =
        findings.where(
              (item) =>
          item['defect_type']?.toString() ==
              'Minor',
        ).length;

    final totalHours =
    _number(
      audit['total_audit_hours'],
    );

    final cph = totalHours > 0
        ? findings.length /
        totalHours
        : 0;

    final auditType =
    audit['audit_types'];

    String auditTypeName = '';

    if (auditType is Map) {
      auditTypeName =
          _text(
            auditType['audit_type'],
          );
    }

    final pdf =
    pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat:
        PdfPageFormat.a4,
        margin:
        const pw.EdgeInsets.all(
          28,
        ),
        build: (context) {
          return [
            _title(
              'AUDIT SUMMARY',
            ),
            pw.SizedBox(
              height: 18,
            ),
            _summaryTable(
              [
                [
                  'MIL Number',
                  _text(
                    audit['mil_number'],
                  ),
                ],
                [
                  'Audit Type',
                  auditTypeName,
                ],
                [
                  'Audit Date',
                  _date(
                    audit['audit_date'],
                  ),
                ],
                [
                  'Vendor',
                  _text(
                    audit['vendor'],
                  ),
                ],
                [
                  'Site',
                  _text(
                    audit['site'],
                  ),
                ],
                [
                  'LOB',
                  _text(
                    audit['lob'],
                  ),
                ],
                [
                  'Program',
                  _text(
                    audit['program'],
                  ),
                ],
                [
                  'Line',
                  _text(
                    audit['line'],
                  ),
                ],
                [
                  'APN',
                  _text(
                    audit['apn'],
                  ),
                ],
                [
                  'Auditor',
                  _text(
                    audit['auditor_name'],
                  ),
                ],
                [
                  'Auditor Email',
                  _text(
                    audit['auditor_email'],
                  ),
                ],
                [
                  'Total Audit Hours',
                  _hours(
                    audit[
                    'total_audit_hours'],
                  ),
                ],
                [
                  'Audit Status',
                  _text(
                    audit['status'],
                  ),
                ],
                [
                  'MIL Status',
                  _text(
                    audit['mil_status'],
                  ),
                ],
              ],
            ),
            pw.SizedBox(
              height: 22,
            ),
            _sectionTitle(
              'FINDINGS',
            ),
            pw.SizedBox(
              height: 8,
            ),
            findings.isEmpty
                ? pw.Container(
              padding:
              const pw.EdgeInsets
                  .all(12),
              child: pw.Text(
                'No findings.',
              ),
            )
                : pw.TableHelper
                .fromTextArray(
              border:
              pw.TableBorder.all(
                color:
                PdfColors.grey600,
                width: 0.5,
              ),
              headerStyle:
              pw.TextStyle(
                fontWeight:
                pw.FontWeight.bold,
                fontSize: 8,
              ),
              cellStyle:
              const pw.TextStyle(
                fontSize: 8,
              ),
              cellPadding:
              const pw.EdgeInsets.all(
                5,
              ),
              headers: const [
                'No.',
                'Question',
                'Description',
                'Defect Type',
              ],
              data: List.generate(
                findings.length,
                    (index) {
                  final item =
                  findings[index];

                  return [
                    '${index + 1}',
                    _text(
                      item['question'],
                    ),
                    _text(
                      item['description'],
                    ),
                    _text(
                      item['defect_type'],
                    ),
                  ];
                },
              ),
            ),
            pw.SizedBox(
              height: 18,
            ),
            pw.TableHelper
                .fromTextArray(
              border:
              pw.TableBorder.all(
                color:
                PdfColors.grey600,
                width: 0.5,
              ),
              headerStyle:
              pw.TextStyle(
                fontWeight:
                pw.FontWeight.bold,
                fontSize: 9,
              ),
              cellStyle:
              const pw.TextStyle(
                fontSize: 9,
              ),
              headers: const [
                'Critical',
                'Major',
                'Minor',
                'CPH',
              ],
              data: [
                [
                  '$critical',
                  '$major',
                  '$minor',
                  cph.toStringAsFixed(2),
                ],
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<void>
  downloadAuditReport(
      String auditId,
      ) async {
    final data =
    await SupabaseService
        .getAuditReport(
      auditId,
    );

    final audit =
    Map<String, dynamic>.from(
      data['audit'] ?? {},
    );

    final bytes =
    await _buildAuditReportPdf(
      auditId,
    );

    final mil =
    _safeFilePart(
      _text(
        audit['mil_number'],
        fallback: auditId,
      ),
    );

    await FileSaver.instance.saveFile(
      name:
      'Audit_Report_$mil',
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  static Future<Uint8List>
  _buildMilReportPdf(
      String auditId,
      ) async {
    final report =
    await SupabaseService
        .getAuditReport(
      auditId,
    );

    final audit =
    Map<String, dynamic>.from(
      report['audit'] ?? {},
    );

    final milItems =
    await SupabaseService
        .getAuditMilItems(
      auditId,
    );

    final auditType =
    audit['audit_types'];

    String auditTypeName = '';

    if (auditType is Map) {
      auditTypeName =
          _text(
            auditType['audit_type'],
          );
    }

    final pdf =
    pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat:
        PdfPageFormat.a4,
        margin:
        const pw.EdgeInsets.all(
          28,
        ),
        build: (context) {
          return [
            _title(
              'MIL REPORT',
            ),
            pw.SizedBox(
              height: 18,
            ),
            _summaryTable(
              [
                [
                  'MIL Number',
                  _text(
                    audit['mil_number'],
                  ),
                ],
                [
                  'Audit Type',
                  auditTypeName,
                ],
                [
                  'Audit Date',
                  _date(
                    audit['audit_date'],
                  ),
                ],
                [
                  'Vendor',
                  _text(
                    audit['vendor'],
                  ),
                ],
                [
                  'Site',
                  _text(
                    audit['site'],
                  ),
                ],
                [
                  'Auditor',
                  _text(
                    audit['auditor_name'],
                  ),
                ],
                [
                  'MIL Status',
                  _text(
                    audit['mil_status'],
                  ),
                ],
              ],
            ),
            pw.SizedBox(
              height: 20,
            ),
            _sectionTitle(
              'MIL FINDINGS',
            ),
            pw.SizedBox(
              height: 8,
            ),
            if (milItems.isEmpty)
              pw.Text(
                'No MIL items.',
              )
            else
              ...milItems.map(
                    (item) {
                  return pw.Container(
                    margin:
                    const pw.EdgeInsets
                        .only(
                      bottom: 14,
                    ),
                    padding:
                    const pw.EdgeInsets
                        .all(
                      10,
                    ),
                    decoration:
                    pw.BoxDecoration(
                      border:
                      pw.Border.all(
                        color:
                        PdfColors.grey600,
                        width: 0.6,
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment:
                      pw.CrossAxisAlignment
                          .start,
                      children: [
                        pw.Text(
                          'Question',
                          style:
                          pw.TextStyle(
                            fontWeight:
                            pw.FontWeight
                                .bold,
                          ),
                        ),
                        pw.SizedBox(
                          height: 3,
                        ),
                        pw.Text(
                          _text(
                            item['question'],
                          ),
                        ),
                        pw.SizedBox(
                          height: 8,
                        ),
                        pw.Text(
                          'Description',
                          style:
                          pw.TextStyle(
                            fontWeight:
                            pw.FontWeight
                                .bold,
                          ),
                        ),
                        pw.Text(
                          _text(
                            item['description'],
                          ),
                        ),
                        pw.SizedBox(
                          height: 8,
                        ),
                        pw.Text(
                          'Defect Type: ${_text(item['defect_type'])}',
                        ),
                        pw.SizedBox(
                          height: 8,
                        ),
                        pw.Text(
                          'Root Cause',
                          style:
                          pw.TextStyle(
                            fontWeight:
                            pw.FontWeight
                                .bold,
                          ),
                        ),
                        pw.Text(
                          _text(
                            item['root_cause'],
                          ),
                        ),
                        pw.SizedBox(
                          height: 6,
                        ),
                        pw.Text(
                          'Corrective Action',
                          style:
                          pw.TextStyle(
                            fontWeight:
                            pw.FontWeight
                                .bold,
                          ),
                        ),
                        pw.Text(
                          _text(
                            item[
                            'corrective_action'],
                          ),
                        ),
                        pw.SizedBox(
                          height: 6,
                        ),
                        pw.Text(
                          'DRI Name: ${_text(item['dri_name'])}',
                        ),
                        pw.Text(
                          'DRI Mail: ${_text(item['dri_mail'])}',
                        ),
                        pw.Text(
                          'Deadline: ${_date(item['deadline'])}',
                        ),
                        pw.Text(
                          'Overall Status: ${_text(item['overall_status'])}',
                        ),
                      ],
                    ),
                  );
                },
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<void>
  downloadMilReport(
      String auditId,
      ) async {
    final report =
    await SupabaseService
        .getAuditReport(
      auditId,
    );

    final audit =
    Map<String, dynamic>.from(
      report['audit'] ?? {},
    );

    final bytes =
    await _buildMilReportPdf(
      auditId,
    );

    final mil =
    _safeFilePart(
      _text(
        audit['mil_number'],
        fallback: auditId,
      ),
    );

    await FileSaver.instance.saveFile(
      name:
      'MIL_Report_$mil',
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  static Future<Uint8List>
  _buildAuditListPdf(
      List<Map<String, dynamic>> audits,
      ) async {
    final pdf =
    pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat:
        PdfPageFormat.a4.landscape,
        margin:
        const pw.EdgeInsets.all(
          24,
        ),
        build: (context) {
          return [
            _title(
              'AUDIT LIST',
            ),
            pw.SizedBox(
              height: 18,
            ),
            pw.TableHelper
                .fromTextArray(
              border:
              pw.TableBorder.all(
                color:
                PdfColors.grey600,
                width: 0.5,
              ),
              headerStyle:
              pw.TextStyle(
                fontWeight:
                pw.FontWeight.bold,
                fontSize: 7,
              ),
              cellStyle:
              const pw.TextStyle(
                fontSize: 7,
              ),
              cellPadding:
              const pw.EdgeInsets.all(
                4,
              ),
              headers: const [
                'Audit Type',
                'Date',
                'Vendor',
                'Site',
                'LOB',
                'Auditor',
                'Status',
                'MIL Status',
              ],
              data: audits.map(
                    (audit) {
                  return [
                    _text(
                      audit['audit_type'],
                    ),
                    _date(
                      audit['audit_date'],
                    ),
                    _text(
                      audit['vendor'],
                    ),
                    _text(
                      audit['site'],
                    ),
                    _text(
                      audit['lob'],
                    ),
                    _text(
                      audit['auditor_name'],
                    ),
                    _text(
                      audit['status'],
                    ),
                    _text(
                      audit['mil_status'],
                    ),
                  ];
                },
              ).toList(),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<void>
  downloadAuditList() async {
    final audits =
    await SupabaseService
        .getAllAudits();

    final bytes =
    await _buildAuditListPdf(
      audits,
    );

    await FileSaver.instance.saveFile(
      name: 'Audit_List',
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }
}