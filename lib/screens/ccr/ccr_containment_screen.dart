import 'package:flutter/material.dart';

import '../../models/ccr/ccr_case.dart';
import '../../models/ccr/ccr_containment.dart';
import '../../services/ccr/ccr_service.dart';
import '../../services/ccr/ccr_containment_service.dart';
import 'ccr_assignment_screen.dart';

class CcrContainmentScreen extends StatefulWidget {
  const CcrContainmentScreen({
    super.key,
    required this.ccrId,
  });

  final String ccrId;

  @override
  State<CcrContainmentScreen> createState() =>
      _CcrContainmentScreenState();
}

class _CcrContainmentScreenState
    extends State<CcrContainmentScreen> {
  final CcrService _ccrService = CcrService();
  final CcrContainmentService _service =
  CcrContainmentService();

  CcrCase? _ccr;
  CcrContainment? _containment;

  List<CcrContainmentSorting> _sortingRows = [];

  final _sortingActivityController =
  TextEditingController();

  final _sortingLearningsController =
  TextEditingController();

  final _customerProtectionController =
  TextEditingController();

  final _recoverPrqController =
  TextEditingController();

  final _firstCertifiedGoodController =
  TextEditingController();

  DateTime? _targetEta;

  bool _loading = true;
  bool _saving = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _sortingActivityController.dispose();
    _sortingLearningsController.dispose();
    _customerProtectionController.dispose();
    _recoverPrqController.dispose();
    _firstCertifiedGoodController.dispose();

    super.dispose();
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

      final containment =
      await _service.getContainment(
        widget.ccrId,
      );

      List<CcrContainmentSorting> rows = [];

      if (containment != null) {
        rows = await _service.getSortingResults(
          containment.id,
        );
      }

      if (!mounted) return;

      _ccr = ccr;
      _containment = containment;
      _sortingRows = rows;

      if (containment != null) {
        _sortingActivityController.text =
            containment.sortingActivity ?? '';

        _sortingLearningsController.text =
            containment.sortingLearnings ?? '';

        _customerProtectionController.text =
            containment.customerProtectionAction ??
                '';

        _recoverPrqController.text =
            containment.recoverPrqSchedule ?? '';

        _firstCertifiedGoodController.text =
            containment.firstCertifiedGoodShipment ??
                '';

        _targetEta = containment.targetEta;
      }

      setState(() {
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

  Future<void> _saveContainment() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final saved =
      await _service.saveContainment(
        ccrId: widget.ccrId,
        sortingActivity:
        _sortingActivityController.text,
        sortingLearnings:
        _sortingLearningsController.text,
        customerProtectionAction:
        _customerProtectionController.text,
        recoverPrqSchedule:
        _recoverPrqController.text,
        firstCertifiedGoodShipment:
        _firstCertifiedGoodController.text,
        targetEta: _targetEta,
      );

      _containment = saved;

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Containment saved successfully.',
          ),
        ),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not save containment: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _addSortingRow() async {
    if (_containment == null) {
      await _saveContainment();
    }

    if (_containment == null) {
      return;
    }

    final result =
    await showDialog<_SortingRowInput>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const _SortingRowDialog();
      },
    );

    if (result == null) {
      return;
    }

    try {
      await _service.saveSortingRow(
        containmentId: _containment!.id,
        location: result.location,
        qtyNg: result.qtyNg,
        qtySorted: result.qtySorted,
        sortingDate: result.sortingDate,
        dri: result.dri,
      );

      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not add sorting result: $e',
          ),
        ),
      );
    }
  }

  Future<void> _editSortingRow(
      CcrContainmentSorting row) async {
    final result =
    await showDialog<_SortingRowInput>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _SortingRowDialog(
          initial: row,
        );
      },
    );

    if (result == null) {
      return;
    }

    try {
      await _service.updateSortingRow(
        id: row.id,
        location: result.location,
        qtyNg: result.qtyNg,
        qtySorted: result.qtySorted,
        sortingDate: result.sortingDate,
        dri: result.dri,
      );

      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not update sorting result: $e',
          ),
        ),
      );
    }
  }

  Future<void> _deleteSortingRow(
      CcrContainmentSorting row) async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete sorting result',
          ),
          content: const Text(
            'This sorting result will be removed.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _service.deleteSortingRow(row.id);
      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete sorting result: $e',
          ),
        ),
      );
    }
  }

  Future<void> _selectTargetEta() async {
    final initial =
        _targetEta ?? DateTime.now();

    final picked =
    await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _targetEta = picked;
    });
  }

  Future<void> _completeContainment() async {
    if (_saving) return;

    await _saveContainment();

    if (_containment == null) {
      return;
    }

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Complete containment',
          ),
          content: const Text(
            'The containment stage will be marked complete and the CCR will move to the next configured workflow stage.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('Complete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _service.completeContainment(
        widget.ccrId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Containment completed.',
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CcrAssignmentScreen(
                ccrId: widget.ccrId,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not complete containment: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF303640),
          ),
          onPressed: () =>
              Navigator.pop(context),
        ),

        title: const Text(
          'Customer Complaint Registration',
          style: TextStyle(
            color: Color(0xFF202124),
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF303640),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 650,
          ),
          child: _errorCard(),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
        constraints.maxWidth > 1400
            ? 1340.0
            : constraints.maxWidth - 40;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 28,
          ),
          child: Center(
            child: SizedBox(
              width: width,
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  _pageHeader(),
                  const SizedBox(height: 20),

                  _ccrSummaryCard(),
                  const SizedBox(height: 16),

                  _sectionCard(
                    title: 'Containment',
                    icon:
                    Icons.shield_outlined,
                    child: _containmentFields(),
                  ),

                  const SizedBox(height: 16),

                  _sectionCard(
                    title:
                    'Sorting Results',
                    icon:
                    Icons.table_chart_outlined,
                    trailing:
                    FilledButton.icon(
                      onPressed:
                      _saving
                          ? null
                          : _addSortingRow,
                      icon: const Icon(
                        Icons.add_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Add Result',
                      ),
                      style:
                      _primaryButtonStyle(),
                    ),
                    child:
                    _sortingTable(),
                  ),

                  const SizedBox(height: 24),

                  _actionBar(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _pageHeader() {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'Containment',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202124),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _ccr?.displayNumber ??
                    'Customer Complaint',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF747982),
                  fontWeight:
                  FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        if (_containment?.status != null)
          _statusChip(
            _containment!.status!,
          ),
      ],
    );
  }

  Widget _ccrSummaryCard() {
    return _card(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color:
              const Color(0xFFF0F3FF),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFF3155C6),
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  _ccr?.customerName
                      ?.trim()
                      .isNotEmpty ==
                      true
                      ? _ccr!.customerName!
                      : 'Customer not entered',
                  style:
                  const TextStyle(
                    fontSize: 14,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF202124),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _ccr?.problemDescription
                      ?.trim()
                      .isNotEmpty ==
                      true
                      ? _ccr!.problemDescription!
                      : 'Problem description not entered',
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 12,
                    color:
                    Color(0xFF747982),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _containmentFields() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        _field(
          label: 'Sorting Activity',
          controller:
          _sortingActivityController,
          maxLines: 4,
          hint:
          'Describe the containment sorting activity.',
        ),
        if (_containment?.status != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3FF),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: const Color(0xFFD9E2FF),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Color(0xFF3155C6),
                ),
                const SizedBox(width: 9),
                const Text(
                  'Containment Status:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _containment!.status!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFF3155C6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        const SizedBox(height: 18),

        _field(
          label: 'Learnings from Sorting',
          controller:
          _sortingLearningsController,
          maxLines: 4,
          hint:
          'Record the learnings obtained from sorting.',
        ),

        const SizedBox(height: 18),

        _field(
          label:
          'Customer Protection Action',
          controller:
          _customerProtectionController,
          maxLines: 4,
          hint:
          'Describe actions taken to protect the customer.',
        ),

        const SizedBox(height: 18),

        _field(
          label: 'Recover PRQ Schedule',
          controller:
          _recoverPrqController,
          maxLines: 3,
          hint:
          'Record the recovery plan for the PRQ schedule.',
        ),

        const SizedBox(height: 18),

        _field(
          label:
          'First Certified Good Shipment',
          controller:
          _firstCertifiedGoodController,
          maxLines: 3,
          hint:
          'Record the first certified good shipment information.',
        ),

        const SizedBox(height: 18),

        _dateField(
          label: 'Target ETA',
          value: _targetEta,
          onTap: _selectTargetEta,
        ),
      ],
    );
  }

  Widget _sortingTable() {
    if (_sortingRows.isEmpty) {
      return Container(
        width: double.infinity,
        padding:
        const EdgeInsets.symmetric(
          vertical: 44,
          horizontal: 20,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
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
              Icons.table_rows_outlined,
              size: 34,
              color: Color(0xFF98A1AC),
            ),
            SizedBox(height: 10),
            Text(
              'No sorting results added',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.w600,
                color: Color(0xFF555A63),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Add the sorting results for each containment location.',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF8A9098),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection:
      Axis.horizontal,
      child: DataTable(
        headingRowHeight: 46,
        dataRowMinHeight: 58,
        dataRowMaxHeight: 70,

        columns: const [
          DataColumn(
            label: Text('Location'),
          ),
          DataColumn(
            label: Text('Qty. NG'),
          ),
          DataColumn(
            label: Text('Qty. Sorted'),
          ),
          DataColumn(
            label: Text('NG %'),
          ),
          DataColumn(
            label: Text('Sorting Date'),
          ),
          DataColumn(
            label: Text('DRI'),
          ),
          DataColumn(
            label: Text(''),
          ),
        ],

        rows: _sortingRows
            .map(
              (row) => DataRow(
            cells: [
              DataCell(
                Text(
                  _display(
                    row.location,
                  ),
                ),
              ),

              DataCell(
                Text(
                  _formatNumber(
                    row.qtyNg,
                  ),
                ),
              ),

              DataCell(
                Text(
                  _formatNumber(
                    row.qtySorted,
                  ),
                ),
              ),

              DataCell(
                Text(
                  row.ngPercentage == null
                      ? '-'
                      : '${row.ngPercentage!.toStringAsFixed(3)}%',
                ),
              ),

              DataCell(
                Text(
                  _formatDate(
                    row.sortingDate,
                  ),
                ),
              ),

              DataCell(
                Text(
                  _display(row.dri),
                ),
              ),

              DataCell(
                Row(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () =>
                          _editSortingRow(
                            row,
                          ),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 19,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () =>
                          _deleteSortingRow(
                            row,
                          ),
                      icon: const Icon(
                        Icons
                            .delete_outline_rounded,
                        size: 19,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            .toList(),
      ),
    );
  }

  Widget _actionBar() {
    return Row(
      children: [
        OutlinedButton(
          onPressed:
          _saving ? null : _saveContainment,
          style: OutlinedButton.styleFrom(
            foregroundColor:
            const Color(0xFF555A63),
            padding:
            const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 14,
            ),
            side: const BorderSide(
              color: Color(0xFFD9DDE3),
            ),
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(11),
            ),
          ),
          child: _saving
              ? const SizedBox(
            width: 18,
            height: 18,
            child:
            CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
              : const Text(
            'Save Draft',
            style: TextStyle(
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 12),

        FilledButton.icon(
          onPressed:
          _saving
              ? null
              : _completeContainment,
          icon: const Icon(
            Icons.check_rounded,
            size: 18,
          ),
          label: const Text(
            'Complete Containment',
          ),
          style: _primaryButtonStyle(),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                  const Color(0xFFF0F3FF),
                  borderRadius:
                  BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color:
                  const Color(0xFF3155C6),
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Text(
                  title,
                  style:
                  const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF202124),
                  ),
                ),
              ),

              if (trailing != null)
                trailing,
            ],
          ),

          const SizedBox(height: 20),

          child,
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3F4349),
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration:
          _inputDecoration(hint),
        ),
      ],
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3F4349),
          ),
        ),

        const SizedBox(height: 8),

        InkWell(
          borderRadius:
          BorderRadius.circular(12),
          onTap: onTap,
          child: InputDecorator(
            decoration:
            _inputDecoration('Select date')
                .copyWith(
              suffixIcon: const Icon(
                Icons.calendar_today_outlined,
                size: 19,
              ),
            ),
            child: Text(
              value == null
                  ? 'Select date'
                  : _formatDate(value),
              style: TextStyle(
                fontSize: 13,
                color: value == null
                    ? const Color(
                    0xFF9A9EA5)
                    : const Color(
                    0xFF30343A),
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
      String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF9A9EA5),
        fontSize: 13,
      ),
      filled: true,
      fillColor:
      const Color(0xFFF8F9FB),
      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFE0E3E8),
        ),
      ),
      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF3155C6),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _card({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: child,
    );
  }

  Widget _errorCard() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
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
            size: 42,
            color: Color(0xFFD94A4A),
          ),
          const SizedBox(height: 12),
          const Text(
            'Could not load containment',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.w700,
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
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String value) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
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

  String _formatNumber(double? value) {
    if (value == null) {
      return '-';
    }

    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}


// ============================================================
// SORTING ROW INPUT
// ============================================================

class _SortingRowInput {
  final String? location;
  final double? qtyNg;
  final double? qtySorted;
  final DateTime? sortingDate;
  final String? dri;

  const _SortingRowInput({
    this.location,
    this.qtyNg,
    this.qtySorted,
    this.sortingDate,
    this.dri,
  });
}


// ============================================================
// SORTING ROW DIALOG
// ============================================================

class _SortingRowDialog extends StatefulWidget {
  const _SortingRowDialog({
    this.initial,
  });

  final CcrContainmentSorting? initial;

  @override
  State<_SortingRowDialog> createState() =>
      _SortingRowDialogState();
}

class _SortingRowDialogState
    extends State<_SortingRowDialog> {
  late final TextEditingController
  _locationController;

  late final TextEditingController
  _qtyNgController;

  late final TextEditingController
  _qtySortedController;

  late final TextEditingController
  _driController;

  DateTime? _sortingDate;

  @override
  void initState() {
    super.initState();

    final row = widget.initial;

    _locationController =
        TextEditingController(
          text: row?.location ?? '',
        );

    _qtyNgController =
        TextEditingController(
          text: row?.qtyNg == null
              ? ''
              : _format(row!.qtyNg!),
        );

    _qtySortedController =
        TextEditingController(
          text: row?.qtySorted == null
              ? ''
              : _format(row!.qtySorted!),
        );

    _driController =
        TextEditingController(
          text: row?.dri ?? '',
        );

    _sortingDate = row?.sortingDate;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _qtyNgController.dispose();
    _qtySortedController.dispose();
    _driController.dispose();

    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked =
    await showDatePicker(
      context: context,
      initialDate:
      _sortingDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _sortingDate = picked;
    });
  }

  void _save() {
    final location =
    _locationController.text.trim();

    final qtyNg =
    double.tryParse(
      _qtyNgController.text.trim(),
    );

    final qtySorted =
    double.tryParse(
      _qtySortedController.text.trim(),
    );

    // ------------------------------------------------------------
    // Location is required because the database column is NOT NULL.
    // Never send an empty value to Supabase for this field.
    // ------------------------------------------------------------

    if (location.isEmpty) {
      _showError(
        'Location is required.',
      );
      return;
    }

    if (qtyNg != null &&
        qtyNg < 0) {
      _showError(
        'NG quantity cannot be negative.',
      );
      return;
    }

    if (qtySorted != null &&
        qtySorted < 0) {
      _showError(
        'Sorted quantity cannot be negative.',
      );
      return;
    }

    if (qtyNg != null &&
        qtySorted != null &&
        qtySorted > 0 &&
        qtyNg > qtySorted) {
      _showError(
        'NG quantity cannot be greater than sorted quantity.',
      );
      return;
    }

    Navigator.pop(
      context,
      _SortingRowInput(
        location: location,
        qtyNg: qtyNg,
        qtySorted: qtySorted,
        sortingDate: _sortingDate,
        dri: _driController.text.trim().isEmpty
            ? null
            : _driController.text.trim(),
      ),
    );
  }
  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initial == null
            ? 'Add Sorting Result'
            : 'Edit Sorting Result',
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(
                'Location',
                _locationController,
                'Enter sorting location',
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _field(
                      'Qty. NG',
                      _qtyNgController,
                      'Enter NG quantity',
                      numeric: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      'Qty. Sorted',
                      _qtySortedController,
                      'Enter sorted quantity',
                      numeric: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _dateField(),

              const SizedBox(height: 14),

              _field(
                'DRI',
                _driController,
                'Enter responsible person',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor:
            const Color(0xFF7655C9),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _field(
      String label,
      TextEditingController controller,
      String hint, {
        bool numeric = false,
      }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(
            decimal: true,
          )
              : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor:
            const Color(0xFFF8F9FB),
            contentPadding:
            const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(11),
              borderSide: const BorderSide(
                color: Color(0xFFE0E3E8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateField() {
    final text = _sortingDate == null
        ? 'Select sorting date'
        : '${_sortingDate!.day.toString().padLeft(2, '0')}/'
        '${_sortingDate!.month.toString().padLeft(2, '0')}/'
        '${_sortingDate!.year}';

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Sorting Date',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        InkWell(
          onTap: _pickDate,
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor:
              const Color(0xFFF8F9FB),
              suffixIcon: const Icon(
                Icons.calendar_today_outlined,
                size: 18,
              ),
              border: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(11),
                borderSide:
                const BorderSide(
                  color: Color(0xFFE0E3E8),
                ),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: _sortingDate == null
                    ? const Color(0xFF9A9EA5)
                    : const Color(0xFF30343A),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _format(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }
}