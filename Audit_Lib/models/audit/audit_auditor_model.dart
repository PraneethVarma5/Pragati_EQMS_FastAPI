class AuditAuditorModel {
  final String auditorId;
  final String auditorName;
  final String? employeeId;
  final String? department;
  final String email;
  final bool active;

  const AuditAuditorModel({
    required this.auditorId,
    required this.auditorName,
    this.employeeId,
    this.department,
    required this.email,
    required this.active,
  });

  factory AuditAuditorModel.fromMap(
      Map<String, dynamic> map,
      ) {
    return AuditAuditorModel(
      auditorId:
      map['auditor_id']?.toString() ?? '',
      auditorName:
      map['auditor_name']?.toString() ?? '',
      employeeId:
      map['employee_id']?.toString(),
      department:
      map['department']?.toString(),
      email:
      map['email']?.toString() ?? '',
      active:
      map['active'] == true,
    );
  }
}