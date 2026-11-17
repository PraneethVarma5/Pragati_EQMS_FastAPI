import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/audit/audit_master_type.dart';
import '../../models/audit/audit_master_section.dart';
import '../../models/audit/audit_master_question.dart';

/// Everything behind the "+New" sidebar item / Audit Master Builder screen:
/// admin creates Audit Types, then Sections (categories) under a type, then
/// Questions under a section. All persisted, nothing hardcoded.
class AuditMasterService {
  AuditMasterService._();

  static SupabaseClient get _db => Supabase.instance.client;

  // ---------------- Audit Types ----------------

  static Future<List<AuditMasterType>> fetchAuditTypes({
    bool activeOnly = true,
  }) async {
    var query = _db.from('audit_master_types').select();
    if (activeOnly) {
      query = query.eq('active', true);
    }
    final rows = await query.order('audit_type', ascending: true);
    return (rows as List)
        .map((r) => AuditMasterType.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  static Future<AuditMasterType> createAuditType(String auditType) async {
    final row = await _db
        .from('audit_master_types')
        .insert({'audit_type': auditType.trim(), 'active': true})
        .select()
        .single();
    return AuditMasterType.fromMap(row);
  }

  static Future<void> deleteAuditType(String typeId) async {
    await _db.from('audit_master_types').delete().eq('type_id', typeId);
  }

  // ---------------- Sections (categories) ----------------

  static Future<List<AuditMasterSection>> fetchSections(
    String auditType,
  ) async {
    final rows = await _db
        .from('audit_master_sections')
        .select()
        .eq('audit_type', auditType)
        .eq('active', true)
        .order('sort_order', ascending: true);
    return (rows as List)
        .map((r) => AuditMasterSection.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  static Future<AuditMasterSection> createSection({
    required String auditType,
    required String sectionName,
  }) async {
    final existing = await fetchSections(auditType);
    final nextSort =
        existing.isEmpty ? 1 : (existing.map((s) => s.sortOrder).reduce((a, b) => a > b ? a : b) + 1);

    final row = await _db
        .from('audit_master_sections')
        .insert({
          'audit_type': auditType,
          'section_name': sectionName.trim(),
          'sort_order': nextSort,
          'active': true,
        })
        .select()
        .single();
    return AuditMasterSection.fromMap(row);
  }

  static Future<void> deleteSection(String sectionId) async {
    await _db
        .from('audit_master_sections')
        .delete()
        .eq('section_id', sectionId);
  }

  // ---------------- Questions ----------------

  static Future<List<AuditMasterQuestion>> fetchQuestions(
    String sectionId,
  ) async {
    final rows = await _db
        .from('audit_master_questions')
        .select()
        .eq('section_id', sectionId)
        .eq('active', true)
        .order('sort_order', ascending: true);
    return (rows as List)
        .map((r) => AuditMasterQuestion.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  static Future<AuditMasterQuestion> createQuestion({
    required String sectionId,
    required String question,
  }) async {
    final existing = await fetchQuestions(sectionId);
    final nextNumber = existing.isEmpty
        ? 1
        : (existing.map((q) => q.questionNumber).reduce((a, b) => a > b ? a : b) + 1);

    final row = await _db
        .from('audit_master_questions')
        .insert({
          'section_id': sectionId,
          'question_number': nextNumber,
          'question': question.trim(),
          'sort_order': nextNumber,
          'active': true,
        })
        .select()
        .single();
    return AuditMasterQuestion.fromMap(row);
  }

  static Future<void> deleteQuestion(String questionId) async {
    await _db
        .from('audit_master_questions')
        .delete()
        .eq('question_id', questionId);
  }

  /// Full checklist shape for a given audit type: section -> its questions.
  /// Used when starting a new audit / rendering the checklist screen.
  static Future<Map<AuditMasterSection, List<AuditMasterQuestion>>>
      fetchFullChecklist(String auditType) async {
    final sections = await fetchSections(auditType);
    final result = <AuditMasterSection, List<AuditMasterQuestion>>{};
    for (final section in sections) {
      result[section] = await fetchQuestions(section.sectionId);
    }
    return result;
  }
}
