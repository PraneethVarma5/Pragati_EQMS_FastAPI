import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/ccr/ccr_case.dart';
import '../../services/ccr/ccr_api_client.dart';
import '../../services/ccr/ccr_service.dart';

class CcrClosureScreen extends StatefulWidget {
  const CcrClosureScreen({
    super.key,
    required this.ccrId,
  });

  final String ccrId;

  @override
  State<CcrClosureScreen> createState() =>
      _CcrClosureScreenState();
}

class _CcrClosureScreenState
    extends State<CcrClosureScreen> {

  final CcrService _ccrService =
  CcrService();

  final TextEditingController
  _summaryController =
  TextEditingController();

  final TextEditingController
  _customerResponseController =
  TextEditingController();

  final TextEditingController
  _remarksController =
  TextEditingController();

  final TextEditingController
  _closedByController =
  TextEditingController();

  DateTime? _closedAt;

  CcrCase? _ccr;

  Map<String, dynamic>? _closure;

  bool _loading = true;
  bool _saving = false;
  bool _completing = false;
  bool _uploadingCustomerFormat = false;

  String? _error;

  Map<String, dynamic>? _customerFormatAttachment;

  PlatformFile? _pendingCustomerFormat;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _customerResponseController.dispose();
    _remarksController.dispose();
    _closedByController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final CcrCase? ccr =
      await _ccrService.getCcrById(widget.ccrId);

      if (ccr == null) {
        throw Exception(
          'The selected customer complaint could not be found.',
        );
      }

      // Load closure record through FastAPI.
      final dynamic closureResponse =
      await CcrApiClient.get(
        '/cases/${widget.ccrId}/closure',
      );

      Map<String, dynamic>? closure;

      if (closureResponse is Map) {
        closure = Map<String, dynamic>.from(
          closureResponse,
        );
      }

      // Load attachments through FastAPI.
      final dynamic attachmentResponse =
      await CcrApiClient.get(
        '/cases/${widget.ccrId}/attachments',
      );

      Map<String, dynamic>? customerFormat;

      if (attachmentResponse is List) {
        final attachments = attachmentResponse
            .whereType<Map>()
            .map(
              (row) => Map<String, dynamic>.from(row),
        )
            .where(
              (row) =>
          row['attachment_type']?.toString() ==
              'customer_format' &&
              row['is_deleted'] != true,
        )
            .toList();

        if (attachments.isNotEmpty) {
          customerFormat = attachments.first;
        }
      }

      if (closure != null) {
        _summaryController.text =
            closure['closure_summary']?.toString() ?? '';

        _customerResponseController.text =
            closure['customer_response']?.toString() ?? '';

        _remarksController.text =
            closure['final_remarks']?.toString() ?? '';

        _closedByController.text =
            closure['closed_by']?.toString() ?? '';

        _closedAt = closure['closed_at'] == null
            ? null
            : DateTime.tryParse(
          closure['closed_at'].toString(),
        );
      } else {
        _summaryController.clear();
        _customerResponseController.clear();
        _remarksController.clear();
        _closedByController.clear();
        _closedAt = null;
      }

      if (!mounted) return;

      setState(() {
        _ccr = ccr;
        _closure = closure;
        _customerFormatAttachment = customerFormat;
        _pendingCustomerFormat = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _cleanError(e);
      });
    }
  }

  // ============================================================
  // SAVE DRAFT
  // ============================================================

  // ============================================================
  // CUSTOMER FORMAT PICKER
  // ============================================================

  Future<void> _pickCustomerFormat() async {
    if (_saving ||
        _completing ||
        _uploadingCustomerFormat) {
      return;
    }

    try {
      final FilePickerResult? result =
      await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'txt',
          'jpg',
          'jpeg',
          'png',
        ],
      );

      if (result == null ||
          result.files.isEmpty) {
        return;
      }

      final PlatformFile file =
          result.files.first;

      if (file.bytes == null) {
        throw Exception(
          'Unable to read the selected Customer Format file.',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _pendingCustomerFormat = file;
      });

      _showMessage(
        'Customer Format selected. Save the Closure to upload it.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanError(e),
        error: true,
      );
    }
  }

  // ============================================================
  // UPLOAD CUSTOMER FORMAT
  // ============================================================

  Future<void> _uploadCustomerFormat() async {
    final PlatformFile? file = _pendingCustomerFormat;

    if (file == null || file.bytes == null) {
      return;
    }

    setState(() {
      _uploadingCustomerFormat = true;
    });

    try {
      // Soft-delete the previous Customer Format attachment.
      final existingId =
      _customerFormatAttachment?['id']
          ?.toString()
          .trim();

      if (existingId != null && existingId.isNotEmpty) {
        await CcrApiClient.delete(
          '/attachments/$existingId',
        );
      }

      // Upload the new file through FastAPI.
      final dynamic response =
      await CcrApiClient.uploadFileBytes(
        path: '/cases/${widget.ccrId}/attachments',
        bytes: file.bytes!,
        fileName: file.name,
        fields: {
          'attachment_type': 'customer_format',
          'title': file.name,
          'description':
          'Customer Format uploaded during CCR Closure.',
        },
      );

      if (response is! Map) {
        throw Exception(
          'Customer Format upload did not return attachment details.',
        );
      }

      _customerFormatAttachment =
      Map<String, dynamic>.from(response);

      _pendingCustomerFormat = null;

      if (!mounted) return;

      _showMessage(
        'Customer Format uploaded successfully.',
      );
    } catch (e) {
      if (mounted) {
        _showMessage(
          _cleanError(e),
          error: true,
        );
      }

      // Prevent CCR closure if attachment upload fails.
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _uploadingCustomerFormat = false;
        });
      }
    }
  }

  // ============================================================
  // FILE HELPERS
  // ============================================================

  String _fileExtension(
      String fileName,
      ) {
    final int dotIndex =
    fileName.lastIndexOf('.');

    if (dotIndex < 0 ||
        dotIndex == fileName.length - 1) {
      return 'bin';
    }

    return fileName
        .substring(dotIndex + 1)
        .toLowerCase();
  }

  String _contentType(
      String extension,
      ) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';

      case 'doc':
        return 'application/msword';

      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

      case 'xls':
        return 'application/vnd.ms-excel';

      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

      case 'ppt':
        return 'application/vnd.ms-powerpoint';

      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';

      case 'txt':
        return 'text/plain';

      case 'png':
        return 'image/png';

      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';

      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _saveDraft() async {
    if (_saving || _completing) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final Map<String, dynamic> payload = {
        'ccr_id': widget.ccrId,
        'closure_status':
        _closure?['closure_status'] ?? 'pending',
        'closure_summary': _nullable(
          _summaryController.text,
        ),
        'customer_response': _nullable(
          _customerResponseController.text,
        ),
        'final_remarks': _nullable(
          _remarksController.text,
        ),
        'closed_by': _nullable(
          _closedByController.text,
        ),
        'closed_at': _closedAt?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final dynamic response = await CcrApiClient.put(
        '/cases/${widget.ccrId}/closure',
        body: {
          'data': payload,
        },
      );

      if (response is Map) {
        _closure = Map<String, dynamic>.from(response);
      }

      await _uploadCustomerFormat();

      if (!mounted) return;

      _showMessage(
        'Closure draft saved successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
  // ============================================================
  // COMPLETE / CLOSE CC
  // ============================================================
  Future<void> _complete() async {
    if (_saving || _completing) {
      return;
    }

    final String? validation = _validate();

    if (validation != null) {
      _showMessage(
        validation,
        error: true,
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Close Customer Complaint',
          ),
          content: const Text(
            'The CCR will be marked as closed after the final closure information is saved.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                true,
              ),
              style: _primaryButtonStyle(),
              child: const Text('Close CC'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _completing = true;
    });

    try {
      // Customer Format must upload successfully before closing.
      await _uploadCustomerFormat();

      final DateTime now = DateTime.now();

      final Map<String, dynamic> payload = {
        'ccr_id': widget.ccrId,
        'closure_status': 'closed',
        'closure_summary':
        _summaryController.text.trim(),
        'customer_response': _nullable(
          _customerResponseController.text,
        ),
        'final_remarks': _nullable(
          _remarksController.text,
        ),
        'closed_by':
        _closedByController.text.trim(),
        'closed_at':
        _closedAt!.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      await CcrApiClient.post(
        '/cases/${widget.ccrId}/closure/complete',
        body: {
          'data': payload,
        },
      );

      if (!mounted) return;

      _showMessage(
        'CCR closed successfully.',
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      Navigator.popUntil(
        context,
            (Route<dynamic> route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _completing = false;
        });
      }
    }
  }
  // ============================================================
  // GET CLOSED STATUS FROM MASTER
  // ============================================================

  Future<void> _selectClosedAt() async {
    final DateTime initialDate =
        _closedAt ?? DateTime.now();

    final DateTime? selected =
    await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _closedAt = DateTime(
        selected.year,
        selected.month,
        selected.day,
      );
    });
  }

  String _formatClosedAt(DateTime? date) {
    if (date == null) {
      return 'Select closure date';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
  // ============================================================
  // VALIDATION
  // ============================================================

  String? _validate() {
    if (_summaryController.text.trim().isEmpty) {
      return 'Closure Summary is required.';
    }

    if (_closedByController.text.trim().isEmpty) {
      return 'Closed By is required.';
    }

    if (_closedAt == null) {
      return 'Please select the Closed At date.';
    }

    return null;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    if (_loading) {
      return const Scaffold(
        backgroundColor:
        Color(0xFFF5F7FB),
        body: Center(
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor:
        const Color(0xFFF5F7FB),
        appBar: _appBar(),
        body: _errorView(),
      );
    }

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),
      appBar: _appBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 1100,
            ),
            child:
            SingleChildScrollView(
              padding:
              const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 20),
                  _caseCard(),
                  const SizedBox(height: 18),
                  _closureCard(),
                  const SizedBox(height: 18),
                  _actionBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      foregroundColor:
      const Color(0xFF172033),
      title: Row(
        children: [
          _iconBox(
            Icons.check_circle_outline,
          ),
          const SizedBox(width: 12),
          Text(
            _ccr?.displayNumber ??
                'CCR',
            style:
            const TextStyle(
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 24,
          color:
          Color(0xFF3155C6),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Close CC',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  Color(0xFF172033),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Complete the final review and close the customer complaint.',
                style: TextStyle(
                  fontSize: 12.5,
                  color:
                  Color(0xFF7A818C),
                ),
              ),
            ],
          ),
        ),
        _statusChip(),
      ],
    );
  }

  Widget _statusChip() {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFF3F4F6),
        borderRadius:
        BorderRadius.circular(10),
      ),
      child: Text(
        _closure?['closure_status']
            ?.toString() ??
            'pending',
        style:
        const TextStyle(
          fontSize: 11,
          fontWeight:
          FontWeight.w700,
          color:
          Color(0xFF626873),
        ),
      ),
    );
  }

  Widget _caseCard() {
    return _surfaceCard(
      child: Row(
        children: [
          _iconBox(
            Icons.assignment_outlined,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  _ccr?.displayNumber ??
                      'CCR',
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _ccr?.problemDescription ??
                      '-',
                  maxLines: 3,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 12.5,
                    color:
                    Color(0xFF747B86),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _closureCard() {
    return _surfaceCard(
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            Icons.verified_outlined,
            'Closure Information',
            'Record the final disposition of the customer complaint.',
          ),
          const SizedBox(height: 20),
          _field(
            'Closure Summary',
            _summaryController,
            'Enter the final closure summary.',
            6,
          ),

          const SizedBox(height: 18),

          _field(
            'Customer Response',
            _customerResponseController,
            'Record the customer response or acceptance information.',
            5,
          ),

          const SizedBox(height: 18),

          _field(
            'Final Remarks',
            _remarksController,
            'Enter final remarks.',
            5,
          ),

          const SizedBox(height: 18),

          _field(
            'Closed By',
            _closedByController,
            'Enter the name of the person closing this CCR.',
            1,
          ),

          const SizedBox(height: 18),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Closed At',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF252A31),
                ),
              ),
              const SizedBox(height: 7),
              InkWell(
                onTap: _saving || _completing
                    ? null
                    : _selectClosedAt,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 17,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE2E5EA),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: Color(0xFF3155C6),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _formatClosedAt(_closedAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: _closedAt == null
                                ? const Color(0xFF8A9098)
                                : const Color(0xFF252A31),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF747B86),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _customerFormatField(),
        ],
      ),
    );
  }
  // ============================================================
  // CUSTOMER FORMAT FIELD
  // ============================================================

  Widget _customerFormatField() {
    final pending =
        _pendingCustomerFormat;

    final saved =
        _customerFormatAttachment;

    final String? fileName =
        pending?.name ??
            saved?['original_file_name']
                ?.toString()
                .trim();

    final bool hasFile =
        fileName != null &&
            fileName.isNotEmpty;

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
        const Color(0xFFF8F9FB),
        borderRadius:
        BorderRadius.circular(10),
        border: Border.all(
          color:
          const Color(0xFFE2E5EA),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Customer Format',
            style: TextStyle(
              fontSize: 13,
              fontWeight:
              FontWeight.w700,
              color:
              Color(0xFF252A31),
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Upload the customer format that belongs to this closed complaint.',
            style: TextStyle(
              fontSize: 11.5,
              color:
              Color(0xFF7A818C),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              FilledButton.icon(
                onPressed:
                _saving ||
                    _completing ||
                    _uploadingCustomerFormat
                    ? null
                    : _pickCustomerFormat,
                icon:
                _uploadingCustomerFormat
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                    Colors.white,
                  ),
                )
                    : const Icon(
                  Icons
                      .upload_file_outlined,
                ),
                label: Text(
                  _uploadingCustomerFormat
                      ? 'Uploading...'
                      : hasFile
                      ? 'Replace File'
                      : 'Select File',
                ),
              ),
            ],
          ),

          if (hasFile) ...[
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(9),
                border: Border.all(
                  color:
                  const Color(0xFFE2E5EA),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons
                        .insert_drive_file_outlined,
                    color:
                    Color(0xFF3155C6),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      fileName,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      const TextStyle(
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),

                  if (pending != null)
                    IconButton(
                      tooltip:
                      'Remove selected file',
                      onPressed:
                      _saving ||
                          _completing ||
                          _uploadingCustomerFormat
                          ? null
                          : () {
                        setState(() {
                          _pendingCustomerFormat =
                          null;
                        });
                      },
                      icon:
                      const Icon(
                        Icons.close,
                        size: 19,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _actionBar() {
    return _surfaceCard(
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed:
            _saving ||
                _completing
                ? null
                : _saveDraft,
            icon:
            const Icon(
              Icons.save_outlined,
              size: 18,
            ),
            label:
            const Text(
              'Save Draft',
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed:
            _saving ||
                _completing
                ? null
                : _complete,
            style:
            _primaryButtonStyle(),
            icon:
            _completing
                ? const SizedBox(
              width: 17,
              height: 17,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
                color:
                Colors.white,
              ),
            )
                : const Icon(
              Icons
                  .check_circle_outline,
            ),
            label:
            const Text(
              'Close CC',
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
      String label,
      TextEditingController controller,
      String hint,
      int maxLines,
      ) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration:
      InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor:
        const Color(0xFFF8F9FB),
        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(10),
          borderSide:
          const BorderSide(
            color:
            Color(0xFFE2E5EA),
          ),
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(10),
          borderSide:
          const BorderSide(
            color:
            Color(0xFFE2E5EA),
          ),
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(10),
          borderSide:
          const BorderSide(
            color:
            Color(0xFF3155C6),
            width: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(
      IconData icon,
      String title,
      String subtitle,
      ) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        _iconBox(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                const TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style:
                const TextStyle(
                  fontSize: 12,
                  color:
                  Color(0xFF7A818C),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _surfaceCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(20),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color:
          const Color(0xFFE3E6EB),
        ),
      ),
      child: child,
    );
  }

  Widget _iconBox(
      IconData icon,
      ) {
    return Container(
      width: 40,
      height: 40,
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFEFF3FF),
        borderRadius:
        BorderRadius.circular(11),
      ),
      child: Icon(
        icon,
        color:
        const Color(0xFF3155C6),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: _surfaceCard(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 42,
              color:
              Color(0xFFE14B4B),
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load Close CC',
              style:
              TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _error ?? '',
              textAlign:
              TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _load,
              child:
              const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor:
      const Color(0xFF7655C9),
      foregroundColor:
      Colors.white,
      elevation: 0,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 13,
      ),
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(11),
      ),
    );
  }

  String? _nullable(String value) {
    final String clean =
    value.trim();

    return clean.isEmpty
        ? null
        : clean;
  }

  String _cleanError(dynamic error) {
    return error
        .toString()
        .replaceFirst(
      'Exception: ',
      '',
    );
  }

  void _showMessage(
      String message, {
        bool error = false,
      }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error
            ? const Color(0xFFC62828)
            : null,
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }
}