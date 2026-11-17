import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/audit/audit_master_name.dart';

class AuditMastersService {
  AuditMastersService._();

  static SupabaseClient get _db => Supabase.instance.client;

  static Future<List<AuditMasterName>> fetchAll({bool activeOnly = true}) async {
    var query = _db.from('audit_masters').select();
    if (activeOnly) {
      query = query.eq('active', true);
    }
    final rows = await query.order('master_name', ascending: true);
    return (rows as List)
        .map((r) => AuditMasterName.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  static Future<List<AuditMasterName>> fetchByType(
    String auditType, {
    bool activeOnly = true,
  }) async {
    var query =
        _db.from('audit_masters').select().eq('audit_type', auditType);
    if (activeOnly) {
      query = query.eq('active', true);
    }
    final rows = await query.order('master_name', ascending: true);
    return (rows as List)
        .map((r) => AuditMasterName.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  static Future<AuditMasterName> create({
    required String masterName,
    required String auditType,
  }) async {
    final row = await _db
        .from('audit_masters')
        .insert({
          'master_name': masterName.trim(),
          'audit_type': auditType,
          'active': true,
        })
        .select()
        .single();
    return AuditMasterName.fromMap(row);
  }

  static Future<void> update({
    required String masterId,
    required String masterName,
    required bool active,
  }) async {
    await _db.from('audit_masters').update({
      'master_name': masterName.trim(),
      'active': active,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('master_id', masterId);
  }

  static Future<void> delete(String masterId) async {
    await _db.from('audit_masters').delete().eq('master_id', masterId);
  }
}
