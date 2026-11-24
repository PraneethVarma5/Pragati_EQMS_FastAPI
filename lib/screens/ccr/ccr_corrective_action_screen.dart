import 'package:flutter/material.dart';
import '../../services/ccr/ccr_api_client.dart';
import '../../models/ccr/ccr_case.dart';
import '../../models/ccr/ccr_corrective_action.dart';
import '../../services/ccr/ccr_corrective_action_service.dart';
import '../../services/ccr/ccr_service.dart';
import 'ccr_evidence_screen.dart';

class CcrCorrectiveActionScreen extends StatefulWidget {
  const CcrCorrectiveActionScreen({
    super.key,
    required this.ccrId,
  });

  final String ccrId;

  @override
  State<CcrCorrectiveActionScreen> createState() =>
      _CcrCorrectiveActionScreenState();
}

class _CcrCorrectiveActionScreenState
    extends State<CcrCorrectiveActionScreen> {
  final CcrService _ccrService = CcrService();

  final CcrCorrectiveActionService _service =
  CcrCorrectiveActionService();

  CcrCase? _ccr;

  List<CcrCorrectiveAction> _actions = [];

  bool _loading = true;
  bool _saving = false;

  String? _error;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final Map<String, TextEditingController> _problemControllers = {};

  final Map<String, TextEditingController> _occurrenceControllers = {};

  final Map<String, TextEditingController> _detectionControllers = {};

  final Map<String, TextEditingController> _actionControllers = {};

  final Map<String, TextEditingController> _driControllers = {};

  final Map<String, TextEditingController> _beforeControllers = {};

  final Map<String, TextEditingController> _afterControllers = {};

  final Map<String, DateTime?> _dueDates = {};

  final Map<String, DateTime?> _completionDates = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ccr = await _ccrService.getCcrById(
        widget.ccrId,
      );

      // --------------------------------------------------------
      // Automatically create one CA for every validated YES
      // root cause if it does not already exist.
      // --------------------------------------------------------

      await _service.ensureActionsFromValidatedCauses(
        widget.ccrId,
      );

      final actions = await _service.getCorrectiveActions(
        widget.ccrId,
      );

      _disposeControllers();
      _clearControllerMaps();

      for (final action in actions) {
        _problemControllers[action.id] =
            TextEditingController(
              text: action.problemStatement,
            );

        _occurrenceControllers[action.id] =
            TextEditingController(
              text: action.occurrenceRootCause,
            );

        _detectionControllers[action.id] =
            TextEditingController(
              text: action.detectionRootCause,
            );

        _actionControllers[action.id] =
            TextEditingController(
              text: action.correctiveAction,
            );

        _driControllers[action.id] =
            TextEditingController(
              text: action.dri,
            );

        _beforeControllers[action.id] =
            TextEditingController(
              text: action.resultBefore,
            );

        _afterControllers[action.id] =
            TextEditingController(
              text: action.resultAfter,
            );

        _dueDates[action.id] = action.dueDate;

        _completionDates[action.id] =
            action.completionDate;
      }

      if (!mounted) return;

      setState(() {
        _ccr = ccr;
        _actions = actions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // SAVE DRAFT
  // ============================================================

  Future<void> _saveDraft() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      for (final action in _actions) {
        await _saveAction(
          action,
          allowIncomplete: true,
        );
      }

      if (!mounted) return;

      _message(
        'Corrective Action draft saved.',
      );
    } catch (e) {
      if (!mounted) return;

      _message(
        'Could not save draft: $e',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // SAVE ONE ACTION
  // ============================================================

  Future<void> _saveAction(
      CcrCorrectiveAction action, {
        required bool allowIncomplete,
      }) async {
    final actionText =
        _actionControllers[action.id]?.text ?? '';

    final dri =
        _driControllers[action.id]?.text ?? '';

    final status = _deriveActionStatus(
      action,
    );

    if (!allowIncomplete) {
      if (actionText.trim().isEmpty) {
        throw Exception(
          'Corrective action is required.',
        );
      }

      if (dri.trim().isEmpty) {
        throw Exception(
          'DRI is required.',
        );
      }
    }

    await _service.saveCorrectiveAction(
      actionId: action.id,
      problemStatement: _text(
        action.id,
        _problemControllers,
      ),
      occurrenceRootCause: _text(
        action.id,
        _occurrenceControllers,
      ),
      detectionRootCause: _text(
        action.id,
        _detectionControllers,
      ),
      correctiveAction: actionText,
      dri: dri,
      resultBefore: _text(
        action.id,
        _beforeControllers,
      ),
      resultAfter: _text(
        action.id,
        _afterControllers,
      ),
      dueDate: _dueDates[action.id],
      completionDate: _completionDates[action.id],
      status: status,
    );
  }

  // ============================================================
  // COMPLETE
  // ============================================================

  Future<void> _complete() async {
    if (_saving) return;

    if (_actions.isEmpty) {
      _message(
        'No corrective action plans are available.',
        error: true,
      );
      return;
    }

    // ----------------------------------------------------------
    // Validate visible CA data.
    //
    // Verification is intentionally NOT part of this stage.
    // ----------------------------------------------------------

    for (final action in _actions) {
      final correctiveAction = _text(
        action.id,
        _actionControllers,
      );

      final dri = _text(
        action.id,
        _driControllers,
      );

      final before = _text(
        action.id,
        _beforeControllers,
      );

      final after = _text(
        action.id,
        _afterControllers,
      );

      if (correctiveAction.isEmpty) {
        _message(
          'Corrective Action is required for every action plan.',
          error: true,
        );
        return;
      }

      if (dri.isEmpty) {
        _message(
          'DRI is required for every action plan.',
          error: true,
        );
        return;
      }

      if (before.isEmpty) {
        _message(
          'Result Before CA is required for every action plan.',
          error: true,
        );
        return;
      }

      if (after.isEmpty) {
        _message(
          'Result After CA is required for every action plan.',
          error: true,
        );
        return;
      }

      if (_dueDates[action.id] == null) {
        _message(
          'Due Date is required for every action plan.',
          error: true,
        );
        return;
      }

      if (_completionDates[action.id] == null) {
        _message(
          'Completion Date is required for every action plan.',
          error: true,
        );
        return;
      }
    }

    // ----------------------------------------------------------
    // Confirmation
    // ----------------------------------------------------------

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Complete Corrective Action',
        ),
        content: const Text(
          'The corrective-action plans will be saved and the CCR will move to the next configured workflow stage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              false,
            ),
            child: const Text(
              'Cancel',
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              true,
            ),
            style: _primaryButtonStyle(),
            child: const Text(
              'Complete',
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _saving = true;
    });

    try {
      // --------------------------------------------------------
      // Save every CA row.
      // --------------------------------------------------------

      for (final action in _actions) {
        await _saveAction(
          action,
          allowIncomplete: false,
        );
      }

      // --------------------------------------------------------
      // Complete current CA workflow stage.
      //
      // The service obtains the next stage from
      // ccr_workflow_stages using display_order.
      // --------------------------------------------------------

      await _service.completeStage(
        widget.ccrId,
      );

      // --------------------------------------------------------
      // Read the actual stage after completion.
      // --------------------------------------------------------

      final dynamic rawReport = await CcrApiClient.get(
        '/cases/${widget.ccrId}/report',
      );

      if (rawReport is! Map) {
        throw Exception(
          'Could not retrieve the updated CCR workflow stage.',
        );
      }

      final dynamic rawCase = rawReport['case'];

      if (rawCase is! Map) {
        throw Exception(
          'The CCR report did not contain case information.',
        );
      }

      final nextStage = rawCase['current_stage']
          ?.toString()
          .trim()
          .toLowerCase();
      if (nextStage == null || nextStage.isEmpty) {
        throw Exception(
          'Corrective Action completed but the next CCR workflow stage could not be determined.',
        );
      }

      if (!mounted) return;

      _message(
        'Corrective Action completed.',
      );

      // --------------------------------------------------------
      // Evidence is the next configured stage in the current
      // workflow configuration.
      // --------------------------------------------------------

      if (nextStage == 'evidence') {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CcrEvidenceScreen(
              ccrId: widget.ccrId,
            ),
          ),
        );

        return;
      }

      throw Exception(
        'The CCR moved to workflow stage "$nextStage", '
            'but no screen is connected to that stage.',
      );
    } catch (e) {
      if (!mounted) return;

      _message(
        'Could not complete Corrective Action: $e',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // DERIVE STATUS
  // ============================================================

  String _deriveActionStatus(
      CcrCorrectiveAction action,
      ) {
    final actionText = _text(
      action.id,
      _actionControllers,
    );

    if (actionText.isEmpty) {
      return 'open';
    }

    return 'in_progress';
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _pickDate(
      String actionId,
      bool dueDate,
      ) async {
    final current = dueDate
        ? _dueDates[actionId]
        : _completionDates[actionId];

    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      if (dueDate) {
        _dueDates[actionId] = selected;
      } else {
        _completionDates[actionId] = selected;
      }
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF3FF),
                borderRadius:
                BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.build_circle_outlined,
                color: Color(0xFF3155C6),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _ccr?.displayNumber ??
                  'Corrective Action',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
            _loading || _saving ? null : _load,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _error != null
          ? _errorView()
          : _body(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _body() {
    return Column(
      children: [
        _stageHeader(),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              24,
              22,
              24,
              130,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1500,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.stretch,
                  children: [
                    _summaryCard(),

                    const SizedBox(height: 18),

                    _correctiveActionTable(),

                    const SizedBox(height: 18),

                    _bottomBar(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STAGE HEADER
  // ============================================================

  Widget _stageHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1250,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.build_outlined,
                color: Color(0xFF3155C6),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Corrective Action & Verification',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Define permanent countermeasures and verify their effectiveness.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              _chip(
                _ccr?.currentStageName ??
                    _ccr?.currentStageKey ??
                    '-',
              ),
              const SizedBox(width: 8),
              _chip(
                _ccr?.statusName ??
                    _ccr?.statusKey ??
                    '-',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3FF),
              borderRadius:
              BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.assignment_turned_in_outlined,
              color: Color(0xFF3155C6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Permanent Countermeasures',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_actions.length} action plan${_actions.length == 1 ? '' : 's'} generated from validated root causes.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF747982),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CORRECTIVE ACTION TABLE
  // ============================================================


  Widget _correctiveActionTable() {
    if (_actions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: const Center(
          child: Text(
            'No validated root causes are available for corrective action.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF747982),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.table_chart_outlined,
                  color: Color(0xFF3155C6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Action Plan for Permanent Countermeasures',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_actions.length} corrective action plan${_actions.length == 1 ? '' : 's'} generated from validated root causes.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF747982),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          ..._actions.asMap().entries.map((entry) {
            return _caTwoRowPlan(
              entry.key + 1,
              entry.value,
            );
          }),
        ],
      ),
    );
  }

  Widget _caTwoRowPlan(
      int rowNumber,
      CcrCorrectiveAction action,
      ) {
    const labelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: Color(0xFF475467),
    );

    Widget field(
        String label,
        Widget child, {
          int flex = 1,
        }) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: labelStyle),
              const SizedBox(height: 6),
              child,
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFD9DEE6),
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3FF),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              children: [
                const Text(
                  'Action Status:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475467),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _deriveActionStatus(action),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3155C6),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          // FIRST ROW: Five fields
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              field(
                'Problem Statement',
                _caEditableCell(
                  _problemControllers[action.id]!,
                  double.infinity,
                  minLines: 2,
                  maxLines: 8,
                ),
                flex: 2,
              ),
              field(
                'Root Cause Occurrence',
                _caReadOnlyRootCauseCell(
                  _occurrenceControllers[action.id]!,
                  double.infinity,
                ),
                flex: 2,
              ),
              field(
                'Root Cause Non-Detection',
                _caReadOnlyRootCauseCell(
                  _detectionControllers[action.id]!,
                  double.infinity,
                ),
                flex: 2,
              ),
              field(
                'Corrective Action',
                _caEditableCell(
                  _actionControllers[action.id]!,
                  double.infinity,
                  minLines: 2,
                  maxLines: 8,
                ),
                flex: 2,
              ),
              field(
                'DRI',
                _caEditableCell(
                  _driControllers[action.id]!,
                  double.infinity,
                  minLines: 2,
                  maxLines: 6,
                ),
                flex: 1,
              ),
            ],
          ),

          const Divider(
            height: 14,
            color: Color(0xFFE5E7EB),
          ),

          // SECOND ROW: Four fields
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              field(
                'Result Before CA',
                _caEditableCell(
                  _beforeControllers[action.id]!,
                  double.infinity,
                  minLines: 2,
                  maxLines: 8,
                ),
              ),
              field(
                'Result After CA',
                _caEditableCell(
                  _afterControllers[action.id]!,
                  double.infinity,
                  minLines: 2,
                  maxLines: 8,
                ),
              ),
              field(
                'Due Date',
                _caDateCell(
                  action.id,
                  dueDate: true,
                  width: double.infinity,
                ),
              ),
              field(
                'Completion Date',
                _caDateCell(
                  action.id,
                  dueDate: false,
                  width: double.infinity,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABLE HEADER
  // ============================================================

  Widget _caTableHeader() {
    const style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: Color(0xFF344054),
    );

    return Container(
      height: 58,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F3F6),
        border: Border(
          top: BorderSide(
            color: Color(0xFFD9DEE6),
          ),
          left: BorderSide(
            color: Color(0xFFD9DEE6),
          ),
          right: BorderSide(
            color: Color(0xFFD9DEE6),
          ),
          bottom: BorderSide(
            color: Color(0xFFD9DEE6),
          ),
        ),
      ),
      child: Row(
        children: [
          _caHeaderCell(
            '#',
            55,
            style,
          ),
          _caHeaderCell(
            'Problem Statement',
            230,
            style,
          ),
          _caHeaderCell(
            'Root Cause\nOccurrence',
            250,
            style,
          ),
          _caHeaderCell(
            'Root Cause\nNon-Detection',
            250,
            style,
          ),
          _caHeaderCell(
            'Corrective Action',
            280,
            style,
          ),
          _caHeaderCell(
            'DRI',
            160,
            style,
          ),
          _caHeaderCell(
            'Result Before CA',
            220,
            style,
          ),
          _caHeaderCell(
            'Result After CA',
            220,
            style,
          ),
          _caHeaderCell(
            'Due Date',
            140,
            style,
          ),
          _caHeaderCell(
            'Completion Date',
            160,
            style,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABLE HEADER CELL
  // ============================================================

  Widget _caHeaderCell(
      String text,
      double width,
      TextStyle style,
      ) {
    return Container(
      width: width,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Color(0xFFD9DEE6),
          ),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }

  // ============================================================
  // TABLE ROW
  // ============================================================

  Widget _caTableRow(
      int rowNumber,
      CcrCorrectiveAction action,
      ) {
    Widget field(
        String label,
        Widget child,
        ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF475467),
              ),
            ),
          ),
          child,
        ],
      );
    }

    Widget editable(
        TextEditingController controller, {
          int minLines = 3,
          int maxLines = 8,
        }) {
      return _caEditableCell(
        controller,
        double.infinity,
        minLines: minLines,
        maxLines: maxLines,
      );
    }

    Widget rootCause(
        TextEditingController controller,
        ) {
      return _caReadOnlyRootCauseCell(
        controller,
        double.infinity,
      );
    }

    Widget dateField(bool dueDate) {
      return _caDateCell(
        action.id,
        dueDate: dueDate,
        width: double.infinity,
      );
    }

    Widget responsiveFields(List<Widget> fields) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final fieldWidth = (availableWidth - 16) / 2;

          return Wrap(
            spacing: 16,
            runSpacing: 14,
            children: fields.map((item) {
              return SizedBox(
                width: fieldWidth,
                child: item,
              );
            }).toList(),
          );
        },
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFD9DEE6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Action Plan $rowNumber',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3155C6),
            ),
          ),
          const SizedBox(height: 14),

          // First section
          responsiveFields([
            field(
              'Problem Statement',
              editable(
                _problemControllers[action.id]!,
                minLines: 3,
              ),
            ),
            field(
              'Root Cause - Occurrence',
              rootCause(
                _occurrenceControllers[action.id]!,
              ),
            ),
            field(
              'Root Cause - Non-Detection',
              rootCause(
                _detectionControllers[action.id]!,
              ),
            ),
            field(
              'Corrective Action',
              editable(
                _actionControllers[action.id]!,
                minLines: 3,
              ),
            ),
            field(
              'DRI',
              editable(
                _driControllers[action.id]!,
                minLines: 2,
                maxLines: 5,
              ),
            ),
          ]),

          const SizedBox(height: 18),
          const Divider(
            color: Color(0xFFE5E7EB),
          ),
          const SizedBox(height: 12),

          // Results start on a separate line.
          const Text(
            'RESULTS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3155C6),
            ),
          ),
          const SizedBox(height: 12),

          responsiveFields([
            field(
              'Result Before CA',
              editable(
                _beforeControllers[action.id]!,
                minLines: 3,
              ),
            ),
            field(
              'Result After CA',
              editable(
                _afterControllers[action.id]!,
                minLines: 3,
              ),
            ),
            field(
              'Due Date',
              dateField(true),
            ),
            field(
              'Completion Date',
              dateField(false),
            ),
          ]),
        ],
      ),
    );
  }
  // ============================================================
  // EDITABLE TABLE CELL
  // ============================================================

  Widget _caEditableCell(
      TextEditingController controller,
      double width, {
        int minLines = 3,
        int maxLines = 6,
      }) {
    return SizedBox(
      width: width.isInfinite ? double.infinity : width,
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        keyboardType: TextInputType.multiline,
        decoration: const InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Color(0xFFFBFCFD),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(7),
            ),
            borderSide: BorderSide(
              color: Color(0xFFE0E3E8),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(7),
            ),
            borderSide: BorderSide(
              color: Color(0xFFE0E3E8),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(7),
            ),
            borderSide: BorderSide(
              color: Color(0xFF3155C6),
              width: 1.3,
            ),
          ),
        ),
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF344054),
        ),
      ),
    );
  }
  // ============================================================
  // READ-ONLY ROOT CAUSE CELL
  // ============================================================

  Widget _caReadOnlyRootCauseCell(
      TextEditingController controller,
      double width,
      ) {
    final text = controller.text.trim();

    return Container(
      width: width,
      constraints: const BoxConstraints(
        minHeight: 125,
      ),
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Color(0xFFD9DEE6),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F8),
          borderRadius:
          BorderRadius.circular(7),
          border: Border.all(
            color: const Color(0xFFDCE1E7),
          ),
        ),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 14,
              color: Color(0xFF667085),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                text.isEmpty
                    ? 'No final Why entered'
                    : text,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: text.isEmpty
                      ? FontWeight.w400
                      : FontWeight.w600,
                  color: text.isEmpty
                      ? const Color(0xFF98A2B3)
                      : const Color(0xFF344054),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATE CELL
  // ============================================================

  Widget _caDateCell(
      String actionId, {
        required bool dueDate,
        required double width,
      }) {
    final value = dueDate
        ? _dueDates[actionId]
        : _completionDates[actionId];

    return Container(
      width: width,
      padding: const EdgeInsets.all(7),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Color(0xFFD9DEE6),
          ),
        ),
      ),
      child: InkWell(
        onTap: _saving
            ? null
            : () => _pickDate(
          actionId,
          dueDate,
        ),
        borderRadius:
        BorderRadius.circular(7),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 105,
          ),
          padding:
          const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFBFCFD),
            borderRadius:
            BorderRadius.circular(7),
            border: Border.all(
              color: const Color(0xFFE0E3E8),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: Color(0xFF667085),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  value == null
                      ? 'Select date'
                      : _formatDate(value),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: value == null
                        ? FontWeight.w400
                        : FontWeight.w600,
                    color: value == null
                        ? const Color(0xFF98A2B3)
                        : const Color(0xFF344054),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM BAR
  // ============================================================

  Widget _bottomBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed:
            _saving ? null : _saveDraft,
            child: const Text(
              'Save Draft',
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed:
            _saving ? null : _complete,
            style: _primaryButtonStyle(),
            child: _saving
                ? const SizedBox(
              width: 17,
              height: 17,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text(
              'Complete & Continue',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR VIEW
  // ============================================================

  Widget _errorView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: Color(0xFFD94A4A),
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load Corrective Action',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF747982),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _load,
              style: _primaryButtonStyle(),
              child: const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _text(
      String id,
      Map<String, TextEditingController> map,
      ) {
    return map[id]?.text.trim() ?? '';
  }

  String _formatDate(DateTime date) {
    final d = date.day
        .toString()
        .padLeft(2, '0');

    final m = date.month
        .toString()
        .padLeft(2, '0');

    return '$d/$m/${date.year}';
  }

  Widget _chip(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius:
        BorderRadius.circular(10),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF62666D),
        ),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor:
      const Color(0xFF7655C9),
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(11),
      ),
    );
  }

  void _message(
      String message, {
        bool error = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
        SnackBarBehavior.floating,
        backgroundColor: error
            ? const Color(0xFFB42318)
            : null,
      ),
    );
  }

  // ============================================================
  // DISPOSE CONTROLLERS
  // ============================================================

  void _disposeControllers() {
    for (final controller
    in _problemControllers.values) {
      controller.dispose();
    }

    for (final controller
    in _occurrenceControllers.values) {
      controller.dispose();
    }

    for (final controller
    in _detectionControllers.values) {
      controller.dispose();
    }

    for (final controller
    in _actionControllers.values) {
      controller.dispose();
    }

    for (final controller
    in _driControllers.values) {
      controller.dispose();
    }

    for (final controller
    in _beforeControllers.values) {
      controller.dispose();
    }

    for (final controller
    in _afterControllers.values) {
      controller.dispose();
    }
  }

  // ============================================================
  // CLEAR MAPS
  // ============================================================

  void _clearControllerMaps() {
    _problemControllers.clear();
    _occurrenceControllers.clear();
    _detectionControllers.clear();
    _actionControllers.clear();
    _driControllers.clear();
    _beforeControllers.clear();
    _afterControllers.clear();

    _dueDates.clear();
    _completionDates.clear();
  }
}