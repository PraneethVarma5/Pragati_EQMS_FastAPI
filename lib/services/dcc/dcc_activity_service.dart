import '../../models/dcc/dcc_activity.dart';
import 'dcc_api_client.dart';
import 'dcc_session.dart';
import 'package:flutter/foundation.dart';

/// DCC activity log through FastAPI. No direct Supabase/PostgREST calls.
class DccActivityService {
  static DccActivity _fromRow(Map<String, dynamic> row) {
    return DccActivity(
      id: row['id']?.toString() ?? '',
      userEmail:
      (row['user_email'] ?? row['userEmail'])?.toString() ?? '',
      userName:
      (row['user_name'] ?? row['userName'])?.toString() ?? '',
      action: row['action']?.toString() ?? '',
      description: row['description']?.toString() ?? '',
      documentNo:
      (row['document_no'] ?? row['documentNo'])?.toString() ?? '',
      timestamp: DateTime.tryParse(
        (row['timestamp'] ?? row['created_at'])?.toString() ?? '',
      ) ??
          DateTime.now(),
    );
  }
  static Map<String, dynamic> _toRow(DccActivity activity) => {
        'id': activity.id,
        'user_email': activity.userEmail,
        'user_name': activity.userName,
        'action': activity.action,
        'description': activity.description,
        'document_no': activity.documentNo,
        'timestamp': activity.timestamp.toIso8601String(),
      };

  static Future<void> addActivity(DccActivity activity) async {
    await DccApiClient.post(
      '/activities',
      body: {'data': _toRow(activity)},
    );
  }

  static Future<List<DccActivity>> getActivitiesForUser(String email) async {
    final role = DccSession.currentUser?.role.toUpperCase() ?? '';
    final query = <String, String>{};

    if (role == 'ADMIN' || role == 'DCC') {
      query['email'] = email.trim();
    }

    final response = await DccApiClient.get(
      '/activities',
      query: query.isEmpty ? null : query,
    );

    debugPrint('DCC ACTIVITY ROLE: $role');
    debugPrint('DCC ACTIVITY EMAIL: $email');
    debugPrint('DCC ACTIVITY RESPONSE TYPE: ${response.runtimeType}');
    debugPrint('DCC ACTIVITY RESPONSE: $response');

    if (response is! List) {
      throw Exception(
        'Activity API returned ${response.runtimeType}, expected List.',
      );
    }

    final activities = response
        .map(
          (row) => _fromRow(
        Map<String, dynamic>.from(row as Map),
      ),
    )
        .toList();

    debugPrint('DCC ACTIVITY PARSED COUNT: ${activities.length}');

    return activities;
  }

  static Future<List<DccActivity>> getAllActivities({int limit = 200}) async {
    final rows = await DccApiClient.get(
      '/activities',
      query: {'limit': limit.toString()},
    ) as List;
    return rows
        .map((row) => _fromRow(Map<String, dynamic>.from(row as Map)))
        .toList();
  }
}
