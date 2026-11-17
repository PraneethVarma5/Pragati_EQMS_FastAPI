class AuditMasterType {
  final String typeId;
  final String auditType;
  final bool active;

  AuditMasterType({
    required this.typeId,
    required this.auditType,
    required this.active,
  });

  factory AuditMasterType.fromMap(Map<String, dynamic> map) {
    return AuditMasterType(
      typeId: map['type_id'] as String,
      auditType: map['audit_type'] as String,
      active: map['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toInsertMap() => {
        'audit_type': auditType,
        'active': active,
      };
}
