import 'package:flutter/material.dart';

import '../../services/ncr/ncr_service.dart';

class NcrHodDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> ncr;

  const NcrHodDetailsScreen({
    super.key,
    required this.ncr,
  });

  @override
  State<NcrHodDetailsScreen> createState() =>
      _NcrHodDetailsScreenState();
}

class _NcrHodDetailsScreenState
    extends State<NcrHodDetailsScreen> {
  final TextEditingController _commentsController =
  TextEditingController();

  bool _processing = false;

  Map<String, dynamic> get ncr => widget.ncr;

  // ============================================================
  // GET VALUE
  // ============================================================

  String _getValue(
      List<String> keys, {
        String fallback = '-',
      }) {
    for (final key in keys) {
      final value = ncr[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  // ============================================================
  // STATUS KEY
  // ============================================================

  String _getStatusKey() {
    return _getValue(
      [
        'status_key',
        'statusKey',
        'status',
      ],
      fallback: '',
    ).toLowerCase().trim();
  }

  // ============================================================
  // STATUS NAME
  // ============================================================

  String _getStatusName() {
    return _getValue(
      [
        'status_name',
        'statusName',
        'status',
      ],
      fallback: 'Unknown',
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(
      List<String> keys, {
        String fallback = '-',
      }) {
    final raw = _getValue(
      keys,
      fallback: '',
    );

    if (raw.isEmpty) {
      return fallback;
    }

    final date = DateTime.tryParse(raw);

    if (date == null) {
      return raw;
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // FORMAT DATE TIME
  // ============================================================

  String _formatDateTime(
      List<String> keys, {
        String fallback = '-',
      }) {
    final raw = _getValue(
      keys,
      fallback: '',
    );

    if (raw.isEmpty) {
      return fallback;
    }

    final date = DateTime.tryParse(raw);

    if (date == null) {
      return raw;
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // CAN REVIEW
  // ============================================================

  bool get _canReview {
    return _getStatusKey() == 'submitted_to_hod';
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final ncrNumber = _getValue(
      [
        'ncr_number',
        'ncrNumber',
      ],
      fallback: 'NCR Details',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(ncrNumber),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),

          const SizedBox(height: 16),

          _buildAdminDetails(),

          const SizedBox(height: 16),

          _buildUserActionPlan(),

          const SizedBox(height: 16),

          _buildHodReview(),

          const SizedBox(height: 16),

          _buildDccInformation(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    _getValue(
                      [
                        'ncr_number',
                        'ncrNumber',
                      ],
                      fallback: 'NCR',
                    ),
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'HOD NCR Details',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            _buildStatusChip(
              _getStatusName(),
              _getStatusKey(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ADMIN CREATED DETAILS
  // ============================================================

  Widget _buildAdminDetails() {
    return _buildSection(
      title: 'Admin Created Details',
      icon: Icons.admin_panel_settings_outlined,
      children: [
        _detail(
          'Process / Function',
          _getValue([
            'process_function',
            'processFunction',
          ]),
        ),

        _detail(
          'Clause / Section',
          _getValue([
            'clause_section',
            'clauseSection',
          ]),
        ),

        _detail(
          'Auditee Name',
          _getValue([
            'auditee_name',
            'auditeeName',
            'auditee_full_name',
          ]),
        ),

        _detail(
          'Standard(s)',
          _getValue([
            'standard',
            'standards',
          ]),
        ),

        _detail(
          'Report No',
          _getValue([
            'report_no',
            'reportNo',
          ]),
        ),

        _detail(
          'IA No',
          _getValue([
            'ia_no',
            'iaNo',
          ]),
        ),

        _detail(
          'Auditor Name',
          _getValue([
            'auditor_name',
            'auditorName',
            'auditor_full_name',
          ]),
        ),

        _detail(
          'Audit Date',
          _formatDate([
            'audit_date',
            'auditDate',
          ]),
        ),

        _detail(
          'Finding / Nonconformity',
          _getValue([
            'finding_statement',
            'findingStatement',
          ]),
        ),

        _detail(
          'Requirement / Clause Reference',
          _getValue([
            'requirement_clause_reference',
            'requirementClauseReference',
          ]),
        ),
      ],
    );
  }

  // ============================================================
  // USER ACTION PLAN
  // ============================================================

  Widget _buildUserActionPlan() {
    return _buildSection(
      title: 'User Action Plan',
      icon: Icons.assignment_outlined,
      children: [
        _detail(
          'Root Causes',
          _getValue([
            'root_causes',
            'rootCauses',
          ]),
        ),

        _detail(
          'Correction',
          _getValue([
            'correction',
          ]),
        ),

        _detail(
          'Correction Effective Date',
          _formatDate([
            'correction_effective_date',
            'correctionEffectiveDate',
          ]),
        ),

        _detail(
          'Corrective Action',
          _getValue([
            'corrective_action',
            'correctiveAction',
          ]),
        ),

        _detail(
          'Corrective Action Effective Date',
          _formatDate([
            'corrective_action_effective_date',
            'correctiveActionEffectiveDate',
          ]),
        ),

        _detail(
          'Follow-up Audit Details',
          _getValue([
            'follow_up_audit_details',
            'followUpAuditDetails',
          ]),
        ),

        _detail(
          'Follow-up Audit Date',
          _formatDate([
            'follow_up_audit_date',
            'followUpAuditDate',
          ]),
        ),

        _detail(
          'Effectiveness of Corrective Action',
          _getValue([
            'effectiveness_of_corrective_action',
            'effectivenessOfCorrectiveAction',
          ]),
        ),

        _detail(
          'Effectiveness Date',
          _formatDate([
            'effectiveness_date',
            'effectivenessDate',
          ]),
        ),
      ],
    );
  }

  // ============================================================
  // HOD REVIEW
  // ============================================================

  Widget _buildHodReview() {
    final hodAction = _getValue(
      [
        'hod_action',
        'hodAction',
      ],
      fallback: '',
    );

    final hodComments = _getValue(
      [
        'hod_comments',
        'hodComments',
      ],
      fallback: '',
    );

    return _buildSection(
      title: 'HOD Review',
      icon: Icons.rate_review_outlined,
      children: [
        if (_canReview) ...[
          const Text(
            'Review Comments',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: _commentsController,
            enabled: !_processing,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText:
              'Enter HOD review comments',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 18),

          _buildDecisionButtons(),
        ] else ...[
          _detail(
            'HOD Decision',
            hodAction.isEmpty
                ? 'Not decided'
                : hodAction,
          ),

          _detail(
            'HOD Comments',
            hodComments.isEmpty
                ? '-'
                : hodComments,
          ),

          _detail(
            'HOD Decision Date',
            _formatDateTime([
              'hod_action_at',
              'hodActionAt',
            ]),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // APPROVE / REJECT BUTTONS
  // ============================================================

  Widget _buildDecisionButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          height: 46,
          child: ElevatedButton.icon(
            onPressed:
            _processing ? null : _approve,
            icon: _processing
                ? const SizedBox(
              height: 18,
              width: 18,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Icon(
              Icons.check,
            ),
            label: const Text('Approve'),
          ),
        ),

        SizedBox(
          height: 46,
          child: OutlinedButton.icon(
            onPressed:
            _processing ? null : _reject,
            icon: const Icon(
              Icons.close,
            ),
            label: const Text('Reject'),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DCC INFORMATION
  // ============================================================

  Widget _buildDccInformation() {
    final dccAction = _getValue(
      [
        'dcc_action',
        'dccAction',
      ],
      fallback: '',
    );

    final dccComments = _getValue(
      [
        'dcc_comments',
        'dccComments',
      ],
      fallback: '',
    );

    final statusKey = _getStatusKey();

    final shouldShow =
        dccAction.isNotEmpty ||
            dccComments.isNotEmpty ||
            statusKey == 'sent_to_dcc' ||
            statusKey == 'dcc_rejected' ||
            statusKey == 'closed';

    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'DCC Information',
      icon: Icons.approval_outlined,
      children: [
        _detail(
          'DCC Decision',
          dccAction.isEmpty
              ? 'Not decided'
              : dccAction,
        ),

        _detail(
          'DCC Comments',
          dccComments.isEmpty
              ? '-'
              : dccComments,
        ),

        _detail(
          'DCC Decision Date',
          _formatDateTime([
            'dcc_action_at',
            'dccActionAt',
          ]),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),

                const SizedBox(width: 9),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(
              height: 26,
            ),

            ...children,
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL FIELD
  // ============================================================

  Widget _detail(
      String label,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 5),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
              BorderRadius.circular(7),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: SelectableText(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _buildStatusChip(
      String status,
      String statusKey,
      ) {
    Color color;

    switch (statusKey) {
      case 'submitted_to_hod':
        color = Colors.orange;
        break;

      case 'hod_rejected':
        color = Colors.red;
        break;

      case 'sent_to_dcc':
        color = Colors.blue;
        break;

      case 'dcc_rejected':
        color = Colors.red;
        break;

      case 'closed':
        color = Colors.green;
        break;

      case 'assigned':
      case 'in_progress':
        color = Colors.amber.shade800;
        break;

      default:
        color = Colors.grey;
    }

    return Container(
      constraints:
      const BoxConstraints(
        maxWidth: 180,
      ),
      padding:
      const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // ============================================================
  // APPROVE
  // ============================================================

  Future<void> _approve() async {
    if (!_canReview || _processing) {
      return;
    }

    final ncrId = _getValue(
      ['id'],
      fallback: '',
    );

    if (ncrId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'NCR ID is missing.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      await NcrService.hodApprove(
        ncrId: ncrId,
        comments:
        _commentsController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'NCR approved and sent to DCC.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _processing = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Approval failed: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // REJECT
  // ============================================================

  Future<void> _reject() async {
    if (!_canReview || _processing) {
      return;
    }

    final comments =
    _commentsController.text.trim();

    if (comments.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Comments are required when rejecting an NCR.',
          ),
        ),
      );

      return;
    }

    final ncrId = _getValue(
      ['id'],
      fallback: '',
    );

    if (ncrId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'NCR ID is missing.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      await NcrService.hodReject(
        ncrId: ncrId,
        comments: comments,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'NCR rejected and returned for correction.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _processing = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Rejection failed: $e',
          ),
        ),
      );
    }
  }
}