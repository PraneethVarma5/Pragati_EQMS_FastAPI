import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/audit/audit_answer_model_new.dart';
import '../../models/audit/audit_model_new.dart';
import '../../models/audit/audit_question_model_new.dart';
import '../../models/audit/audit_section_model_new.dart';
import '../../models/audit/audit_type_model.dart';

class AuditServiceNew {
  AuditServiceNew();

  final SupabaseClient _client =
      Supabase.instance.client;

  // ============================================================
  // AUDIT TYPES
  // ============================================================

  Future<List<AuditTypeModelNew>>
  getAuditTypes() async {
    final response = await _client
        .from('audit_master_types')
        .select(
      'type_id,audit_type,active',
    )
        .eq('active', true)
        .order('audit_type');

    return List<Map<String, dynamic>>
        .from(response)
        .map(
      AuditTypeModelNew.fromMap,
    )
        .toList();
  }

  // ============================================================
  // STANDARD SECTIONS
  // ============================================================

  Future<List<AuditSectionModelNew>>
  getSections(
      String auditType,
      ) async {
    final response = await _client
        .from('audit_master_sections')
        .select(
      'section_id,'
          'audit_type,'
          'section_name,'
          'sort_order,'
          'active',
    )
        .eq(
      'audit_type',
      auditType,
    )
        .eq(
      'active',
      true,
    )
        .order('sort_order')
        .order('section_name');

    return List<Map<String, dynamic>>
        .from(response)
        .map(
      AuditSectionModelNew.fromMap,
    )
        .toList();
  }

  // ============================================================
  // QUESTIONS
  // ============================================================

  Future<List<AuditQuestionModelNew>>
  getQuestions(
      dynamic sectionId,
      ) async {
    final response = await _client
        .from('audit_master_questions')
        .select(
      'question_id,'
          'section_id,'
          'question_number,'
          'question,'
          'sort_order,'
          'active',
    )
        .eq(
      'section_id',
      sectionId,
    )
        .eq(
      'active',
      true,
    )
        .order('sort_order')
        .order('question_number');

    return List<Map<String, dynamic>>
        .from(response)
        .map(
      AuditQuestionModelNew.fromMap,
    )
        .toList();
  }

  // ============================================================
  // AUDITS
  // ============================================================

  Future<List<AuditModelNew>>
  getAudits() async {
    final response = await _client
        .from('audits')
        .select()
        .order(
      'audit_id',
      ascending: false,
    );

    return List<Map<String, dynamic>>
        .from(response)
        .map(
      AuditModelNew.fromMap,
    )
        .toList();
  }

  Future<AuditModelNew?> getAudit(
      dynamic auditId,
      ) async {
    final response = await _client
        .from('audits')
        .select()
        .eq(
      'audit_id',
      auditId,
    )
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return AuditModelNew.fromMap(
      Map<String, dynamic>.from(
        response,
      ),
    );
  }

  Future<AuditModelNew?> getAuditByMilNumber(
      String milNumber,
      ) async {
    final response = await _client
        .from('audits')
        .select()
        .eq(
      'mil_number',
      milNumber,
    )
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return AuditModelNew.fromMap(
      Map<String, dynamic>.from(
        response,
      ),
    );
  }

  // ============================================================
  // CREATE AUDIT
  // ============================================================

  Future<AuditModelNew> createAudit({
    required String milNumber,
    required String auditType,
    required String vendor,
    required String site,
    required String lob,
    required String program,
    required String line,
    required String apn,
    required String auditor,
    required String auditDate,
  }) async {
    final existing =
    await getAuditByMilNumber(
      milNumber,
    );

    if (existing != null) {
      throw Exception(
        'MIL number "$milNumber" already exists.',
      );
    }

    final data = <String, dynamic>{
      'mil_number': milNumber,
      'audit_type': auditType,
      'vendor': vendor,
      'site': site,
      'lob': lob,
      'program': program,
      'line': line,
      'apn': apn,
      'auditor': auditor,
      'audit_date': auditDate,
    };

    final response = await _client
        .from('audits')
        .insert(data)
        .select()
        .single();

    return AuditModelNew.fromMap(
      Map<String, dynamic>.from(
        response,
      ),
    );
  }

  // ============================================================
  // ANSWERS
  // ============================================================

  Future<List<AuditAnswerModelNew>>
  getAnswers(
      dynamic auditId,
      ) async {
    final response = await _client
        .from('audit_checklist_answers')
        .select()
        .eq(
      'audit_id',
      auditId,
    );

    return List<Map<String, dynamic>>
        .from(response)
        .map(
      AuditAnswerModelNew.fromMap,
    )
        .toList();
  }

  Future<void> saveAnswer({
    required dynamic auditId,
    required dynamic checklistItemId,
    required String auditType,
    required String category,
    required String question,
    required String answer,
    required String description,
    required String defect,
    required String finding,
    required String findingType,
  }) async {
    await _client
        .from('audit_checklist_answers')
        .upsert(
      {
        'audit_id': auditId,
        'checklist_item_id':
        checklistItemId,
        'audit_type': auditType,
        'category': category,
        'question': question,
        'answer': answer,
        'description': description,
        'defect': defect,
        'finding': finding,
        'finding_type':
        findingType,
      },
      onConflict:
      'audit_id,checklist_item_id',
    );
  }

  // ============================================================
  // FINDINGS
  // ============================================================

  Future<List<Map<String, dynamic>>>
  getFindings(
      dynamic auditId,
      ) async {
    final response = await _client
        .from('audit_findings')
        .select()
        .eq(
      'audit_id',
      auditId,
    );

    return List<Map<String, dynamic>>
        .from(response);
  }
}