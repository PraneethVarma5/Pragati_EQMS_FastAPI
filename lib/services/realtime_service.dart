import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase Realtime's Postgres Changes
/// feature. A screen calls [RealtimeService.subscribeToTable] in
/// initState and [RealtimeChannel.unsubscribe] (via the returned
/// channel) in dispose — this is what makes lists refresh live
/// across different users/tabs instead of needing a manual reload.
///
/// Requires each subscribed table to be added to the
/// "supabase_realtime" publication in Postgres — see the SQL
/// migration files for which tables this has been enabled on.
class RealtimeService {
  RealtimeService._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Subscribes to INSERT/UPDATE/DELETE events on [table]. Calls
  /// [onInsert]/[onUpdate]/[onDelete] with the affected row as a
  /// Map whenever a matching event arrives. Returns the channel so
  /// the caller can unsubscribe when its screen is disposed.
  static RealtimeChannel subscribeToTable({
    required String table,
    void Function(Map<String, dynamic> row)? onInsert,
    void Function(Map<String, dynamic> row)? onUpdate,
    void Function(Map<String, dynamic> row)? onDelete,
  }) {
    final channel = _client.channel(
      'public:$table:${DateTime.now().microsecondsSinceEpoch}',
    );

    if (onInsert != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: table,
        callback: (payload) {
          onInsert(Map<String, dynamic>.from(payload.newRecord));
        },
      );
    }

    if (onUpdate != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: table,
        callback: (payload) {
          onUpdate(Map<String, dynamic>.from(payload.newRecord));
        },
      );
    }

    if (onDelete != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: table,
        callback: (payload) {
          onDelete(Map<String, dynamic>.from(payload.oldRecord));
        },
      );
    }

    channel.subscribe();

    return channel;
  }
}
