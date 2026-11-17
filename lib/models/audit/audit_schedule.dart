class AuditSchedule {
  final String scheduleId;
  final String? masterId;
  final String auditType;
  final DateTime auditDate;
  final String vendor;
  final String site;
  final String? lob;
  final String? program;
  final String? line;
  final String? apn;
  final String auditorName;
  final String? auditorEmail;
  final String status; // Scheduled | Completed | Cancelled

  AuditSchedule({
    required this.scheduleId,
    this.masterId,
    required this.auditType,
    required this.auditDate,
    required this.vendor,
    required this.site,
    this.lob,
    this.program,
    this.line,
    this.apn,
    required this.auditorName,
    this.auditorEmail,
    required this.status,
  });

  factory AuditSchedule.fromMap(Map<String, dynamic> map) {
    return AuditSchedule(
      scheduleId: map['schedule_id'] as String,
      masterId: map['master_id'] as String?,
      auditType: map['audit_type'] as String,
      auditDate: DateTime.parse(map['audit_date'] as String),
      vendor: map['vendor'] as String,
      site: map['site'] as String,
      lob: map['lob'] as String?,
      program: map['program'] as String?,
      line: map['line'] as String?,
      apn: map['apn'] as String?,
      auditorName: map['auditor_name'] as String,
      auditorEmail: map['auditor_email'] as String?,
      status: map['status'] as String? ?? 'Scheduled',
    );
  }

  Map<String, dynamic> toInsertMap() => {
        'master_id': masterId,
        'audit_type': auditType,
        'audit_date': auditDate.toIso8601String().split('T').first,
        'vendor': vendor,
        'site': site,
        'lob': lob,
        'program': program,
        'line': line,
        'apn': apn,
        'auditor_name': auditorName,
        'auditor_email': auditorEmail,
        'status': status,
      };
}
