class DccMasterData {
  final String documentNo;
  final String documentName;
  final String documentType;
  final String department;
  final String candidateName;
  final String candidateEmail;
  final String createdByName;
  final String createdByEmail;
  final int revision;

  DccMasterData({
    required this.documentNo,
    required this.documentName,
    required this.documentType,
    required this.department,
    required this.candidateName,
    required this.candidateEmail,
    this.createdByName = '',
    this.createdByEmail = '',
    this.revision = 0,
  });
}
