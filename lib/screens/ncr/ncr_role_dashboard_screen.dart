import 'package:flutter/material.dart';

import '../../services/ncr/ncr_admin_service.dart';
import '../../services/ncr/ncr_auth_service.dart';
import '../../services/ncr/ncr_session.dart';
import 'ncr_user_management_screen.dart';
import 'ncr_create_screen.dart';


class NcrRoleDashboardScreen extends StatefulWidget {
  const NcrRoleDashboardScreen({super.key});

  @override
  State<NcrRoleDashboardScreen> createState() =>
      _NcrRoleDashboardScreenState();
}

class _NcrRoleDashboardScreenState
    extends State<NcrRoleDashboardScreen> {
  NcrAdminDashboardData? _dashboardData;

  bool _isLoading = true;
  String? _errorMessage;

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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data =
      await NcrAdminService.getDashboardData();

      if (!mounted) {
        return;
      }

      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
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

  // ============================================================
  // NAVIGATION HELPER
  // ============================================================

  void _openComingSoon(String title) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$title will be connected in the next step.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final user = NcrSession.currentUser;

    if (user == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/NCR/login',
          );
        }
      });

      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FA),

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,

        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back,
          ),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/NCR',
                  (route) => false,
            );
          },
        ),

        title: const Text(
          'NCR Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),

        actions: [
          // --------------------------------------------------------
          // ROLE
          // --------------------------------------------------------

          Container(
            margin:
            const EdgeInsets.symmetric(
              vertical: 12,
            ),
            padding:
            const EdgeInsets.symmetric(
              horizontal: 14,
            ),
            decoration: BoxDecoration(
              color:
              const Color(0xFFEAF0FF),
              borderRadius:
              BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                user.roleName.isEmpty
                    ? user.roleKey.toUpperCase()
                    : user.roleName,
                style: const TextStyle(
                  fontWeight:
                  FontWeight.w700,
                  color:
                  Color(0xFF3155D9),
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // --------------------------------------------------------
          // CHANGE PASSWORD
          // --------------------------------------------------------

          IconButton(
            tooltip: 'Change Password',
            icon: const Icon(
              Icons.lock_reset_outlined,
            ),
            onPressed: () {
              _openComingSoon(
                'Change Password',
              );
            },
          ),

          // --------------------------------------------------------
          // LOGOUT
          // --------------------------------------------------------

          IconButton(
            tooltip: 'Logout',
            icon: const Icon(
              Icons.logout,
            ),
            onPressed: _logout,
          ),

          const SizedBox(width: 8),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // ====================================================
              // HEADER
              // ====================================================

              Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${user.fullName}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight:
                            FontWeight.w800,
                            color:
                            Color(0xFF172033),
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                            Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          user.roleName.isEmpty
                              ? user.roleKey
                              .toUpperCase()
                              : user.roleName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight:
                            FontWeight.w600,
                            color:
                            Color(0xFF3155D9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ------------------------------------------------
                  // REFRESH
                  // ------------------------------------------------

                  OutlinedButton.icon(
                    onPressed:
                    _isLoading
                        ? null
                        : _loadDashboard,
                    icon: const Icon(
                      Icons.refresh,
                      size: 19,
                    ),
                    label:
                    const Text('Refresh'),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ====================================================
              // ERROR
              // ====================================================

              if (_errorMessage != null)
                _errorCard(),

              // ====================================================
              // STATISTICS
              // ====================================================

              const Text(
                'NCR Overview',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 14),

              LayoutBuilder(
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
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _statCard(
                          title: 'Total NCRs',
                          value:
                          _isLoading
                              ? null
                              : _dashboardData
                              ?.totalNcrs
                              .toString(),
                          icon:
                          Icons.assignment_outlined,
                          description:
                          'All NCR records',
                        ),
                      ),

                      SizedBox(
                        width: cardWidth,
                        child: _statCard(
                          title: 'In Progress',
                          value:
                          _isLoading
                              ? null
                              : _dashboardData
                              ?.inProgress
                              .toString(),
                          icon:
                          Icons.pending_actions,
                          description:
                          'Active NCR workflow',
                        ),
                      ),

                      SizedBox(
                        width: cardWidth,
                        child: _statCard(
                          title: 'Pending HOD',
                          value:
                          _isLoading
                              ? null
                              : _dashboardData
                              ?.pendingHod
                              .toString(),
                          icon:
                          Icons.fact_check_outlined,
                          description:
                          'Awaiting HOD review',
                        ),
                      ),

                      SizedBox(
                        width: cardWidth,
                        child: _statCard(
                          title: 'Pending DCC',
                          value:
                          _isLoading
                              ? null
                              : _dashboardData
                              ?.pendingDcc
                              .toString(),
                          icon:
                          Icons.approval_outlined,
                          description:
                          'Awaiting DCC review',
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              // ====================================================
              // CLOSED CARD
              // ====================================================

              SizedBox(
                width: double.infinity,
                child: _closedCard(),
              ),

              const SizedBox(height: 34),

              // ====================================================
              // ADMIN ACTIONS
              // ====================================================

              const Text(
                'Admin Actions',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 14),

              LayoutBuilder(
                builder:
                    (context, constraints) {
                  final width =
                      constraints.maxWidth;

                  final cardWidth =
                  width >= 1000
                      ? (width - 32) / 3
                      : width >= 650
                      ? (width - 16) / 2
                      : width;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _actionCard(
                          title: 'Raise New NCR',
                          description:
                          'Create a new Non-Conformance Report and assign it to an NCR user.',
                          icon:
                          Icons.add_task,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const NcrCreateScreen(),
                              ),
                            );

                            if (!mounted) {
                              return;
                            }

                            if (result != null) {
                              await _loadDashboard();
                            }
                          },
                        ),
                      ),

                      SizedBox(
                        width: cardWidth,
                        child: _actionCard(
                          title: 'NCR Records',
                          description:
                          'View and manage all NCR records and their current workflow status.',
                          icon:
                          Icons.folder_open_outlined,
                          onTap: () {
                            _openComingSoon(
                              'NCR Records',
                            );
                          },
                        ),
                      ),

                      SizedBox(
                        width: cardWidth,
                        child: _actionCard(
                          title: 'NCR User Management',
                          description:
                          'Add NCR users and assign their Admin, User, HOD or DCC roles.',
                          icon:
                          Icons.manage_accounts_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const NcrUserManagementScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 34),

              // ====================================================
              // ADMIN INFORMATION
              // ====================================================

              _adminInformation(user),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // STAT CARD
  // ==============================================================

  Widget _statCard({
    required String title,
    required String? value,
    required IconData icon,
    required String description,
  }) {
    return Container(
      height: 145,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xFFE2E7EF),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(
              0.035,
            ),
            blurRadius: 14,
            offset:
            const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color:
              const Color(0xFFEFF3FF),
              borderRadius:
              BorderRadius.circular(
                14,
              ),
            ),
            child: Icon(
              icon,
              size: 27,
              color:
              const Color(0xFF3155D9),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                    Colors.grey.shade600,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 6),

                if (value == null)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2.5,
                    ),
                  )
                else
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight:
                      FontWeight.w800,
                      color:
                      Color(0xFF172033),
                    ),
                  ),

                const SizedBox(height: 3),

                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                    Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // CLOSED CARD
  // ==============================================================

  Widget _closedCard() {
    final value =
    _isLoading
        ? null
        : _dashboardData
        ?.closed
        .toString();

    return Container(
      padding:
      const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xFFE2E7EF),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(
              0.025,
            ),
            blurRadius: 12,
            offset:
            const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color:
              Colors.green.shade50,
              borderRadius:
              BorderRadius.circular(
                14,
              ),
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 27,
              color:
              Colors.green.shade700,
            ),
          ),

          const SizedBox(width: 16),

          const Text(
            'Closed NCRs',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.w700,
            ),
          ),

          const Spacer(),

          if (value == null)
            const SizedBox(
              width: 23,
              height: 23,
              child:
              CircularProgressIndicator(
                strokeWidth: 2.5,
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight:
                FontWeight.w800,
                color:
                Color(0xFF172033),
              ),
            ),
        ],
      ),
    );
  }

  // ==============================================================
  // ACTION CARD
  // ==============================================================

  Widget _actionCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius:
      BorderRadius.circular(16),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          constraints:
          const BoxConstraints(
            minHeight: 170,
            maxHeight: 220,
          ),
          padding:
          const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(16),
            border: Border.all(
              color:
              const Color(0xFFE2E7EF),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3FF),
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF3155D9),
                  size: 26,
                ),
              ),

              const SizedBox(height: 17),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 7),

              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 18),

              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Open',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3155D9),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.arrow_forward,
                      size: 17,
                      color: Color(0xFF3155D9),
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

  // ==============================================================
  // ADMIN INFORMATION
  // ==============================================================

  Widget _adminInformation(dynamic user) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color:
        const Color(0xFFEFF7FF),
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xFFD7E9FA),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.admin_panel_settings_outlined,
            size: 28,
            color:
            Color(0xFF3155D9),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Administrator Access',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'You are logged in as ${user.roleName.isEmpty ? user.roleKey : user.roleName}. '
                      'Admin users can create NCRs, manage NCR users and view all NCR records.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color:
                    Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // ERROR CARD
  // ==============================================================

  Widget _errorCard() {
    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(bottom: 25),
      padding:
      const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
        Colors.red.shade50,
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color:
          Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color:
            Colors.red.shade700,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              _errorMessage ??
                  'Unable to load NCR dashboard.',
              style: TextStyle(
                color:
                Colors.red.shade800,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),

          TextButton(
            onPressed: _loadDashboard,
            child:
            const Text('Retry'),
          ),
        ],
      ),
    );
  }
}