import 'package:uuid/uuid.dart';

import '../../models/audit/audit_progress_model.dart';
import 'audit_db_service.dart';

class AuditProgressService {
  AuditProgressService._();

  static final _db =
      AuditDbService.client;

  static const _uuid = Uuid();

  static Future<List<AuditProgressModel>>
  getProgress(
      String auditId,
      ) async {
    final response = await _db
        .from(AuditDbService.progress)
        .select()
        .eq(
      'audit_id',
      auditId,
    );

    return List<Map<String, dynamic>>
        .from(response)
        .map(AuditProgressModel.fromMap)
        .toList();
  }

  static Future<void>
  saveProgress({
    required String auditId,
    required String category,
    required double timeTakenHours,
    required bool completed,
  }) async {
    final existing =
    await _db
        .from(AuditDbService.progress)
        .select('progress_id')
        .eq(
      'audit_id',
      auditId,
    )
        .eq(
      'category',
      category,
    )
        .maybeSingle();

    final progressId =
        existing?['progress_id']
            ?.toString() ??
            _uuid.v4();

    await _db
        .from(AuditDbService.progress)
        .upsert(
      {
        'progress_id': progressId,
        'audit_id': auditId,
        'category': category,
        'time_taken_hours':
        timeTakenHours,
        'completed':
        completed,
        'completed_at':
        completed
            ? DateTime.now()
            .toIso8601String()
            : null,
      },
      onConflict:
      'audit_id,category',
    );
  }
}