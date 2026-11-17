import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

import 'supabase_service.dart';

class ExcelImportResult {
  final bool success;
  final String message;
  final int imported;

  ExcelImportResult({
    required this.success,
    required this.message,
    required this.imported,
  });
}

class ExcelImportService {
  ExcelImportService._();

  static Future<ExcelImportResult> importBatch({
    required String batchId,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["xlsx"],
    );

    if (result == null) {
      return ExcelImportResult(
        success: false,
        message: "Import cancelled.",
        imported: 0,
      );
    }

    final bytes = File(result.files.single.path!)
        .readAsBytesSync();

    final excel = Excel.decodeBytes(bytes);

    final sheet = excel.tables.values.first;
    final header = sheet.rows.first;

    if (header.length < 3 ||
        header[0]?.value.toString().trim() != "Part Number" ||
        header[1]?.value.toString().trim() != "QR Code" ||
        header[2]?.value.toString().trim() != "Master Data") {

      return ExcelImportResult(
        success: false,
        message:
        "Invalid Excel format.\n\nExpected columns:\nPart Number | QR Code | Master Data",
        imported: 0,
      );

    }

    if (sheet.maxRows <= 1) {
      return ExcelImportResult(
        success: false,
        message: "Excel file is empty.",
        imported: 0,
      );
    }

    final existing =
    await SupabaseService.getAllParts(batchId);

    final existingPartNos = existing
        .map(
          (e) => e['part_no']
          ?.toString()
          .trim()
          .toLowerCase(),
    )
        .whereType<String>()
        .toSet();

    final existingQRs = existing
        .map(
          (e) => e['barcode']
          ?.toString()
          .trim()
          .toLowerCase(),
    )
        .whereType<String>()
        .toSet();

    final excelPartNos = <String>{};

    final excelQRs = <String>{};

    final List<Map<String, dynamic>> importedParts = [];
    final List<String> errors = [];

    for (int row = 1;
    row < sheet.maxRows;
    row++) {

      final cells = sheet.rows[row];

      if (cells.length < 3) {

        errors.add(
          "Row ${row + 1} : Missing required columns.",
        );

        continue;

      }

      final partNo =
          cells[0]?.value
              ?.toString()
              .trim() ??
              "";

      final qr =
          cells[1]?.value
              ?.toString()
              .trim() ??
              "";

      final master =
          cells[2]?.value
              ?.toString()
              .trim() ??
              "";

      if (partNo.isEmpty &&
          qr.isEmpty &&
          master.isEmpty) {
        continue;
      }

      if (partNo.isEmpty) {
        errors.add(
          "Row ${row + 1} : Part Number is empty.",
        );

        continue;
      }

      if (qr.isEmpty) {
        errors.add(
          "Row ${row + 1} : QR Code is empty.",
        );

        continue;
      }

      if (master != "0" &&
          master != "1") {
        errors.add(
          "Row ${row + 1} : Master Data must be 0 or 1.",
        );

        continue;
      }

      if (excelPartNos.contains(
          partNo.toLowerCase())) {
        errors.add(
          "Row ${row + 1} : Duplicate Part Number ($partNo).",
        );

        continue;
      }

      if (excelQRs.contains(
          qr.toLowerCase())) {
        errors.add(
          "Row ${row + 1} : Duplicate QR Code ($qr).",
        );

        continue;
      }

      if (existingPartNos.contains(
          partNo.toLowerCase())) {

        errors.add(
          "Row ${row + 1} : Part Number already exists in this batch ($partNo).",
        );

        continue;

      }

      if (existingQRs.contains(
          qr.toLowerCase())) {

        errors.add(
          "Row ${row + 1} : QR Code already exists in this batch ($qr).",
        );

        continue;

      }

      excelPartNos.add(
        partNo.toLowerCase(),
      );

      excelQRs.add(
        qr.toLowerCase(),
      );

      importedParts.add({
        'batch_id': batchId,
        'part_no': partNo,
        'part_name': '',
        'initial_status': int.parse(master),
        'barcode': qr,
        'sequence_order': importedParts.length + 1,
        'is_active': true,
      });
    }

    if (errors.isNotEmpty) {

      return ExcelImportResult(
        success: false,
        message: errors.join("\n\n"),
        imported: 0,
      );

    }

    if (importedParts.isEmpty) {
      return ExcelImportResult(
        success: false,
        message: "No valid parts found in the Excel file.",
        imported: 0,
      );
    }

    try {
      await SupabaseService.client
          .from('parts')
          .insert(importedParts);

      return ExcelImportResult(
        success: true,
        message:
        "Imported ${importedParts.length} parts successfully.",
        imported: importedParts.length,
      );
    } catch (e) {
      return ExcelImportResult(
        success: false,
        message:
        "Unable to import parts into Supabase.\n\n$e",
        imported: 0,
      );
    }
  }
}