import 'package:flutter/material.dart';
import '../../services/ccr/ccr_api_client.dart';
import '../../models/ccr/ccr_assignment.dart';
import '../../models/ccr/ccr_case.dart';
import '../../services/ccr/ccr_assignment_service.dart';
import '../../services/ccr/ccr_service.dart';
import 'ccr_fishbone_screen.dart';

class CcrAssignmentScreen extends StatefulWidget {
  const CcrAssignmentScreen({
    super.key,
    required this.ccrId,
  });

  final String ccrId;

  @override
  State<CcrAssignmentScreen> createState() =>
      _CcrAssignmentScreenState();
}

class _CcrAssignmentScreenState
    extends State<CcrAssignmentScreen> {
  final CcrService _ccrService =
  CcrService();

  final CcrAssignmentService _service =
  CcrAssignmentService();

  CcrCase? _ccr;

  List<CcrAssignment> _assignments =
  [];

  bool _loading = true;
  bool _saving = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ccr =
      await _ccrService.getCcrById(
        widget.ccrId,
      );

      final assignments =
      await _service.getAssignments(
        widget.ccrId,
      );

      if (!mounted) return;

      setState(() {
        _ccr = ccr;
        _assignments = assignments;
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

  Future<void> _addAssignment() async {
    final result = await showDialog<_AssignmentInput>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AssignmentDialog(),
    );

    if (result == null) return;

    try {
      await _service.createAssignment(
        ccrId: widget.ccrId,
        activity: result.activity,
        dri: result.dri,
        dueDate: result.dueDate,
        doneDate: result.doneDate,
        statusKey: result.statusKey ?? 'pending',
        remarks: result.remarks,
      );
      await _load();

      if (!mounted) return;

      _message('Assignment saved successfully.');
    } catch (e) {
      if (!mounted) return;

      _message(
        'Could not save assignment: $e',
        error: true,
      );
    }
  }

  Future<void> _editAssignment(
      CcrAssignment assignment,
      ) async {
    final result =
    await showDialog<
        _AssignmentInput>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _AssignmentDialog(
            initial: assignment,
          ),
    );

    if (result == null) {
      return;
    }

    try {
      await _service.updateAssignment(
        id: assignment.id,
        activity: result.activity,
        dri: result.dri,
        dueDate: result.dueDate,
        doneDate: result.doneDate,
        statusKey: result.statusKey,
        remarks: result.remarks,
      );

      await _load();

      if (!mounted) return;

      _message(
        'Assignment updated successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _message(
        'Could not update assignment: $e',
        error: true,
      );
    }
  }

  Future<void> _deleteAssignment(
      CcrAssignment assignment,
      ) async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text(
              'Delete assignment',
            ),
            content: const Text(
              'This assignment will be removed.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                      context,
                      false,
                    ),
                child:
                const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(
                      context,
                      true,
                    ),
                child:
                const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _service.deleteAssignment(
        assignment.id,
      );

      await _load();
    } catch (e) {
      if (!mounted) return;

      _message(
        'Could not delete assignment: $e',
        error: true,
      );
    }
  }

  Future<void> _completeAssignment() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      // ----------------------------------------------------------
      // Complete the assignment in the database.
      //
      // The service determines the NEXT workflow stage using
      // ccr_workflow_stages.display_order.
      // ----------------------------------------------------------

      await _service.completeAssignment(
        widget.ccrId,
      );

      // ----------------------------------------------------------
      // Read the stage that the database actually moved to.
      // ----------------------------------------------------------

      final nextStage = await _service.getCurrentStage(
        widget.ccrId,
      );
      if (!mounted) return;

      _message(
        'Assignment completed.',
      );

      // ----------------------------------------------------------
      // Assignment's next configured screen.
      //
      // The DB decides the stage. This screen is the implementation
      // for the Fishbone stage.
      // ----------------------------------------------------------

      if (nextStage == 'fishbone') {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CcrFishboneScreen(
              ccrId: widget.ccrId,
            ),
          ),
        );

        return;
      }

      // ----------------------------------------------------------
      // Never silently return to Home if workflow configuration
      // and screen implementation are out of sync.
      // ----------------------------------------------------------

      throw Exception(
        'The CCR moved to workflow stage "$nextStage", '
            'but no screen is connected to that stage.',
      );
    } catch (e) {
      if (!mounted) return;

      _message(
        'Could not complete assignment: $e',
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

  void _message(
      String text, {
        bool error = false,
      }) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(text),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor:
        const Color(0xFF172033),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xFFEFF3FF,
                ),
                borderRadius:
                BorderRadius.circular(
                  11,
                ),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color:
                Color(0xFF3155C6),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _ccr?.displayNumber ??
                  'Customer Complaint Registration',
              style: const TextStyle(
                fontSize: 19,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
            _loading || _saving
                ? null
                : _load,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : _error != null
          ? _errorView()
          : _body(),
    );
  }

  Widget _body() {
    return Column(
      children: [
        _stageHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              14,
              18,
              14,
              30,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1100,
                ),
                child: _sectionCard(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stageHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    color: Color(0xFF3155C6),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Assignment',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                'Assign activities, responsibilities and due dates.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(
                    'Stage: ${_ccr?.currentStageName ??
                        _ccr?.currentStageKey ?? '-'}',
                  ),
                  _chip(
                    'Status: ${_ccr?.statusName ??
                        _ccr?.statusKey ?? '-'}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
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
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.list_alt_outlined,
                  color: Color(0xFF3155C6),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigned Activities',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Manage activities required for this CCR.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF747982),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _addAssignment,
              icon: const Icon(
                Icons.add,
                size: 18,
              ),
              label: const Text('Add Assignment'),
              style: _primaryButtonStyle(),
            ),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Assignment List',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF172033),
                  ),
                ),
              ),
              Text(
                '${_assignments.length} ${_assignments.length == 1 ? 'item' : 'items'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF747982),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (_assignments.isEmpty)
            _emptyAssignments()
          else
            _assignmentTable(),

          const SizedBox(height: 24),

          _actionBar(),
        ],
      ),
    );
  }

  Widget _emptyAssignments() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(
        vertical: 48,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color:
        const Color(0xFFF8F9FB),
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color:
          const Color(0xFFE5E7EB),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 36,
            color:
            Color(0xFF98A1AC),
          ),
          SizedBox(height: 10),
          Text(
            'No assignments added',
            style: TextStyle(
              fontSize: 13,
              fontWeight:
              FontWeight.w600,
              color:
              Color(0xFF555A63),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Add the activities required to progress this CCR.',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color:
              Color(0xFF8A9098),
            ),
          ),
        ],
      ),
    );
  }

  Widget _assignmentTable() {
    return Column(
      children: _assignments.map((assignment) {
        return _assignmentCard(assignment);
      }).toList(),
    );
  }

  Widget _assignmentCard(CcrAssignment assignment) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity heading and status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3FF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  size: 19,
                  color: Color(0xFF3155C6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACTIVITY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8A9098),
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _display(assignment.activity),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF172033),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(
            height: 1,
            color: Color(0xFFE9EBF0),
          ),
          const SizedBox(height: 14),

          // Responsive assignment details
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 520;

              final itemWidth = isWide
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _assignmentDetail(
                      icon: Icons.person_outline,
                      label: 'Responsible Person (DRI)',
                      value: _display(assignment.dri),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _assignmentDetail(
                      icon: Icons.calendar_today_outlined,
                      label: 'Due Date',
                      value: _formatDate(assignment.dueDate),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _assignmentDetail(
                      icon: Icons.event_available_outlined,
                      label: 'Done Date',
                      value: _formatDate(assignment.doneDate),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _assignmentDetail(
                      icon: Icons.info_outline,
                      label: 'Status',
                      value: assignment.displayStatus,
                    ),
                  ),
                  SizedBox(
                    width: constraints.maxWidth,
                    child: _assignmentDetail(
                      icon: Icons.notes_outlined,
                      label: 'Remarks',
                      value: _display(assignment.remarks),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Always visible actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving
                      ? null
                      : () => _editAssignment(assignment),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 17,
                  ),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3155C6),
                    side: const BorderSide(
                      color: Color(0xFF3155C6),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving
                      ? null
                      : () => _deleteAssignment(assignment),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 17,
                  ),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(
                      color: Color(0xFFFFD5D5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _assignmentDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color: const Color(0xFF7B8492),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF858C98),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF303847),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _statusBadge(
      CcrAssignment assignment,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color:
        const Color(0xFFF3F4F6),
        borderRadius:
        BorderRadius.circular(9),
      ),
      child: Text(
        assignment.displayStatus,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight:
          FontWeight.w600,
          color:
          Color(0xFF62666D),
        ),
      ),
    );
  }

  Widget _actionBar() {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed:
          _saving ? null : _load,
          child:
          const Text('Save Draft'),
        ),
        const SizedBox(width: 10),
        FilledButton(
          onPressed:
          _saving
              ? null
              : _completeAssignment,
          style:
          _primaryButtonStyle(),
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
            'Complete Assignment',
          ),
        ),
      ],
    );
  }

  Widget _errorView() {
    return Center(
      child: Container(
        margin:
        const EdgeInsets.all(24),
        padding:
        const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(14),
          border: Border.all(
            color:
            const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color:
              Color(0xFFD94A4A),
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load assignment',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign:
              TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color:
                Color(0xFF747982),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _load,
              child:
              const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String value) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color:
        const Color(0xFFF5F6F8),
        borderRadius:
        BorderRadius.circular(10),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight:
          FontWeight.w600,
          color:
          Color(0xFF62666D),
        ),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor:
      const Color(0xFF7655C9),
      foregroundColor:
      Colors.white,
      elevation: 0,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 13,
      ),
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(11),
      ),
    );
  }

  String _display(String? value) {
    if (value == null ||
        value.trim().isEmpty) {
      return '-';
    }

    return value.trim();
  }

  String _formatDate(
      DateTime? date,
      ) {
    if (date == null) {
      return '-';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

// ============================================================
// ASSIGNMENT INPUT
// ============================================================

class _AssignmentInput {
  final String? activity;
  final String? dri;
  final DateTime? dueDate;
  final DateTime? doneDate;
  final String? statusKey;
  final String? remarks;

  const _AssignmentInput({
    this.activity,
    this.dri,
    this.dueDate,
    this.doneDate,
    this.statusKey,
    this.remarks,
  });
}

// ============================================================
// ASSIGNMENT DIALOG
// ============================================================

class _AssignmentDialog
    extends StatefulWidget {
  const _AssignmentDialog({
    this.initial,
  });

  final CcrAssignment? initial;

  @override
  State<_AssignmentDialog> createState() =>
      _AssignmentDialogState();
}

class _AssignmentDialogState
    extends State<_AssignmentDialog> {
  late final TextEditingController
  _activityController;

  late final TextEditingController
  _driController;

  late final TextEditingController
  _remarksController;

  DateTime? _dueDate;
  DateTime? _doneDate;

  String? _statusKey;

  List<Map<String, dynamic>> _statuses = [];

  bool _loadingStatuses = true;

  String? _statusLoadError;

  @override
  void initState() {
    super.initState();

    final initial =
        widget.initial;

    _activityController =
        TextEditingController(
          text: initial?.activity ?? '',
        );

    _driController =
        TextEditingController(
          text: initial?.dri ?? '',
        );

    _remarksController =
        TextEditingController(
          text: initial?.remarks ?? '',
        );

    _dueDate =
        initial?.dueDate;

    _doneDate =
        initial?.doneDate;

    _statusKey =
        initial?.statusKey ?? 'pending';

    _loadStatuses();
  }


  Future<void> _loadStatuses() async {
    if (!mounted) return;

    setState(() {
      _loadingStatuses = true;
      _statusLoadError = null;
    });

    try {
      final response = await CcrApiClient.get(
        '/assignment-statuses',
        authenticated: false,
      );

      if (response is! List) {
        throw Exception(
          'Invalid assignment statuses response from server.',
        );
      }

      final statuses = response
          .map(
            (item) => Map<String, dynamic>.from(item as Map),
      )
          .toList();

      if (!mounted) return;

      setState(() {
        _statuses = statuses;

        if (!_statuses.any(
              (item) =>
          item['status_key']?.toString() == _statusKey,
        )) {
          _statusKey = _statuses.any(
                (item) =>
            item['status_key']?.toString() == 'pending',
          )
              ? 'pending'
              : (_statuses.isNotEmpty
              ? _statuses.first['status_key']?.toString()
              : null);
        }

        _loadingStatuses = false;
        _statusLoadError = null;
      });
    } catch (e) {
      debugPrint('CCR ASSIGNMENT STATUS ERROR: $e');

      if (!mounted) return;

      setState(() {
        _statuses = [];
        _loadingStatuses = false;
        _statusLoadError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _activityController.dispose();
    _driController.dispose();
    _remarksController.dispose();

    super.dispose();
  }

  Future<void> _pickDueDate()
  async {
    final picked =
    await showDatePicker(
      context: context,
      initialDate:
      _dueDate ??
          DateTime.now(),
      firstDate:
      DateTime(2000),
      lastDate:
      DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _dueDate = picked;
    });
  }

  Future<void> _pickDoneDate()
  async {
    final picked =
    await showDatePicker(
      context: context,
      initialDate:
      _doneDate ??
          DateTime.now(),
      firstDate:
      DateTime(2000),
      lastDate:
      DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _doneDate = picked;
    });
  }

  void _save() {
    final activity =
    _activityController.text
        .trim();

    if (activity.isEmpty) {
      _error(
        'Activity is required.',
      );
      return;
    }

    Navigator.pop(
      context,
      _AssignmentInput(
        activity: activity,
        dri: _nullable(
          _driController.text,
        ),
        dueDate: _dueDate,
        doneDate: _doneDate,
        statusKey: _statusKey,
        remarks: _nullable(
          _remarksController.text,
        ),
      ),
    );
  }

  String? _nullable(
      String value,
      ) {
    final trimmed =
    value.trim();

    return trimmed.isEmpty
        ? null
        : trimmed;
  }

  void _error(
      String message,
      ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return AlertDialog(
      title: Text(
        widget.initial == null
            ? 'Add Assignment'
            : 'Edit Assignment',
      ),
      content: SizedBox(
        width: 560,
        child:
        SingleChildScrollView(
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              _field(
                'Activity',
                _activityController,
                'Enter the activity to be completed',
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              _field(
                'DRI',
                _driController,
                'Enter responsible person',
              ),
              const SizedBox(height: 14),
              _dateField(
                'Due Date',
                _dueDate,
                _pickDueDate,
              ),
              const SizedBox(height: 14),
              _dateField(
                'Done Date',
                _doneDate,
                _pickDoneDate,
              ),
              const SizedBox(height: 14),
              if (_loadingStatuses)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                )
              else if (_statuses.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFFD699),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unable to load assignment statuses.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9A5B00),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        _statusLoadError ?? 'No active statuses returned.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9A5B00),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _loadStatuses,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _statuses.any(
                        (item) =>
                    item['status_key']?.toString() == _statusKey,
                  )
                      ? _statusKey
                      : (_statuses.any(
                        (item) =>
                    item['status_key']?.toString() == 'pending',
                  )
                      ? 'pending'
                      : _statuses.first['status_key']?.toString()),
                  decoration: InputDecoration(
                    labelText: 'Assignment Status',
                    prefixIcon: const Icon(
                      Icons.flag_outlined,
                      color: Color(0xFF7655C9),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _statuses.map((item) {
                    final key = item['status_key']?.toString();

                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text(
                        item['status_name']?.toString() ?? key ?? '-',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _statusKey = value;
                    });
                  },
                ),
              const SizedBox(height: 14),
              _field(
                'Remarks',
                _remarksController,
                'Enter remarks',
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context),
          child:
          const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          style:
          FilledButton.styleFrom(
            backgroundColor:
            const Color(0xFF7655C9),
          ),
          child:
          const Text('Save'),
        ),
      ],
    );
  }

  Widget _field(
      String label,
      TextEditingController
      controller,
      String hint, {
        int maxLines = 1,
      }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration:
      InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor:
        const Color(0xFFF8F9FB),
        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
          borderSide:
          const BorderSide(
            color:
            Color(0xFFE0E3E8),
          ),
        ),
      ),
    );
  }

  Widget _dateField(
      String label,
      DateTime? value,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(12),
      child: InputDecorator(
        decoration:
        InputDecoration(
          labelText: label,
          border:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(12),
          ),
        ),
        child: Text(
          value == null
              ? 'Select date'
              : '${value.day.toString().padLeft(2, '0')}/'
              '${value.month.toString().padLeft(2, '0')}/'
              '${value.year}',
        ),
      ),
    );
  }
}