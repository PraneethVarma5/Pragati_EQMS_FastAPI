import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/audit/audit_auditor.dart';

class AuditAuditorService {
  AuditAuditorService._();

  static SupabaseClient get _db => Supabase.instance.client;

  static Future<List<AuditAuditor>> fetchAll({bool activeOnly = true}) async {
    var query = _db.from('audit_auditors').select();
    if (activeOnly) {
      query = query.eq('active', true);
    }
    final rows = await query.order('auditor_name', ascending: true);
    return (rows as List)
        .map((r) => AuditAuditor.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  static Future<AuditAuditor> create({
    required String auditorName,
    String? employeeId,
    String? department,
    required String email,
  }) async {
    final row = await _db
        .from('audit_auditors')
        .insert({
          'auditor_name': auditorName.trim(),
          'employee_id': employeeId?.trim(),
          'department': department?.trim(),
          'email': email.trim(),
          'active': true,
        })
        .select()
        .single();
    return AuditAuditor.fromMap(row);
  }

  static Future<void> update({
    required String auditorId,
    required String auditorName,
    String? employeeId,
    String? department,
    required String email,
    required bool active,
  }) async {
    await _db.from('audit_auditors').update({
      'auditor_name': auditorName.trim(),
      'employee_id': employeeId?.trim(),
      'department': department?.trim(),
      'email': email.trim(),
      'active': active,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('auditor_id', auditorId);
  }

  static Future<void> delete(String auditorId) async {
    await _db.from('audit_auditors').delete().eq('auditor_id', auditorId);
  }
}
