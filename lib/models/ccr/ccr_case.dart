class CcrCase {
  final String id;
  final int ccrNumber;

  final String? statusKey;
  final String? statusName;

  final String? currentStageKey;
  final String? currentStageName;

  final DateTime? complaintDate;
  final String? complaintSource;

  final String? customerName;
  final String? teamLeader;
  final String? groupName;

  final String? customerContactName;
  final String? customerContactPosition;
  final String? customerContactCompany;

  final String? customerPartNumber;
  final String? supplierPartNumber;

  final String? problemDescription;
  final String? complaintDescription;
  final String? customerLocation;

// Registration screen fields
  final String? partDescription;
  final String? partNo;
  final num? qty;

  final DateTime? detectedDate;
  final String? detectedBy;

  final DateTime createdAt;
  final DateTime updatedAt;

  const CcrCase({
    required this.id,
    required this.ccrNumber,
    required this.createdAt,
    required this.updatedAt,
    this.statusKey,
    this.statusName,
    this.currentStageKey,
    this.currentStageName,
    this.complaintDate,
    this.complaintSource,
    this.customerName,
    this.teamLeader,
    this.groupName,
    this.customerContactName,
    this.customerContactPosition,
    this.customerContactCompany,
    this.customerPartNumber,
    this.supplierPartNumber,
    this.problemDescription,
    this.complaintDescription,
    this.customerLocation,

    this.partDescription,
    this.partNo,
    this.qty,
    this.detectedDate,
    this.detectedBy,
  });

  factory CcrCase.fromMap(
      Map<String, dynamic> map,
      ) {
    DateTime? parseDate(dynamic value) {
      if (value == null) {
        return null;
      }

      return DateTime.tryParse(
        value.toString(),
      );
    }

    String? relationName(
        dynamic relation,
        String field,
        ) {
      // Supabase normally returns a single
      // related row as a Map.
      if (relation is Map) {
        return relation[field]?.toString();
      }

      // Keep this fallback in case the
      // relationship is returned as a list.
      if (relation is List &&
          relation.isNotEmpty &&
          relation.first is Map) {
        return relation.first[field]?.toString();
      }

      return null;
    }

    final String? nestedStatusName =
    relationName(
      map['ccr_statuses'],
      'status_name',
    );

    final String? nestedStageName =
    relationName(
      map['ccr_workflow_stages'],
      'stage_name',
    );

    return CcrCase(
      id: map['id']?.toString() ?? '',

      ccrNumber:
      int.tryParse(
        map['ccr_number']?.toString() ?? '',
      ) ??
          0,

      statusKey:
      map['status']?.toString(),

      // Prefer the nested master-table value.
      // Keep flat-field fallback for compatibility.
      statusName:
      nestedStatusName ??
          map['status_name']?.toString(),

      currentStageKey:
      map['current_stage']?.toString(),

      // Prefer the nested workflow master value.
      // Keep flat-field fallback for compatibility.
      currentStageName:
      nestedStageName ??
          map['stage_name']?.toString(),

      complaintDate:
      parseDate(
        map['complaint_date'],
      ),

      complaintSource:
      map['complaint_source']?.toString(),

      customerName:
      map['customer_name']?.toString(),

      teamLeader:
      map['team_leader']?.toString(),

      groupName:
      map['group_name']?.toString(),

      customerContactName:
      map['customer_contact_name']?.toString(),

      customerContactPosition:
      map['customer_contact_position']?.toString(),

      customerContactCompany:
      map['customer_contact_company']?.toString(),

      customerPartNumber:
      map['customer_part_number']?.toString(),

      supplierPartNumber:
      map['supplier_part_number']?.toString(),

      problemDescription:
      map['problem_description']?.toString(),

      customerLocation:
      map['customer_location']?.toString(),

      partDescription:
      map['part_description']?.toString(),

      partNo:
      map['part_no']?.toString(),

      qty:
      num.tryParse(
        map['qty']?.toString() ?? '',
      ),

      complaintDescription:
      map['complaint_description']?.toString(),

      detectedDate:
      parseDate(
        map['detected_date'],
      ),

      detectedBy:
      map['detected_by']?.toString(),
      createdAt:
      parseDate(
        map['created_at'],
      ) ??
          DateTime.now(),

      updatedAt:
      parseDate(
        map['updated_at'],
      ) ??
          DateTime.now(),
    );
  }

  String get displayNumber {
    if (ccrNumber <= 0) {
      return 'CCR';
    }

    return 'CCR-${ccrNumber.toString().padLeft(6, '0')}';
  }

  bool get isDraft =>
      statusKey?.trim().toLowerCase() ==
          'draft';

  bool get isClosed =>
      statusKey?.trim().toLowerCase() ==
          'closed';

  bool get isReopened =>
      statusKey?.trim().toLowerCase() ==
          'reopened';
}