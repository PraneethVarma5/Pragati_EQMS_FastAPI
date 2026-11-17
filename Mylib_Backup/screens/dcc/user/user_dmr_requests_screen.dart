import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/dcc/dcc_dmr_request.dart';
import '../../../services/dcc/dcc_dmr_service.dart';
import '../../../services/dcc/dcc_document_service.dart';
import '../../../services/dcc/dcc_session.dart';
import '../../../models/dcc/dcc_document.dart';
import 'package:file_picker/file_picker.dart';
import '../../../services/dcc/dcc_notification_service.dart';
import '../../../services/dcc/dcc_storage_service.dart';
class UserDmrRequestsScreen extends StatefulWidget {
  const UserDmrRequestsScreen({
    super.key,
  });

  @override
  State<UserDmrRequestsScreen> createState() =>
      _UserDmrRequestsScreenState();
}

class _UserDmrRequestsScreenState
    extends State<UserDmrRequestsScreen> {
  List<DccDmrRequest> _requests = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isUploading = false;
  bool _isSubmitting = false;

  PlatformFile? _selectedRevisedFile;
  String _selectedRevisedFileName = '';

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests({
    bool refresh = false,
  }) async {
    final user = DccSession.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

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
      final requests =
      await DccDmrService.getRequestsByUser(
        user.email,
      );

      final approvedRequests = requests
          .where(
            (request) =>
        request.status ==
            'EDIT_ACCESS_GRANTED' &&
            request.modificationAccessGranted,
      )
          .toList();

      approvedRequests.sort(
            (a, b) =>
            b.createdDate.compareTo(
              a.createdDate,
            ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _requests = approvedRequests;
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
            'Unable to load DMR requests: $e',
          ),
        ),
      );
    }
  }

  Future<DccDocument?> _getDocument(
      DccDmrRequest request,
      ) async {
    final documents =
    await DccDocumentService.getDocuments();

    try {
      return documents.firstWhere(
            (document) =>
        document.id == request.documentId,
      );
    } catch (_) {
      return null;
    }
  }
  Future<void> _selectRevisedFile() async {
    try {
      final result =
      await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result == null ||
          result.files.single.path == null) {
        return;
      }

      final file =
          result.files.single;

      if (file.bytes == null ||
          file.bytes!.isEmpty) {
        throw Exception(
          'Selected file could not be read.',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedRevisedFile = file;
        _selectedRevisedFileName =
            result.files.single.name;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to select revised file: $e',
          ),
        ),
      );
    }
  }

  void _removeRevisedFile() {
    setState(() {
      _selectedRevisedFile = null;
      _selectedRevisedFileName = '';
    });
  }
  Future<bool> _uploadRevisedFile(
      DccDmrRequest request,
      ) async {
    if (_selectedRevisedFile == null) {
      return false;
    }

    final fileBytes =
        _selectedRevisedFile!.bytes;

    if (fileBytes == null ||
        fileBytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Selected revised file could not be read.',
            ),
          ),
        );
      }

      return false;
    }

    try {
      setState(() {
        _isUploading = true;
      });

      final revisedPath =
      await DccStorageService.uploadRevisedDocument(
        fileBytes: fileBytes,
        requestId: request.id,
        originalFileName: _selectedRevisedFileName,
      );

      final updatedRequest =
      DccDmrRequest(
        id: request.id,
        documentId: request.documentId,
        documentNo: request.documentNo,
        documentName: request.documentName,
        documentType: request.documentType,
        department: request.department,
        requestedByName:
        request.requestedByName,
        requestedByEmail:
        request.requestedByEmail,
        hodName: request.hodName,
        hodEmail: request.hodEmail,
        currentRevision:
        request.currentRevision,
        requestReason:
        request.requestReason,
        status: 'PENDING_DCC_REVIEW',
        rejectionReason:
        request.rejectionReason,
        createdDate:
        request.createdDate,
        hodActionDate:
        request.hodActionDate,
        dccActionDate:
        request.dccActionDate,

        sourceFilePath:
        request.sourceFilePath,

        sourceFileName:
        request.sourceFileName,

        revisedFilePath:
        revisedPath,

        revisedFileName:
        _selectedRevisedFileName,

        revisedSubmittedDate:
        DateTime.now().toIso8601String(),

        revisedRejectionReason: '',

        modificationAccessGranted:
        true,
      );

      await DccDmrService.updateRequest(
        updatedRequest,
      );

      await DccNotificationService.notifyAllDcc(
        title:
        'Revised Document Ready for Review',
        message:
        '${request.requestedByName} submitted a revised document '
            'for ${request.documentNo}. It is ready for DCC review.',
        type:
        'REVISED_DOCUMENT_SUBMITTED',
        documentNo:
        request.documentNo,
      );

      if (!mounted) {
        return true;
      }

      setState(() {
        _isUploading = false;
        _selectedRevisedFile = null;
        _selectedRevisedFileName = '';
      });

      await _loadRequests(
        refresh: true,
      );

      if (!mounted) {
        return true;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Revised document uploaded and sent to DCC for review.',
          ),
        ),
      );

      return true;
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to upload revised document: $e',
            ),
          ),
        );
      }

      return false;
    }
  }
  Future<void> _viewSource(
      DccDmrRequest request,
      ) async {
    try {
      final document =
      await _getDocument(request);

      if (document == null) {
        throw Exception(
          'Document could not be found.',
        );
      }

      final storagePath =
      document.attachmentPath.trim();

      if (storagePath.isEmpty) {
        throw Exception(
          'Controlled source file is not available.',
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
          'The browser could not open the source file.',
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open source file: $e',
          ),
        ),
      );
    }
  }

  Future<void> _downloadSource(
      DccDmrRequest request,
      ) async {
    try {
      final document =
      await _getDocument(request);

      if (document == null) {
        throw Exception(
          'Document could not be found.',
        );
      }

      final storagePath =
      document.attachmentPath.trim();

      if (storagePath.isEmpty) {
        throw Exception(
          'Controlled source file is not available.',
        );
      }

      final fileName =
      document.attachmentName.trim().isEmpty
          ? 'source_document'
          : document.attachmentName.trim();

      final url =
      await DccStorageService.createSignedUrl(
        storagePath,
        expiresIn: 3600,
        downloadFileName: fileName,
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
            'Downloading $fileName',
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
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'DMR / Edit Access',
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
            onPressed:
            _isRefreshing
                ? null
                : () {
              _loadRequests(
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
          : RefreshIndicator(
        onRefresh: () =>
            _loadRequests(),
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
              const Text(
                'Approved Modifications',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                  FontWeight.w800,
                  color:
                  Color(0xFF172033),
                ),
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                '${_requests.length} document(s) available for modification.',
                style: const TextStyle(
                  fontSize: 14,
                  color:
                  Color(0xFF6B7280),
                ),
              ),
              const SizedBox(
                height: 25,
              ),
              if (_requests.isEmpty)
                _buildEmptyState()
              else
                ..._requests.map(
                  _buildRequestCard,
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
      height: 300,
      decoration:
      BoxDecoration(
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
                  .edit_document,
              size: 52,
              color:
              Color(0xFF9AA2B1),
            ),
            SizedBox(
              height: 12,
            ),
            Text(
              'No approved DMR requests',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                FontWeight.w700,
                color:
                Color(0xFF4B5563),
              ),
            ),
            SizedBox(
              height: 6,
            ),
            Text(
              'Documents approved for modification will appear here.',
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

  Widget _buildRequestCard(
      DccDmrRequest request,
      ) {
    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(
        bottom: 18,
      ),
      padding:
      const EdgeInsets.all(22),
      decoration:
      BoxDecoration(
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
                width: 52,
                height: 52,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFF2E8FF,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
                child: const Icon(
                  Icons
                      .edit_document,
                  color:
                  Color(0xFF9C27B0),
                ),
              ),
              const SizedBox(
                width: 15,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      request.documentNo,
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
                      request.documentName,
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
                  horizontal: 11,
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
                  'EDIT ACCESS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Color(0xFF2E8B57),
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
            runSpacing: 14,
            children: [
              _infoItem(
                'Department',
                request.department,
              ),
              _infoItem(
                'Document Type',
                request.documentType,
              ),
              _infoItem(
                'Current Revision',
                'Rev ${request.currentRevision}',
              ),
              _infoItem(
                'Approved By',
                'DCC',
              ),
            ],
          ),
          const SizedBox(
            height: 18,
          ),
          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.all(15),
            decoration:
            BoxDecoration(
              color:
              const Color(0xFFF8F9FC),
              borderRadius:
              BorderRadius.circular(
                13,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons
                      .description_outlined,
                  color:
                  Color(0xFFE67E00),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      const Text(
                        'Controlled Source File',
                        style:
                        TextStyle(
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
                        height: 4,
                      ),
                      FutureBuilder<
                          DccDocument?>(
                        future:
                        _getDocument(
                          request,
                        ),
                        builder:
                            (
                            context,
                            snapshot,
                            ) {
                          final document =
                              snapshot
                                  .data;

                          return Text(
                            document
                                ?.attachmentName
                                .isNotEmpty ==
                                true
                                ? document!
                                .attachmentName
                                : 'Source file available after DCC upload',
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            const TextStyle(
                              fontSize: 11,
                              color:
                              Color(
                                0xFF6B7280,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          Row(
            mainAxisAlignment:
            MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () =>
                    _viewSource(
                      request,
                    ),
                icon: const Icon(
                  Icons
                      .visibility_outlined,
                ),
                label:
                const Text('View Source'),
              ),
              const SizedBox(
                width: 12,
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    _downloadSource(
                      request,
                    ),
                icon: const Icon(
                  Icons
                      .download_outlined,
                ),
                label:
                const Text('Download Source'),
              ),
            ],
          ),
          if (request.status ==
              'EDIT_ACCESS_GRANTED' ||
              request.status ==
                  'PENDING_DCC_REVIEW') ...[
            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FC),
                borderRadius:
                BorderRadius.circular(13),
                border: Border.all(
                  color: const Color(0xFFE4E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Submit Revised Document',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF172033),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    request.status ==
                        'PENDING_DCC_REVIEW'
                        ? 'Revised document is already with DCC for review.'
                        : 'Upload the edited document and send it to DCC.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),

                  if (request.status ==
                      'EDIT_ACCESS_GRANTED') ...[
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedRevisedFileName.isEmpty
                                ? 'No revised file selected'
                                : _selectedRevisedFileName,
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight:
                              FontWeight.w700,
                              color:
                              Color(0xFF172033),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        OutlinedButton.icon(
                          onPressed: _isUploading ||
                              _isSubmitting
                              ? null
                              : _selectRevisedFile,
                          icon: const Icon(
                            Icons.attach_file_rounded,
                            size: 17,
                          ),
                          label: Text(
                            _selectedRevisedFile == null
                                ? 'Choose File'
                                : 'Change File',
                          ),
                        ),

                        if (_selectedRevisedFile !=
                            null) ...[
                          const SizedBox(width: 6),

                          IconButton(
                            tooltip:
                            'Remove selected file',
                            onPressed:
                            _isUploading ||
                                _isSubmitting
                                ? null
                                : _removeRevisedFile,
                            icon: const Icon(
                              Icons.close_rounded,
                              color:
                              Color(0xFFD64545),
                            ),
                          ),
                        ],
                      ],
                    ),

                    if (_selectedRevisedFile !=
                        null) ...[
                      const SizedBox(height: 12),

                      Align(
                        alignment:
                        Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed:
                          _isUploading ||
                              _isSubmitting
                              ? null
                              : () async {
                            await _uploadRevisedFile(
                              request,
                            );
                          },
                          icon: _isUploading
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                            CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(
                            Icons
                                .cloud_upload_outlined,
                            size: 17,
                          ),
                          label: Text(
                            _isUploading
                                ? 'Uploading...'
                                : 'Upload & Send to DCC',
                          ),
                        ),
                      ),
                    ],
                  ],

                  if (request.status ==
                      'PENDING_DCC_REVIEW') ...[
                    const SizedBox(height: 14),

                    Container(
                      width: double.infinity,
                      padding:
                      const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                        const Color(0xFFEAF7ED),
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons
                                .hourglass_top_rounded,
                            size: 18,
                            color:
                            Color(0xFF2E8B57),
                          ),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Waiting for DCC to review the revised document.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                FontWeight.w700,
                                color:
                                Color(0xFF2E8B57),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
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
}