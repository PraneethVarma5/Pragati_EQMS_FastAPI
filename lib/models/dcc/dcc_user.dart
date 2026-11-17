
class DccUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String hodName;
  final String hodEmail;
  final String password;
  final bool active;
  final String sessionToken;
  final DateTime? deletedAt;

  DccUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.hodName = '',
    this.hodEmail = '',
    required this.password,
    this.active = true,
    this.sessionToken = '',
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  bool get isDisabled => !active && deletedAt == null;

  bool get isActive => active && deletedAt == null;

  String get accountStatus {
    if (isDeleted) return 'DELETED';
    if (isDisabled) return 'DISABLED';
    return 'ACTIVE';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'hodName': hodName,
      'hodEmail': hodEmail,
      'password': password,
      'active': active,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory DccUser.fromMap(Map<dynamic, dynamic> map) {
    final deletedValue = map['deletedAt'] ?? map['deleted_at'];

    return DccUser(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      hodName: (map['hodName'] ?? map['hod_name'])?.toString() ?? '',
      hodEmail: (map['hodEmail'] ?? map['hod_email'])?.toString() ?? '',
      password: '',
      active: map['active'] == true,
      deletedAt: deletedValue == null
          ? null
          : DateTime.tryParse(deletedValue.toString()),
    );
  }
}
