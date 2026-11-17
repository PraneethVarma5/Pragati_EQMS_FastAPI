class NcrUser {
final String id;
final String fullName;
final String email;
final String roleId;
final String roleKey;
final String roleName;
final bool isActive;
final DateTime? createdAt;
final DateTime? updatedAt;

const NcrUser({
required this.id,
required this.fullName,
required this.email,
required this.roleId,
required this.roleKey,
required this.roleName,
required this.isActive,
this.createdAt,
this.updatedAt,
});

factory NcrUser.fromMap(Map<String, dynamic> map) {
final roleData = map['ncr_roles'];

final Map<String, dynamic> role;

if (roleData is Map<String, dynamic>) {
role = roleData;
} else if (roleData is Map) {
role = Map<String, dynamic>.from(roleData);
} else {
role = {};
}

return NcrUser(
id: map['id']?.toString() ?? '',
fullName: map['full_name']?.toString() ?? '',
email: map['email']?.toString() ?? '',
roleId: map['role_id']?.toString() ?? '',
roleKey: role['role_key']?.toString() ?? '',
roleName: role['role_name']?.toString() ?? '',
isActive: map['is_active'] == true,
createdAt: _parseDate(map['created_at']),
updatedAt: _parseDate(map['updated_at']),
);
}

Map<String, dynamic> toMap() {
return {
'id': id,
'full_name': fullName,
'email': email,
'role_id': roleId,
'role_key': roleKey,
'role_name': roleName,
'is_active': isActive,
'created_at': createdAt?.toIso8601String(),
'updated_at': updatedAt?.toIso8601String(),
};
}

static DateTime? _parseDate(dynamic value) {
if (value == null) {
return null;
}

return DateTime.tryParse(value.toString());
}

bool get isAdmin => roleKey.toLowerCase() == 'admin';

bool get isUser => roleKey.toLowerCase() == 'user';

bool get isHod => roleKey.toLowerCase() == 'hod';

bool get isDcc => roleKey.toLowerCase() == 'dcc';
}
