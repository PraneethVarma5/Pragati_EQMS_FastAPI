class DccFolder {
  final String id;
  final String name;
  final String createdByName;
  final String createdByEmail;
  final String createdAt;

  const DccFolder({
    required this.id,
    required this.name,
    this.createdByName = '',
    this.createdByEmail = '',
    this.createdAt = '',
  });

  factory DccFolder.fromMap(Map<String, dynamic> map) {
    return DccFolder(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      createdByName: map['created_by_name']?.toString() ?? '',
      createdByEmail: map['created_by_email']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? '',
    );
  }
}
