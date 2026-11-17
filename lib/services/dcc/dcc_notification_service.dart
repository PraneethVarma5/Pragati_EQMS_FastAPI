import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/dcc/dcc_notification.dart';
import 'dcc_user_service.dart';

/// DCC notifications, backed by the Supabase "dcc_notifications"
/// table.
///
/// This used to be a local-only Hive box. That meant every
/// notification — including the "notify all DCC" broadcasts —
/// was only ever written into the browser of whoever triggered it
/// (the User submitting a document, the HOD approving a DMR,
/// etc.), never into the actual DCC officers' own browsers. In
/// practice that showed up as "only one DCC member gets
/// notified" — really nobody was reliably getting notified except
/// by coincidence of shared browser storage during testing. Moving
/// this to Supabase (same fix already applied to DMR requests and
/// activity logging) makes every notification visible to whichever
/// account it was actually addressed to, in any browser.
///
/// Method signatures are unchanged from the old Hive version, so
/// every existing call site keeps working without modification.
class DccNotificationService {
  static const String tableName = 'dcc_notifications';

  static SupabaseClient get _client => Supabase.instance.client;

  static Map<String, dynamic> _toRow(DccNotification notification) {
    return {
      'id': notification.id,
      'recipient_email': notification.recipientEmail,
      'title': notification.title,
      'message': notification.message,
      'type': notification.type,
      'document_no': notification.documentNo,
      'document_request_id': notification.documentRequestId,
      'created_at': notification.createdAt.toIso8601String(),
      'is_read': notification.isRead,
    };
  }

  static DccNotification _fromRow(Map<String, dynamic> row) {
    return DccNotification(
      id: row['id']?.toString() ?? '',
      recipientEmail: row['recipient_email']?.toString() ?? '',
      title: row['title']?.toString() ?? '',
      message: row['message']?.toString() ?? '',
      type: row['type']?.toString() ?? 'GENERAL',
      documentNo: row['document_no']?.toString() ?? '',
      documentRequestId: row['document_request_id']?.toString(),
      createdAt: DateTime.tryParse(
            row['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
      isRead: row['is_read'] == true,
    );
  }

  static Future<void> addNotification(
    DccNotification notification,
  ) async {
    await _client.from(tableName).insert(_toRow(notification));
  }

  static Future<List<DccNotification>> getNotificationsForUser(
    String email,
  ) async {
    final rows = await _client
        .from(tableName)
        .select()
        .ilike('recipient_email', email.trim())
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => _fromRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<int> getUnreadCount(String email) async {
    final rows = await _client
        .from(tableName)
        .select('id')
        .ilike('recipient_email', email.trim())
        .eq('is_read', false);

    return (rows as List).length;
  }

  static Future<void> markAsRead(String notificationId) async {
    await _client
        .from(tableName)
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  static Future<void> markAllAsRead(String email) async {
    await _client
        .from(tableName)
        .update({'is_read': true})
        .ilike('recipient_email', email.trim())
        .eq('is_read', false);
  }

  static Future<void> deleteNotification(
    String notificationId,
  ) async {
    await _client.from(tableName).delete().eq('id', notificationId);
  }

  static Future<void> clearAllForUser(String email) async {
    await _client
        .from(tableName)
        .delete()
        .ilike('recipient_email', email.trim());
  }

  static Future<void> notifyAllDcc({
    required String title,
    required String message,
    required String type,
    String documentNo = '',
  }) async {
    final users = await DccUserService.getUsers();

    final dccUsers = users.where((user) {
      final userType = user.role.trim().toUpperCase();

      return user.active &&
          userType == 'DCC' &&
          user.email.trim().isNotEmpty;
    }).toList();

    final sentEmails = <String>{};

    final rows = <Map<String, dynamic>>[];

    for (final user in dccUsers) {
      final email = user.email.trim().toLowerCase();

      if (sentEmails.contains(email)) {
        continue;
      }

      sentEmails.add(email);

      final notificationId = 'DCC_${type}_${documentNo}_'
          '${email}_${DateTime.now().microsecondsSinceEpoch}';

      rows.add(
        _toRow(
          DccNotification(
            id: notificationId,
            recipientEmail: email,
            title: title,
            message: message,
            type: type,
            documentNo: documentNo,
            createdAt: DateTime.now(),
          ),
        ),
      );
    }

    if (rows.isEmpty) {
      return;
    }

    await _client.from(tableName).insert(rows);
  }

  static Future<void> createDocumentUploadNotification({
    required String userEmail,
    required String documentRequestId,
    required String documentName,
  }) async {
    final notificationId = 'DOC_UPLOAD_${documentRequestId}_'
        '${DateTime.now().microsecondsSinceEpoch}';

    await addNotification(
      DccNotification(
        id: notificationId,
        recipientEmail: userEmail.trim().toLowerCase(),
        title: 'Document Upload Required',
        message: 'DCC has prepared "$documentName". '
            'Click to upload the document.',
        type: 'DOCUMENT_UPLOAD',
        documentRequestId: documentRequestId,
        createdAt: DateTime.now(),
      ),
    );
  }
}
