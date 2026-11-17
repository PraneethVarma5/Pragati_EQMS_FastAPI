import 'package:flutter/material.dart';

import '../../models/ccr/ccr_case.dart';
import '../../models/ccr/ccr_root_cause_validation.dart';
import '../../services/ccr/ccr_root_cause_validation_service.dart';
import '../../services/ccr/ccr_service.dart';
import 'ccr_why_screen.dart';

class CcrRootCauseValidationScreen extends StatefulWidget {
  const CcrRootCauseValidationScreen({
    super.key,
    required this.ccrId,
  });

  final String ccrId;

  @override
  State<CcrRootCauseValidationScreen> createState() =>
      _CcrRootCauseValidationScreenState();
}

class _CcrRootCauseValidationScreenState
    extends State<CcrRootCauseValidationScreen> {
  final CcrService _ccrService = CcrService();

  final CcrRootCauseValidationService _service =
  CcrRootCauseValidationService();

  CcrCase? _ccr;

  List<CcrRootCauseValidation> _validations = [];

  final Map<String, TextEditingController> _controllers = {};

  // null  = not selected
  // true  = Yes
  // false = No
  final Map<String, bool?> _relevance = {};

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
    for (final controller in _controllers.values) {
      controller.dispose();
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
      final ccr = await _ccrService.getCcrById(
        widget.ccrId,
      );

      if (ccr == null) {
        throw Exception(
          'CCR record not found. Please verify the CCR ID.',
        );
      }

      final validations = await _service.getValidations(
        widget.ccrId,
      );

      // Dispose old controllers before rebuilding them.
      for (final controller in _controllers.values) {
        controller.dispose();
      }

      _controllers.clear();
      _relevance.clear();

      // Restore saved evidence and Yes/No selections.
      for (final item in validations) {
        _controllers[item.fishboneCauseId] =
            TextEditingController(
              text: item.validationText,
            );

        _relevance[item.fishboneCauseId] =
            item.relevance;
      }

      if (!mounted) return;

      setState(() {
        _ccr = ccr;
        _validations = validations;
        _loading = false;
        _error = null;
      });

    } catch (e, stackTrace) {
      debugPrint('ROOT CAUSE VALIDATION LOAD ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }
  // ============================================================
  // SAVE ONE ROW
  // ============================================================

  Future<void> _saveRow(
      CcrRootCauseValidation item,
      ) async {
    if (_saving) return;

    final relevance = _relevance[item.fishboneCauseId];

    if (relevance == null) {
      _message(
        'Select Yes or No first.',
        error: true,
      );
      return;
    }

    final controller = _controllers[item.fishboneCauseId];

    setState(() {
      _saving = true;
    });

    try {
      await _service.saveValidation(
        fishboneCauseId: item.fishboneCauseId,
        validationText: controller?.text.trim() ?? '',
        relevance: relevance,
      );

      if (!mounted) return;

      _message(
        'Validation saved.',
      );
    } catch (e) {
      if (!mounted) return;

      _message(
        'Could not save validation: $e',
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
  // SAVE DRAFT
  // ============================================================

  Future<void> _saveDraft() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      for (final item in _validations) {
        final relevance = _relevance[item.fishboneCauseId];

        // A cause that has not been answered yet is intentionally
        // skipped. The user can continue later.
        if (relevance == null) {
          continue;
        }

        await _service.saveValidation(
          fishboneCauseId: item.fishboneCauseId,
          validationText:
          _controllers[item.fishboneCauseId]?.text.trim() ?? '',
          relevance: relevance,
        );
      }

      if (!mounted) return;

      _message(
        'Root Cause Validation draft saved.',
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
  // COMPLETE
  // ============================================================

  Future<void> _complete() async {
    if (_saving) return;

    // ----------------------------------------------------------
    // A Fishbone without causes cannot proceed.
    // ----------------------------------------------------------

    if (_validations.isEmpty) {
      _message(
        'No Fishbone causes are available for validation.',
        error: true,
      );
      return;
    }

    // ----------------------------------------------------------
    // Every cause must have a Yes or No decision.
    // ----------------------------------------------------------

    final missing = _validations.where(
          (item) =>
      _relevance[item.fishboneCauseId] == null,
    );

    if (missing.isNotEmpty) {
      _message(
        'Select Yes or No for every Fishbone cause before completing validation.',
        error: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Complete Root Cause Validation',
        ),
        content: const Text(
          'The Yes/No decisions will determine which causes can continue to the 5-Why analysis.',
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

    if (confirmed != true) return;

    setState(() {
      _saving = true;
    });

    try {
      // --------------------------------------------------------
      // Save every current Yes/No decision and validation text.
      // --------------------------------------------------------

      for (final item in _validations) {
        final relevance =
        _relevance[item.fishboneCauseId];

        if (relevance == null) {
          throw Exception(
            'A Fishbone cause has not been assigned Yes or No.',
          );
        }

        await _service.saveValidation(
          fishboneCauseId: item.fishboneCauseId,
          validationText:
          _controllers[item.fishboneCauseId]?.text.trim() ?? '',
          relevance: relevance,
        );
      }

      // --------------------------------------------------------
      // Move CCR to the next database-configured workflow stage.
      // --------------------------------------------------------

      await _service.completeValidation(
        widget.ccrId,
      );

      if (!mounted) return;

      _message(
        'Root Cause Validation completed.',
      );

// --------------------------------------------------------
// Directly continue to the 5-Why stage.
//
// Only causes marked Yes by Root Cause Validation are loaded
// by CcrWhyService.
// --------------------------------------------------------

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CcrWhyScreen(
            ccrId: widget.ccrId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _message(
        'Could not complete validation: $e',
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

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
        error ? const Color(0xFFB42318) : null,
        duration: const Duration(
          seconds: 3,
        ),
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
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.fact_check_outlined,
                color: Color(0xFF3155C6),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _ccr?.displayNumber ??
                  'Customer Complaint Registration',
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
              120,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1250,
                ),
                child: _validationCard(),
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
                Icons.fact_check_outlined,
                color: Color(0xFF3155C6),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Root Cause Validation',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Validate each potential cause identified in the Fishbone analysis.',
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
  // VALIDATION CARD
  // ============================================================

  Widget _validationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
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
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3FF),
                  borderRadius:
                  BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.rule_outlined,
                  color: Color(0xFF3155C6),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Potential Root Cause Validation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Select Yes or No for every Fishbone cause. Only causes marked Yes proceed to the next analysis.',
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
          const SizedBox(height: 20),
          if (_validations.isEmpty)
            _emptyValidation()
          else
            _validationRows(),
          const SizedBox(height: 24),
          Row(
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
                  'Complete Validation',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VALIDATION ROWS
  // ============================================================

  Widget _validationRows() {
    return Column(
      children: [
        _tableHeader(),
        const SizedBox(height: 8),
        ..._validations.map(
          _validationRow,
        ),
      ],
    );
  }

  // ============================================================
  // TABLE HEADER
  // ============================================================

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FB),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              'Category',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Potential Cause',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Validation / Evidence',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(
            width: 210,
            child: Text(
              'Relevance',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(
            width: 48,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VALIDATION ROW
  // ============================================================

  Widget _validationRow(
      CcrRootCauseValidation item,
      ) {
    final controller =
    _controllers[item.fishboneCauseId];

    final selected =
    _relevance[item.fishboneCauseId];

    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 11,
                right: 10,
              ),
              child: Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3FF),
                  borderRadius:
                  BorderRadius.circular(7),
                ),
                child: Text(
                  item.categoryName,
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3155C6),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 8,
                right: 12,
              ),
              child: Text(
                item.causeText,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                'Enter validation / evidence',
                filled: true,
                fillColor:
                const Color(0xFFF8F9FB),
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(9),
                ),
                enabledBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(9),
                  borderSide: const BorderSide(
                    color: Color(0xFFE1E5EA),
                  ),
                ),
                focusedBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(9),
                  borderSide: const BorderSide(
                    color: Color(0xFF3155C6),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 210,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 3,
              ),
              child: _yesNoSelector(
                item,
                selected,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              tooltip: 'Save validation',
              onPressed:
              _saving
                  ? null
                  : () => _saveRow(item),
              icon: const Icon(
                Icons.save_outlined,
                size: 19,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // YES / NO SELECTOR
  //
  // We intentionally do NOT use SegmentedButton here.
  //
  // A new validation has a legitimate third state:
  //
  // null  -> Not selected
  // true  -> Yes
  // false -> No
  //
  // This prevents Flutter's SegmentedButton assertion when
  // selected == null.
  // ============================================================

  Widget _yesNoSelector(
      CcrRootCauseValidation item,
      bool? selected,
      ) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.center,
      children: [
        _relevanceButton(
          label: 'Yes',
          icon: Icons.check_rounded,
          selected: selected == true,
          onPressed: _saving
              ? null
              : () {
            setState(() {
              _relevance[
              item.fishboneCauseId] = true;
            });
          },
        ),
        const SizedBox(width: 8),
        _relevanceButton(
          label: 'No',
          icon: Icons.close_rounded,
          selected: selected == false,
          onPressed: _saving
              ? null
              : () {
            setState(() {
              _relevance[
              item.fishboneCauseId] = false;
            });
          },
        ),
      ],
    );
  }

  // ============================================================
  // YES / NO BUTTON
  // ============================================================

  Widget _relevanceButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 38,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 16,
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected
              ? const Color(0xFFEFF3FF)
              : Colors.white,
          foregroundColor: selected
              ? const Color(0xFF3155C6)
              : const Color(0xFF667085),
          side: BorderSide(
            color: selected
                ? const Color(0xFF3155C6)
                : const Color(0xFFD5D9E0),
            width: selected ? 1.4 : 1,
          ),
          padding:
          const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(9),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _emptyValidation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius:
        BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.fact_check_outlined,
            size: 42,
            color: Color(0xFF98A1AC),
          ),
          SizedBox(height: 10),
          Text(
            'No Fishbone causes available',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Return to Fishbone analysis and add at least one potential cause.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF8A9098),
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
              'Could not load Root Cause Validation',
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
  // CHIP
  // ============================================================

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

  // ============================================================
  // PRIMARY BUTTON STYLE
  // ============================================================

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
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(11),
      ),
    );
  }
}