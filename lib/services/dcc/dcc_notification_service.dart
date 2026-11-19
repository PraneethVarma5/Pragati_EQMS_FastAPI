import '../../models/dcc/dcc_notification.dart';
import 'dcc_api_client.dart';
import 'dcc_user_service.dart';
class DccNotificationService {
 static const String tableName='dcc_notifications';
 static Map<String,dynamic> _toRow(DccNotification n)=>{'id':n.id,'recipient_email':n.recipientEmail,'title':n.title,'message':n.message,'type':n.type,'document_no':n.documentNo,'document_request_id':n.documentRequestId,'created_at':n.createdAt.toIso8601String(),'is_read':n.isRead};
 static DccNotification _from(dynamic r){final m=Map<String,dynamic>.from(r as Map);return DccNotification(id:m['id']?.toString()??'',recipientEmail:m['recipient_email']?.toString()??'',title:m['title']?.toString()??'',message:m['message']?.toString()??'',type:m['type']?.toString()??'GENERAL',documentNo:m['document_no']?.toString()??'',documentRequestId:m['document_request_id']?.toString(),createdAt:DateTime.tryParse(m['created_at']?.toString()??'')??DateTime.now(),isRead:m['is_read']==true);}
 static Future<void> addNotification(DccNotification n) async=>DccApiClient.post('/notifications',body:{'data':_toRow(n)});
 static Future<List<DccNotification>> getNotificationsForUser(
     String email) async {
  final response = await DccApiClient.get('/notifications');

  if (response is! List) {
   throw Exception('Notifications API returned an unexpected response.');
  }

  final normalizedEmail = email.trim().toLowerCase();

  return response
      .map(_from)
      .where(
       (notification) =>
   notification.recipientEmail.trim().toLowerCase() ==
       normalizedEmail,
  )
      .toList();
 }
 static Future<int> getUnreadCount(String email) async=>(await getNotificationsForUser(email)).where((n)=>!n.isRead).length;
 static Future<void> markAsRead(String id) async=>DccApiClient.patch('/notifications/${Uri.encodeComponent(id)}',body:{'data':{'is_read':true}});
 static Future<void> markAllAsRead(String email) async=>DccApiClient.post('/notifications/read-all');
 static Future<void> deleteNotification(String id) async=>DccApiClient.delete('/notifications/${Uri.encodeComponent(id)}');
 static Future<void> clearAllForUser(String email) async=>DccApiClient.delete('/notifications/clear');
 static Future<void> notifyAllDcc({required String title,required String message,required String type,String documentNo=''}) async {final users=await DccUserService.getUsers();final seen=<String>{};for(final u in users.where((u)=>u.active&&u.role.toUpperCase()=='DCC')){final e=u.email.trim().toLowerCase();if(e.isEmpty||!seen.add(e))continue;await addNotification(DccNotification(id:'DCC_${type}_${DateTime.now().microsecondsSinceEpoch}_$e',recipientEmail:e,title:title,message:message,type:type,documentNo:documentNo,createdAt:DateTime.now()));}}
 static Future<void> createDocumentUploadNotification({required String userEmail,required String documentRequestId,required String documentName}) async=>addNotification(DccNotification(id:'DOC_UPLOAD_${documentRequestId}_${DateTime.now().microsecondsSinceEpoch}',recipientEmail:userEmail.trim().toLowerCase(),title:'Document Upload Required',message:'DCC has prepared "$documentName". Click to upload the document.',type:'DOCUMENT_UPLOAD',documentRequestId:documentRequestId,createdAt:DateTime.now()));
}
