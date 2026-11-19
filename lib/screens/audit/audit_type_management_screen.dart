import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../services/audit/audit_admin_session.dart';


class AuditTypeManagementScreen extends StatefulWidget {
  const AuditTypeManagementScreen({super.key});

  @override
  State<AuditTypeManagementScreen> createState() =>
      _AuditTypeManagementScreenState();
}

class _AuditTypeManagementScreenState
    extends State<AuditTypeManagementScreen> {
  String? _sessionToken;
  String? _adminEmail;

  bool _loading = true;

  List<Map<String, dynamic>> _auditTypes = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_sessionToken != null) {
      return;
    }

    final arguments =
        ModalRoute.of(context)?.settings.arguments;

    if (arguments is Map) {
      _sessionToken =
          arguments['sessionToken']?.toString();

      _adminEmail =
          arguments['email']?.toString();
    }

    if (_sessionToken == null ||
        _sessionToken!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          '/AUDIT/admin/login',
        );
      });

      return;
    }

    _loadAuditTypes();
  }

  Future<void> _loadAuditTypes() async {
    final sessionToken = _sessionToken;

    if (sessionToken == null ||
        sessionToken.isEmpty) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      final result =
      await SupabaseService.getAdminAuditTypes(
        sessionToken: sessionToken,
      ).timeout(
        const Duration(seconds: 20),
      );

        result.sort(_compareAuditTypes);

      if (!mounted) return;

      setState(() {
        _auditTypes = result;
        _loading = false;
      });
    } catch (e) {
      if (await AuditAdminSession.handleSessionExpired(context, e)) {
        return;
      }
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showError(
        'Unable to load Audit Types: $e',
      );
    }
  }

  int _compareAuditTypes(
      Map<String, dynamic> a,
      Map<String, dynamic> b,
      ) {
    final aName =
        a['audit_type']?.toString().toLowerCase() ?? '';

    final bName =
        b['audit_type']?.toString().toLowerCase() ?? '';

    return aName.compareTo(bName);
  }

  Future<void> _showAuditTypeDialog({
    Map<String, dynamic>? existing,
  }) async {
    final sessionToken = _sessionToken;

    if (sessionToken == null ||
        sessionToken.isEmpty) {
      _showError(
        'Admin session is missing.',
      );
      return;
    }

    final nameController =
    TextEditingController(
      text:
      existing?['audit_type']?.toString() ?? '',
    );

    final descriptionController =
    TextEditingController(
      text:
      existing?['description']?.toString() ?? '',
    );

    bool active =
        existing?['active'] as bool? ?? true;

    final isEditing = existing != null;

    try {
      final result =
      await showDialog<Map<String, dynamic>?>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          bool saving = false;

          return StatefulBuilder(
            builder: (
                context,
                setDialogState,
                ) {
              Future<void> save() async {
                final name =
                nameController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Audit Type is required.',
                      ),
                    ),
                  );
                  return;
                }

                if (saving) return;

                setDialogState(() {
                  saving = true;
                });

                try {
                  final Map<String, dynamic> saved;

                  if (isEditing) {
                    final typeId =
                    existing['type_id']
                        ?.toString();

                    if (typeId == null ||
                        typeId.isEmpty) {
                      throw Exception(
                        'Audit Type ID is missing.',
                      );
                    }

                    saved =
                    await SupabaseService
                        .updateAdminAuditType(
                      sessionToken:
                      sessionToken,
                      typeId: typeId,
                      auditType: name,
                      description:
                      descriptionController
                          .text
                          .trim()
                          .isEmpty
                          ? null
                          : descriptionController
                          .text
                          .trim(),
                      active: active,
                    ).timeout(
                      const Duration(seconds: 20),
                    );
                  } else {
                    saved =
                    await SupabaseService
                        .createAdminAuditType(
                      sessionToken:
                      sessionToken,
                      auditType: name,
                      description:
                      descriptionController
                          .text
                          .trim()
                          .isEmpty
                          ? null
                          : descriptionController
                          .text
                          .trim(),
                      active: active,
                    ).timeout(
                      const Duration(seconds: 20),
                    );
                  }

                  if (!dialogContext.mounted) {
                    return;
                  }

                  Navigator.pop(
                    dialogContext,
                    saved,
                  );
                } catch (e) {
                  if (await AuditAdminSession.handleSessionExpired(context, e)) {
                    return;
                  }
                  if (!dialogContext.mounted) {
                    return;
                  }

                  setDialogState(() {
                    saving = false;
                  });

                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Unable to save Audit Type: $e',
                      ),
                      backgroundColor:
                      Colors.red.shade700,
                    ),
                  );
                }
              }

              return AlertDialog(
                title: Text(
                  isEditing
                      ? 'Edit Audit Type'
                      : 'Create Audit Type',
                ),
                content: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      TextField(
                        controller:
                        nameController,
                        enabled: !saving,
                        autofocus: true,
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Audit Type',
                          border:
                          OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      TextField(
                        controller:
                        descriptionController,
                        enabled: !saving,
                        maxLines: 3,
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Description',
                          border:
                          OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      SwitchListTile(
                        contentPadding:
                        EdgeInsets.zero,
                        title:
                        const Text('Active'),
                        value: active,
                        onChanged: saving
                            ? null
                            : (value) {
                          setDialogState(
                                () {
                              active =
                                  value;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () =>
                        Navigator.pop(
                          dialogContext,
                        ),
                    child:
                    const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed:
                    saving ? null : save,
                    icon: saving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(
                      Icons.save_outlined,
                    ),
                    label: Text(
                      saving
                          ? 'Saving...'
                          : isEditing
                          ? 'Update'
                          : 'Create',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result == null ||
          !mounted) {
        return;
      }

      setState(() {
        final typeId =
        result['type_id']?.toString();

        if (typeId == null ||
            typeId.isEmpty) {
          return;
        }

        final index =
        _auditTypes.indexWhere(
              (item) =>
          item['type_id']
              ?.toString() ==
              typeId,
        );

        if (index >= 0) {
          _auditTypes[index] =
          Map<String, dynamic>.from(
            result,
          );
        } else {
          _auditTypes.add(
            Map<String, dynamic>.from(
              result,
            ),
          );
        }

        _auditTypes.sort(
          _compareAuditTypes,
        );
      });

      _showMessage(
        isEditing
            ? 'Audit Type updated successfully.'
            : 'Audit Type created successfully.',
      );
    } finally {
      nameController.dispose();
      descriptionController.dispose();
    }
  }

  Future<void> _deleteAuditType(
      Map<String, dynamic> auditType,
      ) async {
    final sessionToken = _sessionToken;

    if (sessionToken == null ||
        sessionToken.isEmpty) {
      _showError(
        'Admin session is missing.',
      );
      return;
    }

    final typeId =
    auditType['type_id']?.toString();

    if (typeId == null ||
        typeId.isEmpty) {
      _showError(
        'Audit Type ID is missing.',
      );
      return;
    }

    final name =
        auditType['audit_type']?.toString() ??
            'this Audit Type';

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
          const Text('Delete Audit Type'),
          content: Text(
            'Delete "$name"?\n\n'
                'Categories and questions under this '
                'Audit Type may also be removed by '
                'the database cascade rules.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                    context,
                    false,
                  ),
              child:
              const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                    context,
                    true,
                  ),
              style:
              FilledButton.styleFrom(
                backgroundColor:
                Colors.red.shade700,
              ),
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
      await SupabaseService
          .deleteAdminAuditType(
        sessionToken: sessionToken,
        typeId: typeId,
      ).timeout(
        const Duration(seconds: 20),
      );

      if (!mounted) return;

      setState(() {
        _auditTypes.removeWhere(
              (item) =>
          item['type_id']
              ?.toString() ==
              typeId,
        );
      });

      _showMessage(
        'Audit Type deleted successfully.',
      );
    } catch (e) {
      if (await AuditAdminSession.handleSessionExpired(context, e)) {
        return;
      }
      if (!mounted) return;

      _showError(
        'Unable to delete Audit Type: $e',
      );
    }
  }

  void _manageCategories(
      Map<String, dynamic> auditType,
      ) {
    final typeId =
    auditType['type_id']?.toString();

    if (typeId == null ||
        typeId.isEmpty) {
      _showError(
        'Audit Type ID is missing.',
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/AUDIT/admin/categories',
      arguments: {
        'sessionToken':
        _sessionToken,
        'typeId': typeId,
        'auditTypeName':
        auditType['audit_type']
            ?.toString() ??
            '',
      },
    );
  }

  void _logout() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/AUDIT',
          (route) => false,
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        Colors.red.shade700,
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Audit Type Management',
        ),
        actions: [
          if (_adminEmail != null)
            Padding(
              padding:
              const EdgeInsets.only(
                right: 8,
              ),
              child: Center(
                child: Text(
                  _adminEmail!,
                  style:
                  const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Refresh',
            onPressed:
            _loading
                ? null
                : _loadAuditTypes,
            icon:
            const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon:
            const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton:
      FloatingActionButton.extended(
        onPressed:
        _loading
            ? null
            : () =>
            _showAuditTypeDialog(),
        icon:
        const Icon(Icons.add),
        label:
        const Text('Add Audit Type'),
      ),
      body: _loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh:
        _loadAuditTypes,
        child: _auditTypes.isEmpty
            ? ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Icon(
              Icons
                  .category_outlined,
              size: 64,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No Audit Types found.',
                style:
                TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight
                      .w600,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Create an Audit Type to begin.',
              ),
            ),
          ],
        )
            : ListView.builder(
          padding:
          const EdgeInsets
              .fromLTRB(
            20,
            20,
            20,
            100,
          ),
          itemCount:
          _auditTypes.length,
          itemBuilder:
              (context, index) {
            final item =
            _auditTypes[index];

            final name =
                item['audit_type']
                    ?.toString() ??
                    '';

            final description =
                item['description']
                    ?.toString() ??
                    '';

            final active =
                item['active']
                as bool? ??
                    false;

            return Card(
              margin:
              const EdgeInsets
                  .only(
                bottom: 12,
              ),
              child: Padding(
                padding:
                const EdgeInsets
                    .all(16),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          child:
                          Text(
                            '${index + 1}',
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child:
                          Text(
                            name,
                            style:
                            const TextStyle(
                              fontSize:
                              17,
                              fontWeight:
                              FontWeight
                                  .w700,
                            ),
                          ),
                        ),
                        Chip(
                          label:
                          Text(
                            active
                                ? 'Active'
                                : 'Inactive',
                          ),
                        ),
                        PopupMenuButton<
                            String>(
                          onSelected:
                              (value) {
                            if (value ==
                                'edit') {
                              _showAuditTypeDialog(
                                existing:
                                item,
                              );
                            } else if (value ==
                                'delete') {
                              _deleteAuditType(
                                item,
                              );
                            }
                          },
                          itemBuilder:
                              (context) =>
                          const [
                            PopupMenuItem(
                              value:
                              'edit',
                              child:
                              Text(
                                'Edit',
                              ),
                            ),
                            PopupMenuItem(
                              value:
                              'delete',
                              child:
                              Text(
                                'Delete',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (description
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        description,
                      ),
                    ],
                    const SizedBox(
                      height: 14,
                    ),
                    Align(
                      alignment:
                      Alignment
                          .centerLeft,
                      child:
                      OutlinedButton
                          .icon(
                        onPressed:
                            () =>
                            _manageCategories(
                              item,
                            ),
                        icon:
                        const Icon(
                          Icons
                              .account_tree_outlined,
                        ),
                        label:
                        const Text(
                          'Manage Categories',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}