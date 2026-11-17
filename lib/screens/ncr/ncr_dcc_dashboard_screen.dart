import 'package:flutter/material.dart';

import '../../services/ncr/ncr_auth_service.dart';
import '../../services/ncr/ncr_service.dart';
import '../../services/ncr/ncr_session.dart';
import 'ncr_dcc_details_screen.dart';

class NcrDccDashboardScreen extends StatefulWidget {
  const NcrDccDashboardScreen({
    super.key,
  });

  @override
  State<NcrDccDashboardScreen> createState() =>
      _NcrDccDashboardScreenState();
}

class _NcrDccDashboardScreenState
    extends State<NcrDccDashboardScreen> {
  bool _loading = true;
  String? _error;

  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _ncrs = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!NcrSession.isLoggedIn ||
        !NcrSession.isDcc) {
      setState(() {
        _loading = false;
        _error =
        'DCC login is required.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final stats =
      await NcrService
          .getDccDashboardData();

      final ncrs =
      await NcrService
          .getDccAllNcrs();

      if (!mounted) return;

      setState(() {
        _stats =
        Map<String, dynamic>.from(
          stats,
        );

        _ncrs = ncrs;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e
            .toString()
            .replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

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

  String _statusName(
      Map<String, dynamic> ncr,
      ) {
    return (
        ncr['status_name'] ??
            ncr['statusName'] ??
            ncr['status'] ??
            'Unknown'
    ).toString();
  }

  String _value(
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

  String _date(dynamic value) {
    if (value == null ||
        value.toString().trim().isEmpty) {
      return '-';
    }

    final parsed =
    DateTime.tryParse(
      value.toString(),
    );

    if (parsed == null) {
      return value.toString();
    }

    return '${parsed.day.toString().padLeft(2, '0')}/'
        '${parsed.month.toString().padLeft(2, '0')}/'
        '${parsed.year}';
  }

  List<Map<String, dynamic>>
  get _pendingDcc {
    return _ncrs
        .where(
          (ncr) =>
      _statusKey(ncr) ==
          'sent_to_dcc',
    )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'DCC Dashboard',
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

  Widget _buildBody() {
    if (_loading &&
        _ncrs.isEmpty) {
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
          const Text(
            'Unable to load DCC dashboard',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight:
              FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
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
        _buildAllSection(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding:
        const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: const Icon(
                Icons.approval,
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
                    'DCC Review Dashboard',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    NcrSession
                        .currentUser
                        ?.fullName ??
                        'DCC',
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Review HOD-approved NCRs and close or reject them.',
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

  Widget _buildStats() {
    final cards = [
      _StatData(
        'Total NCRs',
        _intValue('total_ncrs'),
        Icons.description_outlined,
      ),
      _StatData(
        'Pending DCC',
        _intValue('pending_dcc'),
        Icons.pending_actions,
      ),
      _StatData(
        'Needs Correction',
        _intValue('dcc_rejected'),
        Icons.edit_note,
      ),
      _StatData(
        'Closed',
        _intValue('closed'),
        Icons.check_circle_outline,
      ),
    ];

    return LayoutBuilder(
      builder:
          (context, constraints) {
        final width =
            constraints.maxWidth;

        final cardWidth =
        width >= 1000
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

  Widget _buildPendingSection() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Pending DCC Review',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
            if (_pendingDcc.isNotEmpty)
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
                  BorderRadius.circular(
                    20,
                  ),
                  color: Colors.blue
                      .withOpacity(
                    0.12,
                  ),
                ),
                child: Text(
                  '${_pendingDcc.length}',
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
        if (_pendingDcc.isEmpty)
          _emptyCard(
            Icons.task_alt,
            'No NCRs are currently pending DCC review.',
          )
        else
          ..._pendingDcc.map(
                (ncr) =>
                _ncrCard(
                  ncr,
                  highlight: true,
                ),
          ),
      ],
    );
  }

  Widget _buildAllSection() {
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
          _emptyCard(
            Icons.folder_open,
            'No NCR records found.',
          )
        else
          ..._ncrs.map(
                (ncr) =>
                _ncrCard(
                  ncr,
                  highlight: false,
                ),
          ),
      ],
    );
  }

  Widget _emptyCard(
      IconData icon,
      String text,
      ) {
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
                  color:
                  Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ncrCard(
      Map<String, dynamic> ncr, {
        required bool highlight,
      }) {
    final ncrNumber =
    _value(
      ncr,
      ['ncr_number'],
    );

    final process =
    _value(
      ncr,
      ['process_function'],
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

    final auditDate =
    _date(
      ncr['audit_date'],
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
          const EdgeInsets.all(16),
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
                  _statusChip(
                    _statusName(ncr),
                    _statusKey(ncr),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 20,
                runSpacing: 9,
                children: [
                  _miniInfo(
                    Icons.account_tree_outlined,
                    'Process',
                    process,
                  ),
                  _miniInfo(
                    Icons.person_outline,
                    'Auditee',
                    auditee,
                  ),
                  _miniInfo(
                    Icons.person_search_outlined,
                    'Auditor',
                    auditor,
                  ),
                  _miniInfo(
                    Icons.calendar_today_outlined,
                    'Audit Date',
                    auditDate,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Tap to view full NCR details',
                style: TextStyle(
                  fontSize: 12,
                  color:
                  Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniInfo(
      IconData icon,
      String label,
      String value,
      ) {
    return SizedBox(
      width: 205,
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color:
            Colors.grey.shade600,
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
                      fontWeight:
                      FontWeight.w600,
                      color:
                      Colors.grey.shade800,
                      decoration:
                      TextDecoration.none,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                      Colors.grey.shade800,
                      decoration:
                      TextDecoration.none,
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

  Widget _statusChip(
      String status,
      String statusKey,
      ) {
    Color color;

    switch (statusKey) {
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
        maxWidth: 170,
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
          fontSize: 12,
          fontWeight:
          FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Future<void> _openDetails(
      Map<String, dynamic> ncr,
      ) async {
    final result =
    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder: (_) =>
            NcrDccDetailsScreen(
              ncr: ncr,
            ),
      ),
    );

    if (result == true &&
        mounted) {
      await _loadDashboard();
    }
  }

  Future<void> _logout() async {
    await NcrAuthService.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/NCR',
          (route) => false,
    );
  }
}

class _StatData {
  final String title;
  final int value;
  final IconData icon;

  const _StatData(
      this.title,
      this.value,
      this.icon,
      );
}