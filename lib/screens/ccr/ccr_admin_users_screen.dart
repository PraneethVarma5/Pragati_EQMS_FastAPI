
import 'package:flutter/material.dart';

import '../../services/ccr/ccr_admin_service.dart';
import '../../services/ccr/ccr_session.dart';

class CcrAdminUsersScreen extends StatefulWidget {
  const CcrAdminUsersScreen({
    super.key,
  });

  @override
  State<CcrAdminUsersScreen> createState() =>
      _CcrAdminUsersScreenState();
}

class _CcrAdminUsersScreenState
    extends State<CcrAdminUsersScreen> {
  bool _loading = true;

  List<Map<String, dynamic>> _users = [];

  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // ============================================================
  // LOAD USERS
  // ============================================================

  Future<void> _loadUsers() async {
    if (!CcrSession.isAdmin) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final rows = await CcrAdminService.getUsers();

      if (!mounted) return;

      setState(() {
        _users = rows;
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // CREATE USER
  // ============================================================

  Future<void> _showCreateUserDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    String role = 'user';
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> createUser() async {
              final name = nameController.text.trim();
              final email =
              emailController.text.trim().toLowerCase();

              if (name.isEmpty || email.isEmpty) {
                _showDialogMessage(
                  dialogContext,
                  'Name and email are required.',
                );
                return;
              }

              if (!email.contains('@')) {
                _showDialogMessage(
                  dialogContext,
                  'Enter a valid email address.',
                );
                return;
              }

              setDialogState(() {
                saving = true;
              });

              try {
                await CcrAdminService.createUser(
                  fullName: name,
                  email: email,
                  role: role,
                );

                if (!dialogContext.mounted) return;

                Navigator.pop(dialogContext);

                await _loadUsers();

                if (!mounted) return;

                _showMessage(
                  'User created successfully. Default password: welcome123',
                );
              } catch (e) {
                if (!dialogContext.mounted) return;

                setDialogState(() {
                  saving = false;
                });

                _showDialogMessage(
                  dialogContext,
                  e.toString().replaceFirst('Exception: ', ''),
                );
              }
            }

            return AlertDialog(
              title: const Text('Add CCR User'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: role,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'user',
                          child: Text('User'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Admin'),
                        ),
                      ],
                      onChanged: saving
                          ? null
                          : (value) {
                        if (value == null) return;

                        setDialogState(() {
                          role = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Initial password: welcome123',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving ? null : createUser,
                  child: saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Create User'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
  }

  // ============================================================
  // ACTIVE / INACTIVE
  // ============================================================

  Future<void> _toggleUser(
      Map<String, dynamic> user,
      ) async {
    final id = user['id']?.toString();

    if (id == null || id.isEmpty) return;

    final current = user['is_active'] == true;

    try {
      await CcrAdminService.setUserActive(
        userId: id,
        isActive: !current,
      );

      await _loadUsers();

      if (!mounted) return;

      _showMessage(
        current
            ? 'User deactivated successfully.'
            : 'User activated successfully.',
      );
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ============================================================
  // DELETE USER
  // ============================================================

  Future<void> _deleteUser(
      Map<String, dynamic> user,
      ) async {
    final id = user['id']?.toString();

    if (id == null || id.isEmpty) return;

    final name = user['full_name']?.toString() ?? 'this user';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: Text(
            'Permanently delete "$name"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await CcrAdminService.deleteUser(
        userId: id,
      );

      await _loadUsers();

      if (!mounted) return;

      _showMessage('User deleted successfully.');
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  List<Map<String, dynamic>> get _filteredUsers {
    final search = _search.trim().toLowerCase();

    if (search.isEmpty) {
      return _users;
    }

    return _users.where((user) {
      final name = user['full_name']
          ?.toString()
          .toLowerCase() ??
          '';

      final email = user['email']
          ?.toString()
          .toLowerCase() ??
          '';

      final role = user['role']
          ?.toString()
          .toLowerCase() ??
          '';

      return name.contains(search) ||
          email.contains(search) ||
          role.contains(search);
    }).toList();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _showDialogMessage(
      BuildContext context,
      String message,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (!CcrSession.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('CCR User Management'),
        ),
        body: const Center(
          child: Text(
            'Only a logged-in CCR Admin can manage users.',
          ),
        ),
      );
    }

    final users = _filteredUsers;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('CCR User Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadUsers,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _search = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed:
                  _loading ? null : _showCreateUserDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add User'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _loading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : users.isEmpty
                  ? const Center(
                child: Text('No users found.'),
              )
                  : Card(
                elevation: 0,
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(
                          label: Text('SNo'),
                        ),
                        DataColumn(
                          label: Text('Name'),
                        ),
                        DataColumn(
                          label: Text('Email'),
                        ),
                        DataColumn(
                          label: Text('Role'),
                        ),
                        DataColumn(
                          label: Text('Status'),
                        ),
                        DataColumn(
                          label: Text('Actions'),
                        ),
                      ],
                      rows: List.generate(
                        users.length,
                            (index) {
                          final user = users[index];
                          final active =
                              user['is_active'] == true;

                          return DataRow(
                            cells: [
                              DataCell(
                                Text('${index + 1}'),
                              ),
                              DataCell(
                                Text(
                                  user['full_name']
                                      ?.toString() ??
                                      '-',
                                ),
                              ),
                              DataCell(
                                Text(
                                  user['email']
                                      ?.toString() ??
                                      '-',
                                ),
                              ),
                              DataCell(
                                Text(
                                  user['role']
                                      ?.toString() ??
                                      '-',
                                ),
                              ),
                              DataCell(
                                Chip(
                                  label: Text(
                                    active
                                        ? 'Active'
                                        : 'Inactive',
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: active
                                          ? 'Deactivate'
                                          : 'Activate',
                                      onPressed: () =>
                                          _toggleUser(user),
                                      icon: Icon(
                                        active
                                            ? Icons
                                            .person_off_outlined
                                            : Icons
                                            .person_add_alt_outlined,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      onPressed: () =>
                                          _deleteUser(user),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
