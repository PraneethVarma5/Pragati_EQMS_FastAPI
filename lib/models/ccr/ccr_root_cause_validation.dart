class CcrRootCauseValidation {
  final String id;
  final String fishboneCauseId;
  final String ccrId;
  final String categoryId;
  final String categoryName;
  final String causeText;

  final String validationText;
  final bool? relevance;

  final String? validatedBy;
  final DateTime? validatedAt;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CcrRootCauseValidation({
    required this.id,
    required this.fishboneCauseId,
    required this.ccrId,
    required this.categoryId,
    required this.categoryName,
    required this.causeText,
    required this.validationText,
    required this.relevance,
    this.validatedBy,
    this.validatedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory CcrRootCauseValidation.fromMap(
      Map<String, dynamic> map,
      ) {
    final cause =
    map['ccr_fishbone_causes'];

    String ccrId = '';
    String categoryId = '';
    String categoryName = '';
    String causeText = '';

    if (cause is Map) {
      ccrId =
          cause['ccr_id']?.toString() ??
              '';

      categoryId =
          cause['category_id']?.toString() ??
              '';

      causeText =
          cause['cause_text']?.toString() ??
              '';

      final category =
      cause['ccr_fishbone_categories'];

      if (category is Map) {
        categoryName =
            category['name']?.toString() ??
                '';
      }
    }

    return CcrRootCauseValidation(
      id: map['id']?.toString() ?? '',
      fishboneCauseId:
      map['fishbone_cause_id']
          ?.toString() ??
          '',
      ccrId: ccrId,
      categoryId: categoryId,
      categoryName: categoryName,
      causeText: causeText,
      validationText:
      map['validation_text']
          ?.toString() ??
          '',
      relevance:
      map['relevance'] is bool
          ? map['relevance'] as bool
          : null,
      validatedBy:
      map['validated_by']?.toString(),
      validatedAt:
      _parseDateTime(
        map['validated_at'],
      ),
      createdAt:
      _parseDateTime(
        map['created_at'],
      ),
      updatedAt:
      _parseDateTime(
        map['updated_at'],
      ),
    );
  }

  static DateTime? _parseDateTime(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}