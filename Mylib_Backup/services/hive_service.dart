import 'package:hive/hive.dart';
import '../models/question.dart';
import '../models/arr_record.dart';

class HiveService {
  static final Box masterBox = Hive.box('masterData');

  // Save Master Data
  static Future<void> saveMasterData(List<Question> questions) async {
    List<Map<String, dynamic>> data = [];

    for (var q in questions) {
      data.add({
        "partNo": q.partNo,

        "partName": q.partName,

        "initialStatus": q.initialStatus,

        "barcode": q.barcode,

        "batchId": q.batchId,

      });
    }

    await masterBox.put("questions", data);
  }

  // Load Master Data
  // Load Master Data
  static List<Question> loadMasterData() {
    final data = masterBox.get("questions");

    if (data == null) {
      return [];
    }
    final questions = List<Question>.from(
      (data as List).map(
            (e) => Question(
          partNo: e["partNo"] ?? "",
          partName: e["partName"] ?? "",
          initialStatus: e["initialStatus"] ?? 0,
          barcode: e["barcode"] ?? e["partNo"] ?? "",
          batchId: (e["batchId"] == null ||
              e["batchId"].toString().trim().isEmpty)
              ? "BATCH001"
              : e["batchId"],
        ),
      ),
    );

// One-time migration for old data
    bool updated = false;

    for (final q in questions) {
      if (q.batchId.isEmpty) {
        q.batchId = "BATCH001";
        updated = true;
      }
    }

    if (updated) {
      saveMasterData(questions);
    }

    return questions;
  }

  // Update Factory Master Data
  static Future<void> updateFactoryMasterData(
    List<Question> questions,
    int version,
  ) async {
    final currentVersion = masterBox.get("masterVersion") ?? 0;

    if (currentVersion >= version) {
      return;
    }

    await saveMasterData(questions);

    await masterBox.put("masterVersion", version);
  }

  // Previous ARR Box
  static final Box arrBox = Hive.box('previousArr');

  // Save Previous ARR
  static Future<void> savePreviousArrs(List<ArrRecord> records) async {
    List<Map<String, dynamic>> data = [];

    for (var r in records) {
      data.add({
        "employeeCode": r.employeeCode,
        "appraisee": r.appraisee,
        "department": r.department,
        "product": r.product,
        "batchName": r.batchName,
        "result": r.result,
        "certificateNo": r.certificateNo,
        "date": r.date,

        "falseAlertPercent": r.falseAlertPercent,
        "missRate": r.missRate,
        "effectiveness": r.effectiveness,
        "kappa": r.kappa,

        "trail1Answers": r.trail1Answers,
        "trail2Answers": r.trail2Answers,
        "trail3Answers": r.trail3Answers,

        "candidatePhotoPath": r.candidatePhotoPath,
        "batchId": r.batchId,
        "partNumbers": r.partNumbers,
        "masterAnswers": r.masterAnswers,
      });
    }

    await arrBox.put("records", data);
  }

  // Load Previous ARR
  static List<ArrRecord> loadPreviousArrs() {
    final data = arrBox.get("records");

    if (data == null) {
      return [];
    }

    return List<ArrRecord>.from(
      (data as List).map(
        (e) => ArrRecord(
          employeeCode: e["employeeCode"],

          appraisee: e["appraisee"],

          department: e["department"],

          product: e["product"],

          batchName: e["batchName"] ?? "",

          result: e["result"],

          certificateNo: e["certificateNo"],

          date: e["date"],

          falseAlertPercent:
          (e["falseAlertPercent"] ?? 0).toDouble(),

          missRate:
          (e["missRate"] ?? 0).toDouble(),

          effectiveness:
          (e["effectiveness"] ?? 0).toDouble(),

          kappa:
          (e["kappa"] ?? 0).toDouble(),
          batchId: e["batchId"] ?? "",

          partNumbers:
          List<String>.from(e["partNumbers"] ?? []),

          masterAnswers:
          List<int>.from(e["masterAnswers"] ?? []),

          trail1Answers:
          List<int>.from(e["trail1Answers"] ?? []),

          trail2Answers:
          List<int>.from(e["trail2Answers"] ?? []),

          trail3Answers:
          List<int>.from(e["trail3Answers"] ?? []),

          candidatePhotoPath:
          e["candidatePhotoPath"] ?? "",
        ),
        ),
    );

  }
  static String generateCertificateNumber({
    required String employeeCode,
    required String appraisee,
    required String department,
  }) {
    final records = loadPreviousArrs();

    final employeeRecords = records.where(
          (e) =>
      e.employeeCode.trim().toLowerCase() ==
          employeeCode.trim().toLowerCase(),
    ).toList();

    final attemptNumber = employeeRecords.length + 1;

    return "ARR-$employeeCode-$attemptNumber";
  }

  static String? validateEmployee({
    required String employeeCode,
    required String appraisee,
    required String department,
  }) {
    final records = loadPreviousArrs();

    for (final record in records) {
      if (record.employeeCode.trim().toLowerCase() ==
          employeeCode.trim().toLowerCase()) {

        if (record.appraisee.trim().toLowerCase() !=
            appraisee.trim().toLowerCase() ||
            record.department.trim().toLowerCase() !=
                department.trim().toLowerCase()) {

          return '''
Employee ID already exists.

Existing Details

Name : ${record.appraisee}
Department : ${record.department}

Entered Details

Name : $appraisee
Department : $department
''';
        }

        break;
      }
    }

    return null;
  }

  static List<Question> loadBatchQuestions(
      String batchId,
      ) {
    return loadMasterData()
        .where(
          (e) => e.batchId == batchId,
    )
        .toList();
  }
  static Future<void> addPart(
      Question part,
      ) async {

    final parts =
    loadMasterData();

    final partExists = parts.any(
          (e) =>
      e.partNo == part.partNo &&
          e.batchId == part.batchId,
    );

    if (partExists) {
      throw Exception(
        "Part Number already exists in this batch.",
      );
    }

    final qrExists = parts.any(
          (e) =>
      e.barcode.trim().toLowerCase() ==
          part.barcode.trim().toLowerCase() &&
          e.batchId == part.batchId,
    );

    if (qrExists) {
      throw Exception(
        "QR Code already exists in this batch.",
      );
    }

    parts.add(part);

    await saveMasterData(parts);

  }

  static Future<void> updatePart({
    required Question oldPart,
    required Question newPart,
  }) async {

    final parts = loadMasterData();

    final index = parts.indexWhere(
          (e) =>
      e.partNo == oldPart.partNo &&
          e.batchId == oldPart.batchId,
    );

    if (index == -1) {
      throw Exception("Part not found.");
    }

    final duplicatePart = parts.any(
          (e) =>
      e != parts[index] &&
          e.batchId == newPart.batchId &&
          e.partNo.trim().toLowerCase() ==
              newPart.partNo.trim().toLowerCase(),
    );

    if (duplicatePart) {
      throw Exception(
        "Part Number already exists in this batch.",
      );
    }

    final duplicateQR = parts.any(
          (e) =>
      e != parts[index] &&
          e.batchId == newPart.batchId &&
          e.barcode.trim().toLowerCase() ==
              newPart.barcode.trim().toLowerCase(),
    );

    if (duplicateQR) {
      throw Exception(
        "QR Code already exists in this batch.",
      );
    }

    parts[index] = newPart;

    await saveMasterData(parts);
  }

  static Future<void> deletePart(
      Question part,
      ) async {

    final parts =
    loadMasterData();

    parts.removeWhere(
          (e) =>
      e.partNo == part.partNo &&
          e.batchId == part.batchId,
    );

    await saveMasterData(parts);

  }
  //================== ADMIN SETTINGS ==================//

  static const String _defaultAdminPassword = "admin123";
  static const String _defaultAdminEmail = "lab.quality@pragatirrd.com";

  static String getAdminPassword() {
    return masterBox.get(
      "adminPassword",
      defaultValue: _defaultAdminPassword,
    );
  }

  static Future<void> setAdminPassword(
      String password,
      ) async {
    await masterBox.put(
      "adminPassword",
      password,
    );
  }

  static String getAdminEmail() {
    return masterBox.get(
      "adminEmail",
      defaultValue: _defaultAdminEmail,
    );
  }

  static Future<void> setAdminEmail(
      String email,
      ) async {
    await masterBox.put(
      "adminEmail",
      email,
    );
  }
  static Question? findPartByBarcode(
      String barcode,
      ) {

    try {

      return loadMasterData().firstWhere(

            (e) => e.barcode == barcode,

      );

    } catch (_) {

      return null;

    }

  }
}
