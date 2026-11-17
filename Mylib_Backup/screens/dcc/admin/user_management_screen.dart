import 'package:flutter/material.dart';
import '../../../models/dcc/dcc_user.dart';
import '../../../services/dcc/dcc_user_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState
    extends State<UserManagementScreen> {
  List<DccUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await DccUserService.getUsers();

    if (!mounted) return;

    setState(() {
      _users = users;
      _loading = false;
    });
  }

  Future<void> _toggleUser(DccUser user) async {
    await DccUserService.setUserActive(
      user.id,
      !user.active,
    );

    await _loadUsers();
  }

  Future<void> _deleteUser(DccUser user) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: Text(
            'Delete the account for ${user.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await DccUserService.deleteUser(user.id);

    await _loadUsers();
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'HOD':
        return Colors.orange;
      case 'DCC':
        return Colors.blue;
      case 'USER':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _users.isEmpty
          ? const Center(
        child: Text(
          'No locally created accounts yet.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadUsers,
        child: ListView.builder(
          padding: const EdgeInsets.all(30),
          itemCount: _users.length,
          itemBuilder: (context, index) {
            final user = _users[index];

            return Container(
              margin: const EdgeInsets.only(
                bottom: 14,
              ),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
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
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFEFF3FF,
                      ),
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: _roleColor(user.role),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight:
                            FontWeight.w800,
                            color:
                            Color(0xFF172033),
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 13,
                            color:
                            Color(0xFF6B7280),
                          ),
                        ),

                        if (user.role == 'USER' &&
                            user.hodName.isNotEmpty)
                          Padding(
                            padding:
                            const EdgeInsets.only(
                              top: 5,
                            ),
                            child: Text(
                              'HOD: ${user.hodName}',
                              style:
                              const TextStyle(
                                fontSize: 12,
                                color: Color(
                                  0xFF7A8292,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _roleColor(user.role)
                          .withOpacity(0.10),
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                        FontWeight.w800,
                        color:
                        _roleColor(user.role),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'toggle') {
                        _toggleUser(user);
                      } else if (value ==
                          'delete') {
                        _deleteUser(user);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(
                          user.active
                              ? 'Disable Account'
                              : 'Enable Account',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete Account',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}