import 'package:flutter/material.dart';

import '../../models/ccr/ccr_case.dart';
import '../../models/ccr/ccr_why_analysis.dart';
import '../../services/ccr/ccr_service.dart';
import '../../services/ccr/ccr_why_service.dart';
import 'ccr_corrective_action_screen.dart';

class CcrWhyScreen extends StatefulWidget {
  const CcrWhyScreen({
    super.key,
    required this.ccrId,
  });

  final String ccrId;

  @override
  State<CcrWhyScreen> createState() =>
      _CcrWhyScreenState();
}

class _CcrWhyScreenState
    extends State<CcrWhyScreen> {
  final CcrService _ccrService =
  CcrService();

  final CcrWhyService _service =
  CcrWhyService();

  CcrCase? _ccr;

  List<CcrWhyAnalysis> _analyses = [];

  final Map<String, TextEditingController>
  _rootCauseControllers = {};

  final Map<String, Map<int, TextEditingController>>
  _whyControllers = {};

  final Map<String, Map<int, TextEditingController>>
  _verificationControllers = {};

  final Map<String, Map<int, bool?>>
  _evidenceValues = {};

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
    for (final controller
    in _rootCauseControllers.values) {
      controller.dispose();
    }

    for (final map
    in _whyControllers.values) {
      for (final controller
      in map.values) {
        controller.dispose();
      }
    }

    for (final map
    in _verificationControllers.values) {
      for (final controller
      in map.values) {
        controller.dispose();
      }
    }

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
      final results = await Future.wait([
        _ccrService.getCcrById(
          widget.ccrId,
        ),
        _service.getAnalyses(
          widget.ccrId,
        ),
      ]);

      final ccr =
      results[0] as CcrCase;

      final allAnalyses =
      results[1] as List<CcrWhyAnalysis>;

      // ----------------------------------------------------------
// COMBINED 5-WHY WORKFLOW STAGE
//
// The database has ONE stage: five_why.
//
// Occurrence and Non-Detection are separate analysis types
// inside this same workflow stage.
// ----------------------------------------------------------

      final currentStage =
      (ccr.currentStageKey ?? '')
          .trim()
          .toLowerCase();

      if (currentStage == 'corrective_action') {
        if (!mounted) return;

        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CcrCorrectiveActionScreen(
              ccrId: widget.ccrId,
            ),
          ),
        );

        return;
      }

      if (currentStage != 'five_why') {
        throw Exception(
          'The CCR is currently at "$currentStage", '
              'which is not the configured 5-Why stage.',
        );
      }

// Load both Occurrence and Non-Detection analyses.
      final List<CcrWhyAnalysis> analyses =
      allAnalyses.where((analysis) {
        final type = analysis.analysisType
            .trim()
            .toLowerCase();

        return type == 'occurrence' ||
            type == 'non_detection';
      }).toList();

      if (analyses.isEmpty) {
        throw Exception(
          'No Occurrence or Non-Detection analyses '
              'are available for this CCR.',
        );
      }

      final hasOccurrence = analyses.any(
            (analysis) =>
        analysis.analysisType.trim().toLowerCase() ==
            'occurrence',
      );

      final hasNonDetection = analyses.any(
            (analysis) =>
        analysis.analysisType.trim().toLowerCase() ==
            'non_detection',
      );

      if (!hasOccurrence || !hasNonDetection) {
        throw Exception(
          'Both Occurrence and Non-Detection analyses '
              'must be available for this CCR.',
        );
      }

      _disposeControllers();

      _rootCauseControllers.clear();
      _whyControllers.clear();
      _verificationControllers.clear();
      _evidenceValues.clear();

      for (final analysis in analyses) {
        _rootCauseControllers[
        analysis.id] =
            TextEditingController(
              text:
              analysis.potentialRootCause,
            );

        _whyControllers[
        analysis.id] =
        {};

        _verificationControllers[
        analysis.id] =
        {};

        _evidenceValues[
        analysis.id] =
        {};

        for (final step in analysis.steps) {
          _whyControllers[
          analysis.id]![
          step.whyNumber] =
              TextEditingController(
                text: step.whyText,
              );

          _verificationControllers[
          analysis.id]![
          step.whyNumber] =
              TextEditingController(
                text:
                step.verificationText,
              );

          _evidenceValues[
          analysis.id]![
          step.whyNumber] =
              step.evidenceAvailable;
        }
      }

      if (!mounted) return;

      setState(() {
        _ccr = ccr;
        _analyses = analyses;
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
  // CONTROLLER CLEANUP
  // ============================================================

  void _disposeControllers() {
    for (final controller
    in _rootCauseControllers.values) {
      controller.dispose();
    }

    for (final map
    in _whyControllers.values) {
      for (final controller
      in map.values) {
        controller.dispose();
      }
    }

    for (final map
    in _verificationControllers.values) {
      for (final controller
      in map.values) {
        controller.dispose();
      }
    }
  }

  // ============================================================
  // GET / CREATE WHY CONTROLLER
  // ============================================================

  TextEditingController _whyController(
      String analysisId,
      int whyNumber,
      ) {
    final map =
    _whyControllers.putIfAbsent(
      analysisId,
          () => {},
    );

    return map.putIfAbsent(
      whyNumber,
          () => TextEditingController(),
    );
  }

  TextEditingController _verificationController(
      String analysisId,
      int whyNumber,
      ) {
    final map =
    _verificationControllers.putIfAbsent(
      analysisId,
          () => {},
    );

    return map.putIfAbsent(
      whyNumber,
          () => TextEditingController(),
    );
  }

  bool? _evidenceValue(
      String analysisId,
      int whyNumber,
      ) {
    return _evidenceValues
        .putIfAbsent(
      analysisId,
          () => {},
    )[whyNumber];
  }

  // ============================================================
  // SAVE ONE ANALYSIS
  // ============================================================

  Future<void> _saveAnalysis(
      CcrWhyAnalysis analysis,
      ) async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      await _service.savePotentialRootCause(
        analysisId: analysis.id,
        potentialRootCause:
        _rootCauseControllers[
        analysis.id]
            ?.text
            .trim() ??
            '',
      );

      for (int whyNumber = 1;
      whyNumber <= 5;
      whyNumber++) {
        final whyController =
        _whyController(
          analysis.id,
          whyNumber,
        );

        final verificationController =
        _verificationController(
          analysis.id,
          whyNumber,
        );

        final whyText =
        whyController.text.trim();

        final verificationText =
        verificationController.text.trim();

        final evidence =
        _evidenceValue(
          analysis.id,
          whyNumber,
        );

        // ------------------------------------------------------
        // Do not create empty database rows.
        //
        // If an existing row is already present and the user
        // clears it, remove that row.
        // ------------------------------------------------------

        final existingStep =
            analysis.steps
                .where(
                  (step) =>
              step.whyNumber ==
                  whyNumber,
            )
                .firstOrNull;

        if (whyText.isEmpty &&
            verificationText.isEmpty &&
            evidence == null) {
          if (existingStep?.id != null) {
            await _service.deleteStep(
              existingStep!.id!,
            );
          }

          continue;
        }

        await _service.saveStep(
          analysisId: analysis.id,
          whyNumber: whyNumber,
          whyText: whyText,
          verificationText:
          verificationText,
          evidenceAvailable: evidence,
        );
      }

      if (!mounted) return;

      _message(
        '${analysis.analysisTitle} saved.',
      );
    } catch (e) {
      if (!mounted) return;

      _message(
        'Could not save ${analysis.analysisTitle}: $e',
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
  // SAVE ALL
  // ============================================================

  Future<void> _saveDraft() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      for (final analysis in _analyses) {
        await _service.savePotentialRootCause(
          analysisId: analysis.id,
          potentialRootCause:
          _rootCauseControllers[
          analysis.id]
              ?.text
              .trim() ??
              '',
        );

        for (int whyNumber = 1;
        whyNumber <= 5;
        whyNumber++) {
          final whyController =
          _whyController(
            analysis.id,
            whyNumber,
          );

          final verificationController =
          _verificationController(
            analysis.id,
            whyNumber,
          );

          final whyText =
          whyController.text.trim();

          final verificationText =
          verificationController
              .text
              .trim();

          final evidence =
          _evidenceValue(
            analysis.id,
            whyNumber,
          );

          final existingStep =
              analysis.steps
                  .where(
                    (step) =>
                step.whyNumber ==
                    whyNumber,
              )
                  .firstOrNull;

          if (whyText.isEmpty &&
              verificationText.isEmpty &&
              evidence == null) {
            if (existingStep?.id != null) {
              await _service.deleteStep(
                existingStep!.id!,
              );
            }

            continue;
          }

          await _service.saveStep(
            analysisId: analysis.id,
            whyNumber: whyNumber,
            whyText: whyText,
            verificationText:
            verificationText,
            evidenceAvailable: evidence,
          );
        }
      }

      if (!mounted) return;

      _message(
        '5-Why draft saved.',
      );
    } catch (e) {
      if (!mounted) return;

      _message(
        'Could not save 5-Why draft: $e',
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
  // COMPLETE
  // ============================================================

  Future<void> _complete() async {
    if (_saving) return;

    if (_analyses.isEmpty) {
      _message(
        'No Yes root causes are available for 5-Why analysis.',
        error: true,
      );
      return;
    }

    for (final analysis in _analyses) {
      final rootCause =
          _rootCauseControllers[
          analysis.id]
              ?.text
              .trim() ??
              '';

      if (rootCause.isEmpty) {
        _message(
          'Potential root cause is required for ${analysis.analysisTitle}.',
          error: true,
        );
        return;
      }

      bool hasWhy = false;

      for (int whyNumber = 1;
      whyNumber <= 5;
      whyNumber++) {
        final text =
        _whyController(
          analysis.id,
          whyNumber,
        ).text.trim();

        if (text.isNotEmpty) {
          hasWhy = true;
          break;
        }
      }

      if (!hasWhy) {
        _message(
          'Enter at least one Why for ${analysis.analysisTitle}.',
          error: true,
        );
        return;
      }
    }

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Complete 5-Why Analysis',
        ),
        content: const Text(
          'The completed Occurrence and Non-Detection analyses will be submitted and the CCR will move to the next configured workflow stage.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
                  context,
                  false,
                ),
            child: const Text(
              'Cancel',
            ),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(
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

    if (confirmed != true) return;

    setState(() {
      _saving = true;
    });

    try {
      // --------------------------------------------------------
      // Save all current UI values first.
      // --------------------------------------------------------

      for (final analysis in _analyses) {
        await _service.savePotentialRootCause(
          analysisId: analysis.id,
          potentialRootCause:
          _rootCauseControllers[
          analysis.id]
              ?.text
              .trim() ??
              '',
        );

        for (int whyNumber = 1;
        whyNumber <= 5;
        whyNumber++) {
          final whyText =
          _whyController(
            analysis.id,
            whyNumber,
          ).text.trim();

          final verificationText =
          _verificationController(
            analysis.id,
            whyNumber,
          ).text.trim();

          final evidence =
          _evidenceValue(
            analysis.id,
            whyNumber,
          );

          if (whyText.isEmpty &&
              verificationText.isEmpty &&
              evidence == null) {
            continue;
          }

          await _service.saveStep(
            analysisId: analysis.id,
            whyNumber: whyNumber,
            whyText: whyText,
            verificationText:
            verificationText,
            evidenceAvailable: evidence,
          );
        }
      }

      // --------------------------------------------------------
      // Move to next configured workflow stage.
      // --------------------------------------------------------

      await _service.completeWhyStage(
        widget.ccrId,
      );

// ----------------------------------------------------------
// Read the stage AFTER the database transition.
//
// The service has already advanced current_stage using the
// workflow-stage configuration.
// ----------------------------------------------------------

      // --------------------------------------------------------
// Read the CCR again AFTER the database workflow transition.
//
// getCcrById() can return null, so explicitly handle that
// before accessing currentStageKey.
// --------------------------------------------------------

      final CcrCase? updatedCcr =
      await _ccrService.getCcrById(
        widget.ccrId,
      );

      if (updatedCcr == null) {
        throw Exception(
          '5-Why completed, but the CCR could not be reloaded to determine the next workflow stage.',
        );
      }

      final nextStage =
      (updatedCcr.currentStageKey ?? '')
          .trim()
          .toLowerCase();

      if (nextStage.isEmpty) {
        throw Exception(
          '5-Why completed, but the next CCR workflow stage could not be determined.',
        );
      }

      if (!mounted) return;

      _message(
        '5-Why Analysis completed.',
      );

// --------------------------------------------------------
// Occurrence 5-Why
//        ↓
// Non-Detection 5-Why
// --------------------------------------------------------

      if (nextStage ==
          'five_why_non_detection' ||
          nextStage == 'non_detection' ||
          nextStage == 'non-detection' ||
          nextStage == 'five-why-non-detection') {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CcrWhyScreen(
                  ccrId: widget.ccrId,
                ),
          ),
        );

        return;
      }

// --------------------------------------------------------
// Non-Detection 5-Why
//        ↓
// Corrective Action & Verification
// --------------------------------------------------------

      if (nextStage ==
          'corrective_action' ||
          nextStage == 'corrective-action') {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CcrCorrectiveActionScreen(
                  ccrId: widget.ccrId,
                ),
          ),
        );

        return;
      }

// --------------------------------------------------------
// Do NOT send the user back to Home.
//
// If the DB contains another stage, show the actual stage
// instead of silently destroying the workflow.
// --------------------------------------------------------

      throw Exception(
        'The CCR moved to workflow stage "$nextStage", '
            'but no continuation screen is configured for that stage.',
      );
    } catch (e) {
      if (!mounted) return;

      _message(
        'Could not complete 5-Why Analysis: $e',
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
        content: Text(message),
        behavior:
        SnackBarBehavior.floating,
        duration:
        const Duration(seconds: 3),
        backgroundColor: error
            ? const Color(0xFFB42318)
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
        backgroundColor: Colors.white,
        foregroundColor:
        const Color(0xFF172033),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                const Color(0xFFEFF3FF),
                borderRadius:
                BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.account_tree_outlined,
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

  // ============================================================
  // BODY
  // ============================================================

  Widget _body() {
    return Column(
      children: [
        _stageHeader(),
        Expanded(
          child: SingleChildScrollView(
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
                  maxWidth: 1250,
                ),
                child: Column(
                  children: [
                    _summaryCard(),
                    const SizedBox(height: 18),
                    ..._analyses.map(
                          (analysis) =>
                          Padding(
                            padding:
                            const EdgeInsets.only(
                              bottom: 18,
                            ),
                            child:
                            _analysisCard(
                              analysis,
                            ),
                          ),
                    ),
                    _bottomActions(),
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
            maxWidth: 1250,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_tree_outlined,
                color:
                Color(0xFF3155C6),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      '5-Why Analysis',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Analyze the occurrence and non-detection paths for validated root causes.',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                        Color(0xFF6B7280),
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
    final causeIds =
    _analyses
        .map(
          (analysis) =>
      analysis.causeId,
    )
        .where(
          (id) => id.isNotEmpty,
    )
        .toSet();

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
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
            decoration: BoxDecoration(
              color:
              const Color(0xFFEFF3FF),
              borderRadius:
              BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color:
              Color(0xFF3155C6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Validated Root Causes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${causeIds.length} validated cause${causeIds.length == 1 ? '' : 's'} • '
                      '${_analyses.length} 5-Why analyses',
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

  // ============================================================
  // ANALYSIS CARD
  // ============================================================

  Widget _analysisCard(
      CcrWhyAnalysis analysis,
      ) {
    final isOccurrence =
        analysis.isOccurrence;

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(20),
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
        crossAxisAlignment:
        CrossAxisAlignment.start,
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
                child: Icon(
                  isOccurrence
                      ? Icons.trending_up_outlined
                      : Icons.visibility_outlined,
                  color:
                  const Color(
                    0xFF3155C6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      analysis.analysisTitle,
                      style:
                      const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${analysis.categoryName} • ${analysis.causeText}',
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      const TextStyle(
                        fontSize: 12,
                        color:
                        Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ----------------------------------------------------
          // SOURCE CAUSE
          // ----------------------------------------------------

          _fieldLabel(
            'Validated Potential Cause',
          ),

          const SizedBox(height: 7),

          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.all(12),
            decoration:
            BoxDecoration(
              color:
              const Color(0xFFF8F9FB),
              borderRadius:
              BorderRadius.circular(
                9,
              ),
              border: Border.all(
                color:
                const Color(
                  0xFFE0E3E8,
                ),
              ),
            ),
            child: Text(
              analysis.causeText,
              style:
              const TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.w600,
                color:
                Color(0xFF374151),
              ),
            ),
          ),

          const SizedBox(height: 14),

          _fieldLabel(
            'Potential Root Cause',
          ),

          const SizedBox(height: 7),

          TextField(
            controller:
            _rootCauseControllers[
            analysis.id],
            maxLines: 2,
            decoration:
            _inputDecoration(
              'Enter the potential root cause identified from this analysis.',
            ),
          ),

          const SizedBox(height: 18),

          // ----------------------------------------------------
          // WHY TABLE
          // ----------------------------------------------------

          _whyHeader(),

          const SizedBox(height: 8),

          for (int whyNumber = 1;
          whyNumber <= 5;
          whyNumber++)
            _whyRow(
              analysis,
              whyNumber,
            ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment:
            MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed:
                _saving
                    ? null
                    : () =>
                    _saveAnalysis(
                      analysis,
                    ),
                icon: const Icon(
                  Icons.save_outlined,
                  size: 17,
                ),
                label:
                const Text(
                  'Save Analysis',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WHY HEADER
  // ============================================================

  Widget _whyHeader() {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration:
      const BoxDecoration(
        color:
        Color(0xFFF8F9FB),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 65,
            child: Text(
              'Why',
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              'Why / Reason',
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'How was it verified?',
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              'Evidence',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WHY ROW
  // ============================================================

  Widget _whyRow(
      CcrWhyAnalysis analysis,
      int whyNumber,
      ) {
    final whyController =
    _whyController(
      analysis.id,
      whyNumber,
    );

    final verificationController =
    _verificationController(
      analysis.id,
      whyNumber,
    );

    final evidence =
    _evidenceValue(
      analysis.id,
      whyNumber,
    );

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 9,
      ),
      padding:
      const EdgeInsets.all(10),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(10),
        border: Border.all(
          color:
          const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 65,
            child: Padding(
              padding:
              const EdgeInsets.only(
                top: 11,
              ),
              child: Container(
                width: 42,
                padding:
                const EdgeInsets.symmetric(
                  vertical: 7,
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
                  '$whyNumber${_ordinalSuffix(whyNumber)}',
                  textAlign:
                  TextAlign.center,
                  style:
                  const TextStyle(
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Color(0xFF3155C6),
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            flex: 4,
            child: TextField(
              controller:
              whyController,
              maxLines: 3,
              decoration:
              _inputDecoration(
                'Enter why ${whyNumber}.',
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            flex: 3,
            child: TextField(
              controller:
              verificationController,
              maxLines: 3,
              decoration:
              _inputDecoration(
                'Enter verification method / evidence.',
              ),
            ),
          ),

          const SizedBox(width: 10),

          SizedBox(
            width: 150,
            child:
            _evidenceSelector(
              analysisId:
              analysis.id,
              whyNumber:
              whyNumber,
              value: evidence,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EVIDENCE SELECTOR
  // ============================================================

  Widget _evidenceSelector({
    required String analysisId,
    required int whyNumber,
    required bool? value,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            _choiceButton(
              label: 'Yes',
              selected:
              value == true,
              onTap: _saving
                  ? null
                  : () {
                setState(() {
                  _evidenceValues[
                  analysisId]![
                  whyNumber] = true;
                });
              },
            ),
            const SizedBox(width: 6),
            _choiceButton(
              label: 'No',
              selected:
              value == false,
              onTap: _saving
                  ? null
                  : () {
                setState(() {
                  _evidenceValues[
                  analysisId]![
                  whyNumber] = false;
                });
              },
            ),
          ],
        ),
        if (value == null)
          const Padding(
            padding:
            EdgeInsets.only(
              top: 5,
            ),
            child: Text(
              'Not selected',
              style: TextStyle(
                fontSize: 10,
                color:
                Color(0xFF9AA1AB),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // CHOICE BUTTON
  // ============================================================

  Widget _choiceButton({
    required String label,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius:
      BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 7,
        ),
        decoration:
        BoxDecoration(
          color: selected
              ? const Color(
            0xFFEFF3FF,
          )
              : Colors.white,
          borderRadius:
          BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? const Color(
              0xFF3155C6,
            )
                : const Color(
              0xFFD5D9E0,
            ),
          ),
        ),
        child: Text(
          label,
          style:
          TextStyle(
            fontSize: 11,
            fontWeight:
            FontWeight.w700,
            color: selected
                ? const Color(
              0xFF3155C6,
            )
                : const Color(
              0xFF667085,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ORDINAL
  // ============================================================

  String _ordinalSuffix(
      int number,
      ) {
    if (number == 1) return 'st';
    if (number == 2) return 'nd';
    if (number == 3) return 'rd';
    return 'th';
  }

  // ============================================================
  // FIELD HELPERS
  // ============================================================

  Widget _fieldLabel(
      String text,
      ) {
    return Text(
      text,
      style:
      const TextStyle(
        fontSize: 13,
        fontWeight:
        FontWeight.w600,
        color:
        Color(0xFF3F4349),
      ),
    );
  }

  InputDecoration _inputDecoration(
      String hint,
      ) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
      const TextStyle(
        color:
        Color(0xFF9A9EA5),
        fontSize: 12,
      ),
      filled: true,
      fillColor:
      const Color(0xFFF8F9FB),
      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      border:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(9),
        borderSide: const BorderSide(
          color:
          Color(0xFFE0E3E8),
        ),
      ),
      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(9),
        borderSide: const BorderSide(
          color:
          Color(0xFFE0E3E8),
        ),
      ),
      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(9),
        borderSide:
        const BorderSide(
          color:
          Color(0xFF3155C6),
          width: 1.4,
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM ACTIONS
  // ============================================================

  Widget _bottomActions() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(18),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color:
          const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed:
            _saving
                ? null
                : _saveDraft,
            child:
            const Text(
              'Save Draft',
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed:
            _saving
                ? null
                : _complete,
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
              'Complete 5-Why',
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
        const EdgeInsets.all(24),
        padding:
        const EdgeInsets.all(30),
        decoration:
        BoxDecoration(
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
              'Could not load 5-Why Analysis',
              style:
              TextStyle(
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
              style:
              const TextStyle(
                fontSize: 12,
                color:
                Color(0xFF747982),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _load,
              style:
              _primaryButtonStyle(),
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
      padding:
      const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFF5F6F8),
        borderRadius:
        BorderRadius.circular(10),
      ),
      child: Text(
        value,
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
}