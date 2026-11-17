class AuditSectionModelNew {
  final dynamic sectionId;
  final String auditType;
  final String sectionName;
  final dynamic sortOrder;
  final bool active;

  const AuditSectionModelNew({
    required this.sectionId,
    required this.auditType,
    required this.sectionName,
    this.sortOrder,
    this.active = true,
  });

  factory AuditSectionModelNew.fromMap(
      Map<String, dynamic> map,
      ) {
    return AuditSectionModelNew(
      sectionId: map['section_id'],
      auditType:
      (map['audit_type'] ?? '').toString(),
      sectionName:
      (map['section_name'] ?? '').toString(),
      sortOrder: map['sort_order'],
      active: map['active'] == null
          ? true
          : map['active'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'section_id': sectionId,
      'audit_type': auditType,
      'section_name': sectionName,
      'sort_order': sortOrder,
      'active': active,
    };
  }
}