import '../../models/dcc/dcc_document.dart';
import 'dcc_api_client.dart';
import 'dcc_storage_service.dart';

class DccDocumentService {
  static const String tableName = 'dcc_documents';

  static Map<String, dynamic> _toRow(DccDocument document) {
    return {
      'id': document.id,
      'document_no': document.documentNo,
      'document_name': document.documentName,
      'document_type': document.documentType,
      'department': document.department,
      'candidate_name': document.candidateName,
      'employee_id': document.employeeId,
      'folder_name': document.folderName,
      'attachment_path': document.attachmentPath,
      'attachment_name': document.attachmentName,
      'released_pdf_path': document.releasedPdfPath,
      'released_pdf_name': document.releasedPdfName,
      'created_by_name': document.createdByName,
      'created_by_email': document.createdByEmail,
      'released_by_name': document.releasedByName,
      'released_by_email': document.releasedByEmail,
      'hod_name': document.hodName,
      'hod_email': document.hodEmail,
      'status': document.status,
      'revision': document.revision,
      'revision_date': document.revisionDate,
      'rejection_reason': document.rejectionReason,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  static DccDocument _fromRow(Map<String, dynamic> row) {
    return DccDocument(
      id: row['id']?.toString() ?? '',
      documentNo: row['document_no']?.toString() ?? '',
      documentName: row['document_name']?.toString() ?? '',
      documentType: row['document_type']?.toString() ?? '',
      department: row['department']?.toString() ?? '',
      candidateName: row['candidate_name']?.toString() ?? '',
      employeeId: row['employee_id']?.toString() ?? '',
      folderName: row['folder_name']?.toString() ?? '',
      attachmentPath: row['attachment_path']?.toString() ?? '',
      attachmentName: row['attachment_name']?.toString() ?? '',
      releasedPdfPath: row['released_pdf_path']?.toString() ?? '',
      releasedPdfName: row['released_pdf_name']?.toString() ?? '',
      createdByName: row['created_by_name']?.toString() ?? '',
      createdByEmail: row['created_by_email']?.toString() ?? '',
      releasedByName: row['released_by_name']?.toString() ?? '',
      releasedByEmail: row['released_by_email']?.toString() ?? '',
      hodName: row['hod_name']?.toString() ?? '',
      hodEmail: row['hod_email']?.toString() ?? '',
      status: row['status']?.toString() ?? 'PENDING_HOD',
      revision: int.tryParse(row['revision']?.toString() ?? '') ?? 1,
      revisionDate: row['revision_date']?.toString() ?? '',
      rejectionReason: row['rejection_reason']?.toString() ?? '',
    );
  }

  static List<DccDocument> _parseList(dynamic response) {
    if (response is! List) {
      throw Exception('Documents API returned an unexpected response format.');
    }
    return response
        .map((row) => _fromRow(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  static Future<void> addDocument(DccDocument document) async {
    await DccApiClient.post('/documents', body: {'data': _toRow(document)});
  }


  // Public starting screen: released documents only.
  static Future<List<DccDocument>> getReleasedDocuments() async {
    return _parseList(
      await DccApiClient.get(
        '/documents',
        authenticated: false,
      ),
    );
  }

  // Authenticated DCC dashboard: documents permitted for the logged-in user.
  static Future<List<DccDocument>> getDocuments() async {
    return _parseList(
      await DccApiClient.get(
        '/documents',
        authenticated: true,
      ),
    );
  }


  static Future<DccDocument?> getDocumentById(String documentId) async {
    try {
      final response = await DccApiClient.get('/documents/${Uri.encodeComponent(documentId)}');
      if (response is! Map) return null;
      return _fromRow(Map<String, dynamic>.from(response));
    } catch (e) {
      if (e.toString().contains('404') || e.toString().contains('Record not found')) return null;
      rethrow;
    }
  }

  static Future<List<DccDocument>> getDocumentsForHod(String hodEmail) async {
    // The backend scopes HOD records to the authenticated HOD. The email
    // parameter is retained for compatibility with existing screens.
    return _parseList(await DccApiClient.get('/documents'));
  }

  static Future<List<DccDocument>> getDocumentsByUser(String email) async {
    // USER access is server-scoped to the authenticated account. Released
    // documents are also returned where permitted by the backend.
    return _parseList(await DccApiClient.get('/documents'));
  }

  static Future<void> updateDocument(DccDocument document) async {
    await DccApiClient.patch(
      '/documents/${Uri.encodeComponent(document.id)}',
      body: {'data': _toRow(document)},
    );
  }

  static Future<void> updateSourceFile({
    required String documentId,
    required String attachmentPath,
    required String attachmentName,
  }) async {
    await DccApiClient.patch(
      '/documents/${Uri.encodeComponent(documentId)}',
      body: {'data': {
        'attachment_path': attachmentPath,
        'attachment_name': attachmentName,
        'updated_at': DateTime.now().toIso8601String(),
      }},
    );
  }

  static Future<void> updateStatus({
    required String documentId,
    required String status,
    String? rejectionReason,
  }) async {
    final data = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (rejectionReason != null) data['rejection_reason'] = rejectionReason;
    await DccApiClient.patch(
      '/documents/${Uri.encodeComponent(documentId)}',
      body: {'data': data},
    );
  }

  static Future<void> deleteDocument(DccDocument document) async {
    final documentId = document.id.trim();
    if (documentId.isEmpty) throw Exception('Document ID is missing.');

    final releasedPath = document.releasedPdfPath.trim();
    if (releasedPath.isNotEmpty) {
      try {
        await DccStorageService.deleteFile(releasedPath);
      } catch (e) {
        throw Exception('Unable to delete the released PDF: $e');
      }
    }

    await DccApiClient.delete('/documents/${Uri.encodeComponent(documentId)}');
  }
}
