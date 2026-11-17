import '../../models/audit/audit_type_model.dart';
import '../../models/audit/audit_section_model.dart';
import '../../models/audit/audit_question_model_new.dart';
import '../../models/audit/audit_auditor_model.dart';
import 'audit_db_service.dart';

class AuditMasterService {
  AuditMasterService._();

  static final _db =
      AuditDbService.client;

  // ============================================================
  // AUDIT TYPES
  // ============================================================
  static Future<int>
  getStandardQuestionCount(
      String sectionId,
      ) async {
    final response = await _db
        .from(
      AuditDbService.masterQuestions,
    )
        .select('question_id')
        .eq(
      'section_id',
      sectionId,
    )
        .eq(
      'active',
      true,
    );

    return List.from(response).length;
  }

  static Future<int>
  getCustomQuestionCount(
      String categoryId,
      ) async {
    final response = await _db
        .from(
      AuditDbService.customQuestions,
    )
        .select('question_id')
        .eq(
      'category_id',
      categoryId,
    );

    return List.from(response).length;
  }


  static Future<List<AuditTypeModel>>
  getAuditTypes() async {
    final response = await _db
        .from(AuditDbService.auditTypes)
        .select(
      'type_id,audit_type,active',
    )
        .eq('active', true)
        .order('audit_type');

    return List<Map<String, dynamic>>
        .from(response)
        .map(AuditTypeModel.fromMap)
        .toList();
  }

  // ============================================================
  // STANDARD SECTIONS
  // ============================================================

  static Future<List<AuditSectionModel>>
  getStandardSections(
      String auditType,
      ) async {
    final response = await _db
        .from(AuditDbService.masterSections)
        .select(
      'section_id,'
          'audit_type,'
          'section_name,'
          'sort_order,'
          'active',
    )
        .eq('audit_type', auditType)
        .eq('active', true)
        .order('sort_order')
        .order('section_name');

    return List<Map<String, dynamic>>
        .from(response)
        .map(AuditSectionModel.fromMap)
        .toList();
  }

  // ============================================================
  // CUSTOM CATEGORIES
  // ============================================================

  static Future<List<Map<String, dynamic>>>
  getCustomCategories(
      String auditType,
      ) async {
    final response = await _db
        .from(AuditDbService.customCategories)
        .select(
      'category_id,audit_type,category_name',
    )
        .eq('audit_type', auditType)
        .order('category_name');

    return List<Map<String, dynamic>>
        .from(response);
  }

  // ============================================================
  // STANDARD QUESTIONS
  // ============================================================

  static Future<List<AuditQuestionModel>>
  getStandardQuestions(
      String sectionId,
      ) async {
    final response = await _db
        .from(AuditDbService.masterQuestions)
        .select(
      'question_id,'
          'section_id,'
          'question_number,'
          'question,'
          'sort_order,'
          'active',
    )
        .eq('section_id', sectionId)
        .eq('active', true)
        .order('sort_order')
        .order('question_number');

    return List<Map<String, dynamic>>
        .from(response)
        .map(
      AuditQuestionModel.standard,
    )
        .toList();
  }

  // ============================================================
  // CUSTOM QUESTIONS
  // ============================================================

  static Future<List<AuditQuestionModel>>
  getCustomQuestions(
      String categoryId,
      ) async {
    final response = await _db
        .from(AuditDbService.customQuestions)
        .select(
      'question_id,'
          'category_id,'
          'question_number,'
          'question',
    )
        .eq('category_id', categoryId)
        .order('question_number');

    return List<Map<String, dynamic>>
        .from(response)
        .map(
      AuditQuestionModel.custom,
    )
        .toList();
  }

  // ============================================================
  // AUDITORS
  // ============================================================

  static Future<List<AuditAuditorModel>>
  getAuditors() async {
    final response = await _db
        .from(AuditDbService.auditors)
        .select(
      'auditor_id,'
          'auditor_name,'
          'employee_id,'
          'department,'
          'email,'
          'active',
    )
        .eq('active', true)
        .order('auditor_name');

    return List<Map<String, dynamic>>
        .from(response)
        .map(AuditAuditorModel.fromMap)
        .toList();
  }

  // ============================================================
  // ANSWER OPTIONS
  // ============================================================

  static Future<List<String>>
  getAnswerOptions() async {
    final response = await _db
        .from(AuditDbService.answers)
        .select('answer');

    final values = <String>{};

    for (final row
    in List<Map<String, dynamic>>.from(
      response,
    )) {
      final value =
      row['answer']?.toString().trim();

      if (value != null &&
          value.isNotEmpty) {
        values.add(value);
      }
    }

    return values.toList()..sort();
  }

  // ============================================================
  // FINDING CATEGORY OPTIONS
  // ============================================================

  static Future<List<String>>
  getFindingCategories() async {
    final values = <String>{};

    final answers = await _db
        .from(AuditDbService.answers)
        .select('finding_category');

    for (final row
    in List<Map<String, dynamic>>.from(
      answers,
    )) {
      final value =
      row['finding_category']
          ?.toString()
          .trim();

      if (value != null &&
          value.isNotEmpty) {
        values.add(value);
      }
    }

    final findings = await _db
        .from(AuditDbService.findings)
        .select('finding_category');

    for (final row
    in List<Map<String, dynamic>>.from(
      findings,
    )) {
      final value =
      row['finding_category']
          ?.toString()
          .trim();

      if (value != null &&
          value.isNotEmpty) {
        values.add(value);
      }
    }

    return values.toList()..sort();
  }
}