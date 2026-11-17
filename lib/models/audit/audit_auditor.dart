class AuditAuditor {
  final String auditorId;
  final String auditorName;
  final String? employeeId;
  final String? department;
  final String email;
  final bool active;

  AuditAuditor({
    required this.auditorId,
    required this.auditorName,
    this.employeeId,
    this.department,
    required this.email,
    required this.active,
  });

  factory AuditAuditor.fromMap(Map<String, dynamic> map) {
    return AuditAuditor(
      auditorId: map['auditor_id'] as String,
      auditorName: map['auditor_name'] as String,
      employeeId: map['employee_id'] as String?,
      department: map['department'] as String?,
      email: map['email'] as String,
      active: map['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toInsertMap() => {
        'auditor_name': auditorName,
        'employee_id': employeeId,
        'department': department,
        'email': email,
        'active': active,
      };
}
