class AuditTypeModelNew {
  final dynamic typeId;
  final String auditType;
  final bool active;

  const AuditTypeModelNew({
    required this.typeId,
    required this.auditType,
    this.active = true,
  });

  factory AuditTypeModelNew.fromMap(
      Map<String, dynamic> map,
      ) {
    return AuditTypeModelNew(
      typeId: map['type_id'],
      auditType:
      (map['audit_type'] ?? '').toString(),
      active: map['active'] == null
          ? true
          : map['active'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type_id': typeId,
      'audit_type': auditType,
      'active': active,
    };
  }
}