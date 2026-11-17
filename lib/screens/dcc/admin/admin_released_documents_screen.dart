import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/dcc/dcc_document.dart';
import '../../../services/dcc/dcc_document_service.dart';
import '../../../services/dcc/dcc_storage_service.dart';

class AdminReleasedDocumentsScreen extends StatefulWidget {
  const AdminReleasedDocumentsScreen({
    super.key,
  });

  @override
  State<AdminReleasedDocumentsScreen> createState() =>
      _AdminReleasedDocumentsScreenState();
}

class _AdminReleasedDocumentsScreenState
    extends State<AdminReleasedDocumentsScreen> {
  List<DccDocument> _documents = [];

  bool _loading = true;
  bool _refreshing = false;
  bool _deleting = false;

  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments({
    bool refresh = false,
  }) async {
    if (refresh && mounted) {
      setState(() {
        _refreshing = true;
      });
    } else if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final documents =
      await DccDocumentService.getDocuments();

      final released = documents
          .where(
            (document) =>
        document.status.trim().toUpperCase() ==
            'RELEASED',
      )
          .toList();

      released.sort(
            (a, b) => b.revisionDate.compareTo(
          a.revisionDate,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _documents = released;
        _loading = false;
        _refreshing = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _refreshing = false;
      });

      _showMessage(
        'Unable to load released documents: $e',
        error: true,
      );
    }
  }

  List<DccDocument> get _filteredDocuments {
    final query = _search.trim().toLowerCase();

    if (query.isEmpty) {
      return _documents;
    }

    return _documents.where((document) {
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
          document.releasedPdfName
              .toLowerCase()
              .contains(query) ||
          document.releasedByName
              .toLowerCase()
              .contains(query);
    }).toList();
  }

  Future<void> _viewDocument(
      DccDocument document,
      ) async {
    try {
      final path =
      document.releasedPdfPath.trim();

      if (path.isEmpty) {
        throw Exception(
          'Released PDF path is not available.',
        );
      }

      final url =
      await DccStorageService.createSignedUrl(
        path,
        expiresIn: 3600,
      );

      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.platformDefault,
      );

      if (!opened) {
        throw Exception(
          'The browser could not open the PDF.',
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to open document: $e',
        error: true,
      );
    }
  }

  Future<void> _deleteDocument(
      DccDocument document,
      ) async {
    if (_deleting) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Released Document',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Permanently delete:\n\n'
                '${document.documentNo} '
                'Rev ${document.revision}\n'
                '${document.documentName}\n\n'
                'The released PDF and database record will be deleted.',
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
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              icon: const Icon(
                Icons.delete_outline,
              ),
              label: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _deleting = true;
    });

    try {
      final storagePath =
      document.releasedPdfPath.trim();

      // Delete the released PDF from storage.
      if (storagePath.isNotEmpty) {
        try {
          await DccStorageService.deleteFile(
            storagePath,
          );
        } catch (_) {
          // Continue with database deletion.
          //
          // The database record must not remain simply because
          // an old storage path is already missing.
        }
      }

      // DccDocumentService expects String documentId.
      await DccDocumentService.deleteDocument(
        document,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _documents.removeWhere(
              (item) => item.id == document.id,
        );
      });

      _showMessage(
        '${document.documentNo} Rev ${document.revision} deleted successfully.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to delete document: $e',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _deleting = false;
        });
      }
    }
  }

  void _showMessage(
      String message, {
        bool error = false,
      }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
        error ? Colors.red : null,
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatRevisionDate(
      String value,
      ) {
    if (value.trim().isEmpty) {
      return '-';
    }

    try {
      final date = DateTime.parse(value);

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final documents = _filteredDocuments;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'Released Documents',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshing
                ? null
                : () {
              _loadDocuments(
                refresh: true,
              );
            },
            icon: _refreshing
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
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(16),
                border: Border.all(
                  color:
                  const Color(0xFFE4E8F0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _search = value;
                        });
                      },
                      decoration:
                      InputDecoration(
                        hintText:
                        'Search document...',
                        prefixIcon:
                        const Icon(
                          Icons.search_rounded,
                        ),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    '${documents.length} document(s)',
                    style: const TextStyle(
                      fontWeight:
                      FontWeight.w700,
                      color:
                      Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Expanded(
              child: _loading
                  ? const Center(
                child:
                CircularProgressIndicator(),
              )
                  : documents.isEmpty
                  ? const Center(
                child: Text(
                  'No released documents found.',
                  style: TextStyle(
                    color:
                    Color(0xFF6B7280),
                  ),
                ),
              )
                  : Container(
                width:
                double.infinity,
                decoration:
                BoxDecoration(
                  color:
                  Colors.white,
                  borderRadius:
                  BorderRadius.circular(
                    16,
                  ),
                  border: Border.all(
                    color:
                    const Color(
                      0xFFE4E8F0,
                    ),
                  ),
                ),
                child:
                SingleChildScrollView(
                  child:
                  SingleChildScrollView(
                    scrollDirection:
                    Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(
                          label:
                          Text('SNo'),
                        ),
                        DataColumn(
                          label: Text(
                            'Document No',
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Document Name',
                          ),
                        ),
                        DataColumn(
                          label:
                          Text('Type'),
                        ),
                        DataColumn(
                          label: Text(
                            'Department',
                          ),
                        ),
                        DataColumn(
                          label:
                          Text('Rev'),
                        ),
                        DataColumn(
                          label: Text(
                            'Revision Date',
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Released By',
                          ),
                        ),
                        DataColumn(
                          label:
                          Text('View'),
                        ),
                        DataColumn(
                          label:
                          Text('Delete'),
                        ),
                      ],
                      rows: List.generate(
                        documents.length,
                            (index) {
                          final document =
                          documents[
                          index];

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  '${index + 1}',
                                ),
                              ),
                              DataCell(
                                Text(
                                  document
                                      .documentNo,
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width:
                                  240,
                                  child:
                                  Text(
                                    document
                                        .documentName,
                                    overflow:
                                    TextOverflow
                                        .ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  document
                                      .documentType,
                                ),
                              ),
                              DataCell(
                                Text(
                                  document
                                      .department,
                                ),
                              ),
                              DataCell(
                                Text(
                                  'Rev ${document.revision}',
                                ),
                              ),
                              DataCell(
                                Text(
                                  _formatRevisionDate(
                                    document
                                        .revisionDate,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  document
                                      .releasedByName,
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  tooltip:
                                  'View PDF',
                                  onPressed:
                                      () {
                                    _viewDocument(
                                      document,
                                    );
                                  },
                                  icon:
                                  const Icon(
                                    Icons
                                        .open_in_new_rounded,
                                  ),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  tooltip:
                                  'Delete permanently',
                                  onPressed:
                                  _deleting
                                      ? null
                                      : () {
                                    _deleteDocument(
                                      document,
                                    );
                                  },
                                  icon:
                                  const Icon(
                                    Icons
                                        .delete_outline_rounded,
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
            ),
          ],
        ),
      ),
    );
  }
}