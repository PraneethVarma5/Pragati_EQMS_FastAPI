class DccDmrRequest {
  int get nextRevision => currentRevision + 1;
  final String id;

  final String documentId;
  final String documentNo;
  final String documentName;
  final String documentType;
  final String department;

  final String requestedByName;
  final String requestedByEmail;

  final String hodName;
  final String hodEmail;

  final int currentRevision;

  final String requestReason;

  final String status;

  final String rejectionReason;

  final String createdDate;
  final String hodActionDate;
  final String dccActionDate;

// Source file provided by DCC for editing.
  final String sourceFilePath;
  final String sourceFileName;

// Revised file uploaded by the user.
  final String revisedFilePath;
  final String revisedFileName;
  final String revisedSubmittedDate;

// Reason given by DCC when rejecting the revised file.
  final String revisedRejectionReason;

  final bool modificationAccessGranted;

  DccDmrRequest({
    required this.id,
    required this.documentId,
    required this.documentNo,
    required this.documentName,
    required this.documentType,
    required this.department,
    required this.requestedByName,
    required this.requestedByEmail,
    required this.hodName,
    required this.hodEmail,
    required this.currentRevision,
    required this.requestReason,
    this.status = 'PENDING_HOD',
    this.rejectionReason = '',

    required this.createdDate,
    this.hodActionDate = '',
    this.dccActionDate = '',
    this.sourceFilePath = '',
    this.sourceFileName = '',
    this.revisedFilePath = '',
    this.revisedFileName = '',
    this.revisedSubmittedDate = '',
    this.revisedRejectionReason = '',
    this.modificationAccessGranted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documentId': documentId,
      'documentNo': documentNo,
      'documentName': documentName,
      'documentType': documentType,
      'department': department,
      'requestedByName': requestedByName,
      'requestedByEmail': requestedByEmail,
      'hodName': hodName,
      'hodEmail': hodEmail,
      'currentRevision': currentRevision,
      'requestReason': requestReason,
      'status': status,
      'rejectionReason': rejectionReason,

      'createdDate': createdDate,
      'hodActionDate': hodActionDate,
      'dccActionDate': dccActionDate,
      'sourceFilePath': sourceFilePath,
      'sourceFileName': sourceFileName,
      'revisedFilePath': revisedFilePath,
      'revisedFileName': revisedFileName,
      'revisedSubmittedDate':
      revisedSubmittedDate,
      'revisedRejectionReason':
      revisedRejectionReason,
      'modificationAccessGranted':
      modificationAccessGranted,
    };
  }

  factory DccDmrRequest.fromMap(
      Map<dynamic, dynamic> map,
      ) {
    return DccDmrRequest(
      id: map['id']?.toString() ?? '',
      documentId:
      map['documentId']?.toString() ?? '',
      documentNo:
      map['documentNo']?.toString() ?? '',
      documentName:
      map['documentName']?.toString() ?? '',
      documentType:
      map['documentType']?.toString() ?? '',
      department:
      map['department']?.toString() ?? '',
      requestedByName:
      map['requestedByName']?.toString() ?? '',
      requestedByEmail:
      map['requestedByEmail']?.toString() ?? '',
      hodName:
      map['hodName']?.toString() ?? '',
      hodEmail:
      map['hodEmail']?.toString() ?? '',
      currentRevision:
      int.tryParse(
        map['currentRevision']?.toString() ?? '',
      ) ??
          0,
      requestReason:
      map['requestReason']?.toString() ?? '',
      status:
      map['status']?.toString() ??
          'PENDING_HOD',
      rejectionReason:
      map['rejectionReason']?.toString() ?? '',

      createdDate:
      map['createdDate']?.toString() ?? '',
      hodActionDate:
      map['hodActionDate']?.toString() ?? '',
      dccActionDate:
      map['dccActionDate']?.toString() ?? '',
      sourceFilePath:
      map['sourceFilePath'] == null
          ? ''
          : map['sourceFilePath'].toString(),

      sourceFileName:
      map['sourceFileName'] == null
          ? ''
          : map['sourceFileName'].toString(),

      revisedFilePath:
      map['revisedFilePath'] == null
          ? ''
          : map['revisedFilePath'].toString(),

      revisedFileName:
      map['revisedFileName'] == null
          ? ''
          : map['revisedFileName'].toString(),

      revisedSubmittedDate:
      map['revisedSubmittedDate'] == null
          ? ''
          : map['revisedSubmittedDate'].toString(),

      revisedRejectionReason:
      map['revisedRejectionReason'] == null
          ? ''
          : map['revisedRejectionReason'].toString(),
      modificationAccessGranted:
      map['modificationAccessGranted'] == true,
    );
  }
}