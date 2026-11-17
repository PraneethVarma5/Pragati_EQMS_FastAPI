import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../services/audit/audit_admin_session.dart';

class AuditAuditorManagementScreen extends StatefulWidget {
  const AuditAuditorManagementScreen({
    super.key,
  });

  @override
  State<AuditAuditorManagementScreen> createState() =>
      _AuditAuditorManagementScreenState();
}

class _AuditAuditorManagementScreenState
    extends State<AuditAuditorManagementScreen> {
  String? _sessionToken;
  String? _adminEmail;

  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _auditors = [];
  List<Map<String, dynamic>> _filteredAuditors = [];

  final TextEditingController _searchController =
  TextEditingController();

  String _statusFilter = 'All';

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

    _searchController.addListener(_applyFilters);

    _loadAuditors();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadAuditors() async {
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
      await SupabaseService.getAdminAuditors(
        sessionToken: sessionToken,
      ).timeout(
        const Duration(seconds: 20),
      );

      if (!mounted) return;

      setState(() {
        _auditors = result;
        _loading = false;
      });

      _applyFilters();
    } catch (e) {
      if (await AuditAdminSession.handleSessionExpired(context, e)) {
        return;
      }
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showError(
        'Unable to load Auditors: $e',
      );
    }
  }

  // ============================================================
  // FILTERS
  // ============================================================

  void _applyFilters() {
    final search =
    _searchController.text.trim().toLowerCase();

    final filtered = _auditors.where((auditor) {
      final active =
          auditor['active'] as bool? ?? false;

      if (_statusFilter == 'Active' && !active) {
        return false;
      }

      if (_statusFilter == 'Inactive' && active) {
        return false;
      }

      if (search.isEmpty) {
        return true;
      }

      final name =
          auditor['auditor_name']
              ?.toString()
              .toLowerCase() ??
              '';

      final employeeId =
          auditor['employee_id']
              ?.toString()
              .toLowerCase() ??
              '';

      final email =
          auditor['email']
              ?.toString()
              .toLowerCase() ??
              '';

      return name.contains(search) ||
          employeeId.contains(search) ||
          email.contains(search);
    }).toList();

    if (!mounted) return;

    setState(() {
      _filteredAuditors = filtered;
    });
  }

  // ============================================================
  // ADD / EDIT
  // ============================================================

  Future<void> _showAuditorDialog({
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

    final nameController = TextEditingController(
      text:
      existing?['auditor_name']?.toString() ?? '',
    );

    final employeeController = TextEditingController(
      text:
      existing?['employee_id']?.toString() ?? '',
    );

    final emailController = TextEditingController(
      text:
      existing?['email']?.toString() ?? '',
    );

    bool active =
        existing?['active'] as bool? ?? true;

    final isEditing = existing != null;

    bool dialogSaving = false;

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
                title: Text(
                  isEditing
                      ? 'Edit Auditor'
                      : 'Add Auditor',
                ),
                content: SizedBox(
                  width: 500,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          textCapitalization:
                          TextCapitalization.words,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Auditor Name *',
                            border:
                            OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.person_outline,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextField(
                          controller:
                          employeeController,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Employee ID *',
                            border:
                            OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.badge_outlined,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextField(
                          controller:
                          emailController,
                          keyboardType:
                          TextInputType.emailAddress,
                          decoration:
                          const InputDecoration(
                            labelText: 'Email *',
                            border:
                            OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        SwitchListTile(
                          contentPadding:
                          EdgeInsets.zero,
                          title:
                          const Text('Active'),
                          subtitle: Text(
                            active
                                ? 'Auditor can be selected for new audits.'
                                : 'Auditor will not appear in new audits.',
                          ),
                          value: active,
                          onChanged: dialogSaving
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
                    onPressed: dialogSaving
                        ? null
                        : () {
                      Navigator.pop(
                        dialogContext,
                      );
                    },
                    child: const Text('Cancel'),
                  ),

                  ElevatedButton(
                    onPressed: dialogSaving
                        ? null
                        : () async {
                      final name =
                      nameController.text.trim();

                      final employeeId =
                      employeeController
                          .text
                          .trim();

                      final email =
                      emailController.text.trim();

                      if (name.isEmpty) {
                        _dialogError(
                          dialogContext,
                          'Auditor Name is required.',
                        );
                        return;
                      }

                      if (employeeId.isEmpty) {
                        _dialogError(
                          dialogContext,
                          'Employee ID is required.',
                        );
                        return;
                      }

                      if (email.isEmpty) {
                        _dialogError(
                          dialogContext,
                          'Email is required.',
                        );
                        return;
                      }

                      if (!_isValidEmail(email)) {
                        _dialogError(
                          dialogContext,
                          'Enter a valid email address.',
                        );
                        return;
                      }

                      setDialogState(() {
                        dialogSaving = true;
                      });

                      if (mounted) {
                        setState(() {
                          _saving = true;
                        });
                      }

                      try {
                        Map<String, dynamic>
                        savedAuditor;

                        if (isEditing) {
                          savedAuditor =
                          await SupabaseService
                              .updateAdminAuditor(
                            sessionToken:
                            sessionToken,
                            auditorId:
                            existing[
                            'auditor_id']
                                .toString(),
                            auditorName: name,
                            employeeId:
                            employeeId,
                            email: email,
                            active: active,
                          ).timeout(
                            const Duration(
                              seconds: 20,
                            ),
                          );
                        } else {
                          savedAuditor =
                          await SupabaseService
                              .createAdminAuditor(
                            sessionToken:
                            sessionToken,
                            auditorName: name,
                            employeeId:
                            employeeId,
                            email: email,
                            active: active,
                          ).timeout(
                            const Duration(
                              seconds: 20,
                            ),
                          );
                        }

                        if (!mounted) return;

                        setState(() {
                          _saving = false;

                          if (isEditing) {
                            final index =
                            _auditors.indexWhere(
                                  (item) =>
                              item[
                              'auditor_id']
                                  ?.toString() ==
                                  existing[
                                  'auditor_id']
                                      ?.toString(),
                            );

                            if (index >= 0 &&
                                index <
                                    _auditors.length) {
                              _auditors[index] = {
                                ..._auditors[index],
                                ...savedAuditor,
                                'auditor_id':
                                savedAuditor[
                                'auditor_id'] ??
                                    existing[
                                    'auditor_id'],
                                'auditor_name':
                                savedAuditor[
                                'auditor_name'] ??
                                    name,
                                'employee_id':
                                savedAuditor[
                                'employee_id'] ??
                                    employeeId,
                                'email':
                                savedAuditor[
                                'email'] ??
                                    email,
                                'active':
                                savedAuditor[
                                'active'] ??
                                    active,
                              };
                            }
                          } else {
                            _auditors.add({
                              ...savedAuditor,
                              'auditor_name':
                              savedAuditor[
                              'auditor_name'] ??
                                  name,
                              'employee_id':
                              savedAuditor[
                              'employee_id'] ??
                                  employeeId,
                              'email':
                              savedAuditor[
                              'email'] ??
                                  email,
                              'active':
                              savedAuditor[
                              'active'] ??
                                  active,
                            });
                          }
                        });

                        _applyFilters();

                        if (!dialogContext.mounted) {
                          return;
                        }

                        Navigator.pop(
                          dialogContext,
                        );

                        _showMessage(
                          isEditing
                              ? 'Auditor updated successfully.'
                              : 'Auditor created successfully.',
                        );
                      } catch (e) {
                        if (await AuditAdminSession.handleSessionExpired(context, e)) {
                          return;
                        }
                        if (mounted) {
                          setState(() {
                            _saving = false;
                          });
                        }

                        if (!dialogContext.mounted) {
                          return;
                        }

                        setDialogState(() {
                          dialogSaving = false;
                        });

                        _dialogError(
                          dialogContext,
                          'Unable to save Auditor: $e',
                        );
                      }
                    },
                    child: dialogSaving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      isEditing
                          ? 'Update'
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
      employeeController.dispose();
      emailController.dispose();

      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteAuditor(
      Map<String, dynamic> auditor,
      ) async {
    final sessionToken = _sessionToken;

    if (sessionToken == null ||
        sessionToken.isEmpty) {
      _showError(
        'Admin session is missing.',
      );
      return;
    }

    final auditorId =
    auditor['auditor_id']?.toString();

    if (auditorId == null ||
        auditorId.isEmpty) {
      _showError(
        'Invalid Auditor ID.',
      );
      return;
    }

    final name =
        auditor['auditor_name']?.toString() ??
            'this auditor';

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
          const Text('Delete Auditor'),
          content: Text(
            'Are you sure you want to delete "$name"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
              const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
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

    if (!mounted) return;

    setState(() {
      _saving = true;
    });

    try {
      await SupabaseService.deleteAdminAuditor(
        sessionToken: sessionToken,
        auditorId: auditorId,
      ).timeout(
        const Duration(seconds: 20),
      );

      if (!mounted) return;

      setState(() {
        _auditors.removeWhere(
              (item) =>
          item['auditor_id']?.toString() ==
              auditorId,
        );

        _saving = false;
      });

      _applyFilters();

      _showMessage(
        'Auditor deleted successfully.',
      );
    } catch (e) {
      if (await AuditAdminSession.handleSessionExpired(context, e)) {
        return;
      }
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showError(
        'Unable to delete Auditor: $e',
      );
    }
  }

  // ============================================================
  // ACTIVE / INACTIVE
  // ============================================================

  Future<void> _toggleAuditor(
      Map<String, dynamic> auditor,
      ) async {
    final sessionToken = _sessionToken;

    if (sessionToken == null ||
        sessionToken.isEmpty) {
      _showError(
        'Admin session is missing.',
      );
      return;
    }

    final auditorId =
    auditor['auditor_id']?.toString();

    if (auditorId == null ||
        auditorId.isEmpty) {
      _showError(
        'Invalid Auditor ID.',
      );
      return;
    }

    final currentActive =
        auditor['active'] as bool? ?? false;

    if (!mounted) return;

    setState(() {
      _saving = true;
    });

    try {
      final updated =
      await SupabaseService.updateAdminAuditor(
        sessionToken: sessionToken,
        auditorId: auditorId,
        auditorName:
        auditor['auditor_name']
            ?.toString() ??
            '',
        employeeId:
        auditor['employee_id']
            ?.toString() ??
            '',
        email:
        auditor['email']?.toString() ??
            '',
        active: !currentActive,
      ).timeout(
        const Duration(seconds: 20),
      );

      if (!mounted) return;

      final index =
      _auditors.indexWhere(
            (item) =>
        item['auditor_id']?.toString() ==
            auditorId,
      );

      if (index >= 0) {
        setState(() {
          _auditors[index] = {
            ..._auditors[index],
            ...updated,
            'active':
            updated['active'] ??
                !currentActive,
          };

          _saving = false;
        });
      } else {
        setState(() {
          _saving = false;
        });
      }

      _applyFilters();

      _showMessage(
        !currentActive
            ? 'Auditor activated.'
            : 'Auditor deactivated.',
      );
    } catch (e) {
      if (await AuditAdminSession.handleSessionExpired(context, e)) {
        return;
      }
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showError(
        'Unable to update Auditor: $e',
      );
    }
  }

  // ============================================================
  // EMAIL VALIDATION
  // ============================================================

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
  }

  // ============================================================
  // DIALOG ERROR
  // ============================================================

  void _dialogError(
      BuildContext context,
      String message,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        Colors.red.shade700,
      ),
    );
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        Colors.red.shade700,
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  void _logout() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/AUDIT',
          (route) => false,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor:
        const Color(0xFF172033),
        elevation: 0,

        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            Navigator.pop(context);
          },
          icon:
          const Icon(Icons.arrow_back),
        ),

        title: const Text(
          'Auditor Management',
          style: TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),

        actions: [
          if (_adminEmail != null &&
              _adminEmail!.isNotEmpty)
            Center(
              child: Padding(
                padding:
                const EdgeInsets.only(
                  right: 8,
                ),
                child: Text(
                  _adminEmail!,
                  style: const TextStyle(
                    fontSize: 12,
                    color:
                    Color(0xFF6B7280),
                  ),
                ),
              ),
            ),

          IconButton(
            tooltip: 'Logout',
            onPressed:
            _saving ? null : _logout,
            icon: const Icon(
              Icons.logout_outlined,
            ),
          ),
        ],
      ),

      floatingActionButton:
      FloatingActionButton.extended(
        onPressed:
        _saving
            ? null
            : () {
          _showAuditorDialog();
        },
        icon: const Icon(
          Icons.person_add_outlined,
        ),
        label:
        const Text('Add Auditor'),
      ),

      body: _loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _loadAuditors,
        child: _buildBody(),
      ),
    );
  }

  // ============================================================
  // MAIN BODY
  // ============================================================

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (
          context,
          constraints,
          ) {
        final availableWidth =
            constraints.maxWidth;

        final contentWidth =
        availableWidth < 1050
            ? availableWidth
            : 1050.0;

        return SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),

          padding:
          const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),

          child: Align(
            alignment: Alignment.topCenter,

            child: SizedBox(
              width: contentWidth,

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,

                children: [
                  // ------------------------------------------------
                  // HEADER
                  // ------------------------------------------------

                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Auditors',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight:
                                FontWeight.w800,
                                color:
                                Color(0xFF172033),
                              ),
                            ),

                            const SizedBox(
                              height: 5,
                            ),

                            Text(
                              'Manage auditors available for Audit assignments.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors
                                    .grey
                                    .shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration:
                        BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                          BorderRadius.circular(
                            20,
                          ),
                          border:
                          Border.all(
                            color:
                            const Color(
                              0xFFE1E4E8,
                            ),
                          ),
                        ),
                        child: Text(
                          '${_filteredAuditors.length} auditors',
                          style:
                          const TextStyle(
                            fontSize: 12,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ------------------------------------------------
                  // SEARCH + FILTER
                  // ------------------------------------------------

                  Container(
                    padding:
                    const EdgeInsets.all(
                      14,
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
                          0xFFE1E4E8,
                        ),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (
                          context,
                          searchConstraints,
                          ) {
                        if (searchConstraints
                            .maxWidth <
                            650) {
                          return Column(
                            children: [
                              _searchField(),

                              const SizedBox(
                                height: 12,
                              ),

                              _statusDropdown(),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              child:
                              _searchField(),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            SizedBox(
                              width: 180,
                              child:
                              _statusDropdown(),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // ------------------------------------------------
                  // TABLE
                  // ------------------------------------------------

                  _filteredAuditors.isEmpty
                      ? _buildEmpty()
                      : _buildAuditorTable(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SEARCH FIELD
  // ============================================================

  Widget _searchField() {
    return TextField(
      controller:
      _searchController,
      decoration:
      const InputDecoration(
        hintText:
        'Search auditor, employee ID or email...',
        prefixIcon:
        Icon(Icons.search_rounded),
        border:
        OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  // ============================================================
  // STATUS FILTER
  // ============================================================

  Widget _statusDropdown() {
    return DropdownButtonFormField<String>(
      value: _statusFilter,
      decoration:
      const InputDecoration(
        labelText: 'Status',
        border:
        OutlineInputBorder(),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(
          value: 'All',
          child: Text('All'),
        ),
        DropdownMenuItem(
          value: 'Active',
          child: Text('Active'),
        ),
        DropdownMenuItem(
          value: 'Inactive',
          child: Text('Inactive'),
        ),
      ],
      onChanged: (value) {
        if (value == null) {
          return;
        }

        setState(() {
          _statusFilter = value;
        });

        _applyFilters();
      },
    );
  }

  // ============================================================
  // TABLE
  // ============================================================

  Widget _buildAuditorTable() {
    return Container(
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        border:
        Border.all(
          color:
          const Color(0xFFE1E4E8),
        ),
      ),

      child: ClipRRect(
        borderRadius:
        BorderRadius.circular(14),

        child: SingleChildScrollView(
          scrollDirection:
          Axis.horizontal,

          child: DataTable(
            headingRowColor:
            WidgetStateProperty.all(
              const Color(0xFFF8F9FC),
            ),

            columnSpacing: 35,

            horizontalMargin: 18,

            dataRowMinHeight: 62,

            dataRowMaxHeight: 72,

            columns: const [
              DataColumn(
                label: Text(
                  'Auditor',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),

              DataColumn(
                label: Text(
                  'Employee ID',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),

              DataColumn(
                label: Text(
                  'Email',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),

              DataColumn(
                label: Text(
                  'Status',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),

              DataColumn(
                label: Text(
                  'Actions',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ],

            rows: _filteredAuditors
                .map(
                  (auditor) {
                final name =
                    auditor['auditor_name']
                        ?.toString() ??
                        '';

                final employeeId =
                    auditor['employee_id']
                        ?.toString() ??
                        '';

                final email =
                    auditor['email']
                        ?.toString() ??
                        '';

                final active =
                    auditor['active']
                    as bool? ??
                        false;

                return DataRow(
                  cells: [
                    // ------------------------------------------
                    // AUDITOR
                    // ------------------------------------------

                    DataCell(
                      Row(
                        mainAxisSize:
                        MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration:
                            BoxDecoration(
                              color:
                              const Color(
                                0xFFF0E8FF,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                9,
                              ),
                            ),
                            child:
                            const Icon(
                              Icons
                                  .person_outline,
                              size: 19,
                              color:
                              Color(
                                0xFF7655B7,
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          Text(
                            name,
                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ------------------------------------------
                    // EMPLOYEE ID
                    // ------------------------------------------

                    DataCell(
                      Text(employeeId),
                    ),

                    // ------------------------------------------
                    // EMAIL
                    // ------------------------------------------

                    DataCell(
                      Text(email),
                    ),

                    // ------------------------------------------
                    // STATUS
                    // ------------------------------------------

                    DataCell(
                      _statusChip(active),
                    ),

                    // ------------------------------------------
                    // ACTIONS
                    // ------------------------------------------

                    DataCell(
                      Row(
                        mainAxisSize:
                        MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Edit',
                            onPressed:
                            _saving
                                ? null
                                : () {
                              _showAuditorDialog(
                                existing:
                                auditor,
                              );
                            },
                            icon:
                            const Icon(
                              Icons
                                  .edit_outlined,
                              size: 19,
                            ),
                          ),

                          IconButton(
                            tooltip: active
                                ? 'Deactivate'
                                : 'Activate',
                            onPressed:
                            _saving
                                ? null
                                : () {
                              _toggleAuditor(
                                auditor,
                              );
                            },
                            icon: Icon(
                              active
                                  ? Icons
                                  .block_outlined
                                  : Icons
                                  .check_circle_outline,
                              size: 19,
                            ),
                          ),

                          IconButton(
                            tooltip: 'Delete',
                            onPressed:
                            _saving
                                ? null
                                : () {
                              _deleteAuditor(
                                auditor,
                              );
                            },
                            icon:
                            const Icon(
                              Icons
                                  .delete_outline,
                              size: 19,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ).toList(),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _statusChip(bool active) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
      BoxDecoration(
        color: active
            ? const Color(0xFFEAF7EF)
            : const Color(0xFFF1F2F4),
        borderRadius:
        BorderRadius.circular(8),
      ),
      child: Text(
        active
            ? 'Active'
            : 'Inactive',
        style: TextStyle(
          fontSize: 12,
          fontWeight:
          FontWeight.w700,
          color: active
              ? const Color(0xFF2E9B55)
              : const Color(0xFF6B7280),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(
        vertical: 70,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        border:
        Border.all(
          color:
          const Color(0xFFE1E4E8),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration:
            BoxDecoration(
              color:
              const Color(0xFFF0F2F5),
              borderRadius:
              BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.people_outline,
              size: 29,
              color:
              Color(0xFF747B86),
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          const Text(
            'No auditors found',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            _auditors.isEmpty
                ? 'Add an auditor to make them available for Audit assignments.'
                : 'No auditors match the current search or filter.',
            textAlign:
            TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color:
              Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
//
// import '../../services/supabase_service.dart';
//
// class AuditAuditorManagementScreen extends StatefulWidget {
//   const AuditAuditorManagementScreen({
//     super.key,
//   });
//
//   @override
//   State<AuditAuditorManagementScreen> createState() =>
//       _AuditAuditorManagementScreenState();
// }
//
// class _AuditAuditorManagementScreenState
//     extends State<AuditAuditorManagementScreen> {
//   String? _sessionToken;
//   String? _adminEmail;
//
//   bool _loading = true;
//   bool _saving = false;
//
//   List<Map<String, dynamic>> _auditors = [];
//   List<Map<String, dynamic>> _filteredAuditors = [];
//
//   final TextEditingController _searchController =
//   TextEditingController();
//
//   String _statusFilter = 'All';
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//
//     if (_sessionToken != null) {
//       return;
//     }
//
//     final arguments =
//         ModalRoute.of(context)?.settings.arguments;
//
//     if (arguments is Map) {
//       _sessionToken =
//           arguments['sessionToken']?.toString();
//
//       _adminEmail =
//           arguments['email']?.toString();
//     }
//
//     if (_sessionToken == null ||
//         _sessionToken!.isEmpty) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (!mounted) return;
//
//         Navigator.pushReplacementNamed(
//           context,
//           '/AUDIT/admin/login',
//         );
//       });
//
//       return;
//     }
//
//     _searchController.addListener(_applyFilters);
//
//     _loadAuditors();
//   }
//
//   @override
//   void dispose() {
//     _searchController.removeListener(_applyFilters);
//     _searchController.dispose();
//
//     super.dispose();
//   }
//
//   // ============================================================
//   // LOAD
//   // ============================================================
//
//   Future<void> _loadAuditors() async {
//     final sessionToken = _sessionToken;
//
//     if (sessionToken == null ||
//         sessionToken.isEmpty) {
//       return;
//     }
//
//     if (!mounted) return;
//
//     setState(() {
//       _loading = true;
//     });
//
//     try {
//       final result =
//       await SupabaseService.getAdminAuditors(
//         sessionToken: sessionToken,
//       ).timeout(
//         const Duration(seconds: 20),
//       );
//
//       if (!mounted) return;
//
//       setState(() {
//         _auditors = result;
//         _loading = false;
//       });
//
//       _applyFilters();
//     } catch (e) {
//       if (!mounted) return;
//
//       setState(() {
//         _loading = false;
//       });
//
//       _showError(
//         'Unable to load Auditors: $e',
//       );
//     }
//   }
//
//   // ============================================================
//   // FILTERS
//   // ============================================================
//
//   void _applyFilters() {
//     final search =
//     _searchController.text.trim().toLowerCase();
//
//     final filtered = _auditors.where((auditor) {
//       final active =
//           auditor['active'] as bool? ?? false;
//
//       if (_statusFilter == 'Active' && !active) {
//         return false;
//       }
//
//       if (_statusFilter == 'Inactive' && active) {
//         return false;
//       }
//
//       if (search.isEmpty) {
//         return true;
//       }
//
//       final name =
//           auditor['auditor_name']
//               ?.toString()
//               .toLowerCase() ??
//               '';
//
//       final employeeId =
//           auditor['employee_id']
//               ?.toString()
//               .toLowerCase() ??
//               '';
//
//       final email =
//           auditor['email']
//               ?.toString()
//               .toLowerCase() ??
//               '';
//
//       return name.contains(search) ||
//           employeeId.contains(search) ||
//           email.contains(search);
//     }).toList();
//
//     if (!mounted) return;
//
//     setState(() {
//       _filteredAuditors = filtered;
//     });
//   }
//
//   // ============================================================
//   // ADD / EDIT
//   // ============================================================
//
//   Future<void> _showAuditorDialog({
//     Map<String, dynamic>? existing,
//   }) async {
//     final sessionToken = _sessionToken;
//
//     if (sessionToken == null ||
//         sessionToken.isEmpty) {
//       _showError(
//         'Admin session is missing.',
//       );
//       return;
//     }
//
//     final nameController = TextEditingController(
//       text:
//       existing?['auditor_name']?.toString() ?? '',
//     );
//
//     final employeeController = TextEditingController(
//       text:
//       existing?['employee_id']?.toString() ?? '',
//     );
//
//     final emailController = TextEditingController(
//       text:
//       existing?['email']?.toString() ?? '',
//     );
//
//     bool active =
//         existing?['active'] as bool? ?? true;
//
//     final isEditing = existing != null;
//
//     bool dialogSaving = false;
//
//     try {
//       await showDialog<void>(
//         context: context,
//         barrierDismissible: false,
//         builder: (dialogContext) {
//           return StatefulBuilder(
//             builder: (
//                 context,
//                 setDialogState,
//                 ) {
//               return AlertDialog(
//                 title: Text(
//                   isEditing
//                       ? 'Edit Auditor'
//                       : 'Add Auditor',
//                 ),
//                 content: SizedBox(
//                   width: 500,
//                   child: SingleChildScrollView(
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         TextField(
//                           controller: nameController,
//                           textCapitalization:
//                           TextCapitalization.words,
//                           decoration:
//                           const InputDecoration(
//                             labelText:
//                             'Auditor Name *',
//                             border:
//                             OutlineInputBorder(),
//                             prefixIcon: Icon(
//                               Icons.person_outline,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 14),
//                         TextField(
//                           controller:
//                           employeeController,
//                           decoration:
//                           const InputDecoration(
//                             labelText:
//                             'Employee ID *',
//                             border:
//                             OutlineInputBorder(),
//                             prefixIcon: Icon(
//                               Icons.badge_outlined,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 14),
//                         TextField(
//                           controller:
//                           emailController,
//                           keyboardType:
//                           TextInputType.emailAddress,
//                           decoration:
//                           const InputDecoration(
//                             labelText: 'Email *',
//                             border:
//                             OutlineInputBorder(),
//                             prefixIcon: Icon(
//                               Icons.email_outlined,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         SwitchListTile(
//                           contentPadding:
//                           EdgeInsets.zero,
//                           title:
//                           const Text('Active'),
//                           subtitle: Text(
//                             active
//                                 ? 'Auditor can be selected for new audits.'
//                                 : 'Auditor will not appear in new audits.',
//                           ),
//                           value: active,
//                           onChanged: dialogSaving
//                               ? null
//                               : (value) {
//                             setDialogState(() {
//                               active = value;
//                             });
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 actions: [
//                   TextButton(
//                     onPressed: dialogSaving
//                         ? null
//                         : () {
//                       Navigator.pop(
//                         dialogContext,
//                       );
//                     },
//                     child:
//                     const Text('Cancel'),
//                   ),
//                   ElevatedButton(
//                     onPressed: dialogSaving
//                         ? null
//                         : () async {
//                       final name =
//                       nameController.text.trim();
//
//                       final employeeId =
//                       employeeController
//                           .text
//                           .trim();
//
//                       final email =
//                       emailController.text.trim();
//
//                       if (name.isEmpty) {
//                         _dialogError(
//                           dialogContext,
//                           'Auditor Name is required.',
//                         );
//                         return;
//                       }
//
//                       if (employeeId.isEmpty) {
//                         _dialogError(
//                           dialogContext,
//                           'Employee ID is required.',
//                         );
//                         return;
//                       }
//
//                       if (email.isEmpty) {
//                         _dialogError(
//                           dialogContext,
//                           'Email is required.',
//                         );
//                         return;
//                       }
//
//                       if (!_isValidEmail(email)) {
//                         _dialogError(
//                           dialogContext,
//                           'Enter a valid email address.',
//                         );
//                         return;
//                       }
//
//                       setDialogState(() {
//                         dialogSaving = true;
//                       });
//
//                       if (mounted) {
//                         setState(() {
//                           _saving = true;
//                         });
//                       }
//
//                       try {
//                         Map<String, dynamic>
//                         savedAuditor;
//
//                         if (isEditing) {
//                           savedAuditor =
//                           await SupabaseService
//                               .updateAdminAuditor(
//                             sessionToken:
//                             sessionToken,
//                             auditorId:
//                             existing[
//                             'auditor_id']
//                                 .toString(),
//                             auditorName: name,
//                             employeeId:
//                             employeeId,
//                             email: email,
//                             active: active,
//                           ).timeout(
//                             const Duration(
//                               seconds: 20,
//                             ),
//                           );
//                         } else {
//                           savedAuditor =
//                           await SupabaseService
//                               .createAdminAuditor(
//                             sessionToken:
//                             sessionToken,
//                             auditorName: name,
//                             employeeId:
//                             employeeId,
//                             email: email,
//                             active: active,
//                           ).timeout(
//                             const Duration(
//                               seconds: 20,
//                             ),
//                           );
//                         }
//
//                         if (!mounted) return;
//
//                         setState(() {
//                           _saving = false;
//
//                           if (isEditing) {
//                             final index =
//                             _auditors.indexWhere(
//                                   (item) =>
//                               item[
//                               'auditor_id']
//                                   ?.toString() ==
//                                   existing[
//                                   'auditor_id']
//                                       ?.toString(),
//                             );
//
//                             if (index >= 0 &&
//                                 index <
//                                     _auditors.length) {
//                               _auditors[index] = {
//                                 ..._auditors[index],
//                                 ...savedAuditor,
//                                 'auditor_id':
//                                 savedAuditor[
//                                 'auditor_id'] ??
//                                     existing[
//                                     'auditor_id'],
//                                 'auditor_name':
//                                 savedAuditor[
//                                 'auditor_name'] ??
//                                     name,
//                                 'employee_id':
//                                 savedAuditor[
//                                 'employee_id'] ??
//                                     employeeId,
//                                 'email':
//                                 savedAuditor[
//                                 'email'] ??
//                                     email,
//                                 'active':
//                                 savedAuditor[
//                                 'active'] ??
//                                     active,
//                               };
//                             }
//                           } else {
//                             _auditors.add({
//                               ...savedAuditor,
//                               'auditor_name':
//                               savedAuditor[
//                               'auditor_name'] ??
//                                   name,
//                               'employee_id':
//                               savedAuditor[
//                               'employee_id'] ??
//                                   employeeId,
//                               'email':
//                               savedAuditor[
//                               'email'] ??
//                                   email,
//                               'active':
//                               savedAuditor[
//                               'active'] ??
//                                   active,
//                             });
//                           }
//                         });
//
//                         _applyFilters();
//
//                         if (!dialogContext.mounted) {
//                           return;
//                         }
//
//                         Navigator.pop(
//                           dialogContext,
//                         );
//
//                         _showMessage(
//                           isEditing
//                               ? 'Auditor updated successfully.'
//                               : 'Auditor created successfully.',
//                         );
//                       } catch (e) {
//                         if (mounted) {
//                           setState(() {
//                             _saving = false;
//                           });
//                         }
//
//                         if (!dialogContext.mounted) {
//                           return;
//                         }
//
//                         setDialogState(() {
//                           dialogSaving = false;
//                         });
//
//                         _dialogError(
//                           dialogContext,
//                           'Unable to save Auditor: $e',
//                         );
//                       }
//                     },
//                     child: dialogSaving
//                         ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child:
//                       CircularProgressIndicator(
//                         strokeWidth: 2,
//                       ),
//                     )
//                         : Text(
//                       isEditing
//                           ? 'Update'
//                           : 'Save',
//                     ),
//                   ),
//                 ],
//               );
//             },
//           );
//         },
//       );
//     } finally {
//       nameController.dispose();
//       employeeController.dispose();
//       emailController.dispose();
//
//       if (mounted) {
//         setState(() {
//           _saving = false;
//         });
//       }
//     }
//   }
//
//   // ============================================================
//   // DELETE
//   // ============================================================
//
//   Future<void> _deleteAuditor(
//       Map<String, dynamic> auditor,
//       ) async {
//     final sessionToken = _sessionToken;
//
//     if (sessionToken == null ||
//         sessionToken.isEmpty) {
//       _showError(
//         'Admin session is missing.',
//       );
//       return;
//     }
//
//     final auditorId =
//     auditor['auditor_id']?.toString();
//
//     if (auditorId == null ||
//         auditorId.isEmpty) {
//       _showError(
//         'Invalid Auditor ID.',
//       );
//       return;
//     }
//
//     final name =
//         auditor['auditor_name']?.toString() ??
//             'this auditor';
//
//     final confirmed =
//     await showDialog<bool>(
//       context: context,
//       builder: (dialogContext) {
//         return AlertDialog(
//           title:
//           const Text('Delete Auditor'),
//           content: Text(
//             'Are you sure you want to delete "$name"?',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(
//                   dialogContext,
//                   false,
//                 );
//               },
//               child:
//               const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(
//                   dialogContext,
//                   true,
//                 );
//               },
//               child:
//               const Text('Delete'),
//             ),
//           ],
//         );
//       },
//     );
//
//     if (confirmed != true) {
//       return;
//     }
//
//     if (!mounted) return;
//
//     setState(() {
//       _saving = true;
//     });
//
//     try {
//       await SupabaseService.deleteAdminAuditor(
//         sessionToken: sessionToken,
//         auditorId: auditorId,
//       ).timeout(
//         const Duration(seconds: 20),
//       );
//
//       if (!mounted) return;
//
//       setState(() {
//         _auditors.removeWhere(
//               (item) =>
//           item['auditor_id']?.toString() ==
//               auditorId,
//         );
//
//         _saving = false;
//       });
//
//       _applyFilters();
//
//       _showMessage(
//         'Auditor deleted successfully.',
//       );
//     } catch (e) {
//       if (!mounted) return;
//
//       setState(() {
//         _saving = false;
//       });
//
//       _showError(
//         'Unable to delete Auditor: $e',
//       );
//     }
//   }
//
//   // ============================================================
//   // ACTIVE / INACTIVE
//   // ============================================================
//
//   Future<void> _toggleAuditor(
//       Map<String, dynamic> auditor,
//       ) async {
//     final sessionToken = _sessionToken;
//
//     if (sessionToken == null ||
//         sessionToken.isEmpty) {
//       _showError(
//         'Admin session is missing.',
//       );
//       return;
//     }
//
//     final auditorId =
//     auditor['auditor_id']?.toString();
//
//     if (auditorId == null ||
//         auditorId.isEmpty) {
//       _showError(
//         'Invalid Auditor ID.',
//       );
//       return;
//     }
//
//     final currentActive =
//         auditor['active'] as bool? ?? false;
//
//     if (!mounted) return;
//
//     setState(() {
//       _saving = true;
//     });
//
//     try {
//       final updated =
//       await SupabaseService.updateAdminAuditor(
//         sessionToken: sessionToken,
//         auditorId: auditorId,
//         auditorName:
//         auditor['auditor_name']
//             ?.toString() ??
//             '',
//         employeeId:
//         auditor['employee_id']
//             ?.toString() ??
//             '',
//         email:
//         auditor['email']?.toString() ??
//             '',
//         active: !currentActive,
//       ).timeout(
//         const Duration(seconds: 20),
//       );
//
//       if (!mounted) return;
//
//       final index =
//       _auditors.indexWhere(
//             (item) =>
//         item['auditor_id']?.toString() ==
//             auditorId,
//       );
//
//       if (index >= 0) {
//         setState(() {
//           _auditors[index] = {
//             ..._auditors[index],
//             ...updated,
//             'active':
//             updated['active'] ??
//                 !currentActive,
//           };
//
//           _saving = false;
//         });
//       } else {
//         setState(() {
//           _saving = false;
//         });
//       }
//
//       _applyFilters();
//
//       _showMessage(
//         !currentActive
//             ? 'Auditor activated.'
//             : 'Auditor deactivated.',
//       );
//     } catch (e) {
//       if (!mounted) return;
//
//       setState(() {
//         _saving = false;
//       });
//
//       _showError(
//         'Unable to update Auditor: $e',
//       );
//     }
//   }
//
//   // ============================================================
//   // EMAIL VALIDATION
//   // ============================================================
//
//   bool _isValidEmail(String email) {
//     return RegExp(
//       r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
//     ).hasMatch(email);
//   }
//
//   // ============================================================
//   // DIALOG ERROR
//   // ============================================================
//
//   void _dialogError(
//       BuildContext context,
//       String message,
//       ) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor:
//         Colors.red.shade700,
//       ),
//     );
//   }
//
//   // ============================================================
//   // MESSAGES
//   // ============================================================
//
//   void _showError(String message) {
//     if (!mounted) return;
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor:
//         Colors.red.shade700,
//         behavior:
//         SnackBarBehavior.floating,
//       ),
//     );
//   }
//
//   void _showMessage(String message) {
//     if (!mounted) return;
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         behavior:
//         SnackBarBehavior.floating,
//       ),
//     );
//   }
//
//   // ============================================================
//   // LOGOUT
//   // ============================================================
//
//   void _logout() {
//     Navigator.pushNamedAndRemoveUntil(
//       context,
//       '/AUDIT',
//           (route) => false,
//     );
//   }
//
//   // ============================================================
//   // BUILD
//   // ============================================================
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor:
//       const Color(0xFFF5F7FB),
//
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         foregroundColor:
//         const Color(0xFF172033),
//         elevation: 0,
//
//         leading: IconButton(
//           tooltip: 'Back',
//           onPressed: () {
//             Navigator.pop(context);
//           },
//           icon:
//           const Icon(Icons.arrow_back),
//         ),
//
//         title: const Text(
//           'Auditor Management',
//           style: TextStyle(
//             fontWeight:
//             FontWeight.w700,
//           ),
//         ),
//
//         actions: [
//           if (_adminEmail != null &&
//               _adminEmail!.isNotEmpty)
//             Center(
//               child: Padding(
//                 padding:
//                 const EdgeInsets.only(
//                   right: 8,
//                 ),
//                 child: Text(
//                   _adminEmail!,
//                   style: const TextStyle(
//                     fontSize: 12,
//                     color:
//                     Color(0xFF6B7280),
//                   ),
//                 ),
//               ),
//             ),
//
//           IconButton(
//             tooltip: 'Logout',
//             onPressed:
//             _saving ? null : _logout,
//             icon: const Icon(
//               Icons.logout_outlined,
//             ),
//           ),
//         ],
//       ),
//
//       floatingActionButton:
//       FloatingActionButton.extended(
//         onPressed:
//         _saving
//             ? null
//             : () {
//           _showAuditorDialog();
//         },
//         icon: const Icon(
//           Icons.person_add_outlined,
//         ),
//         label:
//         const Text('Add Auditor'),
//       ),
//
//       body: _loading
//           ? const Center(
//         child:
//         CircularProgressIndicator(),
//       )
//           : RefreshIndicator(
//         onRefresh: _loadAuditors,
//         child: _buildBody(),
//       ),
//     );
//   }
//
//   // ============================================================
//   // MAIN BODY
//   // ============================================================
//
//   Widget _buildBody() {
//     return LayoutBuilder(
//       builder: (
//           context,
//           constraints,
//           ) {
//         final screenWidth =
//             constraints.maxWidth;
//
//         /*
//          * Overall page content.
//          *
//          * This is deliberately NOT stretched to the
//          * complete browser width.
//          */
//         final maxContentWidth =
//         screenWidth < 1100
//             ? screenWidth - 40
//             : 1050.0;
//
//         return SingleChildScrollView(
//           physics:
//           const AlwaysScrollableScrollPhysics(),
//
//           padding:
//           const EdgeInsets.symmetric(
//             horizontal: 20,
//             vertical: 24,
//           ),
//
//           child: Center(
//             child: SizedBox(
//               width: maxContentWidth,
//
//               child: Column(
//                 crossAxisAlignment:
//                 CrossAxisAlignment.center,
//
//                 children: [
//                   // ------------------------------------------------
//                   // HEADER
//                   // ------------------------------------------------
//
//                   SizedBox(
//                     width: 900,
//                     child: Row(
//                       crossAxisAlignment:
//                       CrossAxisAlignment.start,
//                       children: [
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment:
//                             CrossAxisAlignment.start,
//                             children: [
//                               const Text(
//                                 'Auditors',
//                                 style: TextStyle(
//                                   fontSize: 24,
//                                   fontWeight:
//                                   FontWeight.w800,
//                                   color:
//                                   Color(0xFF172033),
//                                 ),
//                               ),
//
//                               const SizedBox(
//                                 height: 5,
//                               ),
//
//                               Text(
//                                 'Manage auditors available for Audit assignments.',
//                                 style: TextStyle(
//                                   fontSize: 13,
//                                   color: Colors
//                                       .grey
//                                       .shade600,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//
//                         Container(
//                           padding:
//                           const EdgeInsets
//                               .symmetric(
//                             horizontal: 11,
//                             vertical: 7,
//                           ),
//                           decoration:
//                           BoxDecoration(
//                             color:
//                             Colors.white,
//                             borderRadius:
//                             BorderRadius
//                                 .circular(
//                               20,
//                             ),
//                             border:
//                             Border.all(
//                               color:
//                               const Color(
//                                 0xFFE1E4E8,
//                               ),
//                             ),
//                           ),
//                           child: Text(
//                             '${_filteredAuditors.length} auditors',
//                             style:
//                             const TextStyle(
//                               fontSize: 12,
//                               fontWeight:
//                               FontWeight.w700,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   const SizedBox(
//                     height: 20,
//                   ),
//
//                   // ------------------------------------------------
//                   // SEARCH / FILTER CARD
//                   // ------------------------------------------------
//
//                   SizedBox(
//                     width: 900,
//                     child: Container(
//                       padding:
//                       const EdgeInsets.all(
//                         14,
//                       ),
//                       decoration:
//                       BoxDecoration(
//                         color:
//                         Colors.white,
//                         borderRadius:
//                         BorderRadius
//                             .circular(
//                           14,
//                         ),
//                         border:
//                         Border.all(
//                           color:
//                           const Color(
//                             0xFFE1E4E8,
//                           ),
//                         ),
//                       ),
//                       child: LayoutBuilder(
//                         builder: (
//                             context,
//                             searchConstraints,
//                             ) {
//                           if (searchConstraints
//                               .maxWidth <
//                               650) {
//                             return Column(
//                               children: [
//                                 _searchField(),
//
//                                 const SizedBox(
//                                   height: 12,
//                                 ),
//
//                                 _statusDropdown(),
//                               ],
//                             );
//                           }
//
//                           return Row(
//                             children: [
//                               Expanded(
//                                 child:
//                                 _searchField(),
//                               ),
//
//                               const SizedBox(
//                                 width: 12,
//                               ),
//
//                               SizedBox(
//                                 width: 180,
//                                 child:
//                                 _statusDropdown(),
//                               ),
//                             ],
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(
//                     height: 14,
//                   ),
//
//                   // ------------------------------------------------
//                   // AUDITOR TABLE
//                   // ------------------------------------------------
//
//                   _filteredAuditors.isEmpty
//                       ? SizedBox(
//                     width: 900,
//                     child: _buildEmpty(),
//                   )
//                       : Center(
//                     child:
//                     _buildAuditorTable(),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   // ============================================================
//   // SEARCH FIELD
//   // ============================================================
//
//   Widget _searchField() {
//     return TextField(
//       controller:
//       _searchController,
//       decoration:
//       const InputDecoration(
//         hintText:
//         'Search auditor, employee ID or email...',
//         prefixIcon:
//         Icon(Icons.search_rounded),
//         border:
//         OutlineInputBorder(),
//         isDense: true,
//       ),
//     );
//   }
//
//   // ============================================================
//   // STATUS FILTER
//   // ============================================================
//
//   Widget _statusDropdown() {
//     return DropdownButtonFormField<String>(
//       value: _statusFilter,
//       decoration:
//       const InputDecoration(
//         labelText: 'Status',
//         border:
//         OutlineInputBorder(),
//         isDense: true,
//       ),
//       items: const [
//         DropdownMenuItem(
//           value: 'All',
//           child: Text('All'),
//         ),
//         DropdownMenuItem(
//           value: 'Active',
//           child: Text('Active'),
//         ),
//         DropdownMenuItem(
//           value: 'Inactive',
//           child: Text('Inactive'),
//         ),
//       ],
//       onChanged: (value) {
//         if (value == null) {
//           return;
//         }
//
//         setState(() {
//           _statusFilter = value;
//         });
//
//         _applyFilters();
//       },
//     );
//   }
//
//   // ============================================================
//   // TABLE
//   // ============================================================
//
//   Widget _buildAuditorTable() {
//     /*
//      * IMPORTANT:
//      *
//      * The table card is deliberately NOT wrapped in
//      * Expanded / double.infinity / stretch.
//      *
//      * Its width is determined by the DataTable itself.
//      * This removes the giant empty area on the right.
//      */
//
//     return Container(
//       decoration:
//       BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//         BorderRadius.circular(14),
//         border:
//         Border.all(
//           color:
//           const Color(0xFFE1E4E8),
//         ),
//       ),
//
//       child: ClipRRect(
//         borderRadius:
//         BorderRadius.circular(14),
//
//         child: DataTable(
//           headingRowColor:
//           WidgetStateProperty.all(
//             const Color(0xFFF8F9FC),
//           ),
//
//           columnSpacing: 35,
//
//           horizontalMargin: 18,
//
//           dataRowMinHeight: 62,
//
//           dataRowMaxHeight: 72,
//
//           columns: const [
//             DataColumn(
//               label: Text(
//                 'Auditor',
//                 style: TextStyle(
//                   fontWeight:
//                   FontWeight.w700,
//                 ),
//               ),
//             ),
//
//             DataColumn(
//               label: Text(
//                 'Employee ID',
//                 style: TextStyle(
//                   fontWeight:
//                   FontWeight.w700,
//                 ),
//               ),
//             ),
//
//             DataColumn(
//               label: Text(
//                 'Email',
//                 style: TextStyle(
//                   fontWeight:
//                   FontWeight.w700,
//                 ),
//               ),
//             ),
//
//             DataColumn(
//               label: Text(
//                 'Status',
//                 style: TextStyle(
//                   fontWeight:
//                   FontWeight.w700,
//                 ),
//               ),
//             ),
//
//             DataColumn(
//               label: Text(
//                 'Actions',
//                 style: TextStyle(
//                   fontWeight:
//                   FontWeight.w700,
//                 ),
//               ),
//             ),
//           ],
//
//           rows: _filteredAuditors
//               .map(
//                 (auditor) {
//               final name =
//                   auditor['auditor_name']
//                       ?.toString() ??
//                       '';
//
//               final employeeId =
//                   auditor['employee_id']
//                       ?.toString() ??
//                       '';
//
//               final email =
//                   auditor['email']
//                       ?.toString() ??
//                       '';
//
//               final active =
//                   auditor['active']
//                   as bool? ??
//                       false;
//
//               return DataRow(
//                 cells: [
//                   // ------------------------------------------
//                   // AUDITOR
//                   // ------------------------------------------
//
//                   DataCell(
//                     Row(
//                       mainAxisSize:
//                       MainAxisSize.min,
//                       children: [
//                         Container(
//                           width: 36,
//                           height: 36,
//                           decoration:
//                           BoxDecoration(
//                             color:
//                             const Color(
//                               0xFFF0E8FF,
//                             ),
//                             borderRadius:
//                             BorderRadius
//                                 .circular(
//                               9,
//                             ),
//                           ),
//                           child:
//                           const Icon(
//                             Icons
//                                 .person_outline,
//                             size: 19,
//                             color:
//                             Color(
//                               0xFF7655B7,
//                             ),
//                           ),
//                         ),
//
//                         const SizedBox(
//                           width: 10,
//                         ),
//
//                         Text(
//                           name,
//                           style:
//                           const TextStyle(
//                             fontWeight:
//                             FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   // ------------------------------------------
//                   // EMPLOYEE ID
//                   // ------------------------------------------
//
//                   DataCell(
//                     Text(employeeId),
//                   ),
//
//                   // ------------------------------------------
//                   // EMAIL
//                   // ------------------------------------------
//
//                   DataCell(
//                     Text(email),
//                   ),
//
//                   // ------------------------------------------
//                   // STATUS
//                   // ------------------------------------------
//
//                   DataCell(
//                     _statusChip(active),
//                   ),
//
//                   // ------------------------------------------
//                   // ACTIONS
//                   // ------------------------------------------
//
//                   DataCell(
//                     Row(
//                       mainAxisSize:
//                       MainAxisSize.min,
//                       children: [
//                         IconButton(
//                           tooltip: 'Edit',
//                           onPressed:
//                           _saving
//                               ? null
//                               : () {
//                             _showAuditorDialog(
//                               existing:
//                               auditor,
//                             );
//                           },
//                           icon:
//                           const Icon(
//                             Icons
//                                 .edit_outlined,
//                             size: 19,
//                           ),
//                         ),
//
//                         IconButton(
//                           tooltip: active
//                               ? 'Deactivate'
//                               : 'Activate',
//                           onPressed:
//                           _saving
//                               ? null
//                               : () {
//                             _toggleAuditor(
//                               auditor,
//                             );
//                           },
//                           icon: Icon(
//                             active
//                                 ? Icons
//                                 .block_outlined
//                                 : Icons
//                                 .check_circle_outline,
//                             size: 19,
//                           ),
//                         ),
//
//                         IconButton(
//                           tooltip: 'Delete',
//                           onPressed:
//                           _saving
//                               ? null
//                               : () {
//                             _deleteAuditor(
//                               auditor,
//                             );
//                           },
//                           icon:
//                           const Icon(
//                             Icons
//                                 .delete_outline,
//                             size: 19,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ).toList(),
//         ),
//       ),
//     );
//   }
//
//   // ============================================================
//   // STATUS CHIP
//   // ============================================================
//
//   Widget _statusChip(bool active) {
//     return Container(
//       padding:
//       const EdgeInsets.symmetric(
//         horizontal: 10,
//         vertical: 6,
//       ),
//       decoration:
//       BoxDecoration(
//         color: active
//             ? const Color(0xFFEAF7EF)
//             : const Color(0xFFF1F2F4),
//         borderRadius:
//         BorderRadius.circular(8),
//       ),
//       child: Text(
//         active
//             ? 'Active'
//             : 'Inactive',
//         style: TextStyle(
//           fontSize: 12,
//           fontWeight:
//           FontWeight.w700,
//           color: active
//               ? const Color(0xFF2E9B55)
//               : const Color(0xFF6B7280),
//         ),
//       ),
//     );
//   }
//
//   // ============================================================
//   // EMPTY
//   // ============================================================
//
//   Widget _buildEmpty() {
//     return Container(
//       width: double.infinity,
//       padding:
//       const EdgeInsets.symmetric(
//         vertical: 70,
//       ),
//       decoration:
//       BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//         BorderRadius.circular(14),
//         border:
//         Border.all(
//           color:
//           const Color(0xFFE1E4E8),
//         ),
//       ),
//       child: Column(
//         children: [
//           Container(
//             width: 58,
//             height: 58,
//             decoration:
//             BoxDecoration(
//               color:
//               const Color(0xFFF0F2F5),
//               borderRadius:
//               BorderRadius.circular(15),
//             ),
//             child: const Icon(
//               Icons.people_outline,
//               size: 29,
//               color:
//               Color(0xFF747B86),
//             ),
//           ),
//
//           const SizedBox(
//             height: 14,
//           ),
//
//           const Text(
//             'No auditors found',
//             style: TextStyle(
//               fontSize: 17,
//               fontWeight:
//               FontWeight.w700,
//             ),
//           ),
//
//           const SizedBox(
//             height: 6,
//           ),
//
//           Text(
//             _auditors.isEmpty
//                 ? 'Add an auditor to make them available for Audit assignments.'
//                 : 'No auditors match the current search or filter.',
//             textAlign:
//             TextAlign.center,
//             style: const TextStyle(
//               fontSize: 13,
//               color:
//               Color(0xFF6B7280),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }