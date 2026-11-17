import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../services/audit/audit_admin_session.dart';

class AuditMasterDataManagementScreen
    extends StatefulWidget {
  const AuditMasterDataManagementScreen({
    super.key,
  });

  @override
  State<AuditMasterDataManagementScreen> createState() =>
      _AuditMasterDataManagementScreenState();
}

class _AuditMasterDataManagementScreenState
    extends State<AuditMasterDataManagementScreen> {
  String? _sessionToken;
  String? _adminEmail;

  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _masters = [];
  List<Map<String, dynamic>> _filteredMasters = [];

  List<Map<String, dynamic>> _auditTypes = [];

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

    _loadData();
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

  Future<void> _loadData() async {
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
      final results = await Future.wait([
        SupabaseService.getAdminAuditMasterData(
          sessionToken: sessionToken,
        ).timeout(
          const Duration(seconds: 20),
        ),

        SupabaseService.getActiveAuditTypes().timeout(
          const Duration(seconds: 20),
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _masters =
        List<Map<String, dynamic>>.from(
          results[0] as List,
        );

        _auditTypes =
        List<Map<String, dynamic>>.from(
          results[1] as List,
        );

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
        'Unable to load Master Data: $e',
      );
    }
  }

  // ============================================================
  // FILTERS
  // ============================================================

  void _applyFilters() {
    final search =
    _searchController.text.trim().toLowerCase();

    final filtered =
    _masters.where((master) {
      final active =
          master['active'] as bool? ?? false;

      if (_statusFilter == 'Active' &&
          !active) {
        return false;
      }

      if (_statusFilter == 'Inactive' &&
          active) {
        return false;
      }

      if (search.isEmpty) {
        return true;
      }

      final masterName =
          master['master_name']
              ?.toString()
              .toLowerCase() ??
              '';

      final auditType =
          master['audit_type_name']
              ?.toString()
              .toLowerCase() ??
              '';

      return masterName.contains(search) ||
          auditType.contains(search);
    }).toList();

    if (!mounted) return;

    setState(() {
      _filteredMasters = filtered;
    });
  }

  // ============================================================
  // ADD / EDIT
  // ============================================================

  Future<void> _showMasterDialog({
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

    final masterNameController =
    TextEditingController(
      text:
      existing?['master_name']
          ?.toString() ??
          '',
    );

    final manualTypeController =
    TextEditingController();

    final existingTypeId =
    existing?['audit_type_id']
        ?.toString();

    bool useExistingType =
        existing != null &&
            existingTypeId != null &&
            existingTypeId.isNotEmpty;

    String? selectedTypeId =
        existingTypeId;

    if (!useExistingType) {
      manualTypeController.text =
          existing?['audit_type_name']
              ?.toString() ??
              '';
    }

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
                      ? 'Edit Master Data'
                      : 'Add Master Data',
                ),

                content: SizedBox(
                  width: 500,

                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize:
                      MainAxisSize.min,

                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [
                        // --------------------------------------
                        // MASTER NAME
                        // --------------------------------------

                        TextField(
                          controller:
                          masterNameController,

                          textCapitalization:
                          TextCapitalization.words,

                          decoration:
                          const InputDecoration(
                            labelText:
                            'Master Name *',
                            border:
                            OutlineInputBorder(),
                            prefixIcon:
                            Icon(
                              Icons
                                  .list_alt_outlined,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        const Text(
                          'Audit Type',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        // --------------------------------------
                        // TYPE MODE
                        // --------------------------------------

                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment<bool>(
                              value: true,
                              label:
                              Text(
                                'Existing',
                              ),
                              icon:
                              Icon(
                                Icons
                                    .storage_outlined,
                              ),
                            ),
                            ButtonSegment<bool>(
                              value: false,
                              label:
                              Text(
                                'Manual',
                              ),
                              icon:
                              Icon(
                                Icons
                                    .edit_outlined,
                              ),
                            ),
                          ],

                          selected: {
                            useExistingType,
                          },

                          onSelectionChanged:
                          dialogSaving
                              ? null
                              : (
                              selection,
                              ) {
                            setDialogState(
                                  () {
                                useExistingType =
                                    selection
                                        .first;

                                if (useExistingType) {
                                  manualTypeController
                                      .clear();
                                } else {
                                  selectedTypeId =
                                  null;
                                }
                              },
                            );
                          },
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // --------------------------------------
                        // EXISTING TYPE
                        // --------------------------------------

                        if (useExistingType)
                          DropdownButtonFormField<
                              String>(
                            value:
                            selectedTypeId,

                            decoration:
                            const InputDecoration(
                              labelText:
                              'Existing Audit Type *',
                              border:
                              OutlineInputBorder(),
                            ),

                            items:
                            _auditTypes
                                .map(
                                  (
                                  type,
                                  ) {
                                final id =
                                type[
                                'type_id']
                                    ?.toString();

                                final name =
                                    type[
                                    'audit_type']
                                        ?.toString() ??
                                        '';

                                if (id ==
                                    null) {
                                  return null;
                                }

                                return DropdownMenuItem<
                                    String>(
                                  value: id,
                                  child:
                                  Text(
                                    name,
                                  ),
                                );
                              },
                            )
                                .whereType<
                                DropdownMenuItem<
                                    String>>()
                                .toList(),

                            onChanged:
                            dialogSaving
                                ? null
                                : (
                                value,
                                ) {
                              setDialogState(
                                    () {
                                  selectedTypeId =
                                      value;
                                },
                              );
                            },
                          ),

                        // --------------------------------------
                        // MANUAL TYPE
                        // --------------------------------------

                        if (!useExistingType)
                          TextField(
                            controller:
                            manualTypeController,

                            decoration:
                            const InputDecoration(
                              labelText:
                              'Manual Audit Type *',
                              hintText:
                              'Enter Audit Type',
                              border:
                              OutlineInputBorder(),
                            ),
                          ),

                        const SizedBox(
                          height: 14,
                        ),

                        // --------------------------------------
                        // ACTIVE
                        // --------------------------------------

                        SwitchListTile(
                          contentPadding:
                          EdgeInsets.zero,

                          title:
                          const Text(
                            'Active',
                          ),

                          subtitle:
                          Text(
                            active
                                ? 'Master data is available.'
                                : 'Master data is inactive.',
                          ),

                          value: active,

                          onChanged:
                          dialogSaving
                              ? null
                              : (
                              value,
                              ) {
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
                ),

                actions: [
                  TextButton(
                    onPressed:
                    dialogSaving
                        ? null
                        : () {
                      Navigator.pop(
                        dialogContext,
                      );
                    },
                    child:
                    const Text(
                      'Cancel',
                    ),
                  ),

                  ElevatedButton(
                    onPressed:
                    dialogSaving
                        ? null
                        : () async {
                      final masterName =
                      masterNameController
                          .text
                          .trim();

                      if (masterName
                          .isEmpty) {
                        _dialogError(
                          dialogContext,
                          'Master Name is required.',
                        );
                        return;
                      }

                      String?
                      auditTypeId;

                      String
                      auditTypeName;

                      if (useExistingType) {
                        if (selectedTypeId ==
                            null ||
                            selectedTypeId!
                                .isEmpty) {
                          _dialogError(
                            dialogContext,
                            'Please select an Audit Type.',
                          );
                          return;
                        }

                        auditTypeId =
                            selectedTypeId;

                        final selectedType =
                        _auditTypes
                            .where(
                              (type) =>
                          type[
                          'type_id']
                              ?.toString() ==
                              selectedTypeId,
                        )
                            .toList();

                        if (selectedType
                            .isEmpty) {
                          _dialogError(
                            dialogContext,
                            'Selected Audit Type was not found.',
                          );
                          return;
                        }

                        auditTypeName =
                            selectedType
                                .first[
                            'audit_type']
                                .toString();
                      } else {
                        auditTypeName =
                            manualTypeController
                                .text
                                .trim();

                        if (auditTypeName
                            .isEmpty) {
                          _dialogError(
                            dialogContext,
                            'Manual Audit Type is required.',
                          );
                          return;
                        }
                      }

                      setDialogState(() {
                        dialogSaving =
                        true;
                      });

                      if (mounted) {
                        setState(() {
                          _saving =
                          true;
                        });
                      }

                      try {
                        Map<String,
                            dynamic>
                        saved;

                        if (isEditing) {
                          saved =
                          await SupabaseService
                              .updateAdminAuditMasterData(
                            sessionToken:
                            sessionToken,
                            masterId:
                            existing[
                            'master_id']
                                .toString(),
                            masterName:
                            masterName,
                            auditTypeId:
                            auditTypeId,
                            auditTypeName:
                            auditTypeName,
                            active:
                            active,
                          ).timeout(
                            const Duration(
                              seconds: 20,
                            ),
                          );
                        } else {
                          saved =
                          await SupabaseService
                              .createAdminAuditMasterData(
                            sessionToken:
                            sessionToken,
                            masterName:
                            masterName,
                            auditTypeId:
                            auditTypeId,
                            auditTypeName:
                            auditTypeName,
                            active:
                            active,
                          ).timeout(
                            const Duration(
                              seconds: 20,
                            ),
                          );
                        }

                        if (!mounted) {
                          return;
                        }

                        setState(() {
                          _saving =
                          false;

                          if (isEditing) {
                            final index =
                            _masters.indexWhere(
                                  (item) =>
                              item[
                              'master_id']
                                  ?.toString() ==
                                  existing[
                                  'master_id']
                                      ?.toString(),
                            );

                            if (index >=
                                0) {
                              _masters[
                              index] = {
                                ..._masters[
                                index],
                                ...saved,
                                'master_id':
                                saved[
                                'master_id'] ??
                                    existing[
                                    'master_id'],
                                'master_name':
                                saved[
                                'master_name'] ??
                                    masterName,
                                'audit_type_id':
                                saved[
                                'audit_type_id'] ??
                                    auditTypeId,
                                'audit_type_name':
                                saved[
                                'audit_type_name'] ??
                                    auditTypeName,
                                'active':
                                saved[
                                'active'] ??
                                    active,
                              };
                            }
                          } else {
                            _masters.add({
                              ...saved,
                              'master_name':
                              saved[
                              'master_name'] ??
                                  masterName,
                              'audit_type_id':
                              saved[
                              'audit_type_id'] ??
                                  auditTypeId,
                              'audit_type_name':
                              saved[
                              'audit_type_name'] ??
                                  auditTypeName,
                              'active':
                              saved[
                              'active'] ??
                                  active,
                            });
                          }
                        });

                        _applyFilters();

                        if (!dialogContext
                            .mounted) {
                          return;
                        }

                        Navigator.pop(
                          dialogContext,
                        );

                        _showMessage(
                          isEditing
                              ? 'Master Data updated successfully.'
                              : 'Master Data created successfully.',
                        );
                      } catch (e) {
                        if (await AuditAdminSession.handleSessionExpired(context, e)) {
                          return;
                        }
                        if (mounted) {
                          setState(() {
                            _saving =
                            false;
                          });
                        }

                        if (!dialogContext
                            .mounted) {
                          return;
                        }

                        setDialogState(() {
                          dialogSaving =
                          false;
                        });

                        _dialogError(
                          dialogContext,
                          'Unable to save Master Data: $e',
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
      masterNameController.dispose();
      manualTypeController.dispose();

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

  Future<void> _deleteMaster(
      Map<String, dynamic> master,
      ) async {
    final sessionToken = _sessionToken;

    if (sessionToken == null ||
        sessionToken.isEmpty) {
      _showError(
        'Admin session is missing.',
      );
      return;
    }

    final masterId =
    master['master_id']?.toString();

    if (masterId == null ||
        masterId.isEmpty) {
      _showError(
        'Invalid Master Data ID.',
      );
      return;
    }

    final name =
        master['master_name']
            ?.toString() ??
            'this record';

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
          const Text(
            'Delete Master Data',
          ),
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
      await SupabaseService
          .deleteAdminAuditMasterData(
        sessionToken: sessionToken,
        masterId: masterId,
      ).timeout(
        const Duration(seconds: 20),
      );

      if (!mounted) return;

      setState(() {
        _masters.removeWhere(
              (item) =>
          item['master_id']?.toString() ==
              masterId,
        );

        _saving = false;
      });

      _applyFilters();

      _showMessage(
        'Master Data deleted successfully.',
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
        'Unable to delete Master Data: $e',
      );
    }
  }

  // ============================================================
  // ACTIVE / INACTIVE
  // ============================================================

  Future<void> _toggleMaster(
      Map<String, dynamic> master,
      ) async {
    final sessionToken = _sessionToken;

    if (sessionToken == null ||
        sessionToken.isEmpty) {
      _showError(
        'Admin session is missing.',
      );
      return;
    }

    final masterId =
    master['master_id']?.toString();

    if (masterId == null ||
        masterId.isEmpty) {
      _showError(
        'Invalid Master Data ID.',
      );
      return;
    }

    final currentActive =
        master['active'] as bool? ?? false;

    if (!mounted) return;

    setState(() {
      _saving = true;
    });

    try {
      final updated =
      await SupabaseService
          .updateAdminAuditMasterData(
        sessionToken: sessionToken,
        masterId: masterId,
        masterName:
        master['master_name']
            ?.toString() ??
            '',
        auditTypeId:
        master['audit_type_id']
            ?.toString(),
        auditTypeName:
        master['audit_type_name']
            ?.toString() ??
            '',
        active: !currentActive,
      ).timeout(
        const Duration(seconds: 20),
      );

      if (!mounted) return;

      final index =
      _masters.indexWhere(
            (item) =>
        item['master_id']?.toString() ==
            masterId,
      );

      if (index >= 0) {
        setState(() {
          _masters[index] = {
            ..._masters[index],
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
            ? 'Master Data activated.'
            : 'Master Data deactivated.',
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
        'Unable to update Master Data: $e',
      );
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _searchField() {
    return TextField(
      controller:
      _searchController,
      decoration:
      const InputDecoration(
        hintText:
        'Search master name or audit type...',
        prefixIcon:
        Icon(Icons.search_rounded),
        border:
        OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  // ============================================================
  // STATUS
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

  Widget _buildMasterTable() {
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

        child: DataTable(
          headingRowColor:
          WidgetStateProperty.all(
            const Color(0xFFF8F9FC),
          ),

          columnSpacing: 38,

          horizontalMargin: 18,

          dataRowMinHeight: 62,

          dataRowMaxHeight: 72,

          columns: const [
            DataColumn(
              label: Text(
                'Master Name',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ),

            DataColumn(
              label: Text(
                'Audit Type',
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

          rows:
          _filteredMasters.map(
                (master) {
              final masterName =
                  master['master_name']
                      ?.toString() ??
                      '';

              final auditType =
                  master['audit_type_name']
                      ?.toString() ??
                      '';

              final active =
                  master['active']
                  as bool? ??
                      false;

              return DataRow(
                cells: [
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
                                .list_alt_outlined,
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
                          masterName,
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  DataCell(
                    Text(auditType),
                  ),

                  DataCell(
                    _statusChip(active),
                  ),

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
                            _showMasterDialog(
                              existing:
                              master,
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
                            _toggleMaster(
                              master,
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
                            _deleteMaster(
                              master,
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
      width: 900,

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
            child:
            const Icon(
              Icons
                  .list_alt_outlined,
              size: 29,
              color:
              Color(0xFF747B86),
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          const Text(
            'No Master Data found',
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
            _masters.isEmpty
                ? 'Add Master Data to create your independent master list.'
                : 'No records match the current search or filter.',
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

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (
          context,
          constraints,
          ) {
        final screenWidth =
            constraints.maxWidth;

        final contentWidth =
        screenWidth < 1100
            ? screenWidth - 40
            : 1050.0;

        return SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),

          padding:
          const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),

          child: Center(
            child: SizedBox(
              width: contentWidth,

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.center,

                children: [
                  // ------------------------------------------------
                  // HEADER
                  // ------------------------------------------------

                  SizedBox(
                    width: 900,

                    child: Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              const Text(
                                'Audit Master Data',
                                style:
                                TextStyle(
                                  fontSize: 24,
                                  fontWeight:
                                  FontWeight.w800,
                                  color:
                                  Color(
                                    0xFF172033,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 5,
                              ),

                              Text(
                                'Manage independent master data for Audit operations.',
                                style:
                                TextStyle(
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
                            color:
                            Colors.white,
                            borderRadius:
                            BorderRadius
                                .circular(
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

                          child:
                          Text(
                            '${_filteredMasters.length} records',
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
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ------------------------------------------------
                  // SEARCH / FILTER
                  // ------------------------------------------------

                  SizedBox(
                    width: 900,

                    child: Container(
                      padding:
                      const EdgeInsets.all(
                        14,
                      ),

                      decoration:
                      BoxDecoration(
                        color:
                        Colors.white,
                        borderRadius:
                        BorderRadius
                            .circular(
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
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // ------------------------------------------------
                  // TABLE
                  // ------------------------------------------------

                  _filteredMasters.isEmpty
                      ? _buildEmpty()
                      : Center(
                    child:
                    _buildMasterTable(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // MESSAGES
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
          onPressed: _saving
              ? null
              : () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
          ),
        ),

        title: const Text(
          'Audit Master Data',
          style: TextStyle(
            fontWeight: FontWeight.w700,
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
            tooltip: 'Refresh',
            onPressed: _loading || _saving
                ? null
                : _loadData,
            icon: const Icon(
              Icons.refresh,
            ),
          ),

          IconButton(
            tooltip: 'Logout',
            onPressed: _saving
                ? null
                : _logout,
            icon: const Icon(
              Icons.logout,
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: _loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _loadData,
        child: _buildBody(),
      ),

      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: _saving
            ? null
            : () {
          _showMasterDialog();
        },
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Add Master Data',
        ),
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
}