import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../services/audit/audit_admin_session.dart';

class AuditRecordsManagementScreen
    extends StatefulWidget {
  final String sessionToken;

  const AuditRecordsManagementScreen({
    super.key,
    required this.sessionToken,
  });

  @override
  State<AuditRecordsManagementScreen> createState() =>
      _AuditRecordsManagementScreenState();
}

class _AuditRecordsManagementScreenState
    extends State<AuditRecordsManagementScreen> {
  List<Map<String, dynamic>> _audits = [];

  bool _loading = true;
  bool _deleting = false;

  String _searchText = '';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  // ============================================================
  // LOAD RECORDS
  // ============================================================

  Future<void> _loadRecords() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      final records =
      await SupabaseService.getAllAudits()
          .timeout(
        const Duration(seconds: 20),
      );

      if (!mounted) return;

      setState(() {
        _audits = records;
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
        'Unable to load Audit Records: $e',
      );
    }
  }

  // ============================================================
  // FILTERING
  // ============================================================

  List<Map<String, dynamic>> get _filteredAudits {
    final search =
    _searchText.trim().toLowerCase();

    return _audits.where((audit) {
      final status =
          audit['status']?.toString() ?? '';

      if (_statusFilter != 'All' &&
          status != _statusFilter) {
        return false;
      }

      if (search.isEmpty) {
        return true;
      }

      final values = [
        audit['mil_number'],
        audit['audit_type'],
        audit['audit_date'],
        audit['vendor'],
        audit['site'],
        audit['lob'],
        audit['program'],
        audit['line'],
        audit['apn'],
        audit['auditor_name'],
        audit['auditor_email'],
        audit['status'],
        audit['mil_status'],
      ];

      final searchable = values
          .map(
            (value) =>
        value?.toString() ?? '',
      )
          .join(' ')
          .toLowerCase();

      return searchable.contains(search);
    }).toList();
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteAudit(
      Map<String, dynamic> audit,
      ) async {
    if (_deleting) {
      return;
    }

    final auditId =
    audit['audit_id']?.toString().trim();

    if (auditId == null || auditId.isEmpty) {
      _showError(
        'Invalid Audit ID.',
      );
      return;
    }

    final auditType =
    audit['audit_type']?.toString().trim();

    final milNumber =
    audit['mil_number']?.toString().trim();

    final vendor =
    audit['vendor']?.toString().trim();

    final displayName =
    milNumber != null &&
        milNumber.isNotEmpty
        ? milNumber
        : (auditType != null &&
        auditType.isNotEmpty
        ? auditType
        : 'this audit');

    // ----------------------------------------------------------
    // FIRST CONFIRMATION
    // ----------------------------------------------------------

    final firstConfirmation =
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
              ),
              SizedBox(width: 10),
              Text('Delete Audit Record'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'You are about to permanently delete:',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge,
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius:
                    BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors
                          .orange
                          .shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight:
                          FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (vendor != null &&
                          vendor.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Vendor: $vendor',
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        'Status: ${audit['status'] ?? '-'}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'MIL Status: ${audit['mil_status'] ?? '-'}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'The audit record, checklist answers, '
                      'category progress and MIL items will '
                      'be permanently deleted.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Continue',
              ),
            ),
          ],
        );
      },
    );

    if (firstConfirmation != true) {
      return;
    }

    if (!mounted) return;

    // ----------------------------------------------------------
    // SECOND CONFIRMATION
    // ----------------------------------------------------------

    final secondConfirmation =
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Confirm Permanent Deletion',
          ),
          content: Text(
            'Delete "$displayName" permanently?\n\n'
                'There is no restore option after deletion.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Delete Permanently',
              ),
            ),
          ],
        );
      },
    );

    if (secondConfirmation != true) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _deleting = true;
    });

    try {
      await SupabaseService
          .deleteAdminAudit(
        sessionToken:
        widget.sessionToken,
        auditId: auditId,
      ).timeout(
        const Duration(seconds: 20),
      );

      if (!mounted) return;

      setState(() {
        _audits.removeWhere(
              (item) =>
          item['audit_id']
              ?.toString() ==
              auditId,
        );

        _deleting = false;
      });

      _showMessage(
        'Audit record permanently deleted.',
      );
    } catch (e) {
      if (await AuditAdminSession.handleSessionExpired(context, e)) {
        return;
      }
      if (!mounted) return;

      setState(() {
        _deleting = false;
      });

      _showError(
        'Unable to delete Audit Record: $e',
      );
    }
  }

  // ============================================================
  // OPEN AUDIT REPORT
  // ============================================================

  Future<void> _openAuditReport(
      Map<String, dynamic> audit,
      ) async {
    final auditId =
    audit['audit_id']?.toString().trim();

    if (auditId == null || auditId.isEmpty) {
      _showError(
        'Invalid Audit ID.',
      );
      return;
    }

    await Navigator.pushNamed(
      context,
      '/AUDIT/report',
      arguments: auditId,
    );
  }

  // ============================================================
  // OPEN MIL
  // ============================================================

  Future<void> _openMilReport(
      Map<String, dynamic> audit,
      ) async {
    final auditId =
    audit['audit_id']?.toString().trim();

    if (auditId == null || auditId.isEmpty) {
      _showError(
        'Invalid Audit ID.',
      );
      return;
    }

    await Navigator.pushNamed(
      context,
      '/AUDIT/mil',
      arguments: auditId,
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _statusChip(
      String? status,
      ) {
    final value =
    status?.trim().isNotEmpty == true
        ? status!.trim()
        : '-';

    Color background;
    Color foreground;

    switch (value) {
      case 'Completed':
        background =
            Colors.green.shade100;
        foreground =
            Colors.green.shade800;
        break;

      case 'Submitted':
        background =
            Colors.blue.shade100;
        foreground =
            Colors.blue.shade800;
        break;

      case 'In Progress':
        background =
            Colors.orange.shade100;
        foreground =
            Colors.orange.shade800;
        break;

      case 'Draft':
        background =
            Colors.grey.shade200;
        foreground =
            Colors.grey.shade800;
        break;

      default:
        background =
            Colors.grey.shade100;
        foreground =
            Colors.grey.shade700;
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: foreground,
          fontWeight:
          FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  // ============================================================
  // MIL CHIP
  // ============================================================

  Widget _milStatusChip(
      String? status,
      ) {
    final value =
    status?.trim().isNotEmpty == true
        ? status!.trim()
        : '-';

    final isClosed =
        value.toLowerCase() ==
            'closed';

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isClosed
            ? Colors.green.shade100
            : Colors.orange.shade100,
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: isClosed
              ? Colors.green.shade800
              : Colors.orange.shade800,
          fontWeight:
          FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final records =
        _filteredAudits;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Audit Records Management',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
            _loading || _deleting
                ? null
                : _loadRecords,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
          child:
          CircularProgressIndicator(),
        )
            : _buildContent(records),
      ),
    );
  }

  Widget _buildContent(
      List<Map<String, dynamic>> records,
      ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
        children: [
          // ------------------------------------------------------
          // HEADER
          // ------------------------------------------------------

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audit Records',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Permanent administration of all Audit records.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                        color: Colors
                            .grey
                            .shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  borderRadius:
                  BorderRadius.circular(20),
                  color:
                  Colors.red.shade50,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons
                          .admin_panel_settings_outlined,
                      size: 18,
                      color:
                      Colors.red.shade700,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${_audits.length} Records',
                      style: TextStyle(
                        color:
                        Colors.red.shade700,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ------------------------------------------------------
          // FILTER BAR
          // ------------------------------------------------------

          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchText = value;
                    });
                  },
                  decoration:
                  const InputDecoration(
                    hintText:
                    'Search audit records...',
                    prefixIcon:
                    Icon(Icons.search),
                    border:
                    OutlineInputBorder(),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              SizedBox(
                width: 210,
                child:
                DropdownButtonFormField<
                    String>(
                  value: _statusFilter,
                  decoration:
                  const InputDecoration(
                    labelText: 'Status',
                    border:
                    OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'All',
                      child: Text('All'),
                    ),
                    DropdownMenuItem(
                      value: 'Draft',
                      child: Text('Draft'),
                    ),
                    DropdownMenuItem(
                      value: 'In Progress',
                      child:
                      Text('In Progress'),
                    ),
                    DropdownMenuItem(
                      value: 'Submitted',
                      child:
                      Text('Submitted'),
                    ),
                    DropdownMenuItem(
                      value: 'Completed',
                      child:
                      Text('Completed'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _statusFilter =
                          value ?? 'All';
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ------------------------------------------------------
          // RECORD COUNT
          // ------------------------------------------------------

          Text(
            'Showing ${records.length} of ${_audits.length} records',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight:
              FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          // ------------------------------------------------------
          // TABLE
          // ------------------------------------------------------

          Expanded(
            child: records.isEmpty
                ? _buildEmptyState()
                : _buildRecordsTable(
              records,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsTable(
      List<Map<String, dynamic>> records,
      ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection:
            Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              headingRowHeight: 52,
              dataRowMinHeight: 62,
              dataRowMaxHeight: 72,
              columns: const [
                DataColumn(
                  label: Text('SNo'),
                ),
                DataColumn(
                  label: Text('MIL Number'),
                ),
                DataColumn(
                  label: Text('Audit Type'),
                ),
                DataColumn(
                  label: Text('Audit Date'),
                ),
                DataColumn(
                  label: Text('Vendor'),
                ),
                DataColumn(
                  label: Text('Site'),
                ),
                DataColumn(
                  label: Text('LOB'),
                ),
                DataColumn(
                  label: Text('Program'),
                ),
                DataColumn(
                  label: Text('Line'),
                ),
                DataColumn(
                  label: Text('APN'),
                ),
                DataColumn(
                  label: Text('Status'),
                ),
                DataColumn(
                  label: Text('MIL Status'),
                ),
                DataColumn(
                  label:
                  Text('Audit Hours'),
                ),
                DataColumn(
                  label: Text('Actions'),
                ),
              ],
              rows: List.generate(
                records.length,
                    (index) {
                  final audit =
                  records[index];

                  final auditId =
                  audit['audit_id']
                      ?.toString()
                      .trim();

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          '${index + 1}',
                        ),
                      ),

                      DataCell(
                        Text(
                          _display(
                            audit[
                            'mil_number'],
                          ),
                        ),
                      ),

                      DataCell(
                        Text(
                          _display(
                            audit[
                            'audit_type'],
                          ),
                        ),
                      ),

                      DataCell(
                        Text(
                          _display(
                            audit[
                            'audit_date'],
                          ),
                        ),
                      ),

                      DataCell(
                        Text(
                          _display(
                            audit['vendor'],
                          ),
                        ),
                      ),

                      DataCell(
                        Text(
                          _display(
                            audit['site'],
                          ),
                        ),
                      ),

                      DataCell(
                        Text(
                          _display(
                            audit['lob'],
                          ),
                        ),
                      ),

                      DataCell(
                        Text(
                          _display(
                            audit['program'],
                          ),
                        ),
                      ),

                      DataCell(
                        Text(
                          _display(
                            audit['line'],
                          ),
                        ),
                      ),

                      DataCell(
                        Text(
                          _display(
                            audit['apn'],
                          ),
                        ),
                      ),

                      DataCell(
                        _statusChip(
                          audit['status']
                              ?.toString(),
                        ),
                      ),

                      DataCell(
                        _milStatusChip(
                          audit['mil_status']
                              ?.toString(),
                        ),
                      ),

                      DataCell(
                        Text(
                          _display(
                            audit[
                            'total_audit_hours'],
                          ),
                        ),
                      ),

                      DataCell(
                        Row(
                          mainAxisSize:
                          MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip:
                              'Audit Report',
                              onPressed:
                              _deleting ||
                                  auditId ==
                                      null ||
                                  auditId
                                      .isEmpty
                                  ? null
                                  : () =>
                                  _openAuditReport(
                                    audit,
                                  ),
                              icon:
                              const Icon(
                                Icons
                                    .description_outlined,
                              ),
                            ),

                            IconButton(
                              tooltip:
                              'MIL Report',
                              onPressed:
                              _deleting ||
                                  auditId ==
                                      null ||
                                  auditId
                                      .isEmpty
                                  ? null
                                  : () =>
                                  _openMilReport(
                                    audit,
                                  ),
                              icon:
                              const Icon(
                                Icons
                                    .assignment_late_outlined,
                              ),
                            ),

                            IconButton(
                              tooltip:
                              'Delete Permanently',
                              onPressed:
                              _deleting
                                  ? null
                                  : () =>
                                  _deleteAudit(
                                    audit,
                                  ),
                              icon: Icon(
                                Icons
                                    .delete_forever_outlined,
                                color: Colors
                                    .red
                                    .shade700,
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Icon(
            Icons
                .folder_open_outlined,
            size: 64,
            color: Colors
                .grey
                .shade400,
          ),
          const SizedBox(height: 14),
          Text(
            'No Audit Records Found',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
              fontWeight:
              FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No records match the current search or filter.',
            style: TextStyle(
              color:
              Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _display(
      dynamic value,
      ) {
    final text =
        value?.toString().trim() ?? '';

    return text.isEmpty ? '-' : text;
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

  void _showError(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        Colors.red.shade700,
      ),
    );
  }
}