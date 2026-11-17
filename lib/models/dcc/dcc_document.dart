class DccDocument {
  final String id;
  final String documentNo;
  final String documentName;
  final String documentType;
  final String department;
  final String candidateName;
  final String employeeId;
  final String folderName;

  final String attachmentPath;
  final String attachmentName;

  // Released PDF controlled by DCC
  final String releasedPdfPath;
  final String releasedPdfName;

  final String createdByName;
  final String createdByEmail;

  final String releasedByName;
  final String releasedByEmail;

  final String hodName;
  final String hodEmail;

  final String status;

  final int revision;
  final String revisionDate;

  final String rejectionReason;

  DccDocument({
    required this.id,
    required this.documentNo,
    required this.documentName,
    required this.documentType,
    required this.department,
    required this.candidateName,
    required this.employeeId,
    this.folderName = '',
    required this.attachmentPath,
    required this.attachmentName,

    this.releasedPdfPath = '',
    this.releasedPdfName = '',

    required this.createdByName,
    required this.createdByEmail,

    this.releasedByName = '',
    this.releasedByEmail = '',

    required this.hodName,
    required this.hodEmail,

    this.status = 'PENDING_HOD',
    this.revision = 1,
    required this.revisionDate,

    this.rejectionReason = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documentNo': documentNo,
      'documentName': documentName,
      'documentType': documentType,
      'department': department,
      'candidateName': candidateName,
      'employeeId': employeeId,
      'folderName': folderName,

      'attachmentPath': attachmentPath,
      'attachmentName': attachmentName,

      'releasedPdfPath': releasedPdfPath,
      'releasedPdfName': releasedPdfName,

      'createdByName': createdByName,
      'createdByEmail': createdByEmail,

      'releasedByName': releasedByName,
      'releasedByEmail': releasedByEmail,

      'hodName': hodName,
      'hodEmail': hodEmail,

      'status': status,
      'revision': revision,
      'revisionDate': revisionDate,

      'rejectionReason': rejectionReason,
    };
  }

  factory DccDocument.fromMap(
      Map<dynamic, dynamic> map,
      ) {
    return DccDocument(
      id: map['id']?.toString() ?? '',

      documentNo:
      map['documentNo']?.toString() ?? '',

      documentName:
      map['documentName']?.toString() ?? '',

      documentType:
      map['documentType']?.toString() ?? '',

      department:
      map['department']?.toString() ?? '',

      candidateName:
      map['candidateName']?.toString() ?? '',

      employeeId:
      map['employeeId']?.toString() ?? '',

      folderName:
      map['folderName']?.toString() ?? '',

      attachmentPath:
      map['attachmentPath']?.toString() ?? '',

      attachmentName:
      map['attachmentName']?.toString() ?? '',

      releasedPdfPath:
      map['releasedPdfPath']?.toString() ?? '',

      releasedPdfName:
      map['releasedPdfName']?.toString() ?? '',

      createdByName:
      map['createdByName']?.toString() ?? '',

      createdByEmail:
      map['createdByEmail']?.toString() ?? '',

      releasedByName:
      map['releasedByName']?.toString() ?? '',

      releasedByEmail:
      map['releasedByEmail']?.toString() ?? '',

      hodName:
      map['hodName']?.toString() ?? '',

      hodEmail:
      map['hodEmail']?.toString() ?? '',

      status:
      map['status']?.toString() ?? 'PENDING_HOD',

      revision:
      int.tryParse(
        map['revision']?.toString() ?? '',
      ) ??
          1,

      revisionDate:
      map['revisionDate']?.toString() ?? '',

      rejectionReason:
      map['rejectionReason']?.toString() ?? '',
    );
  }
}