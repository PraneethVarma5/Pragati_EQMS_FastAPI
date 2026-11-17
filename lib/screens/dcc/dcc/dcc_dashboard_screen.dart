import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/dcc/dcc_activity.dart';
import '../../../models/dcc/dcc_document.dart';
import '../../../models/dcc/dcc_dmr_request.dart';

import '../../../services/dcc/dcc_activity_service.dart';
import '../../../services/dcc/dcc_document_service.dart';
import '../../../services/dcc/dcc_dmr_service.dart';
import '../../../services/dcc/dcc_session.dart';

import '../widgets/dcc_notification_bell.dart';
import 'dcc_pending_documents_screen.dart';
import 'dcc_released_documents_screen.dart';
import 'dcc_dmr_requests_screen.dart';
import 'dcc_document_requests_screen.dart';
import '../dcc_document_control_screen.dart';
import '../../../widgets/logout_button.dart';
import '../../../widgets/dcc_change_password_dialog.dart';
class DccDashboardScreen extends StatefulWidget {
  const DccDashboardScreen({
    super.key,
  });

  @override
  State<DccDashboardScreen> createState() =>
      _DccDashboardScreenState();
}

class _DccDashboardScreenState
    extends State<DccDashboardScreen> {
  List<DccDocument> _documents = [];
  List<DccDmrRequest> _dmrRequests = [];
  List<DccActivity> _activities = [];

  bool _isLoading = true;
  bool _isRefreshing = false;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    _loadDashboardData();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) {
        _loadDashboardData();
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData({
    bool showRefreshIndicator = false,
  }) async {
    final user =
        DccSession.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      return;
    }

    if (showRefreshIndicator &&
        mounted) {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      // IMPORTANT:
      // DCC sees ALL documents.
      final documents =
      await DccDocumentService
          .getDocuments();

      // IMPORTANT:
      // All DCC users see the same pending DMR queue.
      final dmrRequests =
      await DccDmrService
          .getPendingDccRequests();

      // Activity is specific to the logged-in DCC.
      final activities =
      await DccActivityService
          .getActivitiesForUser(
        user.email,
      );

      documents.sort(
            (a, b) =>
            b.revisionDate.compareTo(
              a.revisionDate,
            ),
      );

      dmrRequests.sort(
            (a, b) =>
            b.createdDate.compareTo(
              a.createdDate,
            ),
      );

      activities.sort(
            (a, b) =>
            b.timestamp.compareTo(
              a.timestamp,
            ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _documents = documents;
        _dmrRequests = dmrRequests;
        _activities = activities;
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

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load DCC dashboard data.',
          ),
        ),
      );
    }
  }

  int get _pendingDccCount {
    return _documents
        .where(
          (document) =>
      document.status ==
          'PENDING_DCC',
    )
        .length;
  }

  int get _releasedCount {
    return _documents
        .where(
          (document) =>
      document.status ==
          'RELEASED',
    )
        .length;
  }

  int get _rejectedCount {
    return _documents
        .where(
          (document) =>
      document.status ==
          'REJECTED',
    )
        .length;
  }

  int get _totalDocuments {
    return _documents.length;
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final user =
        DccSession.currentUser;

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'DCC Dashboard',
          style: TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),
        backgroundColor:
        Colors.white,
        foregroundColor:
        const Color(0xFF172033),
        elevation: 0,

        actions: [
          IconButton(
            tooltip: 'Change Password',
            icon: const Icon(Icons.lock_reset_rounded),
            onPressed: () {
              DccChangePasswordDialog.show(context);
            },
          ),
          IconButton(
            onPressed:
            _isRefreshing
                ? null
                : () {
              _loadDashboardData(
                showRefreshIndicator:
                true,
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
              Icons
                  .refresh_rounded,
            ),
            tooltip:
            'Refresh dashboard',
          ),

          const DccNotificationBell(),

          const SizedBox(width: 4),

          LogoutButton(
            onConfirmed: () async {
              final user = DccSession.currentUser;

              if (user != null) {
                await DccActivityService.addActivity(
                  DccActivity(
                    id: DateTime.now()
                        .microsecondsSinceEpoch
                        .toString(),
                    userEmail: user.email,
                    userName: user.name,
                    action: 'LOGOUT',
                    description: 'Logged out of eQMS DCC',
                    timestamp: DateTime.now(),
                  ),
                );
              }

              await DccSession.clear();

              if (!context.mounted) return;

              Navigator.of(context).pushNamedAndRemoveUntil(
                '/DCC',
                (route) => false,
              );
            },
          ),

          const SizedBox(
            width: 8,
          ),
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
        child:
        SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.all(
            30,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              const Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w600,
                  color:
                  Color(
                    0xFF6B7280,
                  ),
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                user?.name ??
                    'DCC',
                style:
                const TextStyle(
                  fontSize: 28,
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

              const Text(
                'Document Control Center',
                style:
                TextStyle(
                  fontSize: 17,
                  fontWeight:
                  FontWeight.w600,
                  color:
                  Color(
                    0xFF4B5563,
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),
              const Text(
                'Review, control and release approved documents.',
                style:
                TextStyle(
                  fontSize: 14,
                  color:
                  Color(
                    0xFF6B7280,
                  ),
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              _buildSummaryCards(),

              const SizedBox(
                height: 30,
              ),

              _buildDccActions(),

              const SizedBox(
                height: 30,
              ),

              _buildPendingDocuments(),

              const SizedBox(
                height: 30,
              ),

              _buildPendingDmr(),

              const SizedBox(
                height: 30,
              ),

              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            title: 'Total Documents',
            value:
            '$_totalDocuments',
            icon:
            Icons.folder_outlined,
            iconColor:
            const Color(
              0xFF3155D9,
            ),
          ),
        ),

        const SizedBox(
          width: 16,
        ),

        Expanded(
          child: _summaryCard(
            title: 'Pending DCC',
            value:
            '$_pendingDccCount',
            icon:
            Icons.fact_check_outlined,
            iconColor:
            Colors.orange,
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
            icon:
            Icons.verified_outlined,
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
            icon:
            Icons.cancel_outlined,
            iconColor:
            Colors.red,
          ),
        ),

        const SizedBox(
          width: 16,
        ),

        Expanded(
          child: _summaryCard(
            title: 'DMR',
            value:
            '${_dmrRequests.length}',
            icon:
            Icons.edit_document,
            iconColor:
            Colors.purple,
          ),
        ),
      ],
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
            0xFFE4E8F0,
          ),
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
              iconColor.withValues(
                alpha: 0.10,
              ),
              borderRadius:
              BorderRadius.circular(
                14,
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 27,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  value,
                  style:
                  const TextStyle(
                    fontSize: 24,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Color(
                      0xFF172033,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  title,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 11,
                    color:
                    Color(
                      0xFF6B7280,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDccActions() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'DCC Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight:
            FontWeight.w800,
            color:
            Color(0xFF172033),
          ),
        ),

        const SizedBox(
          height: 16,
        ),

        Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _actionCard(
                title:
                'Pending Documents',
                subtitle:
                'Review documents approved by HOD and waiting for DCC action.',
                icon:
                Icons.fact_check_outlined,
                iconColor:
                Colors.orange,
                onTap: () async {
                  await Navigator.pushNamed(
                    context,
                    '/DCC/dcc/pendingDocuments',
                  );

                  if (mounted) {
                    await _loadDashboardData();
                  }
                },
              ),
            ),

            const SizedBox(
              width: 18,
            ),

            Expanded(
              child: _actionCard(
                title:
                'Released Documents',
                subtitle:
                '$_releasedCount controlled document(s) available for viewing and download.',
                icon:
                Icons.picture_as_pdf_outlined,
                iconColor:
                Colors.redAccent,
                onTap: () async {
                  await Navigator.pushNamed(
                    context,
                    '/DCC/dcc/releasedDocuments',
                  );

                  await _loadDashboardData();
                },
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 18,
        ),

        Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _actionCard(
                title:
                'DMR Requests',
                subtitle:
                'Review modification requests approved by HOD.',
                icon:
                Icons.edit_document,
                iconColor:
                Colors.purple,
                onTap: () async {
                  await Navigator.pushNamed(
                    context,
                    '/DCC/dcc/dmrRequests',
                  );

                  await _loadDashboardData();
                },
              ),
            ),

            const SizedBox(
              width: 18,
            ),

            Expanded(
              child: _actionCard(
                title:
                'Document Requests',
                subtitle:
                'Prepare documents users have asked DCC to create.',
                icon:
                Icons.description_outlined,
                iconColor:
                Colors.blueGrey,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const DccDocumentRequestsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius:
      BorderRadius.circular(
        18,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        child: Container(
          constraints:
          const BoxConstraints(
            minHeight: 155,
          ),
          padding:
          const EdgeInsets.all(
            22,
          ),
          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color:
              const Color(
                0xFFE4E8F0,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration:
                BoxDecoration(
                  color:
                  iconColor.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    13,
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 25,
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              Text(
                title,
                style:
                const TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.w800,
                  color:
                  Color(
                    0xFF172033,
                  ),
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                subtitle,
                maxLines: 3,
                overflow:
                TextOverflow.ellipsis,
                style:
                const TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color:
                  Color(
                    0xFF6B7280,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingDocuments() {
    final pending =
    _documents
        .where(
          (document) =>
      document.status ==
          'PENDING_DCC',
    )
        .toList();

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Pending DCC Review',
          style: TextStyle(
            fontSize: 20,
            fontWeight:
            FontWeight.w800,
            color:
            Color(0xFF172033),
          ),
        ),

        const SizedBox(
          height: 6,
        ),

        const Text(
          'Documents approved by HOD and waiting for DCC processing.',
          style: TextStyle(
            fontSize: 13,
            color:
            Color(0xFF6B7280),
          ),
        ),

        const SizedBox(
          height: 16,
        ),

        Container(
          width: double.infinity,
          decoration:
          BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color:
              const Color(
                0xFFE4E8F0,
              ),
            ),
          ),
          child: pending.isEmpty
              ? const Padding(
            padding:
            EdgeInsets.all(45),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons
                        .assignment_turned_in_outlined,
                    size: 45,
                    color:
                    Color(
                      0xFF9AA2B1,
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    'No documents pending DCC review',
                    style:
                    TextStyle(
                      fontSize: 15,
                      fontWeight:
                      FontWeight
                          .w700,
                      color:
                      Color(
                        0xFF4B5563,
                      ),
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
            itemCount:
            pending.length,
            separatorBuilder:
                (_, _) =>
            const Divider(
              height: 1,
            ),
            itemBuilder:
                (context, index) {
              final document =
              pending[index];

              return ListTile(
                contentPadding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading:
                const Icon(
                  Icons
                      .description_outlined,
                  color:
                  Color(
                    0xFF3155D9,
                  ),
                ),
                title: Text(
                  document
                      .documentNo,
                  style:
                  const TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight
                        .w800,
                  ),
                ),
                subtitle:
                Text(
                  '${document.documentName} • Rev ${document.revision}',
                  maxLines: 1,
                  overflow:
                  TextOverflow
                      .ellipsis,
                ),
                trailing:
                const Icon(
                  Icons
                      .chevron_right_rounded,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPendingDmr() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Pending DMR',
          style: TextStyle(
            fontSize: 20,
            fontWeight:
            FontWeight.w800,
            color:
            Color(0xFF172033),
          ),
        ),

        const SizedBox(
          height: 6,
        ),

        const Text(
          'Modification requests approved by HOD and waiting for DCC action.',
          style: TextStyle(
            fontSize: 13,
            color:
            Color(0xFF6B7280),
          ),
        ),

        const SizedBox(
          height: 16,
        ),

        Container(
          width: double.infinity,
          decoration:
          BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color:
              const Color(
                0xFFE4E8F0,
              ),
            ),
          ),
          child: _dmrRequests.isEmpty
              ? const Padding(
            padding:
            EdgeInsets.all(40),
            child: Center(
              child: Text(
                'No DMR requests pending DCC action.',
                style:
                TextStyle(
                  fontSize: 13,
                  color:
                  Color(
                    0xFF9AA2B1,
                  ),
                ),
              ),
            ),
          )
              : ListView.separated(
            shrinkWrap: true,
            physics:
            const NeverScrollableScrollPhysics(),
            itemCount:
            _dmrRequests.length,
            separatorBuilder:
                (_, _) =>
            const Divider(
              height: 1,
            ),
            itemBuilder:
                (context, index) {
              final request =
              _dmrRequests[
              index];

              return ListTile(
                contentPadding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading:
                const Icon(
                  Icons
                      .edit_document,
                  color:
                  Color(
                    0xFF9C27B0,
                  ),
                ),
                title: Text(
                  request
                      .documentNo,
                  style:
                  const TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight
                        .w800,
                  ),
                ),
                subtitle:
                Text(
                  '${request.requestedByName} • Current Rev ${request.currentRevision} • Next Rev ${request.nextRevision}',
                  maxLines: 1,
                  overflow:
                  TextOverflow
                      .ellipsis,
                ),
                trailing:
                const Icon(
                  Icons
                      .chevron_right_rounded,
                ),
              );
            },
          ),
        ),
      ],
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
            fontWeight:
            FontWeight.w800,
            color:
            Color(0xFF172033),
          ),
        ),

        const SizedBox(
          height: 6,
        ),

        const Text(
          'Recent actions performed by you.',
          style: TextStyle(
            fontSize: 13,
            color:
            Color(0xFF6B7280),
          ),
        ),

        const SizedBox(
          height: 16,
        ),

        Container(
          width: double.infinity,
          decoration:
          BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color:
              const Color(
                0xFFE4E8F0,
              ),
            ),
          ),
          child: activities.isEmpty
              ? const Padding(
            padding:
            EdgeInsets.all(40),
            child: Center(
              child: Text(
                'No activity yet.',
                style:
                TextStyle(
                  fontSize: 13,
                  color:
                  Color(
                    0xFF9AA2B1,
                  ),
                ),
              ),
            ),
          )
              : ListView.separated(
            shrinkWrap: true,
            physics:
            const NeverScrollableScrollPhysics(),
            itemCount:
            activities.length,
            separatorBuilder:
                (_, _) =>
            const Divider(
              height: 1,
            ),
            itemBuilder:
                (context, index) {
              final activity =
              activities[index];

              return ListTile(
                contentPadding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                leading:
                const Icon(
                  Icons
                      .history_rounded,
                  color:
                  Color(
                    0xFF3155D9,
                  ),
                ),
                title: Text(
                  activity
                      .description,
                  maxLines: 2,
                  overflow:
                  TextOverflow
                      .ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight
                        .w700,
                  ),
                ),
                subtitle:
                Text(
                  activity
                      .documentNo
                      .isEmpty
                      ? activity.action
                      : '${activity.action} • ${activity.documentNo}',
                  style:
                  const TextStyle(
                    fontSize: 10,
                    color:
                    Color(
                      0xFF6B7280,
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
}