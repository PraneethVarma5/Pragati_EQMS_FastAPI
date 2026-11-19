import '../../models/dcc/dcc_document_request.dart';
import 'dcc_api_client.dart';

class DccDocumentRequestService {
  static const String table = 'dcc_document_requests';
  static DccDocumentRequest _from(dynamic row) => DccDocumentRequest.fromMap(Map<String,dynamic>.from(row as Map));
  static Future<void> createRequest({required String documentName, required String userName, required String userEmail, required String description}) async {
    await DccApiClient.post('/document-requests', body: {'data': {'document_name': documentName.trim(), 'user_name': userName.trim(), 'user_email': userEmail.trim(), 'description': description.trim(), 'status':'PENDING'}});
  }
  static Future<List<DccDocumentRequest>> getPendingRequests() async => (await DccApiClient.get('/document-requests', query: {'status_filter':'PENDING'}) as List).map(_from).toList();
  static Future<List<DccDocumentRequest>> getAllRequests() async => (await DccApiClient.get('/document-requests') as List).map(_from).toList();
  static Future<List<DccDocumentRequest>> getRequestsForUser(String userEmail) async => (await DccApiClient.get('/document-requests') as List).map(_from).toList();
  static Future<void> updateDccDetails({required String requestId, required String documentNo, required String documentName, required String documentType, required String department, required String candidateName, required String candidateEmail}) async {
    await DccApiClient.patch('/document-requests/${Uri.encodeComponent(requestId)}', body: {'data': {'document_no':documentNo.trim(),'document_name':documentName.trim(),'document_type':documentType.trim(),'department':department.trim(),'candidate_name':candidateName.trim(),'candidate_email':candidateEmail.trim()}});
  }
  static Future<void> markAsNotified(String requestId) async => DccApiClient.patch('/document-requests/${Uri.encodeComponent(requestId)}', body: {'data': {'status':'NOTIFIED','notified_at':DateTime.now().toIso8601String()}});
  static Future<void> markAsUploaded(String requestId) async => DccApiClient.patch('/document-requests/${Uri.encodeComponent(requestId)}', body: {'data': {'status':'UPLOADED'}});
  static Future<DccDocumentRequest?> getRequest(String requestId) async { try { return _from(await DccApiClient.get('/document-requests/${Uri.encodeComponent(requestId)}')); } catch (_) { return null; } }
}
