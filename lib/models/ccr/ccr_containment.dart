class CcrContainment {
  final String id;
  final String ccrId;

  final String? sortingActivity;
  final String? sortingLearnings;
  final String? customerProtectionAction;
  final String? recoverPrqSchedule;
  final String? firstCertifiedGoodShipment;
  final DateTime? targetEta;

  final String? status;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  CcrContainment({
    required this.id,
    required this.ccrId,
    this.sortingActivity,
    this.sortingLearnings,
    this.customerProtectionAction,
    this.recoverPrqSchedule,
    this.firstCertifiedGoodShipment,
    this.targetEta,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory CcrContainment.fromMap(Map<String, dynamic> map) {
    return CcrContainment(
      id: map['id']?.toString() ?? '',
      ccrId: map['ccr_id']?.toString() ?? '',
      sortingActivity: map['sorting_activity']?.toString(),
      sortingLearnings: map['sorting_learnings']?.toString(),
      customerProtectionAction:
      map['customer_protection_action']?.toString(),
      recoverPrqSchedule:
      map['recover_prq_schedule']?.toString(),
      firstCertifiedGoodShipment:
      map['first_certified_good_shipment']?.toString(),
      targetEta: _parseDate(map['target_eta']),
      status: map['status']?.toString(),
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    return DateTime.tryParse(text);
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    return DateTime.tryParse(text);
  }
}


class CcrContainmentSorting {
  final String id;
  final String containmentId;

  final String? location;

  final double? qtyNg;
  final double? qtySorted;

  final DateTime? sortingDate;

  final String? dri;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  CcrContainmentSorting({
    required this.id,
    required this.containmentId,
    this.location,
    this.qtyNg,
    this.qtySorted,
    this.sortingDate,
    this.dri,
    this.createdAt,
    this.updatedAt,
  });

  double? get ngPercentage {
    if (qtyNg == null ||
        qtySorted == null ||
        qtySorted == 0) {
      return null;
    }

    return (qtyNg! / qtySorted!) * 100;
  }

  factory CcrContainmentSorting.fromMap(
      Map<String, dynamic> map) {
    return CcrContainmentSorting(
      id: map['id']?.toString() ?? '',
      containmentId:
      map['containment_id']?.toString() ?? '',
      location: map['location']?.toString(),
      qtyNg: _parseNumber(map['qty_ng']),
      qtySorted: _parseNumber(map['qty_sorted']),
      sortingDate: _parseDate(map['sorting_date']),
      dri: map['dri']?.toString(),
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
    );
  }

  static double? _parseNumber(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().trim(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    return DateTime.tryParse(text);
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    return DateTime.tryParse(text);
  }
}