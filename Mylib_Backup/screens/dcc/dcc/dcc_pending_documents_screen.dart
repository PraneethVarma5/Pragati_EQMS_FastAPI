import 'package:flutter/material.dart';

import '../../../models/dcc/dcc_document.dart';
import '../../../services/dcc/dcc_document_service.dart';
import 'dcc_document_review_screen.dart';
class DccPendingDocumentsScreen
    extends StatefulWidget {
  const DccPendingDocumentsScreen({
    super.key,
  });

  @override
  State<DccPendingDocumentsScreen> createState() =>
      _DccPendingDocumentsScreenState();
}

class _DccPendingDocumentsScreenState
    extends State<DccPendingDocumentsScreen> {
  List<DccDocument> _documents = [];
  List<DccDocument> _filteredDocuments = [];

  bool _isLoading = true;
  bool _isRefreshing = false;

  final TextEditingController _searchController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments({
    bool refresh = false,
  }) async {
    if (refresh) {
      setState(() {
        _isRefreshing = true;
      });
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final documents =
      await DccDocumentService.getDocuments();

      final pending = documents
          .where(
            (document) =>
        document.status == 'PENDING_DCC',
      )
          .toList();

      pending.sort(
            (a, b) =>
            b.revisionDate.compareTo(
              a.revisionDate,
            ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _documents = pending;
        _isLoading = false;
        _isRefreshing = false;
      });

      _applySearch();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load pending DCC documents.',
          ),
        ),
      );
    }
  }

  void _applySearch() {
    final query =
    _searchController.text.trim().toLowerCase();

    final filtered = _documents.where((document) {
      if (query.isEmpty) {
        return true;
      }

      return document.documentNo
          .toLowerCase()
          .contains(query) ||
          document.documentName
              .toLowerCase()
              .contains(query) ||
          document.documentType
              .toLowerCase()
              .contains(query) ||
          document.department
              .toLowerCase()
              .contains(query) ||
          document.createdByName
              .toLowerCase()
              .contains(query);
    }).toList();

    setState(() {
      _filteredDocuments = filtered;
    });
  }

  String _formatDate(String dateString) {
    try {
      final date =
      DateTime.parse(dateString);

      final day =
      date.day.toString().padLeft(2, '0');

      final month =
      date.month.toString().padLeft(2, '0');

      return '$day/$month/${date.year}';
    } catch (_) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'Pending DCC Documents',
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
                refresh: true,
              );
            },
            icon: _isRefreshing
                ? const SizedBox(
              width: 20,
              height: 20,
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

      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: () =>
            _loadDocuments(),
        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'Documents Waiting for DCC',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                  FontWeight.w800,
                  color:
                  Color(0xFF172033),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'These documents have been approved by HOD and are waiting for DCC processing.',
                style: TextStyle(
                  fontSize: 13,
                  color:
                  Color(0xFF6B7280),
                ),
              ),

              const SizedBox(height: 25),

              _buildSearch(),

              const SizedBox(height: 20),

              _buildDocumentTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      padding:
      const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xFFE4E8F0),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) {
          _applySearch();
        },
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search_rounded,
          ),
          hintText:
          'Search document number, name, department or user...',
          suffixIcon:
          _searchController.text.isNotEmpty
              ? IconButton(
            onPressed: () {
              _searchController.clear();
              _applySearch();
            },
            icon: const Icon(
              Icons.clear_rounded,
            ),
          )
              : null,
          filled: true,
          fillColor:
          const Color(0xFFF8F9FC),
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(12),
            borderSide:
            BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentTable() {
    if (_filteredDocuments.isEmpty) {
      return Container(
        width: double.infinity,
        height: 350,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(18),
          border: Border.all(
            color:
            const Color(0xFFE4E8F0),
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Icon(
                Icons
                    .assignment_turned_in_outlined,
                size: 48,
                color:
                Color(0xFF9AA2B1),
              ),
              SizedBox(height: 12),
              Text(
                'No pending DCC documents',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(0xFFE4E8F0),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics:
        const NeverScrollableScrollPhysics(),
        itemCount:
        _filteredDocuments.length,
        separatorBuilder: (_, _) =>
        const Divider(height: 1),
        itemBuilder: (context, index) {
          final document =
          _filteredDocuments[index];

          return InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DccDocumentReviewScreen(
                        document: document,
                      ),
                ),
              );

              if (mounted) {
                await _loadDocuments();
              }
            },
            child: Padding(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration:
                    BoxDecoration(
                      color:
                      const Color(
                        0xFFEFF3FF,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .description_outlined,
                      color:
                      Color(0xFF3155D9),
                    ),
                  ),

                  const SizedBox(
                    width: 15,
                  ),

                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          document.documentNo,
                          style:
                          const TextStyle(
                            fontSize: 14,
                            fontWeight:
                            FontWeight.w800,
                            color:
                            Color(
                              0xFF172033,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          document.documentName,
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          const TextStyle(
                            fontSize: 12,
                            color:
                            Color(
                              0xFF6B7280,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Text(
                      document.documentType,
                      style:
                      const TextStyle(
                        fontSize: 12,
                        color:
                        Color(
                          0xFF6B7280,
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Text(
                      document.department,
                      style:
                      const TextStyle(
                        fontSize: 12,
                        color:
                        Color(
                          0xFF6B7280,
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Text(
                      document.createdByName,
                      style:
                      const TextStyle(
                        fontSize: 12,
                        color:
                        Color(
                          0xFF6B7280,
                        ),
                      ),
                    ),
                  ),

                  Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      const Color(
                        0xFFFFF3DF,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: const Text(
                      'Pending DCC',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                        FontWeight.w800,
                        color:
                        Color(
                          0xFFE67E00,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Text(
                    _formatDate(
                      document.revisionDate,
                    ),
                    style:
                    const TextStyle(
                      fontSize: 11,
                      color:
                      Color(0xFF9AA2B1),
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  const Icon(
                    Icons
                        .chevron_right_rounded,
                    color:
                    Color(0xFF9AA2B1),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}