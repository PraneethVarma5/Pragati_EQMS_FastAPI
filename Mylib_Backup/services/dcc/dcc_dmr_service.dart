import 'package:hive_flutter/hive_flutter.dart';
import '../../models/dcc/dcc_dmr_request.dart';
import 'dart:io';
import '../../models/dcc/dcc_document.dart';
import '../../services/dcc/dcc_document_service.dart';
import '../../services/dcc/dcc_session.dart';

class DccDmrService {
  static const String boxName = 'dccDmrRequests';

  static Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }

    return Hive.box(boxName);
  }

  static Future<void> addRequest(
      DccDmrRequest request,
      ) async {
    final box = await _getBox();

    await box.put(
      request.id,
      request.toMap(),
    );
  }

  static Future<List<DccDmrRequest>> getRequests() async {
    final box = await _getBox();

    return box.values
        .map(
          (item) => DccDmrRequest.fromMap(
        Map<dynamic, dynamic>.from(item),
      ),
    )
        .toList();
  }

  static Future<List<DccDmrRequest>>
  getRequestsByUser(
      String userEmail,
      ) async {
    final requests = await getRequests();

    return requests.where((request) {
      return request.requestedByEmail
          .toLowerCase() ==
          userEmail.trim().toLowerCase();
    }).toList();
  }

  static Future<List<DccDmrRequest>>
  getRequestsForHod(
      String hodEmail,
      ) async {
    final requests = await getRequests();

    return requests.where((request) {
      return request.hodEmail
          .toLowerCase() ==
          hodEmail.trim().toLowerCase();
    }).toList();
  }

  static Future<List<DccDmrRequest>>
  getPendingHodRequests(
      String hodEmail,
      ) async {
    final requests =
    await getRequestsForHod(hodEmail);

    return requests.where((request) {
      return request.status == 'PENDING_HOD';
    }).toList();
  }

  static Future<List<DccDmrRequest>>
  getPendingDccRequests() async {
    final requests = await getRequests();

    return requests.where((request) {
      return request.status == 'PENDING_DCC' ||
          request.status == 'PENDING_DCC_REVIEW';
    }).toList();
  }

  static Future<List<DccDmrRequest>>
  getRequestsWithEditAccess(
      String userEmail,
      ) async {
    final requests =
    await getRequestsByUser(userEmail);

    return requests.where((request) {
      return request.modificationAccessGranted &&
          (
              request.status ==
                  'EDIT_ACCESS_GRANTED' ||
                  request.status ==
                      'PENDING_DCC_REVIEW'
          );
    }).toList();
  }

  static Future<List<DccDmrRequest>>
  getPendingDccReviewRequests() async {
    final requests =
    await getRequests();

    return requests.where((request) {
      return request.status ==
          'PENDING_DCC_REVIEW';
    }).toList();
  }

  static Future<DccDmrRequest?> getRequestById(
      String requestId,
      ) async {
    final box = await _getBox();

    final data = box.get(requestId);

    if (data == null) {
      return null;
    }

    return DccDmrRequest.fromMap(
      Map<dynamic, dynamic>.from(data),
    );
  }

  static Future<void> updateRequest(
      DccDmrRequest request,
      ) async {
    final box = await _getBox();

    await box.put(
      request.id,
      request.toMap(),
    );
  }

  static Future<void> deleteRequest(
      String requestId,
      ) async {
    final box = await _getBox();

    await box.delete(requestId);
  }
  static Future<void> acceptRevisedDocument(
      DccDmrRequest request,
      String dccName,
      ) async {
    if (request.revisedFilePath.trim().isEmpty) {
      throw Exception(
        'Revised file is not available.',
      );
    }

    final revisedFile =
    File(request.revisedFilePath);

    if (!await revisedFile.exists()) {
      throw Exception(
        'Revised file could not be found.',
      );
    }

    final document =
    await DccDocumentService.getDocumentById(
      request.documentId,
    );

    if (document == null) {
      throw Exception(
        'Original DCC document could not be found.',
      );
    }

    final newRevision =
        request.currentRevision + 1;

    final userProfile =
    Platform.environment['USERPROFILE'];

    if (userProfile == null ||
        userProfile.trim().isEmpty) {
      throw Exception(
        'Unable to determine Windows user folder.',
      );
    }

    final releasedDirectory =
    Directory(
      '$userProfile\\Downloads\\Digital ARR\\DCC Released Documents',
    );

    if (!await releasedDirectory.exists()) {
      await releasedDirectory.create(
        recursive: true,
      );
    }

    final originalName =
    request.revisedFileName.trim().isEmpty
        ? revisedFile.path.split('\\').last
        : request.revisedFileName.trim();

    final dotIndex =
    originalName.lastIndexOf('.');

    final extension =
    dotIndex > 0
        ? originalName.substring(dotIndex)
        : '';

    final baseName =
    dotIndex > 0
        ? originalName.substring(
      0,
      dotIndex,
    )
        : originalName;

    final safeDocumentNo =
    request.documentNo.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );

    final safeBaseName =
    baseName.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );

    final releasedFileName =
        '${safeDocumentNo}_Rev${newRevision}_'
        '${safeBaseName}${extension}';

    final releasedFile =
    File(
      '${releasedDirectory.path}\\$releasedFileName',
    );

    await revisedFile.copy(
      releasedFile.path,
    );

    if (!await releasedFile.exists()) {
      throw Exception(
        'Released revision could not be verified.',
      );
    }

    final newDocumentId =
        '${document.id}_REV$newRevision';

    final newDocument =
    DccDocument(
      id: newDocumentId,

      documentNo:
      document.documentNo,

      documentName:
      document.documentName,

      documentType:
      document.documentType,

      department:
      document.department,

      candidateName:
      document.candidateName,

      employeeId:
      document.employeeId,

      attachmentPath:
      document.attachmentPath,

      attachmentName:
      document.attachmentName,

      createdByName:
      document.createdByName,

      createdByEmail:
      document.createdByEmail,

      hodName:
      document.hodName,

      hodEmail:
      document.hodEmail,

      status:
      'RELEASED',

      revision:
      newRevision,

      revisionDate:
      DateTime.now()
          .toIso8601String(),

      releasedPdfPath:
      releasedFile.path,

      releasedPdfName:
      releasedFileName,

      releasedByName:
      dccName,

      releasedByEmail:
      DccSession.currentUser?.email ?? '',

      rejectionReason:
      '',
    );

    await DccDocumentService.addDocument(
      newDocument,
    );

    final updatedRequest =
    DccDmrRequest(
      id: request.id,
      documentId:
      request.documentId,

      documentNo:
      request.documentNo,

      documentName:
      request.documentName,

      documentType:
      request.documentType,

      department:
      request.department,

      requestedByName:
      request.requestedByName,

      requestedByEmail:
      request.requestedByEmail,

      hodName:
      request.hodName,

      hodEmail:
      request.hodEmail,

      currentRevision:
      newRevision,

      requestReason:
      request.requestReason,

      status:
      'COMPLETED',

      rejectionReason:
      '',

      createdDate:
      request.createdDate,

      hodActionDate:
      request.hodActionDate,

      dccActionDate:
      DateTime.now()
          .toIso8601String(),

      sourceFilePath:
      request.sourceFilePath,

      sourceFileName:
      request.sourceFileName,

      revisedFilePath:
      request.revisedFilePath,

      revisedFileName:
      request.revisedFileName,

      revisedSubmittedDate:
      request.revisedSubmittedDate,

      revisedRejectionReason:
      '',

      modificationAccessGranted:
      false,
    );

    await updateRequest(
      updatedRequest,
    );
  }

  static Future<void> rejectRevisedDocument(
      DccDmrRequest request,
      String reason,
      String dccName,
      ) async {
    final updatedRequest = DccDmrRequest(
      id: request.id,
      documentId: request.documentId,
      documentNo: request.documentNo,
      documentName: request.documentName,
      documentType: request.documentType,
      department: request.department,
      requestedByName: request.requestedByName,
      requestedByEmail: request.requestedByEmail,
      hodName: request.hodName,
      hodEmail: request.hodEmail,
      currentRevision: request.currentRevision,
      requestReason: request.requestReason,
      status: 'EDIT_ACCESS_GRANTED',
      rejectionReason: request.rejectionReason,
      createdDate: request.createdDate,
      hodActionDate: request.hodActionDate,
      dccActionDate: DateTime.now().toIso8601String(),
      sourceFilePath: request.sourceFilePath,
      sourceFileName: request.sourceFileName,
      revisedFilePath: request.revisedFilePath,
      revisedFileName: request.revisedFileName,
      revisedSubmittedDate: request.revisedSubmittedDate,
      revisedRejectionReason: reason,
      modificationAccessGranted: true,
    );

    await updateRequest(updatedRequest);
  }
}