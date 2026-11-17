import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/dcc/dcc_document.dart';
import '../../../models/dcc/dcc_activity.dart';

import '../../../services/dcc/dcc_activity_service.dart';
import '../../../services/dcc/dcc_notification_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../models/dcc/dcc_notification.dart';
import '../../../services/dcc/dcc_document_service.dart';
import '../../../services/dcc/dcc_session.dart';
import '../../../services/dcc/dcc_storage_service.dart';
class DccDocumentReviewScreen
    extends StatefulWidget {
  final DccDocument document;

  const DccDocumentReviewScreen({
    super.key,
    required this.document,
  });

  @override
  State<DccDocumentReviewScreen> createState() =>
      _DccDocumentReviewScreenState();
}

class _DccDocumentReviewScreenState
    extends State<DccDocumentReviewScreen> {

  DccDocument get document => widget.document;

  late final TextEditingController _revisionController;
  late final TextEditingController _revisionDateController;

  PlatformFile? _convertedPdfFile;

  bool _isProcessing = false;
  Future<void> _pickConvertedPdf() async {
    try {
      final result =
      await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null ||
          result.files.isEmpty) {
        return;
      }

      final selectedFile =
          result.files.single;

      final bytes = selectedFile.bytes;

      if (bytes == null || bytes.isEmpty) {
        throw Exception(
          'The selected PDF could not be read.',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _convertedPdfFile = selectedFile;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF selected: ${selectedFile.name}',
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
            'Unable to select PDF: $e',
          ),
        ),
      );
    }
  }
  Future<void> _releaseDocument() async {
    final user = DccSession.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'DCC session not found. Please login again.',
          ),
        ),
      );
      return;
    }

    final revisionText =
    _revisionController.text.trim();

    final revision =
    int.tryParse(revisionText);

    if (revision == null ||
        revision <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid Rev No.',
          ),
        ),
      );
      return;
    }

    final revisionDate =
    _revisionDateController.text.trim();

    if (revisionDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a Rev Date.',
          ),
        ),
      );
      return;
    }

    if (_convertedPdfFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please upload the converted PDF before releasing.',
          ),
        ),
      );
      return;
    }

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Release Document',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Release ${document.documentNo} as Rev $revision?\n\n'
                'Once released, this document will become a controlled document.',
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
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFF2E8B57),
                foregroundColor:
                Colors.white,
              ),
              child: const Text(
                'Release',
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
      final pdfBytes =
          _convertedPdfFile?.bytes;

      if (pdfBytes == null ||
          pdfBytes.isEmpty) {
        throw Exception(
          'The selected PDF could not be read.',
        );
      }

      final originalName =
          _convertedPdfFile!.name;

      final releasedPdfName =
          '${document.documentNo}_Rev${revision}_'
          '${originalName.replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      )}';

      final releasedPdfPath =
      await DccStorageService.uploadConvertedPdf(
        fileBytes: pdfBytes,
        documentId: document.id,
        revision: revision,
        originalFileName: releasedPdfName,
      );

      final updatedDocument =
      DccDocument(
        id: document.id,
        documentNo: document.documentNo,
        documentName: document.documentName,
        documentType: document.documentType,
        department: document.department,
        candidateName: document.candidateName,
        employeeId: document.employeeId,

        attachmentPath:
        document.attachmentPath,
        attachmentName:
        document.attachmentName,

        createdByName:
        document.createdByName,
        createdByEmail:
        document.createdByEmail,

        hodName:
        document.hodName,
        hodEmail:
        document.hodEmail,

        status: 'RELEASED',

        revision: revision,
        revisionDate: revisionDate,

        releasedPdfPath:
        releasedPdfPath,

        releasedPdfName:
        releasedPdfName,

        releasedByName:
        user.name,
        releasedByEmail:
        user.email,

        rejectionReason: '',
      );

      await DccDocumentService.updateDocument(
        updatedDocument,
      );

      await DccActivityService.addActivity(
        DccActivity(
          id: DateTime.now()
              .microsecondsSinceEpoch
              .toString(),
          userEmail: user.email,
          userName: user.name,
          action: 'DOCUMENT_RELEASED',
          description:
          'Released ${document.documentNo} as Rev $revision',
          documentNo:
          document.documentNo,
          timestamp:
          DateTime.now(),
        ),
      );

      await DccNotificationService.addNotification(
        DccNotification(
          id:
          'DOCUMENT_RELEASED_${document.id}_${DateTime.now().microsecondsSinceEpoch}',
          recipientEmail:
          document.createdByEmail,
          title:
          'Document Released',
          message:
          '${document.documentNo} Rev $revision has been released by DCC.',
          type:
          'DOCUMENT_RELEASED',
          documentNo:
          document.documentNo,
          createdAt:
          DateTime.now(),
        ),
      );

      if (!mounted) {
        return;
      }

      await showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF2E8B57),
                ),
                SizedBox(width: 10),
                Text(
                  'Document Released',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ],
            ),
            content: Text(
              '${document.documentNo} Rev $revision has been successfully released as a controlled document.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                child: const Text(
                  'OK',
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to release document: $e',
          ),
          duration:
          const Duration(seconds: 5),
        ),
      );
    }
  }
  @override
  void initState() {
    super.initState();

    _revisionController =
        TextEditingController(
          text: document.revision.toString(),
        );

    _revisionDateController =
        TextEditingController(
          text: document.revisionDate,
        );
  }

  @override
  void dispose() {
    _revisionController.dispose();
    _revisionDateController.dispose();
    super.dispose();
  }
  Future<void> _rejectDocument() async {
    final reasonController =
    TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.cancel_outlined,
                color: Color(0xFFD64545),
              ),
              SizedBox(width: 10),
              Text(
                'Reject Document',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: TextField(
              controller: reasonController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Rejection reason *',
                hintText:
                'Enter the reason for rejecting this document.',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFFD64545),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final value =
                reasonController.text.trim();

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
              child: const Text('Reject Document'),
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

    setState(() {
      _isProcessing = true;
    });

    try {
      final user =
          DccSession.currentUser;

      if (user == null) {
        throw Exception(
          'DCC session not found.',
        );
      }

      final updatedDocument = DccDocument(
        id: document.id,
        documentNo: document.documentNo,
        documentName: document.documentName,
        documentType: document.documentType,
        department: document.department,
        candidateName:
        document.candidateName,
        employeeId:
        document.employeeId,
        attachmentPath:
        document.attachmentPath,
        attachmentName:
        document.attachmentName,
        createdByName:
        document.createdByName,
        createdByEmail:
        document.createdByEmail,
        hodName: document.hodName,
        hodEmail: document.hodEmail,
        status: 'REJECTED',
        revision: document.revision,
        revisionDate:
        document.revisionDate,
        rejectionReason:
        reason.trim(),
      );

      await DccDocumentService.updateDocument(
        updatedDocument,
      );

      await DccActivityService.addActivity(
        DccActivity(
          id: DateTime.now()
              .microsecondsSinceEpoch
              .toString(),
          userEmail: user.email,
          userName: user.name,
          action: 'DOCUMENT_REJECTED',
          description:
          'Rejected ${document.documentNo}. Reason: ${reason.trim()}',
          documentNo:
          document.documentNo,
          timestamp:
          DateTime.now(),
        ),
      );

      await DccNotificationService.addNotification(
        DccNotification(
          id:
          'DOCUMENT_REJECTED_${document.id}_${DateTime.now().microsecondsSinceEpoch}',
          recipientEmail:
          document.createdByEmail,
          title:
          'Document Rejected by DCC',
          message:
          '${document.documentNo} was rejected by DCC. Reason: ${reason.trim()}',
          type:
          'DOCUMENT_REJECTED',
          documentNo:
          document.documentNo,
          createdAt:
          DateTime.now(),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = false;
      });

      await showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.cancel_rounded,
                  color: Color(0xFFD64545),
                ),
                SizedBox(width: 10),
                Text(
                  'Document Rejected',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ],
            ),
            content: Text(
              '${document.documentNo} has been rejected.\n\nReason: ${reason.trim()}',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to reject document: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'DCC Document Review',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor:
        Colors.white,
        foregroundColor:
        const Color(0xFF172033),
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding:
        const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _buildHeader(),

            const SizedBox(
              height: 25,
            ),

            _buildDocumentDetails(),

            const SizedBox(
              height: 25,
            ),

            _buildFileSection(),

            const SizedBox(
              height: 25,
            ),

            _buildActionSection(
              context,
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _downloadSourceFile() async {
    try {
      final storagePath =
      document.attachmentPath.trim();

      if (storagePath.isEmpty) {
        throw Exception(
          'Source file is not available.',
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
  Future<void> _viewSourceFile() async {
    try {
      final storagePath =
      document.attachmentPath.trim();

      if (storagePath.isEmpty) {
        throw Exception(
          'Source file is not available.',
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

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Opening ${document.attachmentName}',
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
            'Unable to open source file: $e',
          ),
        ),
      );
    }
  }
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(24),
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
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration:
            BoxDecoration(
              color:
              const Color(0xFFEFF3FF),
              borderRadius:
              BorderRadius.circular(
                15,
              ),
            ),
            child: const Icon(
              Icons
                  .fact_check_outlined,
              color:
              Color(0xFF3155D9),
              size: 30,
            ),
          ),

          const SizedBox(
            width: 18,
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
                    fontSize: 22,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Color(
                      0xFF172033,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  document.documentName,
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

          Container(
            padding:
            const EdgeInsets
                .symmetric(
              horizontal: 14,
              vertical: 8,
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
              style:
              TextStyle(
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
        ],
      ),
    );
  }

  Widget _buildDocumentDetails() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(24),
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
          const Text(
            'Document Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.w800,
              color:
              Color(0xFF172033),
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          _detailRow(
            'Document Number',
            document.documentNo,
          ),

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
            'Revision',
            document.revision.toString(),
          ),

          _detailRow(
            'Submitted By',
            document.createdByName,
          ),

          _detailRow(
            'HOD',
            document.hodName,
          ),

          _detailRow(
            'Revision Date',
            document.revisionDate,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
      String label,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 9,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style:
              const TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w700,
                color:
                Color(0xFF6B7280),
              ),
            ),
          ),

          const SizedBox(
            width: 20,
          ),

          Expanded(
            child: Text(
              value.isEmpty
                  ? '-'
                  : value,
              style:
              const TextStyle(
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

  Widget _buildFileSection() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(24),
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
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration:
            BoxDecoration(
              color:
              const Color(0xFFFFEBEE),
              borderRadius:
              BorderRadius.circular(
                13,
              ),
            ),
            child: const Icon(
              Icons
                  .picture_as_pdf_outlined,
              color:
              Color(0xFFD32F2F),
              size: 27,
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
                const Text(
                  'Source Document',
                  style:
                  TextStyle(
                    fontSize: 15,
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
                  document.attachmentName.isEmpty
                      ? 'No file name available'
                      : document.attachmentName,
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

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: _viewSourceFile,
                icon: const Icon(
                  Icons.visibility_outlined,
                ),
                label: const Text(
                  'View File',
                ),
              ),

              const SizedBox(width: 10),

              ElevatedButton.icon(
                onPressed: _downloadSourceFile,
                icon: const Icon(
                  Icons.download_outlined,
                ),
                label: const Text(
                  'Download Source',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(
      BuildContext context,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(24),
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
          const Text(
            'DCC Action',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.w800,
              color:
              Color(0xFF172033),
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          const Text(
            'Review the document before releasing it as a controlled document.',
            style: TextStyle(
              fontSize: 13,
              color:
              Color(0xFF6B7280),
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller:
                  _revisionController,
                  keyboardType:
                  TextInputType.number,
                  decoration:
                  InputDecoration(
                    labelText: 'Rev No',
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

              const SizedBox(width: 15),

              Expanded(
                child: TextField(
                  controller:
                  _revisionDateController,
                  readOnly: true,
                  decoration:
                  InputDecoration(
                    labelText: 'Rev Date',
                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        10,
                      ),
                    ),
                    suffixIcon:
                    const Icon(
                      Icons.calendar_today_outlined,
                    ),
                  ),
                  onTap: () async {
                    final selectedDate =
                    await showDatePicker(
                      context: context,
                      initialDate:
                      DateTime.now(),
                      firstDate:
                      DateTime(2000),
                      lastDate:
                      DateTime(2100),
                    );

                    if (selectedDate == null) {
                      return;
                    }

                    final day =
                    selectedDate.day
                        .toString()
                        .padLeft(2, '0');

                    final month =
                    selectedDate.month
                        .toString()
                        .padLeft(2, '0');

                    final year =
                    selectedDate.year.toString();

                    setState(() {
                      _revisionDateController
                          .text =
                      '$day.$month.$year';
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(
                0xFFF8F9FC,
              ),
              borderRadius:
              BorderRadius.circular(14),
              border: Border.all(
                color: const Color(
                  0xFFE4E8F0,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFFFEBEE,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: Color(
                      0xFFD32F2F,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Converted PDF',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                          FontWeight.w800,
                          color: Color(
                            0xFF172033,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        _convertedPdfFile == null
                            ? 'No converted PDF uploaded.'
                            : _convertedPdfFile!.name,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(
                            0xFF6B7280,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 15),

                OutlinedButton.icon(
                  onPressed: _pickConvertedPdf,
                  icon: const Icon(
                    Icons.upload_file_outlined,
                  ),
                  label: Text(
                    _convertedPdfFile == null
                        ? 'Upload PDF'
                        : 'Change PDF',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : _rejectDocument,
                  icon: _isProcessing
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(
                    Icons.cancel_outlined,
                  ),
                  label: const Text(
                    'Reject',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                    const Color(0xFFD64545),
                    side: const BorderSide(
                      color: Color(0xFFD64545),
                    ),
                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 15,
              ),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : _releaseDocument,
                  icon: const Icon(
                    Icons.verified_outlined,
                  ),
                  label: const Text(
                    'Release Document',
                  ),
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF2E8B57),
                    foregroundColor:
                    Colors.white,
                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}