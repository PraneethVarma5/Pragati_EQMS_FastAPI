import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/dcc/dcc_document_request.dart';

class DccDocumentRequestService {
  static final SupabaseClient _supabase =
      Supabase.instance.client;

  static const String table = 'dcc_document_requests';

  /// USER creates a document request
  static Future<void> createRequest({
    required String documentName,
    required String userName,
    required String userEmail,
    required String description,
  }) async {
    await _supabase.from(table).insert({
      'document_name': documentName.trim(),
      'user_name': userName.trim(),
      'user_email': userEmail.trim(),
      'description': description.trim(),
      'status': 'PENDING',
    });
  }

  /// DCC loads pending requests
  static Future<List<DccDocumentRequest>> getPendingRequests() async {
    final response = await _supabase
        .from(table)
        .select()
        .eq('status', 'PENDING')
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (e) => DccDocumentRequest.fromMap(
        Map<String, dynamic>.from(e),
      ),
    )
        .toList();
  }

  /// DCC loads all requests
  static Future<List<DccDocumentRequest>> getAllRequests() async {
    final response = await _supabase
        .from(table)
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (e) => DccDocumentRequest.fromMap(
        Map<String, dynamic>.from(e),
      ),
    )
        .toList();
  }
  /// USER loads all document requests created
  /// by the currently logged-in user.
  static Future<List<DccDocumentRequest>>
  getRequestsForUser(
      String userEmail,
      ) async {

    final email =
    userEmail.trim().toLowerCase();

    if (email.isEmpty) {
      return [];
    }

    final response = await _supabase
        .from(table)
        .select()
        .eq('user_email', email)
        .order(
      'created_at',
      ascending: false,
    );

    return (response as List)
        .map(
          (e) => DccDocumentRequest.fromMap(
        Map<String, dynamic>.from(e),
      ),
    )
        .toList();
  }

  /// DCC saves the master-data details against the request.
  ///
  /// Candidate name/email are intentionally supplied separately
  /// because DCC is allowed to edit them.
  static Future<void> updateDccDetails({
    required String requestId,
    required String documentNo,
    required String documentName,
    required String documentType,
    required String department,
    required String candidateName,
    required String candidateEmail,
  }) async {
    await _supabase
        .from(table)
        .update({
      'document_no': documentNo.trim(),
      'document_name': documentName.trim(),
      'document_type': documentType.trim(),
      'department': department.trim(),
      'candidate_name': candidateName.trim(),
      'candidate_email': candidateEmail.trim(),
    })
        .eq('id', requestId);
  }

  /// Marks the request as notified.
  static Future<void> markAsNotified(
      String requestId,
      ) async {
    await _supabase
        .from(table)
        .update({
      'status': 'NOTIFIED',
      'notified_at': DateTime.now().toIso8601String(),
    })
        .eq('id', requestId);
  }

  /// Used after successful document submission.
  static Future<void> markAsUploaded(
      String requestId,
      ) async {
    await _supabase
        .from(table)
        .update({
      'status': 'UPLOADED',
    })
        .eq('id', requestId);
  }

  /// Get a single request.
  static Future<DccDocumentRequest?> getRequest(
      String requestId,
      ) async {
    final response = await _supabase
        .from(table)
        .select()
        .eq('id', requestId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return DccDocumentRequest.fromMap(
      Map<String, dynamic>.from(response),
    );
  }
}