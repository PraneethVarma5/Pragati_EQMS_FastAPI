class Audit {
  final String auditId;
  final String? milNumber;
  final String auditType;
  final String vendor;
  final String? site;
  final String? lob;
  final String? program;
  final String? line;
  final String? apn;
  final String? auditorName;
  final String? auditorEmail;
  final DateTime auditDate;
  final double totalTimeTakenHours;
  final String status; // 'In Progress' | 'Completed'
  final String? scheduleId;
  final DateTime startedAt;
  final DateTime? finishedAt;

  Audit({
    required this.auditId,
    this.milNumber,
    required this.auditType,
    required this.vendor,
    this.site,
    this.lob,
    this.program,
    this.line,
    this.apn,
    this.auditorName,
    this.auditorEmail,
    required this.auditDate,
    required this.totalTimeTakenHours,
    required this.status,
    this.scheduleId,
    required this.startedAt,
    this.finishedAt,
  });

  bool get isCompleted => status == 'Completed';

  factory Audit.fromMap(Map<String, dynamic> map) {
    return Audit(
      auditId: map['audit_id'] as String,
      milNumber: map['mil_number'] as String?,
      auditType: map['audit_type'] as String,
      vendor: map['vendor'] as String? ?? '',
      site: map['site'] as String?,
      lob: map['lob'] as String?,
      program: map['program'] as String?,
      line: map['line'] as String?,
      apn: map['apn'] as String?,
      auditorName: map['auditor_name'] as String?,
      auditorEmail: map['auditor_email'] as String?,
      auditDate: DateTime.parse(map['audit_date'] as String),
      totalTimeTakenHours:
          (map['total_time_taken_hours'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'In Progress',
      scheduleId: map['schedule_id'] as String?,
      startedAt: map['started_at'] != null
          ? DateTime.parse(map['started_at'] as String)
          : DateTime.now(),
      finishedAt: map['finished_at'] != null
          ? DateTime.parse(map['finished_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertMap() => {
        'audit_type': auditType,
        'vendor': vendor,
        'site': site,
        'lob': lob,
        'program': program,
        'line': line,
        'apn': apn,
        'auditor_name': auditorName,
        'auditor_email': auditorEmail,
        'audit_date': auditDate.toIso8601String().split('T').first,
        'total_time_taken_hours': totalTimeTakenHours,
        'status': status,
        'schedule_id': scheduleId,
      };
}
