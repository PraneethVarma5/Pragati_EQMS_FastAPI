class DccActivity {
  final String id;
  final String userEmail;
  final String userName;
  final String action;
  final String description;
  final String documentNo;
  final DateTime timestamp;

  DccActivity({
    required this.id,
    required this.userEmail,
    required this.userName,
    required this.action,
    required this.description,
    this.documentNo = '',
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userEmail': userEmail,
      'userName': userName,
      'action': action,
      'description': description,
      'documentNo': documentNo,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory DccActivity.fromMap(
      Map<dynamic, dynamic> map,
      ) {
    return DccActivity(
      id: map['id']?.toString() ?? '',
      userEmail: map['userEmail']?.toString() ?? '',
      userName: map['userName']?.toString() ?? '',
      action: map['action']?.toString() ?? '',
      description:
      map['description']?.toString() ?? '',
      documentNo:
      map['documentNo']?.toString() ?? '',
      timestamp: DateTime.tryParse(
        map['timestamp']?.toString() ?? '',
      ) ??
          DateTime.now(),
    );
  }
}