import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/dcc/dcc_document.dart';
import 'dcc_storage_service.dart';

class DccDocumentService {
  static const String tableName = 'dcc_documents';

  static SupabaseClient get _client =>
      Supabase.instance.client;

  // ------------------------------------------------------------
  // Convert DccDocument -> Supabase row
  // ------------------------------------------------------------
  static Map<String, dynamic> _toRow(
      DccDocument document,
      ) {
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

  // ------------------------------------------------------------
  // Convert Supabase row -> DccDocument
  // ------------------------------------------------------------
  static DccDocument _fromRow(
      Map<String, dynamic> row,
      ) {
    return DccDocument(
      id: row['id']?.toString() ?? '',

      documentNo:
      row['document_no']?.toString() ?? '',

      documentName:
      row['document_name']?.toString() ?? '',

      documentType:
      row['document_type']?.toString() ?? '',

      department:
      row['department']?.toString() ?? '',

      candidateName:
      row['candidate_name']?.toString() ?? '',

      employeeId:
      row['employee_id']?.toString() ?? '',

      folderName:
      row['folder_name']?.toString() ?? '',

      attachmentPath:
      row['attachment_path']?.toString() ?? '',

      attachmentName:
      row['attachment_name']?.toString() ?? '',

      releasedPdfPath:
      row['released_pdf_path']?.toString() ?? '',

      releasedPdfName:
      row['released_pdf_name']?.toString() ?? '',

      createdByName:
      row['created_by_name']?.toString() ?? '',

      createdByEmail:
      row['created_by_email']?.toString() ?? '',

      releasedByName:
      row['released_by_name']?.toString() ?? '',

      releasedByEmail:
      row['released_by_email']?.toString() ?? '',

      hodName:
      row['hod_name']?.toString() ?? '',

      hodEmail:
      row['hod_email']?.toString() ?? '',

      status:
      row['status']?.toString() ?? 'PENDING_HOD',

      revision:
      int.tryParse(
        row['revision']?.toString() ?? '',
      ) ??
          1,

      revisionDate:
      row['revision_date']?.toString() ?? '',

      rejectionReason:
      row['rejection_reason']?.toString() ?? '',
    );
  }

  // ------------------------------------------------------------
  // ADD DOCUMENT
  // ------------------------------------------------------------
  static Future<void> addDocument(
      DccDocument document,
      ) async {
    await _client
        .from(tableName)
        .upsert(
      _toRow(document),
      onConflict: 'id',
    );
  }

  // ------------------------------------------------------------
  // GET ALL DOCUMENTS
  // ------------------------------------------------------------
  static Future<List<DccDocument>> getDocuments() async {
    final response = await _client
        .from(tableName)
        .select()
        .order(
      'revision_date',
      ascending: false,
    );

    return (response as List)
        .map(
          (row) => _fromRow(
        Map<String, dynamic>.from(row),
      ),
    )
        .toList();
  }

  // ------------------------------------------------------------
  // GET DOCUMENT BY ID
  // ------------------------------------------------------------
  static Future<DccDocument?> getDocumentById(
      String documentId,
      ) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq('id', documentId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return _fromRow(
      Map<String, dynamic>.from(response),
    );
  }

  // ------------------------------------------------------------
  // GET DOCUMENTS FOR HOD
  // ------------------------------------------------------------
  static Future<List<DccDocument>> getDocumentsForHod(
      String hodEmail,
      ) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq(
      'hod_email',
      hodEmail.trim().toLowerCase(),
    )
        .order(
      'revision_date',
      ascending: false,
    );

    return (response as List)
        .map(
          (row) => _fromRow(
        Map<String, dynamic>.from(row),
      ),
    )
        .toList();
  }

  // ------------------------------------------------------------
  // GET DOCUMENTS CREATED BY USER
  // ------------------------------------------------------------
  static Future<List<DccDocument>> getDocumentsByUser(
      String email,
      ) async {
    final response = await _client
        .from(tableName)
        .select()
        .eq(
      'created_by_email',
      email.trim().toLowerCase(),
    )
        .order(
      'revision_date',
      ascending: false,
    );

    return (response as List)
        .map(
          (row) => _fromRow(
        Map<String, dynamic>.from(row),
      ),
    )
        .toList();
  }

  // ------------------------------------------------------------
  // UPDATE DOCUMENT
  // ------------------------------------------------------------
  static Future<void> updateDocument(
      DccDocument document,
      ) async {
    await _client
        .from(tableName)
        .update(
      _toRow(document),
    )
        .eq(
      'id',
      document.id,
    );
  }

  // ------------------------------------------------------------
  // UPDATE ATTACHMENT
  // ------------------------------------------------------------
  static Future<void> updateSourceFile({
    required String documentId,
    required String attachmentPath,
    required String attachmentName,
  }) async {
    await _client
        .from(tableName)
        .update({
      'attachment_path': attachmentPath,
      'attachment_name': attachmentName,
      'updated_at':
      DateTime.now().toIso8601String(),
    })
        .eq(
      'id',
      documentId,
    );
  }

  // ------------------------------------------------------------
  // UPDATE STATUS
  // ------------------------------------------------------------
  static Future<void> updateStatus({
    required String documentId,
    required String status,
    String? rejectionReason,
  }) async {
    final data = <String, dynamic>{
      'status': status,
      'updated_at':
      DateTime.now().toIso8601String(),
    };

    if (rejectionReason != null) {
      data['rejection_reason'] =
          rejectionReason;
    }

    await _client
        .from(tableName)
        .update(data)
        .eq(
      'id',
      documentId,
    );
  }

  // ------------------------------------------------------------
  // DELETE DOCUMENT
  // ------------------------------------------------------------
  static Future<void> deleteDocument(
      DccDocument document,
      ) async {
    final documentId = document.id.trim();

    if (documentId.isEmpty) {
      throw Exception(
        'Document ID is missing.',
      );
    }

    // Delete the released PDF from Supabase Storage first.
    final releasedPdfPath =
    document.releasedPdfPath.trim();

    if (releasedPdfPath.isNotEmpty) {
      try {
        await DccStorageService.deleteFile(
          releasedPdfPath,
        );
      } catch (e) {
        throw Exception(
          'Unable to delete the released PDF: $e',
        );
      }
    }

    // Delete the document record.
    await _client
        .from(tableName)
        .delete()
        .eq(
      'id',
      documentId,
    );
  }
}