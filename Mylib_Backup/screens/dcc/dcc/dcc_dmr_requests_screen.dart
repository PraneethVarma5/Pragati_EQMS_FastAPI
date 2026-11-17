import 'package:flutter/material.dart';

import '../../../models/dcc/dcc_dmr_request.dart';
import '../../../models/dcc/dcc_notification.dart';
import '../../../models/dcc/dcc_activity.dart';

import '../../../services/dcc/dcc_dmr_service.dart';
import '../../../services/dcc/dcc_notification_service.dart';
import '../../../services/dcc/dcc_activity_service.dart';
import '../../../services/dcc/dcc_session.dart';
import '../../../services/dcc/dcc_document_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class DccDmrRequestsScreen extends StatefulWidget {
  const DccDmrRequestsScreen({
    super.key,
  });

  @override
  State<DccDmrRequestsScreen> createState() =>
      _DccDmrRequestsScreenState();
}

class _DccDmrRequestsScreenState
    extends State<DccDmrRequestsScreen> {
  List<DccDmrRequest> _requests = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isUploading = false;
  bool _sourceFileUploaded = false;

  String _searchText = '';

  File? _selectedSourceFile;
  String _selectedSourceFileName = '';

  final TextEditingController _searchController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests({
    bool refresh = false,
  }) async {
    if (refresh && mounted) {
      setState(() {
        _isRefreshing = true;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final requests =
      await DccDmrService.getPendingDccRequests();

      requests.sort(
            (a, b) =>
            b.createdDate.compareTo(
              a.createdDate,
            ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _requests = requests;
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

  List<DccDmrRequest> get _filteredRequests {
    final search =
    _searchText.trim().toLowerCase();

    if (search.isEmpty) {
      return _requests;
    }

    return _requests.where((request) {
      return request.documentNo
          .toLowerCase()
          .contains(search) ||
          request.documentName
              .toLowerCase()
              .contains(search) ||
          request.documentType
              .toLowerCase()
              .contains(search) ||
          request.department
              .toLowerCase()
              .contains(search) ||
          request.requestedByName
              .toLowerCase()
              .contains(search) ||
          request.requestReason
              .toLowerCase()
              .contains(search);
    }).toList();
  }

  Future<void> _selectSourceFile() async {
    try {
      final result =
      await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: false,
      );

      if (result == null ||
          result.files.single.path == null) {
        return;
      }

      final selectedFile =
      File(result.files.single.path!);

      if (!await selectedFile.exists()) {
        throw Exception(
          'Selected source file could not be found.',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedSourceFile =
            selectedFile;
        _selectedSourceFileName =
            result.files.single.name;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to select source file: $e',
          ),
        ),
      );
    }
  }

  void _removeSelectedSourceFile() {
    setState(() {
      _selectedSourceFile = null;
      _selectedSourceFileName = '';
      _sourceFileUploaded = false;
    });
  }

  Future<String?> _uploadSelectedSourceFile(
      DccDmrRequest request,
      ) async {
    if (_selectedSourceFile == null) {
      return null;
    }

    try {
      setState(() {
        _isUploading = true;
      });

      final userProfile =
      Platform.environment['USERPROFILE'];

      if (userProfile == null ||
          userProfile.trim().isEmpty) {
        throw Exception(
          'Unable to determine Windows user folder.',
        );
      }

      final sourceDirectory =
      Directory(
        '$userProfile\\Downloads\\Digital ARR\\DCC Source Documents',
      );

      if (!await sourceDirectory.exists()) {
        await sourceDirectory.create(
          recursive: true,
        );
      }

      final originalName =
          _selectedSourceFileName;

      final safeDocumentNo =
      request.documentNo.replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );

      final safeFileName =
      originalName.replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );

      final destinationName =
          '${safeDocumentNo}_Source_$safeFileName';

      final destination = File(
        '${sourceDirectory.path}\\$destinationName',
      );

      await _selectedSourceFile!.copy(
        destination.path,
      );

      if (!await destination.exists()) {
        throw Exception(
          'Source file could not be verified after upload.',
        );
      }

      await DccDocumentService.updateSourceFile(
        documentId:
        request.documentId,
        attachmentPath:
        destination.path,
        attachmentName:
        destinationName,
      );

      if (mounted) {
        setState(() {
          _isUploading = false;
          _sourceFileUploaded = true;
        });
      }

      return destination.path;
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to upload source file: $e',
            ),
          ),
        );
      }

      return null;
    }
  }
  Future<void> _openRevisedFile(
      DccDmrRequest request,
      ) async {
    try {
      final path =
      request.revisedFilePath.trim();

      if (path.isEmpty) {
        throw Exception(
          'Revised file is not available.',
        );
      }

      final file = File(path);

      if (!await file.exists()) {
        throw Exception(
          'Revised file could not be found.',
        );
      }

      if (Platform.isWindows) {
        await Process.run(
          'cmd.exe',
          [
            '/c',
            'start',
            '',
            file.path,
          ],
        );
      } else if (Platform.isMacOS) {
        await Process.run(
          'open',
          [file.path],
        );
      } else if (Platform.isLinux) {
        await Process.run(
          'xdg-open',
          [file.path],
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open revised file: $e',
          ),
        ),
      );
    }
  }
  Future<void> _downloadRevisedFile(
      DccDmrRequest request,
      ) async {
    try {
      final sourcePath =
      request.revisedFilePath.trim();

      if (sourcePath.isEmpty) {
        throw Exception(
          'Revised file is not available.',
        );
      }

      final sourceFile =
      File(sourcePath);

      if (!await sourceFile.exists()) {
        throw Exception(
          'Revised file could not be found.',
        );
      }

      final userProfile =
      Platform.environment['USERPROFILE'];

      if (userProfile == null ||
          userProfile.trim().isEmpty) {
        throw Exception(
          'Unable to determine Windows user folder.',
        );
      }

      final downloadDirectory =
      Directory(
        '$userProfile\\Downloads',
      );

      if (!await downloadDirectory.exists()) {
        await downloadDirectory.create(
          recursive: true,
        );
      }

      final originalName =
      request.revisedFileName.trim();

      final extension =
      originalName.contains('.')
          ? originalName
          .substring(
        originalName.lastIndexOf('.'),
      )
          : '';

      final baseName =
      extension.isEmpty
          ? originalName
          : originalName.substring(
        0,
        originalName.length -
            extension.length,
      );

      var destination =
      File(
        '${downloadDirectory.path}\\$originalName',
      );

      var downloadNumber = 2;

      while (await destination.exists()) {
        destination = File(
          '${downloadDirectory.path}\\'
              '${baseName}_$downloadNumber$extension',
        );

        downloadNumber++;
      }

      await sourceFile.copy(
        destination.path,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Downloaded to: ${destination.path}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to download revised file: $e',
          ),
        ),
      );
    }
  }
  Future<void> _rejectRevisedDocument(
      DccDmrRequest request,
      ) async {
    final controller =
    TextEditingController();

    final reason =
    await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Reject Revised Document',
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration:
            const InputDecoration(
              labelText: 'Rejection Reason',
              hintText:
              'Explain what needs to be corrected...',
              border:
              OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                    dialogContext,
                  ),
              child:
              const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value =
                controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  value,
                );
              },
              child:
              const Text('Reject'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (reason == null ||
        reason.trim().isEmpty) {
      return;
    }

    final user =
        DccSession.currentUser;

    if (user == null) {
      return;
    }

    try {
      await DccDmrService
          .rejectRevisedDocument(
        request,
        reason.trim(),
        user.name,
      );

      await _loadRequests(
        refresh: true,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Revised document rejected. User can modify and resubmit.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to reject revised document: $e',
          ),
        ),
      );
    }
  }
  Future<void> _acceptRevisedDocument(
      DccDmrRequest request,
      ) async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Accept Revised Document',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Accept the revised document for '
                '${request.documentNo}?\n\n'
                'This will close the DMR and complete the modification process.',
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFF2E8B57),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Accept Revision',
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
      final user =
          DccSession.currentUser;

      if (user == null) {
        throw Exception(
          'DCC session not found.',
        );
      }

      await DccDmrService
          .acceptRevisedDocument(
        request,
        user.name,
      );

      await DccNotificationService
          .addNotification(
        DccNotification(
          id:
          'DMR_REVISION_ACCEPTED_${request.id}',
          recipientEmail:
          request.requestedByEmail,
          title:
          'Revised Document Accepted',
          message:
          '${request.documentNo} has been accepted by DCC. '
              'The DMR has been completed.',
          type:
          'DMR_REVISION_ACCEPTED',
          documentNo:
          request.documentNo,
          createdAt:
          DateTime.now(),
        ),
      );

      await DccActivityService.addActivity(
        DccActivity(
          id: DateTime.now()
              .microsecondsSinceEpoch
              .toString(),
          userEmail: user.email,
          userName: user.name,
          action:
          'DMR_REVISION_ACCEPTED',
          description:
          'Accepted revised document for ${request.documentNo} and completed the DMR.',
          documentNo:
          request.documentNo,
          timestamp:
          DateTime.now(),
        ),
      );

      if (!mounted) {
        return;
      }

      await _loadRequests(
        refresh: true,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Revised document accepted. DMR completed.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to accept revised document: $e',
          ),
        ),
      );
    }
  }
  Future<void> _approveRequest(
      DccDmrRequest request,
      ) async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Approve DMR',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Approve the modification request for '
                '${request.documentNo}?\n\n'
                'This will grant the user permission to modify the document.',
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
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Approve',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (_selectedSourceFile == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select and upload the source file before granting edit access.',
          ),
        ),
      );

      return;
    }

    try {
      final user =
          DccSession.currentUser;

      if (user == null) {
        throw Exception(
          'DCC session not found.',
        );
      }

      final updatedRequest =
      DccDmrRequest(
        id: request.id,
        documentId:
        request.documentId,
        documentNo:
        request.documentNo,
        documentName:
        request.documentName,
        documentType:
        request.documentType,
        department:
        request.department,
        requestedByName:
        request.requestedByName,
        requestedByEmail:
        request.requestedByEmail,
        hodName:
        request.hodName,
        hodEmail:
        request.hodEmail,
        currentRevision:
        request.currentRevision,
        requestReason:
        request.requestReason,
        status:
        'EDIT_ACCESS_GRANTED',
        rejectionReason: '',
        createdDate:
        request.createdDate,
        hodActionDate:
        request.hodActionDate,
        dccActionDate:
        DateTime.now()
            .toIso8601String(),
        modificationAccessGranted:
        true,
      );

      await DccDmrService.updateRequest(
        updatedRequest,
      );

      await DccNotificationService
          .addNotification(
        DccNotification(
          id:
          'DMR_DCC_APPROVED_${request.id}',
          recipientEmail:
          request.requestedByEmail,
          title:
          'DMR Approved by DCC',
          message:
          '${request.documentNo} has been approved by DCC. '
              'You can now modify the document.',
          type:
          'DMR_DCC_APPROVED',
          documentNo:
          request.documentNo,
          createdAt:
          DateTime.now(),
        ),
      );

      await DccActivityService.addActivity(
        DccActivity(
          id: DateTime.now()
              .microsecondsSinceEpoch
              .toString(),
          userEmail:
          user.email,
          userName:
          user.name,
          action:
          'DMR_APPROVED',
          description:
          'Approved DMR for ${request.documentNo} and granted edit access.',
          documentNo:
          request.documentNo,
          timestamp:
          DateTime.now(),
        ),
      );

      if (!mounted) {
        return;
      }

      await _loadRequests(
        refresh: true,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'DMR approved. User has been granted edit access.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to approve DMR: $e',
          ),
        ),
      );
    }
  }

  Future<void> _rejectRequest(
      DccDmrRequest request,
      ) async {
    final reasonController =
    TextEditingController();

    final reason =
    await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Reject DMR',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SizedBox(
            width: 500,
            child: TextField(
              controller:
              reasonController,
              maxLines: 5,
              decoration:
              const InputDecoration(
                labelText:
                'Rejection reason *',
                hintText:
                'Enter the reason for rejecting this modification request.',
                border:
                OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
              const Text('Cancel'),
            ),
            ElevatedButton(
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(
                  0xFFD64545,
                ),
                foregroundColor:
                Colors.white,
              ),
              onPressed: () {
                final value =
                reasonController
                    .text
                    .trim();

                if (value.isEmpty) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Rejection reason is required.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  value,
                );
              },
              child:
              const Text('Reject'),
            ),
          ],
        );
      },
    );

    reasonController.dispose();

    if (reason == null ||
        reason.trim().isEmpty) {
      return;
    }

    try {
      final user =
          DccSession.currentUser;

      if (user == null) {
        throw Exception(
          'DCC session not found.',
        );
      }

      final updatedRequest =
      DccDmrRequest(
        id: request.id,
        documentId:
        request.documentId,
        documentNo:
        request.documentNo,
        documentName:
        request.documentName,
        documentType:
        request.documentType,
        department:
        request.department,
        requestedByName:
        request.requestedByName,
        requestedByEmail:
        request.requestedByEmail,
        hodName:
        request.hodName,
        hodEmail:
        request.hodEmail,
        currentRevision:
        request.currentRevision,
        requestReason:
        request.requestReason,
        status:
        'REJECTED',
        rejectionReason:
        reason.trim(),
        createdDate:
        request.createdDate,
        hodActionDate:
        request.hodActionDate,
        dccActionDate:
        DateTime.now()
            .toIso8601String(),
        modificationAccessGranted:
        false,
      );

      await DccDmrService.updateRequest(
        updatedRequest,
      );

      await DccNotificationService
          .addNotification(
        DccNotification(
          id:
          'DMR_DCC_REJECTED_${request.id}',
          recipientEmail:
          request.requestedByEmail,
          title:
          'DMR Rejected by DCC',
          message:
          '${request.documentNo} was rejected by DCC. '
              'Reason: ${reason.trim()}',
          type:
          'DMR_DCC_REJECTED',
          documentNo:
          request.documentNo,
          createdAt:
          DateTime.now(),
        ),
      );

      await DccActivityService.addActivity(
        DccActivity(
          id: DateTime.now()
              .microsecondsSinceEpoch
              .toString(),
          userEmail:
          user.email,
          userName:
          user.name,
          action:
          'DMR_REJECTED',
          description:
          'Rejected DMR for ${request.documentNo}. Reason: ${reason.trim()}',
          documentNo:
          request.documentNo,
          timestamp:
          DateTime.now(),
        ),
      );

      if (!mounted) {
        return;
      }

      await _loadRequests(
        refresh: true,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'DMR rejected. User has been notified.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to reject DMR: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final requests =
        _filteredRequests;

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'DMR Requests',
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
                'Document Modification Requests',
                style: TextStyle(
                  fontSize: 27,
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
                '${_requests.length} request(s) waiting for DCC action.',
                style: const TextStyle(
                  fontSize: 14,
                  color:
                  Color(0xFF6B7280),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              TextField(
                controller:
                _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchText =
                        value;
                  });
                },
                decoration:
                InputDecoration(
                  hintText:
                  'Search document, requester or reason...',
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
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              if (requests.isEmpty)
                _buildEmptyState()
              else
                ...requests.map(
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
                  .check_circle_outline,
              size: 52,
              color:
              Color(0xFF9AA2B1),
            ),
            SizedBox(
              height: 12,
            ),
            Text(
              'No pending DMR requests',
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
              'New DMR requests will appear here.',
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
        bottom: 16,
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
                width: 50,
                height: 50,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFF2E8FF,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    13,
                  ),
                ),
                child: const Icon(
                  Icons.edit_document,
                  color:
                  Color(0xFF9C27B0),
                ),
              ),
              const SizedBox(
                width: 14,
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
                const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: request.status ==
                      'PENDING_DCC_REVIEW'
                      ? const Color(0xFFFFF4E5)
                      : const Color(0xFFE8F1FF),
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: Text(
                  request.status ==
                      'PENDING_DCC_REVIEW'
                      ? 'REVISED FILE REVIEW'
                      : 'PENDING DCC',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w800,
                    color: request.status ==
                        'PENDING_DCC_REVIEW'
                        ? const Color(0xFFD97706)
                        : const Color(0xFF3155D9),
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
                'Requester',
                request.requestedByName,
              ),
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
                'HOD',
                request.hodName,
              ),
            ],
          ),
          const SizedBox(
            height: 18,
          ),
          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.all(14),
            decoration:
            BoxDecoration(
              color:
              const Color(0xFFF8F9FC),
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
                  'Modification Reason',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(
                  height: 6,
                ),
                Text(
                  request.requestReason,
                  style:
                  const TextStyle(
                    fontSize: 13,
                    color:
                    Color(0xFF172033),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 18,
          ),

          if (request.status == 'PENDING_DCC_REVIEW')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F8FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD8E7FA),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Revised Document Submitted',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF172033),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    request.revisedFileName.isEmpty
                        ? 'Revised file unavailable'
                        : request.revisedFileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () =>
                            _openRevisedFile(request),
                        icon: const Icon(
                          Icons.visibility_outlined,
                          size: 17,
                        ),
                        label: const Text(
                          'View Revised File',
                        ),
                      ),

                      const SizedBox(width: 10),

                      OutlinedButton.icon(
                        onPressed: () =>
                            _downloadRevisedFile(request),
                        icon: const Icon(
                          Icons.download_outlined,
                          size: 17,
                        ),
                        label: const Text(
                          'Download Revised',
                        ),
                      ),

                      const Spacer(),

                      OutlinedButton.icon(
                        onPressed: () =>
                            _rejectRevisedDocument(request),
                        icon: const Icon(
                          Icons.cancel_outlined,
                          size: 17,
                        ),
                        label: const Text(
                          'Reject Revision',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                          const Color(0xFFD64545),
                          side: const BorderSide(
                            color: Color(0xFFD64545),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      ElevatedButton.icon(
                        onPressed: () =>
                            _acceptRevisedDocument(request),
                        icon: const Icon(
                          Icons.check_circle_outline,
                          size: 17,
                        ),
                        label: const Text(
                          'Accept Revision',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFF2E8B57),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE4E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DCC Source File',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF172033),
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Upload the source file before granting edit access.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedSourceFileName.isEmpty
                              ? 'No file selected'
                              : _selectedSourceFileName,
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                            _selectedSourceFileName.isEmpty
                                ? FontWeight.w400
                                : FontWeight.w700,
                            color:
                            _selectedSourceFileName.isEmpty
                                ? const Color(0xFF9AA2B1)
                                : const Color(0xFF172033),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      OutlinedButton.icon(
                        onPressed: _isUploading
                            ? null
                            : _selectSourceFile,
                        icon: const Icon(
                          Icons.attach_file_rounded,
                          size: 17,
                        ),
                        label: Text(
                          _selectedSourceFile == null
                              ? 'Choose File'
                              : 'Change File',
                        ),
                      ),

                      if (_selectedSourceFile != null) ...[
                        const SizedBox(width: 8),

                        IconButton(
                          tooltip: 'Remove selected file',
                          onPressed: _isUploading
                              ? null
                              : _removeSelectedSourceFile,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFFD64545),
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (_selectedSourceFile != null) ...[
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isUploading
                              ? null
                              : () async {
                            await _uploadSelectedSourceFile(
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
                            Icons.cloud_upload_outlined,
                            size: 17,
                          ),
                          label: Text(
                            _isUploading
                                ? 'Uploading...'
                                : 'Upload Source File',
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

          if (request.status != 'PENDING_DCC_REVIEW') ...[
            const SizedBox(
              height: 18,
            ),

            Row(
              mainAxisAlignment:
              MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      _rejectRequest(request),
                  icon: const Icon(
                    Icons.cancel_outlined,
                  ),
                  label: const Text(
                    'Reject',
                  ),
                  style:
                  OutlinedButton.styleFrom(
                    foregroundColor:
                    const Color(0xFFD64545),
                    side: const BorderSide(
                      color: Color(0xFFD64545),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                ElevatedButton.icon(
                  onPressed:
                  (!_sourceFileUploaded ||
                      _isUploading)
                      ? null
                      : () =>
                      _approveRequest(
                        request,
                      ),
                  icon: const Icon(
                    Icons.lock_open_outlined,
                  ),
                  label: Text(
                    _sourceFileUploaded
                        ? 'Grant Edit Access'
                        : 'Upload Source First',
                  ),
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF2E8B57),
                    foregroundColor:
                    Colors.white,
                  ),
                ),
              ],
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