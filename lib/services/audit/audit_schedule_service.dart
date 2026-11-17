import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/audit/audit_schedule.dart';

class AuditScheduleService {
  AuditScheduleService._();

  static SupabaseClient get _db => Supabase.instance.client;

  static Future<List<AuditSchedule>> fetchAll() async {
    final rows = await _db
        .from('audit_schedules')
        .select()
        .order('audit_date', ascending: false);
    return (rows as List)
        .map((r) => AuditSchedule.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  static Future<List<AuditSchedule>> fetchByType(String auditType) async {
    final rows = await _db
        .from('audit_schedules')
        .select()
        .eq('audit_type', auditType)
        .order('audit_date', ascending: false);
    return (rows as List)
        .map((r) => AuditSchedule.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  static Future<List<AuditSchedule>> fetchForDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T').first;
    final rows = await _db
        .from('audit_schedules')
        .select()
        .eq('audit_date', dateStr);
    return (rows as List)
        .map((r) => AuditSchedule.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  static Future<AuditSchedule> create(AuditSchedule schedule) async {
    final row = await _db
        .from('audit_schedules')
        .insert(schedule.toInsertMap())
        .select()
        .single();
    return AuditSchedule.fromMap(row);
  }

  static Future<void> updateStatus({
    required String scheduleId,
    required String status,
  }) async {
    await _db.from('audit_schedules').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('schedule_id', scheduleId);
  }

  static Future<void> delete(String scheduleId) async {
    await _db
        .from('audit_schedules')
        .delete()
        .eq('schedule_id', scheduleId);
  }
}
