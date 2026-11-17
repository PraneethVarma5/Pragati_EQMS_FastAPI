import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/dcc/dcc_master_data.dart';

/// Stores document metadata DCC enters ahead of the New Document
/// process, keyed uniquely by document_no — see migration 5 for
/// why that alone guarantees no duplicates and makes "a new
/// revision replaces the old one" automatic (there's only ever one
/// row per document number).
class DccMasterDataService {
  static const String tableName = 'dcc_master_data';

  static SupabaseClient get _client => Supabase.instance.client;

  static Map<String, dynamic> _toRow(DccMasterData entry) {
    return {
      'document_no': entry.documentNo,
      'document_name': entry.documentName,
      'document_type': entry.documentType,
      'department': entry.department,
      'candidate_name': entry.candidateName,
      'candidate_email': entry.candidateEmail,
      'created_by_name': entry.createdByName,
      'created_by_email': entry.createdByEmail,
      'revision': entry.revision,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  static DccMasterData _fromRow(Map<String, dynamic> row) {
    return DccMasterData(
      documentNo: row['document_no']?.toString() ?? '',
      documentName: row['document_name']?.toString() ?? '',
      documentType: row['document_type']?.toString() ?? '',
      department: row['department']?.toString() ?? '',
      candidateName: row['candidate_name']?.toString() ?? '',
      candidateEmail: row['candidate_email']?.toString() ?? '',
      createdByName: row['created_by_name']?.toString() ?? '',
      createdByEmail: row['created_by_email']?.toString() ?? '',
      revision: int.tryParse(row['revision']?.toString() ?? '') ?? 0,
    );
  }

  /// Adds or updates a master data entry. Because document_no is
  /// the primary key, entering the same document number again
  /// (e.g. for a new revision) simply replaces the existing entry
  /// rather than creating a duplicate.
  static Future<void> upsertEntry(
    DccMasterData entry, {
    int? manualRevision,
  }) async {
    final documentNo = entry.documentNo.trim();
    if (documentNo.isEmpty) {
      throw Exception('Document No is required.');
    }

    final existing = await getByDocumentNo(documentNo);
    final revision = manualRevision ?? ((existing?.revision ?? -1) + 1);

    final resolved = DccMasterData(
      documentNo: documentNo,
      documentName: entry.documentName,
      documentType: entry.documentType,
      department: entry.department,
      candidateName: entry.candidateName,
      candidateEmail: entry.candidateEmail,
      createdByName: entry.createdByName,
      createdByEmail: entry.createdByEmail,
      revision: revision < 0 ? 0 : revision,
    );

    await _client
        .from(tableName)
        .upsert(_toRow(resolved), onConflict: 'document_no');
  }

  static Future<List<DccMasterData>> getAllEntries() async {
    final response = await _client
        .from(tableName)
        .select()
        .order('updated_at', ascending: false);

    return (response as List)
        .map((row) => _fromRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  /// Looks up a single entry by document number — this is what
  /// powers the New Document screen's auto-fill.
  static Future<DccMasterData?> getByDocumentNo(
      String documentNo,
      ) async {
    final trimmed = documentNo.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    final response = await _client
        .from(tableName)
        .select()
        .eq('document_no', trimmed)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return _fromRow(Map<String, dynamic>.from(response));
  }

  static Future<void> deleteEntry(String documentNo) async {
    await _client
        .from(tableName)
        .delete()
        .eq('document_no', documentNo.trim());
  }
}
