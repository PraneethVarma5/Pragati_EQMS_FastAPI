import 'package:flutter/material.dart';

import '../../services/ncr/ncr_admin_service.dart';
import '../../services/ncr/ncr_auth_service.dart';
import '../../services/ncr/ncr_session.dart';
import 'ncr_create_screen.dart';
import 'ncr_user_management_screen.dart';
import 'ncr_admin_records_screen.dart';
class NcrAdminDashboardScreen
    extends StatefulWidget {
  const NcrAdminDashboardScreen({
    super.key,
  });

  @override
  State<NcrAdminDashboardScreen>
  createState() =>
      _NcrAdminDashboardScreenState();
}

class _NcrAdminDashboardScreenState
    extends State<NcrAdminDashboardScreen> {
  NcrAdminDashboardData?
  _dashboardData;

  bool _isLoading = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  // ============================================================
  // LOAD
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
      await NcrAdminService
          .getDashboardData();

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
        _errorMessage = e
            .toString()
            .replaceFirst(
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
  // OPEN NEW NCR
  // ============================================================

  Future<void> _openNewNcr() async {
    final result =
    await Navigator.push(
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
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user =
        NcrSession.currentUser;

    if (user == null ||
        !NcrSession.isAdmin) {
      WidgetsBinding.instance
          .addPostFrameCallback(
            (_) {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/NCR/login',
            );
          }
        },
      );

      return const Scaffold(
        body: Center(
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
        Colors.white,
        surfaceTintColor:
        Colors.white,

        leading: IconButton(
          tooltip: 'NCR Home',
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
          'NCR Admin Dashboard',
          style: TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),

        actions: [
          Container(
            margin:
            const EdgeInsets
                .symmetric(
              vertical: 11,
            ),
            padding:
            const EdgeInsets
                .symmetric(
              horizontal: 14,
            ),
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFFEAF0FF,
              ),
              borderRadius:
              BorderRadius.circular(
                20,
              ),
            ),
            child: Center(
              child: Text(
                user.roleName
                    .trim()
                    .isEmpty
                    ? 'ADMIN'
                    : user.roleName,
                style:
                const TextStyle(
                  fontWeight:
                  FontWeight.w700,
                  color:
                  Color(
                    0xFF3155D9,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh,
            ),
            onPressed:
            _isLoading
                ? null
                : _loadDashboard,
          ),

          IconButton(
            tooltip: 'Logout',
            icon: const Icon(
              Icons.logout,
            ),
            onPressed: _logout,
          ),

          const SizedBox(
            width: 8,
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh:
        _loadDashboard,
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
              // ==================================================
              // HEADER
              // ==================================================

              Text(
                'Welcome, ${user.fullName}',
                style:
                const TextStyle(
                  fontSize: 28,
                  fontWeight:
                  FontWeight.w800,
                  color:
                  Color(0xFF172033),
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                user.email,
                style:
                TextStyle(
                  fontSize: 14,
                  color:
                  Colors.grey
                      .shade600,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              const Text(
                'Administrator',
                style:
                TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w600,
                  color:
                  Color(0xFF3155D9),
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              if (_errorMessage !=
                  null)
                _errorCard(),

              // ==================================================
              // OVERVIEW
              // ==================================================

              const Text(
                'NCR Overview',
                style:
                TextStyle(
                  fontSize: 21,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              LayoutBuilder(
                builder:
                    (
                    context,
                    constraints,
                    ) {
                  final width =
                      constraints
                          .maxWidth;

                  final cardWidth =
                  width >= 1100
                      ? (width - 48) /
                      4
                      : width >= 700
                      ? (width - 16) /
                      2
                      : width;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _stat(
                        width:
                        cardWidth,
                        title:
                        'Total NCRs',
                        value:
                        _dashboardData
                            ?.totalNcrs,
                        icon:
                        Icons
                            .assignment_outlined,
                        description:
                        'All NCR records',
                      ),
                      _stat(
                        width:
                        cardWidth,
                        title:
                        'In Progress',
                        value:
                        _dashboardData
                            ?.inProgress,
                        icon:
                        Icons
                            .pending_actions,
                        description:
                        'Active workflow',
                      ),
                      _stat(
                        width:
                        cardWidth,
                        title:
                        'Pending HOD',
                        value:
                        _dashboardData
                            ?.pendingHod,
                        icon:
                        Icons
                            .fact_check_outlined,
                        description:
                        'Awaiting HOD',
                      ),
                      _stat(
                        width:
                        cardWidth,
                        title:
                        'Pending DCC',
                        value:
                        _dashboardData
                            ?.pendingDcc,
                        icon:
                        Icons
                            .approval_outlined,
                        description:
                        'Awaiting DCC',
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(
                height: 16,
              ),

              _closedCard(),

              const SizedBox(
                height: 34,
              ),

              // ==================================================
              // ADMIN ACTIONS
              // ==================================================

              const Text(
                'Administrator Actions',
                style:
                TextStyle(
                  fontSize: 21,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              LayoutBuilder(
                builder:
                    (
                    context,
                    constraints,
                    ) {
                  final width =
                      constraints
                          .maxWidth;

                  final cardWidth =
                  width >= 1000
                      ? (width - 32) /
                      3
                      : width >= 650
                      ? (width - 16) /
                      2
                      : width;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _action(
                        width:
                        cardWidth,
                        title:
                        'Raise New NCR',
                        description:
                        'Create a Non-Conformance Report and assign the responsible NCR user.',
                        icon:
                        Icons
                            .add_task,
                        onTap:
                        _openNewNcr,
                      ),
                      _action(
                        width:
                        cardWidth,
                        title:
                        'NCR User Management',
                        description:
                        'Create, edit, activate, deactivate and manage NCR users and roles.',
                        icon:
                        Icons
                            .manage_accounts_outlined,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                              const NcrUserManagementScreen(),
                            ),
                          );

                          if (mounted) {
                            await _loadDashboard();
                          }
                        },
                      ),
                      _action(
                        width:
                        cardWidth,
                        title:
                        'NCR Records',
                        description:
                        'Central area for viewing all NCR records and workflow progress.',
                        icon:
                        Icons
                            .folder_open_outlined,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const NcrAdminRecordsScreen(),
                            ),
                          );

                          if (mounted) {
                            await _loadDashboard();
                          }
                        },
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(
                height: 34,
              ),

              // ==================================================
              // ROLE RESPONSIBILITY
              // ==================================================

              _informationCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STAT
  // ============================================================

  Widget _stat({
    required double width,
    required String title,
    required int? value,
    required IconData icon,
    required String description,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        height: 145,
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
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xFFEFF3FF,
                ),
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
              ),
              child: Icon(
                icon,
                color:
                const Color(
                  0xFF3155D9,
                ),
                size: 27,
              ),
            ),
            const SizedBox(
              width: 16,
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
                    style:
                    TextStyle(
                      fontSize: 14,
                      color: Colors
                          .grey
                          .shade600,
                    ),
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  _isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                    CircularProgressIndicator(
                      strokeWidth:
                      2.5,
                    ),
                  )
                      : Text(
                    '${value ?? 0}',
                    style:
                    const TextStyle(
                      fontSize: 30,
                      fontWeight:
                      FontWeight
                          .w800,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    description,
                    style:
                    TextStyle(
                      fontSize: 12,
                      color: Colors
                          .grey
                          .shade500,
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
  // CLOSED
  // ============================================================

  Widget _closedCard() {
    return Container(
      width: double.infinity,
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
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration:
            BoxDecoration(
              color:
              Colors.green.shade50,
              borderRadius:
              BorderRadius.circular(
                14,
              ),
            ),
            child: Icon(
              Icons
                  .check_circle_outline,
              color:
              Colors.green.shade700,
              size: 27,
            ),
          ),
          const SizedBox(
            width: 16,
          ),
          const Text(
            'Closed NCRs',
            style:
            TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.w700,
            ),
          ),
          const Spacer(),
          _isLoading
              ? const SizedBox(
            width: 22,
            height: 22,
            child:
            CircularProgressIndicator(
              strokeWidth: 2.5,
            ),
          )
              : Text(
            '${_dashboardData?.closed ?? 0}',
            style:
            const TextStyle(
              fontSize: 28,
              fontWeight:
              FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION
  // ============================================================

  Widget _action({
    required double width,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        child: InkWell(
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          onTap: onTap,
          child: Container(
            constraints:
            const BoxConstraints(
              minHeight: 175,
            ),
            padding:
            const EdgeInsets.all(
              22,
            ),
            decoration:
            BoxDecoration(
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
                    const Color(
                      0xFFEFF3FF,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      14,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color:
                    const Color(
                      0xFF3155D9,
                    ),
                    size: 26,
                  ),
                ),
                const SizedBox(
                  height: 17,
                ),
                Text(
                  title,
                  style:
                  const TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 7,
                ),
                Text(
                  description,
                  style:
                  TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors
                        .grey
                        .shade600,
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                const Align(
                  alignment:
                  Alignment.centerRight,
                  child: Row(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      Text(
                        'Open',
                        style:
                        TextStyle(
                          fontWeight:
                          FontWeight.w700,
                          color:
                          Color(
                            0xFF3155D9,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: 17,
                        color:
                        Color(
                          0xFF3155D9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATION
  // ============================================================

  Widget _informationCard() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        22,
      ),
      decoration:
      BoxDecoration(
        color:
        const Color(
          0xFFEFF7FF,
        ),
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color:
          const Color(
            0xFFD7E9FA,
          ),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,
        children: [
          Icon(
            Icons
                .admin_panel_settings_outlined,
            size: 28,
            color:
            Color(0xFF3155D9),
          ),
          SizedBox(
            width: 15,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  'Administrator Access',
                  style:
                  TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                SizedBox(
                  height: 6,
                ),
                Text(
                  'The NCR Admin creates NCRs, assigns auditees and auditors, manages NCR users and oversees the complete NCR workflow.',
                  style:
                  TextStyle(
                    fontSize: 13,
                    height: 1.45,
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
  // ERROR
  // ============================================================

  Widget _errorCard() {
    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(
        bottom: 25,
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
            child: Text(
              _errorMessage ??
                  'Unable to load dashboard.',
              style:
              TextStyle(
                color:
                Colors.red.shade800,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed:
            _loadDashboard,
            child:
            const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
  }
}