import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/ccr/ccr_auth_service.dart';
import '../../services/ccr/ccr_session.dart';
import 'ccr_admin_records_screen.dart';
import 'ccr_team_management_screen.dart';

class CcrAdminDashboardScreen
    extends StatefulWidget {
  const CcrAdminDashboardScreen({
    super.key,
  });

  @override
  State<CcrAdminDashboardScreen> createState() =>
      _CcrAdminDashboardScreenState();
}

class _CcrAdminDashboardScreenState
    extends State<CcrAdminDashboardScreen> {
  Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();

    _startSessionMonitor();
  }

  void _startSessionMonitor() {
    _sessionTimer =
        Timer.periodic(
          const Duration(minutes: 1),
              (_) async {
            await _checkSession();
          },
        );
  }

  Future<void> _checkSession() async {
    if (!CcrSession.isLoggedIn) {
      _logoutToLogin();
      return;
    }

    if (CcrSession.isExpired) {
      await CcrSession.clear();

      if (!mounted) return;

      _showMessage(
        'Your CCR session expired after 15 minutes of inactivity.',
      );

      _logoutToLogin();
    }
  }

  Future<void> _logoutToLogin() async {
    _sessionTimer?.cancel();

    await CcrAuthService.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/CCR/login',
          (_) => false,
    );
  }

  Future<void> _changePassword() async {
    final currentController =
    TextEditingController();

    final newController =
    TextEditingController();

    final confirmController =
    TextEditingController();

    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
              context,
              setDialogState,
              ) {
            Future<void> save() async {
              final current =
              currentController.text
                  .trim();

              final next =
              newController.text
                  .trim();

              final confirm =
              confirmController.text
                  .trim();

              if (current.isEmpty ||
                  next.isEmpty ||
                  confirm.isEmpty) {
                _showMessage(
                  'All password fields are required.',
                );
                return;
              }

              if (next != confirm) {
                _showMessage(
                  'New passwords do not match.',
                );
                return;
              }

              setDialogState(() {
                saving = true;
              });

              try {
                await CcrAuthService
                    .changePassword(
                  currentPassword:
                  current,
                  newPassword:
                  next,
                );

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                );

                _showMessage(
                  'Password changed successfully.',
                );
              } catch (e) {
                _showMessage(
                  e.toString()
                      .replaceFirst(
                    'Exception: ',
                    '',
                  ),
                );
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() {
                    saving = false;
                  });
                }
              }
            }

            return AlertDialog(
              title:
              const Text(
                'Change Password',
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    TextField(
                      controller:
                      currentController,
                      obscureText: true,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Current password',
                        border:
                        OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller:
                      newController,
                      obscureText: true,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'New password',
                        border:
                        OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller:
                      confirmController,
                      obscureText: true,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Confirm new password',
                        border:
                        OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                  saving
                      ? null
                      : () =>
                      Navigator.pop(
                        dialogContext,
                      ),
                  child:
                  const Text('Cancel'),
                ),
                FilledButton(
                  onPressed:
                  saving ? null : save,
                  child: saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Change Password',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
  }

  void _showMessage(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final user =
        CcrSession.currentUser;

    return Listener(
      behavior:
      HitTestBehavior.translucent,
      onPointerDown: (_) {
        CcrSession.touch();
      },
      onPointerMove: (_) {
        CcrSession.touch();
      },
      child: Scaffold(
        backgroundColor:
        const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: const Text(
            'CCR Admin Dashboard',
          ),
          actions: [
            IconButton(
              tooltip:
              'Change Password',
              onPressed:
              _changePassword,
              icon: const Icon(
                Icons.password_outlined,
              ),
            ),
            IconButton(
              tooltip: 'Logout',
              onPressed:
              _logoutToLogin,
              icon: const Icon(
                Icons.logout,
              ),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 1200,
            ),
            child: Padding(
              padding:
              const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${user?.fullName ?? 'Admin'}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      color:
                      Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(
                    height: 28,
                  ),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount:
                      MediaQuery.of(
                        context,
                      ).size.width >
                          900
                          ? 3
                          : 1,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                      childAspectRatio:
                      1.65,
                      children: [
                        _buildCard(
                          icon:
                          Icons
                              .assignment_outlined,
                          title:
                          'CCR Records',
                          subtitle:
                          'View and permanently delete CCR records.',
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const CcrAdminRecordsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildCard(
                          icon:
                          Icons.groups_outlined,
                          title:
                          'Team Management',
                          subtitle:
                          'Create, edit, activate and delete CCR teams.',
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const CcrTeamManagementScreen(
                                  adminOnly: true,
                                ),
                              ),
                            );
                          },
                        ),
                        _buildCard(
                          icon:
                          Icons
                              .manage_accounts_outlined,
                          title:
                          'User Management',
                          subtitle:
                          'Manage CCR users and access.',
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/CCR/admin/users',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding:
          const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 34,
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color:
                  Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}