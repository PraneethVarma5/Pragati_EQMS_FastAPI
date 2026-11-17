import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../pdf/report_pdf.dart';
import '../pdf/certificate_pdf.dart';
import '../pdf/combined_certificate_pdf.dart';
import '../pdf/cross_tab_report_pdf.dart';

import '../models/arr_record.dart';
import '../models/cross_tab_result.dart';

import '../services/app_data.dart';
import '../utils/file_helper.dart';

import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';

class PdfService {
  PdfService._();

  static Future<void> saveReport({
    required BuildContext context,
    required Map<String, dynamic> record,
    required List<Map<String, dynamic>> observations,
  }) async {
    final bytes = await ReportPdf.generate(
      record: record,
      observations: observations,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename:
      "ARR_Report_${record["certificate_number"] ?? AppData.certificateNo}.pdf",
    );
  }

  static Future<Uint8List> saveCertificate({
    ArrRecord? record,
  }) async {
    return await CertificatePdf.generate(
      record: record,
    );
  }

  // static Future<void> downloadReport(
  //     BuildContext context,
  //     ) async {
  //
  //   final file = await saveReport();
  //
  //   if (!context.mounted) return;
  //
  //   ScaffoldMessenger.of(context).showSnackBar(
  //
  //     SnackBar(
  //
  //       content: Text(
  //         "Report saved to\n${file.path}",
  //       ),
  //
  //     ),
  //
  //   );
  //
  // }
  static Future<void> downloadReport({
    required BuildContext context,
    required Map<String, dynamic> record,
    required List<Map<String, dynamic>> observations,
  }) async {
    try {
      final bytes = await ReportPdf.generate(
        record: record,
        observations: observations,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename:
        "ARR_Report_${record["certificate_number"] ?? AppData.certificateNo}.pdf",
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Unable to generate report: $e",
          ),
        ),
      );
    }
  }

  static Future<void> downloadCertificate({
    required BuildContext context,
    ArrRecord? record,
  }) async {
    try {
      final bytes = await saveCertificate(
        record: record,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename:
        "ARR_Certificate_${record?.certificateNo ?? AppData.certificateNo}.pdf",
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Unable to generate certificate: $e",
          ),
        ),
      );
    }
  }
  // static Future<void> printReport() async {
  //
  //   final bytes = await ReportPdf.generate();
  //
  //   await Printing.layoutPdf(
  //
  //     onLayout: (format) async => bytes,
  //
  //   );
  //
  // }
  static Future<void> printReport({
    required Map<String, dynamic> record,
    required List<Map<String, dynamic>> observations,
  }) async {
    try {
      final bytes = await ReportPdf.generate(
        record: record,
        observations: observations,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
      );
    } catch (e) {
      debugPrint(
        "PRINT REPORT ERROR: $e",
      );
    }
  }

  static Future<void> printCertificate({
    ArrRecord? record,
  }) async {
    try {
      final bytes = await CertificatePdf.generate(
        record: record,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
      );
    } catch (e) {
      debugPrint(
        "PRINT CERTIFICATE ERROR: $e",
      );
    }
  }

  // static Future<void> shareReport() async {
  //
  //   final file = await saveReport();
  //
  //   await Share.shareXFiles(
  //
  //     [
  //
  //       XFile(file.path),
  //
  //     ],
  //
  //     text: "ARR Observation Report",
  //
  //   );
  //
  // }
  static Future<void> shareReport({
    required Map<String, dynamic> record,
    required List<Map<String, dynamic>> observations,
  }) async {
    try {
      final bytes = await ReportPdf.generate(
        record: record,
        observations: observations,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename:
        "ARR_Report_${record["certificate_number"] ?? AppData.certificateNo}.pdf",
      );
    } catch (e) {
      debugPrint(
        "SHARE REPORT ERROR: $e",
      );
    }
  }


  static Future<void> shareCertificate({
    ArrRecord? record,
  }) async {
    try {
      final bytes = await CertificatePdf.generate(
        record: record,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename:
        "ARR_Certificate_${record?.certificateNo ?? AppData.certificateNo}.pdf",
      );
    } catch (e) {
      debugPrint(
        "SHARE CERTIFICATE ERROR: $e",
      );
    }
  }
// ================================
// Combined Certificate
// ================================

  // static Future<File> saveCombinedCertificate() async {
  //
  //   final bytes = await CombinedCertificatePdf.generate();
  //
  //   final file = await FileHelper.saveFile(
  //     subFolder: "Certificates",
  //     fileName: "Combined_ARR_Certificate_${AppData.certificateNo}.pdf",
  //     bytes: bytes,
  //   );
  //
  //   return file;
  // }
  //
  // static Future<void> downloadCombinedCertificate({
  //   required BuildContext context,
  // }) async {
  //
  //   final file = await saveCombinedCertificate();
  //
  //   if (!context.mounted) return;
  //
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(
  //         "Saved\n${file.path}",
  //       ),
  //     ),
  //   );
  // }
  //
  // static Future<void> printCombinedCertificate() async {
  //
  //   final bytes = await CombinedCertificatePdf.generate();
  //
  //   await Printing.layoutPdf(
  //     onLayout: (format) async => bytes,
  //   );
  // }
  //
  // static Future<void> shareCombinedCertificate() async {
  //
  //   final file = await saveCombinedCertificate();
  //
  //   await Share.shareXFiles(
  //     [
  //       XFile(file.path),
  //     ],
  //     text: "Combined ARR Certificate",
  //   );
  // }

// Combined Certificate feature
// To be implemented
  static Future<Uint8List> saveCombinedCertificate({
    required List<Map<String, dynamic>> records,
  }) async {
    return await CombinedCertificatePdf.generate(
      records: records,
    );
  }
  static Future<void> downloadCombinedCertificate({
    required BuildContext context,
    required List<Map<String, dynamic>> records,
  }) async {
    try {
      final bytes = await saveCombinedCertificate(
        records: records,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename:
        "Combined_ARR_Certificate_${DateTime.now().millisecondsSinceEpoch}.pdf",
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Unable to generate combined certificate: $e",
          ),
        ),
      );
    }
  }
  static Future<void> printCombinedCertificate({
    required List<Map<String, dynamic>> records,
  }) async {
    try {
      final bytes = await CombinedCertificatePdf.generate(
        records: records,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
      );
    } catch (e) {
      debugPrint(
        "PRINT COMBINED CERTIFICATE ERROR: $e",
      );
    }
  }
  static Future<void> shareCombinedCertificate({
    required List<Map<String, dynamic>> records,
  }) async {
    try {
      final bytes = await CombinedCertificatePdf.generate(
        records: records,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename:
        "Combined_ARR_Certificate_${DateTime.now().millisecondsSinceEpoch}.pdf",
      );
    } catch (e) {
      debugPrint(
        "SHARE COMBINED CERTIFICATE ERROR: $e",
      );
    }
  }
  static Future<Uint8List> saveCrossTabReport({
    required CrossTabResult result,
  }) async {
    return await CrossTabReportPdf.generate(
      result: result,
    );
  }
  static Future<void> downloadCrossTabReport({
    required BuildContext context,
    required CrossTabResult result,
  }) async {
    try {
      final bytes = await saveCrossTabReport(
        result: result,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename:
        "Cross_Tab_Report_${DateTime.now().millisecondsSinceEpoch}.pdf",
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          content: Text(
            "Unable to generate Cross Tab report: $e",
          ),
        ),
      );
    }
  }
  static Future<void> printCrossTabReport({
    required CrossTabResult result,
  }) async {

    final bytes =
    await CrossTabReportPdf.generate(
      result: result,
    );

    await Printing.layoutPdf(

      name: "Digital ARR Cross Tab Report",

      onLayout: (_) async => bytes,

    );

  }
  static Future<void> shareCrossTabReport({
    required CrossTabResult result,
  }) async {
    try {
      final bytes =
      await CrossTabReportPdf.generate(
        result: result,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename:
        "Cross_Tab_Report_${DateTime.now().millisecondsSinceEpoch}.pdf",
      );
    } catch (e) {
      debugPrint(
        "SHARE CROSS TAB REPORT ERROR: $e",
      );
    }
  }
}
