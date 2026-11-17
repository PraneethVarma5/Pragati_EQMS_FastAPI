/// Row from `audit_masters` — a reusable, manually-typed name (a product,
/// process, line, etc.) tied to one audit type, used as the thing being
/// scheduled on the Audit Schedule screen.
class AuditMasterName {
  final String masterId;
  final String masterName;
  final String auditType;
  final bool active;

  AuditMasterName({
    required this.masterId,
    required this.masterName,
    required this.auditType,
    required this.active,
  });

  factory AuditMasterName.fromMap(Map<String, dynamic> map) {
    return AuditMasterName(
      masterId: map['master_id'] as String,
      masterName: map['master_name'] as String,
      auditType: map['audit_type'] as String,
      active: map['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toInsertMap() => {
        'master_name': masterName,
        'audit_type': auditType,
        'active': active,
      };
}
