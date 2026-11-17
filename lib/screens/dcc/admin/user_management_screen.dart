
import 'package:flutter/material.dart';

import '../../../models/dcc/dcc_user.dart';
import '../../../services/dcc/dcc_user_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<DccUser> _users = [];

  bool _loading = true;
  bool _busy = false;

  int _selectedTab = 0;
  String _searchQuery = '';
  String _selectedRole = 'ALL';

  final TextEditingController _searchController =
  TextEditingController();

  static const Color _background = Color(0xFFF5F7FB);
  static const Color _primary = Color(0xFF3157D5);
  static const Color _textDark = Color(0xFF172033);
  static const Color _textMuted = Color(0xFF788196);

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------
  // DATA
  // ---------------------------------------------------------

  List<DccUser> get _activeUsers =>
      _users.where((u) => u.isActive).toList();

  List<DccUser> get _disabledUsers =>
      _users.where((u) => u.isDisabled).toList();

  List<DccUser> get _deletedUsers =>
      _users.where((u) => u.isDeleted).toList();

  List<DccUser> get _currentUsers {
    switch (_selectedTab) {
      case 1:
        return _disabledUsers;
      case 2:
        return _deletedUsers;
      default:
        return _activeUsers;
    }
  }

  List<DccUser> get _filteredUsers {
    final query = _searchQuery.trim().toLowerCase();

    return _currentUsers.where((user) {
      final matchesSearch =
          user.name.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query) ||
              user.id.toLowerCase().contains(query);

      final matchesRole = _selectedRole == 'ALL' ||
          user.role.toUpperCase() == _selectedRole;

      return matchesSearch && matchesRole;
    }).toList();
  }

  Future<void> _loadUsers({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() => _loading = true);
    }

    try {
      final users = await DccUserService.getUsers();

      if (!mounted) return;

      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage(
        'Unable to load users: ${_cleanError(e)}',
        isError: true,
      );
    }
  }

  // ---------------------------------------------------------
  // CONFIRMATION
  // ---------------------------------------------------------

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmText,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
              destructive ? Colors.red.shade600 : _primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result == true;
  }

  // ---------------------------------------------------------
  // ACCOUNT ACTIONS
  // ---------------------------------------------------------

  Future<void> _disableUser(DccUser user) async {
    final confirmed = await _confirmAction(
      title: 'Disable Account',
      message:
      'Disable ${user.name}?\n\n'
          'They will no longer be able to log in. '
          'Their account can be enabled again later.',
      confirmText: 'Disable',
      destructive: true,
    );

    if (!confirmed) return;

    await _performAction(
      action: () => DccUserService.setUserActive(
        user.id,
        false,
      ),
      successMessage: '${user.name} has been disabled.',
    );
  }

  Future<void> _enableUser(DccUser user) async {
    final confirmed = await _confirmAction(
      title: 'Enable Account',
      message:
      'Enable ${user.name}?\n\n'
          'They will be able to log in again.',
      confirmText: 'Enable',
    );

    if (!confirmed) return;

    await _performAction(
      action: () => DccUserService.setUserActive(
        user.id,
        true,
      ),
      successMessage: '${user.name} has been enabled.',
    );
  }

  Future<void> _deleteUser(DccUser user) async {
    final confirmed = await _confirmAction(
      title: 'Delete Account',
      message:
      'Move ${user.name} to Deleted Users?\n\n'
          'They will lose login access. '
          'Their documents and historical records will be preserved. '
          'You can restore this account later.',
      confirmText: 'Delete Account',
      destructive: true,
    );

    if (!confirmed) return;

    await _performAction(
      action: () => DccUserService.deleteUser(user.id),
      successMessage: '${user.name} moved to Deleted Users.',
    );
  }

  Future<void> _restoreUser(DccUser user) async {
    final confirmed = await _confirmAction(
      title: 'Restore Account',
      message:
      'Restore ${user.name}?\n\n'
          'This will move the account to Active Users '
          'and allow the user to log in again.',
      confirmText: 'Restore',
    );

    if (!confirmed) return;

    await _performAction(
      action: () => DccUserService.restoreUser(user.id),
      successMessage: '${user.name} has been restored.',
    );
  }

  Future<void> _performAction({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      await action();

      await _loadUsers(showLoader: false);

      if (!mounted) return;

      _showMessage(successMessage);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Operation failed: ${_cleanError(e)}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
          isError ? Colors.red.shade700 : Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ---------------------------------------------------------
  // STYLING
  // ---------------------------------------------------------

  Color _roleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return Colors.purple;
      case 'HOD':
        return Colors.orange.shade800;
      case 'DCC':
        return Colors.blue.shade700;
      case 'USER':
        return Colors.teal.shade700;
      default:
        return Colors.grey;
    }
  }

  Color get _statusColor {
    switch (_selectedTab) {
      case 1:
        return Colors.orange.shade800;
      case 2:
        return Colors.red.shade700;
      default:
        return Colors.green.shade700;
    }
  }

  String get _sectionTitle {
    switch (_selectedTab) {
      case 1:
        return 'Disabled Accounts';
      case 2:
        return 'Deleted Accounts';
      default:
        return 'Active Accounts';
    }
  }

  String get _sectionDescription {
    switch (_selectedTab) {
      case 1:
        return 'Temporarily disabled accounts. You can enable them anytime.';
      case 2:
        return 'Deleted accounts. Restore them whenever access is needed again.';
      default:
        return 'Manage users who currently have access to the DCC system.';
    }
  }

  // ---------------------------------------------------------
  // USER CARD
  // ---------------------------------------------------------

  Widget _buildUserCard(DccUser user) {
    final roleColor = _roleColor(user.role);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8ECF3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: roleColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textMuted,
                  ),
                ),
                if (user.role.toUpperCase() == 'USER' &&
                    user.hodName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'HOD: ${user.hodName}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  runSpacing: 5,
                  children: [
                    _smallBadge(
                      user.role.toUpperCase(),
                      roleColor,
                    ),
                    _smallBadge(
                      user.accountStatus,
                      _statusColor,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          if (_busy)
            const SizedBox(
              width: 30,
              height: 30,
              child: Padding(
                padding: EdgeInsets.all(6),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            )
          else
            PopupMenuButton<String>(
              tooltip: 'Account actions',
              icon: const Icon(
                Icons.more_vert_rounded,
                color: _textMuted,
              ),
              onSelected: (value) {
                switch (value) {
                  case 'disable':
                    _disableUser(user);
                    break;
                  case 'enable':
                    _enableUser(user);
                    break;
                  case 'delete':
                    _deleteUser(user);
                    break;
                  case 'restore':
                    _restoreUser(user);
                    break;
                }
              },
              itemBuilder: (context) {
                if (user.isActive) {
                  return [
                    const PopupMenuItem(
                      value: 'disable',
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.block_rounded,
                          color: Colors.orange,
                        ),
                        title: Text('Disable Account'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                        ),
                        title: Text('Delete Account'),
                      ),
                    ),
                  ];
                }

                if (user.isDisabled) {
                  return [
                    const PopupMenuItem(
                      value: 'enable',
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                        title: Text('Enable Account'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                        ),
                        title: Text('Delete Account'),
                      ),
                    ),
                  ];
                }

                return [
                  const PopupMenuItem(
                    value: 'restore',
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.restore_rounded,
                        color: Colors.green,
                      ),
                      title: Text('Restore Account'),
                    ),
                  ),
                ];
              },
            ),
        ],
      ),
    );
  }

  Widget _smallBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // SUMMARY CARD
  // ---------------------------------------------------------

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required int tabIndex,
  }) {
    final selected = _selectedTab == tabIndex;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          setState(() {
            _selectedTab = tabIndex;
            _selectedRole = 'ALL';
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.09) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? color : const Color(0xFFE8ECF3),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 12),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _textDark,
        elevation: 0,
        title: const Text(
          'User Management',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh users',
            onPressed: _busy ? null : () => _loadUsers(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadUsers(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Account Overview',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Manage access, account status and user records.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _textMuted,
                    ),
                  ),
                  const SizedBox(height: 19),

                  Row(
                    children: [
                      _buildSummaryCard(
                        title: 'Active',
                        count: _activeUsers.length,
                        color: Colors.green.shade700,
                        icon: Icons.verified_user_outlined,
                        tabIndex: 0,
                      ),
                      const SizedBox(width: 10),
                      _buildSummaryCard(
                        title: 'Disabled',
                        count: _disabledUsers.length,
                        color: Colors.orange.shade800,
                        icon: Icons.block_outlined,
                        tabIndex: 1,
                      ),
                      const SizedBox(width: 10),
                      _buildSummaryCard(
                        title: 'Deleted',
                        count: _deletedUsers.length,
                        color: Colors.red.shade700,
                        icon: Icons.delete_outline_rounded,
                        tabIndex: 2,
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  Text(
                    _sectionTitle,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _sectionDescription,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textMuted,
                    ),
                  ),

                  const SizedBox(height: 17),

                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search name, email or ID...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.close),
                      )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(
                          color: Color(0xFFE8ECF3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(
                          color: Color(0xFFE8ECF3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(
                          color: _primary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Filter by role',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                      const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(
                          color: Color(0xFFE8ECF3),
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'ALL',
                        child: Text('All Roles'),
                      ),
                      DropdownMenuItem(
                        value: 'ADMIN',
                        child: Text('Admin'),
                      ),
                      DropdownMenuItem(
                        value: 'DCC',
                        child: Text('DCC'),
                      ),
                      DropdownMenuItem(
                        value: 'HOD',
                        child: Text('HOD'),
                      ),
                      DropdownMenuItem(
                        value: 'USER',
                        child: Text('User'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value ?? 'ALL';
                      });
                    },
                  ),

                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_filteredUsers.length} account(s)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _textMuted,
                        ),
                      ),
                      if (_busy)
                        const Text(
                          'Updating...',
                          style: TextStyle(
                            fontSize: 11,
                            color: _primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (_filteredUsers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(35),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE8ECF3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _selectedTab == 2
                                ? Icons.delete_outline_rounded
                                : Icons.people_outline_rounded,
                            size: 38,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty ||
                                _selectedRole != 'ALL'
                                ? 'No matching accounts found.'
                                : 'No ${_sectionTitle.toLowerCase()} found.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._filteredUsers.map(_buildUserCard),

                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
