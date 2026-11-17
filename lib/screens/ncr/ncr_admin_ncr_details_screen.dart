import 'package:flutter/material.dart';

import '../../services/ncr/ncr_service.dart';

class NcrAdminNcrDetailsScreen
    extends StatefulWidget {
  final String ncrId;

  const NcrAdminNcrDetailsScreen({
    super.key,
    required this.ncrId,
  });

  @override
  State<NcrAdminNcrDetailsScreen>
  createState() =>
      _NcrAdminNcrDetailsScreenState();
}

class _NcrAdminNcrDetailsScreenState
    extends State<NcrAdminNcrDetailsScreen> {
  Map<String, dynamic>? _ncr;
  List<Map<String, dynamic>> _history = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadDetails() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        NcrService.getNcrById(
          widget.ncrId,
        ),
        NcrService.getApprovalHistory(
          widget.ncrId,
        ),
      ]);

      final ncr =
      results[0] as dynamic;

      final history =
      results[1]
      as List<Map<String, dynamic>>;

      if (!mounted) {
        return;
      }

      if (ncr == null) {
        throw Exception(
          'NCR record could not be found.',
        );
      }

      setState(() {
        _ncr = _recordToMap(ncr);
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = e
            .toString()
            .replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  // ============================================================
  // RECORD CONVERSION
  // ============================================================

  Map<String, dynamic> _recordToMap(
      dynamic record,
      ) {
    if (record is Map<String, dynamic>) {
      return Map<String, dynamic>.from(
        record,
      );
    }

    try {
      final dynamic map =
      record.toMap();

      if (map is Map) {
        return Map<String, dynamic>.from(
          map,
        );
      }
    } catch (_) {}

    final result =
    <String, dynamic>{};

    try {
      result['id'] = record.id;
    } catch (_) {}

    try {
      result['ncr_number'] =
          record.ncrNumber;
    } catch (_) {}

    try {
      result['process_function'] =
          record.processFunction;
    } catch (_) {}

    try {
      result['clause_section'] =
          record.clauseSection;
    } catch (_) {}

    try {
      result['auditee_name'] =
          record.auditeeName;
    } catch (_) {}

    try {
      result['auditor_name'] =
          record.auditorName;
    } catch (_) {}

    try {
      result['standard'] =
          record.standard;
    } catch (_) {}

    try {
      result['report_no'] =
          record.reportNo;
    } catch (_) {}

    try {
      result['ia_no'] =
          record.iaNo;
    } catch (_) {}

    try {
      result['audit_date'] =
          record.auditDate
              ?.toIso8601String();
    } catch (_) {}

    try {
      result['finding_statement'] =
          record.findingStatement;
    } catch (_) {}

    try {
      result[
      'requirement_clause_reference'] =
          record.requirementClauseReference;
    } catch (_) {}

    try {
      result['status_key'] =
          record.statusKey;
    } catch (_) {}

    try {
      result['status_name'] =
          record.statusName;
    } catch (_) {}

    try {
      result['root_causes'] =
          record.rootCauses;
    } catch (_) {}

    try {
      result['correction'] =
          record.correction;
    } catch (_) {}

    try {
      result[
      'correction_effective_date'] =
          record.correctionEffectiveDate
              ?.toIso8601String();
    } catch (_) {}

    try {
      result['corrective_action'] =
          record.correctiveAction;
    } catch (_) {}

    try {
      result[
      'corrective_action_effective_date'] =
          record.correctiveActionEffectiveDate
              ?.toIso8601String();
    } catch (_) {}

    try {
      result[
      'follow_up_audit_details'] =
          record.followUpAuditDetails;
    } catch (_) {}

    try {
      result['follow_up_audit_date'] =
          record.followUpAuditDate
              ?.toIso8601String();
    } catch (_) {}

    try {
      result[
      'effectiveness_of_corrective_action'] =
          record.effectivenessOfCorrectiveAction;
    } catch (_) {}

    try {
      result['effectiveness_date'] =
          record.effectivenessDate
              ?.toIso8601String();
    } catch (_) {}

    try {
      result['hod_action'] =
          record.hodAction;
    } catch (_) {}

    try {
      result['hod_comments'] =
          record.hodComments;
    } catch (_) {}

    try {
      result['dcc_action'] =
          record.dccAction;
    } catch (_) {}

    try {
      result['dcc_comments'] =
          record.dccComments;
    } catch (_) {}

    try {
      result['closed_at'] =
          record.closedAt
              ?.toIso8601String();
    } catch (_) {}

    return result;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          tooltip: 'Back',
          icon:
          const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          _ncr?['ncr_number']
              ?.toString() ??
              'NCR Details',
          style: const TextStyle(
            fontWeight:
            FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon:
            const Icon(Icons.refresh),
            onPressed:
            _isLoading
                ? null
                : _loadDetails,
          ),
          const SizedBox(
            width: 8,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : _errorMessage != null
          ? _errorView()
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final ncr =
        _ncr ?? {};

    return SingleChildScrollView(
      padding:
      const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 1200,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _pageHeader(ncr),

              const SizedBox(
                height: 22,
              ),

              _section(
                title:
                'Audit Information',
                icon:
                Icons.fact_check_outlined,
                children: [
                  _grid(
                    [
                      _field(
                        'NCR Number',
                        ncr[
                        'ncr_number']
                            ?.toString(),
                      ),
                      _field(
                        'Process / Function',
                        ncr[
                        'process_function']
                            ?.toString(),
                      ),
                      _field(
                        'Clause / Section',
                        ncr[
                        'clause_section']
                            ?.toString(),
                      ),
                      _field(
                        'Standard(s)',
                        ncr[
                        'standard']
                            ?.toString(),
                      ),
                      _field(
                        'Report No',
                        ncr[
                        'report_no']
                            ?.toString(),
                      ),
                      _field(
                        'IA No',
                        ncr[
                        'ia_no']
                            ?.toString(),
                      ),
                      _field(
                        'Auditee Name',
                        ncr[
                        'auditee_name']
                            ?.toString(),
                      ),
                      _field(
                        'Auditor Name',
                        ncr[
                        'auditor_name']
                            ?.toString(),
                      ),
                      _field(
                        'Audit Date',
                        _formatDate(
                          ncr[
                          'audit_date'],
                        ),
                      ),
                      _field(
                        'Current Status',
                        ncr[
                        'status_name']
                            ?.toString()
                            .isNotEmpty ==
                            true
                            ? ncr[
                        'status_name']
                            ?.toString()
                            : ncr[
                        'status_key']
                            ?.toString(),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
              ),

              _section(
                title:
                'Non-Conformity Details',
                icon:
                Icons.warning_amber_outlined,
                children: [
                  _largeField(
                    'Audit Finding / Nonconformity Statement',
                    ncr[
                    'finding_statement']
                        ?.toString(),
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                  _largeField(
                    'Requirement / Clause Reference',
                    ncr[
                    'requirement_clause_reference']
                        ?.toString(),
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
              ),

              _section(
                title:
                'Corrective Action Plan',
                icon:
                Icons.build_circle_outlined,
                children: [
                  _largeField(
                    'Root Cause(s)',
                    ncr[
                    'root_causes']
                        ?.toString(),
                  ),
                  _largeField(
                    'Correction (Immediate Containment)',
                    ncr[
                    'correction']
                        ?.toString(),
                  ),
                  _field(
                    'Correction Effective Date',
                    _formatDate(
                      ncr[
                      'correction_effective_date'],
                    ),
                  ),
                  _largeField(
                    'Corrective Action (to address Root Cause)',
                    ncr[
                    'corrective_action']
                        ?.toString(),
                  ),
                  _field(
                    'Corrective Action Effective Date',
                    _formatDate(
                      ncr[
                      'corrective_action_effective_date'],
                    ),
                  ),
                  _largeField(
                    'Follow-up Audit Details',
                    ncr[
                    'follow_up_audit_details']
                        ?.toString(),
                  ),
                  _field(
                    'Follow-up Audit Date',
                    _formatDate(
                      ncr[
                      'follow_up_audit_date'],
                    ),
                  ),
                  _largeField(
                    'Effectiveness of Corrective Action Implementation',
                    ncr[
                    'effectiveness_of_corrective_action']
                        ?.toString(),
                  ),
                  _field(
                    'Effectiveness Date',
                    _formatDate(
                      ncr[
                      'effectiveness_date'],
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
              ),

              _approvalSection(
                title: 'HOD Review',
                actionKey:
                'hod_action',
                commentsKey:
                'hod_comments',
                icon:
                Icons.fact_check_outlined,
              ),

              const SizedBox(
                height: 18,
              ),

              _approvalSection(
                title: 'DCC Review',
                actionKey:
                'dcc_action',
                commentsKey:
                'dcc_comments',
                icon:
                Icons.approval_outlined,
              ),

              const SizedBox(
                height: 18,
              ),

              _historySection(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _pageHeader(
      Map<String, dynamic> ncr,
      ) {
    final status =
    ncr['status_name']
        ?.toString()
        .trim()
        .isNotEmpty ==
        true
        ? ncr['status_name']
        .toString()
        : ncr['status_key']
        ?.toString() ??
        'Unknown';

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xFFE2E7EF),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFFEFF3FF,
              ),
              borderRadius:
              BorderRadius.circular(
                15,
              ),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color:
              Color(0xFF3155D9),
              size: 30,
            ),
          ),
          const SizedBox(
            width: 17,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  ncr['ncr_number']
                      ?.toString() ??
                      'NCR',
                  style:
                  const TextStyle(
                    fontSize: 22,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  ncr['process_function']
                      ?.toString() ??
                      '',
                  style: TextStyle(
                    color:
                    Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          _statusChip(status),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xFFE2E7EF),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 22,
                color:
                const Color(
                  0xFF3155D9,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Text(
                title,
                style:
                const TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _grid(
      List<Widget> fields,
      ) {
    return LayoutBuilder(
      builder:
          (context, constraints) {
        final wide =
            constraints.maxWidth >= 750;

        if (!wide) {
          return Column(
            children:
            fields
                .map(
                  (field) =>
                  Padding(
                    padding:
                    const EdgeInsets
                        .only(
                      bottom: 15,
                    ),
                    child: field,
                  ),
            )
                .toList(),
          );
        }

        final rows =
        <Widget>[];

        for (
        var i = 0;
        i < fields.length;
        i += 2
        ) {
          rows.add(
            Padding(
              padding:
              const EdgeInsets.only(
                bottom: 15,
              ),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child:
                    fields[i],
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child:
                    i + 1 <
                        fields.length
                        ? fields[
                    i + 1]
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: rows,
        );
      },
    );
  }

  Widget _field(
      String label,
      String? value,
      ) {
    final text =
    value?.trim().isNotEmpty ==
        true
        ? value!.trim()
        : 'Not provided';

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color:
        const Color(0xFFF8F9FC),
        borderRadius:
        BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color:
              Colors.grey.shade600,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            text,
            style:
            const TextStyle(
              fontSize: 14,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _largeField(
      String label,
      String? value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 15,
      ),
      child: _field(
        label,
        value,
      ),
    );
  }

  // ============================================================
  // APPROVAL
  // ============================================================

  Widget _approvalSection({
    required String title,
    required String actionKey,
    required String commentsKey,
    required IconData icon,
  }) {
    final action =
    _ncr?[actionKey]
        ?.toString();

    final comments =
    _ncr?[commentsKey]
        ?.toString();

    return _section(
      title: title,
      icon: icon,
      children: [
        _grid(
          [
            _field(
              'Action',
              action,
            ),
            _field(
              'Comments',
              comments,
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // HISTORY
  // ============================================================

  Widget _historySection() {
    return _section(
      title: 'Approval History',
      icon:
      Icons.history_outlined,
      children: [
        if (_history.isEmpty)
          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.all(25),
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFFF8F9FC,
              ),
              borderRadius:
              BorderRadius.circular(
                10,
              ),
            ),
            child: Text(
              'No approval history available yet.',
              style: TextStyle(
                color:
                Colors.grey.shade600,
              ),
            ),
          )
        else
          ..._history.map(
                (item) =>
                _historyItem(item),
          ),
      ],
    );
  }

  Widget _historyItem(
      Map<String, dynamic> item,
      ) {
    final action =
    item['action']
        ?.toString()
        .trim()
        .isNotEmpty ==
        true
        ? item['action'].toString()
        : 'Action';

    final user =
        item['action_by_name']
            ?.toString() ??
            'Unknown user';

    final role =
        item['action_role_name']
            ?.toString() ??
            item['action_role_key']
                ?.toString() ??
            '';

    final comments =
        item['comments']
            ?.toString() ??
            '';

    final date =
    _formatDateTime(
      item['created_at'],
    );

    final previous =
        item['previous_status_name']
            ?.toString() ??
            item['previous_status_key']
                ?.toString() ??
            '';

    final next =
        item['new_status_name']
            ?.toString() ??
            item['new_status_key']
                ?.toString() ??
            '';

    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
      const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color:
        const Color(0xFFF8F9FC),
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color:
          const Color(0xFFE2E7EF),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  action,
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color:
                  Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 7,
          ),
          Text(
            '$user${role.isEmpty ? '' : ' • $role'}',
            style: TextStyle(
              fontSize: 13,
              color:
              Colors.grey.shade700,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          if (previous.isNotEmpty ||
              next.isNotEmpty)
            Text(
              '$previous  →  $next',
              style:
              const TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          if (comments.trim().isNotEmpty) ...[
            const SizedBox(
              height: 8,
            ),
            Text(
              comments,
              style:
              const TextStyle(
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _errorView() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(30),
        child: Container(
          constraints:
          const BoxConstraints(
            maxWidth: 700,
          ),
          padding:
          const EdgeInsets.all(25),
          decoration:
          BoxDecoration(
            color:
            Colors.red.shade50,
            borderRadius:
            BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color:
              Colors.red.shade200,
            ),
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color:
                Colors.red.shade700,
              ),
              const SizedBox(
                height: 14,
              ),
              Text(
                _errorMessage ??
                    'Unable to load NCR.',
                textAlign:
                TextAlign.center,
                style:
                TextStyle(
                  color:
                  Colors.red.shade800,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              FilledButton(
                onPressed:
                _loadDetails,
                child:
                const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Widget _statusChip(
      String status,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color:
        const Color(0xFFEFF3FF),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style:
        const TextStyle(
          fontSize: 12,
          fontWeight:
          FontWeight.w700,
          color:
          Color(0xFF3155D9),
        ),
      ),
    );
  }

  String _formatDate(
      dynamic value,
      ) {
    if (value == null) {
      return 'Not provided';
    }

    final date =
    DateTime.tryParse(
      value.toString(),
    );

    if (date == null) {
      return value.toString();
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatDateTime(
      dynamic value,
      ) {
    if (value == null) {
      return 'Not provided';
    }

    final date =
    DateTime.tryParse(
      value.toString(),
    );

    if (date == null) {
      return value.toString();
    }

    final local =
    date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}