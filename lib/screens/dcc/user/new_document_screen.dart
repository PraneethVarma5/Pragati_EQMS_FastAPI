import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../models/dcc/dcc_document.dart';
import '../../../models/dcc/dcc_document_request.dart';
import '../../../models/dcc/dcc_activity.dart';
import '../../../models/dcc/dcc_notification.dart';

import '../../../services/dcc/dcc_document_service.dart';
import '../../../services/dcc/dcc_document_request_service.dart';
import '../../../services/dcc/dcc_storage_service.dart';
import '../../../services/dcc/dcc_session.dart';
import '../../../services/dcc/dcc_activity_service.dart';
import '../../../services/dcc/dcc_notification_service.dart';
import '../../../services/dcc/dcc_master_data_service.dart';

class NewDocumentScreen extends StatefulWidget {
  final String? documentRequestId;

  final bool restrictedUploadMode;

  const NewDocumentScreen({
    super.key,
    this.documentRequestId,
    this.restrictedUploadMode = false,
  });

  @override
  State<NewDocumentScreen> createState() =>
      _NewDocumentScreenState();
}

class _NewDocumentScreenState
    extends State<NewDocumentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _documentNoController =
  TextEditingController();

  final _documentNameController =
  TextEditingController();

  final _documentTypeController =
  TextEditingController();

  final _departmentController =
  TextEditingController();

  final _candidateNameController =
  TextEditingController();

  final _candidateEmailController =
  TextEditingController();

  final _employeeIdController =
  TextEditingController();

  final _documentNoFocusNode = FocusNode();

  PlatformFile? _selectedFile;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    _documentNoFocusNode.addListener(() {
      if (!_documentNoFocusNode.hasFocus &&
          !widget.restrictedUploadMode) {
        _autoFillFromMasterData();
      }
    });

    if (widget.restrictedUploadMode &&
        widget.documentRequestId != null) {
      _loadDocumentRequest();
    }
  }
  Future<void> _loadDocumentRequest() async {
    final requestId =
        widget.documentRequestId;

    if (requestId == null ||
        requestId.isEmpty) {
      return;
    }

    try {
      final request =
      await DccDocumentRequestService
          .getRequest(requestId);

      if (!mounted) {
        return;
      }

      if (request == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Document request could not be found.',
            ),
          ),
        );

        return;
      }

      setState(() {
        _documentNoController.text =
            request.documentNo ?? '';

        _documentNameController.text =
            request.documentName;

        _documentTypeController.text =
            request.documentType ?? '';

        _departmentController.text =
            request.department ?? '';

        _candidateNameController.text =
            request.candidateName ??
                request.userName;

        _candidateEmailController.text =
            request.candidateEmail ??
                request.userEmail;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load document request: $e',
          ),
        ),
      );
    }
  }
  Future<void> _autoFillFromMasterData() async {
    final docNo = _documentNoController.text.trim();

    if (docNo.isEmpty) return;

    try {
      final entry = await DccMasterDataService.getByDocumentNo(docNo);

      if (!mounted || entry == null) return;

      final currentUserEmail =
          DccSession.currentUser?.email.trim().toLowerCase() ?? '';

      final assignedEmail = entry.candidateEmail.trim().toLowerCase();

      // Only auto-fill for the person this document was actually
      // assigned to in Master Data — anyone else typing the same
      // document number gets no auto-fill (and a heads-up why).
      if (assignedEmail.isEmpty || assignedEmail != currentUserEmail) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This document number is assigned to a different candidate.',
            ),
          ),
        );
        return;
      }

      setState(() {
        _documentNameController.text = entry.documentName;
        _documentTypeController.text = entry.documentType;
        _departmentController.text = entry.department;
        _candidateNameController.text = entry.candidateName;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Details auto-filled from Master Data.'),
        ),
      );
    } catch (_) {
      // No master data found or lookup failed — leave the form as
      // the user filled it in manually, no error needed.
    }
  }

  @override
  void dispose() {
    _documentNoController.dispose();
    _documentNoFocusNode.dispose();
    _documentNameController.dispose();
    _documentTypeController.dispose();
    _departmentController.dispose();
    _candidateNameController.dispose();
    _candidateEmailController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final result =
    await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'docx',
        'xlsx',
        'doc',
        'xls',
      ],
      withData: true,
    );
    if (result == null ||
        result.files.isEmpty) {
      return;
    }

    final file = result.files.single;

    setState(() {
      _selectedFile = file;
    });
  }

  Future<void> _submitDocument() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please attach a Word or Excel document.',
          ),
        ),
      );

      return;
    }

    final currentUser =
        DccSession.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'User session not found. Please login again.',
          ),
        ),
      );

      return;
    }

    if (currentUser.role != 'USER') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Only Users can create new documents.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _submitting = true;
    });

    final fileBytes = _selectedFile!.bytes;

    if (fileBytes == null || fileBytes.isEmpty) {
      setState(() {
        _submitting = false;
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not read the selected file.',
          ),
        ),
      );

      return;
    }

    final documentId = DateTime.now()
        .microsecondsSinceEpoch
        .toString();

    String attachmentPath;

    try {
      attachmentPath =
      await DccStorageService.uploadSourceDocument(
        fileBytes: fileBytes,
        documentId: documentId,
        originalFileName: _selectedFile!.name,
      );
    } catch (e) {
      setState(() {
        _submitting = false;
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'File upload failed: $e',
          ),
        ),
      );

      return;
    }

    final document =
    DccDocument(
      id: documentId,

      documentNo:
      _documentNoController.text.trim(),

      documentName:
      _documentNameController.text.trim(),

      documentType:
      _documentTypeController.text.trim(),

      department:
      _departmentController.text.trim(),

      candidateName:
      _candidateNameController.text.trim(),

      employeeId:
      _employeeIdController.text.trim(),
      attachmentPath:
      attachmentPath,

      attachmentName:
      _selectedFile!.name,

      createdByName:
      currentUser.name,

      createdByEmail:
      currentUser.email,

      hodName:
      currentUser.hodName,

      hodEmail:
      currentUser.hodEmail,

      status:
      'PENDING_HOD',

      revision:
      0,

      revisionDate:
      DateFormat('dd.MM.yyyy')
          .format(DateTime.now()),
    );


    await DccDocumentService.addDocument(document);

// Mark the original DCC request as uploaded.
// This is secondary to saving the actual document.
    if (widget.restrictedUploadMode &&
        widget.documentRequestId != null &&
        widget.documentRequestId!.isNotEmpty) {
      try {
        await DccDocumentRequestService.markAsUploaded(
          widget.documentRequestId!,
        );
      } catch (e) {
        debugPrint('Document request status update failed: $e');
      }
    }

// Notify assigned HOD independently.
    bool hodNotificationFailed = false;

    try {
      await DccNotificationService.addNotification(
        DccNotification(
          id: 'DOC_HOD_SUBMITTED_${document.id}',
          recipientEmail: document.hodEmail.trim().toLowerCase(),
          title: 'New Document Approval Required',
          message:
          '${document.createdByName} submitted '
              '${document.documentNo} for your approval.',
          type: 'DOCUMENT_SUBMITTED_FOR_HOD',
          documentNo: document.documentNo,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      hodNotificationFailed = true;
      debugPrint('HOD notification failed: $e');
    }

// Record USER activity independently.
    bool activityFailed = false;

    try {
      await DccActivityService.addActivity(
        DccActivity(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          userEmail: currentUser.email,
          userName: currentUser.name,
          action: 'DOCUMENT_SUBMITTED',
          description:
          'Submitted ${document.documentNo} for HOD approval',
          documentNo: document.documentNo,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      activityFailed = true;
      debugPrint('USER document submission activity failed: $e');
    }


    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
    });

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            'Document Submitted',
          ),
          content: Text(
            '${document.documentNo} has been submitted to ${document.hodName} for HOD approval.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
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
  }

  @override
  Widget build(BuildContext context) {
    final user =
        DccSession.currentUser;

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'New Document',
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
              maxWidth: 850,
            ),

            child: Container(
              padding:
              const EdgeInsets.all(30),

              decoration:
              BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(22),
                border: Border.all(
                  color:
                  const Color(0xFFE4E8F0),
                ),
              ),

              child: Form(
                key: _formKey,

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Create New Document',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight:
                        FontWeight.w800,
                        color:
                        Color(0xFF172033),
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Enter document details and attach the original Word or Excel file.',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                        Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 28),

                    _sectionTitle(
                      'Document Details',
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller:
                            _documentNoController,
                            label:
                            'Document No',
                            hint:
                            'Enter document number',
                            icon:
                            Icons.numbers_rounded,
                            focusNode:
                            _documentNoFocusNode,
                          ),
                        ),

                        const SizedBox(width: 18),

                        Expanded(
                          child: _field(
                            controller:
                            _documentNameController,
                            label:
                            'Document Name',
                            hint:
                            'Enter document name',
                            icon:
                            Icons.description_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller:
                            _documentTypeController,
                            label:
                            'Document Type',
                            hint:
                            'Example: SOP, Manual, Procedure',
                            icon:
                            Icons.category_outlined,
                          ),
                        ),

                        const SizedBox(width: 18),

                        Expanded(
                          child: _field(
                            controller:
                            _departmentController,
                            label:
                            'Department',
                            hint:
                            'Enter department',
                            icon:
                            Icons.business_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    if (widget.restrictedUploadMode)
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              controller:
                              _candidateNameController,
                              label:
                              'User Name',
                              hint:
                              'User name',
                              icon:
                              Icons.person_outline,
                            ),
                          ),

                          const SizedBox(width: 18),

                          Expanded(
                            child: _field(
                              controller:
                              _candidateEmailController,
                              label:
                              'User Email',
                              hint:
                              'User email',
                              icon:
                              Icons.email_outlined,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              controller:
                              _candidateNameController,
                              label:
                              'Name of Candidate',
                              hint:
                              'Enter candidate name',
                              icon:
                              Icons.person_outline,
                            ),
                          ),

                          const SizedBox(width: 18),

                          Expanded(
                            child: _field(
                              controller:
                              _employeeIdController,
                              label:
                              'Employee ID',
                              hint:
                              'Enter employee ID',
                              icon:
                              Icons.badge_outlined,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 30),

                    _sectionTitle(
                      'Attachment',
                    ),

                    const SizedBox(height: 18),

                    _attachmentBox(),

                    const SizedBox(height: 30),

    if (!widget.restrictedUploadMode) ...[
    _sectionTitle(
    'Approval Details',
    ),

    const SizedBox(height: 16),

    Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
    color: const Color(0xFFF8F9FC),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
    color: const Color(0xFFE4E8F0),
    ),
    ),
    child: Row(
    children: [
    const Icon(
    Icons.supervisor_account_outlined,
    color: Color(0xFF3155D9),
    ),

    const SizedBox(width: 12),

    Expanded(
    child: Column(
    crossAxisAlignment:
    CrossAxisAlignment.start,
    children: [
    const Text(
    'Assigned HOD',
    style: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Color(0xFF7A8292),
    ),
    ),

    const SizedBox(height: 4),

    Text(
    user?.hodName.isNotEmpty == true
    ? user!.hodName
        : 'No HOD assigned',
    style: const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Color(0xFF172033),
    ),
    ),

    if (user?.hodEmail.isNotEmpty == true)
    Text(
    user!.hodEmail,
    style: const TextStyle(
    fontSize: 12,
    color: Color(0xFF6B7280),
    ),
    ),
    ],
    ),
    ),

    Container(
    padding: const EdgeInsets.symmetric(
    horizontal: 11,
    vertical: 6,
    ),
    decoration: BoxDecoration(
    color: const Color(0xFFFFF3E0),
    borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
    'PENDING HOD',
    style: TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: Color(0xFFE65100),
    ),
    ),
    ),
    ],
    ),
    ),

    const SizedBox(height: 30),
    ],

    const SizedBox(height: 30),

    SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton.icon(
    onPressed:
    _submitting
    ? null
        : _submitDocument,

    icon:
    _submitting
    ? const SizedBox(
    width: 18,
    height: 18,
    child:
    CircularProgressIndicator(
    strokeWidth: 2,
    color: Colors.white,
    ),
    )
        : Icon(
    widget.restrictedUploadMode
    ? Icons.cloud_upload_rounded
        : Icons.send_rounded,
    ),

    label: Text(
    _submitting
    ? 'Uploading...'
        : widget.restrictedUploadMode
    ? 'Upload Document'
        : 'Submit for HOD Approval',
    style: const TextStyle(
    fontSize: 15,
    fontWeight:
    FontWeight.w700,
    ),
    ),

    style:
    ElevatedButton.styleFrom(
    backgroundColor:
    const Color(0xFF3155D9),
    foregroundColor:
    Colors.white,
    disabledBackgroundColor:
    const Color(0xFF9AA2B1),
    elevation: 0,
    shape:
    RoundedRectangleBorder(
    borderRadius:
    BorderRadius.circular(14),
    ),
    ),
    ),
    ),
              ]
                )
                ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(
      String title,
      ) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF172033),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF172033),
          ),
        ),

        const SizedBox(height: 7),

        TextFormField(
          controller: controller,
          focusNode: focusNode,
          readOnly:
          widget.restrictedUploadMode,
          decoration:
          _inputDecoration(
            hint,
            icon,
          ),
          validator: (value) {
            if (value == null ||
                value.trim().isEmpty) {
              return 'Required';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _attachmentBox() {
    return InkWell(
      onTap: _pickDocument,
      borderRadius:
      BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding:
        const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color:
          const Color(0xFFF8F9FC),
          borderRadius:
          BorderRadius.circular(16),
          border: Border.all(
            color:
            const Color(0xFFE4E8F0),
          ),
        ),
        child: _selectedFile == null
            ? const Column(
          children: [
            Icon(
              Icons
                  .cloud_upload_outlined,
              size: 40,
              color:
              Color(0xFF3155D9),
            ),

            SizedBox(height: 10),

            Text(
              'Upload Word or Excel Document',
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                FontWeight.w700,
                color:
                Color(0xFF172033),
              ),
            ),

            SizedBox(height: 5),

            Text(
              '.doc, .docx, .xls or .xlsx',
              style: TextStyle(
                fontSize: 12,
                color:
                Color(0xFF7A8292),
              ),
            ),
          ],
        )
            : Row(
          children: [
            const Icon(
              Icons
                  .insert_drive_file_outlined,
              size: 34,
              color:
              Color(0xFF3155D9),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                _selectedFile!.name,
                style:
                const TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  Color(0xFF172033),
                ),
              ),
            ),

            TextButton(
              onPressed:
              _pickDocument,
              child:
              const Text(
                'Change',
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      String hint,
      IconData icon,
      ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor:
      const Color(0xFFF8F9FC),
      border:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(12),
        borderSide:
        const BorderSide(
          color:
          Color(0xFFE4E8F0),
        ),
      ),
      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(12),
        borderSide:
        const BorderSide(
          color:
          Color(0xFFE4E8F0),
        ),
      ),
      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(12),
        borderSide:
        const BorderSide(
          color:
          Color(0xFF3155D9),
          width: 1.5,
        ),
      ),
    );
  }
}