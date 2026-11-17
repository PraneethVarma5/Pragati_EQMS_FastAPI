class AuditProgressModel {
  final String progressId;
  final String auditId;
  final String category;
  final double timeTakenHours;
  final bool completed;
  final DateTime? completedAt;

  const AuditProgressModel({
    required this.progressId,
    required this.auditId,
    required this.category,
    required this.timeTakenHours,
    required this.completed,
    this.completedAt,
  });

  factory AuditProgressModel.fromMap(
      Map<String, dynamic> map,
      ) {
    return AuditProgressModel(
      progressId:
      map['progress_id']?.toString() ?? '',
      auditId:
      map['audit_id']?.toString() ?? '',
      category:
      map['category']?.toString() ?? '',
      timeTakenHours:
      (map['time_taken_hours'] as num?)
          ?.toDouble() ??
          0,
      completed:
      map['completed'] == true,
      completedAt:
      map['completed_at'] == null
          ? null
          : DateTime.tryParse(
        map['completed_at'].toString(),
      ),
    );
  }
}