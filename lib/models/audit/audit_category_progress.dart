class AuditCategoryProgress {
  final String progressId;
  final String auditId;
  final String category;
  final double timeTakenHours;
  final bool completed;
  final DateTime? completedAt;

  AuditCategoryProgress({
    required this.progressId,
    required this.auditId,
    required this.category,
    required this.timeTakenHours,
    required this.completed,
    this.completedAt,
  });

  factory AuditCategoryProgress.fromMap(Map<String, dynamic> map) {
    return AuditCategoryProgress(
      progressId: map['progress_id'] as String,
      auditId: map['audit_id'] as String,
      category: map['category'] as String,
      timeTakenHours: (map['time_taken_hours'] as num?)?.toDouble() ?? 0,
      completed: map['completed'] as bool? ?? false,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toUpsertMap() => {
        'audit_id': auditId,
        'category': category,
        'time_taken_hours': timeTakenHours,
        'completed': completed,
        'completed_at': completedAt?.toIso8601String(),
      };
}
