import 'package:flutter/material.dart';

import '../../services/audit_pdf_service.dart';
import '../../services/supabase_service.dart';

class AuditDashboardScreen extends StatefulWidget {
  const AuditDashboardScreen({super.key});

  @override
  State<AuditDashboardScreen> createState() =>
      _AuditDashboardScreenState();
}

class _AuditDashboardScreenState
    extends State<AuditDashboardScreen> {
  // ============================================================
  // STATE
  // ============================================================

  List<Map<String, dynamic>> _audits = [];
  List<Map<String, dynamic>> _filteredAudits = [];

  final TextEditingController _searchController =
  TextEditingController();

  String _statusFilter = 'All';

  bool _loading = true;
  bool _downloadingAuditList = false;

  // DCC-style compact sidebar width.
  static const double _sidebarWidth = 220;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_applyFilters);

    _loadDashboard();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD DASHBOARD
  // ============================================================

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final audits =
      await SupabaseService.getAllAudits().timeout(
        const Duration(seconds: 20),
      );

      // Dashboard loading is read-only. MIL-number repair is an
      // explicit Audit Admin maintenance operation, never an automatic
      // side-effect of opening the dashboard.
      if (!mounted) return;

      setState(() {
        _audits = audits.map((row) => Map<String, dynamic>.from(row)).toList();
        _loading = false;
      });

      _applyFilters();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showError(
        'Unable to load Audit Dashboard: $e',
      );
    }
  }

  // ============================================================
  // FILTERS
  // ============================================================

  void _applyFilters() {
    final search =
    _searchController.text
        .trim()
        .toLowerCase();

    final filtered =
    _audits.where((audit) {
      final status =
          audit['status']
              ?.toString() ??
              '';

      if (_statusFilter != 'All' &&
          status != _statusFilter) {
        return false;
      }

      if (search.isEmpty) {
        return true;
      }

      final auditType =
          audit['audit_type']
              ?.toString() ??
              '';

      final milNumber =
          audit['mil_number']
              ?.toString() ??
              '';

      final vendor =
          audit['vendor']
              ?.toString() ??
              '';

      final site =
          audit['site']
              ?.toString() ??
              '';

      final lob =
          audit['lob']
              ?.toString() ??
              '';

      final program =
          audit['program']
              ?.toString() ??
              '';

      final auditor =
          audit['auditor_name']
              ?.toString() ??
              '';

      final searchable =
      '$auditType '
          '$milNumber '
          '$vendor '
          '$site '
          '$lob '
          '$program '
          '$auditor'
          .toLowerCase();

      return searchable.contains(search);
    }).toList();

    if (!mounted) return;

    setState(() {
      _filteredAudits = filtered;
    });
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  int get _totalAudits =>
      _audits.length;

  int get _draftAudits =>
      _audits.where(
            (audit) =>
        audit['status']
            ?.toString() ==
            'Draft',
      ).length;

  int get _inProgressAudits =>
      _audits.where(
            (audit) =>
        audit['status']
            ?.toString() ==
            'In Progress',
      ).length;

  int get _submittedAudits =>
      _audits.where(
            (audit) =>
        audit['status']
            ?.toString() ==
            'Submitted',
      ).length;

  int get _completedAudits =>
      _audits.where(
            (audit) =>
        audit['status']
            ?.toString() ==
            'Completed',
      ).length;

  int get _openMilAudits =>
      _audits.where(
            (audit) =>
        audit['mil_status']
            ?.toString() ==
            'Open',
      ).length;

  // ============================================================
  // NAVIGATION
  // ============================================================

  Future<void> _startNewAudit() async {
    await Navigator.pushNamed(
      context,
      '/AUDIT/start',
    );

    if (!mounted) return;

    await _loadDashboard();
  }

  Future<void> _continueAudit(
      Map<String, dynamic> audit,
      ) async {
    final auditId =
    audit['audit_id']
        ?.toString()
        .trim();

    if (auditId == null ||
        auditId.isEmpty) {
      _showError(
        'Invalid Audit ID.',
      );
      return;
    }

    await Navigator.pushNamed(
      context,
      '/AUDIT/categories',
      arguments: auditId,
    );

    if (!mounted) return;

    await _loadDashboard();
  }

  Future<void> _openMilReport(
      Map<String, dynamic> audit,
      ) async {
    final auditId =
    audit['audit_id']
        ?.toString()
        .trim();

    if (auditId == null ||
        auditId.isEmpty) {
      _showError(
        'Invalid Audit ID.',
      );
      return;
    }

    await Navigator.pushNamed(
      context,
      '/AUDIT/mil',
      arguments: auditId,
    );

    if (!mounted) return;

    await _loadDashboard();
  }

  Future<void> _openAuditReport(
      Map<String, dynamic> audit,
      ) async {
    final auditId =
    audit['audit_id']
        ?.toString()
        .trim();

    if (auditId == null ||
        auditId.isEmpty) {
      _showError(
        'Invalid Audit ID.',
      );
      return;
    }

    await Navigator.pushNamed(
      context,
      '/AUDIT/report',
      arguments: auditId,
    );

    if (!mounted) return;

    await _loadDashboard();
  }

  // ============================================================
  // DOWNLOAD AUDIT LIST
  // ============================================================

  Future<void> _downloadAuditList() async {
    if (_downloadingAuditList) {
      return;
    }

    if (_audits.isEmpty) {
      _showError(
        'There are no audits to download.',
      );
      return;
    }

    setState(() {
      _downloadingAuditList = true;
    });

    try {
      await AuditPdfService
          .downloadAuditList();

      if (!mounted) return;

      _showMessage(
        'Audit List downloaded successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Unable to download Audit List: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloadingAuditList =
          false;
        });
      }
    }
  }

  // ============================================================
  // DOWNLOAD AUDIT REPORT
  // ============================================================

  Future<void> _downloadAuditReport(
      Map<String, dynamic> audit,
      ) async {
    final auditId =
    audit['audit_id']
        ?.toString()
        .trim();

    if (auditId == null ||
        auditId.isEmpty) {
      _showError(
        'Invalid Audit ID.',
      );
      return;
    }

    try {
      await AuditPdfService
          .downloadAuditReport(
        auditId,
      );

      if (!mounted) return;

      _showMessage(
        'Audit Report downloaded successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Unable to download Audit Report: $e',
      );
    }
  }

  // ============================================================
  // DOWNLOAD MIL REPORT
  // ============================================================

  Future<void> _downloadMilReport(
      Map<String, dynamic> audit,
      ) async {
    final auditId =
    audit['audit_id']
        ?.toString()
        .trim();

    if (auditId == null ||
        auditId.isEmpty) {
      _showError(
        'Invalid Audit ID.',
      );
      return;
    }

    try {
      await AuditPdfService
          .downloadMilReport(
        auditId,
      );

      if (!mounted) return;

      _showMessage(
        'MIL Report downloaded successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Unable to download MIL Report: $e',
      );
    }
  }

  // ============================================================
  // SIDEBAR
  // ============================================================

  void _openAdminLogin() {
    Navigator.pushNamed(
      context,
      '/AUDIT/admin/login',
    );
  }
  void _openAuditSchedule() {
    Navigator.pushNamed(
      context,
      '/AUDIT/admin/login',
      arguments: {
        'redirectTo':
        '/AUDIT/admin/schedule',
      },
    );
  }
  void _openAuditMasterDataManagement() {
    Navigator.pushNamed(
      context,
      '/AUDIT/admin/login',
      arguments: {
        'redirectTo':
        '/AUDIT/admin/master-data',
      },
    );
  }
  void _openAuditorManagement() {
    Navigator.pushNamed(
      context,
      '/AUDIT/admin/login',
      arguments: {
        'redirectTo':
        '/AUDIT/admin/auditors',
      },
    );
  }
  void _openAuditRecordsManagement() {
    Navigator.pushNamed(
      context,
      '/AUDIT/admin/login',
      arguments: {
        'redirectTo':
        '/AUDIT/admin/records',
      },
    );
  }

  Widget _buildSidebar() {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return SizedBox(
      width: _sidebarWidth,
      child: Material(
        color: colorScheme.surface,
        child: SafeArea(
          right: false,
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [
              // ------------------------------------------------
              // SIDEBAR HEADER
              // ------------------------------------------------

              SizedBox(
                height: 82,
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration:
                        BoxDecoration(
                          color: colorScheme
                              .primaryContainer,
                          borderRadius:
                          BorderRadius
                              .circular(
                            10,
                          ),
                        ),
                        child: Icon(
                          Icons
                              .fact_check_outlined,
                          size: 21,
                          color: colorScheme
                              .onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(
                        width: 11,
                      ),
                      Expanded(
                        child: Text(
                          'Audit',
                          style:
                          Theme.of(
                            context,
                          )
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                            fontWeight:
                            FontWeight
                                .w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Divider(
                height: 1,
                color:
                Colors.grey.shade300,
              ),

              // ------------------------------------------------
              // SIDEBAR SECTION LABEL
              // ------------------------------------------------

              Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  18,
                  22,
                  18,
                  8,
                ),
                child: Text(
                  'ADMINISTRATION',
                  style:
                  Theme.of(
                    context,
                  )
                      .textTheme
                      .labelSmall
                      ?.copyWith(
                    color: Colors
                        .grey
                        .shade600,
                    fontWeight:
                    FontWeight
                        .w700,
                    letterSpacing:
                    0.7,
                  ),
                ),
              ),

              // ------------------------------------------------
              // AUDIT TYPE MANAGEMENT
              // ------------------------------------------------

              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius:
                    BorderRadius
                        .circular(
                      8,
                    ),
                    onTap:
                    _openAdminLogin,
                    child: Padding(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .settings_outlined,
                            size: 21,
                            color:
                            Colors
                                .grey
                                .shade700,
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child:
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  'Audit Type',
                                  style:
                                  Theme.of(
                                    context,
                                  )
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                    fontWeight:
                                    FontWeight
                                        .w600,
                                  ),
                                ),
                                const SizedBox(
                                  height: 2,
                                ),
                                Text(
                                  'Management',
                                  style:
                                  Theme.of(
                                    context,
                                  )
                                      .textTheme
                                      .bodyMedium,
                                ),
                                const SizedBox(
                                  height: 2,
                                ),
                                Text(
                                  'Types, categories & questions',
                                  style:
                                  Theme.of(
                                    context,
                                  )
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                    color: Colors
                                        .grey
                                        .shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons
                                .chevron_right,
                            size: 20,
                            color:
                            Colors
                                .grey
                                .shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
// ------------------------------------------------
// AUDITOR MANAGEMENT
// ------------------------------------------------

              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius:
                    BorderRadius.circular(
                      8,
                    ),
                    onTap:
                    _openAuditorManagement,
                    child: Padding(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .people_outline,
                            size: 21,
                            color:
                            Colors.grey.shade700,
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Auditor Management',
                                  style:
                                  Theme.of(
                                    context,
                                  )
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(
                                  height: 2,
                                ),
                                Text(
                                  'Manage auditors',
                                  style:
                                  Theme.of(
                                    context,
                                  )
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                    color:
                                    Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color:
                            Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius:
                    BorderRadius.circular(8),
                    onTap:
                    _openAuditMasterDataManagement,
                    child: Padding(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .list_alt_outlined,
                            size: 21,
                            color:
                            Colors.grey.shade700,
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Audit Master',
                                  style:
                                  Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(
                                  height: 2,
                                ),

                                Text(
                                  'Data',
                                  style:
                                  Theme.of(context)
                                      .textTheme
                                      .bodyMedium,
                                ),

                                const SizedBox(
                                  height: 2,
                                ),

                                Text(
                                  'Independent master list',
                                  style:
                                  Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                    color:
                                    Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color:
                            Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // ------------------------------------------------
// AUDIT SCHEDULE
// ------------------------------------------------

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius:
                    BorderRadius.circular(8),
                    onTap: _openAuditSchedule,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_note_outlined,
                            size: 21,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Audit Schedule',
                                  style:
                                  Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(
                                  height: 2,
                                ),
                                Text(
                                  'Plan and assign audits',
                                  style:
                                  Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                    color:
                                    Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

// ------------------------------------------------
// AUDIT RECORDS MANAGEMENT
// ------------------------------------------------

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius:
                    BorderRadius.circular(8),
                    onTap:
                    _openAuditRecordsManagement,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.manage_history_outlined,
                            size: 21,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Audit Records Management',
                                  style:
                                  Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(
                                  height: 2,
                                ),
                                Text(
                                  'View & permanently delete records',
                                  style:
                                  Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                    color:
                                    Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatDate(
      dynamic value,
      ) {
    if (value == null) {
      return '-';
    }

    final text =
    value.toString();

    if (text.length >= 10) {
      return text.substring(
        0,
        10,
      );
    }

    return text;
  }

  String _formatHours(
      dynamic value,
      ) {
    if (value == null) {
      return '0.00';
    }

    final number =
    value is num
        ? value.toDouble()
        : double.tryParse(
      value.toString(),
    ) ??
        0;

    return number.toStringAsFixed(
      2,
    );
  }

  String _value(
      dynamic value,
      ) {
    if (value == null) {
      return '-';
    }

    final text =
    value.toString().trim();

    if (text.isEmpty) {
      return '-';
    }

    return text;
  }

  Color _statusColor(
      String status,
      ) {
    switch (status) {
      case 'Draft':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Submitted':
        return Colors.deepPurple;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _milStatusColor(
      String status,
      ) {
    switch (status) {
      case 'Open':
        return Colors.orange;
      case 'Closed':
        return Colors.green;
      case 'Not Generated':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _showError(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
        Text(message),
        backgroundColor:
        Colors.red.shade700,
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  void _showMessage(
      String message,
      ) {
    if (!mounted) return;

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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      body: Row(
        children: [
          // ----------------------------------------------------
          // LEFT SIDEBAR
          // ----------------------------------------------------

          _buildSidebar(),

          // ----------------------------------------------------
          // MAIN APPLICATION AREA
          // ----------------------------------------------------

          Expanded(
            child: Scaffold(
              appBar: AppBar(
                elevation: 0,
                surfaceTintColor:
                Colors.transparent,

                leading:
                IconButton(
                  tooltip:
                  'Back',
                  icon:
                  const Icon(
                    Icons
                        .arrow_back,
                  ),
                  onPressed: () {
                    Navigator
                        .maybePop(
                      context,
                    );
                  },
                ),

                title:
                const Text(
                  'Audit Dashboard',
                  style:
                  TextStyle(
                    fontWeight:
                    FontWeight
                        .w700,
                  ),
                ),

                actions: [
                  IconButton(
                    tooltip:
                    'Download Audit List',
                    onPressed:
                    _downloadingAuditList
                        ? null
                        : _downloadAuditList,
                    icon:
                    _downloadingAuditList
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                      CircularProgressIndicator(
                        strokeWidth:
                        2,
                      ),
                    )
                        : const Icon(
                      Icons
                          .download_outlined,
                    ),
                  ),

                  IconButton(
                    tooltip:
                    'Refresh',
                    onPressed:
                    _loading
                        ? null
                        : _loadDashboard,
                    icon:
                    const Icon(
                      Icons
                          .refresh,
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),
                ],
              ),

              body:
              SafeArea(
                child: _loading
                    ? const Center(
                  child:
                  CircularProgressIndicator(),
                )
                    : _buildBody(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh:
      _loadDashboard,
      child:
      SingleChildScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.fromLTRB(
          24,
          18,
          24,
          30,
        ),
        child: Center(
          child:
          ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 1500,
            ),
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .stretch,
              children: [
                _buildPageHeader(),

                const SizedBox(
                  height: 20,
                ),

                _buildStatistics(),

                const SizedBox(
                  height: 20,
                ),

                _buildStartAuditButton(),

                const SizedBox(
                  height: 24,
                ),

                _buildAuditHistory(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          'Audit Management',
          style:
          Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(
            fontWeight:
            FontWeight
                .w800,
          ),
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          'Create, continue, review and manage audits.',
          style:
          Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(
            color: Colors
                .grey
                .shade700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics() {
    return LayoutBuilder(
      builder:
          (
          context,
          constraints,
          ) {
        final width =
            constraints.maxWidth;

        int columns;

        if (width >= 1200) {
          columns = 6;
        } else if (width >= 750) {
          columns = 3;
        } else {
          columns = 2;
        }

        final cardWidth =
            (width -
                ((columns - 1) *
                    12)) /
                columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _statCard(
              width: cardWidth,
              title:
              'Total Audits',
              value:
              _totalAudits,
              icon:
              Icons
                  .fact_check_outlined,
            ),
            _statCard(
              width: cardWidth,
              title:
              'Draft',
              value:
              _draftAudits,
              icon:
              Icons
                  .edit_note_outlined,
            ),
            _statCard(
              width: cardWidth,
              title:
              'In Progress',
              value:
              _inProgressAudits,
              icon:
              Icons
                  .pending_actions_outlined,
            ),
            _statCard(
              width: cardWidth,
              title:
              'Submitted',
              value:
              _submittedAudits,
              icon:
              Icons
                  .send_outlined,
            ),
            _statCard(
              width: cardWidth,
              title:
              'Completed',
              value:
              _completedAudits,
              icon:
              Icons
                  .check_circle_outline,
            ),
            _statCard(
              width: cardWidth,
              title:
              'Open MIL',
              value:
              _openMilAudits,
              icon:
              Icons
                  .assignment_late_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required double width,
    required String title,
    required int value,
    required IconData icon,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        child:
        Padding(
          padding:
          const EdgeInsets.all(
            16,
          ),
          child:
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                BoxDecoration(
                  color: Theme.of(
                    context,
                  )
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius:
                  BorderRadius
                      .circular(
                    10,
                  ),
                ),
                child:
                Icon(
                  icon,
                  size: 21,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child:
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      title,
                      style:
                      Theme.of(
                        context,
                      )
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                        color: Colors
                            .grey
                            .shade700,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      value.toString(),
                      style:
                      const TextStyle(
                        fontSize: 22,
                        fontWeight:
                        FontWeight
                            .w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // START NEW AUDIT
  // ============================================================

  Widget _buildStartAuditButton() {
    return SizedBox(
      height: 54,
      child:
      ElevatedButton.icon(
        onPressed:
        _startNewAudit,
        icon:
        const Icon(
          Icons
              .add_circle_outline,
        ),
        label:
        const Text(
          'Start New Audit',
        ),
      ),
    );
  }

  // ============================================================
  // AUDIT HISTORY
  // ============================================================

  Widget _buildAuditHistory() {
    return Card(
      elevation: 0,
      child:
      Padding(
        padding:
        const EdgeInsets.all(
          18,
        ),
        child:
        Column(
          crossAxisAlignment:
          CrossAxisAlignment
              .stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons
                      .history_outlined,
                  size: 22,
                ),
                const SizedBox(
                  width: 9,
                ),
                Expanded(
                  child:
                  Text(
                    'Audit History',
                    style:
                    Theme.of(
                      context,
                    )
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                      fontWeight:
                      FontWeight
                          .w800,
                    ),
                  ),
                ),
                Text(
                  '${_filteredAudits.length} audit${_filteredAudits.length == 1 ? '' : 's'}',
                  style:
                  Theme.of(
                    context,
                  )
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    color:
                    Colors
                        .grey
                        .shade700,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            _buildFilters(),

            const SizedBox(
              height: 18,
            ),

            _filteredAudits.isEmpty
                ? _buildEmptyHistory()
                : _buildAuditList(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    return LayoutBuilder(
      builder:
          (
          context,
          constraints,
          ) {
        if (constraints.maxWidth <
            700) {
          return Column(
            children: [
              TextField(
                controller:
                _searchController,
                decoration:
                InputDecoration(
                  labelText:
                  'Search audits',
                  hintText:
                  'MIL, Audit Type, Vendor, Site, Auditor...',
                  prefixIcon:
                  const Icon(
                    Icons.search,
                  ),
                  suffixIcon:
                  _searchController
                      .text
                      .isEmpty
                      ? null
                      : IconButton(
                    onPressed: () {
                      _searchController
                          .clear();
                    },
                    icon:
                    const Icon(
                      Icons.clear,
                    ),
                  ),
                  border:
                  const OutlineInputBorder(),
                  isDense:
                  true,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              _buildStatusDropdown(),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child:
              TextField(
                controller:
                _searchController,
                decoration:
                InputDecoration(
                  labelText:
                  'Search audits',
                  hintText:
                  'MIL, Audit Type, Vendor, Site, Auditor...',
                  prefixIcon:
                  const Icon(
                    Icons.search,
                  ),
                  suffixIcon:
                  _searchController
                      .text
                      .isEmpty
                      ? null
                      : IconButton(
                    onPressed: () {
                      _searchController
                          .clear();
                    },
                    icon:
                    const Icon(
                      Icons.clear,
                    ),
                  ),
                  border:
                  const OutlineInputBorder(),
                  isDense:
                  true,
                ),
              ),
            ),
            const SizedBox(
              width: 14,
            ),
            SizedBox(
              width: 190,
              child:
              _buildStatusDropdown(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<
        String>(
      value:
      _statusFilter,
      decoration:
      const InputDecoration(
        labelText:
        'Status',
        border:
        OutlineInputBorder(),
        isDense:
        true,
      ),
      items: const [
        DropdownMenuItem(
          value: 'All',
          child:
          Text('All'),
        ),
        DropdownMenuItem(
          value: 'Draft',
          child:
          Text('Draft'),
        ),
        DropdownMenuItem(
          value: 'In Progress',
          child:
          Text('In Progress'),
        ),
        DropdownMenuItem(
          value: 'Submitted',
          child:
          Text('Submitted'),
        ),
        DropdownMenuItem(
          value: 'Completed',
          child:
          Text('Completed'),
        ),
      ],
      onChanged:
          (value) {
        if (value ==
            null) {
          return;
        }

        setState(() {
          _statusFilter =
              value;
        });

        _applyFilters();
      },
    );
  }

  // ============================================================
  // AUDIT LIST
  // ============================================================

  Widget _buildAuditList() {
    return Column(
      children:
      List.generate(
        _filteredAudits.length,
            (index) {
          return _buildAuditCard(
            _filteredAudits[
            index],
          );
        },
      ),
    );
  }

  // ============================================================
  // AUDIT CARD
  // ============================================================

  Widget _buildAuditCard(
      Map<String, dynamic> audit,
      ) {
    final auditType =
    _value(
      audit['audit_type'],
    );

    final milNumber =
    _value(
      audit['mil_number'],
    );

    final auditDate =
    _formatDate(
      audit['audit_date'],
    );

    final vendor =
    _value(
      audit['vendor'],
    );

    final site =
    _value(
      audit['site'],
    );

    final lob =
    _value(
      audit['lob'],
    );

    final auditor =
    _value(
      audit['auditor_name'],
    );

    final auditHours =
    _formatHours(
      audit['total_audit_hours'],
    );

    final status =
    _value(
      audit['status'],
    );

    final milStatus =
    _value(
      audit['mil_status'],
    );

    final statusColor =
    _statusColor(
      status,
    );

    final isActive =
        status == 'Draft' ||
            status ==
                'In Progress';

    return Card(
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 0,
      child:
      Padding(
        padding:
        const EdgeInsets.all(
          18,
        ),
        child:
        Column(
          crossAxisAlignment:
          CrossAxisAlignment
              .stretch,
          children: [
            // --------------------------------------------------
            // HEADER
            // --------------------------------------------------

            Row(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Expanded(
                  child:
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        auditType,
                        style:
                        Theme.of(
                          context,
                        )
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight:
                          FontWeight
                              .w800,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons
                                .confirmation_number_outlined,
                            size: 15,
                            color: Colors
                                .grey
                                .shade700,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            'MIL: $milNumber',
                            style:
                            TextStyle(
                              fontSize: 13,
                              fontWeight:
                              FontWeight
                                  .w700,
                              color: Colors
                                  .grey
                                  .shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration:
                  BoxDecoration(
                    borderRadius:
                    BorderRadius.circular(
                      18,
                    ),
                    border:
                    Border.all(
                      color:
                      statusColor,
                    ),
                  ),
                  child:
                  Text(
                    status,
                    style:
                    TextStyle(
                      color:
                      statusColor,
                      fontSize: 12,
                      fontWeight:
                      FontWeight
                          .w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 17,
            ),

            // --------------------------------------------------
            // DETAILS
            // --------------------------------------------------

            LayoutBuilder(
              builder:
                  (
                  context,
                  constraints,
                  ) {
                final columns =
                constraints.maxWidth >=
                    950
                    ? 4
                    : constraints
                    .maxWidth >=
                    600
                    ? 2
                    : 1;

                final width =
                columns ==
                    1
                    ? constraints
                    .maxWidth
                    : (constraints
                    .maxWidth -
                    ((columns -
                        1) *
                        18)) /
                    columns;

                return Wrap(
                  spacing: 18,
                  runSpacing: 15,
                  children: [
                    _detailItem(
                      width: width,
                      icon: Icons
                          .calendar_today_outlined,
                      label:
                      'Audit Date',
                      value:
                      auditDate,
                    ),
                    _detailItem(
                      width: width,
                      icon: Icons
                          .business_outlined,
                      label:
                      'Vendor',
                      value:
                      vendor,
                    ),
                    _detailItem(
                      width: width,
                      icon: Icons
                          .location_on_outlined,
                      label:
                      'Site',
                      value:
                      site,
                    ),
                    _detailItem(
                      width: width,
                      icon: Icons
                          .category_outlined,
                      label:
                      'LOB',
                      value:
                      lob,
                    ),
                    _detailItem(
                      width: width,
                      icon: Icons
                          .person_outline,
                      label:
                      'Auditor',
                      value:
                      auditor,
                    ),
                    _detailItem(
                      width: width,
                      icon: Icons
                          .schedule_outlined,
                      label:
                      'Audit Hours',
                      value:
                      auditHours,
                    ),
                    _detailItem(
                      width: width,
                      icon: Icons
                          .assignment_outlined,
                      label:
                      'MIL Status',
                      value:
                      milStatus,
                      valueColor:
                      _milStatusColor(
                        milStatus,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(
              height: 17,
            ),

            const Divider(
              height: 1,
            ),

            const SizedBox(
              height: 11,
            ),

            // --------------------------------------------------
            // ACTIONS
            // --------------------------------------------------

            _buildAuditActions(
              audit: audit,
              isActive:
              isActive,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL ITEM
  // ============================================================

  Widget _detailItem({
    required double width,
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return SizedBox(
      width: width,
      child:
      Row(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,
        children: [
          Icon(
            icon,
            size: 17,
            color:
            Colors
                .grey
                .shade700,
          ),
          const SizedBox(
            width: 7,
          ),
          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  label,
                  style:
                  Theme.of(
                    context,
                  )
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    color: Colors
                        .grey
                        .shade600,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  value,
                  maxLines:
                  2,
                  overflow:
                  TextOverflow
                      .ellipsis,
                  style:
                  TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight
                        .w600,
                    color:
                    valueColor,
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
  // ACTIONS
  // ============================================================

  Widget _buildAuditActions({
    required Map<String, dynamic> audit,
    required bool isActive,
  }) {
    if (isActive) {
      return Align(
        alignment:
        Alignment.centerRight,
        child:
        ElevatedButton.icon(
          onPressed:
              () =>
              _continueAudit(
                audit,
              ),
          icon:
          const Icon(
            Icons
                .play_arrow_outlined,
            size: 18,
          ),
          label:
          const Text(
            'Continue Audit',
          ),
        ),
      );
    }

    return Wrap(
      alignment:
      WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed:
              () =>
              _openMilReport(
                audit,
              ),
          icon:
          const Icon(
            Icons
                .assignment_outlined,
            size: 18,
          ),
          label:
          const Text(
            'Open MIL',
          ),
        ),

        ElevatedButton.icon(
          onPressed:
              () =>
              _openAuditReport(
                audit,
              ),
          icon:
          const Icon(
            Icons
                .description_outlined,
            size: 18,
          ),
          label:
          const Text(
            'Audit Report',
          ),
        ),

        OutlinedButton.icon(
          onPressed:
              () =>
              _downloadAuditReport(
                audit,
              ),
          icon:
          const Icon(
            Icons
                .download_outlined,
            size: 18,
          ),
          label:
          const Text(
            'Download Audit Report',
          ),
        ),

        OutlinedButton.icon(
          onPressed:
              () =>
              _downloadMilReport(
                audit,
              ),
          icon:
          const Icon(
            Icons
                .download_outlined,
            size: 18,
          ),
          label:
          const Text(
            'Download MIL Report',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY HISTORY
  // ============================================================

  Widget _buildEmptyHistory() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 48,
      ),
      child:
      Column(
        children: [
          Icon(
            Icons
                .assignment_outlined,
            size: 52,
            color:
            Colors.grey.shade500,
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            _audits.isEmpty
                ? 'No audits have been created yet.'
                : 'No audits match the selected filters.',
            textAlign:
            TextAlign.center,
            style:
            Theme.of(
              context,
            )
                .textTheme
                .titleMedium
                ?.copyWith(
              fontWeight:
              FontWeight
                  .w600,
            ),
          ),
          if (_audits.isEmpty) ...[
            const SizedBox(
              height: 6,
            ),
            Text(
              'Start a new audit to begin.',
              style:
              Theme.of(
                context,
              )
                  .textTheme
                  .bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}