import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../services/audit/audit_admin_session.dart';

class AuditCategoryManagementScreen extends StatefulWidget {
  final String typeId;
  final String auditTypeName;
  final String sessionToken;

  const AuditCategoryManagementScreen({
    super.key,
    required this.typeId,
    required this.auditTypeName,
    required this.sessionToken,
  });

  @override
  State<AuditCategoryManagementScreen> createState() =>
      _AuditCategoryManagementScreenState();
}

class _AuditCategoryManagementScreenState
    extends State<AuditCategoryManagementScreen> {
  bool _loading = true;

  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      final result =
      await SupabaseService.getAdminAuditCategories(
        sessionToken: widget.sessionToken,
        typeId: widget.typeId,
      ).timeout(
        const Duration(seconds: 20),
      );

      if (!mounted) return;

      setState(() {
        _categories = List<Map<String, dynamic>>.from(result);
      });
    } catch (e) {
      if (await AuditAdminSession.handleSessionExpired(context, e)) {
        return;
      }
      if (!mounted) return;

      _showError(
        'Unable to load Categories: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _showCategoryDialog({
    Map<String, dynamic>? existing,
  }) async {
    final nameController = TextEditingController(
      text: existing?['category_name']?.toString() ?? '',
    );

    final descriptionController = TextEditingController(
      text: existing?['description']?.toString() ?? '',
    );

    bool active =
        existing?['active'] as bool? ?? true;

    final bool isEditing = existing != null;

    try {
      await showDialog<void>(
        context: context,
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
                  ScaffoldMessenger.of(dialogContext)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Category Name is required.',
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
                  final Map<String, dynamic> result;

                  if (isEditing) {
                    final categoryId =
                    existing['category_id']
                        ?.toString();

                    if (categoryId == null ||
                        categoryId.isEmpty) {
                      throw Exception(
                        'Category ID is missing.',
                      );
                    }

                    result =
                    await SupabaseService
                        .updateAdminAuditCategory(
                      sessionToken:
                      widget.sessionToken,
                      categoryId:
                      categoryId,
                      categoryName:
                      name,
                      description:
                      descriptionController.text
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
                    result =
                    await SupabaseService
                        .createAdminAuditCategory(
                      sessionToken:
                      widget.sessionToken,
                      typeId: widget.typeId,
                      categoryName:
                      name,
                      description:
                      descriptionController.text
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

                  if (!mounted) return;

                  final updated =
                  Map<String, dynamic>.from(result);

                  setState(() {
                    if (isEditing) {
                      final categoryId =
                      updated['category_id']
                          ?.toString();

                      final index =
                      _categories.indexWhere(
                            (row) =>
                        row['category_id']
                            ?.toString() ==
                            categoryId,
                      );

                      if (index >= 0) {
                        _categories[index] = updated;
                      }
                    } else {
                      _categories.add(updated);
                    }

                    _categories.sort(
                          (a, b) =>
                          (a['category_name']
                              ?.toString() ??
                              '')
                              .toLowerCase()
                              .compareTo(
                            (b['category_name']
                                ?.toString() ??
                                '')
                                .toLowerCase(),
                          ),
                    );
                  });

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }

                  _showMessage(
                    isEditing
                        ? 'Category updated successfully.'
                        : 'Category created successfully.',
                  );
                } catch (e) {
                  if (await AuditAdminSession.handleSessionExpired(context, e)) {
                    return;
                  }
                  if (!dialogContext.mounted) return;

                  setDialogState(() {
                    saving = false;
                  });

                  ScaffoldMessenger.of(dialogContext)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        'Unable to save Category: $e',
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
                      ? 'Edit Category'
                      : 'Create Category',
                ),
                content: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          enabled: !saving,
                          autofocus: true,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Category Name',
                            border:
                            OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller:
                          descriptionController,
                          enabled: !saving,
                          maxLines: 4,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Description',
                            border:
                            OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding:
                          EdgeInsets.zero,
                          title:
                          const Text('Active'),
                          value: active,
                          onChanged: saving
                              ? null
                              : (value) {
                            setDialogState(() {
                              active = value;
                            });
                          },
                        ),
                      ],
                    ),
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
                      width: 16,
                      height: 16,
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
                          : 'Save',
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
      descriptionController.dispose();
    }
  }

  Future<void> _deleteCategory(
      Map<String, dynamic> category,
      ) async {
    final categoryId =
    category['category_id']?.toString();

    if (categoryId == null ||
        categoryId.isEmpty) {
      _showError(
        'Category ID is missing.',
      );
      return;
    }

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
          const Text('Delete Category'),
          content: Text(
            'Delete "${category['category_name'] ?? ''}"?\n\n'
                'Questions belonging to this category '
                'will also be removed according to the '
                'database cascade rule.',
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

    if (confirmed != true) return;

    try {
      await SupabaseService
          .deleteAdminAuditCategory(
        sessionToken:
        widget.sessionToken,
        categoryId: categoryId,
      ).timeout(
        const Duration(seconds: 20),
      );

      if (!mounted) return;

      setState(() {
        _categories.removeWhere(
              (row) =>
          row['category_id']
              ?.toString() ==
              categoryId,
        );
      });

      _showMessage(
        'Category deleted successfully.',
      );
    } catch (e) {
      if (await AuditAdminSession.handleSessionExpired(context, e)) {
        return;
      }
      if (!mounted) return;

      _showError(
        'Unable to delete Category: $e',
      );
    }
  }

  void _openQuestions(
      Map<String, dynamic> category,
      ) {
    final categoryId =
    category['category_id']?.toString();

    if (categoryId == null ||
        categoryId.isEmpty) {
      _showError(
        'Category ID is missing.',
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/AUDIT/admin/questions',
      arguments: {
        'sessionToken':
        widget.sessionToken,
        'categoryId':
        categoryId,
        'categoryName':
        category['category_name']
            ?.toString() ??
            '',
      },
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
        title: Text(
          'Categories • ${widget.auditTypeName}',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
            _loading ? null : _loadCategories,
            icon:
            const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: _loading
            ? null
            : () =>
            _showCategoryDialog(),
        icon:
        const Icon(Icons.add),
        label:
        const Text('Add Category'),
      ),
      body: _loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : _categories.isEmpty
          ? const Center(
        child: Padding(
          padding:
          EdgeInsets.all(24),
          child: Text(
            'No categories are configured for this Audit Type.',
            textAlign:
            TextAlign.center,
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh:
        _loadCategories,
        child: ListView.builder(
          padding:
          const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            100,
          ),
          itemCount:
          _categories.length,
          itemBuilder:
              (context, index) {
            final category =
            _categories[index];

            final name =
                category[
                'category_name']
                    ?.toString() ??
                    '';

            final description =
                category[
                'description']
                    ?.toString() ??
                    '';

            final active =
                category['active']
                as bool? ??
                    true;

            return Card(
              margin:
              const EdgeInsets.only(
                bottom: 12,
              ),
              child: Padding(
                padding:
                const EdgeInsets.all(
                  16,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style:
                            const TextStyle(
                              fontSize: 18,
                              fontWeight:
                              FontWeight
                                  .w700,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(
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
                              _showCategoryDialog(
                                existing:
                                category,
                              );
                            } else if (value ==
                                'delete') {
                              _deleteCategory(
                                category,
                              );
                            }
                          },
                          itemBuilder:
                              (context) =>
                          const [
                            PopupMenuItem(
                              value:
                              'edit',
                              child: Text(
                                'Edit',
                              ),
                            ),
                            PopupMenuItem(
                              value:
                              'delete',
                              child: Text(
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
                        style:
                        TextStyle(
                          color: Colors
                              .grey
                              .shade700,
                        ),
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
                            _openQuestions(
                              category,
                            ),
                        icon:
                        const Icon(
                          Icons
                              .quiz_outlined,
                        ),
                        label:
                        const Text(
                          'Manage Questions',
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