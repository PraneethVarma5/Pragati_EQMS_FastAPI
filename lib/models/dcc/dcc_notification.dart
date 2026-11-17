class DccNotification {
  final String id;
  final String recipientEmail;

  final String title;
  final String message;

  final String type;
  final String documentNo;
  final String? documentRequestId;
  final DateTime createdAt;

  final bool isRead;

  DccNotification({
    required this.id,
    required this.recipientEmail,
    required this.title,
    required this.message,
    required this.type,
    this.documentNo = '',
    required this.createdAt,
    this.isRead = false,
    this.documentRequestId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipientEmail': recipientEmail,
      'title': title,
      'message': message,
      'type': type,
      'documentNo': documentNo,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'documentRequestId': documentRequestId,
    };
  }

  factory DccNotification.fromMap(
      Map<dynamic, dynamic> map,
      ) {
    return DccNotification(
      id: map['id']?.toString() ?? '',
      recipientEmail:
      map['recipientEmail']?.toString() ?? '',
      title:
      map['title']?.toString() ?? '',
      message:
      map['message']?.toString() ?? '',
      type:
      map['type']?.toString() ?? 'GENERAL',
      documentNo:
      map['documentNo']?.toString() ?? '',
      documentRequestId:
      map['documentRequestId'],
      createdAt:
      DateTime.tryParse(
        map['createdAt']?.toString() ?? '',
      ) ??
          DateTime.now(),
      isRead:
      map['isRead'] == true,
    );
  }

  DccNotification copyWith({
    bool? isRead,
  }) {
    return DccNotification(
      id: id,
      recipientEmail: recipientEmail,
      title: title,
      message: message,
      type: type,
      documentNo: documentNo,
      documentRequestId: documentRequestId,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}