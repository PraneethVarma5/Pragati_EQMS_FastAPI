import 'package:flutter/material.dart';

import '../../../models/dcc/dcc_document.dart';
import '../../../services/dcc/dcc_document_service.dart';
import '../../../services/dcc/dcc_session.dart';
import '../widgets/dcc_notification_bell.dart';
import 'hod_dmr_requests_screen.dart';
import 'hod_document_review_screen.dart';
import 'hod_activity_history_screen.dart';
import '../../../services/dcc/dcc_dmr_service.dart';
import '../../../models/dcc/dcc_activity.dart';
import '../../../services/dcc/dcc_activity_service.dart';

class HodDashboardScreen extends StatefulWidget {
  const HodDashboardScreen({super.key});

  @override
  State<HodDashboardScreen> createState() =>
      _HodDashboardScreenState();
}

class _HodDashboardScreenState
    extends State<HodDashboardScreen> {
  List<DccDocument> _documents = [];
  List<DccActivity> _activities = [];

  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData({
    bool showRefreshIndicator = false,
  }) async {
    final user = DccSession.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    if (showRefreshIndicator) {
      setState(() {
        _isRefreshing = true;
      });
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final documents =
      await DccDocumentService.getDocumentsForHod(
        user.email,
      );

      final pendingDmrRequests =
      await DccDmrService.getPendingHodRequests(
        user.email,
      );

      final activities =
      await DccActivityService.getActivitiesForUser(
        user.email,
      );

      documents.sort(
            (a, b) =>
            b.revisionDate.compareTo(
              a.revisionDate,
            ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _documents = documents;
        _activities = activities;
        _pendingDmrCount =
            pendingDmrRequests.length;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load HOD dashboard data.',
          ),
        ),
      );
    }
  }

  int get _pendingCount {
    return _documents
        .where(
          (document) =>
      document.status == 'PENDING_HOD',
    )
        .length;
  }

  int get _dccReviewCount {
    return _documents
        .where(
          (document) =>
      document.status == 'PENDING_DCC',
    )
        .length;
  }

  int get _releasedCount {
    return _documents
        .where(
          (document) =>
      document.status == 'RELEASED',
    )
        .length;
  }

  int get _rejectedCount {
    return _documents
        .where(
          (document) =>
      document.status == 'REJECTED',
    )
        .length;
  }

  int _pendingDmrCount = 0;

  @override
  Widget build(BuildContext context) {
    final user = DccSession.currentUser;

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'HOD Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor:
        const Color(0xFF172033),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isRefreshing
                ? null
                : () {
              _loadDashboardData(
                showRefreshIndicator: true,
              );
            },
            icon: _isRefreshing
                ? const SizedBox(
              width: 20,
              height: 20,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Icon(
              Icons.refresh_rounded,
            ),
            tooltip: 'Refresh dashboard',
          ),

          const DccNotificationBell(),

          const SizedBox(width: 8),
        ],
      ),

      body: _isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: () =>
            _loadDashboardData(),
        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w600,
                  color:
                  Color(0xFF6B7280),
                ),
              ),

              const SizedBox(height: 5),

              Text(
                user?.name ?? 'HOD',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight:
                  FontWeight.w800,
                  color:
                  Color(0xFF172033),
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Document Approval Management',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight:
                  FontWeight.w600,
                  color:
                  Color(0xFF4B5563),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Review documents submitted by users and manage approval requests.',
                style: TextStyle(
                  fontSize: 14,
                  color:
                  Color(0xFF6B7280),
                ),
              ),

              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      title:
                      'Pending Approval',
                      value:
                      '$_pendingCount',
                      icon: Icons
                          .pending_actions_rounded,
                      iconColor:
                      Colors.orange,
                    ),
                  ),

                  const SizedBox(
                    width: 16,
                  ),

                  Expanded(
                    child: _summaryCard(
                      title:
                      'DCC Review',
                      value:
                      '$_dccReviewCount',
                      icon: Icons
                          .fact_check_outlined,
                      iconColor:
                      Colors.blue,
                    ),
                  ),

                  const SizedBox(
                    width: 16,
                  ),

                  Expanded(
                    child: _summaryCard(
                      title: 'Released',
                      value:
                      '$_releasedCount',
                      icon: Icons
                          .verified_outlined,
                      iconColor:
                      Colors.green,
                    ),
                  ),

                  const SizedBox(
                    width: 16,
                  ),

                  Expanded(
                    child: _summaryCard(
                      title: 'Rejected',
                      value:
                      '$_rejectedCount',
                      icon: Icons
                          .cancel_outlined,
                      iconColor:
                      Colors.red,
                    ),
                  ),

                  const SizedBox(
                    width: 16,
                  ),

                  Expanded(
                    child: _summaryCard(
                      title: 'DMR Requests',
                      value:
                      '$_pendingDmrCount',
                      icon: Icons
                          .edit_document,
                      iconColor:
                      Colors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              _buildDmrActionCard(
                context,
              ),

              const SizedBox(height: 30),

              const Text(
                'Pending Approvals',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                  FontWeight.w800,
                  color:
                  Color(0xFF172033),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Documents waiting for your review.',
                style: TextStyle(
                  fontSize: 13,
                  color:
                  Color(0xFF6B7280),
                ),
              ),

              const SizedBox(height: 16),

              _buildPendingDocuments(),

              const SizedBox(height: 30),

              _buildRecentActivity(),

              const SizedBox(height: 15),

              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const HodActivityHistoryScreen(),
                      ),
                    );

                    if (mounted) {
                      await _loadDashboardData();
                    }
                  },
                  icon: const Icon(
                    Icons.history_rounded,
                  ),
                  label: const Text(
                    'View Full Activity History',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding:
      const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xFFE4E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color:
              iconColor.withOpacity(
                0.10,
              ),
              borderRadius:
              BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 27,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style:
                  const TextStyle(
                    fontSize: 24,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
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
    );
  }

  Widget _buildPendingDocuments() {
    final pending =
    _documents
        .where(
          (document) =>
      document.status ==
          'PENDING_HOD',
    )
        .toList();

    if (pending.isEmpty) {
      return Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(18),
          border: Border.all(
            color:
            const Color(0xFFE4E8F0),
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Icon(
                Icons
                    .assignment_turned_in_outlined,
                size: 48,
                color:
                Color(0xFF9AA2B1),
              ),

              SizedBox(height: 12),

              Text(
                'No pending approvals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  Color(0xFF4B5563),
                ),
              ),

              SizedBox(height: 5),

              Text(
                'Documents waiting for your approval will appear here.',
                style: TextStyle(
                  fontSize: 12,
                  color:
                  Color(0xFF9AA2B1),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(0xFFE4E8F0),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics:
        const NeverScrollableScrollPhysics(),
        itemCount: pending.length,
        separatorBuilder: (_, _) =>
        const Divider(
          height: 1,
        ),
        itemBuilder:
            (context, index) {
          final document =
          pending[index];

          return InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        HodDocumentReviewScreen(
                          document: document,
                        ),
                  ),
                );

                if (result == true && mounted) {
                  await _loadDashboardData();
                }
              },
              child: Padding(
                padding:
                const EdgeInsets.all(20),
                child: Row(
                  children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(
                      0xFFFFF3DF,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
                    ),
                  ),
                  child: const Icon(
                    Icons
                        .description_outlined,
                    color:
                    Color(0xFFE67E00),
                  ),
                ),

                const SizedBox(
                  width: 16,
                ),

                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        document.documentNo,
                        style:
                        const TextStyle(
                          fontSize: 14,
                          fontWeight:
                          FontWeight.w800,
                          color:
                          Color(
                            0xFF172033,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        document.documentName,
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        const TextStyle(
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

                Expanded(
                  child: Text(
                    document.documentType,
                    style:
                    const TextStyle(
                      fontSize: 12,
                      color:
                      Color(
                        0xFF6B7280,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: Text(
                    document.department,
                    style:
                    const TextStyle(
                      fontSize: 12,
                      color:
                      Color(
                        0xFF6B7280,
                      ),
                    ),
                  ),
                ),

                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(
                      0xFFFFF3DF,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      20,
                    ),
                  ),
                  child: const Text(
                    'Pending HOD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                      FontWeight.w800,
                      color:
                      Color(
                        0xFFE67E00,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 15,
                ),

                const Icon(
                  Icons
                      .chevron_right_rounded,
                  color:
                  Color(0xFF9AA2B1),
                ),
                  ],
                ),
              ),
          );
            },
      ),
    );
  }

  Widget _buildDmrActionCard(
      BuildContext context,
      ) {
    return Material(
      color: Colors.white,
      borderRadius:
      BorderRadius.circular(18),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(18),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
              const HodDmrRequestsScreen(),
            ),
          );

          await _loadDashboardData();
        },
        child: Container(
          width: double.infinity,
          padding:
          const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(18),
            border: Border.all(
              color:
              const Color(0xFFE4E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration:
                BoxDecoration(
                  color:
                  const Color(0xFFF2E8FF),
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
                child: const Icon(
                  Icons.edit_document,
                  color:
                  Color(0xFF9C27B0),
                  size: 26,
                ),
              ),

              const SizedBox(
                width: 16,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DMR / Edit Requests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w800,
                        color:
                        Color(0xFF172033),
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      _pendingDmrCount == 0
                          ? 'No modification requests pending.'
                          : '$_pendingDmrCount modification request(s) waiting for your approval.',
                      style: const TextStyle(
                        fontSize: 12,
                        color:
                        Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons
                    .arrow_forward_ios_rounded,
                size: 17,
                color:
                Color(0xFF9AA2B1),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildRecentActivity() {
    final activities =
    _activities.take(10).toList();

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF172033),
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Recent actions performed by you.',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),

        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE4E8F0),
            ),
          ),
          child: activities.isEmpty
              ? const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 42,
                    color:
                    Color(0xFF9AA2B1),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No activity yet',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                      FontWeight.w700,
                      color:
                      Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
          )
              : ListView.separated(
            shrinkWrap: true,
            physics:
            const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (_, _) =>
            const Divider(
              height: 1,
            ),
            itemBuilder:
                (context, index) {
              final activity =
              activities[index];

              return ListTile(
                contentPadding:
                const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 7,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(
                      0xFFEFF3FF,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      11,
                    ),
                  ),
                  child: const Icon(
                    Icons
                        .history_rounded,
                    size: 20,
                    color:
                    Color(
                      0xFF3155D9,
                    ),
                  ),
                ),
                title: Text(
                  activity.description,
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(
                      0xFF172033,
                    ),
                  ),
                ),
                subtitle: Padding(
                  padding:
                  const EdgeInsets.only(
                    top: 4,
                  ),
                  child: Text(
                    activity.documentNo
                        .isEmpty
                        ? activity.action
                        : '${activity.action} • ${activity.documentNo}',
                    style:
                    const TextStyle(
                      fontSize: 11,
                      color:
                      Color(
                        0xFF6B7280,
                      ),
                    ),
                  ),
                ),
                trailing: Text(
                  _formatActivityTime(
                    activity.timestamp,
                  ),
                  style:
                  const TextStyle(
                    fontSize: 10,
                    color:
                    Color(
                      0xFF9AA2B1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatActivityTime(
      DateTime time,
      ) {
    final day =
    time.day.toString().padLeft(2, '0');

    final month =
    time.month.toString().padLeft(2, '0');

    final hour =
    time.hour.toString().padLeft(2, '0');

    final minute =
    time.minute.toString().padLeft(2, '0');

    return '$day/$month $hour:$minute';
  }
}