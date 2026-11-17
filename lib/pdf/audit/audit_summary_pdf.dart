import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/audit/audit.dart';
import '../../models/audit/audit_finding.dart';
import '../../services/audit/audit_calculation_service.dart';

/// Builds the Audit Summary PDFs (single-audit and all-completed-audits
/// variants) and hands them to the platform share/print sheet.
///
/// Written independently of the sample summary PDF code supplied by the
/// user — same purpose, fresh implementation.
class AuditSummaryPdf {
  AuditSummaryPdf._();

  static final _accent = PdfColor.fromInt(0xFF6C4FD1);

  // ============================================================
  // Single audit
  // ============================================================

  static Future<Uint8List> _buildSingle({
    required Audit audit,
    required List<AuditFinding> findings,
    required String milNumber,
  }) async {
    final doc = pw.Document();

    final critical = AuditCalculationService.criticalCount(findings);
    final major = AuditCalculationService.majorCount(findings);
    final minor = AuditCalculationService.minorCount(findings);
    final cph = AuditCalculationService.cph(audit: audit, findings: findings);
    final scoreApplicable =
        AuditCalculationService.isScoreApplicable(audit.auditType);
    final score = scoreApplicable
        ? AuditCalculationService.auditScore(audit: audit, findings: findings)
        : null;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Text('Audit Summary',
              style: pw.TextStyle(
                  fontSize: 22, fontWeight: pw.FontWeight.bold, color: _accent)),
          pw.SizedBox(height: 16),
          _infoTable({
            'MIL Number': milNumber,
            'Audit Type': audit.auditType,
            'Audit Date': _fmtDate(audit.auditDate),
            'Vendor': audit.vendor,
            'Site': audit.site ?? '-',
            'LOB': audit.lob ?? '-',
            'Program': audit.program ?? '-',
            'Line': audit.line ?? '-',
            'APN': audit.apn ?? '-',
            'Auditor': audit.auditorName ?? '-',
            'Status': audit.status,
            'Total Audited Hours': audit.totalTimeTakenHours.toStringAsFixed(2),
            'Critical Findings': '$critical',
            'Major Findings': '$major',
            'Minor Findings': '$minor',
            'CPH': cph.toStringAsFixed(2),
            if (scoreApplicable) 'Audit Score': score!.toStringAsFixed(2),
          }),
          pw.SizedBox(height: 24),
          pw.Text('Findings',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (findings.isEmpty)
            pw.Text('No findings recorded.')
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              headerDecoration: pw.BoxDecoration(color: _accent),
              headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headers: const ['No.', 'Section', 'Question', 'Severity', 'Status'],
              data: findings.asMap().entries.map((e) {
                final f = e.value;
                return [
                  '${e.key + 1}',
                  f.section,
                  f.question,
                  f.category?.value ?? '-',
                  f.overallStatus,
                ];
              }).toList(),
            ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<void> generate({
    required Audit audit,
    required List<AuditFinding> findings,
    required String milNumber,
  }) async {
    final bytes = await _buildSingle(
      audit: audit,
      findings: findings,
      milNumber: milNumber,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Audit_Summary_${milNumber}.pdf',
    );
  }

  // ============================================================
  // All completed audits
  // ============================================================

  static Future<Uint8List> _buildAll({
    required List<Audit> audits,
    required Map<String, List<AuditFinding>> findingsByAudit,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(22),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('Audit Summary — Completed Audits',
                style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: _accent)),
            pw.SizedBox(height: 12),
          ],
        ),
        build: (context) {
          if (audits.isEmpty) {
            return [pw.Center(child: pw.Text('No completed audits found.'))];
          }

          return [
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              headerDecoration: pw.BoxDecoration(color: _accent),
              headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              cellPadding: const pw.EdgeInsets.all(4),
              headers: const [
                'MIL',
                'Type',
                'Date',
                'Vendor',
                'Site',
                'Auditor',
                'Hours',
                'Critical',
                'Major',
                'Minor',
                'CPH',
                'Score',
                'MIL Status',
              ],
              data: audits.map((audit) {
                final findings = findingsByAudit[audit.auditId] ?? [];
                final critical =
                    AuditCalculationService.criticalCount(findings);
                final major = AuditCalculationService.majorCount(findings);
                final minor = AuditCalculationService.minorCount(findings);
                final cph = AuditCalculationService.cph(
                    audit: audit, findings: findings);
                final scoreApplicable =
                    AuditCalculationService.isScoreApplicable(audit.auditType);
                final score = scoreApplicable
                    ? AuditCalculationService.auditScore(
                            audit: audit, findings: findings)
                        .toStringAsFixed(2)
                    : '-';
                final milStatus = AuditCalculationService.milStatusLabel(
                  milNumber: audit.milNumber,
                  findings: findings,
                );

                return [
                  audit.milNumber ?? '-',
                  audit.auditType,
                  _fmtDate(audit.auditDate),
                  audit.vendor,
                  audit.site ?? '-',
                  audit.auditorName ?? '-',
                  audit.totalTimeTakenHours.toStringAsFixed(2),
                  '$critical',
                  '$major',
                  '$minor',
                  cph.toStringAsFixed(2),
                  score,
                  milStatus,
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Calculation rules',
                style:
                    pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(
              'CPH = (Critical + Major findings) / Total Audited Hours',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              'Audit Score (Process/System Audit only) = 100 - 20×Critical - 5×Major - 2×Minor',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  static Future<void> generateAll({
    required List<Audit> audits,
    required Map<String, List<AuditFinding>> findingsByAudit,
  }) async {
    final bytes = await _buildAll(
      audits: audits,
      findingsByAudit: findingsByAudit,
    );
    await Printing.sharePdf(bytes: bytes, filename: 'Audit_Summary_All.pdf');
  }

  // ============================================================
  // Helpers
  // ============================================================

  static pw.Widget _infoTable(Map<String, String> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.3),
        1: pw.FlexColumnWidth(2),
      },
      children: rows.entries
          .map(
            (e) => pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(e.key,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(e.value, style: const pw.TextStyle(fontSize: 9)),
              ),
            ]),
          )
          .toList(),
    );
  }

  static String _fmtDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}
