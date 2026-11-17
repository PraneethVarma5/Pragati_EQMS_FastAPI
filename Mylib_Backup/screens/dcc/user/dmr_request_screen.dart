import 'package:flutter/material.dart';

import '../../../models/dcc/dcc_document.dart';
import '../../../models/dcc/dcc_dmr_request.dart';
import '../../../models/dcc/dcc_activity.dart';
import '../../../models/dcc/dcc_notification.dart';

import '../../../services/dcc/dcc_document_service.dart';
import '../../../services/dcc/dcc_dmr_service.dart';
import '../../../services/dcc/dcc_activity_service.dart';
import '../../../services/dcc/dcc_notification_service.dart';
import '../../../services/dcc/dcc_session.dart';

class DmrRequestScreen extends StatefulWidget {
  const DmrRequestScreen({super.key});

  @override
  State<DmrRequestScreen> createState() =>
      _DmrRequestScreenState();
}

class _DmrRequestScreenState
    extends State<DmrRequestScreen> {
  List<DccDocument> _releasedDocuments = [];

  DccDocument? _selectedDocument;

  String _documentSearch = '';

  final TextEditingController _searchController =
  TextEditingController();

  final TextEditingController _reasonController =
  TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadReleasedDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadReleasedDocuments() async {
    final user = DccSession.currentUser;

    if (user == null) {
      return;
    }

    try {
      final documents =
      await DccDocumentService.getDocumentsByUser(
        user.email,
      );

      final released = documents
          .where(
            (document) =>
        document.status == 'RELEASED',
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
        _releasedDocuments = released;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load released documents.',
          ),
        ),
      );
    }
  }

  Future<void> _submitRequest() async {
    final user = DccSession.currentUser;

    if (user == null) {
      return;
    }

    if (_selectedDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a document.',
          ),
        ),
      );
      return;
    }

    final reason =
    _reasonController.text.trim();

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter the modification reason.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final document = _selectedDocument!;

      final request = DccDmrRequest(
        id: DateTime.now()
            .microsecondsSinceEpoch
            .toString(),
        documentId: document.id,
        documentNo: document.documentNo,
        documentName: document.documentName,
        documentType: document.documentType,
        department: document.department,
        requestedByName: user.name,
        requestedByEmail: user.email,
        hodName: document.hodName,
        hodEmail: document.hodEmail,
        currentRevision: document.revision,
        requestReason: reason,
        status: 'PENDING_HOD',
        createdDate:
        DateTime.now().toIso8601String(),
      );

      await DccDmrService.addRequest(
        request,
      );

      await DccNotificationService.addNotification(
        DccNotification(
          id: 'DMR_${request.id}_HOD',
          recipientEmail: request.hodEmail,
          title: 'DMR Approval Required',
          message:
          '${request.requestedByName} submitted a modification request for ${request.documentNo}.',
          type: 'DMR_SUBMITTED',
          documentNo: request.documentNo,
          createdAt: DateTime.now(),
        ),
      );

      await DccActivityService.addActivity(
        DccActivity(
          id: DateTime.now()
              .microsecondsSinceEpoch
              .toString(),
          userEmail: user.email,
          userName: user.name,
          action: 'DMR_SUBMITTED',
          description:
          'Modification request submitted for ${document.documentNo}',
          documentNo: document.documentNo,
          timestamp: DateTime.now(),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      _reasonController.clear();

      await showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF2E7D32),
                ),
                SizedBox(width: 10),
                Text(
                  'Request Submitted',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            content: Text(
              'Your modification request for '
                  '${document.documentNo} has been sent '
                  'to ${document.hodName} for approval.',
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
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to submit modification request.',
          ),
        ),
      );
    }
  }
  Future<void> _createTestReleasedDocument() async {
    final user = DccSession.currentUser;

    if (user == null) {
      return;
    }

    final document = DccDocument(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      documentNo: 'TEST-SOP-001',
      documentName: 'Test Quality Procedure',
      documentType: 'SOP',
      department: 'Quality',
      candidateName: 'Test Candidate',
      employeeId: 'TEST001',
      attachmentPath: '',
      attachmentName: 'Test_Quality_Procedure.docx',
      createdByName: user.name,
      createdByEmail: user.email,
      hodName: 'Rajesh Kumar',
      hodEmail: 'rajesh@eqms.com',
      status: 'RELEASED',
      revision: 1,
      revisionDate: DateTime.now()
          .toIso8601String()
          .split('T')
          .first,
    );

    await DccDocumentService.addDocument(
      document,
    );

    await _loadReleasedDocuments();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Test released document created.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'DMR / Edit Request',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor:
        const Color(0xFF172033),
        elevation: 0,
      ),

      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 1000,
            ),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Document Modification Request',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF172033),
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Select a released document and provide the reason for modification.',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),

        const SizedBox(height: 25),

        _buildDocumentSelectionCard(),

        const SizedBox(height: 20),

        if (_selectedDocument != null)
          _buildSelectedDocumentCard(),

        if (_selectedDocument != null)
          const SizedBox(height: 20),

        if (_selectedDocument != null)
          _buildReasonCard(),

        if (_selectedDocument != null)
          const SizedBox(height: 25),

        if (_selectedDocument != null)
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed:
              _isSubmitting
                  ? null
                  : _submitRequest,
              icon: _isSubmitting
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
                Icons.send_rounded,
              ),
              label: Text(
                _isSubmitting
                    ? 'Submitting...'
                    : 'Submit DMR',
              ),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFF3155D9),
                foregroundColor:
                Colors.white,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentSelectionCard() {
    final search =
    _documentSearch.trim().toLowerCase();

    final filteredDocuments =
    _releasedDocuments.where((document) {
      return search.isEmpty ||
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
    }).toList();

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
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Released Document',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172033),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Select the document you want to request for modification.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _documentSearch = value;
              });
            },
            decoration: InputDecoration(
              hintText:
              'Search by document no, name, type or department...',
              prefixIcon: const Icon(
                Icons.search_rounded,
              ),
              suffixIcon:
              _documentSearch.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _searchController.clear();

                  setState(() {
                    _documentSearch = '';
                  });
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
                const BorderSide(
                  color: Color(0xFFE4E8F0),
                ),
              ),
              enabledBorder:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(12),
                borderSide:
                const BorderSide(
                  color: Color(0xFFE4E8F0),
                ),
              ),
              focusedBorder:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(12),
                borderSide:
                const BorderSide(
                  color: Color(0xFF3155D9),
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (_releasedDocuments.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FC),
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.folder_open_outlined,
                    size: 38,
                    color: Color(0xFF9AA2B1),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'No released documents are available.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w600,
                      color:
                      Color(0xFF6B7280),
                    ),
                  ),

                  const SizedBox(height: 14),

                  OutlinedButton.icon(
                    onPressed:
                    _createTestReleasedDocument,
                    icon: const Icon(
                      Icons.science_outlined,
                    ),
                    label: const Text(
                      'Create Test Released Document',
                    ),
                  ),
                ],
              ),
            )
          else if (filteredDocuments.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FC),
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 38,
                    color: Color(0xFF9AA2B1),
                  ),

                  SizedBox(height: 10),

                  Text(
                    'No matching documents found.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w600,
                      color:
                      Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              constraints:
              const BoxConstraints(
                maxHeight: 390,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                  const Color(0xFFE4E8F0),
                ),
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount:
                filteredDocuments.length,
                separatorBuilder:
                    (_, __) =>
                const Divider(
                  height: 1,
                ),
                itemBuilder:
                    (context, index) {
                  final document =
                  filteredDocuments[index];

                  final isSelected =
                      _selectedDocument?.id ==
                          document.id;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDocument =
                            document;
                      });
                    },
                    child: Container(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      color: isSelected
                          ? const Color(
                        0xFFEFF3FF,
                      )
                          : Colors.white,
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration:
                            BoxDecoration(
                              color: isSelected
                                  ? const Color(
                                0xFFDCE5FF,
                              )
                                  : const Color(
                                0xFFF1F3F8,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                11,
                              ),
                            ),
                            child: Icon(
                              Icons
                                  .description_outlined,
                              color: isSelected
                                  ? const Color(
                                0xFF3155D9,
                              )
                                  : const Color(
                                0xFF6B7280,
                              ),
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
                                  document
                                      .documentNo,
                                  style:
                                  const TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                    FontWeight
                                        .w800,
                                    color: Color(
                                      0xFF172033,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  document
                                      .documentName,
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow
                                      .ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(
                                      0xFF4B5563,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  '${document.documentType}  •  '
                                      '${document.department}  •  '
                                      'Rev ${document.revision}',
                                  style:
                                  const TextStyle(
                                    fontSize: 11,
                                    color: Color(
                                      0xFF8A93A3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (isSelected)
                            const Icon(
                              Icons
                                  .check_circle_rounded,
                              color: Color(
                                0xFF3155D9,
                              ),
                            )
                          else
                            const Icon(
                              Icons
                                  .chevron_right_rounded,
                              color: Color(
                                0xFF9AA2B1,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          if (_releasedDocuments.isNotEmpty)
            Padding(
              padding:
              const EdgeInsets.only(
                top: 10,
              ),
              child: Text(
                '${filteredDocuments.length} of '
                    '${_releasedDocuments.length} documents',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8A93A3),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedDocumentCard() {
    final document = _selectedDocument!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3FF),
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD8E0FF),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected Document',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3155D9),
            ),
          ),

          const SizedBox(height: 16),

          _infoRow(
            'Document No',
            document.documentNo,
          ),

          _infoRow(
            'Document Name',
            document.documentName,
          ),

          _infoRow(
            'Document Type',
            document.documentType,
          ),

          _infoRow(
            'Department',
            document.department,
          ),

          _infoRow(
            'Current Revision',
            document.revision.toString(),
          ),

          _infoRow(
            'Revision Date',
            document.revisionDate,
          ),
        ],
      ),
    );
  }

  Widget _buildReasonCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE4E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Modification Reason',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172033),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Explain why this document needs to be modified.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: _reasonController,
            minLines: 5,
            maxLines: 8,
            maxLength: 500,
            decoration: InputDecoration(
              hintText:
              'Enter modification reason...',
              alignLabelWithHint: true,
              border:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
      String label,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w700,
                color: Color(0xFF6B7280),
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
                color: Color(0xFF172033),
              ),
            ),
          ),
        ],
      ),
    );
  }
}