class DccUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String hodName;
  final String hodEmail;
  final String password;
  final bool active;

  DccUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.hodName = '',
    this.hodEmail = '',
    required this.password,
    this.active = true,
  });

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
    };
  }

  factory DccUser.fromMap(Map<dynamic, dynamic> map) {
    return DccUser(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      hodName: map['hodName']?.toString() ?? '',
      hodEmail: map['hodEmail']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      active: map['active'] == true,
    );
  }
}