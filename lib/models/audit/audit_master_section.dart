class AuditMasterSection {
  final String sectionId;
  final String auditType;
  final String sectionName;
  final int sortOrder;
  final bool active;

  AuditMasterSection({
    required this.sectionId,
    required this.auditType,
    required this.sectionName,
    required this.sortOrder,
    required this.active,
  });

  factory AuditMasterSection.fromMap(Map<String, dynamic> map) {
    return AuditMasterSection(
      sectionId: map['section_id'] as String,
      auditType: map['audit_type'] as String,
      sectionName: map['section_name'] as String,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      active: map['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toInsertMap() => {
        'audit_type': auditType,
        'section_name': sectionName,
        'sort_order': sortOrder,
        'active': active,
      };
}
