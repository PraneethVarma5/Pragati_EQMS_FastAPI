class Question {
  final String partId;

  final String partNo;

  final String partName;

  int initialStatus;

  String barcode;

  String batchId;

  final int sequenceOrder;

  Question({
    this.partId = '',

    required this.partNo,

    required this.partName,

    required this.initialStatus,

    required this.barcode,

    required this.batchId,

    this.sequenceOrder = 0,
  });
}