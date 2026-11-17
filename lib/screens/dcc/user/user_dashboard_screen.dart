import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/dcc/dcc_activity.dart';
import '../../../services/dcc/dcc_activity_service.dart';
import '../../../services/dcc/dcc_document_service.dart';
import '../../../services/dcc/dcc_dmr_service.dart';
import '../../../services/dcc/dcc_session.dart';

import 'new_document_screen.dart';
import 'my_documents_screen.dart';
import 'dmr_request_screen.dart';
import 'dmr_history_screen.dart';
import 'user_dmr_requests_screen.dart';
import 'released_documents_screen.dart';
import '../widgets/dcc_notification_bell.dart';
import 'user_dmr_requests_screen.dart';
import 'request_document_screen.dart';
import '../../../widgets/logout_button.dart';
import '../../../widgets/dcc_change_password_dialog.dart';
class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() =>
      _UserDashboardScreenState();
}

class _UserDashboardScreenState
    extends State<UserDashboardScreen> {
  List<DccActivity> _activities = [];

  int _pendingHodCount = 0;
  int _dccReviewCount = 0;
  int _releasedCount = 0;
  int _dmrRequestCount = 0;
  int _dmrEditAccessCount = 0;

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
    final user = DccSession.currentUser;

    if (user == null) {
      return;
    }

    if (showRefreshIndicator && mounted) {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      final activities =
      await DccActivityService.getActivitiesForUser(
        user.email,
      );

      final documents =
      await DccDocumentService.getDocumentsByUser(
        user.email,
      );

      final dmrRequests =
      await DccDmrService.getRequestsByUser(
        user.email,
      );

      int pendingHod = 0;
      int dccReview = 0;
      int released = 0;

      for (final document in documents) {
        switch (document.status) {
          case 'PENDING_HOD':
            pendingHod++;
            break;

          case 'PENDING_DCC':
          case 'DCC_REVIEW':
            dccReview++;
            break;

          case 'RELEASED':
            released++;
            break;
        }
      }

      int dmrCount = 0;
      int dmrEditAccessCount = 0;

      for (final request in dmrRequests) {
        if (request.status == 'PENDING_HOD' ||
            request.status == 'PENDING_DCC' ||
            request.status == 'EDIT_ACCESS_GRANTED') {
          dmrCount++;
        }

        if (request.status == 'EDIT_ACCESS_GRANTED' &&
            request.modificationAccessGranted) {
          dmrEditAccessCount++;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _activities = activities;

        _pendingHodCount = pendingHod;
        _dccReviewCount = dccReview;
        _releasedCount = released;

        _dmrRequestCount = dmrCount;
        _dmrEditAccessCount = dmrEditAccessCount;

        _isRefreshing = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isRefreshing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to refresh dashboard data.',
          ),
        ),
      );
    }
  }
  Future<void> _openNewDocument() async {
    final updated = await Navigator.pushNamed(
      context,
      '/DCC/user/newDocument',
    );

    if (updated == true) {
      await _loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'User Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
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
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Icon(
              Icons.refresh_rounded,
            ),
            tooltip: 'Refresh dashboard',
          ),

          const DccNotificationBell(),

          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Change Password',
            icon: const Icon(Icons.lock_reset_rounded),
            onPressed: () {
              DccChangePasswordDialog.show(context);
            },
          ),
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

          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),

            const SizedBox(height: 5),

            Text(
              DccSession.currentUser?.name ?? 'User',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF172033),
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'Document Management',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Create documents, track approvals and manage modification requests.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    title: 'Pending HOD',
                    value: '$_pendingHodCount',
                    icon: Icons.pending_actions_rounded,
                    iconColor: Colors.orange,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: _summaryCard(
                    title: 'DCC Review',
                    value: '$_dccReviewCount',
                    icon: Icons.fact_check_outlined,
                    iconColor: Colors.blue,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: _summaryCard(
                    title: 'Released',
                    value: '$_releasedCount',
                    icon: Icons.verified_outlined,
                    iconColor: Colors.green,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: _summaryCard(
                    title: 'DMR Requests',
                    value: '$_dmrRequestCount',
                    icon: Icons.edit_document,
                    iconColor: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            const Text(
              'Document Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF172033),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _actionCard(
                    context: context,
                    title: 'New Document',
                    subtitle:
                    'Upload a Word or Excel document and submit it for HOD approval.',
                    icon: Icons.note_add_outlined,
                    iconColor: const Color(0xFF3155D9),
                    onTap: () {
                      _openNewDocument();
                    },
                  ),
                ),
                const SizedBox(width: 18),

                Expanded(
                  child: _actionCard(
                    context: context,
                    title: 'Request New Document',
                    subtitle:
                    "Ask DCC to prepare a document that isn't in the system yet.",
                    icon: Icons.playlist_add_outlined,
                    iconColor: Colors.deepPurple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const RequestDocumentScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 18),

                Expanded(
                  child: _actionCard(
                    context: context,
                    title: 'My Documents',
                    subtitle:
                    'View documents created and submitted by you.',
                    icon: Icons.folder_open_outlined,
                    iconColor: Colors.teal,
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        '/DCC/user/myDocuments',
                      );

                      await _loadDashboardData();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _actionCard(
                    context: context,
                    title: 'DMR / Edit Request',
                    subtitle:
                    'Request modification access for an existing released document.',
                    icon: Icons.edit_note_rounded,
                    iconColor: Colors.purple,
                    onTap: () async {
                      final updated = await Navigator.pushNamed(
                        context,
                        '/DCC/user/dmrRequest',
                      );

                      if (updated == true) {
                        await _loadDashboardData();
                      }
                    },
                  ),
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: _actionCard(
                    context: context,
                    title: 'DMR History',
                    subtitle:
                    'View your modification requests, approvals and rejection reasons.',
                    icon: Icons.history_rounded,
                    iconColor: Colors.indigo,
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        '/DCC/user/dmrHistory',
                      );

                      await _loadDashboardData();
                    },
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: _actionCard(
                    context: context,
                    title: 'DMR / Edit Access',
                    subtitle:
                    'Open documents approved by DCC for modification.',
                    icon: Icons.lock_open_outlined,
                    iconColor: Colors.green,
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        '/DCC/user/dmrRequestsList',
                      );

                      await _loadDashboardData();
                    },
                  ),
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: _actionCard(
                    context: context,
                    title: 'Released Documents',
                    subtitle:
                    'View documents released by DCC.',
                    icon: Icons.picture_as_pdf_outlined,
                    iconColor: Colors.redAccent,
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        '/DCC/user/releasedDocuments',
                      );

                      await _loadDashboardData();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            _recentActivityCard(),
          ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE4E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF172033),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 150,
          ),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE4E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 27,
                ),
              ),

              const SizedBox(width: 17),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172033),
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Row(
                      children: [
                        Text(
                          'Open',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3155D9),
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: Color(0xFF3155D9),
                        ),
                      ],
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

  Widget _recentActivityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE4E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172033),
            ),
          ),

          const SizedBox(height: 18),

          if (_activities.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 28,
                horizontal: 20,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 34,
                    color: Color(0xFF9AA2B1),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No recent activity',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your document activities will appear here.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9AA2B1),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _activities
                  .take(8)
                  .map(
                    (activity) =>
                    _activityItem(activity),
              )
                  .toList(),
            ),
        ],
      ),
    );
  }
  Widget _activityItem(
      DccActivity activity,
      ) {
    final time =
        '${activity.timestamp.day.toString().padLeft(2, '0')}/'
        '${activity.timestamp.month.toString().padLeft(2, '0')}/'
        '${activity.timestamp.year} '
        '${activity.timestamp.hour.toString().padLeft(2, '0')}:'
        '${activity.timestamp.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3FF),
              borderRadius:
              BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 20,
              color: Color(0xFF3155D9),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF172033),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A93A3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}