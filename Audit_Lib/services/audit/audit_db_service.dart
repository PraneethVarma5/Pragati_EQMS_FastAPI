import 'package:supabase_flutter/supabase_flutter.dart';

class AuditDbService {
  AuditDbService._();

  static final SupabaseClient client =
      Supabase.instance.client;

  static const String audits =
      'audits';

  static const String auditTypes =
      'audit_master_types';

  static const String masterSections =
      'audit_master_sections';

  static const String masterQuestions =
      'audit_master_questions';

  static const String customCategories =
      'audit_custom_categories';

  static const String customQuestions =
      'audit_custom_questions';

  static const String auditors =
      'audit_auditors';

  static const String schedules =
      'audit_schedules';

  static const String answers =
      'audit_checklist_answers';

  static const String progress =
      'audit_category_progress';

  static const String findings =
      'audit_findings';

  static const String masters =
      'audit_masters';
}