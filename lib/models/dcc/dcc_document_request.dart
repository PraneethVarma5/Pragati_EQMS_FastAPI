class DccDocumentRequest {
  final String id;

  final String documentName;
  final String userName;
  final String userEmail;
  final String description;

  final String status;

  final String? documentNo;
  final String? documentType;
  final String? department;

  final String? candidateName;
  final String? candidateEmail;

  final DateTime? createdAt;
  final DateTime? notifiedAt;

  DccDocumentRequest({
    required this.id,
    required this.documentName,
    required this.userName,
    required this.userEmail,
    required this.description,
    required this.status,
    this.documentNo,
    this.documentType,
    this.department,
    this.candidateName,
    this.candidateEmail,
    this.createdAt,
    this.notifiedAt,
  });

  factory DccDocumentRequest.fromMap(
      Map<String, dynamic> map,
      ) {
    return DccDocumentRequest(
      id: map['id'].toString(),

      documentName:
      map['document_name']?.toString() ?? '',

      userName:
      map['user_name']?.toString() ?? '',

      userEmail:
      map['user_email']?.toString() ?? '',

      description:
      map['description']?.toString() ?? '',

      status:
      map['status']?.toString() ?? 'PENDING',

      documentNo:
      map['document_no']?.toString(),

      documentType:
      map['document_type']?.toString(),

      department:
      map['department']?.toString(),

      candidateName:
      map['candidate_name']?.toString(),

      candidateEmail:
      map['candidate_email']?.toString(),

      createdAt:
      map['created_at'] != null
          ? DateTime.tryParse(
        map['created_at'].toString(),
      )
          : null,

      notifiedAt:
      map['notified_at'] != null
          ? DateTime.tryParse(
        map['notified_at'].toString(),
      )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_name': documentName,
      'user_name': userName,
      'user_email': userEmail,
      'description': description,
      'status': status,
      'document_no': documentNo,
      'document_type': documentType,
      'department': department,
      'candidate_name': candidateName,
      'candidate_email': candidateEmail,
      'created_at':
      createdAt?.toIso8601String(),
      'notified_at':
      notifiedAt?.toIso8601String(),
    };
  }
}