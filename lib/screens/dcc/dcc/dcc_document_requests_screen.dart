import 'package:flutter/material.dart';

import '../../../models/dcc/dcc_document_request.dart';
import '../../../models/dcc/dcc_master_data.dart';
import '../../../services/dcc/dcc_document_request_service.dart';
import '../../../services/dcc/dcc_master_data_service.dart';
import '../../../services/dcc/dcc_notification_service.dart';
import '../../../services/dcc/dcc_session.dart';
import '../../../models/dcc/dcc_activity.dart';
import '../../../services/dcc/dcc_activity_service.dart';


class DccDocumentRequestsScreen
    extends StatefulWidget {
  const DccDocumentRequestsScreen({
    super.key,
  });

  @override
  State<DccDocumentRequestsScreen> createState() =>
      _DccDocumentRequestsScreenState();
}

class _DccDocumentRequestsScreenState
    extends State<DccDocumentRequestsScreen> {
  late Future<List<DccDocumentRequest>>
  _requestsFuture;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    _requestsFuture =
        DccDocumentRequestService
            .getPendingRequests();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadRequests();
    });

    await _requestsFuture;
  }

  void _openRequest(
      DccDocumentRequest request,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DccDocumentRequestDetailScreen(
              request: request,
            ),
      ),
    ).then((_) {
      _refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Document Requests',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FutureBuilder<
          List<DccDocumentRequest>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load requests\n'
                    '${snapshot.error}',
              ),
            );
          }

          final requests =
              snapshot.data ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                'No pending document requests.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                24,
                20,
                24,
                24,
              ),
              itemCount: requests.length,
              itemBuilder:
                  (context, index) {
                final request =
                requests[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openRequest(request),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.description_outlined,
                              color: Colors.blue.shade700,
                              size: 24,
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.documentName,
                                  maxLines: 2,
                                  overflow:
                                  TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 16,
                                      color:
                                      Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        request.userName,
                                        overflow:
                                        TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color:
                                          Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 4),

                                Row(
                                  children: [
                                    Icon(
                                      Icons.email_outlined,
                                      size: 16,
                                      color:
                                      Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        request.userEmail,
                                        overflow:
                                        TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color:
                                          Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          Container(
                            padding:
                            const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius:
                              BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Pending',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 12,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
class DccDocumentRequestDetailScreen
    extends StatefulWidget {
  final DccDocumentRequest request;

  const DccDocumentRequestDetailScreen({
    super.key,
    required this.request,
  });

  @override
  State<DccDocumentRequestDetailScreen>
  createState() =>
      _DccDocumentRequestDetailScreenState();
}

class _DccDocumentRequestDetailScreenState
    extends State<DccDocumentRequestDetailScreen> {
  late final TextEditingController
  _documentNameController;

  late final TextEditingController
  _documentNoController;

  late final TextEditingController
  _documentTypeController;

  late final TextEditingController
  _departmentController;

  late final TextEditingController
  _candidateNameController;

  late final TextEditingController
  _candidateEmailController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final request = widget.request;

    _documentNameController =
        TextEditingController(
          text: request.documentName,
        );

    _documentNoController =
        TextEditingController(
          text: request.documentNo ?? '',
        );

    _documentTypeController =
        TextEditingController(
          text: request.documentType ?? '',
        );

    _departmentController =
        TextEditingController(
          text: request.department ?? '',
        );

    _candidateNameController =
        TextEditingController(
          text: request.candidateName ??
              request.userName,
        );

    _candidateEmailController =
        TextEditingController(
          text: request.candidateEmail ??
              request.userEmail,
        );
  }

  @override
  void dispose() {
    _documentNameController.dispose();
    _documentNoController.dispose();
    _documentTypeController.dispose();
    _departmentController.dispose();
    _candidateNameController.dispose();
    _candidateEmailController.dispose();
    super.dispose();
  }

  Future<void> _saveAndNotify() async {
    if (_documentNoController.text.trim().isEmpty) {
      _showError('Enter document number');
      return;
    }

    if (_documentNameController.text.trim().isEmpty) {
      _showError('Enter document name');
      return;
    }

    if (_documentTypeController.text.trim().isEmpty) {
      _showError('Enter document type');
      return;
    }

    if (_departmentController.text.trim().isEmpty) {
      _showError('Enter department');
      return;
    }

    if (_candidateNameController.text.trim().isEmpty) {
      _showError('Enter candidate name');
      return;
    }

    if (_candidateEmailController.text.trim().isEmpty) {
      _showError('Enter candidate email');
      return;
    }

    setState(() => _saving = true);

    try {
      final currentUser = DccSession.currentUser;

      final documentNo = _documentNoController.text.trim();
      final documentName = _documentNameController.text.trim();
      final documentType = _documentTypeController.text.trim();
      final department = _departmentController.text.trim();
      final candidateName = _candidateNameController.text.trim();
      final candidateEmail =
      _candidateEmailController.text.trim().toLowerCase();

      // 1. Save DCC details.
      await DccDocumentRequestService.updateDccDetails(
        requestId: widget.request.id,
        documentNo: documentNo,
        documentName: documentName,
        documentType: documentType,
        department: department,
        candidateName: candidateName,
        candidateEmail: candidateEmail,
      );

      // 2. Save/update Master Data.
      final existingMaster =
      await DccMasterDataService.getByDocumentNo(documentNo);

      await DccMasterDataService.upsertEntry(
        DccMasterData(
          documentNo: documentNo,
          documentName: documentName,
          documentType: documentType,
          department: department,
          candidateName: candidateName,
          candidateEmail: candidateEmail,
          createdByName: currentUser?.name ?? '',
          createdByEmail: currentUser?.email ?? '',
          revision: existingMaster?.revision ?? 0,
        ),
        manualRevision: existingMaster == null ? 0 : null,
      );

      // 3. Notify the requesting USER.
      bool notificationSent = true;

      try {
        await DccNotificationService.createDocumentUploadNotification(
          userEmail: candidateEmail,
          documentRequestId: widget.request.id,
          documentName: documentName,
        );

        // Mark as notified only after notification succeeds.
        await DccDocumentRequestService.markAsNotified(
          widget.request.id,
        );
      } catch (e) {
        notificationSent = false;
        debugPrint('Document upload notification failed: $e');
      }

      // 4. Record DCC activity independently.
      bool activitySaved = true;

      try {
        await DccActivityService.addActivity(
          DccActivity(
            id: 'DOC_REQUEST_PROCESSED_${DateTime.now().microsecondsSinceEpoch}',
            userEmail: currentUser?.email ?? '',
            userName: currentUser?.name ?? '',
            action: 'DOCUMENT_REQUEST_PROCESSED',
            description:
            'Processed the document request for "$documentName" '
                '(Document No: $documentNo).',
            documentNo: documentNo,
            timestamp: DateTime.now(),
          ),
        );
      } catch (e) {
        activitySaved = false;
        debugPrint('DCC document request activity failed: $e');
      }

      if (!mounted) return;

      String message = 'Document details and Master Data saved successfully.';

      if (!notificationSent && !activitySaved) {
        message += ' User notification and recent activity failed.';
      } else if (!notificationSent) {
        message += ' User notification failed.';
      } else if (!activitySaved) {
        message += ' Recent activity failed.';
      } else {
        message += ' User notified successfully.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
          notificationSent && activitySaved ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      _showError('Failed to save document details: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  InputDecoration _decoration(
      String label,
      ) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _field(
      TextEditingController controller,
      String label, {
        bool readOnly = false,
      }) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration:
        _decoration(label),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE4E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Review Document Request',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Review Document Request',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF172033),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Requested by ${widget.request.userName}.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 25),

                _sectionCard(
                  title: 'User Request',
                  subtitle:
                      'What the user asked for.',
                  children: [
                    Text(
                      widget.request.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF172033),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _sectionCard(
                  title: 'Master Data Details',
                  subtitle:
                      'Fill these in before saving — they become '
                      'the canonical Master Data entry for this '
                      'document.',
                  children: [
                    _field(
                      _documentNoController,
                      'Document No',
                    ),
                    _field(
                      _documentNameController,
                      'Document Name',
                    ),
                    _field(
                      _documentTypeController,
                      'Document Type',
                    ),
                    _field(
                      _departmentController,
                      'Department',
                    ),
                    _field(
                      _candidateNameController,
                      'Candidate Name',
                    ),
                    _field(
                      _candidateEmailController,
                      'Candidate Email',
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed:
                    _saving
                        ? null
                        : _saveAndNotify,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.notifications_active_rounded,
                          ),
                    label: Text(
                      _saving
                          ? 'Saving...'
                          : 'Save & Notify User',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3155D9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}