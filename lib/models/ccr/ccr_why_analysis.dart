class CcrWhyStep {
  final String? id;
  final String analysisId;
  final int whyNumber;
  final String whyText;
  final String verificationText;
  final bool? evidenceAvailable;

  const CcrWhyStep({
    this.id,
    required this.analysisId,
    required this.whyNumber,
    required this.whyText,
    required this.verificationText,
    required this.evidenceAvailable,
  });

  factory CcrWhyStep.fromMap(
      Map<String, dynamic> map,
      ) {
    final rawWhyNumber = map['why_number'];

    final whyNumber = rawWhyNumber is num
        ? rawWhyNumber.toInt()
        : int.tryParse(
      rawWhyNumber?.toString() ?? '',
    ) ??
        0;

    bool? evidence;

    final rawEvidence =
    map['evidence_available'];

    if (rawEvidence is bool) {
      evidence = rawEvidence;
    } else if (rawEvidence != null) {
      final value =
      rawEvidence.toString().toLowerCase();

      if (value == 'true') {
        evidence = true;
      } else if (value == 'false') {
        evidence = false;
      }
    }

    return CcrWhyStep(
      id: map['id']?.toString(),
      analysisId:
      map['analysis_id']?.toString() ?? '',
      whyNumber: whyNumber,
      whyText:
      map['why_text']?.toString() ?? '',
      verificationText:
      map['verification_text']?.toString() ?? '',
      evidenceAvailable: evidence,
    );
  }
}

class CcrWhyAnalysis {
  final String id;
  final String validationId;
  final String analysisType;
  final String potentialRootCause;
  final List<CcrWhyStep> steps;

  final String causeId;
  final String categoryName;
  final String causeText;
  final String validationText;

  const CcrWhyAnalysis({
    required this.id,
    required this.validationId,
    required this.analysisType,
    required this.potentialRootCause,
    required this.steps,
    required this.causeId,
    required this.categoryName,
    required this.causeText,
    required this.validationText,
  });

  factory CcrWhyAnalysis.fromMap(
      Map<String, dynamic> map,
      ) {
    final rawSteps = map['ccr_why_steps'];

    final steps = <CcrWhyStep>[];

    if (rawSteps is List) {
      for (final raw in rawSteps) {
        if (raw is Map) {
          steps.add(
            CcrWhyStep.fromMap(
              Map<String, dynamic>.from(raw),
            ),
          );
        }
      }
    }

    steps.sort(
          (a, b) =>
          a.whyNumber.compareTo(b.whyNumber),
    );

    final validation =
    map['ccr_root_cause_validations'];

    Map<String, dynamic> validationMap = {};

    if (validation is Map) {
      validationMap =
      Map<String, dynamic>.from(validation);
    }

    final cause =
    validationMap['ccr_fishbone_causes'];

    Map<String, dynamic> causeMap = {};

    if (cause is Map) {
      causeMap =
      Map<String, dynamic>.from(cause);
    }

    final category =
    causeMap['ccr_fishbone_categories'];

    Map<String, dynamic> categoryMap = {};

    if (category is Map) {
      categoryMap =
      Map<String, dynamic>.from(category);
    }

    return CcrWhyAnalysis(
      id: map['id']?.toString() ?? '',
      validationId:
      map['validation_id']?.toString() ?? '',
      analysisType:
      map['analysis_type']?.toString() ?? '',
      potentialRootCause:
      map['potential_root_cause']
          ?.toString() ??
          '',
      steps: steps,
      causeId:
      validationMap['fishbone_cause_id']
          ?.toString() ??
          '',
      categoryName:
      categoryMap['name']?.toString() ?? '',
      causeText:
      causeMap['cause_text']?.toString() ?? '',
      validationText:
      validationMap['validation_text']
          ?.toString() ??
          '',
    );
  }

  bool get isOccurrence =>
      analysisType.trim().toLowerCase() ==
          'occurrence';

  bool get isNonDetection =>
      analysisType.trim().toLowerCase() ==
          'non_detection';

  String get analysisTitle {
    if (isOccurrence) {
      return 'Occurrence 5-Why';
    }

    if (isNonDetection) {
      return 'Non-Detection 5-Why';
    }

    return analysisType;
  }
}