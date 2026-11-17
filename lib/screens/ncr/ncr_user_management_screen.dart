import 'package:flutter/material.dart';

import '../../services/ncr/ncr_admin_service.dart';
import '../../services/ncr/ncr_auth_service.dart';
import '../../services/ncr/ncr_session.dart';

class NcrUserManagementScreen extends StatefulWidget {
  const NcrUserManagementScreen({super.key});

  @override
  State<NcrUserManagementScreen> createState() =>
      _NcrUserManagementScreenState();
}

class _NcrUserManagementScreenState
    extends State<NcrUserManagementScreen> {
  List<NcrAdminUser> _users = [];
  List<NcrRoleOption> _roles = [];

  bool _isLoading = true;
  String? _errorMessage;

  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // LOAD USERS + ROLES
  // ============================================================

  Future<void> _loadData() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        NcrAdminService.getUsers(),
        NcrAdminService.getRoles(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _users = results[0] as List<NcrAdminUser>;
        _roles = results[1] as List<NcrRoleOption>;
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
            .replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // FILTER USERS
  // ============================================================

  List<NcrAdminUser> get _filteredUsers {
    final query = _searchText.trim().toLowerCase();

    if (query.isEmpty) {
      return _users;
    }

    return _users.where((user) {
      return user.fullName
          .toLowerCase()
          .contains(query) ||
          user.email
              .toLowerCase()
              .contains(query) ||
          user.roleName
              .toLowerCase()
              .contains(query) ||
          user.roleKey
              .toLowerCase()
              .contains(query);
    }).toList();
  }

  // ============================================================
  // ADD USER
  // ============================================================

  Future<void> _showAddUserDialog() async {
    if (!NcrSession.isAdmin) {
      _showMessage(
        'Only an NCR Admin can create users.',
        isError: true,
      );
      return;
    }

    if (_roles.isEmpty) {
      _showMessage(
        'No active NCR roles are available.',
        isError: true,
      );
      return;
    }

    final nameController = TextEditingController();
    final emailController = TextEditingController();

    String selectedRoleId = _roles.first.id;

    bool isSaving = false;
    bool obscurePassword = true;

    final formKey = GlobalKey<FormState>();

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (
                context,
                setDialogState,
                ) {
              return AlertDialog(
                title: const Row(
                  children: [
                    Icon(
                      Icons.person_add_alt_1,
                    ),
                    SizedBox(width: 10),
                    Text('Add NCR User'),
                  ],
                ),
                content: SizedBox(
                  width: 480,
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize:
                        MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller:
                            nameController,
                            textInputAction:
                            TextInputAction.next,
                            decoration:
                            const InputDecoration(
                              labelText:
                              'Full Name',
                              hintText:
                              'Enter full name',
                              prefixIcon:
                              Icon(
                                Icons.person_outline,
                              ),
                              border:
                              OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Full name is required.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller:
                            emailController,
                            keyboardType:
                            TextInputType.emailAddress,
                            textInputAction:
                            TextInputAction.next,
                            decoration:
                            const InputDecoration(
                              labelText: 'Email',
                              hintText:
                              'Enter email address',
                              prefixIcon:
                              Icon(
                                Icons.email_outlined,
                              ),
                              border:
                              OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final email =
                                  value?.trim() ??
                                      '';

                              if (email.isEmpty) {
                                return 'Email is required.';
                              }

                              final emailRegex =
                              RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              );

                              if (!emailRegex
                                  .hasMatch(email)) {
                                return 'Enter a valid email address.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            initialValue:
                            selectedRoleId,
                            decoration:
                            const InputDecoration(
                              labelText: 'Role',
                              prefixIcon:
                              Icon(
                                Icons
                                    .admin_panel_settings_outlined,
                              ),
                              border:
                              OutlineInputBorder(),
                            ),
                            items: _roles
                                .map(
                                  (role) {
                                return DropdownMenuItem<
                                    String>(
                                  value: role.id,
                                  child: Text(
                                    role.roleName,
                                  ),
                                );
                              },
                            )
                                .toList(),
                            onChanged: isSaving
                                ? null
                                : (value) {
                              if (value ==
                                  null) {
                                return;
                              }

                              setDialogState(
                                    () {
                                  selectedRoleId =
                                      value;
                                },
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            initialValue:
                            'welcome123',
                            obscureText:
                            obscurePassword,
                            readOnly: true,
                            decoration:
                            InputDecoration(
                              labelText:
                              'Default Password',
                              prefixIcon:
                              const Icon(
                                Icons.lock_outline,
                              ),
                              suffixIcon:
                              IconButton(
                                tooltip:
                                obscurePassword
                                    ? 'Show password'
                                    : 'Hide password',
                                icon: Icon(
                                  obscurePassword
                                      ? Icons
                                      .visibility_outlined
                                      : Icons
                                      .visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setDialogState(
                                        () {
                                      obscurePassword =
                                      !obscurePassword;
                                    },
                                  );
                                },
                              ),
                              border:
                              const OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Container(
                            width: double.infinity,
                            padding:
                            const EdgeInsets.all(
                              12,
                            ),
                            decoration:
                            BoxDecoration(
                              color:
                              Colors.blue.shade50,
                              borderRadius:
                              BorderRadius.circular(
                                8,
                              ),
                            ),
                            child: const Row(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 19,
                                  color:
                                  Color(
                                    0xFF3155D9,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'The user will receive the default password welcome123 and can change it after logging in.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
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
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () {
                      Navigator.pop(
                        dialogContext,
                      );
                    },
                    child:
                    const Text('Cancel'),
                  ),
                  FilledButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                      if (!formKey
                          .currentState!
                          .validate()) {
                        return;
                      }

                      setDialogState(() {
                        isSaving = true;
                      });

                      try {
                        await NcrAuthService
                            .createUser(
                          fullName:
                          nameController
                              .text
                              .trim(),
                          email:
                          emailController
                              .text
                              .trim(),
                          roleId:
                          selectedRoleId,
                          password:
                          'welcome123',
                        );

                        if (!dialogContext
                            .mounted) {
                          return;
                        }

                        Navigator.pop(
                          dialogContext,
                        );

                        _showMessage(
                          'NCR user created successfully.',
                        );

                        await _loadData();
                      } catch (e) {
                        if (!dialogContext
                            .mounted) {
                          return;
                        }

                        setDialogState(() {
                          isSaving = false;
                        });

                        ScaffoldMessenger.of(
                          dialogContext,
                        )
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                e
                                    .toString()
                                    .replaceFirst(
                                  'Exception: ',
                                  '',
                                ),
                              ),
                              backgroundColor:
                              Colors.red,
                            ),
                          );
                      }
                    },
                    icon: isSaving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons.person_add,
                    ),
                    label: Text(
                      isSaving
                          ? 'Creating...'
                          : 'Create User',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      emailController.dispose();
    }
  }

  // ============================================================
  // EDIT USER
  // ============================================================

  Future<void> _showEditUserDialog(
      NcrAdminUser user,
      ) async {
    if (!NcrSession.isAdmin) {
      _showMessage(
        'Only an NCR Admin can edit users.',
        isError: true,
      );
      return;
    }

    if (_roles.isEmpty) {
      _showMessage(
        'No active NCR roles are available.',
        isError: true,
      );
      return;
    }

    final nameController =
    TextEditingController(
      text: user.fullName,
    );

    final emailController =
    TextEditingController(
      text: user.email,
    );

    String selectedRoleId = user.roleId;

    final roleExists = _roles.any(
          (role) => role.id == selectedRoleId,
    );

    if (!roleExists) {
      selectedRoleId = _roles.first.id;
    }

    bool isSaving = false;

    final formKey =
    GlobalKey<FormState>();

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (
                context,
                setDialogState,
                ) {
              return AlertDialog(
                title: const Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                    ),
                    SizedBox(width: 10),
                    Text('Edit NCR User'),
                  ],
                ),

                content: SizedBox(
                  width: 480,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller:
                          nameController,
                          textInputAction:
                          TextInputAction.next,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Full Name',
                            prefixIcon:
                            Icon(
                              Icons.person_outline,
                            ),
                            border:
                            OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Full name is required.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller:
                          emailController,
                          keyboardType:
                          TextInputType.emailAddress,
                          textInputAction:
                          TextInputAction.next,
                          decoration:
                          const InputDecoration(
                            labelText: 'Email',
                            prefixIcon:
                            Icon(
                              Icons.email_outlined,
                            ),
                            border:
                            OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final email =
                                value?.trim() ??
                                    '';

                            if (email.isEmpty) {
                              return 'Email is required.';
                            }

                            final emailRegex =
                            RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            );

                            if (!emailRegex
                                .hasMatch(email)) {
                              return 'Enter a valid email address.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          initialValue:
                          selectedRoleId,
                          decoration:
                          const InputDecoration(
                            labelText: 'Role',
                            prefixIcon:
                            Icon(
                              Icons
                                  .admin_panel_settings_outlined,
                            ),
                            border:
                            OutlineInputBorder(),
                          ),
                          items: _roles
                              .map(
                                (role) {
                              return DropdownMenuItem<
                                  String>(
                                value: role.id,
                                child: Text(
                                  role.roleName,
                                ),
                              );
                            },
                          )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (value) {
                            if (value ==
                                null) {
                              return;
                            }

                            setDialogState(
                                  () {
                                selectedRoleId =
                                    value;
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        Container(
                          width: double.infinity,
                          padding:
                          const EdgeInsets.all(
                            12,
                          ),
                          decoration:
                          BoxDecoration(
                            color:
                            Colors.grey.shade100,
                            borderRadius:
                            BorderRadius.circular(
                              8,
                            ),
                          ),
                          child: const Row(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Password is not changed when editing a user.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () {
                      Navigator.pop(
                        dialogContext,
                      );
                    },
                    child:
                    const Text('Cancel'),
                  ),

                  FilledButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                      if (!formKey
                          .currentState!
                          .validate()) {
                        return;
                      }

                      setDialogState(() {
                        isSaving = true;
                      });

                      try {
                        await NcrAdminService
                            .updateUser(
                          userId:
                          user.id,
                          fullName:
                          nameController
                              .text
                              .trim(),
                          email:
                          emailController
                              .text
                              .trim(),
                          roleId:
                          selectedRoleId,
                        );

                        if (!dialogContext
                            .mounted) {
                          return;
                        }

                        Navigator.pop(
                          dialogContext,
                        );

                        _showMessage(
                          'NCR user updated successfully.',
                        );

                        await _loadData();
                      } catch (e) {
                        if (!dialogContext
                            .mounted) {
                          return;
                        }

                        setDialogState(() {
                          isSaving = false;
                        });

                        ScaffoldMessenger.of(
                          dialogContext,
                        )
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                e
                                    .toString()
                                    .replaceFirst(
                                  'Exception: ',
                                  '',
                                ),
                              ),
                              backgroundColor:
                              Colors.red,
                            ),
                          );
                      }
                    },
                    icon: isSaving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons.save_outlined,
                    ),
                    label: Text(
                      isSaving
                          ? 'Saving...'
                          : 'Save Changes',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      emailController.dispose();
    }
  }

  // ============================================================
  // TOGGLE ACTIVE STATUS
  // ============================================================

  Future<void> _toggleUserStatus(
      NcrAdminUser user,
      ) async {
    final newStatus = !user.isActive;

    final action = newStatus
        ? 'activate'
        : 'deactivate';

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            newStatus
                ? 'Activate User'
                : 'Deactivate User',
          ),
          content: Text(
            newStatus
                ? 'Are you sure you want to activate ${user.fullName}?'
                : 'Are you sure you want to deactivate ${user.fullName}? They will no longer be able to log in.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
              const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: Text(
                newStatus
                    ? 'Activate'
                    : 'Deactivate',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await NcrAdminService
          .setUserActive(
        userId: user.id,
        isActive: newStatus,
      );

      _showMessage(
        '${user.fullName} has been $action'
            'd successfully.',
      );

      await _loadData();
    } catch (e) {
      _showMessage(
        e
            .toString()
            .replaceFirst(
          'Exception: ',
          '',
        ),
        isError: true,
      );
    }
  }

  // ============================================================
  // DELETE USER
  // ============================================================

  Future<void> _deleteUser(
      NcrAdminUser user,
      ) async {
    if (!NcrSession.isAdmin) {
      _showMessage(
        'Only an NCR Admin can delete users.',
        isError: true,
      );
      return;
    }

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 10),
              Text('Delete NCR User'),
            ],
          ),

          content: Text(
            'Are you sure you want to permanently delete ${user.fullName} (${user.email})?\n\nThis action cannot be undone. If this user is already referenced by an NCR, deletion may be blocked to preserve NCR history.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
              const Text('Cancel'),
            ),

            FilledButton(
              style:
              FilledButton.styleFrom(
                backgroundColor:
                Colors.red,
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
              const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await NcrAdminService
          .deleteUser(
        userId: user.id,
      );

      _showMessage(
        '${user.fullName} was deleted successfully.',
      );

      await _loadData();
    } catch (e) {
      _showMessage(
        e
            .toString()
            .replaceFirst(
          'Exception: ',
          '',
        ),
        isError: true,
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
          Text(message),
          backgroundColor:
          isError
              ? Colors.red
              : null,
          behavior:
          SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // ROLE LABEL
  // ============================================================

  String _roleLabel(
      NcrAdminUser user,
      ) {
    if (user.roleName
        .trim()
        .isNotEmpty) {
      return user.roleName;
    }

    return user.roleKey.isEmpty
        ? 'Unknown'
        : user.roleKey
        .toUpperCase();
  }

  // ============================================================
  // ROLE BADGE
  // ============================================================

  Widget _roleBadge(
      NcrAdminUser user,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFEAF0FF),
        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        _roleLabel(user),
        style:
        const TextStyle(
          fontSize: 12,
          fontWeight:
          FontWeight.w700,
          color:
          Color(0xFF3155D9),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(
      NcrAdminUser user,
      ) {
    final active =
        user.isActive;

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration:
      BoxDecoration(
        color: active
            ? Colors.green.shade50
            : Colors.red.shade50,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration:
            BoxDecoration(
              shape:
              BoxShape.circle,
              color: active
                  ? Colors
                  .green
                  .shade700
                  : Colors
                  .red
                  .shade700,
            ),
          ),
          const SizedBox(
            width: 6,
          ),
          Text(
            active
                ? 'Active'
                : 'Inactive',
            style:
            TextStyle(
              fontSize: 12,
              fontWeight:
              FontWeight.w700,
              color: active
                  ? Colors
                  .green
                  .shade700
                  : Colors
                  .red
                  .shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // USER CARD
  // ============================================================

  Widget _userCard(
      NcrAdminUser user,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(
        18,
      ),
      margin:
      const EdgeInsets.only(
        bottom: 2,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border:
        Border.all(
          color:
          const Color(
            0xFFE2E7EF,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black
                .withOpacity(
              0.025,
            ),
            blurRadius: 10,
            offset:
            const Offset(
              0,
              3,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor:
            const Color(
              0xFFEAF0FF,
            ),
            child: Text(
              user.fullName
                  .trim()
                  .isEmpty
                  ? '?'
                  : user.fullName
                  .trim()
                  .substring(
                0,
                1,
              )
                  .toUpperCase(),
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w800,
                color:
                Color(
                  0xFF3155D9,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 15,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  user.fullName,
                  style:
                  const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  user.email,
                  style:
                  TextStyle(
                    fontSize: 13,
                    color:
                    Colors.grey
                        .shade600,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _roleBadge(
                      user,
                    ),
                    _statusBadge(
                      user,
                    ),
                  ],
                ),
              ],
            ),
          ),

          PopupMenuButton<String>(
            tooltip:
            'User actions',

            onSelected:
                (value) {
              switch (value) {
                case 'view':
                  _showUserDetails(
                    user,
                  );
                  break;

                case 'edit':
                  _showEditUserDialog(
                    user,
                  );
                  break;

                case 'toggle':
                  _toggleUserStatus(
                    user,
                  );
                  break;

                case 'delete':
                  _deleteUser(
                    user,
                  );
                  break;
              }
            },

            itemBuilder:
                (context) {
              return [
                const PopupMenuItem(
                  value:
                  'view',
                  child:
                  Row(
                    children: [
                      Icon(
                        Icons
                            .visibility_outlined,
                        size: 19,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'View Details',
                      ),
                    ],
                  ),
                ),

                const PopupMenuItem(
                  value:
                  'edit',
                  child:
                  Row(
                    children: [
                      Icon(
                        Icons
                            .edit_outlined,
                        size: 19,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Edit User',
                      ),
                    ],
                  ),
                ),

                PopupMenuItem(
                  value:
                  'toggle',
                  child:
                  Row(
                    children: [
                      Icon(
                        user.isActive
                            ? Icons
                            .person_off_outlined
                            : Icons
                            .person_add_alt_1_outlined,
                        size: 19,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        user.isActive
                            ? 'Deactivate User'
                            : 'Activate User',
                      ),
                    ],
                  ),
                ),

                const PopupMenuDivider(),

                const PopupMenuItem(
                  value:
                  'delete',
                  child:
                  Row(
                    children: [
                      Icon(
                        Icons
                            .delete_outline,
                        size: 19,
                        color:
                        Colors.red,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Delete User',
                        style:
                        TextStyle(
                          color:
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // USER DETAILS
  // ============================================================

  void _showUserDetails(
      NcrAdminUser user,
      ) {
    showDialog<void>(
      context: context,
      builder:
          (context) {
        return AlertDialog(
          title:
          const Text(
            'NCR User Details',
          ),
          content:
          SizedBox(
            width: 450,
            child:
            Column(
              mainAxisSize:
              MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                _detailRow(
                  'Full Name',
                  user.fullName,
                ),
                _detailRow(
                  'Email',
                  user.email,
                ),
                _detailRow(
                  'Role',
                  _roleLabel(
                    user,
                  ),
                ),
                _detailRow(
                  'Status',
                  user.isActive
                      ? 'Active'
                      : 'Inactive',
                ),
                _detailRow(
                  'Created',
                  _formatDate(
                    user.createdAt,
                  ),
                ),
                _detailRow(
                  'Last Updated',
                  _formatDate(
                    user.updatedAt,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child:
              const Text(
                'Close',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
      String label,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 14,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style:
              TextStyle(
                fontSize: 13,
                color:
                Colors.grey
                    .shade600,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
              const TextStyle(
                fontSize: 14,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(
      DateTime? date,
      ) {
    if (date == null) {
      return '-';
    }

    final local =
    date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final currentUser =
        NcrSession.currentUser;

    if (currentUser == null) {
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
        body:
        Center(
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    if (!NcrSession.isAdmin) {
      return Scaffold(
        appBar:
        AppBar(
          title:
          const Text(
            'NCR User Management',
          ),
        ),
        body:
        const Center(
          child:
          Text(
            'Only NCR Admin users can access user management.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
      const Color(
        0xFFF5F7FA,
      ),

      appBar:
      AppBar(
        elevation: 0,
        backgroundColor:
        Colors.white,
        surfaceTintColor:
        Colors.white,

        leading:
        IconButton(
          tooltip:
          'Back',
          icon:
          const Icon(
            Icons.arrow_back,
          ),
          onPressed: () {
            Navigator.pop(
              context,
            );
          },
        ),

        title:
        const Text(
          'NCR User Management',
          style:
          TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),

        actions: [
          IconButton(
            tooltip:
            'Refresh',
            icon:
            const Icon(
              Icons.refresh,
            ),
            onPressed:
            _isLoading
                ? null
                : _loadData,
          ),
          const SizedBox(
            width: 8,
          ),
        ],
      ),

      body:
      RefreshIndicator(
        onRefresh:
        _loadData,
        child:
        SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.all(
            28,
          ),
          child:
          Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              Row(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Expanded(
                    child:
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        const Text(
                          'NCR Users',
                          style:
                          TextStyle(
                            fontSize:
                            28,
                            fontWeight:
                            FontWeight
                                .w800,
                            color:
                            Color(
                              0xFF172033,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Text(
                          'Manage independent users for the NCR module.',
                          style:
                          TextStyle(
                            fontSize:
                            14,
                            color:
                            Colors
                                .grey
                                .shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  FilledButton.icon(
                    onPressed:
                    _isLoading
                        ? null
                        : _showAddUserDialog,
                    icon:
                    const Icon(
                      Icons
                          .person_add_alt_1,
                    ),
                    label:
                    const Text(
                      'Add NCR User',
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 25,
              ),

              TextField(
                onChanged:
                    (value) {
                  setState(() {
                    _searchText =
                        value;
                  });
                },
                decoration:
                InputDecoration(
                  hintText:
                  'Search by name, email or role...',
                  prefixIcon:
                  const Icon(
                    Icons.search,
                  ),
                  suffixIcon:
                  _searchText.isEmpty
                      ? null
                      : IconButton(
                    icon:
                    const Icon(
                      Icons.clear,
                    ),
                    onPressed:
                        () {
                      setState(
                            () {
                          _searchText =
                          '';
                        },
                      );
                    },
                  ),
                  filled: true,
                  fillColor:
                  Colors.white,
                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
                    ),
                    borderSide:
                    const BorderSide(
                      color:
                      Color(
                        0xFFE2E7EF,
                      ),
                    ),
                  ),
                  enabledBorder:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
                    ),
                    borderSide:
                    const BorderSide(
                      color:
                      Color(
                        0xFFE2E7EF,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              if (_errorMessage !=
                  null)
                Container(
                  width:
                  double.infinity,
                  margin:
                  const EdgeInsets
                      .only(
                    bottom: 20,
                  ),
                  padding:
                  const EdgeInsets
                      .all(
                    16,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.red
                        .shade50,
                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
                    ),
                    border:
                    Border.all(
                      color:
                      Colors.red
                          .shade200,
                    ),
                  ),
                  child:
                  Row(
                    children: [
                      Icon(
                        Icons
                            .error_outline,
                        color:
                        Colors.red
                            .shade700,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child:
                        Text(
                          _errorMessage!,
                          style:
                          TextStyle(
                            color:
                            Colors.red
                                .shade800,
                            fontWeight:
                            FontWeight
                                .w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (!_isLoading)
                Row(
                  children: [
                    _summaryItem(
                      'Total Users',
                      _users.length
                          .toString(),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    _summaryItem(
                      'Active',
                      _users
                          .where(
                            (u) =>
                        u.isActive,
                      )
                          .length
                          .toString(),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    _summaryItem(
                      'Inactive',
                      _users
                          .where(
                            (u) =>
                        !u.isActive,
                      )
                          .length
                          .toString(),
                    ),
                  ],
                ),

              const SizedBox(
                height: 20,
              ),

              if (_isLoading)
                const Padding(
                  padding:
                  EdgeInsets.only(
                    top: 80,
                  ),
                  child:
                  Center(
                    child:
                    CircularProgressIndicator(),
                  ),
                )
              else if (_filteredUsers
                  .isEmpty)
                _emptyState()
              else
                ..._filteredUsers
                    .map(
                  _userCard,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY ITEM
  // ============================================================

  Widget _summaryItem(
      String title,
      String value,
      ) {
    return Container(
      padding:
      const EdgeInsets
          .symmetric(
        horizontal: 18,
        vertical: 12,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        border:
        Border.all(
          color:
          const Color(
            0xFFE2E7EF,
          ),
        ),
      ),
      child:
      Row(
        children: [
          Text(
            title,
            style:
            TextStyle(
              fontSize: 13,
              color:
              Colors.grey
                  .shade600,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Text(
            value,
            style:
            const TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets
          .symmetric(
        vertical: 80,
        horizontal: 30,
      ),
      child:
      Column(
        children: [
          Icon(
            Icons
                .people_outline,
            size: 70,
            color:
            Colors.grey
                .shade400,
          ),
          const SizedBox(
            height: 15,
          ),
          const Text(
            'No NCR users found',
            style:
            TextStyle(
              fontSize: 20,
              fontWeight:
              FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 7,
          ),
          Text(
            _searchText
                .isEmpty
                ? 'Create the first NCR user using the button above.'
                : 'No users match your search.',
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              color:
              Colors.grey
                  .shade600,
            ),
          ),
        ],
      ),
    );
  }
}