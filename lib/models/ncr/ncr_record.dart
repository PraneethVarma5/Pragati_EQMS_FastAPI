class NcrRecord {
  final String id;
  final String ncrNumber;
  final String reportNo;

  // ============================================================
  // ADMIN / AUDIT INFORMATION
  // ============================================================

  final String processFunction;
  final String clauseSection;

  final String? auditeeId;
  final String? auditeeName;

  final String standard;
  final String iaNo;

  final String? auditorId;
  final String? auditorName;

  final DateTime? auditDate;

  final String findingStatement;
  final String requirementClauseReference;

  // ============================================================
  // WORKFLOW / STATUS
  // ============================================================

  final String? statusId;
  final String? statusKey;
  final String? statusName;

  final String? createdBy;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ============================================================
  // USER ACTION PLAN
  // ============================================================

  final String? rootCauses;

  final String? correction;
  final DateTime? correctionEffectiveDate;

  final String? correctiveAction;
  final DateTime? correctiveActionEffectiveDate;

  final String? followUpAuditDetails;
  final DateTime? followUpAuditDate;

  final String? effectivenessOfCorrectiveAction;
  final DateTime? effectivenessDate;

  // ============================================================
  // HOD REVIEW
  // ============================================================

  final String? hodAction;
  final String? hodComments;
  final String? hodActionBy;
  final DateTime? hodActionAt;

  // ============================================================
  // DCC REVIEW
  // ============================================================

  final String? dccAction;
  final String? dccComments;
  final String? dccActionBy;
  final DateTime? dccActionAt;

  final DateTime? closedAt;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const NcrRecord({
    required this.id,
    required this.ncrNumber,
    required this.reportNo,

    required this.processFunction,
    required this.clauseSection,

    required this.auditeeId,
    required this.auditeeName,

    required this.standard,
    required this.iaNo,

    required this.auditorId,
    required this.auditorName,

    required this.auditDate,

    required this.findingStatement,
    required this.requirementClauseReference,

    required this.statusId,
    required this.statusKey,
    required this.statusName,

    required this.createdBy,

    required this.createdAt,
    required this.updatedAt,

    required this.rootCauses,

    required this.correction,
    required this.correctionEffectiveDate,

    required this.correctiveAction,
    required this.correctiveActionEffectiveDate,

    required this.followUpAuditDetails,
    required this.followUpAuditDate,

    required this.effectivenessOfCorrectiveAction,
    required this.effectivenessDate,

    required this.hodAction,
    required this.hodComments,
    required this.hodActionBy,
    required this.hodActionAt,

    required this.dccAction,
    required this.dccComments,
    required this.dccActionBy,
    required this.dccActionAt,

    required this.closedAt,
  });

  // ============================================================
  // FROM MAP
  // ============================================================

  factory NcrRecord.fromMap(
      Map<String, dynamic> map,
      ) {
    return NcrRecord(
      id:
      map['id']?.toString() ?? '',

      ncrNumber:
      map['ncr_number']?.toString() ?? '',

      reportNo:
      map['report_no']?.toString() ?? '',

      // --------------------------------------------------------
      // ADMIN INFORMATION
      // --------------------------------------------------------

      processFunction:
      map['process_function']?.toString() ?? '',

      clauseSection:
      map['clause_section']?.toString() ?? '',

      auditeeId:
      map['auditee_id']?.toString(),

      auditeeName:
      map['auditee_name']?.toString(),

      standard:
      map['standard']?.toString() ?? '',

      iaNo:
      map['ia_no']?.toString() ?? '',

      auditorId:
      map['auditor_id']?.toString(),

      auditorName:
      map['auditor_name']?.toString(),

      auditDate:
      _parseDate(
        map['audit_date'],
      ),

      findingStatement:
      map['finding_statement']?.toString() ?? '',

      requirementClauseReference:
      map['requirement_clause_reference']
          ?.toString() ??
          '',

      // --------------------------------------------------------
      // STATUS
      // --------------------------------------------------------

      statusId:
      map['status_id']?.toString(),

      statusKey:
      map['status_key']?.toString(),

      statusName:
      map['status_name']?.toString(),

      createdBy:
      map['created_by']?.toString(),

      createdAt:
      _parseDate(
        map['created_at'],
      ),

      updatedAt:
      _parseDate(
        map['updated_at'],
      ),

      // --------------------------------------------------------
      // USER ACTION PLAN
      // --------------------------------------------------------

      rootCauses:
      map['root_causes']?.toString(),

      correction:
      map['correction']?.toString(),

      correctionEffectiveDate:
      _parseDate(
        map['correction_effective_date'],
      ),

      correctiveAction:
      map['corrective_action']?.toString(),

      correctiveActionEffectiveDate:
      _parseDate(
        map['corrective_action_effective_date'],
      ),

      followUpAuditDetails:
      map['follow_up_audit_details']?.toString(),

      followUpAuditDate:
      _parseDate(
        map['follow_up_audit_date'],
      ),

      effectivenessOfCorrectiveAction:
      map[
      'effectiveness_of_corrective_action']
          ?.toString(),

      effectivenessDate:
      _parseDate(
        map['effectiveness_date'],
      ),

      // --------------------------------------------------------
      // HOD
      // --------------------------------------------------------

      hodAction:
      map['hod_action']?.toString(),

      hodComments:
      map['hod_comments']?.toString(),

      hodActionBy:
      map['hod_action_by']?.toString(),

      hodActionAt:
      _parseDate(
        map['hod_action_at'],
      ),

      // --------------------------------------------------------
      // DCC
      // --------------------------------------------------------

      dccAction:
      map['dcc_action']?.toString(),

      dccComments:
      map['dcc_comments']?.toString(),

      dccActionBy:
      map['dcc_action_by']?.toString(),

      dccActionAt:
      _parseDate(
        map['dcc_action_at'],
      ),

      closedAt:
      _parseDate(
        map['closed_at'],
      ),
    );
  }

  // ============================================================
  // TO MAP
  //
  // Required by the Admin NCR Details screen.
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ncr_number': ncrNumber,
      'report_no': reportNo,

      'process_function':
      processFunction,

      'clause_section':
      clauseSection,

      'auditee_id':
      auditeeId,

      'auditee_name':
      auditeeName,

      'standard':
      standard,

      'ia_no':
      iaNo,

      'auditor_id':
      auditorId,

      'auditor_name':
      auditorName,

      'audit_date':
      auditDate?.toIso8601String(),

      'finding_statement':
      findingStatement,

      'requirement_clause_reference':
      requirementClauseReference,

      'status_id':
      statusId,

      'status_key':
      statusKey,

      'status_name':
      statusName,

      'created_by':
      createdBy,

      'created_at':
      createdAt?.toIso8601String(),

      'updated_at':
      updatedAt?.toIso8601String(),

      // --------------------------------------------------------
      // USER ACTION PLAN
      // --------------------------------------------------------

      'root_causes':
      rootCauses,

      'correction':
      correction,

      'correction_effective_date':
      correctionEffectiveDate
          ?.toIso8601String(),

      'corrective_action':
      correctiveAction,

      'corrective_action_effective_date':
      correctiveActionEffectiveDate
          ?.toIso8601String(),

      'follow_up_audit_details':
      followUpAuditDetails,

      'follow_up_audit_date':
      followUpAuditDate
          ?.toIso8601String(),

      'effectiveness_of_corrective_action':
      effectivenessOfCorrectiveAction,

      'effectiveness_date':
      effectivenessDate
          ?.toIso8601String(),

      // --------------------------------------------------------
      // HOD
      // --------------------------------------------------------

      'hod_action':
      hodAction,

      'hod_comments':
      hodComments,

      'hod_action_by':
      hodActionBy,

      'hod_action_at':
      hodActionAt?.toIso8601String(),

      // --------------------------------------------------------
      // DCC
      // --------------------------------------------------------

      'dcc_action':
      dccAction,

      'dcc_comments':
      dccComments,

      'dcc_action_by':
      dccActionBy,

      'dcc_action_at':
      dccActionAt?.toIso8601String(),

      'closed_at':
      closedAt?.toIso8601String(),
    };
  }

  // ============================================================
  // DATE PARSER
  // ============================================================

  static DateTime? _parseDate(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    final text =
    value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }
}