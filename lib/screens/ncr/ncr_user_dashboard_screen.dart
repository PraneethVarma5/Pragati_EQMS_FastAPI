import 'package:flutter/material.dart';

import '../../services/ncr/ncr_auth_service.dart';
import '../../services/ncr/ncr_service.dart';
import '../../services/ncr/ncr_session.dart';

class NcrUserDashboardScreen
    extends StatefulWidget {
  const NcrUserDashboardScreen({
    super.key,
  });

  @override
  State<NcrUserDashboardScreen>
  createState() =>
      _NcrUserDashboardScreenState();
}

class _NcrUserDashboardScreenState
    extends State<NcrUserDashboardScreen> {
  List<Map<String, dynamic>> _records = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadRecords() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final records =
      await NcrService.getAssignedNcrs();

      if (!mounted) {
        return;
      }

      setState(() {
        _records = records;
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
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    await NcrAuthService.logout();

    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/NCR',
          (route) => false,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user =
        NcrSession.currentUser;

    if (user == null ||
        !NcrSession.isUser) {
      WidgetsBinding.instance
          .addPostFrameCallback(
            (_) {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/NCR/login',
            );
          }
        },
      );

      return const Scaffold(
        body: Center(
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
        Colors.white,
        surfaceTintColor:
        Colors.white,

        leading: IconButton(
          tooltip: 'NCR Home',
          icon:
          const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/NCR',
                  (route) => false,
            );
          },
        ),

        title: const Text(
          'NCR User Dashboard',
          style: TextStyle(
            fontWeight:
            FontWeight.w800,
          ),
        ),

        actions: [
          Container(
            margin:
            const EdgeInsets.symmetric(
              vertical: 11,
            ),
            padding:
            const EdgeInsets.symmetric(
              horizontal: 14,
            ),
            decoration:
            BoxDecoration(
              color:
              const Color(0xFFEAF0FF),
              borderRadius:
              BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                user.roleName
                    .trim()
                    .isEmpty
                    ? 'USER'
                    : user.roleName,
                style:
                const TextStyle(
                  fontWeight:
                  FontWeight.w700,
                  color:
                  Color(0xFF3155D9),
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          IconButton(
            tooltip: 'Refresh',
            icon:
            const Icon(Icons.refresh),
            onPressed:
            _isLoading
                ? null
                : _loadRecords,
          ),

          IconButton(
            tooltip: 'Logout',
            icon:
            const Icon(Icons.logout),
            onPressed: _logout,
          ),

          const SizedBox(
            width: 8,
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadRecords,
        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${user.fullName}',
                style:
                const TextStyle(
                  fontSize: 28,
                  fontWeight:
                  FontWeight.w800,
                  color:
                  Color(0xFF172033),
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                'NCRs assigned to you for corrective action.',
                style: TextStyle(
                  fontSize: 14,
                  color:
                  Colors.grey.shade600,
                ),
              ),

              const SizedBox(
                height: 28,
              ),

              _summary(),

              const SizedBox(
                height: 28,
              ),

              const Text(
                'My Assigned NCRs',
                style:
                TextStyle(
                  fontSize: 21,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              if (_errorMessage != null)
                _errorCard(),

              if (_isLoading)
                _loading()
              else if (_records.isEmpty)
                _empty()
              else
                _recordsList(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _summary() {
    final total =
        _records.length;

    final submitted =
        _records.where(
              (record) =>
          record['status_key']
              ?.toString() ==
              'submitted_to_hod',
        ).length;

    final rejected =
        _records.where(
              (record) {
            final key =
            record['status_key']
                ?.toString();

            return key ==
                'hod_rejected' ||
                key ==
                    'dcc_rejected';
          },
        ).length;

    final closed =
        _records.where(
              (record) =>
          record['status_key']
              ?.toString() ==
              'closed',
        ).length;

    return LayoutBuilder(
      builder:
          (context, constraints) {
        final width =
            constraints.maxWidth;

        final cardWidth =
        width >= 900
            ? (width - 48) / 4
            : width >= 600
            ? (width - 16) / 2
            : width;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _stat(
              width: cardWidth,
              title: 'Assigned',
              value: total,
              icon:
              Icons.assignment_outlined,
            ),
            _stat(
              width: cardWidth,
              title: 'Submitted',
              value: submitted,
              icon:
              Icons.send_outlined,
            ),
            _stat(
              width: cardWidth,
              title: 'Needs Correction',
              value: rejected,
              icon:
              Icons.edit_note_outlined,
            ),
            _stat(
              width: cardWidth,
              title: 'Closed',
              value: closed,
              icon:
              Icons.check_circle_outline,
            ),
          ],
        );
      },
    );
  }

  Widget _stat({
    required double width,
    required String title,
    required int value,
    required IconData icon,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        height: 125,
        padding:
        const EdgeInsets.all(18),
        decoration:
        BoxDecoration(
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
              width: 48,
              height: 48,
              decoration:
              BoxDecoration(
                color:
                const Color(0xFFEFF3FF),
                borderRadius:
                BorderRadius.circular(
                  13,
                ),
              ),
              child: Icon(
                icon,
                color:
                const Color(
                  0xFF3155D9,
                ),
              ),
            ),
            const SizedBox(
              width: 14,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                    TextStyle(
                      fontSize: 13,
                      color:
                      Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    '$value',
                    style:
                    const TextStyle(
                      fontSize: 27,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RECORD LIST
  // ============================================================

  Widget _recordsList() {
    return Column(
      children:
      _records.map(
            (record) {
          return Padding(
            padding:
            const EdgeInsets.only(
              bottom: 14,
            ),
            child:
            _recordCard(record),
          );
        },
      ).toList(),
    );
  }

  Widget _recordCard(
      Map<String, dynamic> record,
      ) {
    final status =
    record['status_name']
        ?.toString()
        .trim()
        .isNotEmpty ==
        true
        ? record['status_name']
        .toString()
        : record['status_key']
        ?.toString() ??
        'Unknown';

    return Material(
      color: Colors.white,
      borderRadius:
      BorderRadius.circular(16),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(16),
        onTap: () {
          _openActionPlan(record);
        },
        child: Container(
          width: double.infinity,
          padding:
          const EdgeInsets.all(20),
          decoration:
          BoxDecoration(
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
                  Expanded(
                    child: Text(
                      record['ncr_number']
                          ?.toString() ??
                          'NCR',
                      style:
                      const TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                  ),
                  _statusChip(status),
                ],
              ),

              const SizedBox(
                height: 14,
              ),

              Text(
                record['process_function']
                    ?.toString() ??
                    '',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                record[
                'finding_statement']
                    ?.toString() ??
                    'No finding statement',
                maxLines: 2,
                overflow:
                TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                  Colors.grey.shade600,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              Row(
                mainAxisAlignment:
                MainAxisAlignment.end,
                children: [
                  const Text(
                    'Open Action Plan',
                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight.w700,
                      color:
                      Color(0xFF3155D9),
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    size: 17,
                    color:
                    Color(0xFF3155D9),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACTION PLAN
  // ============================================================

  Future<void> _openActionPlan(
      Map<String, dynamic> record,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _NcrUserActionPlanScreen(
              record: record,
            ),
      ),
    );

    if (mounted) {
      await _loadRecords();
    }
  }

  // ============================================================
  // STATES
  // ============================================================

  Widget _loading() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(50),
      decoration:
      _boxDecoration(),
      child: const Center(
        child:
        CircularProgressIndicator(),
      ),
    );
  }

  Widget _empty() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(50),
      decoration:
      _boxDecoration(),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 55,
            color:
            Colors.grey.shade400,
          ),
          const SizedBox(
            height: 12,
          ),
          const Text(
            'No NCRs are currently assigned to you.',
            style:
            TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(
        bottom: 18,
      ),
      padding:
      const EdgeInsets.all(18),
      decoration:
      BoxDecoration(
        color:
        Colors.red.shade50,
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color:
          Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color:
            Colors.red.shade700,
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Text(
              _errorMessage ??
                  'Unable to load NCRs.',
              style:
              TextStyle(
                color:
                Colors.red.shade800,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius:
      BorderRadius.circular(16),
      border: Border.all(
        color:
        const Color(0xFFE2E7EF),
      ),
    );
  }

  Widget _statusChip(
      String status,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration:
      BoxDecoration(
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
}


// ============================================================
// USER ACTION PLAN SCREEN
// ============================================================

class _NcrUserActionPlanScreen
    extends StatefulWidget {
  final Map<String, dynamic> record;

  const _NcrUserActionPlanScreen({
    required this.record,
  });

  @override
  State<_NcrUserActionPlanScreen>
  createState() =>
      _NcrUserActionPlanScreenState();
}

class _NcrUserActionPlanScreenState
    extends State<_NcrUserActionPlanScreen> {
  late final TextEditingController
  _rootCausesController;

  late final TextEditingController
  _correctionController;

  late final TextEditingController
  _correctiveActionController;

  late final TextEditingController
  _followUpController;

  late final TextEditingController
  _effectivenessController;

  DateTime? _correctionDate;
  DateTime? _correctiveActionDate;
  DateTime? _followUpDate;
  DateTime? _effectivenessDate;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _rootCausesController =
        TextEditingController(
          text:
          widget.record[
          'root_causes']
              ?.toString() ??
              '',
        );

    _correctionController =
        TextEditingController(
          text:
          widget.record[
          'correction']
              ?.toString() ??
              '',
        );

    _correctiveActionController =
        TextEditingController(
          text:
          widget.record[
          'corrective_action']
              ?.toString() ??
              '',
        );

    _followUpController =
        TextEditingController(
          text:
          widget.record[
          'follow_up_audit_details']
              ?.toString() ??
              '',
        );

    _effectivenessController =
        TextEditingController(
          text:
          widget.record[
          'effectiveness_of_corrective_action']
              ?.toString() ??
              '',
        );

    _correctionDate =
        _parseDate(
          widget.record[
          'correction_effective_date'],
        );

    _correctiveActionDate =
        _parseDate(
          widget.record[
          'corrective_action_effective_date'],
        );

    _followUpDate =
        _parseDate(
          widget.record[
          'follow_up_audit_date'],
        );

    _effectivenessDate =
        _parseDate(
          widget.record[
          'effectiveness_date'],
        );
  }

  @override
  void dispose() {
    _rootCausesController.dispose();
    _correctionController.dispose();
    _correctiveActionController.dispose();
    _followUpController.dispose();
    _effectivenessController.dispose();
    super.dispose();
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await NcrService.updateActionPlan(
        ncrId:
        widget.record['id']
            .toString(),

        rootCauses:
        _rootCausesController.text,

        correction:
        _correctionController.text,

        correctionEffectiveDate:
        _correctionDate,

        correctiveAction:
        _correctiveActionController.text,

        correctiveActionEffectiveDate:
        _correctiveActionDate,

        followUpAuditDetails:
        _followUpController.text,

        followUpAuditDate:
        _followUpDate,

        effectivenessOfCorrectiveAction:
        _effectivenessController
            .text,

        effectivenessDate:
        _effectivenessDate,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text(
            'Action plan saved successfully.',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
          Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submit() async {
    if (_rootCausesController.text
        .trim()
        .isEmpty ||
        _correctionController.text
            .trim()
            .isEmpty ||
        _correctiveActionController.text
            .trim()
            .isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text(
            'Root Cause, Correction and Corrective Action are required.',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _save();

      await NcrService.submitActionPlan(
        widget.record['id']
            .toString(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text(
            'Action plan submitted to HOD.',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
          Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final record =
        widget.record;

    final status =
    record['status_name']
        ?.toString()
        .trim()
        .isNotEmpty ==
        true
        ? record['status_name']
        .toString()
        : record['status_key']
        ?.toString() ??
        'Unknown';

    final statusKey =
        record['status_key']
            ?.toString() ??
            '';

    final editable =
        statusKey !=
            'submitted_to_hod' &&
            statusKey !=
                'sent_to_dcc' &&
            statusKey !=
                'closed';

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
        Colors.white,
        surfaceTintColor:
        Colors.white,

        leading: IconButton(
          icon:
          const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.pop(context),
        ),

        title: Text(
          record['ncr_number']
              ?.toString() ??
              'NCR Action Plan',
          style:
          const TextStyle(
            fontWeight:
            FontWeight.w800,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding:
        const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 1100,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                _readOnlyInformation(
                  record,
                  status,
                ),

                const SizedBox(
                  height: 20,
                ),

                _section(
                  title:
                  'Action Plan',
                  children: [
                    _field(
                      'Root Cause(s)',
                      _rootCausesController,
                      editable,
                    ),

                    _dateField(
                      'Correction Effective Date',
                      _correctionDate,
                      editable,
                          (date) {
                        setState(() {
                          _correctionDate =
                              date;
                        });
                      },
                    ),

                    _field(
                      'Correction (Immediate Containment)',
                      _correctionController,
                      editable,
                    ),

                    _field(
                      'Corrective Action (to address Root Cause)',
                      _correctiveActionController,
                      editable,
                    ),

                    _dateField(
                      'Corrective Action Effective Date',
                      _correctiveActionDate,
                      editable,
                          (date) {
                        setState(() {
                          _correctiveActionDate =
                              date;
                        });
                      },
                    ),

                    _field(
                      'Follow-up Audit Details',
                      _followUpController,
                      editable,
                    ),

                    _dateField(
                      'Follow-up Audit Date',
                      _followUpDate,
                      editable,
                          (date) {
                        setState(() {
                          _followUpDate =
                              date;
                        });
                      },
                    ),

                    _field(
                      'Effectiveness of Corrective Action Implementation',
                      _effectivenessController,
                      editable,
                    ),

                    _dateField(
                      'Effectiveness Date',
                      _effectivenessDate,
                      editable,
                          (date) {
                        setState(() {
                          _effectivenessDate =
                              date;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(
                  height: 20,
                ),

                if (record['hod_action']
                    ?.toString()
                    .trim()
                    .isNotEmpty ==
                    true)
                  _approvalInfo(
                    'HOD Decision',
                    record[
                    'hod_action']
                        ?.toString(),
                    record[
                    'hod_comments']
                        ?.toString(),
                  ),

                if (record['dcc_action']
                    ?.toString()
                    .trim()
                    .isNotEmpty ==
                    true)
                  _approvalInfo(
                    'DCC Decision',
                    record[
                    'dcc_action']
                        ?.toString(),
                    record[
                    'dcc_comments']
                        ?.toString(),
                  ),

                if (editable) ...[
                  const SizedBox(
                    height: 20,
                  ),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed:
                        _isSaving
                            ? null
                            : _save,
                        child:
                        const Text(
                          'Save Draft',
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      FilledButton.icon(
                        onPressed:
                        _isSaving
                            ? null
                            : _submit,
                        icon:
                        _isSaving
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                          CircularProgressIndicator(
                            strokeWidth:
                            2,
                          ),
                        )
                            : const Icon(
                          Icons
                              .send_outlined,
                        ),
                        label:
                        const Text(
                          'Submit to HOD',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // READ ONLY
  // ============================================================

  Widget _readOnlyInformation(
      Map<String, dynamic> record,
      String status,
      ) {
    return _section(
      title:
      'NCR Information (Read Only)',
      children: [
        _readOnlyGrid([
          _readOnly(
            'NCR Number',
            record['ncr_number'],
          ),
          _readOnly(
            'Process / Function',
            record[
            'process_function'],
          ),
          _readOnly(
            'Clause / Section',
            record[
            'clause_section'],
          ),
          _readOnly(
            'Standard(s)',
            record['standard'],
          ),
          _readOnly(
            'Report No',
            record['report_no'],
          ),
          _readOnly(
            'IA No',
            record['ia_no'],
          ),
          _readOnly(
            'Auditee',
            record[
            'auditee_name'],
          ),
          _readOnly(
            'Auditor',
            record[
            'auditor_name'],
          ),
          _readOnly(
            'Audit Date',
            _formatDate(
              record['audit_date'],
            ),
          ),
          _readOnly(
            'Status',
            status,
          ),
          _readOnly(
            'Finding',
            record[
            'finding_statement'],
          ),
          _readOnly(
            'Requirement / Clause Reference',
            record[
            'requirement_clause_reference'],
          ),
        ]),
      ],
    );
  }

  Widget _readOnlyGrid(
      List<Widget> children,
      ) {
    return LayoutBuilder(
      builder:
          (context, constraints) {
        if (constraints.maxWidth <
            700) {
          return Column(
            children:
            children
                .map(
                  (child) =>
                  Padding(
                    padding:
                    const EdgeInsets
                        .only(
                      bottom: 12,
                    ),
                    child: child,
                  ),
            )
                .toList(),
          );
        }

        final rows =
        <Widget>[];

        for (
        var i = 0;
        i < children.length;
        i += 2
        ) {
          rows.add(
            Padding(
              padding:
              const EdgeInsets.only(
                bottom: 12,
              ),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child:
                    children[i],
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child:
                    i + 1 <
                        children.length
                        ? children[
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

  Widget _readOnly(
      String label,
      dynamic value,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(14),
      decoration:
      BoxDecoration(
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
            style:
            TextStyle(
              fontSize: 11,
              color:
              Colors.grey.shade600,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            value?.toString()
                .trim()
                .isNotEmpty ==
                true
                ? value.toString()
                : 'Not provided',
            maxLines: 4,
            overflow:
            TextOverflow.ellipsis,
            style:
            const TextStyle(
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EDITABLE FIELD
  // ============================================================

  Widget _field(
      String label,
      TextEditingController controller,
      bool enabled,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 16,
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        minLines: 3,
        maxLines: 7,
        decoration:
        InputDecoration(
          labelText: label,
          alignLabelWithHint: true,
          border:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(
              10,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateField(
      String label,
      DateTime? value,
      bool enabled,
      ValueChanged<DateTime?>
      onChanged,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 16,
      ),
      child: InkWell(
        onTap: !enabled
            ? null
            : () async {
          final date =
          await showDatePicker(
            context: context,
            initialDate:
            value ??
                DateTime.now(),
            firstDate:
            DateTime(2020),
            lastDate:
            DateTime(2100),
          );

          if (date != null) {
            onChanged(date);
          }
        },
        child: InputDecorator(
          decoration:
          InputDecoration(
            labelText: label,
            prefixIcon:
            const Icon(
              Icons
                  .calendar_today_outlined,
            ),
            border:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                10,
              ),
            ),
          ),
          child: Text(
            value == null
                ? 'Select date'
                : _formatDate(value),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _section({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(22),
      decoration:
      BoxDecoration(
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
          Text(
            title,
            style:
            const TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _approvalInfo(
      String title,
      String? action,
      String? comments,
      ) {
    return _section(
      title: title,
      children: [
        _readOnly(
          'Decision',
          action,
        ),
        _readOnly(
          'Comments',
          comments,
        ),
      ],
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  DateTime? _parseDate(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  String _formatDate(
      dynamic value,
      ) {
    if (value == null) {
      return 'Not provided';
    }

    final date =
    value is DateTime
        ? value
        : DateTime.tryParse(
      value.toString(),
    );

    if (date == null) {
      return value.toString();
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}