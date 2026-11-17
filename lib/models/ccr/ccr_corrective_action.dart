class CcrCorrectiveAction {
  final String id;
  final String ccrId;
  final String? validationId;
  final String problemStatement;
  final String occurrenceRootCause;
  final String detectionRootCause;
  final String correctiveAction;
  final String dri;

  final String resultBefore;
  final String resultAfter;

  final DateTime? dueDate;
  final DateTime? completionDate;

  final String status;

  final bool verificationRequired;
  final String verificationStatus;
  final String verifiedBy;
  final DateTime? verificationDate;
  final String verificationMethod;
  final String verificationResult;
  final String verificationRemarks;

  const CcrCorrectiveAction({
    required this.id,
    required this.ccrId,
    this.validationId,
    required this.problemStatement,
    required this.occurrenceRootCause,
    required this.detectionRootCause,
    required this.correctiveAction,
    required this.dri,
    required this.resultBefore,
    required this.resultAfter,
    required this.dueDate,
    required this.completionDate,
    required this.status,
    required this.verificationRequired,
    required this.verificationStatus,
    required this.verifiedBy,
    required this.verificationDate,
    required this.verificationMethod,
    required this.verificationResult,
    required this.verificationRemarks,
  });

  factory CcrCorrectiveAction.fromMap(
      Map<String, dynamic> map,
      ) {
    return CcrCorrectiveAction(
      id: map['id']?.toString() ?? '',
      validationId:
      map['validation_id']
          ?.toString(),
      ccrId: map['ccr_id']?.toString() ?? '',
      problemStatement:
      map['problem_statement']?.toString() ?? '',
      occurrenceRootCause:
      map['occurrence_root_cause']?.toString() ?? '',
      detectionRootCause:
      map['detection_root_cause']?.toString() ?? '',
      correctiveAction:
      map['corrective_action']?.toString() ?? '',
      dri: map['dri']?.toString() ?? '',
      resultBefore:
      map['result_before']?.toString() ?? '',
      resultAfter:
      map['result_after']?.toString() ?? '',
      dueDate: _parseDate(
        map['due_date'],
      ),
      completionDate: _parseDate(
        map['completion_date'],
      ),
      status:
      map['status']?.toString() ?? '',
      verificationRequired:
      _parseBool(
        map['verification_required'],
      ),
      verificationStatus:
      map['verification_status']?.toString() ?? '',
      verifiedBy:
      map['verified_by']?.toString() ?? '',
      verificationDate:
      _parseDate(
        map['verification_date'],
      ),
      verificationMethod:
      map['verification_method']?.toString() ?? '',
      verificationResult:
      map['verification_result']?.toString() ?? '',
      verificationRemarks:
      map['verification_remarks']?.toString() ?? '',
    );
  }

  static DateTime? _parseDate(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  static bool _parseBool(
      dynamic value,
      ) {
    if (value is bool) {
      return value;
    }

    return value
        ?.toString()
        .toLowerCase() ==
        'true';
  }

  bool get isOpen =>
      status.trim().toLowerCase() ==
          'open';

  bool get isInProgress =>
      status.trim().toLowerCase() ==
          'in_progress';

  bool get isCompleted =>
      status.trim().toLowerCase() ==
          'completed';

  bool get isVerified =>
      status.trim().toLowerCase() ==
          'verified';
}