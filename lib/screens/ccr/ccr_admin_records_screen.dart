import 'package:flutter/material.dart';

import '../../models/ccr/ccr_case.dart';
import '../../services/ccr/ccr_admin_service.dart';
import '../../services/ccr/ccr_service.dart';

class CcrAdminRecordsScreen extends StatefulWidget {
  const CcrAdminRecordsScreen({
    super.key,
  });

  @override
  State<CcrAdminRecordsScreen> createState() =>
      _CcrAdminRecordsScreenState();
}

class _CcrAdminRecordsScreenState
    extends State<CcrAdminRecordsScreen> {
  final CcrService _ccrService = CcrService();

  bool _loading = true;
  String? _error;

  List<CcrCase> _records = <CcrCase>[];

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
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final records =
      await _ccrService.getCcrCases();

      if (!mounted) {
        return;
      }

      setState(() {
        _records = records;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<CcrCase> get _filteredRecords {
    final search =
    _searchText.trim().toLowerCase();

    return _records.where((ccr) {
      final status =
      (ccr.statusName ??
          ccr.statusKey ??
          '')
          .trim();

      final matchesStatus =
          _statusFilter == 'All' ||
              status.toLowerCase() ==
                  _statusFilter.toLowerCase();

      if (!matchesStatus) {
        return false;
      }

      if (search.isEmpty) {
        return true;
      }

      final values = <String>[
        ccr.displayNumber,
        ccr.customerName ?? '',
        ccr.customerLocation ?? '',
        ccr.customerPartNumber ?? '',
        ccr.problemDescription ?? '',
        ccr.statusName ?? '',
        ccr.statusKey ?? '',
        ccr.currentStageName ?? '',
        ccr.currentStageKey ?? '',
        ccr.teamLeader ?? '',
        ccr.groupName ?? '',
      ];

      return values.any(
            (value) =>
            value.toLowerCase().contains(search),
      );
    }).toList();
  }

  List<String> get _statuses {
    final values = <String>{
      'All',
    };

    for (final ccr in _records) {
      final status =
      (ccr.statusName ??
          ccr.statusKey ??
          '')
          .trim();

      if (status.isNotEmpty) {
        values.add(status);
      }
    }

    return values.toList();
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteCcr(
      CcrCase ccr,
      ) async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete CCR Record',
          ),
          content: Text(
            'Are you sure you want to permanently delete '
                '${ccr.displayNumber}?\n\n'
                'This will delete the CCR and its related workflow records.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              style:
              FilledButton.styleFrom(
                backgroundColor:
                Colors.red,
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

    if (confirmed != true) {
      return;
    }

    try {
      await CcrAdminService.deleteCcr(
        ccrId: ccr.id,
      );
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '${ccr.displayNumber} deleted successfully.',
          ),
        ),
      );

      await _loadRecords();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    }
  }

  // ============================================================
  // VIEW CCR
  // ============================================================

  Future<void> _openCcr(
      CcrCase ccr,
      ) async {
    await Navigator.pushNamed(
      context,
      '/CCR/registration',
      arguments: ccr.id,
    );

    if (!mounted) {
      return;
    }

    await _loadRecords();
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(
      DateTime? date,
      ) {
    if (date == null) {
      return '-';
    }

    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  // ============================================================
  // STATUS DISPLAY
  // ============================================================

  String _status(
      CcrCase ccr,
      ) {
    final value =
    (ccr.statusName ??
        ccr.statusKey ??
        '')
        .trim();

    if (value.isEmpty) {
      return '-';
    }

    return value;
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(
      String status,
      ) {
    final value =
    status.toLowerCase();

    if (value.contains('closed')) {
      return Colors.green;
    }

    if (value.contains('draft')) {
      return Colors.orange;
    }

    if (value.contains('reopen')) {
      return Colors.red;
    }

    if (value.contains('progress')) {
      return Colors.blue;
    }

    return Colors.grey;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final records =
        _filteredRecords;

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'CCR Records Management',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
            _loading
                ? null
                : _loadRecords,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
          const SizedBox(
            width: 8,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _buildToolbar(),
              const SizedBox(
                height: 16,
              ),
              Expanded(
                child: _buildContent(
                  records,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOOLBAR
  // ============================================================

  Widget _buildToolbar() {
    return Card(
      elevation: 0,
      child: Padding(
        padding:
        const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (
              context,
              constraints,
              ) {
            final compact =
                constraints.maxWidth <
                    800;

            final search =
            SizedBox(
              width:
              compact
                  ? double.infinity
                  : 420,
              child: TextField(
                decoration:
                InputDecoration(
                  hintText:
                  'Search CCR...',
                  prefixIcon:
                  const Icon(
                    Icons.search,
                  ),
                  suffixIcon:
                  _searchText
                      .isNotEmpty
                      ? IconButton(
                    onPressed: () {
                      setState(() {
                        _searchText =
                        '';
                      });
                    },
                    icon:
                    const Icon(
                      Icons.clear,
                    ),
                  )
                      : null,
                  border:
                  const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchText =
                        value;
                  });
                },
              ),
            );

            final filter =
            SizedBox(
              width:
              compact
                  ? double.infinity
                  : 220,
              child:
              DropdownButtonFormField<
                  String>(
                initialValue:
                _statusFilter,
                decoration:
                const InputDecoration(
                  labelText:
                  'Status',
                  border:
                  OutlineInputBorder(),
                ),
                items:
                _statuses
                    .map(
                      (
                      status,
                      ) =>
                      DropdownMenuItem<
                          String>(
                        value:
                        status,
                        child:
                        Text(
                          status,
                        ),
                      ),
                )
                    .toList(),
                onChanged:
                    (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _statusFilter =
                        value;
                  });
                },
              ),
            );

            if (compact) {
              return Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .stretch,
                children: [
                  search,
                  const SizedBox(
                    height: 12,
                  ),
                  filter,
                ],
              );
            }

            return Row(
              children: [
                search,
                const SizedBox(
                  width: 16,
                ),
                filter,
                const Spacer(),
                Text(
                  '${_filteredRecords.length} record(s)',
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.w600,
                    color:
                    Color(0xFF6B7280),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent(
      List<CcrCase> records,
      ) {
    if (_loading) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              _error!,
              textAlign:
              TextAlign.center,
            ),
            const SizedBox(
              height: 16,
            ),
            FilledButton.icon(
              onPressed:
              _loadRecords,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Retry',
              ),
            ),
          ],
        ),
      );
    }

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const Icon(
              Icons.folder_open_outlined,
              size: 56,
              color:
              Color(0xFF9CA3AF),
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              'No CCR records found.',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.w700,
              ),
            ),
            if (_searchText
                .trim()
                .isNotEmpty ||
                _statusFilter != 'All')
              const Padding(
                padding:
                EdgeInsets.only(
                  top: 6,
                ),
                child: Text(
                  'Try changing the search or status filter.',
                ),
              ),
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      clipBehavior:
      Clip.antiAlias,
      child: Scrollbar(
        child:
        SingleChildScrollView(
          scrollDirection:
          Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor:
              WidgetStateProperty
                  .all(
                const Color(
                  0xFFF3F4F6,
                ),
              ),
              columnSpacing: 24,
              horizontalMargin: 18,
              dataRowMinHeight: 64,
              dataRowMaxHeight: 82,
              columns: const [
                DataColumn(
                  label: Text(
                    'SNo',
                  ),
                ),
                DataColumn(
                  label: Text(
                    'CCR No',
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Customer',
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Location',
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Product / Part No',
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Complaint Description',
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Status',
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Current Stage',
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Created',
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Open',
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Delete',
                  ),
                ),
              ],
              rows: List<DataRow>.generate(
                records.length,
                    (index) {
                  final ccr =
                  records[index];

                  final status =
                  _status(ccr);

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          '${index + 1}',
                        ),
                      ),
                      DataCell(
                        Text(
                          ccr.displayNumber,
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Text(
                            ccr.customerName ??
                                '-',
                            overflow:
                            TextOverflow
                                .ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Text(
                            ccr.customerLocation ??
                                '-',
                            overflow:
                            TextOverflow
                                .ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 160,
                          child: Text(
                            [
                              if ((ccr
                                  .groupName ??
                                  '')
                                  .trim()
                                  .isNotEmpty)
                                ccr.groupName!,
                              if ((ccr
                                  .customerPartNumber ??
                                  '')
                                  .trim()
                                  .isNotEmpty)
                                ccr.customerPartNumber!,
                            ].join(
                              ' / ',
                            ),
                            overflow:
                            TextOverflow
                                .ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 280,
                          child: Text(
                            ccr.problemDescription ??
                                '-',
                            maxLines: 3,
                            overflow:
                            TextOverflow
                                .ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration:
                          BoxDecoration(
                            color: _statusColor(
                              status,
                            ).withValues(
                              alpha: 0.10,
                            ),
                            borderRadius:
                            BorderRadius
                                .circular(
                              20,
                            ),
                          ),
                          child: Text(
                            status,
                            style:
                            TextStyle(
                              color:
                              _statusColor(
                                status,
                              ),
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Text(
                            ccr.currentStageName ??
                                ccr.currentStageKey ??
                                '-',
                            overflow:
                            TextOverflow
                                .ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          _formatDate(
                            ccr.createdAt,
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          tooltip:
                          'Open CCR',
                          onPressed: () =>
                              _openCcr(
                                ccr,
                              ),
                          icon:
                          const Icon(
                            Icons
                                .open_in_new,
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          tooltip:
                          'Delete permanently',
                          onPressed: () =>
                              _deleteCcr(
                                ccr,
                              ),
                          icon:
                          const Icon(
                            Icons
                                .delete_outline,
                            color:
                            Colors.red,
                          ),
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
}