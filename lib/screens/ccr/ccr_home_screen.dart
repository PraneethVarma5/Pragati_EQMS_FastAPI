import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import '../../services/ccr/ccr_api_client.dart';
import '../../models/ccr/ccr_case.dart';
import '../../services/ccr/ccr_service.dart';
import 'ccr_assignment_screen.dart';
import 'ccr_closure_screen.dart';
import 'ccr_containment_screen.dart';
import 'ccr_corrective_action_screen.dart';
import 'ccr_evidence_screen.dart';
import 'ccr_fishbone_screen.dart';
import 'ccr_report_screen.dart';
import 'ccr_root_cause_validation_screen.dart';
import 'ccr_team_management_screen.dart';
import 'ccr_why_screen.dart';

class CcrHomeScreen extends StatefulWidget {
  const CcrHomeScreen({
    super.key,
  });

  @override
  State<CcrHomeScreen> createState() =>
      _CcrHomeScreenState();
}

class _CcrHomeScreenState
    extends State<CcrHomeScreen> {



  final CcrService _service =
  CcrService();

  bool _loading = true;
  bool _creating = false;

  String? _error;

  List<CcrCase> _ccrs =
  <CcrCase>[];

  // ============================================================
  // ADDITIONAL GRID DATA
  // ============================================================

  /// ccr_id -> customer complaint description
  ///
  /// This comes from ccr_customer_view.what_happened.
  final Map<String, String>
  _complaintDescriptions =
  <String, String>{};

  /// ccr_id -> corrective actions
  ///
  /// One CCR can have multiple corrective-action rows.
  /// They are displayed together inside the same grid cell.
  final Map<String, List<Map<String, dynamic>>>
  _actionsByCcr =
  <String, List<Map<String, dynamic>>>{};

  /// ccr_id -> active attachments
  final Map<String, List<Map<String, dynamic>>>
  _attachmentsByCcr =
  <String, List<Map<String, dynamic>>>{};
  /// Tracks which complaints have had their attachment metadata loaded.
  /// An empty list is also cached, so we don't repeatedly request it.
  final Set<String> _attachmentsLoadedFor = <String>{};

  /// Tracks attachment requests currently in progress.
  final Set<String> _attachmentsLoadingFor = <String>{};

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadCcrs();
  }

  // ============================================================
  // LOAD ALL CCR DATA
  // ============================================================

  // ============================================================
  // LOAD ALL CCR DATA
  // ============================================================

  Future<void> _loadCcrs() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dynamic response =
      await CcrApiClient.get('/dashboard');

      if (response is! Map) {
        throw Exception('Invalid CCR dashboard response.');
      }

      final Map<String, dynamic> dashboard =
      Map<String, dynamic>.from(response);

      final dynamic rawCases = dashboard['cases'];
      final dynamic rawActions = dashboard['corrective_actions'];

      if (rawCases is! List) {
        throw Exception('Dashboard response does not contain a valid cases list.');
      }

      if (rawActions is! List) {
        throw Exception('Dashboard response does not contain a valid corrective actions list.');
      }

      final List<CcrCase> records = rawCases
          .whereType<Map>()
          .map(
            (row) => CcrCase.fromMap(
          Map<String, dynamic>.from(row),
        ),
      )
          .toList();

      final Map<String, String> complaintDescriptions = {};
      final Map<String, List<Map<String, dynamic>>> actionsByCcr = {};

      for (final CcrCase ccr in records) {
        final String description = _value(ccr.complaintDescription);

        if (description.isNotEmpty) {
          complaintDescriptions[ccr.id] = description;
        }
      }

      for (final dynamic raw in rawActions) {
        if (raw is! Map) continue;

        final Map<String, dynamic> row =
        Map<String, dynamic>.from(raw);

        final String ccrId = _value(row['ccr_id']);

        if (ccrId.isEmpty) continue;

        actionsByCcr.putIfAbsent(
          ccrId,
              () => <Map<String, dynamic>>[],
        ).add(row);
      }

      if (!mounted) return;

      setState(() {
        _ccrs = records;

        _complaintDescriptions
          ..clear()
          ..addAll(complaintDescriptions);

        _actionsByCcr
          ..clear()
          ..addAll(actionsByCcr);

        // Do not carry attachment metadata across dashboard refreshes.
        _attachmentsByCcr.clear();
        _attachmentsLoadedFor.clear();
        _attachmentsLoadingFor.clear();

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _cleanError(e);
      });
    }
  }
  // ============================================================
  // CREATE NEW CCR
  // ============================================================

  Future<void> _createNewCcr() async {
    if (_creating) {
      return;
    }

    setState(() {
      _creating = true;
    });

    try {
      final CcrCase ccr =
      await _service.createCcr();

      if (!mounted) {
        return;
      }

      await Navigator.pushNamed(
        context,
        '/CCR/registration',
        arguments: ccr.id,
      );

      if (!mounted) {
        return;
      }

      await _loadCcrs();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        _cleanError(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _creating = false;
        });
      }
    }
  }

  // ============================================================
  // TEAM MANAGEMENT
  // ============================================================

  Future<void> _openTeamManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const CcrTeamManagementScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadCcrs();
  }

  // ============================================================
  // OPEN CURRENT WORKFLOW STAGE
  // ============================================================

  Future<void> _openCcr(
      CcrCase ccr,
      ) async {
    final String stageKey =
        ccr.currentStageKey
            ?.trim()
            .toLowerCase() ??
            '';

    if (stageKey.isEmpty) {
      _showError(
        'The current CCR workflow stage is not available.',
      );
      return;
    }

    // ----------------------------------------------------------
    // REGISTRATION
    // ----------------------------------------------------------

    if (stageKey == 'registration') {
      await Navigator.pushNamed(
        context,
        '/CCR/registration',
        arguments: ccr.id,
      );

      if (!mounted) {
        return;
      }

      await _loadCcrs();
      return;
    }

    // ----------------------------------------------------------
    // CONTAINMENT
    // ----------------------------------------------------------

    if (stageKey == 'containment') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CcrContainmentScreen(
                ccrId: ccr.id,
              ),
        ),
      );

      if (!mounted) {
        return;
      }

      await _loadCcrs();
      return;
    }

    // ----------------------------------------------------------
    // ASSIGNMENT
    // ----------------------------------------------------------

    if (stageKey == 'assignment') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CcrAssignmentScreen(
                ccrId: ccr.id,
              ),
        ),
      );

      if (!mounted) {
        return;
      }

      await _loadCcrs();
      return;
    }

    // ----------------------------------------------------------
    // FISHBONE
    // ----------------------------------------------------------

    if (stageKey == 'fishbone') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CcrFishboneScreen(
                ccrId: ccr.id,
              ),
        ),
      );

      if (!mounted) {
        return;
      }

      await _loadCcrs();
      return;
    }

    // ----------------------------------------------------------
    // ROOT CAUSE VALIDATION
    // ----------------------------------------------------------

    if (stageKey ==
        'root_cause_validation') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CcrRootCauseValidationScreen(
                ccrId: ccr.id,
              ),
        ),
      );

      if (!mounted) {
        return;
      }

      await _loadCcrs();
      return;
    }

    // ----------------------------------------------------------
    // 5 WHY
    // ----------------------------------------------------------

    if (stageKey == 'five_why' ||
        stageKey == '5_why' ||
        stageKey == 'why_analysis') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CcrWhyScreen(
                ccrId: ccr.id,
              ),
        ),
      );

      if (!mounted) {
        return;
      }

      await _loadCcrs();
      return;
    }

    // ----------------------------------------------------------
    // CORRECTIVE ACTION
    // ----------------------------------------------------------

    if (stageKey ==
        'corrective_action') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CcrCorrectiveActionScreen(
                ccrId: ccr.id,
              ),
        ),
      );

      if (!mounted) {
        return;
      }

      await _loadCcrs();
      return;
    }

    // ----------------------------------------------------------
    // EVIDENCE
    // ----------------------------------------------------------

    if (stageKey == 'evidence') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CcrEvidenceScreen(
                ccrId: ccr.id,
              ),
        ),
      );

      if (!mounted) {
        return;
      }

      await _loadCcrs();
      return;
    }

    // ----------------------------------------------------------
    // CLOSURE
    // ----------------------------------------------------------

    if (stageKey == 'closure') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CcrClosureScreen(
                ccrId: ccr.id,
              ),
        ),
      );

      if (!mounted) {
        return;
      }

      await _loadCcrs();
      return;
    }

    _showError(
      'The current CCR stage "$stageKey" is not connected to a screen yet.',
    );
  }

  // ============================================================
  // VIEW REPORT
  // ============================================================

  Future<void> _viewReport(
      CcrCase ccr,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CcrReportScreen(
              ccrId: ccr.id,
            ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadCcrs();
  }

  // ============================================================
  // VIEW ATTACHMENTS
  // ============================================================

  Future<void> _viewAttachments(CcrCase ccr) async {
    final String ccrId = ccr.id;

    if (_attachmentsLoadingFor.contains(ccrId)) {
      return;
    }

    if (!_attachmentsLoadedFor.contains(ccrId)) {
      setState(() {
        _attachmentsLoadingFor.add(ccrId);
      });

      try {
        final dynamic response =
        await CcrApiClient.get('/cases/$ccrId/attachments');

        final List<dynamic> rows;

        if (response is List) {
          rows = response;
        } else if (response is Map && response['items'] is List) {
          rows = response['items'] as List;
        } else if (response is Map && response['data'] is List) {
          rows = response['data'] as List;
        } else {
          throw Exception('Invalid attachment response.');
        }

        final List<Map<String, dynamic>> attachments = rows
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();

        if (!mounted) return;

        setState(() {
          _attachmentsByCcr[ccrId] = attachments;
          _attachmentsLoadedFor.add(ccrId);
          _attachmentsLoadingFor.remove(ccrId);
        });
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _attachmentsLoadingFor.remove(ccrId);
        });

        _showError(_cleanError(e));
        return;
      }
    }

    if (!mounted) return;

    final List<Map<String, dynamic>> attachments =
        _attachmentsByCcr[ccrId] ?? <Map<String, dynamic>>[];

    if (attachments.isEmpty) {
      _showMessage('No attachments are available for ${ccr.displayNumber}.');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.attach_file_outlined,
                color: Color(0xFF3155C6),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('${ccr.displayNumber} Attachments'),
              ),
            ],
          ),
          content: SizedBox(
            width: 650,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: attachments.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final Map<String, dynamic> attachment = attachments[index];

                final String fileName = _attachmentFileName(attachment);

                final String type = _displayAttachmentType(
                  attachment['attachment_type'],
                );

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF3FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.insert_drive_file_outlined,
                      color: Color(0xFF3155C6),
                    ),
                  ),
                  title: Text(
                    fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '$type • ${_fileSizeText(attachment['file_size'])}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7A818C),
                      ),
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: 'Download',
                    onPressed: () => _downloadAttachment(attachment),
                    icon: const Icon(
                      Icons.download_outlined,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  // ============================================================
  // DOWNLOAD ATTACHMENT
  // ============================================================

  Future<void> _downloadAttachment(
      Map<String, dynamic> attachment,
      ) async {
    final String attachmentId = _value(attachment['id']);

    if (attachmentId.isEmpty) {
      _showError('Attachment ID is missing.');
      return;
    }

    try {
      final bytes = await CcrApiClient.downloadFileBytes(
        '/attachments/$attachmentId/file',
      );

      final String fileName = _attachmentFileName(attachment);
      final String extension = _fileExtension(fileName);

      final String mimeType =
      _value(attachment['mime_type']).isNotEmpty
          ? _value(attachment['mime_type'])
          : 'application/octet-stream';

      await FileSaver.instance.saveFile(
        name: _removeFileExtension(fileName),
        bytes: bytes,
        fileExtension: extension,
        mimeType: MimeType.other,
        customMimeType: mimeType,
      );

      if (!mounted) return;

      _showMessage('Attachment downloaded successfully.');
    } catch (e) {
      if (!mounted) return;

      _showError(_cleanError(e));
    }
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
        const Color(0xFF1F2937),
        title: const Text(
          'Customer Complaint Registration',
          style: TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),
        actions: [
          // ----------------------------------------------------------
          // ADMIN / USER LOGIN
          // ----------------------------------------------------------

          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/CCR/login',
              );
            },
            icon: const Icon(
              Icons.login_outlined,
              size: 18,
            ),
            label: const Text(
              'Login',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor:
              const Color(0xFF3155C6),
              side: const BorderSide(
                color: Color(0xFF3155C6),
              ),
              padding:
              const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          // ----------------------------------------------------------
          // REFRESH
          // ----------------------------------------------------------

          IconButton(
            tooltip: 'Refresh',
            onPressed:
            _loading
                ? null
                : _loadCcrs,
            icon: const Icon(
              Icons.refresh,
            ),
          ),

          const SizedBox(
            width: 8,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 1600,
            ),
            child: Padding(
              padding:
              const EdgeInsets.all(
                24,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  _buildHeader(),
                  const SizedBox(
                    height: 20,
                  ),
                  Expanded(
                    child:
                    _buildContent(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (
          BuildContext context,
          BoxConstraints constraints,
          ) {
        final bool compact =
            constraints.maxWidth < 700;


        final Widget newComplaintButton =
        FilledButton.icon(
          onPressed: _creating
              ? null
              : _createNewCcr,
          icon: _creating
              ? const SizedBox(
            width: 17,
            height: 17,
            child:
            CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
              : const Icon(
            Icons.add,
          ),
          label:
          const Text(
            'New Complaint',
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              _headerText(),
              const SizedBox(
                height: 14,
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [

                  newComplaintButton,
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment:
          CrossAxisAlignment
              .center,
          children: [
            Expanded(
              child:
              _headerText(),
            ),
            const SizedBox(
              width: 16,
            ),

            const SizedBox(
              width: 10,
            ),
            newComplaintButton,
          ],
        );
      },
    );
  }

  Widget _headerText() {
    return const Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Complaints',
          style: TextStyle(
            fontSize: 24,
            fontWeight:
            FontWeight.w800,
            color:
            Color(0xFF111827),
          ),
        ),
        SizedBox(
          height: 5,
        ),
        Text(
          'All customer complaints in a single row-based grid.',
          style: TextStyle(
            fontSize: 14,
            color:
            Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_ccrs.isEmpty) {
      return _buildEmptyState();
    }

    return _buildCcrGrid();
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          side:
          const BorderSide(
            color:
            Color(0xFFE5E7EB),
          ),
        ),
        child: Padding(
          padding:
          const EdgeInsets.all(
            32,
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 42,
                color:
                Colors.redAccent,
              ),
              const SizedBox(
                height: 12,
              ),
              const Text(
                'Unable to load complaints',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              ConstrainedBox(
                constraints:
                const BoxConstraints(
                  maxWidth: 650,
                ),
                child: Text(
                  _error ?? '',
                  textAlign:
                  TextAlign.center,
                  style:
                  const TextStyle(
                    color:
                    Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              OutlinedButton.icon(
                onPressed:
                _loadCcrs,
                icon:
                const Icon(
                  Icons.refresh,
                ),
                label:
                const Text(
                  'Retry',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        side:
        const BorderSide(
          color:
          Color(0xFFE5E7EB),
        ),
      ),
      child: Center(
        child: Padding(
          padding:
          const EdgeInsets.all(
            50,
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              Icon(
                Icons
                    .assignment_outlined,
                size: 52,
                color:
                Colors.blueGrey
                    .shade300,
              ),
              const SizedBox(
                height: 14,
              ),
              const Text(
                'No customer complaints found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  Color(0xFF1F2937),
                ),
              ),
              const SizedBox(
                height: 7,
              ),
              const Text(
                'Create the first complaint to begin the CCR workflow.',
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  color:
                  Color(0xFF6B7280),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              FilledButton.icon(
                onPressed:
                _creating
                    ? null
                    : _createNewCcr,
                icon:
                const Icon(
                  Icons.add,
                ),
                label:
                const Text(
                  'Create Complaint',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MAIN GRID
  // ============================================================


  // ============================================================
  // MAIN GRID - VERTICAL SCROLL ONLY
  // ============================================================

  Widget _buildCcrGrid() {
    return Card(
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'CCR Register',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF3FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_ccrs.length} CCR',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3155C6),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _ccrs.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  return _buildCcrCard(_ccrs[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INDIVIDUAL CCR CARD
  // ============================================================

  Widget _buildCcrCard(CcrCase ccr) {
    final actions =
        _actionsByCcr[ccr.id] ?? <Map<String, dynamic>>[];

    final complaintDescription =
        _complaintDescriptions[ccr.id] ?? '';

    final occurrenceCauses = _rootCauses(
      actions,
      occurrence: true,
    );

    final detectionCauses = _rootCauses(
      actions,
      occurrence: false,
    );

    final actionPlans = actions
        .map((action) => _value(action['corrective_action']))
        .where((value) => value.isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFD8DEE9),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // CCR HEADER
            // --------------------------------------------------

            Row(
              children: [
                Expanded(
                  child: Text(
                    ccr.displayNumber,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF253047),
                    ),
                  ),
                ),
                const Text(
                  'STATUS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 10),
                _statusCell(ccr),
              ],
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // PRIMARY INFORMATION
            // --------------------------------------------------

            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth >= 700
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _registerInfo(
                        'Customer',
                        _displayValue(ccr.customerName),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _registerInfo(
                        'Customer Location',
                        _displayValue(ccr.customerLocation),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _registerInfo(
                        'Part Description',
                        _displayValue(ccr.partDescription),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _registerInfo(
                        'Part No',
                        _displayValue(ccr.partNo),
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth,
                      child: _registerInfo(
                        'Complaint Description',
                        _displayValue(ccr.complaintDescription),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _registerInfo(
                        'Quantity',
                        _displayValue(ccr.qty),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // --------------------------------------------------
// ROOT CAUSE & CORRECTIVE ACTIONS
// --------------------------------------------------

            const Text(
              'Root Cause & Corrective Actions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF253047),
              ),
            ),

            const SizedBox(height: 14),

            LayoutBuilder(
              builder: (context, constraints) {
                final double spacing = 12;

                final int columns =
                constraints.maxWidth >= 900
                    ? 3
                    : constraints.maxWidth >= 600
                    ? 2
                    : 1;

                final double itemWidth =
                    (constraints.maxWidth -
                        (spacing * (columns - 1))) /
                        columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _registerDetail(
                        'Root Cause Occurrence',
                        _multiValueCell(
                          occurrenceCauses,
                          width: double.infinity,
                        ),
                      ),
                    ),

                    SizedBox(
                      width: itemWidth,
                      child: _registerDetail(
                        'Root Cause Detection',
                        _multiValueCell(
                          detectionCauses,
                          width: double.infinity,
                        ),
                      ),
                    ),

                    SizedBox(
                      width: itemWidth,
                      child: _registerDetail(
                        'Action Plan',
                        _multiValueCell(
                          actionPlans,
                          width: double.infinity,
                          numbered: true,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // --------------------------------------------------
            // ACTION BUTTONS
            // --------------------------------------------------

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _viewReport(ccr),
                  icon: const Icon(
                    Icons.description_outlined,
                    size: 17,
                  ),
                  label: const Text('View Report'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7655C9),
                    side: const BorderSide(
                      color: Color(0xFF7655C9),
                    ),
                  ),
                ),

                OutlinedButton.icon(
                  onPressed: _attachmentsLoadingFor.contains(ccr.id)
                      ? null
                      : () => _viewAttachments(ccr),
                  icon: _attachmentsLoadingFor.contains(ccr.id)
                      ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(
                    Icons.attach_file_outlined,
                    size: 17,
                  ),
                  label: Text(
                    _attachmentsLoadingFor.contains(ccr.id)
                        ? 'Loading...'
                        : 'View Attachments',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3155C6),
                    side: const BorderSide(
                      color: Color(0xFF3155C6),
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openCcr(ccr),
                  icon: const Icon(
                    Icons.open_in_new_outlined,
                    size: 17,
                  ),
                  label: const Text('Open CCR'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3155C6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // REGISTER INFORMATION FIELD
  // ============================================================

  Widget _registerInfo(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFEEF0F4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REGISTER DETAIL SECTION
  // ============================================================

  Widget _registerDetail(String label, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE1E5ED),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: child,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ROOT CAUSES
  // ============================================================

  List<String> _rootCauses(
      List<Map<String, dynamic>>
      actions, {
        required bool occurrence,
      }) {
    final List<String> values =
    <String>[];

    for (final Map<String, dynamic>
    action in actions) {
      final String value =
      _value(
        occurrence
            ? action[
        'occurrence_root_cause']
            : action[
        'detection_root_cause'],
      );

      if (value.isEmpty) {
        continue;
      }

      if (!values.contains(value)) {
        values.add(value);
      }
    }

    return values;
  }

  // ============================================================
  // BASIC CELL
  // ============================================================

  Widget _cell(
      String value, {
        required double width,
        bool bold = false,
      }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          vertical: 7,
        ),
        child: Text(
          value.isEmpty
              ? '-'
              : value,
          maxLines: 6,
          overflow:
          TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: bold
                ? FontWeight.w800
                : FontWeight.w500,
            color:
            const Color(
              0xFF374151,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MULTI-VALUE CELL
  // ============================================================

  Widget _multiValueCell(
      List<String> values, {
        required double width,
        bool numbered = false,
      }) {
    if (values.isEmpty) {
      return SizedBox(
        width: width,
        child: const Text(
          '-',
          style: TextStyle(
            fontSize: 12,
            color:
            Color(0xFF9CA3AF),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          vertical: 7,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          mainAxisSize:
          MainAxisSize.min,
          children: List<
              Widget>.generate(
            values.length,
                (
                int index,
                ) {
              final String prefix =
              numbered
                  ? '${index + 1}. '
                  : '• ';

              return Padding(
                padding:
                const EdgeInsets.only(
                  bottom: 4,
                ),
                child: Text(
                  '$prefix${values[index]}',
                  maxLines: 4,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 11.5,
                    color:
                    Color(0xFF374151),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS CELL
  // ============================================================

  Widget _statusCell(
      CcrCase ccr,
      ) {
    final String status =
    (ccr.statusName ??
        ccr.statusKey ??
        'Status unavailable')
        .trim();

    final String normalized =
    status.toLowerCase();

    Color background =
    const Color(0xFFF3F4F6);

    Color foreground =
    const Color(0xFF374151);

    if (normalized == 'closed') {
      background =
      const Color(0xFFEAF7EF);

      foreground =
      const Color(0xFF238B4E);
    } else if (normalized ==
        'draft') {
      background =
      const Color(0xFFFFF3E0);

      foreground =
      const Color(0xFFD97706);
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration:
      BoxDecoration(
        color: background,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        status.isEmpty
            ? '-'
            : status,
        maxLines: 2,
        overflow:
        TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight:
          FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }

  // ============================================================
  // ATTACHMENT HELPERS
  // ============================================================

  String _attachmentFileName(
      Map<String, dynamic>
      attachment,
      ) {
    final String original =
        attachment[
        'original_file_name']
            ?.toString()
            .trim() ??
            '';

    if (original.isNotEmpty) {
      return original;
    }

    final String title =
        attachment['title']
            ?.toString()
            .trim() ??
            '';

    if (title.isNotEmpty) {
      return title;
    }

    return 'Attachment';
  }

  String _displayAttachmentType(
      dynamic value,
      ) {
    final String raw =
        value?.toString().trim() ??
            '';

    if (raw.isEmpty) {
      return 'Attachment';
    }

    return raw
        .replaceAll(
      '_',
      ' ',
    )
        .split(' ')
        .map(
          (
          String word,
          ) {
        if (word.isEmpty) {
          return word;
        }

        return word[0]
            .toUpperCase() +
            word.substring(1);
      },
    )
        .join(' ');
  }

  String _fileSizeText(
      dynamic value,
      ) {
    if (value == null) {
      return 'Size unavailable';
    }

    final int bytes =
        int.tryParse(
          value.toString(),
        ) ??
            0;

    if (bytes <= 0) {
      return 'Size unavailable';
    }

    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes <
        1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    if (bytes <
        1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _fileExtension(
      String fileName,
      ) {
    final int dotIndex =
    fileName.lastIndexOf('.');

    if (dotIndex < 0 ||
        dotIndex ==
            fileName.length - 1) {
      return 'bin';
    }

    return fileName
        .substring(dotIndex + 1)
        .toLowerCase();
  }

  String _removeFileExtension(
      String fileName,
      ) {
    final int dotIndex =
    fileName.lastIndexOf('.');

    if (dotIndex <= 0) {
      return fileName;
    }

    return fileName.substring(
      0,
      dotIndex,
    );
  }

  // ============================================================
  // VALUE HELPERS
  // ============================================================

  String _value(
      dynamic value,
      ) {
    return value
        ?.toString()
        .trim() ??
        '';
  }

  String _displayValue(
      dynamic value,
      ) {
    final String result =
    _value(value);

    return result.isEmpty
        ? '-'
        : result;
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _cleanError(
      dynamic error,
      ) {
    return error
        .toString()
        .replaceFirst(
      'Exception: ',
      '',
    )
        .replaceFirst(
      'PostgrestException: ',
      '',
    );
  }

  void _showError(
      String message,
      ) {
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
        const Color(
          0xFFC62828,
        ),
      ),
    );
  }

  void _showMessage(
      String message,
      ) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
        Text(message),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }
}