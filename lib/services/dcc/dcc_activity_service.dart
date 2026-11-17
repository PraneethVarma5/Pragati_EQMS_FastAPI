import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/dcc/dcc_activity.dart';

/// DCC activity log, backed by the Supabase "dcc_activities" table.
///
/// This used to be a local Hive box, which meant activity only
/// ever showed up in the browser that performed it — a DCC/HOD
/// checking "recent activity" from a different machine, or after
/// clearing browser storage, saw nothing. Moving it to Supabase
/// (same fix already applied to DMR requests) makes it consistent
/// everywhere: every dashboard reads the same underlying log.
///
/// Method signatures are unchanged from the old Hive version, so
/// every existing call site (login, new document, DMR actions,
/// document review, etc.) keeps working without modification.
class DccActivityService {
  static const String tableName = 'dcc_activities';

  static SupabaseClient get _client => Supabase.instance.client;

  static Map<String, dynamic> _toRow(DccActivity activity) {
    return {
      'id': activity.id,
      'user_email': activity.userEmail,
      'user_name': activity.userName,
      'action': activity.action,
      'description': activity.description,
      'document_no': activity.documentNo,
      'timestamp': activity.timestamp.toIso8601String(),
    };
  }

  static DccActivity _fromRow(Map<String, dynamic> row) {
    return DccActivity(
      id: row['id']?.toString() ?? '',
      userEmail: row['user_email']?.toString() ?? '',
      userName: row['user_name']?.toString() ?? '',
      action: row['action']?.toString() ?? '',
      description: row['description']?.toString() ?? '',
      documentNo: row['document_no']?.toString() ?? '',
      timestamp: DateTime.tryParse(
            row['timestamp']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  static Future<void> addActivity(DccActivity activity) async {
    await _client.from(tableName).insert(_toRow(activity));
  }

  static Future<List<DccActivity>> getActivitiesForUser(
    String email,
  ) async {
    final rows = await _client
        .from(tableName)
        .select()
        .ilike('user_email', email.trim())
        .order('timestamp', ascending: false);

    return (rows as List)
        .map((row) => _fromRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  /// All activity across every user — used for the HOD/DCC-facing
  /// full activity history screen (department-wide oversight),
  /// as opposed to [getActivitiesForUser]'s "my own activity" view.
  static Future<List<DccActivity>> getAllActivities({
    int limit = 200,
  }) async {
    final rows = await _client
        .from(tableName)
        .select()
        .order('timestamp', ascending: false)
        .limit(limit);

    return (rows as List)
        .map((row) => _fromRow(Map<String, dynamic>.from(row)))
        .toList();
  }
}
