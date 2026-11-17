import 'package:flutter/material.dart';

import '../../services/ncr/ncr_service.dart';

class NcrDccDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> ncr;

  const NcrDccDetailsScreen({
    super.key,
    required this.ncr,
  });

  @override
  State<NcrDccDetailsScreen> createState() =>
      _NcrDccDetailsScreenState();
}

class _NcrDccDetailsScreenState
    extends State<NcrDccDetailsScreen> {
  final TextEditingController
  _commentsController =
  TextEditingController();

  bool _processing = false;

  Map<String, dynamic> get ncr =>
      widget.ncr;

  String _value(
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

  String _statusKey() {
    return (
        ncr['status_key'] ??
            ncr['statusKey'] ??
            ''
    )
        .toString()
        .toLowerCase()
        .trim();
  }

  String _statusName() {
    return (
        ncr['status_name'] ??
            ncr['statusName'] ??
            ncr['status'] ??
            'Unknown'
    ).toString();
  }

  String _date(
      List<String> keys,
      ) {
    final raw = _value(
      keys,
      fallback: '',
    );

    if (raw.isEmpty) {
      return '-';
    }

    final parsed =
    DateTime.tryParse(raw);

    if (parsed == null) {
      return raw;
    }

    return '${parsed.day.toString().padLeft(2, '0')}/'
        '${parsed.month.toString().padLeft(2, '0')}/'
        '${parsed.year}';
  }

  String _dateTime(
      List<String> keys,
      ) {
    final raw = _value(
      keys,
      fallback: '',
    );

    if (raw.isEmpty) {
      return '-';
    }

    final parsed =
    DateTime.tryParse(raw);

    if (parsed == null) {
      return raw;
    }

    return '${parsed.day.toString().padLeft(2, '0')}/'
        '${parsed.month.toString().padLeft(2, '0')}/'
        '${parsed.year} '
        '${parsed.hour.toString().padLeft(2, '0')}:'
        '${parsed.minute.toString().padLeft(2, '0')}';
  }

  bool get _canReview {
    return _statusKey() ==
        'sent_to_dcc';
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _value(
            ['ncr_number'],
            fallback: 'NCR Details',
          ),
        ),
      ),
      body: ListView(
        padding:
        const EdgeInsets.all(16),
        children: [
          _header(),

          const SizedBox(height: 16),

          _adminDetails(),

          const SizedBox(height: 16),

          _userActionPlan(),

          const SizedBox(height: 16),

          _hodReview(),

          const SizedBox(height: 16),

          _dccReview(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _header() {
    return Card(
      elevation: 2,
      child: Padding(
        padding:
        const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _value(
                  ['ncr_number'],
                  fallback: 'NCR',
                ),
                style:
                const TextStyle(
                  fontSize: 22,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
            _statusChip(
              _statusName(),
              _statusKey(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminDetails() {
    return _section(
      'Admin Created Details',
      Icons.admin_panel_settings_outlined,
      [
        _detail(
          'Process / Function',
          _value([
            'process_function',
          ]),
        ),
        _detail(
          'Clause / Section',
          _value([
            'clause_section',
          ]),
        ),
        _detail(
          'Auditee Name',
          _value([
            'auditee_name',
          ]),
        ),
        _detail(
          'Standard(s)',
          _value([
            'standard',
          ]),
        ),
        _detail(
          'Report No',
          _value([
            'report_no',
          ]),
        ),
        _detail(
          'IA No',
          _value([
            'ia_no',
          ]),
        ),
        _detail(
          'Auditor Name',
          _value([
            'auditor_name',
          ]),
        ),
        _detail(
          'Audit Date',
          _date([
            'audit_date',
          ]),
        ),
        _detail(
          'Finding / Nonconformity',
          _value([
            'finding_statement',
          ]),
        ),
        _detail(
          'Requirement / Clause Reference',
          _value([
            'requirement_clause_reference',
          ]),
        ),
      ],
    );
  }

  Widget _userActionPlan() {
    return _section(
      'User Action Plan',
      Icons.assignment_outlined,
      [
        _detail(
          'Root Causes',
          _value([
            'root_causes',
          ]),
        ),
        _detail(
          'Correction',
          _value([
            'correction',
          ]),
        ),
        _detail(
          'Correction Effective Date',
          _date([
            'correction_effective_date',
          ]),
        ),
        _detail(
          'Corrective Action',
          _value([
            'corrective_action',
          ]),
        ),
        _detail(
          'Corrective Action Effective Date',
          _date([
            'corrective_action_effective_date',
          ]),
        ),
        _detail(
          'Follow-up Audit Details',
          _value([
            'follow_up_audit_details',
          ]),
        ),
        _detail(
          'Follow-up Audit Date',
          _date([
            'follow_up_audit_date',
          ]),
        ),
        _detail(
          'Effectiveness of Corrective Action',
          _value([
            'effectiveness_of_corrective_action',
          ]),
        ),
        _detail(
          'Effectiveness Date',
          _date([
            'effectiveness_date',
          ]),
        ),
      ],
    );
  }

  Widget _hodReview() {
    return _section(
      'HOD Review',
      Icons.rate_review_outlined,
      [
        _detail(
          'HOD Decision',
          _value(
            ['hod_action'],
            fallback: 'Not decided',
          ),
        ),
        _detail(
          'HOD Comments',
          _value(
            ['hod_comments'],
            fallback: '-',
          ),
        ),
        _detail(
          'HOD Decision Date',
          _dateTime([
            'hod_action_at',
          ]),
        ),
      ],
    );
  }

  Widget _dccReview() {
    final dccAction = _value(
      ['dcc_action'],
      fallback: '',
    );

    final dccComments = _value(
      ['dcc_comments'],
      fallback: '',
    );

    return _section(
      'DCC Review',
      Icons.approval_outlined,
      [
        if (_canReview) ...[
          const Text(
            'DCC Review Comments',
            style: TextStyle(
              fontWeight:
              FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller:
            _commentsController,
            enabled: !_processing,
            minLines: 4,
            maxLines: 8,
            decoration:
            const InputDecoration(
              hintText:
              'Enter DCC comments',
              border:
              OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 18),

          _decisionButtons(),
        ] else ...[
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
            _dateTime([
              'dcc_action_at',
            ]),
          ),
        ],
      ],
    );
  }

  Widget _decisionButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          height: 46,
          child:
          ElevatedButton.icon(
            onPressed:
            _processing
                ? null
                : _approve,
            icon: const Icon(
              Icons.check,
            ),
            label: const Text(
              'Approve & Close',
            ),
          ),
        ),

        SizedBox(
          height: 46,
          child:
          OutlinedButton.icon(
            onPressed:
            _processing
                ? null
                : _reject,
            icon: const Icon(
              Icons.close,
            ),
            label: const Text(
              'Reject',
            ),
          ),
        ),
      ],
    );
  }

  Widget _section(
      String title,
      IconData icon,
      List<Widget> children,
      ) {
    return Card(
      elevation: 1,
      child: Padding(
        padding:
        const EdgeInsets.all(18),
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
                    style:
                    const TextStyle(
                      fontSize: 19,
                      fontWeight:
                      FontWeight.bold,
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

  Widget _detail(
      String label,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 14,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
              FontWeight.w600,
              color:
              Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 5),

          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.all(12),
            decoration:
            BoxDecoration(
              color:
              Colors.grey.shade50,
              borderRadius:
              BorderRadius.circular(
                7,
              ),
              border: Border.all(
                color:
                Colors.grey.shade200,
              ),
            ),
            child: SelectableText(
              value.isEmpty
                  ? '-'
                  : value,
              style:
              const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(
      String status,
      String statusKey,
      ) {
    Color color;

    switch (statusKey) {
      case 'sent_to_dcc':
        color = Colors.blue;
        break;
      case 'dcc_rejected':
        color = Colors.red;
        break;
      case 'closed':
        color = Colors.green;
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
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
      BoxDecoration(
        color:
        color.withOpacity(0.12),
        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow:
        TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontWeight:
          FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _approve() async {
    if (!_canReview ||
        _processing) {
      return;
    }

    final ncrId =
    _value(
      ['id'],
      fallback: '',
    );

    if (ncrId.isEmpty) {
      _showMessage(
        'NCR ID is missing.',
      );
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      await NcrService.dccApprove(
        ncrId: ncrId,
        comments:
        _commentsController.text
            .trim(),
      );

      if (!mounted) return;

      _showMessage(
        'NCR approved and closed.',
      );

      Navigator.of(context)
          .pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _processing = false;
      });

      _showMessage(
        'Approval failed: $e',
      );
    }
  }

  Future<void> _reject() async {
    if (!_canReview ||
        _processing) {
      return;
    }

    final comments =
    _commentsController.text
        .trim();

    if (comments.isEmpty) {
      _showMessage(
        'Comments are required when rejecting an NCR.',
      );
      return;
    }

    final ncrId =
    _value(
      ['id'],
      fallback: '',
    );

    if (ncrId.isEmpty) {
      _showMessage(
        'NCR ID is missing.',
      );
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      await NcrService.dccReject(
        ncrId: ncrId,
        comments: comments,
      );

      if (!mounted) return;

      _showMessage(
        'NCR rejected and returned for correction.',
      );

      Navigator.of(context)
          .pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _processing = false;
      });

      _showMessage(
        'Rejection failed: $e',
      );
    }
  }

  void _showMessage(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}