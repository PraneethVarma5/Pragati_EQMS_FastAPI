import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/dcc/dcc_activity.dart';
import '../../../models/dcc/dcc_document.dart';
import '../../../models/dcc/dcc_notification.dart';

import '../../../services/dcc/dcc_activity_service.dart';
import '../../../services/dcc/dcc_document_service.dart';
import '../../../services/dcc/dcc_notification_service.dart';
import '../../../services/dcc/dcc_session.dart';
import '../../../services/dcc/dcc_storage_service.dart';

class HodDocumentReviewScreen extends StatefulWidget {
  final DccDocument document;

  const HodDocumentReviewScreen({
    super.key,
    required this.document,
  });

  @override
  State<HodDocumentReviewScreen> createState() =>
      _HodDocumentReviewScreenState();
}

class _HodDocumentReviewScreenState
    extends State<HodDocumentReviewScreen> {
  bool _isProcessing = false;
  bool _isOpening = false;

  static const List<String> _dccEmails = [
    'officer@eqms.com',
  ];

  DccDocument get document => widget.document;

  Future<void> _openAttachment() async {
    if (_isOpening) {
      return;
    }

    final storagePath =
    document.attachmentPath.trim();

    if (storagePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No document attachment is available.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isOpening = true;
    });

    try {
      final url =
      await DccStorageService.createSignedUrl(
        storagePath,
        expiresIn: 3600,
      );

      final uri = Uri.parse(url);

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );

      if (!launched) {
        throw Exception(
          'The browser could not open the document.',
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
            'Unable to open attachment: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOpening = false;
        });
      }
    }
  }

  Future<void> _approveDocument() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF2E8B57),
              ),
              SizedBox(width: 10),
              Text(
                'Approve Document',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          content: Text(
            'Approve ${document.documentNo} and send it to DCC for document control?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFF2E8B57),
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _processApproval();
  }

  Future<void> _processApproval() async {
    final user = DccSession.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final updatedDocument = DccDocument(
        id: document.id,
        documentNo: document.documentNo,
        documentName: document.documentName,
        documentType: document.documentType,
        department: document.department,
        candidateName: document.candidateName,
        employeeId: document.employeeId,
        attachmentPath: document.attachmentPath,
        attachmentName: document.attachmentName,
        createdByName: document.createdByName,
        createdByEmail: document.createdByEmail,
        hodName: document.hodName,
        hodEmail: document.hodEmail,
        status: 'PENDING_DCC',
        revision: document.revision,
        revisionDate: document.revisionDate,
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
          action: 'DOCUMENT_HOD_APPROVED',
          description:
          '${document.documentNo} approved by HOD and sent to DCC',
          documentNo: document.documentNo,
          timestamp: DateTime.now(),
        ),
      );

      await DccNotificationService.addNotification(
        DccNotification(
          id:
          'DOC_HOD_APPROVED_USER_${document.id}',
          recipientEmail:
          document.createdByEmail,
          title: 'Document Approved by HOD',
          message:
          '${document.documentNo} has been approved by '
              '${user.name} and sent to DCC for review.',
          type: 'DOCUMENT_HOD_APPROVED',
          documentNo: document.documentNo,
          createdAt: DateTime.now(),
        ),
      );

      await DccNotificationService.notifyAllDcc(
        title: 'Document Ready for DCC Review',
        message:
        '${document.documentNo} was approved by '
            '${user.name} and is ready for DCC review.',
        type: 'DOCUMENT_READY_FOR_DCC',
        documentNo: document.documentNo,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = false;
      });

      await showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF2E8B57),
                ),
                SizedBox(width: 10),
                Text(
                  'Document Approved',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            content: Text(
              '${document.documentNo} has been approved and sent to DCC.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Close'),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to approve document: $e',
          ),
        ),
      );
    }
  }

  Future<void> _rejectDocument() async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
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
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Rejection reason *',
                hintText:
                'Enter the reason for rejecting this document.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value =
                controller.text.trim();

                if (value.isEmpty) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Rejection reason is required.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  context,
                  value,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFFD64545),
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
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

    await _processRejection(
      reason.trim(),
    );
  }

  Future<void> _processRejection(
      String reason,
      ) async {
    final user = DccSession.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final updatedDocument = DccDocument(
        id: document.id,
        documentNo: document.documentNo,
        documentName: document.documentName,
        documentType: document.documentType,
        department: document.department,
        candidateName: document.candidateName,
        employeeId: document.employeeId,
        attachmentPath: document.attachmentPath,
        attachmentName: document.attachmentName,
        createdByName: document.createdByName,
        createdByEmail: document.createdByEmail,
        hodName: document.hodName,
        hodEmail: document.hodEmail,
        status: 'REJECTED',
        revision: document.revision,
        revisionDate: document.revisionDate,
        rejectionReason: reason,
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
          action: 'DOCUMENT_HOD_REJECTED',
          description:
          '${document.documentNo} rejected by HOD',
          documentNo: document.documentNo,
          timestamp: DateTime.now(),
        ),
      );

      await DccNotificationService.addNotification(
        DccNotification(
          id:
          'DOC_HOD_REJECTED_USER_${document.id}',
          recipientEmail:
          document.createdByEmail,
          title: 'Document Rejected by HOD',
          message:
          '${document.documentNo} was rejected by '
              '${user.name}. Reason: $reason',
          type: 'DOCUMENT_HOD_REJECTED',
          documentNo: document.documentNo,
          createdAt: DateTime.now(),
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
        builder: (_) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFD64545),
                ),
                SizedBox(width: 10),
                Text(
                  'Document Rejected',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            content: Text(
              '${document.documentNo} has been rejected.\n\nReason:\n$reason',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Close'),
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

      ScaffoldMessenger.of(context).showSnackBar(
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
          'Document Review',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor:
        const Color(0xFF172033),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 1100,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Review Document',
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
                  'Review the submitted document before approving or rejecting it.',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                    Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 25),

                _buildDocumentInformation(),

                const SizedBox(height: 20),

                _buildAttachmentCard(),

                const SizedBox(height: 25),

                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
                decoration: BoxDecoration(
                  color:
                  const Color(0xFFEFF3FF),
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color:
                  Color(0xFF3155D9),
                  size: 28,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.documentNo,
                      style:
                      const TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.w800,
                        color:
                        Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      document.documentName,
                      style:
                      const TextStyle(
                        fontSize: 13,
                        color:
                        Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              _statusChip(
                document.status,
              ),
            ],
          ),

          const SizedBox(height: 25),

          const Divider(),

          const SizedBox(height: 20),

          Wrap(
            spacing: 45,
            runSpacing: 22,
            children: [
              _info(
                'Document No',
                document.documentNo,
              ),
              _info(
                'Document Name',
                document.documentName,
              ),
              _info(
                'Document Type',
                document.documentType,
              ),
              _info(
                'Department',
                document.department,
              ),
              _info(
                'Revision',
                document.revision.toString(),
              ),
              _info(
                'Revision Date',
                document.revisionDate,
              ),
              _info(
                'Candidate Name',
                document.candidateName,
              ),
              _info(
                'Employee ID',
                document.employeeId,
              ),
              _info(
                'Submitted By',
                document.createdByName,
              ),
              _info(
                'Submitter Email',
                document.createdByEmail,
              ),
            ],
          ),

          const SizedBox(height: 25),

          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
              const Color(0xFFF8F9FC),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.account_tree_outlined,
                  size: 21,
                  color:
                  Color(0xFF6B7280),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Approval Route',
                        style:
                        TextStyle(
                          fontSize: 11,
                          fontWeight:
                          FontWeight.w700,
                          color:
                          Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${document.createdByName} → '
                            '${document.hodName} → DCC',
                        style:
                        const TextStyle(
                          fontSize: 13,
                          fontWeight:
                          FontWeight.w700,
                          color:
                          Color(0xFF172033),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
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
            decoration: BoxDecoration(
              color:
              const Color(0xFFF1F3F8),
              borderRadius:
              BorderRadius.circular(13),
            ),
            child: Icon(
              _attachmentIcon(
                document.attachmentName,
              ),
              color:
              const Color(0xFF6B7280),
              size: 27,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Uploaded Attachment',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  document.attachmentName.isEmpty
                      ? 'No attachment name available'
                      : document.attachmentName,
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color:
                    Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 15),

          OutlinedButton.icon(
            onPressed: _isOpening
                ? null
                : _openAttachment,
            icon: _isOpening
                ? const SizedBox(
              width: 17,
              height: 17,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Icon(
              Icons.open_in_new_rounded,
            ),
            label: Text(
              _isOpening
                  ? 'Opening...'
                  : 'View Attachment',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: _isProcessing
              ? null
              : _rejectDocument,
          icon: const Icon(
            Icons.close_rounded,
          ),
          label:
          const Text('Reject'),
          style:
          OutlinedButton.styleFrom(
            foregroundColor:
            const Color(0xFFD64545),
            side: const BorderSide(
              color:
              Color(0xFFD64545),
            ),
            padding:
            const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 15,
            ),
          ),
        ),

        const SizedBox(width: 12),

        ElevatedButton.icon(
          onPressed: _isProcessing
              ? null
              : _approveDocument,
          icon: _isProcessing
              ? const SizedBox(
            width: 18,
            height: 18,
            child:
            CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Icon(
            Icons.check_circle_outline,
          ),
          label: Text(
            _isProcessing
                ? 'Processing...'
                : 'Approve & Send to DCC',
          ),
          style:
          ElevatedButton.styleFrom(
            backgroundColor:
            const Color(0xFF2E8B57),
            foregroundColor:
            Colors.white,
            padding:
            const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _info(
      String label,
      String value,
      ) {
    return SizedBox(
      width: 210,
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight:
              FontWeight.w600,
              color:
              Color(0xFF9AA2B1),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value.isEmpty ? '-' : value,
            maxLines: 2,
            overflow:
            TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
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

  Widget _statusChip(String status) {
    Color color;
    Color background;
    String text;

    switch (status) {
      case 'PENDING_HOD':
        color =
        const Color(0xFFE67E00);
        background =
        const Color(0xFFFFF3DF);
        text = 'Pending HOD';
        break;

      case 'PENDING_DCC':
        color =
        const Color(0xFF3155D9);
        background =
        const Color(0xFFEFF3FF);
        text = 'Pending DCC';
        break;

      case 'REJECTED':
        color =
        const Color(0xFFD64545);
        background =
        const Color(0xFFFDECEC);
        text = 'Rejected';
        break;

      default:
        color =
        const Color(0xFF6B7280);
        background =
        const Color(0xFFF1F3F8);
        text = status;
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight:
          FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  IconData _attachmentIcon(
      String fileName,
      ) {
    final name =
    fileName.toLowerCase();

    if (name.endsWith('.doc') ||
        name.endsWith('.docx')) {
      return Icons.article_outlined;
    }

    if (name.endsWith('.xls') ||
        name.endsWith('.xlsx')) {
      return Icons.table_chart_outlined;
    }

    if (name.endsWith('.pdf')) {
      return Icons.picture_as_pdf_outlined;
    }

    return Icons.insert_drive_file_outlined;
  }
}