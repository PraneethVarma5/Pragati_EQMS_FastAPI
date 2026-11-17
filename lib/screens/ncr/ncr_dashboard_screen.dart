import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/ncr/ncr_service.dart';
import '../../services/ncr/ncr_session.dart';

class NcrDashboardScreen extends StatefulWidget {
  const NcrDashboardScreen({
    super.key,
  });

  @override
  State<NcrDashboardScreen> createState() =>
      _NcrDashboardScreenState();
}

class _NcrDashboardScreenState
    extends State<NcrDashboardScreen> {
  // ============================================================
  // DATA
  // ============================================================

  bool _isLoading = true;

  String? _errorMessage;

  int _totalNcrs = 0;
  int _inProgress = 0;
  int _pendingApproval = 0;
  int _closed = 0;

  List<Map<String, dynamic>> _records = [];

  Timer? _refreshTimer;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadDashboard();

    // ----------------------------------------------------------
    // Automatic refresh.
    //
    // This keeps the public dashboard current even when the page
    // remains open while an Admin/User/HOD/DCC changes an NCR.
    // ----------------------------------------------------------

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) {
        _loadDashboard(
          silent: true,
        );
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // LOAD DASHBOARD
  // ============================================================

  Future<void> _loadDashboard({
    bool silent = false,
  }) async {
    if (!mounted) {
      return;
    }

    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response =
      await NcrService
          .getPublicDashboardData();

      if (!mounted) {
        return;
      }

      final recordsRaw =
      response['records'];

      final List<Map<String, dynamic>>
      records = recordsRaw is List
          ? recordsRaw
          .whereType<Map>()
          .map(
            (item) =>
        Map<String, dynamic>.from(
          item,
        ),
      )
          .toList()
          : <Map<String, dynamic>>[];

      setState(() {
        _totalNcrs =
            _toInt(
              response['total_ncrs'],
            );

        _inProgress =
            _toInt(
              response['in_progress'],
            );

        _pendingApproval =
            _toInt(
              response['pending_approval'],
            );

        _closed =
            _toInt(
              response['closed'],
            );

        _records = records;

        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // During silent auto-refresh, don't wipe existing working
      // data just because one refresh request failed.
      // --------------------------------------------------------

      if (silent) {
        return;
      }

      setState(() {
        _isLoading = false;

        _errorMessage =
            e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // INTEGER HELPER
  // ============================================================

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user =
        NcrSession.currentUser;

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FA),

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        elevation: 0,

        backgroundColor:
        Colors.white,

        surfaceTintColor:
        Colors.white,

        title: const Text(
          'NCR Management',
          style: TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),

        actions: [
          // ------------------------------------------------------
          // REFRESH
          // ------------------------------------------------------

          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading
                ? null
                : () {
              _loadDashboard();
            },
            icon: const Icon(
              Icons.refresh,
            ),
          ),

          // ------------------------------------------------------
          // LOGIN / MY DASHBOARD
          // ------------------------------------------------------

          if (user == null)
            Padding(
              padding:
              const EdgeInsets.only(
                right: 16,
              ),
              child:
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/NCR/login',
                  );
                },
                icon: const Icon(
                  Icons.login,
                  size: 19,
                ),
                label: const Text(
                  'Login',
                ),
              ),
            )
          else
            Padding(
              padding:
              const EdgeInsets.only(
                right: 16,
              ),
              child:
              ElevatedButton.icon(
                onPressed:
                _openMyDashboard,
                icon: const Icon(
                  Icons
                      .dashboard_outlined,
                  size: 19,
                ),
                label: const Text(
                  'My Dashboard',
                ),
              ),
            ),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body:
      RefreshIndicator(
        onRefresh: () =>
            _loadDashboard(),

        child:
        SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),

          padding:
          const EdgeInsets.all(
            28,
          ),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // ====================================================
              // HEADER
              // ====================================================

              const Text(
                'Non-Conformance Report',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight:
                  FontWeight.w800,
                  color:
                  Color(0xFF172033),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                'NCR Dashboard',
                style: TextStyle(
                  fontSize: 16,
                  color:
                  Colors.grey.shade600,
                ),
              ),

              const SizedBox(
                height: 28,
              ),

              // ====================================================
              // INFORMATION CARD
              // ====================================================

              _buildInformationCard(),

              const SizedBox(
                height: 28,
              ),

              // ====================================================
              // ERROR
              // ====================================================

              if (_errorMessage != null)
                _buildErrorCard(),

              // ====================================================
              // SUMMARY
              // ====================================================

              LayoutBuilder(
                builder:
                    (
                    context,
                    constraints,
                    ) {
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
                      SizedBox(
                        width:
                        cardWidth,
                        child:
                        _summaryCard(
                          title:
                          'Total NCRs',
                          value:
                          _isLoading
                              ? null
                              : _totalNcrs
                              .toString(),
                          icon:
                          Icons
                              .assignment_outlined,
                        ),
                      ),

                      SizedBox(
                        width:
                        cardWidth,
                        child:
                        _summaryCard(
                          title:
                          'In Progress',
                          value:
                          _isLoading
                              ? null
                              : _inProgress
                              .toString(),
                          icon:
                          Icons
                              .pending_actions,
                        ),
                      ),

                      SizedBox(
                        width:
                        cardWidth,
                        child:
                        _summaryCard(
                          title:
                          'Pending Approval',
                          value:
                          _isLoading
                              ? null
                              : _pendingApproval
                              .toString(),
                          icon:
                          Icons
                              .approval_outlined,
                        ),
                      ),

                      SizedBox(
                        width:
                        cardWidth,
                        child:
                        _summaryCard(
                          title:
                          'Closed',
                          value:
                          _isLoading
                              ? null
                              : _closed
                              .toString(),
                          icon:
                          Icons
                              .check_circle_outline,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(
                height: 32,
              ),

              // ====================================================
              // NCR RECORDS
              // ====================================================

              _buildNcrRecordsSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATION CARD
  // ============================================================

  Widget _buildInformationCard() {
    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.all(
        24,
      ),

      decoration:
      BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(
          16,
        ),

        border: Border.all(
          color:
          const Color(
            0xFFE2E7EF,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color:
            Colors.black
                .withOpacity(
              0.04,
            ),
            blurRadius: 15,
            offset:
            const Offset(
              0,
              6,
            ),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,

            decoration:
            BoxDecoration(
              color:
              Colors.orange.shade50,
              borderRadius:
              BorderRadius.circular(
                15,
              ),
            ),

            child: Icon(
              Icons
                  .warning_amber_rounded,
              size: 30,
              color:
              Colors.orange.shade700,
            ),
          ),

          const SizedBox(
            width: 18,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                const Text(
                  'NCR Overview',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  'Live NCR records and their current workflow status.',
                  style: TextStyle(
                    color: Colors
                        .grey.shade600,
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
  // ERROR CARD
  // ============================================================

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,

      margin:
      const EdgeInsets.only(
        bottom: 28,
      ),

      padding:
      const EdgeInsets.all(
        18,
      ),

      decoration:
      BoxDecoration(
        color:
        Colors.red.shade50,

        borderRadius:
        BorderRadius.circular(
          12,
        ),

        border: Border.all(
          color:
          Colors.red.shade200,
        ),
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
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
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  'Unable to load NCR data',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.bold,
                    color:
                    Colors.red.shade800,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  _errorMessage ??
                      'Unknown error.',
                  style: TextStyle(
                    color:
                    Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),

          TextButton(
            onPressed:
            _loadDashboard,
            child:
            const Text(
              'Retry',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _summaryCard({
    required String title,
    required String? value,
    required IconData icon,
  }) {
    return Container(
      height: 125,

      padding:
      const EdgeInsets.all(
        20,
      ),

      decoration:
      BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(
          16,
        ),

        border: Border.all(
          color:
          const Color(
            0xFFE2E7EF,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color:
            Colors.black
                .withOpacity(
              0.035,
            ),
            blurRadius: 12,
            offset:
            const Offset(
              0,
              5,
            ),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,

            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFFEFF3FF,
              ),
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
              size: 25,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment
                  .center,
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors
                        .grey.shade600,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                if (value == null)
                  const SizedBox(
                    height: 25,
                    width: 25,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2.5,
                    ),
                  )
                else
                  Text(
                    value,
                    style:
                    const TextStyle(
                      fontSize: 25,
                      fontWeight:
                      FontWeight.bold,
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
  // NCR RECORDS SECTION
  // ============================================================

  Widget _buildNcrRecordsSection() {
    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.all(
        24,
      ),

      decoration:
      BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(
          16,
        ),

        border: Border.all(
          color:
          const Color(
            0xFFE2E7EF,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color:
            Colors.black
                .withOpacity(
              0.025,
            ),
            blurRadius: 12,
            offset:
            const Offset(
              0,
              4,
            ),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'NCR Records',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),

              if (_records
                  .isNotEmpty)
                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(
                      0xFFEFF3FF,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      20,
                    ),
                  ),
                  child: Text(
                    '${_records.length} Records',
                    style:
                    const TextStyle(
                      fontSize: 12,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            'All NCR records currently available in the system.',
            style: TextStyle(
              color:
              Colors.grey.shade600,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          if (_isLoading &&
              _records.isEmpty)
            _buildLoadingRecords()

          else if (_records.isEmpty)
            _buildEmptyRecords()

          else
            ..._records.map(
              _buildNcrCard,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING RECORDS
  // ============================================================

  Widget _buildLoadingRecords() {
    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.symmetric(
        vertical: 55,
      ),

      decoration:
      BoxDecoration(
        color:
        const Color(
          0xFFF8F9FC,
        ),
        borderRadius:
        BorderRadius.circular(
          12,
        ),
      ),

      child: const Column(
        children: [
          SizedBox(
            height: 35,
            width: 35,
            child:
            CircularProgressIndicator(
              strokeWidth: 3,
            ),
          ),

          SizedBox(
            height: 14,
          ),

          Text(
            'Loading NCR records...',
            style: TextStyle(
              fontSize: 15,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY RECORDS
  // ============================================================

  Widget _buildEmptyRecords() {
    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.symmetric(
        vertical: 55,
      ),

      decoration:
      BoxDecoration(
        color:
        const Color(
          0xFFF8F9FC,
        ),
        borderRadius:
        BorderRadius.circular(
          12,
        ),
      ),

      child: Column(
        children: [
          Icon(
            Icons
                .assignment_outlined,
            size: 55,
            color:
            Colors.grey.shade400,
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            'No NCR records found',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.w600,
              color:
              Colors.grey.shade600,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            'NCR records will appear here once they are created.',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color:
              Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NCR CARD
  // ============================================================

  Widget _buildNcrCard(
      Map<String, dynamic> ncr,
      ) {
    final ncrNumber =
    _value(
      ncr,
      [
        'ncr_number',
      ],
    );

    final process =
    _value(
      ncr,
      [
        'process_function',
      ],
    );

    final auditee =
    _value(
      ncr,
      [
        'auditee_name',
      ],
    );

    final auditor =
    _value(
      ncr,
      [
        'auditor_name',
      ],
    );

    final standard =
    _value(
      ncr,
      [
        'standard',
      ],
    );

    final auditDate =
    _formatDate(
      ncr['audit_date'],
    );

    final statusKey =
    _value(
      ncr,
      [
        'status_key',
      ],
      fallback: '',
    );

    final statusName =
    _value(
      ncr,
      [
        'status_name',
      ],
      fallback: 'Unknown',
    );

    final finding =
    _value(
      ncr,
      [
        'finding_statement',
      ],
      fallback: '',
    );

    return Container(
      width: double.infinity,

      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),

      decoration:
      BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(
          12,
        ),

        border: Border.all(
          color:
          const Color(
            0xFFE5E9F0,
          ),
        ),
      ),

      child: Padding(
        padding:
        const EdgeInsets.all(
          18,
        ),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment
              .start,
          children: [
            // ------------------------------------------------------
            // TOP ROW
            // ------------------------------------------------------

            Row(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        ncrNumber,
                        style:
                        const TextStyle(
                          fontSize: 17,
                          fontWeight:
                          FontWeight
                              .bold,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        'Non-Conformance Report',
                        style:
                        TextStyle(
                          fontSize: 12,
                          color: Colors
                              .grey
                              .shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                _statusChip(
                  statusName,
                  statusKey,
                ),
              ],
            ),

            const Divider(
              height: 26,
            ),

            // ------------------------------------------------------
            // BASIC DETAILS
            // ------------------------------------------------------

            LayoutBuilder(
              builder:
                  (
                  context,
                  constraints,
                  ) {
                final width =
                    constraints.maxWidth;

                final itemWidth =
                width >= 800
                    ? (width - 24) / 2
                    : width;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width:
                      itemWidth,
                      child:
                      _recordInfo(
                        Icons
                            .account_tree_outlined,
                        'Process / Function',
                        process,
                      ),
                    ),

                    SizedBox(
                      width:
                      itemWidth,
                      child:
                      _recordInfo(
                        Icons
                            .person_outline,
                        'Auditee',
                        auditee,
                      ),
                    ),

                    SizedBox(
                      width:
                      itemWidth,
                      child:
                      _recordInfo(
                        Icons
                            .person_search_outlined,
                        'Auditor',
                        auditor,
                      ),
                    ),

                    SizedBox(
                      width:
                      itemWidth,
                      child:
                      _recordInfo(
                        Icons
                            .calendar_today_outlined,
                        'Audit Date',
                        auditDate,
                      ),
                    ),

                    SizedBox(
                      width:
                      itemWidth,
                      child:
                      _recordInfo(
                        Icons
                            .verified_outlined,
                        'Standard',
                        standard,
                      ),
                    ),
                  ],
                );
              },
            ),

            // ------------------------------------------------------
            // FINDING
            // ------------------------------------------------------

            if (finding
                .trim()
                .isNotEmpty) ...[
              const SizedBox(
                height: 14,
              ),

              _recordInfo(
                Icons
                    .report_problem_outlined,
                'Finding / Nonconformity',
                finding,
                fullWidth: true,
              ),
            ],

            const SizedBox(
              height: 12,
            ),

            // ------------------------------------------------------
            // FOOTER
            // ------------------------------------------------------

            Row(
              children: [
                Icon(
                  Icons
                      .visibility_outlined,
                  size: 16,
                  color: Colors
                      .grey.shade500,
                ),

                const SizedBox(
                  width: 6,
                ),

                Text(
                  'Public NCR record',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors
                        .grey.shade500,
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
  // RECORD INFO
  // ============================================================

  Widget _recordInfo(
      IconData icon,
      String label,
      String value, {
        bool fullWidth = false,
      }) {
    return Container(
      width: fullWidth
          ? double.infinity
          : null,

      padding:
      const EdgeInsets.all(
        12,
      ),

      decoration:
      BoxDecoration(
        color:
        const Color(
          0xFFF8F9FC,
        ),

        borderRadius:
        BorderRadius.circular(
          9,
        ),

        border: Border.all(
          color:
          const Color(
            0xFFE9ECF2,
          ),
        ),
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,
        children: [
          Icon(
            icon,
            size: 18,
            color:
            Colors.grey.shade600,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  label,
                  style:
                  TextStyle(
                    fontSize: 11,
                    fontWeight:
                    FontWeight
                        .w600,
                    color: Colors
                        .grey
                        .shade600,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  value.isEmpty
                      ? '-'
                      : value,
                  style:
                  const TextStyle(
                    fontSize: 14,
                    fontWeight:
                    FontWeight.w500,
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
  // STATUS CHIP
  // ============================================================

  Widget _statusChip(
      String status,
      String statusKey,
      ) {
    Color color;

    switch (statusKey) {
      case 'assigned':
      case 'in_progress':
        color =
            Colors.orange.shade800;
        break;

      case 'submitted_to_hod':
        color =
            Colors.amber.shade800;
        break;

      case 'hod_rejected':
        color = Colors.red;
        break;

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
        maxWidth: 190,
      ),

      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration:
      BoxDecoration(
        color:
        color.withOpacity(
          0.12,
        ),

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
          fontSize: 12,
          fontWeight:
          FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // VALUE
  // ============================================================

  String _value(
      Map<String, dynamic> map,
      List<String> keys, {
        String fallback = '-',
      }) {
    for (final key in keys) {
      final value = map[key];

      if (value != null &&
          value.toString()
              .trim()
              .isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(
      dynamic value,
      ) {
    if (value == null ||
        value.toString()
            .trim()
            .isEmpty) {
      return '-';
    }

    final date =
    DateTime.tryParse(
      value.toString(),
    );

    if (date == null) {
      return value.toString();
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // MY DASHBOARD
  // ============================================================

  void _openMyDashboard() {
    final user =
        NcrSession.currentUser;

    if (user == null) {
      Navigator.pushNamed(
        context,
        '/NCR/login',
      );
      return;
    }

    switch (
    user.roleKey.toLowerCase()) {
      case 'admin':
        Navigator.pushNamed(
          context,
          '/NCR/admin-dashboard',
        );
        break;

      case 'user':
        Navigator.pushNamed(
          context,
          '/NCR/user-dashboard',
        );
        break;

      case 'hod':
        Navigator.pushNamed(
          context,
          '/NCR/hod-dashboard',
        );
        break;

      case 'dcc':
        Navigator.pushNamed(
          context,
          '/NCR/dcc-dashboard',
        );
        break;

      default:
        Navigator.pushNamed(
          context,
          '/NCR/login',
        );
    }
  }
}