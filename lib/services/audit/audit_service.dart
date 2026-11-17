import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/audit/audit.dart';
import '../../models/audit/audit_checklist_answer.dart';
import '../../models/audit/audit_finding.dart';
import '../../models/audit/audit_category_progress.dart';
import '../../models/audit/finding_category.dart';

class AuditService {
  AuditService._();

  static SupabaseClient get _db => Supabase.instance.client;

  // ============================================================
  // Audits
  // ============================================================

  static Future<List<Audit>> fetchAllAudits() async {
    final rows =
        await _db.from('audits').select().order('created_at', ascending: false);
    return (rows as List)
        .map((r) => Audit.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  static Future<Audit> fetchAudit(String auditId) async {
    final row =
        await _db.from('audits').select().eq('audit_id', auditId).single();
    return Audit.fromMap(row);
  }

  /// Starts a new audit run from the "Audit Details" form. Category
  /// progress rows are seeded (one per section, completed = false) so the
  /// checklist screen and "all categories complete" gate have something to
  /// key off of from the very first save.
  static Future<Audit> startAudit({
    required String auditType,
    required String vendor,
    required String site,
    required String lob,
    required String program,
    required String line,
    required String apn,
    required DateTime auditDate,
    required String auditorName,
    String? auditorEmail,
    required double totalTimeTakenHours,
    List<String> sectionNames = const [],
    String? scheduleId,
  }) async {
    final row = await _db
        .from('audits')
        .insert({
          'audit_type': auditType,
          'vendor': vendor,
          'site': site,
          'lob': lob,
          'program': program,
          'line': line,
          'apn': apn,
          'audit_date': auditDate.toIso8601String().split('T').first,
          'auditor_name': auditorName,
          'auditor_email': auditorEmail,
          'total_time_taken_hours': totalTimeTakenHours,
          'status': 'In Progress',
          'schedule_id': scheduleId,
          'started_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    final audit = Audit.fromMap(row);

    if (sectionNames.isNotEmpty) {
      await _db.from('audit_category_progress').upsert(
            sectionNames
                .map((name) => {
                      'audit_id': audit.auditId,
                      'category': name,
                      'time_taken_hours': 0,
                      'completed': false,
                    })
                .toList(),
            onConflict: 'audit_id,category',
          );
    }

    if (scheduleId != null) {
      await _db.from('audit_schedules').update({
        'status': 'In Progress',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('schedule_id', scheduleId);
    }

    return audit;
  }

  static Future<void> markAuditCompleted(String auditId) async {
    await _db.from('audits').update({
      'status': 'Completed',
      'finished_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('audit_id', auditId);

    final audit = await fetchAudit(auditId);
    if (audit.scheduleId != null) {
      await _db.from('audit_schedules').update({
        'status': 'Completed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('schedule_id', audit.scheduleId!);
    }
  }

  // ============================================================
  // Category progress
  // ============================================================

  static Future<List<AuditCategoryProgress>> fetchCategoryProgress(
    String auditId,
  ) async {
    final rows = await _db
        .from('audit_category_progress')
        .select()
        .eq('audit_id', auditId);
    return (rows as List)
        .map((r) => AuditCategoryProgress.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  static Future<void> markCategoryCompleted({
    required String auditId,
    required String category,
    required bool completed,
  }) async {
    await _db.from('audit_category_progress').upsert({
      'audit_id': auditId,
      'category': category,
      'completed': completed,
      'completed_at': completed ? DateTime.now().toIso8601String() : null,
    }, onConflict: 'audit_id,category');
  }

  /// True once every seeded category for this audit is marked completed.
  /// This is the gate for "MIL report / Audit summary" becoming available.
  static Future<bool> areAllCategoriesComplete(String auditId) async {
    final progress = await fetchCategoryProgress(auditId);
    if (progress.isEmpty) return false;
    return progress.every((p) => p.completed);
  }

  // ============================================================
  // Checklist answers (every question, Yes or No)
  // ============================================================

  static Future<List<AuditChecklistAnswer>> fetchAnswersForSection({
    required String auditId,
    required String section,
  }) async {
    final rows = await _db
        .from('audit_checklist_answers')
        .select()
        .eq('audit_id', auditId)
        .eq('section', section)
        .order('question_number', ascending: true);
    return (rows as List)
        .map((r) => AuditChecklistAnswer.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  static Future<List<AuditChecklistAnswer>> fetchAllAnswers(
    String auditId,
  ) async {
    final rows = await _db
        .from('audit_checklist_answers')
        .select()
        .eq('audit_id', auditId)
        .order('question_number', ascending: true);
    return (rows as List)
        .map((r) => AuditChecklistAnswer.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Saves (upserts) one answer, and keeps `audit_findings` in sync:
  /// - answer == 'No'  -> upsert a matching finding row
  /// - answer == 'Yes' -> remove any finding row that used to exist for it
  static Future<void> saveAnswer(AuditChecklistAnswer answer) async {
    final savedAnswerRow = await _db
        .from('audit_checklist_answers')
        .upsert(
          answer.toUpsertMap(),
          onConflict: 'audit_id,checklist_item_id',
        )
        .select()
        .single();

    final savedAnswerId = savedAnswerRow['answer_id'] as String;

    if (answer.answer == 'No') {
      await _db.from('audit_findings').upsert({
        'audit_id': answer.auditId,
        'answer_id': savedAnswerId,
        'section': answer.section,
        'checklist_item_id': answer.checklistItemId,
        'question_number': answer.questionNumber,
        'question': answer.question,
        'issue': answer.description ?? '',
        'finding_category': answer.category?.value,
      }, onConflict: 'answer_id');
    } else {
      await _db
          .from('audit_findings')
          .delete()
          .eq('audit_id', answer.auditId)
          .eq('checklist_item_id', answer.checklistItemId);
    }
  }

  // ============================================================
  // Findings (MIL report detail fields)
  // ============================================================

  static Future<List<AuditFinding>> fetchFindings(String auditId) async {
    final rows = await _db
        .from('audit_findings')
        .select()
        .eq('audit_id', auditId)
        .order('question_number', ascending: true);
    return (rows as List)
        .map((r) => AuditFinding.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, List<AuditFinding>>> fetchFindingsForAudits(
    List<String> auditIds,
  ) async {
    if (auditIds.isEmpty) return {};
    final rows = await _db
        .from('audit_findings')
        .select()
        .filter('audit_id', 'in', '(${auditIds.join(',')})');
    final map = <String, List<AuditFinding>>{};
    for (final r in (rows as List)) {
      final finding = AuditFinding.fromMap(r as Map<String, dynamic>);
      map.putIfAbsent(finding.auditId, () => []).add(finding);
    }
    return map;
  }

  static Future<void> updateFindingDetail(AuditFinding finding) async {
    await _db
        .from('audit_findings')
        .update(finding.toUpdateMap())
        .eq('finding_id', finding.findingId);
  }

  // ============================================================
  // MIL numbering — {yyyy-MM-dd}-{n}, n increments per day across all
  // audit types, generated the moment an audit is completed.
  // ============================================================

  static Future<String> generateMilNumber(DateTime forDate) async {
    final prefix =
        '${forDate.year.toString().padLeft(4, '0')}-'
        '${forDate.month.toString().padLeft(2, '0')}-'
        '${forDate.day.toString().padLeft(2, '0')}';

    // Try increasing sequence numbers until we find one that isn't taken.
    // The unique constraint on audits.mil_number is the real safety net if
    // two completions race; this loop just avoids the obvious collision.
    for (var seq = 1; seq < 1000; seq++) {
      final candidate = '$prefix-$seq';
      final existing = await _db
          .from('audits')
          .select('audit_id')
          .eq('mil_number', candidate)
          .maybeSingle();
      if (existing == null) return candidate;
    }
    throw StateError('Could not allocate a MIL number for $prefix');
  }

  /// Generates and assigns the MIL number to an audit (if it doesn't
  /// already have one) and returns the number.
  static Future<String> ensureMilNumber(Audit audit) async {
    if (audit.milNumber != null && audit.milNumber!.isNotEmpty) {
      return audit.milNumber!;
    }
    final milNumber = await generateMilNumber(audit.auditDate);
    await _db.from('audits').update({
      'mil_number': milNumber,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('audit_id', audit.auditId);
    return milNumber;
  }

  // ============================================================
  // MIL close gate: cannot close until every finding is Closed
  // ============================================================

  static bool canCloseMil(List<AuditFinding> findings) {
    if (findings.isEmpty) return true;
    return findings.every((f) => f.isClosed);
  }
}
