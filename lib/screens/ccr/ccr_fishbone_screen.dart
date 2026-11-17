import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/ccr/ccr_case.dart';
import '../../models/ccr/ccr_fishbone.dart';
import '../../services/ccr/ccr_fishbone_service.dart';
import '../../services/ccr/ccr_service.dart';
import 'ccr_root_cause_validation_screen.dart';

class CcrFishboneScreen extends StatefulWidget {
  const CcrFishboneScreen({
    super.key,
    required this.ccrId,
  });

  final String ccrId;

  @override
  State<CcrFishboneScreen> createState() =>
      _CcrFishboneScreenState();
}

class _CcrFishboneScreenState
    extends State<CcrFishboneScreen> {
  final CcrService _ccrService = CcrService();

  final CcrFishboneService _service =
  CcrFishboneService();

  CcrCase? _ccr;

  List<CcrFishboneCategory> _categories =
  <CcrFishboneCategory>[];

  List<CcrFishboneCause> _causes =
  <CcrFishboneCause>[];

  bool _loading = true;
  bool _saving = false;

  String? _error;

  // ============================================================
  // FISHBONE GEOMETRY
  //
  // IMPORTANT:
  // The painter and the category widgets MUST use the same
  // geometry. This prevents the category boxes from drifting
  // away from their corresponding fishbone branches.
  // ============================================================

  static const double _categoryWidth = 245;

  static const double _spineStartX = 45;

  static const double _effectWidth = 205;

  static const double _effectRightMargin = 24;

  static const double _branchLength = 205;

  static const double _branchHorizontalOffset = 90;

  static const double _diagramTopPadding = 24;

  static const double _diagramBottomPadding = 24;

  static const double _branchNodeGap = 12;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _load();
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
      final results = await Future.wait([
        _ccrService.getCcrById(
          widget.ccrId,
        ),
        _service.getCategories(),
        _service.getCauses(
          widget.ccrId,
        ),
      ]);

      if (!mounted) return;

      final ccr =
      results[0] as CcrCase;

      final categories =
      List<CcrFishboneCategory>.from(
        results[1]
        as List<CcrFishboneCategory>,
      )..sort(
            (a, b) =>
            a.displayOrder.compareTo(
              b.displayOrder,
            ),
      );

      final causes =
      List<CcrFishboneCause>.from(
        results[2]
        as List<CcrFishboneCause>,
      )..sort(
            (a, b) =>
            a.displayOrder.compareTo(
              b.displayOrder,
            ),
      );

      setState(() {
        _ccr = ccr;
        _categories = categories;
        _causes = causes;
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
  // ADD CAUSE
  // ============================================================

  Future<void> _addCause(
      CcrFishboneCategory category,
      ) async {
    final text =
    await _showCauseDialog(
      category: category,
    );

    if (text == null) return;

    try {
      await _service.addCause(
        ccrId: widget.ccrId,
        categoryId: category.id,
        causeText: text,
      );

      await _load();

      if (!mounted) return;

      _message(
        'Cause added to ${category.name}.',
      );
    } catch (e) {
      if (!mounted) return;

      _message(
        'Could not save cause: $e',
        error: true,
      );
    }
  }

  // ============================================================
  // EDIT CAUSE
  // ============================================================

  Future<void> _editCause(
      CcrFishboneCause cause,
      ) async {
    final matching =
    _categories.where(
          (item) =>
      item.id == cause.categoryId,
    );

    if (matching.isEmpty) {
      _message(
        'The category for this cause is no longer active.',
        error: true,
      );
      return;
    }

    final category =
        matching.first;

    final result =
    await _showCauseDialog(
      category: category,
      initialText: cause.causeText,
    );

    if (result == null) return;

    try {
      await _service.updateCause(
        id: cause.id,
        categoryId: cause.categoryId,
        causeText: result,
      );

      await _load();

      if (!mounted) return;

      _message(
        'Cause updated.',
      );
    } catch (e) {
      if (!mounted) return;

      _message(
        'Could not update cause: $e',
        error: true,
      );
    }
  }

  // ============================================================
  // DELETE CAUSE
  // ============================================================

  Future<void> _deleteCause(
      CcrFishboneCause cause,
      ) async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (_) =>
          AlertDialog(
            title:
            const Text(
              'Delete cause',
            ),
            content:
            Text(
              'Remove "${cause.causeText}" from the Fishbone analysis?',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                      context,
                      false,
                    ),
                child:
                const Text(
                  'Cancel',
                ),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(
                      context,
                      true,
                    ),
                style:
                _primaryButtonStyle(),
                child:
                const Text(
                  'Delete',
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteCause(
        cause.id,
      );

      await _load();

      if (!mounted) return;

      _message(
        'Cause deleted.',
      );
    } catch (e) {
      if (!mounted) return;

      _message(
        'Could not delete cause: $e',
        error: true,
      );
    }
  }

  // ============================================================
  // CAUSE DIALOG
  // ============================================================

  Future<String?> _showCauseDialog({
    required CcrFishboneCategory category,
    String? initialText,
  }) async {
    final controller =
    TextEditingController(
      text: initialText ?? '',
    );

    try {
      return await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            AlertDialog(
              title: Text(
                initialText == null
                    ? 'Add Cause'
                    : 'Edit Cause',
              ),
              content: SizedBox(
                width: 560,
                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style:
                      const TextStyle(
                        fontSize: 14,
                        fontWeight:
                        FontWeight.w800,
                        color:
                        Color(0xFF3155C6),
                      ),
                    ),

                    if (category.description
                        ?.trim()
                        .isNotEmpty ==
                        true) ...[
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        category.description!,
                        style:
                        const TextStyle(
                          fontSize: 12,
                          color:
                          Color(0xFF747982),
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 16,
                    ),

                    TextField(
                      controller:
                      controller,
                      autofocus: true,
                      maxLines: 5,
                      decoration:
                      InputDecoration(
                        labelText:
                        'Potential Cause',
                        hintText:
                        'Enter the potential cause',
                        filled: true,
                        fillColor:
                        const Color(
                          0xFFF8F9FB,
                        ),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                        context,
                      ),
                  child:
                  const Text(
                    'Cancel',
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    final value =
                    controller.text
                        .trim();

                    if (value.isEmpty) {
                      ScaffoldMessenger
                          .of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Cause description is required.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(
                      context,
                      value,
                    );
                  },
                  style:
                  _primaryButtonStyle(),
                  child:
                  const Text(
                    'Save',
                  ),
                ),
              ],
            ),
      );
    } finally {
      controller.dispose();
    }
  }

  // ============================================================
  // COMPLETE FISHBONE
  // ============================================================

  Future<void> _completeFishbone() async {
    if (_saving) return;

    if (_causes.isEmpty) {
      _message(
        'Add at least one potential cause before completing Fishbone analysis.',
        error: true,
      );
      return;
    }

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (_) =>
          AlertDialog(
            title:
            const Text(
              'Complete Fishbone analysis',
            ),
            content:
            const Text(
              'The entered Fishbone causes will be sent to Root Cause Validation.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                      context,
                      false,
                    ),
                child:
                const Text(
                  'Cancel',
                ),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(
                      context,
                      true,
                    ),
                style:
                _primaryButtonStyle(),
                child:
                const Text(
                  'Complete',
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() {
      _saving = true;
    });

    try {
      await _service.completeFishbone(
        widget.ccrId,
      );

      if (!mounted) return;

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CcrRootCauseValidationScreen(
                ccrId: widget.ccrId,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _message(
        'Could not complete Fishbone analysis: $e',
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
  // MESSAGE
  // ============================================================

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
        content:
        Text(message),
        behavior:
        SnackBarBehavior.floating,
        backgroundColor:
        error
            ? const Color(
          0xFFB42318,
        )
            : null,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

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
        backgroundColor:
        Colors.white,
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
                Icons
                    .account_tree_outlined,
                color:
                Color(0xFF3155C6),
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Text(
                _ccr?.displayNumber ??
                    'Customer Complaint Registration',
                style:
                const TextStyle(
                  fontSize: 19,
                  fontWeight:
                  FontWeight.w700,
                ),
                overflow:
                TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
            _loading ||
                _saving
                ? null
                : _load,
            icon:
            const Icon(
              Icons
                  .refresh_rounded,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
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

  // ============================================================
  // BODY
  // ============================================================

  Widget _body() {
    return Column(
      children: [
        _stageHeader(),

        Expanded(
          child:
          SingleChildScrollView(
            padding:
            const EdgeInsets.fromLTRB(
              24,
              22,
              24,
              130,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints:
                const BoxConstraints(
                  maxWidth: 1400,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .stretch,
                  children: [
                    _effectCard(),

                    const SizedBox(
                      height: 18,
                    ),

                    _fishboneDiagramCard(),

                    const SizedBox(
                      height: 18,
                    ),

                    _causeListCard(),
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
      padding:
      const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 1400,
          ),
          child: Row(
            children: [
              const Icon(
                Icons
                    .account_tree_outlined,
                color:
                Color(0xFF3155C6),
              ),

              const SizedBox(
                width: 10,
              ),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      'Fishbone Analysis',
                      style:
                      TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    SizedBox(
                      height: 3,
                    ),
                    Text(
                      'Identify potential causes by category.',
                      style:
                      TextStyle(
                        fontSize: 12,
                        color:
                        Color(
                          0xFF6B7280,
                        ),
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

              const SizedBox(
                width: 8,
              ),

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
  // EFFECT CARD
  // ============================================================

  Widget _effectCard() {
    final problem = [
      _ccr?.problemDescription,
      _ccr?.complaintDescription,
    ].whereType<String>()
        .map((value) => value.trim())
        .firstWhere(
          (value) => value.isNotEmpty,
      orElse: () => '',
    );

    return Container(
      padding:
      const EdgeInsets.all(18),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color:
          const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFFEFF3FF,
              ),
              borderRadius:
              BorderRadius.circular(
                10,
              ),
            ),
            child: const Icon(
              Icons
                  .report_problem_outlined,
              color:
              Color(0xFF3155C6),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          const Text(
            'Effect / Problem',
            style:
            TextStyle(
              fontSize: 14,
              fontWeight:
              FontWeight.w800,
            ),
          ),

          const SizedBox(
            width: 18,
          ),

          Expanded(
            child: Text(
              problem.isEmpty
                  ? 'Problem description not entered'
                  : problem,
              maxLines: 2,
              overflow:
              TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: problem
                    .isEmpty
                    ? const Color(
                  0xFF9AA1AA,
                )
                    : const Color(
                  0xFF374151,
                ),
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FISHBONE CARD
  // ============================================================

  Widget _fishboneDiagramCard() {
    return Container(
      padding:
      const EdgeInsets.all(20),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color:
          const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFEFF3FF,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                ),
                child: const Icon(
                  Icons
                      .schema_outlined,
                  color:
                  Color(0xFF3155C6),
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      'Cause-and-Effect Diagram',
                      style:
                      TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    SizedBox(
                      height: 3,
                    ),
                    Text(
                      'The diagram updates immediately when causes are added, edited or deleted.',
                      style:
                      TextStyle(
                        fontSize: 12,
                        color:
                        Color(
                          0xFF747982,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          _buildRealFishbone(),
        ],
      ),
    );
  }

  // ============================================================
  // REAL FISHBONE
  // ============================================================

  Widget _buildRealFishbone() {
    if (_categories.isEmpty) {
      return _emptyCategories();
    }

    final categories = List<CcrFishboneCategory>.from(
      _categories,
    )..sort(
          (a, b) => a.displayOrder.compareTo(b.displayOrder),
    );

    final grouped = <String, List<CcrFishboneCause>>{
      for (final category in categories)
        category.id: <CcrFishboneCause>[],
    };

    for (final cause in _causes) {
      grouped
          .putIfAbsent(
        cause.categoryId,
            () => <CcrFishboneCause>[],
      )
          .add(cause);
    }

    final upperCount = categories.length <= 1
        ? categories.length
        : (categories.length / 2).ceil();

    final upper = categories.take(upperCount).toList();
    final lower = categories.skip(upperCount).toList();

    final upperHeight = upper.fold<double>(
      66,
          (maximum, category) {
        final height = _categoryNodeEstimatedHeight(
          grouped[category.id] ?? [],
        );
        return math.max(maximum, height);
      },
    );

    final lowerHeight = lower.fold<double>(
      66,
          (maximum, category) {
        final height = _categoryNodeEstimatedHeight(
          grouped[category.id] ?? [],
        );
        return math.max(maximum, height);
      },
    );

    final centerY = _diagramTopPadding +
        upperHeight +
        _branchLength +
        _branchNodeGap;

    final diagramHeight = centerY +
        _branchLength +
        _branchNodeGap +
        lowerHeight +
        _diagramBottomPadding;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        final diagramWidth = math.max(
          1180.0,
          availableWidth,
        );

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: diagramWidth,
            height: diagramHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RealFishbonePainter(
                      upperCount: upper.length,
                      lowerCount: lower.length,
                      diagramWidth: diagramWidth,
                      centerY: centerY,
                    ),
                  ),
                ),

                Positioned(
                  left: diagramWidth -
                      _effectRightMargin -
                      _effectWidth,
                  top: centerY - 52,
                  width: _effectWidth,
                  child: _effectNode(),
                ),

                ..._buildCategoryNodes(
                  categories: upper,
                  causes: grouped,
                  upper: true,
                  diagramWidth: diagramWidth,
                  centerY: centerY,
                ),

                ..._buildCategoryNodes(
                  categories: lower,
                  causes: grouped,
                  upper: false,
                  diagramWidth: diagramWidth,
                  centerY: centerY,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // ============================================================
  // CATEGORY NODES
  // ============================================================

  List<Widget> _buildCategoryNodes({
    required List<CcrFishboneCategory> categories,
    required Map<String, List<CcrFishboneCause>> causes,
    required bool upper,
    required double diagramWidth,
    required double centerY,
  }) {
    final result = <Widget>[];

    for (int index = 0; index < categories.length; index++) {
      final category = categories[index];

      final categoryCauses = causes[category.id] ??
          <CcrFishboneCause>[];

      final anchor = _branchGeometry(
        index: index,
        count: categories.length,
        upper: upper,
        diagramWidth: diagramWidth,
        centerY: centerY,
      );

      final left = (anchor.endX - _categoryWidth / 2).clamp(
        10.0,
        diagramWidth - _categoryWidth - 10,
      );

      final nodeHeight = _categoryNodeEstimatedHeight(
        categoryCauses,
      );

      final top = upper
          ? anchor.endY - nodeHeight - _branchNodeGap
          : anchor.endY + _branchNodeGap;

      result.add(
        Positioned(
          left: left,
          top: top,
          width: _categoryWidth,
          child: _fishboneCategoryNode(
            category,
            categoryCauses,
            upper,
          ),
        ),
      );
    }

    return result;
  }
  // ============================================================
  // CATEGORY NODE HEIGHT
  // ============================================================

  double _categoryNodeEstimatedHeight(
      List<CcrFishboneCause> causes,
      ) {
    if (causes.isEmpty) {
      return 66;
    }

    // Header and spacing.
    const headerHeight = 40.0;

    // Each cause card can grow when its text wraps.
    // Reserve enough room for three lines of text.
    const causeCardHeight = 55.0;

    return headerHeight +
        (causes.length * causeCardHeight);
  }

  // ============================================================
  // SHARED BRANCH GEOMETRY
  //
  // This function is used by BOTH:
  //   1. CustomPainter
  //   2. Category widgets
  //
  // Therefore the boxes and branches cannot drift apart.
  // ============================================================

  _BranchGeometry _branchGeometry({
    required int index,
    required int count,
    required bool upper,
    required double diagramWidth,
    required double centerY,
  }) {
    final effectStart = diagramWidth -
        _effectRightMargin -
        _effectWidth -
        30;

    const usableStart = 185.0;

    final usableEnd = math.max(
      usableStart + 200,
      effectStart - 160,
    );

    final available = usableEnd - usableStart;

    final anchorX = count <= 1
        ? usableStart + available / 2
        : usableStart +
        (available / (count - 1)) * index;

    final branchEndX = anchorX + _branchHorizontalOffset;

    final branchEndY = upper
        ? centerY - _branchLength
        : centerY + _branchLength;

    return _BranchGeometry(
      anchorX: anchorX,
      anchorY: centerY,
      endX: branchEndX,
      endY: branchEndY,
    );
  }

  // ============================================================
  // EFFECT NODE
  // ============================================================

  Widget _effectNode() {
    final problem = [
      _ccr?.problemDescription,
      _ccr?.complaintDescription,
    ].whereType<String>()
        .map((value) => value.trim())
        .firstWhere(
          (value) => value.isNotEmpty,
      orElse: () => '',
    );

    return Container(
      padding:
      const EdgeInsets.all(12),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          10,
        ),
        border: Border.all(
          color:
          const Color(0xFF3155C6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black
                .withValues(
              alpha: 0.04,
            ),
            blurRadius: 8,
            offset:
            const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        mainAxisSize:
        MainAxisSize.min,
        children: [
          const Text(
            'EFFECT',
            style:
            TextStyle(
              fontSize: 10,
              fontWeight:
              FontWeight.w800,
              color:
              Color(0xFF3155C6),
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            problem.isEmpty
                ? 'Problem description not entered'
                : problem,
            maxLines: 4,
            overflow:
            TextOverflow.ellipsis,
            style:
            const TextStyle(
              fontSize: 12,
              fontWeight:
              FontWeight.w700,
              color:
              Color(0xFF172033),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CATEGORY NODE
  // ============================================================

  Widget _fishboneCategoryNode(
      CcrFishboneCategory category,
      List<CcrFishboneCause> causes,
      bool upper,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w800,
                  color:
                  Color(0xFF172033),
                ),
              ),
            ),

            const SizedBox(
              width: 5,
            ),

            InkWell(
              onTap:
              _saving
                  ? null
                  : () =>
                  _addCause(
                    category,
                  ),
              borderRadius:
              BorderRadius.circular(
                8,
              ),
              child:
              Container(
                width: 26,
                height: 26,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFEFF3FF,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    7,
                  ),
                ),
                child:
                const Icon(
                  Icons.add,
                  size: 17,
                  color:
                  Color(0xFF3155C6),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 7,
        ),

        if (causes.isEmpty)
          Container(
            padding:
            const EdgeInsets
                .symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFFF8F9FB,
              ),
              borderRadius:
              BorderRadius.circular(
                7,
              ),
              border: Border.all(
                color:
                const Color(
                  0xFFE5E7EB,
                ),
              ),
            ),
            child:
            const Text(
              'No causes',
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                fontSize: 10,
                color:
                Color(0xFF9AA1AA),
              ),
            ),
          )
        else
          ...causes.map(
                (cause) =>
                _causeOnBranch(
                  cause,
                  upper,
                ),
          ),
      ],
    );
  }

  // ============================================================
  // CAUSE ON BRANCH
  // ============================================================

  Widget _causeOnBranch(
      CcrFishboneCause cause,
      bool upper,
      ) {
    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 5,
      ),
      padding:
      const EdgeInsets
          .symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          7,
        ),
        border: Border.all(
          color:
          const Color(0xFFDCE2EA),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,
        children: [
          Padding(
            padding:
            const EdgeInsets.only(
              top: 2,
            ),
            child:
            Icon(
              upper
                  ? Icons
                  .arrow_forward
                  : Icons
                  .arrow_forward,
              size: 12,
              color:
              const Color(
                0xFF3155C6,
              ),
            ),
          ),

          const SizedBox(
            width: 4,
          ),

          Expanded(
            child: Text(
              cause.causeText,
              maxLines: 3,
              overflow:
              TextOverflow.ellipsis,
              style:
              const TextStyle(
                fontSize: 10.5,
                color:
                Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CAUSE LIST CARD
  // ============================================================

  Widget _causeListCard() {
    return Container(
      padding:
      const EdgeInsets.all(20),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color:
          const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      'Potential Causes',
                      style:
                      TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w800,
                        color:
                        Color(
                          0xFF202124,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 3,
                    ),
                    Text(
                      'Review, edit or delete the causes entered for this complaint.',
                      style:
                      TextStyle(
                        fontSize: 12,
                        color:
                        Color(
                          0xFF747982,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              FilledButton.icon(
                onPressed:
                _saving ||
                    _categories
                        .isEmpty
                    ? null
                    : _addCauseFromCategories,
                icon:
                const Icon(
                  Icons.add,
                  size: 18,
                ),
                label:
                const Text(
                  'Add Cause',
                ),
                style:
                _primaryButtonStyle(),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          if (_causes.isEmpty)
            _emptyCauses()
          else
            _causeRows(),

          const SizedBox(
            height: 24,
          ),

          Row(
            mainAxisAlignment:
            MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed:
                _saving
                    ? null
                    : _load,
                child:
                const Text(
                  'Save Draft',
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              FilledButton(
                onPressed:
                _saving
                    ? null
                    : _completeFishbone,
                style:
                _primaryButtonStyle(),
                child: _saving
                    ? const SizedBox(
                  width: 17,
                  height: 17,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                    Colors.white,
                  ),
                )
                    : const Text(
                  'Complete Fishbone',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADD CAUSE FROM CATEGORY LIST
  // ============================================================

  Future<void>
  _addCauseFromCategories() async {
    final category =
    await showDialog<
        CcrFishboneCategory>(
      context: context,
      builder: (_) =>
          SimpleDialog(
            title:
            const Text(
              'Select Category',
            ),
            children:
            _categories.map(
                  (category) {
                return SimpleDialogOption(
                  onPressed: () =>
                      Navigator.pop(
                        context,
                        category,
                      ),
                  child:
                  Text(
                    category.name,
                  ),
                );
              },
            ).toList(),
          ),
    );

    if (category == null) {
      return;
    }

    await _addCause(
      category,
    );
  }

  // ============================================================
  // CAUSE ROWS
  // ============================================================

  Widget _causeRows() {
    return Column(
      children:
      _causes.map(
            (cause) {
          return Container(
            margin:
            const EdgeInsets.only(
              bottom: 8,
            ),
            padding:
            const EdgeInsets.all(
              12,
            ),
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFFF8F9FB,
              ),
              borderRadius:
              BorderRadius.circular(
                10,
              ),
              border: Border.all(
                color:
                const Color(
                  0xFFE5E7EB,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  constraints:
                  const BoxConstraints(
                    maxWidth: 170,
                  ),
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(
                      0xFFEFF3FF,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      8,
                    ),
                  ),
                  child: Text(
                    cause.categoryName,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 11,
                      fontWeight:
                      FontWeight.w700,
                      color:
                      Color(
                        0xFF3155C6,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Text(
                    cause.causeText,
                    style:
                    const TextStyle(
                      fontSize: 12.5,
                      color:
                      Color(
                        0xFF374151,
                      ),
                    ),
                  ),
                ),

                IconButton(
                  tooltip: 'Edit',
                  onPressed:
                  _saving
                      ? null
                      : () =>
                      _editCause(
                        cause,
                      ),
                  icon:
                  const Icon(
                    Icons
                        .edit_outlined,
                    size: 18,
                  ),
                ),

                IconButton(
                  tooltip: 'Delete',
                  onPressed:
                  _saving
                      ? null
                      : () =>
                      _deleteCause(
                        cause,
                      ),
                  icon:
                  const Icon(
                    Icons
                        .delete_outline,
                    size: 18,
                  ),
                ),
              ],
            ),
          );
        },
      ).toList(),
    );
  }

  // ============================================================
  // EMPTY CAUSES
  // ============================================================

  Widget _emptyCauses() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets
          .symmetric(
        vertical: 40,
      ),
      child: const Column(
        children: [
          Icon(
            Icons
                .account_tree_outlined,
            size: 38,
            color:
            Color(0xFF98A1AC),
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            'No potential causes added',
            style:
            TextStyle(
              fontSize: 13,
              fontWeight:
              FontWeight.w600,
              color:
              Color(0xFF555A63),
            ),
          ),
          SizedBox(
            height: 4,
          ),
          Text(
            'Add causes under the relevant Fishbone categories.',
            style:
            TextStyle(
              fontSize: 12,
              color:
              Color(0xFF8A9098),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY CATEGORIES
  // ============================================================

  Widget _emptyCategories() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        40,
      ),
      child: const Column(
        children: [
          Icon(
            Icons
                .category_outlined,
            size: 38,
            color:
            Color(0xFF98A1AC),
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            'No active Fishbone categories configured',
            style:
            TextStyle(
              fontSize: 13,
              fontWeight:
              FontWeight.w600,
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            'Configure active Fishbone categories in the database before adding causes.',
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              fontSize: 12,
              color:
              Color(0xFF8A9098),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _errorView() {
    return Center(
      child: Container(
        margin:
        const EdgeInsets.all(
          24,
        ),
        padding:
        const EdgeInsets.all(
          30,
        ),
        decoration:
        BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color:
            const Color(
              0xFFE5E7EB,
            ),
          ),
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .error_outline_rounded,
              size: 44,
              color:
              Color(0xFFD94A4A),
            ),

            const SizedBox(
              height: 12,
            ),

            const Text(
              'Could not load Fishbone analysis',
              style:
              TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              _error ?? '',
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                fontSize: 12,
                color:
                Color(0xFF747982),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            FilledButton(
              onPressed: _load,
              child:
              const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CHIP
  // ============================================================

  Widget _chip(
      String value,
      ) {
    return Container(
      constraints:
      const BoxConstraints(
        maxWidth: 190,
      ),
      padding:
      const EdgeInsets
          .symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFF5F6F8),
        borderRadius:
        BorderRadius.circular(
          10,
        ),
      ),
      child: Text(
        value,
        maxLines: 1,
        overflow:
        TextOverflow.ellipsis,
        style:
        const TextStyle(
          fontSize: 11.5,
          fontWeight:
          FontWeight.w600,
          color:
          Color(0xFF62666D),
        ),
      ),
    );
  }

  // ============================================================
  // BUTTON STYLE
  // ============================================================

  ButtonStyle _primaryButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor:
      const Color(0xFF7655C9),
      foregroundColor:
      Colors.white,
      elevation: 0,
      padding:
      const EdgeInsets
          .symmetric(
        horizontal: 18,
        vertical: 13,
      ),
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(
          11,
        ),
      ),
    );
  }
}

// ============================================================
// BRANCH GEOMETRY
// ============================================================

class _BranchGeometry {
  final double anchorX;
  final double anchorY;
  final double endX;
  final double endY;

  const _BranchGeometry({
    required this.anchorX,
    required this.anchorY,
    required this.endX,
    required this.endY,
  });
}

// ============================================================
// FISHBONE PAINTER
// ============================================================

class _RealFishbonePainter
    extends CustomPainter {
  final int upperCount;
  final int lowerCount;
  final double diagramWidth;
  final double centerY;

  const _RealFishbonePainter({
    required this.upperCount,
    required this.lowerCount,
    required this.diagramWidth,
    required this.centerY,
  });


  static const double spineStartX = 45;

  static const double branchLength = 205;

  static const double branchHorizontalOffset = 90;

  static const double effectWidth = 205;

  static const double effectRightMargin = 24;

  // ============================================================
  // SHARED BRANCH POSITION
  // ============================================================

  double _branchAnchorX({
    required int index,
    required int count,
  }) {
    final effectStart =
        diagramWidth -
            effectRightMargin -
            effectWidth -
            30;

    final usableStart =
    185.0;

    final usableEnd =
    math.max(
      usableStart + 200,
      effectStart - 160,
    );

    final available =
        usableEnd -
            usableStart;

    if (count <= 1) {
      return usableStart +
          available / 2;
    }

    final spacing =
        available /
            (count - 1);

    return usableStart +
        spacing * index;
  }

  // ============================================================
  // PAINT
  // ============================================================

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final bonePaint =
    Paint()
      ..color =
      const Color(
        0xFF1590FF,
      )
      ..strokeWidth = 2.4
      ..style =
          PaintingStyle.stroke
      ..strokeCap =
          StrokeCap.round;

    final ribPaint =
    Paint()
      ..color =
      const Color(
        0xFF1590FF,
      )
      ..strokeWidth = 1.6
      ..style =
          PaintingStyle.stroke
      ..strokeCap =
          StrokeCap.round;

    // ----------------------------------------------------------
    // MAIN SPINE
    // ----------------------------------------------------------

    final effectStart =
        diagramWidth -
            effectRightMargin -
            effectWidth -
            30;

    final spineEndX =
        effectStart + 120;

    canvas.drawLine(
      Offset(
        spineStartX,
        centerY,
      ),
      Offset(
        spineEndX,
        centerY,
      ),
      bonePaint,
    );

    // ----------------------------------------------------------
    // EFFECT ARROW
    // ----------------------------------------------------------

    final arrowX =
        spineEndX;

    canvas.drawLine(
      Offset(
        arrowX - 12,
        centerY - 7,
      ),
      Offset(
        arrowX,
        centerY,
      ),
      bonePaint,
    );

    canvas.drawLine(
      Offset(
        arrowX - 12,
        centerY + 7,
      ),
      Offset(
        arrowX,
        centerY,
      ),
      bonePaint,
    );

    // ----------------------------------------------------------
    // UPPER BRANCHES
    // ----------------------------------------------------------

    for (int i = 0;
    i < upperCount;
    i++) {
      _drawBranch(
        canvas,
        bonePaint,
        ribPaint,
        index: i,
        count: upperCount,
        upper: true,
      );
    }

    // ----------------------------------------------------------
    // LOWER BRANCHES
    // ----------------------------------------------------------

    for (int i = 0;
    i < lowerCount;
    i++) {
      _drawBranch(
        canvas,
        bonePaint,
        ribPaint,
        index: i,
        count: lowerCount,
        upper: false,
      );
    }
  }

  // ============================================================
  // DRAW ONE BRANCH
  // ============================================================

  void _drawBranch(
      Canvas canvas,
      Paint bonePaint,
      Paint ribPaint, {
        required int index,
        required int count,
        required bool upper,
      }) {
    final anchorX =
    _branchAnchorX(
      index: index,
      count: count,
    );

    final anchor =
    Offset(
      anchorX,
      centerY,
    );

    final end =
    Offset(
      anchorX +
          branchHorizontalOffset,
      upper
          ? centerY -
          branchLength
          : centerY +
          branchLength,
    );

    // Main angled branch.
    canvas.drawLine(
      anchor,
      end,
      bonePaint,
    );

    // Three horizontal ribs.
    for (int ribIndex = 1;
    ribIndex <= 3;
    ribIndex++) {
      final t =
          ribIndex / 4;

      final x =
          anchor.dx +
              (end.dx -
                  anchor.dx) *
                  t;

      final y =
          anchor.dy +
              (end.dy -
                  anchor.dy) *
                  t;

      const ribLength =
      65.0;

      canvas.drawLine(
        Offset(
          x,
          y,
        ),
        Offset(
          x + ribLength,
          y,
        ),
        ribPaint,
      );
    }
  }

  // ============================================================
  // REPAINT
  // ============================================================

  @override
  bool shouldRepaint(
      covariant _RealFishbonePainter oldDelegate,
      ) {
    return oldDelegate.upperCount != upperCount ||
        oldDelegate.lowerCount != lowerCount ||
        oldDelegate.diagramWidth != diagramWidth ||
        oldDelegate.centerY != centerY;
  }
}