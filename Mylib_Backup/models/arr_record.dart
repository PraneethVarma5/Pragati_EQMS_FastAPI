class ArrRecord {
  final String employeeCode;

  final String appraisee;

  final String department;

  final String product;

  final String result;

  final String certificateNo;

  final String date;
  final String batchName;


  final double falseAlertPercent;
  final double missRate;
  final double effectiveness;
  final double kappa;

  final List<int> trail1Answers;
  final List<int> trail2Answers;
  final List<int> trail3Answers;
  final List<String> partNumbers;
  final List<int> masterAnswers;
  final String batchId;
  final String candidatePhotoPath;
  ArrRecord({
    required this.employeeCode,

    required this.appraisee,

    required this.department,

    required this.product,
    required this.batchName,

    required this.result,

    required this.certificateNo,

    required this.date,

    required this.falseAlertPercent,
    required this.missRate,
    required this.effectiveness,
    required this.kappa,
    required this.trail1Answers,
    required this.trail2Answers,
    required this.trail3Answers,
    required this.candidatePhotoPath,
    required this.batchId,
    required this.partNumbers,
    required this.masterAnswers,

  });
}
