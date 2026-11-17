// import 'package:flutter/material.dart';
//
// import '../../services/ncr/ncr_service.dart';
// import 'ncr_admin_ncr_details_screen.dart';
//
// class NcrAdminRecordsScreen extends StatefulWidget {
//   const NcrAdminRecordsScreen({
//     super.key,
//   });
//
//   @override
//   State<NcrAdminRecordsScreen> createState() =>
//       _NcrAdminRecordsScreenState();
// }
//
// class _NcrAdminRecordsScreenState
//     extends State<NcrAdminRecordsScreen> {
//   List<Map<String, dynamic>> _allRecords = [];
//   List<Map<String, dynamic>> _filteredRecords = [];
//   List<Map<String, dynamic>> _statuses = [];
//
//   bool _isLoading = true;
//   String? _errorMessage;
//
//   final TextEditingController _searchController =
//   TextEditingController();
//
//   String _selectedStatusId = '';
//
//   @override
//   void initState() {
//     super.initState();
//
//     _searchController.addListener(
//       _applyFilters,
//     );
//
//     _loadRecords();
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   // ============================================================
//   // LOAD
//   // ============================================================
//
//   Future<void> _loadRecords() async {
//     if (!mounted) {
//       return;
//     }
//
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//
//     try {
//       final results = await Future.wait([
//         NcrService.getAllNcrs(),
//         NcrService.getActiveStatuses(),
//       ]);
//
//       if (!mounted) {
//         return;
//       }
//
//       setState(() {
//         _allRecords =
//         results[0] as List<Map<String, dynamic>>;
//
//         _statuses =
//         results[1] as List<Map<String, dynamic>>;
//
//         _isLoading = false;
//       });
//
//       _applyFilters();
//     } catch (e) {
//       if (!mounted) {
//         return;
//       }
//
//       setState(() {
//         _isLoading = false;
//         _errorMessage = e
//             .toString()
//             .replaceFirst(
//           'Exception: ',
//           '',
//         );
//       });
//     }
//   }
//
//   // ============================================================
//   // FILTER
//   // ============================================================
//
//   void _applyFilters() {
//     final search =
//     _searchController.text
//         .trim()
//         .toLowerCase();
//
//     final filtered =
//     _allRecords.where((record) {
//       final statusId =
//           record['status_id']?.toString() ?? '';
//
//       final matchesStatus =
//           _selectedStatusId.isEmpty ||
//               statusId == _selectedStatusId;
//
//       if (!matchesStatus) {
//         return false;
//       }
//
//       if (search.isEmpty) {
//         return true;
//       }
//
//       final values = [
//         record['ncr_number'],
//         record['process_function'],
//         record['clause_section'],
//         record['standard'],
//         record['ia_no'],
//         record['auditee_name'],
//         record['auditor_name'],
//         record['finding_statement'],
//         record[
//         'requirement_clause_reference'],
//         record['status_name'],
//       ];
//
//       return values.any(
//             (value) =>
//         value
//             ?.toString()
//             .toLowerCase()
//             .contains(search) ==
//             true,
//       );
//     }).toList();
//
//     if (mounted) {
//       setState(() {
//         _filteredRecords = filtered;
//       });
//     }
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
//       const Color(0xFFF5F7FA),
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         surfaceTintColor: Colors.white,
//         leading: IconButton(
//           tooltip: 'Back',
//           icon: const Icon(
//             Icons.arrow_back,
//           ),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//         title: const Text(
//           'NCR Records',
//           style: TextStyle(
//             fontWeight: FontWeight.w800,
//           ),
//         ),
//         actions: [
//           IconButton(
//             tooltip: 'Refresh',
//             icon: const Icon(
//               Icons.refresh,
//             ),
//             onPressed:
//             _isLoading
//                 ? null
//                 : _loadRecords,
//           ),
//           const SizedBox(
//             width: 8,
//           ),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: _loadRecords,
//         child: SingleChildScrollView(
//           physics:
//           const AlwaysScrollableScrollPhysics(),
//           padding:
//           const EdgeInsets.all(28),
//           child: Column(
//             crossAxisAlignment:
//             CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'All NCR Records',
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight:
//                   FontWeight.w800,
//                   color:
//                   Color(0xFF172033),
//                 ),
//               ),
//
//               const SizedBox(
//                 height: 6,
//               ),
//
//               Text(
//                 'View all NCRs and their current workflow status.',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color:
//                   Colors.grey.shade600,
//                 ),
//               ),
//
//               const SizedBox(
//                 height: 24,
//               ),
//
//               _filters(),
//
//               const SizedBox(
//                 height: 22,
//               ),
//
//               if (_errorMessage != null)
//                 _errorCard(),
//
//               if (_isLoading)
//                 _loadingCard()
//               else if (_filteredRecords.isEmpty)
//                 _emptyCard()
//               else
//                 _recordsList(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ============================================================
//   // FILTER BAR
//   // ============================================================
//
//   Widget _filters() {
//     return Container(
//       padding:
//       const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//         BorderRadius.circular(16),
//         border: Border.all(
//           color:
//           const Color(0xFFE2E7EF),
//         ),
//       ),
//       child: LayoutBuilder(
//         builder:
//             (context, constraints) {
//           final isWide =
//               constraints.maxWidth >= 700;
//
//           if (isWide) {
//             return Row(
//               children: [
//                 Expanded(
//                   child: _searchField(),
//                 ),
//                 const SizedBox(
//                   width: 16,
//                 ),
//                 SizedBox(
//                   width: 280,
//                   child: _statusDropdown(),
//                 ),
//               ],
//             );
//           }
//
//           return Column(
//             children: [
//               _searchField(),
//               const SizedBox(
//                 height: 14,
//               ),
//               _statusDropdown(),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _searchField() {
//     return TextField(
//       controller:
//       _searchController,
//       decoration:
//       InputDecoration(
//         labelText: 'Search NCRs',
//         hintText:
//         'NCR number, process, auditee, auditor...',
//         prefixIcon:
//         const Icon(
//           Icons.search,
//         ),
//         suffixIcon:
//         _searchController.text.isEmpty
//             ? null
//             : IconButton(
//           icon:
//           const Icon(
//             Icons.clear,
//           ),
//           onPressed: () {
//             _searchController.clear();
//           },
//         ),
//         border:
//         OutlineInputBorder(
//           borderRadius:
//           BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }
//
//   Widget _statusDropdown() {
//     return DropdownButtonFormField<String>(
//       value:
//       _selectedStatusId.isEmpty
//           ? null
//           : _selectedStatusId,
//       decoration:
//       InputDecoration(
//         labelText: 'Filter by Status',
//         prefixIcon:
//         const Icon(
//           Icons.filter_alt_outlined,
//         ),
//         border:
//         OutlineInputBorder(
//           borderRadius:
//           BorderRadius.circular(10),
//         ),
//       ),
//       items: [
//         const DropdownMenuItem<String>(
//           value: '',
//           child: Text(
//             'All Statuses',
//           ),
//         ),
//         ..._statuses.map(
//               (status) {
//             return DropdownMenuItem<String>(
//               value:
//               status['id']
//                   ?.toString(),
//               child: Text(
//                 status['status_name']
//                     ?.toString() ??
//                     status['status_key']
//                         ?.toString() ??
//                     '',
//               ),
//             );
//           },
//         ),
//       ],
//       onChanged: (value) {
//         setState(() {
//           _selectedStatusId =
//               value ?? '';
//         });
//
//         _applyFilters();
//       },
//     );
//   }
//
//   // ============================================================
//   // RECORDS
//   // ============================================================
//
//   Widget _recordsList() {
//     return Column(
//       children:
//       _filteredRecords.map(
//             (record) {
//           return Padding(
//             padding:
//             const EdgeInsets.only(
//               bottom: 14,
//             ),
//             child:
//             _recordCard(record),
//           );
//         },
//       ).toList(),
//     );
//   }
//
//   Widget _recordCard(
//       Map<String, dynamic> record,
//       ) {
//     final status =
//     record['status_name']
//         ?.toString()
//         .trim()
//         .isNotEmpty ==
//         true
//         ? record['status_name']
//         .toString()
//         : record['status_key']
//         ?.toString() ??
//         'Unknown';
//
//     final ncrNumber =
//         record['ncr_number']
//             ?.toString() ??
//             'NCR';
//
//     final process =
//         record['process_function']
//             ?.toString() ??
//             '';
//
//     final auditee =
//         record['auditee_name']
//             ?.toString() ??
//             'Not assigned';
//
//     final auditor =
//         record['auditor_name']
//             ?.toString() ??
//             'Not assigned';
//
//     final auditDate =
//     _formatDate(
//       record['audit_date'],
//     );
//
//     return Material(
//       color: Colors.white,
//       borderRadius:
//       BorderRadius.circular(16),
//       child: InkWell(
//         borderRadius:
//         BorderRadius.circular(16),
//         onTap: () async {
//           await Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) =>
//                   NcrAdminNcrDetailsScreen(
//                     ncrId:
//                     record['id']
//                         ?.toString() ??
//                         '',
//                   ),
//             ),
//           );
//
//           if (mounted) {
//             await _loadRecords();
//           }
//         },
//         child: Container(
//           padding:
//           const EdgeInsets.all(20),
//           decoration:
//           BoxDecoration(
//             borderRadius:
//             BorderRadius.circular(16),
//             border: Border.all(
//               color:
//               const Color(
//                 0xFFE2E7EF,
//               ),
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment:
//             CrossAxisAlignment.start,
//             children: [
//               Row(
//                 crossAxisAlignment:
//                 CrossAxisAlignment.start,
//                 children: [
//                   Expanded(
//                     child: Text(
//                       ncrNumber,
//                       style:
//                       const TextStyle(
//                         fontSize: 18,
//                         fontWeight:
//                         FontWeight.w800,
//                         color:
//                         Color(
//                           0xFF172033,
//                         ),
//                       ),
//                     ),
//                   ),
//                   _statusChip(status),
//                 ],
//               ),
//
//               const SizedBox(
//                 height: 15,
//               ),
//
//               Wrap(
//                 spacing: 28,
//                 runSpacing: 12,
//                 children: [
//                   _infoItem(
//                     Icons.account_tree_outlined,
//                     'Process',
//                     process,
//                   ),
//                   _infoItem(
//                     Icons.person_outline,
//                     'Auditee',
//                     auditee,
//                   ),
//                   _infoItem(
//                     Icons.person_search_outlined,
//                     'Auditor',
//                     auditor,
//                   ),
//                   _infoItem(
//                     Icons.calendar_today_outlined,
//                     'Audit Date',
//                     auditDate,
//                   ),
//                 ],
//               ),
//
//               const SizedBox(
//                 height: 16,
//               ),
//
//               const Divider(
//                 height: 1,
//               ),
//
//               const SizedBox(
//                 height: 12,
//               ),
//
//               Row(
//                 mainAxisAlignment:
//                 MainAxisAlignment.end,
//                 children: [
//                   Text(
//                     'View Details',
//                     style:
//                     const TextStyle(
//                       fontWeight:
//                       FontWeight.w700,
//                       color:
//                       Color(
//                         0xFF3155D9,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(
//                     width: 6,
//                   ),
//                   const Icon(
//                     Icons.arrow_forward,
//                     size: 17,
//                     color:
//                     Color(0xFF3155D9),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _infoItem(
//       IconData icon,
//       String label,
//       String value,
//       ) {
//     return SizedBox(
//       width: 220,
//       child: Row(
//         crossAxisAlignment:
//         CrossAxisAlignment.start,
//         children: [
//           Icon(
//             icon,
//             size: 18,
//             color:
//             Colors.grey.shade600,
//           ),
//           const SizedBox(
//             width: 8,
//           ),
//           Expanded(
//             child: Column(
//               crossAxisAlignment:
//               CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: 11,
//                     color:
//                     Colors.grey.shade500,
//                   ),
//                 ),
//                 const SizedBox(
//                   height: 2,
//                 ),
//                 Text(
//                   value.isEmpty
//                       ? 'Not provided'
//                       : value,
//                   maxLines: 2,
//                   overflow:
//                   TextOverflow.ellipsis,
//                   style:
//                   const TextStyle(
//                     fontSize: 13,
//                     fontWeight:
//                     FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _statusChip(String status) {
//     return Container(
//       padding:
//       const EdgeInsets.symmetric(
//         horizontal: 12,
//         vertical: 7,
//       ),
//       decoration: BoxDecoration(
//         color:
//         const Color(0xFFEFF3FF),
//         borderRadius:
//         BorderRadius.circular(20),
//       ),
//       child: Text(
//         status,
//         style: const TextStyle(
//           fontSize: 12,
//           fontWeight:
//           FontWeight.w700,
//           color:
//           Color(0xFF3155D9),
//         ),
//       ),
//     );
//   }
//
//   // ============================================================
//   // STATES
//   // ============================================================
//
//   Widget _loadingCard() {
//     return Container(
//       width: double.infinity,
//       padding:
//       const EdgeInsets.all(50),
//       decoration:
//       _boxDecoration(),
//       child: const Center(
//         child:
//         CircularProgressIndicator(),
//       ),
//     );
//   }
//
//   Widget _emptyCard() {
//     return Container(
//       width: double.infinity,
//       padding:
//       const EdgeInsets.all(55),
//       decoration:
//       _boxDecoration(),
//       child: Column(
//         children: [
//           Icon(
//             Icons.assignment_outlined,
//             size: 58,
//             color:
//             Colors.grey.shade400,
//           ),
//           const SizedBox(
//             height: 15,
//           ),
//           const Text(
//             'No NCR records found',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight:
//               FontWeight.w700,
//             ),
//           ),
//           const SizedBox(
//             height: 7,
//           ),
//           Text(
//             _allRecords.isEmpty
//                 ? 'There are currently no NCR records in the database.'
//                 : 'No records match the selected search or status filter.',
//             textAlign:
//             TextAlign.center,
//             style: TextStyle(
//               color:
//               Colors.grey.shade600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _errorCard() {
//     return Container(
//       width: double.infinity,
//       margin:
//       const EdgeInsets.only(
//         bottom: 20,
//       ),
//       padding:
//       const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color:
//         Colors.red.shade50,
//         borderRadius:
//         BorderRadius.circular(12),
//         border: Border.all(
//           color:
//           Colors.red.shade200,
//         ),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             Icons.error_outline,
//             color:
//             Colors.red.shade700,
//           ),
//           const SizedBox(
//             width: 12,
//           ),
//           Expanded(
//             child: Text(
//               _errorMessage ??
//                   'Unable to load NCR records.',
//               style: TextStyle(
//                 color:
//                 Colors.red.shade800,
//                 fontWeight:
//                 FontWeight.w600,
//               ),
//             ),
//           ),
//           TextButton(
//             onPressed:
//             _loadRecords,
//             child:
//             const Text('Retry'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   BoxDecoration _boxDecoration() {
//     return BoxDecoration(
//       color: Colors.white,
//       borderRadius:
//       BorderRadius.circular(16),
//       border: Border.all(
//         color:
//         const Color(0xFFE2E7EF),
//       ),
//     );
//   }
//
//   String _formatDate(dynamic value) {
//     if (value == null) {
//       return 'Not provided';
//     }
//
//     final parsed =
//     DateTime.tryParse(
//       value.toString(),
//     );
//
//     if (parsed == null) {
//       return value.toString();
//     }
//
//     return '${parsed.day.toString().padLeft(2, '0')}/'
//         '${parsed.month.toString().padLeft(2, '0')}/'
//         '${parsed.year}';
//   }
// }

import 'package:flutter/material.dart';

import '../../services/ncr/ncr_admin_service.dart';
import '../../services/ncr/ncr_service.dart';
import 'ncr_admin_ncr_details_screen.dart';

class NcrAdminRecordsScreen extends StatefulWidget {
  const NcrAdminRecordsScreen({
    super.key,
  });

  @override
  State<NcrAdminRecordsScreen> createState() =>
      _NcrAdminRecordsScreenState();
}

class _NcrAdminRecordsScreenState
    extends State<NcrAdminRecordsScreen> {
  List<Map<String, dynamic>> _allRecords = [];
  List<Map<String, dynamic>> _filteredRecords = [];

  List<Map<String, dynamic>> _statuses = [];

  bool _isLoading = true;
  bool _isDeleting = false;

  String? _errorMessage;

  String _searchText = '';
  String _selectedStatus = 'ALL';

  final TextEditingController _searchController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD RECORDS
  // ============================================================

  Future<void> _loadRecords() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        NcrService.getAllNcrs(),
        NcrService.getActiveStatuses(),
      ]);

      final records =
      results[0] as List<Map<String, dynamic>>;

      final statuses =
      results[1] as List<Map<String, dynamic>>;

      if (!mounted) {
        return;
      }

      setState(() {
        _allRecords = records;
        _statuses = statuses;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = e
            .toString()
            .replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  void _applyFilters() {
    final search =
    _searchText.trim().toLowerCase();

    final filtered =
    _allRecords.where((record) {
      final status =
          record['status_name']
              ?.toString()
              .trim() ??
              record['status_key']
                  ?.toString()
                  .trim() ??
              '';

      final searchableText = [
        record['ncr_number'],
        record['report_no'],
        record['process_function'],
        record['clause_section'],
        record['auditee_name'],
        record['auditor_name'],
        record['standard'],
        record['ia_no'],
        status,
      ]
          .map(
            (value) =>
        value?.toString().toLowerCase() ?? '',
      )
          .join(' ');

      final matchesSearch =
          search.isEmpty ||
              searchableText.contains(search);

      final matchesStatus =
          _selectedStatus == 'ALL' ||
              status.toLowerCase() ==
                  _selectedStatus.toLowerCase();

      return matchesSearch &&
          matchesStatus;
    }).toList();

    if (!mounted) {
      return;
    }

    setState(() {
      _filteredRecords = filtered;
    });
  }

  // ============================================================
  // OPEN DETAILS
  // ============================================================

  Future<void> _openDetails(
      String ncrId,
      ) async {
    if (ncrId.trim().isEmpty) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NcrAdminNcrDetailsScreen(
              ncrId: ncrId,
            ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadRecords();
  }

  // ============================================================
  // DELETE CONFIRMATION
  // ============================================================

  Future<void> _confirmDelete(
      Map<String, dynamic> record,
      ) async {
    if (_isDeleting) {
      return;
    }

    final ncrId =
        record['id']?.toString() ?? '';

    final ncrNumber =
    record['ncr_number']
        ?.toString()
        .trim()
        .isNotEmpty ==
        true
        ? record['ncr_number']
        .toString()
        : 'this NCR';

    if (ncrId.trim().isEmpty) {
      _showMessage(
        'NCR ID is missing.',
        isError: true,
      );
      return;
    }

    final confirmed =
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Delete NCR Permanently',
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently '
                'delete $ncrNumber?\n\n'
                'This will also delete its related '
                'approval history. This action cannot '
                'be undone.',
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
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
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

    if (confirmed != true ||
        !mounted) {
      return;
    }

    await _deleteNcr(
      ncrId: ncrId,
      ncrNumber: ncrNumber,
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteNcr({
    required String ncrId,
    required String ncrNumber,
  }) async {
    if (_isDeleting) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await NcrAdminService.deleteNcr(
        ncrId: ncrId,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        '$ncrNumber deleted permanently.',
      );

      await _loadRecords();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor:
          isError
              ? Colors.red.shade700
              : Colors.green.shade700,
          content: Text(message),
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
      const Color(0xFFF5F7FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,

        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'NCR Records',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh,
            ),
            onPressed:
            _isLoading
                ? null
                : _loadRecords,
          ),
          const SizedBox(
            width: 8,
          ),
        ],
      ),

      body: _isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : _errorMessage != null
          ? _errorView()
          : _buildContent(),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 1500,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NCR Records',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          'View and permanently manage all NCR records.',
                          style: TextStyle(
                            color:
                            Colors.grey.shade600,
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
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(20),
                      border: Border.all(
                        color:
                        const Color(0xFFE2E7EF),
                      ),
                    ),
                    child: Text(
                      '${_filteredRecords.length} NCRs',
                      style: const TextStyle(
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 22,
              ),

              _filterCard(),

              const SizedBox(
                height: 18,
              ),

              _recordsCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILTER CARD
  // ============================================================

  Widget _filterCard() {
    return Container(
      padding:
      const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xFFE2E7EF),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller:
              _searchController,
              onChanged: (value) {
                _searchText = value;
                _applyFilters();
              },
              decoration:
              InputDecoration(
                hintText:
                'Search NCR number, process, auditee, auditor...',
                prefixIcon:
                const Icon(
                  Icons.search,
                ),
                suffixIcon:
                _searchController
                    .text
                    .isNotEmpty
                    ? IconButton(
                  icon:
                  const Icon(
                    Icons.clear,
                  ),
                  onPressed: () {
                    _searchController
                        .clear();

                    _searchText =
                    '';

                    _applyFilters();
                  },
                )
                    : null,
                border:
                const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          SizedBox(
            width: 230,
            child: DropdownButtonFormField<
                String>(
              value:
              _selectedStatus,
              decoration:
              const InputDecoration(
                labelText: 'Status',
                border:
                OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(
                  value: 'ALL',
                  child: Text(
                    'All Statuses',
                  ),
                ),
                ..._statuses.map(
                      (status) {
                    final key =
                        status['status_key']
                            ?.toString() ??
                            '';

                    final name =
                        status['status_name']
                            ?.toString() ??
                            key;

                    return DropdownMenuItem(
                      value: name,
                      child: Text(
                        name,
                        overflow:
                        TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedStatus =
                      value;
                });

                _applyFilters();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECORDS CARD
  // ============================================================

  Widget _recordsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xFFE2E7EF),
        ),
      ),
      child: _filteredRecords.isEmpty
          ? _emptyState()
          : _table(),
    );
  }

  // ============================================================
  // TABLE
  // ============================================================

  Widget _table() {
    return ClipRRect(
      borderRadius:
      BorderRadius.circular(16),
      child: SingleChildScrollView(
        scrollDirection:
        Axis.horizontal,
        child: DataTable(
          headingRowColor:
          WidgetStateProperty.all(
            const Color(0xFFF8F9FC),
          ),
          dataRowMinHeight: 62,
          dataRowMaxHeight: 72,
          columnSpacing: 28,
          horizontalMargin: 22,

          columns: const [
            DataColumn(
              label: Text(
                'SNo',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'NCR No',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Process / Function',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Auditee',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Auditor',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Audit Date',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'View',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Delete',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ),
          ],

          rows: List.generate(
            _filteredRecords.length,
                (index) {
              final record =
              _filteredRecords[index];

              final id =
                  record['id']
                      ?.toString() ??
                      '';

              final ncrNumber =
                  record['ncr_number']
                      ?.toString() ??
                      '-';

              final process =
                  record['process_function']
                      ?.toString() ??
                      '-';

              final auditee =
                  record['auditee_name']
                      ?.toString() ??
                      '-';

              final auditor =
                  record['auditor_name']
                      ?.toString() ??
                      '-';

              final auditDate =
              _formatDate(
                record['audit_date'],
              );

              final status =
              record['status_name']
                  ?.toString()
                  .trim()
                  .isNotEmpty ==
                  true
                  ? record['status_name']
                  .toString()
                  : record['status_key']
                  ?.toString() ??
                  'Unknown';

              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      '${index + 1}',
                    ),
                  ),

                  DataCell(
                    SizedBox(
                      width: 130,
                      child: Text(
                        ncrNumber,
                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  DataCell(
                    SizedBox(
                      width: 220,
                      child: Text(
                        process,
                        overflow:
                        TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  DataCell(
                    SizedBox(
                      width: 170,
                      child: Text(
                        auditee,
                        overflow:
                        TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  DataCell(
                    SizedBox(
                      width: 170,
                      child: Text(
                        auditor,
                        overflow:
                        TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  DataCell(
                    Text(
                      auditDate,
                    ),
                  ),

                  DataCell(
                    _statusChip(
                      status,
                    ),
                  ),

                  DataCell(
                    IconButton(
                      tooltip:
                      'View NCR',
                      icon:
                      const Icon(
                        Icons
                            .visibility_outlined,
                      ),
                      onPressed:
                      _isDeleting
                          ? null
                          : () {
                        _openDetails(
                          id,
                        );
                      },
                    ),
                  ),

                  DataCell(
                    IconButton(
                      tooltip:
                      'Delete NCR permanently',
                      icon:
                      const Icon(
                        Icons
                            .delete_outline,
                        color:
                        Colors.red,
                      ),
                      onPressed:
                      _isDeleting
                          ? null
                          : () {
                        _confirmDelete(
                          record,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _statusChip(
      String status,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color:
        const Color(0xFFEFF3FF),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
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
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 70,
        horizontal: 20,
      ),
      child: Column(
        children: [
          Icon(
            Icons
                .assignment_outlined,
            size: 58,
            color:
            Colors.grey.shade400,
          ),
          const SizedBox(
            height: 14,
          ),
          const Text(
            'No NCR records found',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 7,
          ),
          Text(
            _searchText.isNotEmpty ||
                _selectedStatus !=
                    'ALL'
                ? 'Try changing the search or status filter.'
                : 'There are no NCR records available.',
            style: TextStyle(
              color:
              Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _errorView() {
    return Center(
      child: Container(
        margin:
        const EdgeInsets.all(28),
        padding:
        const EdgeInsets.all(28),
        constraints:
        const BoxConstraints(
          maxWidth: 650,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(16),
          border: Border.all(
            color:
            Colors.red.shade200,
          ),
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 50,
              color:
              Colors.red.shade700,
            ),
            const SizedBox(
              height: 14,
            ),
            Text(
              _errorMessage ??
                  'Unable to load NCR records.',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                color:
                Colors.red.shade800,
                fontWeight:
                FontWeight.w600,
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            FilledButton.icon(
              onPressed:
              _loadRecords,
              icon:
              const Icon(
                Icons.refresh,
              ),
              label:
              const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(
      dynamic value,
      ) {
    if (value == null) {
      return '-';
    }

    final date =
    DateTime.tryParse(
      value.toString(),
    );

    if (date == null) {
      return value.toString();
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}