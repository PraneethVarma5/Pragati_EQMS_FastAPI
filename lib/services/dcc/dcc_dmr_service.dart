import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/dcc/dcc_dmr_request.dart';
import '../../models/dcc/dcc_document.dart';
import 'dcc_document_service.dart';
import 'dcc_storage_service.dart';
import 'dcc_session.dart';
import 'dcc_master_data_service.dart';
import '../../models/dcc/dcc_master_data.dart';

/// DMR (Document Modification Request) storage, backed by the
/// Supabase "dcc_dmr_requests" table.
///
/// This used to be stored in a local Hive box, which meant a
/// User's request was never actually visible to their HOD at
/// all — each browser only saw its own local copy. Moving it to
/// Supabase is what makes cross-user visibility (and real-time
/// updates) possible.
class DccDmrService {
  static const String tableName = 'dcc_dmr_requests';

  static SupabaseClient get _client => Supabase.instance.client;

  // ------------------------------------------------------------
  // Convert DccDmrRequest -> Supabase row
  // ------------------------------------------------------------
  static Map<String, dynamic> _toRow(DccDmrRequest request) {
    return {
      'id': request.id,
      'document_id': request.documentId,
      'document_no': request.documentNo,
      'document_name': request.documentName,
      'document_type': request.documentType,
      'department': request.department,

      'requested_by_name': request.requestedByName,
      'requested_by_email': request.requestedByEmail,

      'hod_name': request.hodName,
      'hod_email': request.hodEmail,

      'current_revision': request.currentRevision,

      'request_reason': request.requestReason,

      'status': request.status,
      'rejection_reason': request.rejectionReason,

      'created_date': request.createdDate,
      'hod_action_date': request.hodActionDate,
      'dcc_action_date': request.dccActionDate,

      'source_file_path': request.sourceFilePath,
      'source_file_name': request.sourceFileName,

      'revised_file_path': request.revisedFilePath,
      'revised_file_name': request.revisedFileName,
      'revised_submitted_date': request.revisedSubmittedDate,

      'revised_rejection_reason': request.revisedRejectionReason,

      'modification_access_granted':
      request.modificationAccessGranted,

      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // ------------------------------------------------------------
  // Convert Supabase row -> DccDmrRequest
  // ------------------------------------------------------------
  static DccDmrRequest _fromRow(Map<String, dynamic> row) {
    return DccDmrRequest(
      id: row['id']?.toString() ?? '',
      documentId: row['document_id']?.toString() ?? '',
      documentNo: row['document_no']?.toString() ?? '',
      documentName: row['document_name']?.toString() ?? '',
      documentType: row['document_type']?.toString() ?? '',
      department: row['department']?.toString() ?? '',
      requestedByName: row['requested_by_name']?.toString() ?? '',
      requestedByEmail: row['requested_by_email']?.toString() ?? '',
      hodName: row['hod_name']?.toString() ?? '',
      hodEmail: row['hod_email']?.toString() ?? '',
      currentRevision:
      int.tryParse(row['current_revision']?.toString() ?? '') ?? 0,
      requestReason: row['request_reason']?.toString() ?? '',
      status: row['status']?.toString() ?? 'PENDING_HOD',
      rejectionReason: row['rejection_reason']?.toString() ?? '',
      createdDate: row['created_date']?.toString() ?? '',
      hodActionDate: row['hod_action_date']?.toString() ?? '',
      dccActionDate: row['dcc_action_date']?.toString() ?? '',
      sourceFilePath: row['source_file_path']?.toString() ?? '',
      sourceFileName: row['source_file_name']?.toString() ?? '',
      revisedFilePath: row['revised_file_path']?.toString() ?? '',
      revisedFileName: row['revised_file_name']?.toString() ?? '',
      revisedSubmittedDate:
      row['revised_submitted_date']?.toString() ?? '',
      revisedRejectionReason:
      row['revised_rejection_reason']?.toString() ?? '',
      modificationAccessGranted:
      row['modification_access_granted'] == true,
    );
  }

  static Future<void> addRequest(DccDmrRequest request) async {
    await _client
        .from(tableName)
        .upsert(_toRow(request), onConflict: 'id');
  }

  static Future<List<DccDmrRequest>> getRequests() async {
    final response = await _client
        .from(tableName)
        .select()
        .order('created_date', ascending: false);

    return (response as List)
        .map((row) => _fromRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<List<DccDmrRequest>> getRequestsByUser(
      String userEmail,
      ) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('requested_by_email', userEmail.trim().toLowerCase())
        .order('created_date', ascending: false);

    return (response as List)
        .map((row) => _fromRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<List<DccDmrRequest>> getRequestsForHod(
      String hodEmail,
      ) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('hod_email', hodEmail.trim().toLowerCase())
        .order('created_date', ascending: false);

    return (response as List)
        .map((row) => _fromRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<List<DccDmrRequest>> getPendingHodRequests(
      String hodEmail,
      ) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('hod_email', hodEmail.trim().toLowerCase())
        .eq('status', 'PENDING_HOD')
        .order('created_date', ascending: false);

    return (response as List)
        .map((row) => _fromRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<List<DccDmrRequest>> getPendingDccRequests() async {
    final response = await _client
        .from(tableName)
        .select()
        .inFilter('status', ['PENDING_DCC', 'PENDING_DCC_REVIEW'])
        .order('created_date', ascending: false);

    return (response as List)
        .map((row) => _fromRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<List<DccDmrRequest>> getRequestsWithEditAccess(
      String userEmail,
      ) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('requested_by_email', userEmail.trim().toLowerCase())
        .eq('modification_access_granted', true)
        .inFilter(
      'status',
      ['EDIT_ACCESS_GRANTED', 'PENDING_DCC_REVIEW'],
    )
        .order('created_date', ascending: false);

    return (response as List)
        .map((row) => _fromRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<List<DccDmrRequest>>
  getPendingDccReviewRequests() async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('status', 'PENDING_DCC_REVIEW')
        .order('created_date', ascending: false);

    return (response as List)
        .map((row) => _fromRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<DccDmrRequest?> getRequestById(
      String requestId,
      ) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('id', requestId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return _fromRow(Map<String, dynamic>.from(response));
  }

  static Future<void> updateRequest(DccDmrRequest request) async {
    await _client
        .from(tableName)
        .upsert(_toRow(request), onConflict: 'id');
  }

  static Future<void> deleteRequest(String requestId) async {
    await _client.from(tableName).delete().eq('id', requestId);
  }

  /// DCC accepts a User's revised document: promotes the already
  /// -uploaded revised file (in Supabase Storage) to the released
  /// area as the next revision, creates the new released
  /// DccDocument row, and marks the request COMPLETED. Entirely
  /// server-side storage — no local filesystem access, so this
  /// works on web the same as anywhere else.
  static Future<void> acceptRevisedDocument(
      DccDmrRequest request,
      String dccName,
      ) async {
    final latestRequest =
    await getRequestById(
      request.id,
    );

    if (latestRequest == null) {
      throw Exception(
        'DMR request could not be found.',
      );
    }

    // ------------------------------------------------------------
    // IMPORTANT:
    // Only a DMR currently waiting for DCC review can be accepted.
    //
    // If the first click already completed it, every later click
    // stops here instead of increasing the revision again.
    // ------------------------------------------------------------

    if (latestRequest.status !=
        'PENDING_DCC_REVIEW') {
      throw Exception(
        'This DMR has already been processed.',
      );
    }

    if (latestRequest.revisedFilePath
        .trim()
        .isEmpty) {
      throw Exception(
        'Revised file is not available.',
      );
    }

    // Get the original DCC document.
    final document =
    await DccDocumentService.getDocumentById(
      request.documentId,
    );

    if (document == null) {
      throw Exception(
        'Original DCC document could not be found.',
      );
    }

    // ------------------------------------------------------------
    // Calculate the next revision.
    // Master Data is used as the latest revision source when
    // available.
    // ------------------------------------------------------------

    final master =
    await DccMasterDataService.getByDocumentNo(
      request.documentNo,
    );

    final baseRevision =
        master?.revision ?? request.currentRevision;

    final newRevision =
        (baseRevision > request.currentRevision
            ? baseRevision
            : request.currentRevision) +
            1;

    // ------------------------------------------------------------
    // Promote the revised PDF to the released area.
    // ------------------------------------------------------------

    final releasedFileName =
    request.revisedFileName.trim().isNotEmpty
        ? request.revisedFileName
        : document.releasedPdfName;

    final releasedPath =
    await DccStorageService.promoteRevisedToReleased(
      revisedPath: request.revisedFilePath,
      documentId: document.id,
      revision: newRevision,
      originalFileName: releasedFileName,
    );

    // ------------------------------------------------------------
    // Create a NEW DCC document row for the new revision.
    // ------------------------------------------------------------

    final newDocument = DccDocument(
      id: '${document.id}_REV$newRevision',
      documentNo: document.documentNo,
      documentName: document.documentName,
      documentType: document.documentType,
      department: document.department,
      candidateName: document.candidateName,
      employeeId: document.employeeId,
      attachmentPath: document.attachmentPath,
      attachmentName: document.attachmentName,
      createdByName: document.createdByName,
      createdByEmail: document.createdByEmail,
      hodName: document.hodName,
      hodEmail: document.hodEmail,
      status: 'RELEASED',
      revision: newRevision,
      revisionDate: DateTime.now().toIso8601String(),
      releasedPdfPath: releasedPath,
      releasedPdfName: releasedFileName,
      releasedByName: dccName,
      releasedByEmail:
      DccSession.currentUser?.email ?? '',
      rejectionReason: '',
    );

    await DccDocumentService.addDocument(
      newDocument,
    );

    // ------------------------------------------------------------
    // Update Master Data to the new revision.
    // ------------------------------------------------------------

    await DccMasterDataService.upsertEntry(
      DccMasterData(
        documentNo: document.documentNo,
        documentName: document.documentName,
        documentType: document.documentType,
        department: document.department,
        candidateName:
        master?.candidateName.isNotEmpty == true
            ? master!.candidateName
            : document.candidateName,
        candidateEmail:
        master?.candidateEmail ?? '',
        createdByName:
        master?.createdByName.isNotEmpty == true
            ? master!.createdByName
            : document.createdByName,
        createdByEmail:
        master?.createdByEmail.isNotEmpty == true
            ? master!.createdByEmail
            : document.createdByEmail,
        revision: newRevision,
      ),
      manualRevision: newRevision,
    );

    // ------------------------------------------------------------
    // Complete the DMR.
    //
    // IMPORTANT:
    // documentId points to the NEW released document revision,
    // not the old document.
    // ------------------------------------------------------------

    final updatedRequest = DccDmrRequest(
      id: request.id,
      documentId: newDocument.id,
      documentNo: request.documentNo,
      documentName: request.documentName,
      documentType: request.documentType,
      department: request.department,
      requestedByName: request.requestedByName,
      requestedByEmail: request.requestedByEmail,
      hodName: request.hodName,
      hodEmail: request.hodEmail,
      currentRevision: newRevision,
      requestReason: request.requestReason,
      status: 'COMPLETED',
      rejectionReason: '',
      createdDate: request.createdDate,
      hodActionDate: request.hodActionDate,
      dccActionDate:
      DateTime.now().toIso8601String(),
      sourceFilePath: request.sourceFilePath,
      sourceFileName: request.sourceFileName,
      revisedFilePath: request.revisedFilePath,
      revisedFileName: request.revisedFileName,
      revisedSubmittedDate:
      request.revisedSubmittedDate,
      revisedRejectionReason: '',
      modificationAccessGranted: false,
    );

    await updateRequest(updatedRequest);
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
