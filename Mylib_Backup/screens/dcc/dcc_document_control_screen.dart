import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../models/dcc/dcc_document.dart';
import '../../services/dcc/dcc_document_service.dart';

import 'dcc_login_screen.dart';

class DccDocumentControlScreen extends StatefulWidget {
  const DccDocumentControlScreen({super.key});

  @override
  State<DccDocumentControlScreen> createState() =>
      _DccDocumentControlScreenState();
}

class _DccDocumentControlScreenState
    extends State<DccDocumentControlScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  String _selectedCategory = 'All Documents';

  final List<String> _categories = [
    'All Documents',
    'Admin',
    'New Documents',
    'DMR',
    'Quality Manuals',
    'Project Documents',
    'New',
    'Master Data',
  ];

  List<DccDocument> _documents = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReleasedDocuments();
  }

  Future<void> _loadReleasedDocuments() async {
    try {
      final documents =
      await DccDocumentService.getDocuments();

      final released = documents
          .where(
            (document) =>
        document.status == 'RELEASED',
      )
          .toList();

      released.sort(
            (a, b) {
          final documentCompare =
          a.documentNo.compareTo(
            b.documentNo,
          );

          if (documentCompare != 0) {
            return documentCompare;
          }

          return b.revision.compareTo(
            a.revision,
          );
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _documents = released;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load released documents: $e',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final search =
    _searchController.text.trim().toLowerCase();

    return _documents.where((document) {
      final matchesCategory =
          _selectedCategory == 'All Documents' ||
              document.documentType
                  .toLowerCase() ==
                  _selectedCategory
                      .toLowerCase() ||
              document.department
                  .toLowerCase() ==
                  _selectedCategory
                      .toLowerCase();

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

      return matchesCategory && matchesSearch;
    }).toList();
  }
  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DccLoginScreen(),
      ),
    );
  }

  Future<void> _viewDocument(
      DccDocument document,
      ) async {
    final pdfPath =
    document.releasedPdfPath.trim();

    if (pdfPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Released PDF is not available for this document.',
          ),
        ),
      );
      return;
    }

    final pdfFile = File(pdfPath);

    if (!await pdfFile.exists()) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Released PDF could not be found:\n$pdfPath',
          ),
          duration:
          const Duration(seconds: 5),
        ),
      );
      return;
    }

    try {
      final result =
      await OpenFilex.open(pdfPath);

      if (!mounted) {
        return;
      }

      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message.isEmpty
                  ? 'Unable to open the released PDF.'
                  : result.message,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open released PDF: $e',
          ),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final documents = _filteredDocuments;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSidebar(),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        24,
                        30,
                        30,
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          _buildPageHeader(),

                          const SizedBox(height: 22),

                          Expanded(
                            child: _buildDocumentTable(
                              documents,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE4E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
            tooltip: 'Back',
          ),

          const SizedBox(width: 12),

          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: Color(0xFF3155D9),
              size: 23,
            ),
          ),

          const SizedBox(width: 14),

          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Document Control Centre',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF172033),
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Controlled Document Repository',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7A8292),
                ),
              ),
            ],
          ),

          const Spacer(),

          OutlinedButton.icon(
            onPressed: _openLogin,
            icon: const Icon(
              Icons.login_rounded,
              size: 18,
            ),
            label: const Text(
              'LOGIN',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3155D9),
              side: const BorderSide(
                color: Color(0xFF3155D9),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              24,
              20,
              12,
            ),
            child: Text(
              'DOCUMENTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Color(0xFF9AA2B1),
              ),
            ),
          ),

          ..._categories.map(
                (category) {
              final selected =
                  _selectedCategory == category;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFEFF3FF)
                        : Colors.transparent,
                    border: selected
                        ? const Border(
                      right: BorderSide(
                        color: Color(0xFF3155D9),
                        width: 3,
                      ),
                    )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _categoryIcon(category),
                        size: 18,
                        color: selected
                            ? const Color(0xFF3155D9)
                            : const Color(0xFF7A8292),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected
                                ? const Color(0xFF3155D9)
                                : const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const Spacer(),

          const Divider(
            color: Color(0xFFE4E8F0),
          ),

          const Padding(
            padding: EdgeInsets.all(22),
            child: Row(
              children: [
                Icon(
                  Icons.public_rounded,
                  size: 17,
                  color: Color(0xFF6B7280),
                ),
                SizedBox(width: 9),
                Text(
                  'Public View',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Released Documents',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF172033),
                ),
              ),
              SizedBox(height: 5),
              Text(
                'View controlled documents available for public access.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          width: 330,
          child: TextField(
            controller: _searchController,
            onChanged: (_) {
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: 'Search document...',
              prefixIcon: const Icon(
                Icons.search_rounded,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
              const EdgeInsets.symmetric(
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE4E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE4E8F0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF3155D9),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentTable(
      List<DccDocument> documents,
      ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE4E8F0),
        ),
      ),
      child: documents.isEmpty
          ? const Center(
        child: Text(
          'No released documents found.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
      )
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 28,
            headingRowHeight: 52,
            dataRowMinHeight: 62,
            dataRowMaxHeight: 72,
            headingRowColor:
            WidgetStateProperty.all(
              const Color(0xFFF8F9FC),
            ),
            columns: const [
              DataColumn(
                label: Text(
                  'Document No',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Document Name',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Type',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Rev',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Date',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Release Status',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'PDF Document',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            rows: documents.map(
                  (document) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        document.documentNo,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF172033),
                        ),
                      ),
                    ),

                    DataCell(
                      Text(
                        document.documentName,
                      ),
                    ),

                    DataCell(
                      Text(
                        document.documentType,
                      ),
                    ),

                    DataCell(
                      Text(
                        'Rev ${document.revision}',
                      ),
                    ),

                    DataCell(
                      Text(
                        document.revisionDate,
                      ),
                    ),

                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Released',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ),

                    DataCell(
                      TextButton.icon(
                        onPressed: () {
                          _viewDocument(document);
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
                        ),
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

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Admin':
        return Icons.admin_panel_settings_outlined;
      case 'New Documents':
        return Icons.note_add_outlined;
      case 'DMR':
        return Icons.edit_note_rounded;
      case 'Quality Manuals':
        return Icons.menu_book_outlined;
      case 'Project Documents':
        return Icons.folder_outlined;
      case 'New':
        return Icons.fiber_new_rounded;
      case 'Master Data':
        return Icons.storage_outlined;
      default:
        return Icons.folder_open_outlined;
    }
  }
}