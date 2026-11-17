import 'package:flutter/material.dart';

import 'add_dcc_user_screen.dart';
import 'user_management_screen.dart';

import '../../../models/dcc/dcc_activity.dart';
import '../../../services/dcc/dcc_activity_service.dart';
import '../../../services/dcc/dcc_session.dart';
import '../../../widgets/logout_button.dart';
import '../../../widgets/dcc_change_password_dialog.dart';

class AdminDccDashboardScreen extends StatelessWidget {
  const AdminDccDashboardScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'DCC Admin Panel',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
        actions: [
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

              if (!context.mounted) {
                return;
              }

              Navigator.of(context).pushNamedAndRemoveUntil(
                '/DCC',
                    (route) => false,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Administration',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF172033),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Manage DCC users, released documents and system access.',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF6B7280),
              ),
            ),

            const SizedBox(height: 30),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _adminCard(
                  icon: Icons.person_add_alt_1_rounded,
                  title: 'Add User',
                  subtitle:
                  'Create a new User, HOD or DCC account',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/DCC/admin/addUser',
                    );
                  },
                ),

                const SizedBox(width: 20),

                _adminCard(
                  icon: Icons.people_alt_outlined,
                  title: 'User Management',
                  subtitle:
                  'View and manage existing accounts',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/DCC/admin/userManagement',
                    );
                  },
                ),

                const SizedBox(width: 20),

                _adminCard(
                  icon: Icons.description_outlined,
                  title: 'Released Documents',
                  subtitle:
                  'View and permanently delete released documents',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/DCC/admin/releasedDocuments',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE4E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF3FF),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF3155D9),
                    size: 28,
                  ),
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF172033),
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7A8292),
                          height: 1.4,
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
}