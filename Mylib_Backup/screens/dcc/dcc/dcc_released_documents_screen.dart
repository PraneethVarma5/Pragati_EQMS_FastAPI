import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/dcc/dcc_document.dart';
import '../../../services/dcc/dcc_document_service.dart';
import '../../../services/dcc/dcc_storage_service.dart';

class DccReleasedDocumentsScreen extends StatefulWidget {
  const DccReleasedDocumentsScreen({
    super.key,
  });

  @override
  State<DccReleasedDocumentsScreen> createState() =>
      _DccReleasedDocumentsScreenState();
}


class _DccReleasedDocumentsScreenState
    extends State<DccReleasedDocumentsScreen> {

  List<DccDocument> _documents = [];

  bool _isLoading = true;
  bool _isRefreshing = false;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadReleasedDocuments();
  }


  Future<void> _loadReleasedDocuments({
    bool showRefreshIndicator = false,
  }) async {
    if (showRefreshIndicator && mounted) {
      setState(() {
        _isRefreshing = true;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final documents =
      await DccDocumentService.getDocuments();

      final releasedDocuments = documents
          .where(
            (document) =>
        document.status == 'RELEASED',
      )
          .toList();

      releasedDocuments.sort(
            (a, b) =>
            b.revisionDate.compareTo(
              a.revisionDate,
            ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _documents = releasedDocuments;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
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


  List<DccDocument> get _filteredDocuments {
    final query = _searchQuery.trim().toLowerCase();

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
          document.attachmentName
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


  Future<void> _viewFile(
      String path,
      String fileName,
      ) async {
    try {
      final storagePath = path.trim();

      if (storagePath.isEmpty) {
        throw Exception(
          'File path is not available.',
        );
      }

      final url =
      await DccStorageService.createSignedUrl(
        storagePath,
        expiresIn: 3600,
      );

      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.platformDefault,
      );

      if (!launched) {
        throw Exception(
          'The browser could not open the file.',
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Opening $fileName',
          ),
          duration:
          const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open $fileName: $e',
          ),
        ),
      );
    }
  }

  Future<void> _downloadFile(
      String path,
      String fileName,
      ) async {
    try {
      final storagePath = path.trim();

      if (storagePath.isEmpty) {
        throw Exception(
          'File path is not available.',
        );
      }

      final safeFileName =
      fileName.trim().isEmpty
          ? 'document'
          : fileName.trim();

      final url =
      await DccStorageService.createSignedUrl(
        storagePath,
        expiresIn: 3600,
        downloadFileName: safeFileName,
      );

      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.platformDefault,
      );

      if (!launched) {
        throw Exception(
          'The browser could not start the download.',
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Downloading $safeFileName',
          ),
          duration:
          const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Download failed: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final documents =
        _filteredDocuments;

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'Released Documents',
          style: TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),
        backgroundColor:
        Colors.white,
        foregroundColor:
        const Color(0xFF172033),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isRefreshing
                ? null
                : () {
              _loadReleasedDocuments(
                showRefreshIndicator:
                true,
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
            tooltip:
            'Refresh released documents',
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: _isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: () =>
            _loadReleasedDocuments(),
        child:
        SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        const Text(
                          'Released Documents',
                          style:
                          TextStyle(
                            fontSize: 28,
                            fontWeight:
                            FontWeight.w800,
                            color:
                            Color(
                              0xFF172033,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Text(
                          '${_documents.length} controlled document(s) released by DCC.',
                          style:
                          const TextStyle(
                            fontSize: 14,
                            color:
                            Color(
                              0xFF6B7280,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    width: 360,
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery =
                              value;
                        });
                      },
                      decoration:
                      InputDecoration(
                        hintText:
                        'Search released documents...',
                        prefixIcon:
                        const Icon(
                          Icons.search_rounded,
                        ),
                        filled: true,
                        fillColor:
                        Colors.white,
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            12,
                          ),
                          borderSide:
                          const BorderSide(
                            color:
                            Color(
                              0xFFE4E8F0,
                            ),
                          ),
                        ),
                        enabledBorder:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            12,
                          ),
                          borderSide:
                          const BorderSide(
                            color:
                            Color(
                              0xFFE4E8F0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 25,
              ),

              if (documents.isEmpty)
                _buildEmptyState()
              else
                ...documents.map(
                  _buildDocumentCard,
                ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      height: 330,
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
                  .picture_as_pdf_outlined,
              size: 52,
              color:
              Color(0xFF9AA2B1),
            ),
            SizedBox(height: 14),
            Text(
              'No released documents found',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                FontWeight.w700,
                color:
                Color(0xFF4B5563),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Documents released by DCC will appear here.',
              style: TextStyle(
                fontSize: 12,
                color:
                Color(0xFF9AA2B1),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildDocumentCard(
      DccDocument document,
      ) {
    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(
        bottom: 18,
      ),
      padding:
      const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(0xFFE4E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFE8F5E9,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
                child: const Icon(
                  Icons
                      .verified_outlined,
                  color:
                  Color(0xFF2E8B57),
                  size: 28,
                ),
              ),

              const SizedBox(
                width: 16,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      document.documentNo,
                      style:
                      const TextStyle(
                        fontSize: 16,
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
                        fontSize: 13,
                        color:
                        Color(
                          0xFF6B7280,
                        ),
                      ),
                    ),
                  ],
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
                    0xFFE8F5E9,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
                child: const Text(
                  'RELEASED',
                  style:
                  TextStyle(
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Color(
                      0xFF2E8B57,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          Wrap(
            spacing: 35,
            runSpacing: 12,
            children: [
              _infoItem(
                'Department',
                document.department,
              ),
              _infoItem(
                'Type',
                document.documentType,
              ),
              _infoItem(
                'Revision',
                'Rev ${document.revision}',
              ),
              _infoItem(
                'Rev Date',
                document.revisionDate,
              ),
              _infoItem(
                'Released By',
                document.releasedByName
                    .isEmpty
                    ? '-'
                    : document.releasedByName,
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          const Divider(
            height: 1,
          ),

          const SizedBox(
            height: 18,
          ),

          Row(
            children: [
              Expanded(
                child: _fileRow(
                  icon:
                  Icons.description_outlined,
                  title:
                  'Source File',
                  fileName:
                  document.attachmentName,
                  iconColor:
                  const Color(
                    0xFFE67E00,
                  ),
                  onView: () {
                    _viewFile(
                      document.attachmentPath,
                      document.attachmentName,
                    );
                  },
                  onDownload: () {
                    _downloadFile(
                      document.attachmentPath,
                      document.attachmentName,
                    );
                  },
                ),
              ),

              const SizedBox(
                width: 18,
              ),

              Expanded(
                child: _fileRow(
                  icon:
                  Icons.picture_as_pdf_outlined,
                  title:
                  'Released PDF',
                  fileName:
                  document.releasedPdfName,
                  iconColor:
                  const Color(
                    0xFFD32F2F,
                  ),
                  onView: () {
                    _viewFile(
                      document.releasedPdfPath,
                      document.releasedPdfName,
                    );
                  },
                  onDownload: () {
                    _downloadFile(
                      document.releasedPdfPath,
                      document.releasedPdfName,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _infoItem(
      String label,
      String value,
      ) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
            const TextStyle(
              fontSize: 10,
              fontWeight:
              FontWeight.w700,
              color:
              Color(0xFF9AA2B1),
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            value.isEmpty
                ? '-'
                : value,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style:
            const TextStyle(
              fontSize: 12,
              fontWeight:
              FontWeight.w700,
              color:
              Color(0xFF172033),
            ),
          ),
        ],
      ),
    );
  }


  Widget _fileRow({
    required IconData icon,
    required String title,
    required String fileName,
    required Color iconColor,
    required VoidCallback onView,
    required VoidCallback onDownload,
  }) {
    return Container(
      padding:
      const EdgeInsets.all(15),
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFF8F9FC),
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color:
          const Color(0xFFE4E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
            BoxDecoration(
              color:
              iconColor.withValues(
                alpha: 0.10,
              ),
              borderRadius:
              BorderRadius.circular(
                11,
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                  const TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Color(
                      0xFF172033,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  fileName.isEmpty
                      ? 'File not available'
                      : fileName,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 10,
                    color:
                    Color(
                      0xFF6B7280,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          IconButton(
            tooltip: 'View',
            onPressed:
            fileName.isEmpty
                ? null
                : onView,
            icon: const Icon(
              Icons.visibility_outlined,
              size: 19,
            ),
          ),

          IconButton(
            tooltip: 'Download',
            onPressed:
            fileName.isEmpty
                ? null
                : onDownload,
            icon: const Icon(
              Icons.download_outlined,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}