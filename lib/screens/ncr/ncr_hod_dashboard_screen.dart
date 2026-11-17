import 'package:flutter/material.dart';

import '../../services/ncr/ncr_auth_service.dart';
import '../../services/ncr/ncr_service.dart';
import '../../services/ncr/ncr_session.dart';
import 'ncr_hod_details_screen.dart';

class NcrHodDashboardScreen extends StatefulWidget {
  const NcrHodDashboardScreen({super.key});

  @override
  State<NcrHodDashboardScreen> createState() =>
      _NcrHodDashboardScreenState();
}

class _NcrHodDashboardScreenState
    extends State<NcrHodDashboardScreen> {
  bool _loading = true;
  String? _error;

  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _ncrs = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  // ============================================================
  // LOAD DASHBOARD
  // ============================================================

  Future<void> _loadDashboard() async {
    if (!mounted) {
      return;
    }

    if (!NcrSession.isLoggedIn || !NcrSession.isHod) {
      setState(() {
        _loading = false;
        _error = 'HOD login is required.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final statsResult =
      await NcrService.getHodDashboardData();

      final ncrResult =
      await NcrService.getHodAllNcrs();

      if (!mounted) {
        return;
      }

      final Map<String, dynamic> stats =
      Map<String, dynamic>.from(
        statsResult as Map,
      );

      final List<Map<String, dynamic>> ncrs =
      (ncrResult as List)
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
      )
          .toList();

      setState(() {
        _stats = stats;
        _ncrs = ncrs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = e
            .toString()
            .replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // INTEGER VALUE
  // ============================================================

  int _intValue(String key) {
    final value = _stats[key];

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
  // PENDING NCRs
  // ============================================================

  List<Map<String, dynamic>> get _pendingNcrs {
    return _ncrs.where(
          (ncr) {
        return _statusKey(ncr) ==
            'submitted_to_hod';
      },
    ).toList();
  }

  // ============================================================
  // STATUS KEY
  // ============================================================

  String _statusKey(
      Map<String, dynamic> ncr,
      ) {
    return (
        ncr['status_key'] ??
            ncr['statusKey'] ??
            ''
    )
        .toString()
        .toLowerCase()
        .trim();
  }

  // ============================================================
  // STATUS NAME
  // ============================================================

  String _statusName(
      Map<String, dynamic> ncr,
      ) {
    final value =
        ncr['status_name'] ??
            ncr['statusName'] ??
            ncr['status'] ??
            'Unknown';

    return value.toString();
  }

  // ============================================================
  // STRING VALUE
  // ============================================================

  String _stringValue(
      Map<String, dynamic> ncr,
      List<String> keys, {
        String fallback = '-',
      }) {
    for (final key in keys) {
      final value = ncr[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(dynamic value) {
    if (value == null ||
        value.toString().trim().isEmpty) {
      return '-';
    }

    final date =
    DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,

        title: const Text(
          'HOD Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
            _loading
                ? null
                : _loadDashboard,
            icon: const Icon(
              Icons.refresh,
            ),
          ),

          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: _buildBody(),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_loading && _ncrs.isEmpty) {
      return ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 250),
          Center(
            child:
            CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (_error != null &&
        _ncrs.isEmpty) {
      return ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),

          Icon(
            Icons.error_outline,
            size: 56,
            color: Colors.red.shade400,
          ),

          const SizedBox(height: 16),

          const Center(
            child: Text(
              'Unable to load HOD dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Center(
            child: Text(
              _error!,
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child:
            ElevatedButton.icon(
              onPressed:
              _loadDashboard,
              icon: const Icon(
                Icons.refresh,
              ),
              label:
              const Text('Retry'),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding:
      const EdgeInsets.all(16),
      children: [
        _buildWelcomeCard(),

        const SizedBox(height: 18),

        _buildStats(),

        const SizedBox(height: 28),

        _buildPendingSection(),

        const SizedBox(height: 30),

        _buildAllNcrSection(),

        const SizedBox(height: 24),
      ],
    );
  }

  // ============================================================
  // WELCOME CARD
  // ============================================================

  Widget _buildWelcomeCard() {
    final user =
        NcrSession.currentUser;

    return Card(
      elevation: 2,
      child: Padding(
        padding:
        const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              child: const Icon(
                Icons.verified_user,
                size: 29,
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HOD Review Dashboard',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    user?.fullName ??
                        'HOD',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    'Review submitted NCR action plans and take approval decisions.',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                      Colors.grey.shade700,
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
  // STATISTICS
  // ============================================================

  Widget _buildStats() {
    final cards = [
      _StatData(
        title: 'Total NCRs',
        value:
        _intValue('total_ncrs'),
        icon:
        Icons.description_outlined,
      ),

      _StatData(
        title: 'Pending HOD',
        value:
        _intValue('pending_hod'),
        icon:
        Icons.pending_actions,
      ),

      _StatData(
        title: 'Needs Correction',
        value:
        _intValue('hod_rejected'),
        icon:
        Icons.edit_note,
      ),

      _StatData(
        title: 'Sent to DCC',
        value:
        _intValue('sent_to_dcc'),
        icon:
        Icons.send_outlined,
      ),

      _StatData(
        title: 'Closed',
        value:
        _intValue('closed'),
        icon:
        Icons.check_circle_outline,
      ),
    ];

    return LayoutBuilder(
      builder:
          (context, constraints) {
        final width =
            constraints.maxWidth;

        final cardWidth =
        width >= 1100
            ? (width - 48) / 4
            : width >= 700
            ? (width - 16) / 2
            : width;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children:
          cards.map(
                (data) {
              return SizedBox(
                width: cardWidth,
                child:
                _buildStatCard(
                  data,
                ),
              );
            },
          ).toList(),
        );
      },
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _buildStatCard(
      _StatData data,
      ) {
    return Card(
      elevation: 1,
      child: Padding(
        padding:
        const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration:
              BoxDecoration(
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
                color: Colors.grey
                    .withOpacity(0.10),
              ),
              child: Icon(
                data.icon,
                size: 26,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    data.value.toString(),
                    style:
                    const TextStyle(
                      fontSize: 25,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    data.title,
                    maxLines: 2,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors
                          .grey.shade700,
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
  // PENDING HOD SECTION
  // ============================================================

  Widget _buildPendingSection() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Pending HOD Review',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),

            if (_pendingNcrs.isNotEmpty)
              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 11,
                  vertical: 5,
                ),
                decoration:
                BoxDecoration(
                  borderRadius:
                  BorderRadius
                      .circular(
                    20,
                  ),
                  color: Colors.orange
                      .withOpacity(
                    0.12,
                  ),
                ),
                child: Text(
                  '${_pendingNcrs.length}',
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        if (_pendingNcrs.isEmpty)
          _buildEmptyCard(
            icon:
            Icons.task_alt,
            text:
            'No NCRs are currently pending HOD review.',
          )
        else
          ..._pendingNcrs.map(
                (ncr) =>
                _buildNcrCard(
                  ncr,
                  highlight: true,
                ),
          ),
      ],
    );
  }

  // ============================================================
  // ALL NCR SECTION
  // ============================================================

  Widget _buildAllNcrSection() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'All NCR Records',
          style: TextStyle(
            fontSize: 20,
            fontWeight:
            FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        if (_ncrs.isEmpty)
          _buildEmptyCard(
            icon:
            Icons.folder_open,
            text:
            'No NCR records found.',
          )
        else
          ..._ncrs.map(
                (ncr) =>
                _buildNcrCard(
                  ncr,
                  highlight: false,
                ),
          ),
      ],
    );
  }

  // ============================================================
  // EMPTY CARD
  // ============================================================

  Widget _buildEmptyCard({
    required IconData icon,
    required String text,
  }) {
    return Card(
      child: Padding(
        padding:
        const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color:
              Colors.grey.shade500,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors
                      .grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NCR CARD
  // ============================================================

  Widget _buildNcrCard(
      Map<String, dynamic> ncr, {
        required bool highlight,
      }) {
    final ncrNumber =
    _stringValue(
      ncr,
      [
        'ncr_number',
        'ncrNumber',
      ],
    );

    final process =
    _stringValue(
      ncr,
      [
        'process_function',
        'processFunction',
      ],
    );

    final auditee =
    _stringValue(
      ncr,
      [
        'auditee_name',
        'auditeeName',
        'auditee_full_name',
      ],
    );

    final auditor =
    _stringValue(
      ncr,
      [
        'auditor_name',
        'auditorName',
        'auditor_full_name',
      ],
    );

    final status =
    _statusName(ncr);

    final auditDate =
    _formatDate(
      ncr['audit_date'] ??
          ncr['auditDate'],
    );

    return Card(
      elevation:
      highlight ? 3 : 1,
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        onTap: () =>
            _openDetails(ncr),
        child: Padding(
          padding:
          const EdgeInsets.all(
            16,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ncrNumber,
                      style:
                      const TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),

                  _buildStatusChip(
                    status,
                    _statusKey(ncr),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  const Icon(
                    Icons.chevron_right,
                    size: 22,
                  ),
                ],
              ),

              const SizedBox(
                height: 12,
              ),

              Wrap(
                spacing: 20,
                runSpacing: 9,
                children: [
                  _miniInfo(
                    Icons
                        .account_tree_outlined,
                    'Process',
                    process,
                  ),

                  _miniInfo(
                    Icons.person_outline,
                    'Auditee',
                    auditee,
                  ),

                  _miniInfo(
                    Icons
                        .person_search_outlined,
                    'Auditor',
                    auditor,
                  ),

                  _miniInfo(
                    Icons
                        .calendar_today_outlined,
                    'Audit Date',
                    auditDate,
                  ),
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                'Tap to view full NCR details',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors
                      .grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MINI INFO
  // ============================================================

  Widget _miniInfo(
      IconData icon,
      String label,
      String value,
      ) {
    return SizedBox(
      width: 205,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.grey.shade600,
          ),

          const SizedBox(width: 7),

          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade800,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _buildStatusChip(
      String status,
      String statusKey,
      ) {
    Color color;

    switch (statusKey) {
      case 'submitted_to_hod':
        color = Colors.orange;
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

      case 'in_progress':
      case 'assigned':
        color =
            Colors.amber.shade800;
        break;

      default:
        color = Colors.grey;
    }

    return Container(
      constraints:
      const BoxConstraints(
        maxWidth: 150,
      ),
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration:
      BoxDecoration(
        color:
        color.withOpacity(0.12),
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
  // OPEN DETAILS
  // ============================================================

  Future<void> _openDetails(
      Map<String, dynamic> ncr,
      ) async {
    final result =
    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder: (_) =>
            NcrHodDetailsScreen(
              ncr: ncr,
            ),
      ),
    );

    if (result == true &&
        mounted) {
      await _loadDashboard();
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
}

// ================================================================
// STAT DATA
// ================================================================

class _StatData {
  final String title;
  final int value;
  final IconData icon;

  const _StatData({
    required this.title,
    required this.value,
    required this.icon,
  });
}