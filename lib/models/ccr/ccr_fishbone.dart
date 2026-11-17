class CcrFishboneCategory {
  final String id;
  final String name;
  final String? description;
  final int displayOrder;
  final bool isActive;

  const CcrFishboneCategory({
    required this.id,
    required this.name,
    this.description,
    required this.displayOrder,
    required this.isActive,
  });

  factory CcrFishboneCategory.fromMap(
      Map<String, dynamic> map,
      ) {
    final rawOrder = map['display_order'];

    int order;

    if (rawOrder is int) {
      order = rawOrder;
    } else if (rawOrder is num) {
      order = rawOrder.toInt();
    } else {
      order =
          int.tryParse(
            rawOrder?.toString() ?? '',
          ) ??
              0;
    }

    return CcrFishboneCategory(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description:
      map['description']?.toString(),
      displayOrder: order,
      isActive:
      map['is_active'] == true,
    );
  }
}

class CcrFishboneCause {
  final String id;
  final String ccrId;
  final String categoryId;
  final String categoryName;
  final String causeText;
  final int displayOrder;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CcrFishboneCause({
    required this.id,
    required this.ccrId,
    required this.categoryId,
    required this.categoryName,
    required this.causeText,
    required this.displayOrder,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory CcrFishboneCause.fromMap(
      Map<String, dynamic> map,
      ) {
    final category =
    map['ccr_fishbone_categories'];

    String categoryName = '';

    if (category is Map) {
      categoryName =
          category['name']
              ?.toString() ??
              '';
    }

    final rawOrder = map['display_order'];

    int order;

    if (rawOrder is int) {
      order = rawOrder;
    } else if (rawOrder is num) {
      order = rawOrder.toInt();
    } else {
      order =
          int.tryParse(
            rawOrder?.toString() ?? '',
          ) ??
              0;
    }

    return CcrFishboneCause(
      id: map['id']?.toString() ?? '',
      ccrId:
      map['ccr_id']?.toString() ?? '',
      categoryId:
      map['category_id']
          ?.toString() ??
          '',
      categoryName: categoryName,
      causeText:
      map['cause_text']?.toString() ??
          '',
      displayOrder: order,
      createdBy:
      map['created_by']?.toString(),
      updatedBy:
      map['updated_by']?.toString(),
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