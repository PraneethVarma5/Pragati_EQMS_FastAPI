class AuditModelNew {
  final dynamic auditId;

  final String milNumber;
  final String auditType;

  final String vendor;
  final String site;
  final String lob;
  final String program;
  final String line;
  final String apn;

  final String auditor;
  final String auditDate;
  final String status;

  final dynamic totalTimeTakenHours;

  const AuditModelNew({
    this.auditId,
    required this.milNumber,
    required this.auditType,
    required this.vendor,
    required this.site,
    required this.lob,
    required this.program,
    required this.line,
    required this.apn,
    required this.auditor,
    required this.auditDate,
    required this.status,
    this.totalTimeTakenHours,
  });

  factory AuditModelNew.fromMap(
      Map<String, dynamic> map,
      ) {
    return AuditModelNew(
      auditId: map['audit_id'],
      milNumber:
      (map['mil_number'] ?? '')
          .toString(),
      auditType:
      (map['audit_type'] ?? '')
          .toString(),
      vendor:
      (map['vendor'] ?? '')
          .toString(),
      site:
      (map['site'] ?? '')
          .toString(),
      lob:
      (map['lob'] ?? '')
          .toString(),
      program:
      (map['program'] ?? '')
          .toString(),
      line:
      (map['line'] ?? '')
          .toString(),
      apn:
      (map['apn'] ?? '')
          .toString(),
      auditor:
      (map['auditor'] ?? '')
          .toString(),
      auditDate:
      (map['audit_date'] ?? '')
          .toString(),
      status:
      (map['status'] ?? '')
          .toString(),
      totalTimeTakenHours:
      map['total_time_taken_hours'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'audit_id': auditId,
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
      'status': status,
      'total_time_taken_hours':
      totalTimeTakenHours,
    };
  }
}