class CcrAssignment {
  final String id;
  final String ccrId;
  final String? activity;
  final String? dri;
  final DateTime? dueDate;
  final DateTime? doneDate;
  final String? statusKey;
  final String? statusName;
  final String? remarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CcrAssignment({
    required this.id,
    required this.ccrId,
    this.activity,
    this.dri,
    this.dueDate,
    this.doneDate,
    this.statusKey,
    this.statusName,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  factory CcrAssignment.fromMap(
      Map<String, dynamic> map,
      ) {
    final status =
    map['ccr_assignment_statuses'];

    Map<String, dynamic>? statusMap;

    if (status is Map) {
      statusMap =
      Map<String, dynamic>.from(status);
    }

    return CcrAssignment(
      id: map['id']?.toString() ?? '',
      ccrId: map['ccr_id']?.toString() ?? '',
      activity: map['activity']?.toString(),
      dri: map['dri']?.toString(),
      dueDate: _parseDate(
        map['due_date'],
      ),
      doneDate: _parseDate(
        map['done_date'],
      ),
      statusKey:
      map['status']?.toString(),
      statusName:
      statusMap?['status_name']
          ?.toString(),
      remarks:
      map['remarks']?.toString(),
      createdAt:
      _parseDateTime(
        map['created_at'],
      ),
      updatedAt:
      _parseDateTime(
        map['updated_at'],
      ),
    );
  }

  static DateTime? _parseDate(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  static DateTime? _parseDateTime(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  String get displayStatus {
    final value = statusName?.trim();

    if (value == null || value.isEmpty) {
      return statusKey ?? '-';
    }

    return value;
  }
}