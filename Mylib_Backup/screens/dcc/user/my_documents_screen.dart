import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/dcc/dcc_document.dart';
import '../../../services/dcc/dcc_document_service.dart';
import '../../../services/dcc/dcc_session.dart';

class MyDocumentsScreen extends StatefulWidget {
  const MyDocumentsScreen({super.key});

  @override
  State<MyDocumentsScreen> createState() =>
      _MyDocumentsScreenState();
}

class _MyDocumentsScreenState
    extends State<MyDocumentsScreen> {
  List<DccDocument> _documents = [];

  String _searchText = '';
  String _selectedStatus = 'All';

  bool _isRefreshing = false;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    _loadDocuments();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) {
        _loadDocuments();
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDocuments({
    bool showRefreshIndicator = false,
  }) async {
    final user = DccSession.currentUser;

    if (user == null) {
      return;
    }

    if (showRefreshIndicator && mounted) {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      final documents =
      await DccDocumentService.getDocumentsByUser(
        user.email,
      );

      documents.sort(
            (a, b) => b.revisionDate.compareTo(
          a.revisionDate,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _documents = documents;
        _isRefreshing = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isRefreshing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load documents.',
          ),
        ),
      );
    }
  }

  bool _isLatestRevision(
      DccDocument document,
      ) {
    final sameDocuments = _documents.where(
          (item) =>
      item.documentNo.trim().toLowerCase() ==
          document.documentNo.trim().toLowerCase(),
    );

    if (sameDocuments.isEmpty) {
      return true;
    }

    final latestRevision = sameDocuments
        .map((item) => item.revision)
        .reduce(
          (a, b) => a > b ? a : b,
    );

    return document.revision == latestRevision;
  }

  String _revisionStatus(
      DccDocument document,
      ) {
    return _isLatestRevision(document)
        ? 'Current Revision'
        : 'Previous Revision';
  }

  List<DccDocument> get _filteredDocuments {
    return _documents.where((document) {
      final search =
      _searchText.trim().toLowerCase();

      final matchesSearch =
          search.isEmpty ||
              document.documentNo
                  .toLowerCase()
                  .contains(search) ||
              document.documentName
                  .toLowerCase()
                  .contains(search) ||
              document.documentType
                  .toLowerCase()
                  .contains(search) ||
              document.department
                  .toLowerCase()
                  .contains(search);

      final matchesStatus =
          _selectedStatus == 'All' ||
              _displayStatus(document.status) ==
                  _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final documents = _filteredDocuments;

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'My Documents',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor:
        const Color(0xFF172033),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isRefreshing
                ? null
                : () {
              _loadDocuments(
                showRefreshIndicator: true,
              );
            },
            icon: _isRefreshing
                ? const SizedBox(
              width: 19,
              height: 19,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Icon(
              Icons.refresh_rounded,
            ),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Documents',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight:
                          FontWeight.w800,
                          color:
                          Color(0xFF172033),
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        'Documents created and submitted by you.',
                        style: TextStyle(
                          fontSize: 13,
                          color:
                          Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  width: 330,
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                      });
                    },
                    decoration:
                    InputDecoration(
                      hintText:
                      'Search documents...',
                      prefixIcon:
                      const Icon(
                        Icons.search_rounded,
                      ),
                      filled: true,
                      fillColor:
                      Colors.white,
                      contentPadding:
                      const EdgeInsets
                          .symmetric(
                        vertical: 14,
                      ),
                      border:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(
                          12,
                        ),
                        borderSide:
                        const BorderSide(
                          color:
                          Color(0xFFE4E8F0),
                        ),
                      ),
                      enabledBorder:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(
                          12,
                        ),
                        borderSide:
                        const BorderSide(
                          color:
                          Color(0xFFE4E8F0),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            _buildStatusFilters(),

            const SizedBox(height: 18),

            Expanded(
              child: _buildDocumentList(
                documents,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    const statuses = [
      'All',
      'Pending HOD',
      'Pending DCC',
      'Released',
      'Rejected',
    ];

    return Row(
      children: statuses.map((status) {
        final selected =
            _selectedStatus == status;

        return Padding(
          padding:
          const EdgeInsets.only(right: 10),
          child: ChoiceChip(
            label: Text(status),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedStatus = status;
              });
            },
            selectedColor:
            const Color(0xFFEFF3FF),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected
                  ? const Color(0xFF3155D9)
                  : const Color(0xFF6B7280),
            ),
            side: BorderSide(
              color: selected
                  ? const Color(0xFF3155D9)
                  : const Color(0xFFE4E8F0),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Widget _buildDocumentList(
  //     List<DccDocument> documents,
  //     ) {
  //   if (documents.isEmpty) {
  //     return Container(
  //       width: double.infinity,
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius:
  //         BorderRadius.circular(18),
  //         border: Border.all(
  //           color: const Color(0xFFE4E8F0),
  //         ),
  //       ),
  //       child: const Center(
  //         child: Column(
  //           mainAxisAlignment:
  //           MainAxisAlignment.center,
  //           children: [
  //             Icon(
  //               Icons.folder_open_outlined,
  //               size: 48,
  //               color: Color(0xFF9AA2B1),
  //             ),
  //
  //             SizedBox(height: 12),
  //
  //             Text(
  //               'No documents found',
  //               style: TextStyle(
  //                 fontSize: 16,
  //                 fontWeight:
  //                 FontWeight.w700,
  //                 color: Color(0xFF4B5563),
  //               ),
  //             ),
  //
  //             SizedBox(height: 5),
  //
  //             Text(
  //               'Documents you create will appear here.',
  //               style: TextStyle(
  //                 fontSize: 12,
  //                 color: Color(0xFF9AA2B1),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     );
  //   }
  //
  //   return Container(
  //     width: double.infinity,
  //
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius:
  //       BorderRadius.circular(18),
  //       border: Border.all(
  //         color: const Color(0xFFE4E8F0),
  //       ),
  //     ),
  //
  //     child: SingleChildScrollView(
  //       child: SingleChildScrollView(
  //         scrollDirection:
  //         Axis.horizontal,
  //
  //         child: DataTable(
  //           columnSpacing: 28,
  //           headingRowHeight: 54,
  //           dataRowMinHeight: 68,
  //           dataRowMaxHeight: 82,
  //
  //           headingRowColor:
  //           WidgetStateProperty.all(
  //             const Color(0xFFF8F9FC),
  //           ),
  //
  //           columns: const [
  //             DataColumn(
  //               label: Text(
  //                 'Document No',
  //                 style: TextStyle(
  //                   fontWeight:
  //                   FontWeight.w800,
  //                 ),
  //               ),
  //             ),
  //
  //             DataColumn(
  //               label: Text(
  //                 'Document Name',
  //                 style: TextStyle(
  //                   fontWeight:
  //                   FontWeight.w800,
  //                 ),
  //               ),
  //             ),
  //
  //             DataColumn(
  //               label: Text(
  //                 'Type',
  //                 style: TextStyle(
  //                   fontWeight:
  //                   FontWeight.w800,
  //                 ),
  //               ),
  //             ),
  //
  //             DataColumn(
  //               label: Text(
  //                 'Department',
  //                 style: TextStyle(
  //                   fontWeight:
  //                   FontWeight.w800,
  //                 ),
  //               ),
  //             ),
  //
  //             DataColumn(
  //               label: Text(
  //                 'Rev',
  //                 style: TextStyle(
  //                   fontWeight:
  //                   FontWeight.w800,
  //                 ),
  //               ),
  //             ),
  //
  //             DataColumn(
  //               label: Text(
  //                 'Rev Date',
  //                 style: TextStyle(
  //                   fontWeight:
  //                   FontWeight.w800,
  //                 ),
  //               ),
  //             ),
  //
  //             DataColumn(
  //               label: Text(
  //                 'Status',
  //                 style: TextStyle(
  //                   fontWeight:
  //                   FontWeight.w800,
  //                 ),
  //               ),
  //             ),
  //
  //             DataColumn(
  //               label: Text(
  //                 'Action',
  //                 style: TextStyle(
  //                   fontWeight:
  //                   FontWeight.w800,
  //                 ),
  //               ),
  //             ),
  //           ],
  //
  //           rows: documents.map(
  //                 (document) {
  //               return DataRow(
  //                 cells: [
  //                   DataCell(
  //                     Text(
  //                       document.documentNo,
  //                       style:
  //                       const TextStyle(
  //                         fontWeight:
  //                         FontWeight.w700,
  //                         color:
  //                         Color(0xFF172033),
  //                       ),
  //                     ),
  //                   ),
  //
  //                   DataCell(
  //                     Text(
  //                       document.documentName,
  //                     ),
  //                   ),
  //
  //                   DataCell(
  //                     Text(
  //                       document.documentType,
  //                     ),
  //                   ),
  //
  //                   DataCell(
  //                     Text(
  //                       document.department,
  //                     ),
  //                   ),
  //
  //                   DataCell(
  //                     Text(
  //                       document.revision
  //                           .toString(),
  //                     ),
  //                   ),
  //
  //                   DataCell(
  //                     Text(
  //                       document.revisionDate,
  //                     ),
  //                   ),
  //
  //                   DataCell(
  //                     _statusChip(
  //                       document.status,
  //                     ),
  //                   ),
  //
  //                   DataCell(
  //                     TextButton.icon(
  //                       onPressed: () {
  //                         _showDocumentDetails(
  //                           document,
  //                         );
  //                       },
  //                       icon: const Icon(
  //                         Icons.visibility_outlined,
  //                         size: 17,
  //                       ),
  //                       label: const Text(
  //                         'View',
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               );
  //             },
  //           ).toList(),
  //         ),
  //       ),
  //     ),
  //   );
  // }
  Widget _buildDocumentList(
      List<DccDocument> documents,
      ) {
    if (documents.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE4E8F0),
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open_outlined,
                size: 48,
                color: Color(0xFF9AA2B1),
              ),
              SizedBox(height: 12),
              Text(
                'No documents found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4B5563),
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Documents you create will appear here.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9AA2B1),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE4E8F0),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.15),
                1: FlexColumnWidth(1.8),
                2: FlexColumnWidth(0.9),
                3: FlexColumnWidth(1.15),
                4: FlexColumnWidth(0.55),
                5: FlexColumnWidth(0.95),
                6: FlexColumnWidth(1.25),
                7: FlexColumnWidth(1.15),
                8: FlexColumnWidth(0.9),
              },
              border: const TableBorder(
                horizontalInside: BorderSide(
                  color: Color(0xFFE4E8F0),
                  width: 1,
                ),
              ),
              defaultVerticalAlignment:
              TableCellVerticalAlignment.middle,
              children: [
                _buildTableHeader(),

                ...documents.map(
                      (document) => _buildTableRow(
                    document,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  TableRow _buildTableHeader() {
    const headerStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: Color(0xFF172033),
    );

    return TableRow(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FC),
      ),
      children: [
        _tableHeaderCell('Document No', headerStyle),
        _tableHeaderCell('Document Name', headerStyle),
        _tableHeaderCell('Type', headerStyle),
        _tableHeaderCell('Department', headerStyle),
        _tableHeaderCell('Rev', headerStyle),
        _tableHeaderCell('Rev Date', headerStyle),
        _tableHeaderCell('Revision Status', headerStyle),
        _tableHeaderCell('Status', headerStyle),
        _tableHeaderCell('Action', headerStyle),
      ],
    );
  }
  TableRow _buildTableRow(
      DccDocument document,
      ) {
    return TableRow(
      children: [
        _tableCell(
          document.documentNo,
          bold: true,
        ),

        _tableCell(
          document.documentName,
        ),

        _tableCell(
          document.documentType,
        ),

        _tableCell(
          document.department,
        ),

        _tableCell(
          document.revision.toString(),
        ),

        _tableCell(
          document.revisionDate,
        ),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _revisionStatusChip(
              document,
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _statusChip(
              document.status,
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                _showDocumentDetails(
                  document,
                );
              },
              icon: const Icon(
                Icons.visibility_outlined,
                size: 17,
              ),
              label: const Text(
                'View',
              ),
              style: TextButton.styleFrom(
                foregroundColor:
                const Color(0xFF3155D9),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _tableCell(
      String text, {
        bool bold = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 20,
      ),
      child: Text(
        text.isEmpty ? '-' : text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold
              ? FontWeight.w700
              : FontWeight.w500,
          color: const Color(0xFF172033),
        ),
      ),
    );
  }
  Widget _tableHeaderCell(
      String text,
      TextStyle style,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 17,
      ),
      child: Text(
        text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
  Widget _revisionStatusChip(
      DccDocument document,
      ) {
    final isLatest =
    _isLatestRevision(document);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isLatest
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFF1F3F5),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        isLatest
            ? 'Current Revision'
            : 'Previous Revision',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: isLatest
              ? const Color(0xFF2E7D32)
              : const Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color background;
    Color foreground;

    switch (status) {
      case 'PENDING_HOD':
        background =
        const Color(0xFFFFF3E0);
        foreground =
        const Color(0xFFE65100);
        break;

      case 'PENDING_DCC':
      case 'DCC_REVIEW':
        background =
        const Color(0xFFE3F2FD);
        foreground =
        const Color(0xFF1565C0);
        break;

      case 'RELEASED':
        background =
        const Color(0xFFE8F5E9);
        foreground =
        const Color(0xFF2E7D32);
        break;

      case 'REJECTED':
        background =
        const Color(0xFFFFEBEE);
        foreground =
        const Color(0xFFC62828);
        break;

      default:
        background =
        const Color(0xFFF1F3F5);
        foreground =
        const Color(0xFF616161);
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
        _displayStatus(status),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }

  String _displayStatus(String status) {
    switch (status) {
      case 'PENDING_HOD':
        return 'Pending HOD';

      case 'PENDING_DCC':
      case 'DCC_REVIEW':
        return 'Pending DCC';

      case 'RELEASED':
        return 'Released';

      case 'REJECTED':
        return 'Rejected';

      default:
        return status;
    }
  }

  void _showDocumentDetails(
      DccDocument document,
      ) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.description_outlined,
                color: Color(0xFF3155D9),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  document.documentNo,
                  style: const TextStyle(
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                _detailRow(
                  'Document Name',
                  document.documentName,
                ),

                _detailRow(
                  'Document Type',
                  document.documentType,
                ),

                _detailRow(
                  'Department',
                  document.department,
                ),

                _detailRow(
                  'Candidate',
                  document.candidateName,
                ),

                _detailRow(
                  'Employee ID',
                  document.employeeId,
                ),

                _detailRow(
                  'Revision',
                  document.revision.toString(),
                ),

                _detailRow(
                  'Revision Date',
                  document.revisionDate,
                ),

                _detailRow(
                  'HOD',
                  document.hodName,
                ),

                _detailRow(
                  'HOD Email',
                  document.hodEmail,
                ),

                _detailRow(
                  'Attachment',
                  document.attachmentName,
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Text(
                      'Status: ',
                      style: TextStyle(
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                    _statusChip(
                      document.status,
                    ),
                  ],
                ),

                if (document.rejectionReason
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(height: 18),

                  Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:
                      const Color(
                        0xFFFFEBEE,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rejection Reason',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                            FontWeight.w800,
                            color:
                            Color(0xFFC62828),
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          document
                              .rejectionReason,
                          style:
                          const TextStyle(
                            fontSize: 13,
                            color:
                            Color(0xFF5F2120),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Close',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(
      String label,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w700,
                color:
                Color(0xFF6B7280),
              ),
            ),
          ),

          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.w600,
                color:
                Color(0xFF172033),
              ),
            ),
          ),
        ],
      ),
    );
  }
}