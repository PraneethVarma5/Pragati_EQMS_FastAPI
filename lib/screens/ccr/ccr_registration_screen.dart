
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ccr/ccr_api_client.dart';

import 'ccr_containment_screen.dart';
import '../../services/ccr/ccr_team_service.dart';

class CcrRegistrationScreen extends StatefulWidget {
  final String ccrId;

  const CcrRegistrationScreen({
    super.key,
    required this.ccrId,
  });

  @override
  State<CcrRegistrationScreen> createState() =>
      _CcrRegistrationScreenState();
}

class _CcrRegistrationScreenState
    extends State<CcrRegistrationScreen> {
  final ImagePicker _imagePicker = ImagePicker();

// ============================================================
// REGISTRATION FIELDS
// ============================================================

  final TextEditingController _complaintDateController =
  TextEditingController();

  final TextEditingController _complaintSourceController =
  TextEditingController();

  final TextEditingController _customerNameController =
  TextEditingController();

  final TextEditingController _groupNameController =
  TextEditingController();

  final TextEditingController _customerContactNameController =
  TextEditingController();

  final TextEditingController _customerContactPositionController =
  TextEditingController();

  final TextEditingController _customerContactCompanyController =
  TextEditingController();

  final TextEditingController _customerLocationController =
  TextEditingController();

  final TextEditingController _customerPartNumberController =
  TextEditingController();

  final TextEditingController _supplierPartNumberController =
  TextEditingController();

  final TextEditingController _partDescriptionController =
  TextEditingController();

  final TextEditingController _partNoController =
  TextEditingController();

  final TextEditingController _qtyController =
  TextEditingController();

  final TextEditingController _complaintDescriptionController =
  TextEditingController();

  final TextEditingController _problemDescriptionController =
  TextEditingController();

  final TextEditingController _detectedDateController =
  TextEditingController();

  final TextEditingController _detectedByController =
  TextEditingController();

// ============================================================
// STATE
// ============================================================

  bool _loading = true;
  bool _saving = false;
  bool _completing = false;

  String? _error;

  Map<String, dynamic>? _ccr;

  String? _stageName;
  String? _statusName;

  List<Map<String, dynamic>> _attachments =
  <Map<String, dynamic>>[];

// ============================================================
// CCR TEAM
// ============================================================

  List<Map<String, dynamic>> _availableTeams =
  <Map<String, dynamic>>[];

  String? _selectedTeamId;

  String? _selectedTeamLeaderName;

  List<String> _selectedTeamMembers =
  <String>[];

  bool _loadingTeams = false;

// ============================================================
// PENDING PHOTOS
// ============================================================

  final List<_PendingPhoto> _pendingPhotos =
  <_PendingPhoto>[];

// ============================================================
// CUSTOMER COMPLAINT DOCUMENT
// ============================================================

  _PendingDocument? _pendingCustomerDocument;

  Map<String, dynamic>?
  _savedCustomerComplaintDocument;

// ============================================================
// INIT
// ============================================================

  @override
  void initState() {
    super.initState();
    _loadRegistration();
  }

// ============================================================
// LOAD REGISTRATION
// ============================================================

  Future<void> _loadRegistration() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _loadingTeams = true;
      _error = null;
    });

    try {
      final dynamic rawCcr = await CcrApiClient.get(
        '/cases/${widget.ccrId}',
      );

      if (rawCcr == null || rawCcr is! Map) {
        throw Exception('Customer complaint could not be found.');
      }

      final Map<String, dynamic> ccr =
      Map<String, dynamic>.from(rawCcr);

      final dynamic rawAttachments = await CcrApiClient.get(
        '/cases/${widget.ccrId}/attachments',
      );

      final List<Map<String, dynamic>> attachments =
      rawAttachments is List
          ? rawAttachments
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList()
          : <Map<String, dynamic>>[];

      final availableTeams =
      await CcrTeamService
          .getActiveTeamsForSelection();

      _ccr = ccr;

      _stageName = _extractNestedName(
        ccr['ccr_workflow_stages'],
        'stage_name',
      );

      _statusName = _extractNestedName(
        ccr['ccr_statuses'],
        'status_name',
      );

      _populateCase(ccr);

      _attachments = attachments;

// ----------------------------------------------------------
// CUSTOMER COMPLAINT DOCUMENT
// ----------------------------------------------------------

      _savedCustomerComplaintDocument = null;

      for (final attachment in _attachments) {
        final attachmentType =
        attachment['attachment_type']
            ?.toString();

        if (attachmentType ==
            'customer_complaint_document') {
          _savedCustomerComplaintDocument =
              attachment;
          break;
        }
      }

// ----------------------------------------------------------
// TEAM
// ----------------------------------------------------------

      _availableTeams =
      List<Map<String, dynamic>>.from(
        availableTeams,
      );

      final existingTeamId =
      ccr['team_id']?.toString();

      if (existingTeamId != null &&
          existingTeamId.trim().isNotEmpty) {
        _selectTeamById(
          existingTeamId,
          updateState: false,
        );
      }

      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadingTeams = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadingTeams = false;
        _error = _cleanError(e);
      });
    }
  }

// ============================================================
// NESTED VALUE
// ============================================================

  String? _extractNestedName(
      dynamic value,
      String key,
      ) {
    if (value is Map) {
      return value[key]?.toString();
    }

    if (value is List &&
        value.isNotEmpty &&
        value.first is Map) {
      return value.first[key]?.toString();
    }

    return null;
  }

// ============================================================
// POPULATE CASE
// ============================================================

  void _populateCase(
      Map<String, dynamic> data,
      ) {
    _setController(
      _complaintDateController,
      data['complaint_date'],
    );

    _setController(
      _complaintSourceController,
      data['complaint_source'],
    );

    _setController(
      _customerNameController,
      data['customer_name'],
    );

    _setController(
      _groupNameController,
      data['group_name'],
    );

    _setController(
      _customerContactNameController,
      data['customer_contact_name'],
    );

    _setController(
      _customerContactPositionController,
      data['customer_contact_position'],
    );

    _setController(
      _customerContactCompanyController,
      data['customer_contact_company'],
    );

    _setController(
      _customerLocationController,
      data['customer_location'],
    );

    _setController(
      _customerPartNumberController,
      data['customer_part_number'],
    );

    _setController(
      _supplierPartNumberController,
      data['supplier_part_number'],
    );

    _setController(
      _partDescriptionController,
      data['part_description'],
    );

    _setController(
      _partNoController,
      data['part_no'],
    );

    _setController(
      _qtyController,
      data['qty'],
    );

    _setController(
      _complaintDescriptionController,
      data['complaint_description'],
    );

    _setController(
      _problemDescriptionController,
      data['problem_description'],
    );

    _setController(
      _detectedDateController,
      data['detected_date'],
    );

    _setController(
      _detectedByController,
      data['detected_by'],
    );
  }

  void _setController(
      TextEditingController controller,
      dynamic value,
      ) {
    controller.text =
        value?.toString() ?? '';
  }

// ============================================================
// TEAM SELECTION
// ============================================================

  void _selectTeamById(
      String? teamId, {
        bool updateState = true,
      }) {
    if (teamId == null ||
        teamId.trim().isEmpty) {
      void clear() {
        _selectedTeamId = null;
        _selectedTeamLeaderName = null;
        _selectedTeamMembers =
        <String>[];
      }

      if (updateState) {
        setState(clear);
      } else {
        clear();
      }

      return;
    }

    Map<String, dynamic>? team;

    for (final item in _availableTeams) {
      if (item['id']?.toString() == teamId) {
        team = item;
        break;
      }
    }

    if (team == null) {
      return;
    }

    final leader =
    team['team_leader_name']
        ?.toString()
        .trim();

    final members = <String>[];

    final rawMembers = team['members'];

    if (rawMembers is List) {
      for (final member in rawMembers) {
        if (member is Map) {
          final name =
          member['member_name']
              ?.toString()
              .trim();

          if (name != null && name.isNotEmpty) {
            members.add(name);
          }
        }
      }
    }

// Fallback for nested data.
    if (members.isEmpty) {
      final rawNested =
      team['ccr_team_members'];

      if (rawNested is List) {
        for (final member in rawNested) {
          if (member is Map) {
            final name =
            member['member_name']
                ?.toString()
                .trim();

            if (name != null && name.isNotEmpty) {
              members.add(name);
            }
          }
        }
      }
    }

    void apply() {
      _selectedTeamId = teamId;
      _selectedTeamLeaderName = leader;
      _selectedTeamMembers = members;
    }

    if (updateState) {
      setState(apply);
    } else {
      apply();
    }
  }

// ============================================================
// SAVE DRAFT
// ============================================================

  Future<void> _saveDraft({
    bool closeAfterSave = false,
  }) async {
    if (_saving || _completing) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _saveCase();

      if (_selectedTeamId != null &&
          _selectedTeamId!.trim().isNotEmpty) {
        await CcrTeamService.saveCcrTeamSnapshot(
          ccrId: widget.ccrId,
          teamId: _selectedTeamId!,
        );
      }

      await _uploadPendingPhotos();

      await _uploadPendingCustomerDocument();

      await _refreshAfterSave();

      if (!mounted) return;

      _showMessage(
        'Registration draft saved successfully.',
      );

      if (closeAfterSave) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e),
        isError: true,
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
// SAVE CASE
// ============================================================

  Future<void> _saveCase() async {
    await CcrApiClient.patch(
      '/cases/${widget.ccrId}',
      body: {
        'data': {
          'complaint_date': _nullableText(_complaintDateController),
          'complaint_source': _nullableText(_complaintSourceController),
          'customer_name': _nullableText(_customerNameController),
          'group_name': _nullableText(_groupNameController),
          'customer_contact_name': _nullableText(_customerContactNameController),
          'customer_contact_position': _nullableText(_customerContactPositionController),
          'customer_contact_company': _nullableText(_customerContactCompanyController),
          'customer_location': _nullableText(_customerLocationController),
          'customer_part_number': _nullableText(_customerPartNumberController),
          'supplier_part_number': _nullableText(_supplierPartNumberController),
          'part_description': _nullableText(_partDescriptionController),
          'part_no': _nullableText(_partNoController),
          'qty': _toNumber(_qtyController),
          'complaint_description': _nullableText(_complaintDescriptionController),
          'problem_description': _nullableText(_problemDescriptionController),
          'detected_date': _nullableText(_detectedDateController),
          'detected_by': _nullableText(_detectedByController),
          'team_leader': _selectedTeamLeaderName,
        },
      },
    );
  }

// ============================================================
// COMPLETE REGISTRATION
// ============================================================

  Future<void> _completeRegistration() async {
    if (_saving || _completing) return;

    final validationMessage = _validateForCompletion();
    if (validationMessage != null) {
      _showMessage(validationMessage, isError: true);
      return;
    }

    setState(() => _completing = true);

    try {
      final dynamic currentCaseRaw = await CcrApiClient.get(
        '/cases/${widget.ccrId}',
      );
      if (currentCaseRaw is! Map) {
        throw Exception('Customer complaint could not be found.');
      }

      final currentStageKey =
      currentCaseRaw['current_stage']?.toString().trim();
      if (currentStageKey == null || currentStageKey.isEmpty) {
        throw Exception('Current CCR workflow stage is missing.');
      }

      final dynamic stagesRaw = await CcrApiClient.get(
        '/workflow/stages',
        query: {'active_only': 'true'},
      );
      final stages = stagesRaw is List
          ? stagesRaw.whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row)).toList()
          : <Map<String, dynamic>>[];

      if (stages.isEmpty) {
        throw Exception('No active CCR workflow stage is configured.');
      }

      stages.sort((a, b) =>
          _displayOrder(a['display_order']).compareTo(
            _displayOrder(b['display_order']),
          ));

      final firstStageKey = stages.first['stage_key']?.toString().trim();
      if (firstStageKey == null || firstStageKey.isEmpty) {
        throw Exception('Initial CCR workflow stage is missing.');
      }

      if (currentStageKey != firstStageKey) {
        throw Exception(
          'Registration has already been completed. '
              'The CCR is currently at "$currentStageKey".',
        );
      }

      await _saveCase();

      if (_selectedTeamId != null && _selectedTeamId!.trim().isNotEmpty) {
        await CcrTeamService.saveCcrTeamSnapshot(
          ccrId: widget.ccrId,
          teamId: _selectedTeamId!,
        );
      }

      await _uploadPendingPhotos();
      await _uploadPendingCustomerDocument();

      final currentIndex = stages.indexWhere(
            (stage) => stage['stage_key']?.toString() == currentStageKey,
      );
      if (currentIndex < 0) {
        throw Exception(
          'Current workflow stage is not active or is not configured.',
        );
      }
      if (currentIndex + 1 >= stages.length) {
        throw Exception('No next active CCR workflow stage is configured.');
      }

      final nextStage = stages[currentIndex + 1];
      final nextStageKey = nextStage['stage_key']?.toString().trim();
      final nextStageName = nextStage['stage_name']?.toString().trim();

      if (nextStageKey == null || nextStageKey.isEmpty) {
        throw Exception('Next CCR workflow stage is missing.');
      }

      final dynamic advanced = await CcrApiClient.post(
        '/cases/${widget.ccrId}/workflow/advance',
      );

      if (advanced is! Map ||
          advanced['current_stage']?.toString() != nextStageKey) {
        throw Exception(
          'The CCR stage changed before Registration could be completed. '
              'Please reload the complaint.',
        );
      }

      if (!mounted) return;

      _showMessage(
        'Registration completed. '
            'Next stage: ${nextStageName ?? nextStageKey}.',
      );

      await _openNextStage(stageKey: nextStageKey);
    } catch (e) {
      if (!mounted) return;
      _showMessage(_cleanError(e), isError: true);
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

// ============================================================
// OPEN NEXT STAGE
// ============================================================

  Future<void> _openNextStage({
    required String stageKey,
  }) async {
    final cleanStage =
    stageKey.trim().toLowerCase();

    if (cleanStage.isEmpty) {
      throw Exception(
        'Next CCR workflow stage is missing.',
      );
    }

// ----------------------------------------------------------
// Containment is currently the next implemented screen.
//
// The database determines that it is the next stage.
// ----------------------------------------------------------

    if (cleanStage == 'containment') {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CcrContainmentScreen(
                ccrId: widget.ccrId,
              ),
        ),
      );

      return;
    }

// ----------------------------------------------------------
// If the DB contains a stage for which the Flutter screen
// has not yet been implemented, do not silently send the
// user Home.
// ----------------------------------------------------------

    throw Exception(
      'The next CCR workflow stage "$stageKey" '
          'does not have an implemented screen yet.',
    );
  }

// ============================================================
// COMPLETION VALIDATION
// ============================================================

  String? _validateForCompletion() {
    if (_complaintDateController.text
        .trim()
        .isEmpty) {
      return 'Complaint Date is required.';
    }

    if (_customerNameController.text
        .trim()
        .isEmpty) {
      return 'Customer is required.';
    }

    if (_customerLocationController.text
        .trim()
        .isEmpty) {
      return 'Location is required.';
    }

    if (_partDescriptionController.text
        .trim()
        .isEmpty) {
      return 'Part Description is required.';
    }

    if (_partNoController.text
        .trim()
        .isEmpty) {
      return 'Part No is required.';
    }

    if (_qtyController.text
        .trim()
        .isEmpty) {
      return 'Qty is required.';
    }

    if (_toNumber(_qtyController) == null) {
      return 'Qty must be a valid number.';
    }

    if (_complaintDescriptionController.text
        .trim()
        .isEmpty) {
      return 'Complaint Description is required.';
    }

// if (_problemDescriptionController.text
//     .trim()
//     .isEmpty) {
// return 'Problem Description is required.';
// }

    if (_selectedTeamId == null ||
        _selectedTeamId!.trim().isEmpty) {
      return 'Please select a CCR Team before completing Registration.';
    }

    return null;
  }

// ============================================================
// CUSTOMER COMPLAINT DOCUMENT
// ============================================================

  Future<void>
  _pickCustomerComplaintDocument() async {
    try {
      final result =
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

      final file = result.files.first;

      if (file.bytes == null) {
        throw Exception(
          'Unable to read the selected document.',
        );
      }

      if (!mounted) return;

      setState(() {
        _pendingCustomerDocument =
            _PendingDocument(
              bytes: file.bytes!,
              fileName: file.name,
              extension:
              _fileExtension(file.name),
            );
      });

      _showMessage(
        'Customer complaint document selected. Save the registration to upload it.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e),
        isError: true,
      );
    }
  }

// ============================================================
// PHOTO PICKER
// ============================================================

  Future<void> _pickPhoto(
      ImageSource source,
      ) async {
    try {
      final image =
      await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (image == null) {
        return;
      }

      final bytes =
      await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _pendingPhotos.add(
          _PendingPhoto(
            bytes: bytes,
            fileName: image.name,
          ),
        );
      });

      _showMessage(
        'Photo added. Save the registration to upload it.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e),
        isError: true,
      );
    }
  }

// ============================================================
// UPLOAD PHOTOS
// ============================================================

  Future<void> _uploadPendingPhotos() async {
    if (_pendingPhotos.isEmpty) return;

    for (final photo in List<_PendingPhoto>.from(_pendingPhotos)) {
      await CcrApiClient.uploadFileBytes(
        path: '/cases/${widget.ccrId}/attachments',
        bytes: photo.bytes,
        fileName: photo.fileName,
        fields: {
          'attachment_type': 'complaint_photo',
          'title': photo.fileName,
          'description': 'Customer complaint registration photo.',
        },
      );
    }

    _pendingPhotos.clear();
  }

// ============================================================
// FILE HELPERS
// ============================================================

  String _fileExtension(
      String fileName,
      ) {
    final dotIndex =
    fileName.lastIndexOf('.');

    if (dotIndex == -1) {
      return 'jpg';
    }

    final extension =
    fileName.substring(
      dotIndex + 1,
    );

    if (extension.isEmpty) {
      return 'jpg';
    }

    return extension.toLowerCase();
  }

  String _contentType(
      String extension,
      ) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';

      case 'webp':
        return 'image/webp';

      case 'gif':
        return 'image/gif';

      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';

      default:
        return 'application/octet-stream';
    }
  }

  String _documentContentType(
      String extension,
      ) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';

      case 'doc':
        return 'application/msword';

      case 'docx':
        return
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

      case 'xls':
        return 'application/vnd.ms-excel';

      case 'xlsx':
        return
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

      case 'ppt':
        return 'application/vnd.ms-powerpoint';

      case 'pptx':
        return
          'application/vnd.openxmlformats-officedocument.presentationml.presentation';

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

// ============================================================
// UPLOAD CUSTOMER COMPLAINT DOCUMENT
// ============================================================

  Future<void> _uploadPendingCustomerDocument() async {
    final document = _pendingCustomerDocument;
    if (document == null) return;

    final existingId = _savedCustomerComplaintDocument?['id']?.toString();
    if (existingId != null && existingId.isNotEmpty) {
      await CcrApiClient.delete('/attachments/$existingId');
    }

    await CcrApiClient.uploadFileBytes(
      path: '/cases/${widget.ccrId}/attachments',
      bytes: document.bytes,
      fileName: document.fileName,
      fields: {
        'attachment_type': 'customer_complaint_document',
        'title': document.fileName,
        'description': 'Original customer complaint document.',
      },
    );

    _pendingCustomerDocument = null;
  }

// ============================================================
// DATE PICKER
// ============================================================

  Future<void> _selectDate(
      TextEditingController controller,
      ) async {
    DateTime initialDate =
    DateTime.now();

    final existing =
    DateTime.tryParse(
      controller.text.trim(),
    );

    if (existing != null) {
      initialDate = existing;
    }

    final picked =
    await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    controller.text =
        _formatDate(picked);
  }

  String _formatDate(
      DateTime date,
      ) {
    final month =
    date.month
        .toString()
        .padLeft(2, '0');

    final day =
    date.day
        .toString()
        .padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

// ============================================================
// REFRESH
// ============================================================

  Future<void> _refreshAfterSave() async {
    final dynamic rawCcr = await CcrApiClient.get(
      '/cases/${widget.ccrId}',
    );

    if (rawCcr is! Map) return;

    final ccr = Map<String, dynamic>.from(rawCcr);
    _ccr = ccr;

    _stageName = _extractNestedName(
      ccr['ccr_workflow_stages'],
      'stage_name',
    );
    _statusName = _extractNestedName(
      ccr['ccr_statuses'],
      'status_name',
    );

    _populateCase(ccr);

    final dynamic rawAttachments = await CcrApiClient.get(
      '/cases/${widget.ccrId}/attachments',
    );

    _attachments = rawAttachments is List
        ? rawAttachments.whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row)).toList()
        : <Map<String, dynamic>>[];

    _savedCustomerComplaintDocument = null;
    for (final attachment in _attachments) {
      if (attachment['attachment_type']?.toString() ==
          'customer_complaint_document') {
        _savedCustomerComplaintDocument = attachment;
        break;
      }
    }

    if (mounted) setState(() {});
  }

// ============================================================
// HELPERS
// ============================================================

  String? _nullableText(
      TextEditingController controller,
      ) {
    final value =
    controller.text.trim();

    return value.isEmpty
        ? null
        : value;
  }

  num? _toNumber(
      TextEditingController controller,
      ) {
    final value =
    controller.text.trim();

    if (value.isEmpty) {
      return null;
    }

    return num.tryParse(value);
  }

  int _displayOrder(
      dynamic value,
      ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  String _cleanError(
      dynamic error,
      ) {
    final text =
    error.toString();

    return text
        .replaceFirst(
      'Exception: ',
      '',
    )
        .replaceFirst(
      'PostgrestException(message: ',
      '',
    );
  }

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

// ============================================================
// BUILD
// ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor:
        const Color(0xFF172033),

        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xFFEFF3FF,
                ),
                borderRadius:
                BorderRadius.circular(
                  11,
                ),
              ),
              child: const Icon(
                Icons
                    .report_problem_outlined,
                color:
                Color(0xFF3155C6),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                _ccrDisplayNumber(),
                style:
                const TextStyle(
                  fontSize: 19,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
            _loading ||
                _saving ||
                _completing
                ? null
                : _loadRegistration,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: _loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : _error != null
          ? _buildError()
          : _buildBody(),
    );
  }

  String _ccrDisplayNumber() {
    final value =
    _ccr?['ccr_number'];

    if (value == null) {
      return 'Customer Complaint Registration';
    }

    final number =
        int.tryParse(
          value.toString(),
        ) ??
            0;

    if (number <= 0) {
      return 'Customer Complaint Registration';
    }

    return 'CCR-${number.toString().padLeft(6, '0')}';
  }

// ============================================================
// ERROR
// ============================================================

  Widget _buildError() {
    return Center(
      child: _surfaceCard(
        child: Padding(
          padding:
          const EdgeInsets.all(40),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons
                    .error_outline_rounded,
                size: 46,
                color:
                Color(0xFFD94A4A),
              ),

              const SizedBox(height: 14),

              const Text(
                'Unable to load complaint',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _error ?? '',
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  color:
                  Color(0xFF6B7280),
                ),
              ),

              const SizedBox(height: 18),

              OutlinedButton.icon(
                onPressed:
                _loadRegistration,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label:
                const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

// ============================================================
// BODY
// ============================================================

  Widget _buildBody() {
    return Column(
      children: [
        _buildStageHeader(),

        Expanded(
          child:
          SingleChildScrollView(
            padding:
            const EdgeInsets.fromLTRB(
              24,
              22,
              24,
              130,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints:
                const BoxConstraints(
                  maxWidth: 1200,
                ),
                child: Column(
                  children: [
                    _buildRegistrationInformation(),

                    const SizedBox(
                      height: 18,
                    ),

                    _buildTeamSection(),

                    const SizedBox(
                      height: 18,
                    ),

                    _buildCustomerComplaintDocument(),

                    const SizedBox(
                      height: 18,
                    ),

                    _buildPhotos(),
                  ],
                ),
              ),
            ),
          ),
        ),

        _buildBottomBar(),
      ],
    );
  }

// ============================================================
// STAGE HEADER
// ============================================================

  Widget _buildStageHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 1200,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.assignment_outlined,
                color:
                Color(0xFF3155C6),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registration',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Register the customer complaint and required traceability information.',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                        Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),

              if (_stageName != null)
                _chip(_stageName!),

              const SizedBox(width: 8),

              if (_statusName != null)
                _chip(_statusName!),
            ],
          ),
        ),
      ),
    );
  }

// ============================================================
// REGISTRATION INFORMATION
// ============================================================


  Widget _buildRegistrationInformation() {
    return _sectionCard(
      icon: Icons.info_outline_rounded,
      title: 'Complaint Registration',
      subtitle: 'Enter the required customer complaint information.',
      child: _responsiveFields(
        [
          _dateField(
            'Complaint Date',
            _complaintDateController,
          ),

          _textField(
            'Customer Name',
            _customerNameController,
          ),

          _textField(
            'Customer Location',
            _customerLocationController,
          ),

          _textField(
            'Part Description',
            _partDescriptionController,
          ),

          _textField(
            'Part No',
            _partNoController,
          ),

          _numberField(
            'Qty',
            _qtyController,
          ),

          _textField(
            'Complaint Description',
            _complaintDescriptionController,
            maxLines: 4,
            fullWidth: true,
          ),
        ],
      ),
    );
  }


// ============================================================
// TEAM SECTION
// ============================================================

  Widget _buildTeamSection() {
    return _sectionCard(
      icon:
      Icons.groups_outlined,
      title: 'CCR Team and Members',
      subtitle:
      'Select the configured CCR team and review its members.',
      child: _teamSelectionField().widget,
    );
  }

  _FieldItem _teamSelectionField() {
    return _FieldItem(
      fullWidth: true,
      widget: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _availableTeams.any(
                  (team) =>
              team['id']?.toString() ==
                  _selectedTeamId,
            )
                ? _selectedTeamId
                : null,
            isExpanded: true,
            decoration:
            _inputDecoration(
              'CCR Team',
            ).copyWith(
              prefixIcon: const Icon(
                Icons.groups_outlined,
              ),
            ),
            hint: const Text(
              'Select Team Leader',
            ),
            items: _availableTeams
                .map<DropdownMenuItem<String>?>(
                  (team) {
                final id =
                team['id']?.toString();

                final leader =
                team['team_leader_name']
                    ?.toString()
                    .trim();

                if (id == null ||
                    id.isEmpty ||
                    leader == null ||
                    leader.isEmpty) {
                  return null;
                }

                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(
                    leader,
                    overflow:
                    TextOverflow.ellipsis,
                  ),
                );
              },
            )
                .whereType<
                DropdownMenuItem<String>>()
                .toList(),
            onChanged:
            _availableTeams.isEmpty ||
                _loadingTeams
                ? null
                : (value) {
              _selectTeamById(
                value,
              );
            },
          ),

          const SizedBox(height: 12),

          if (_loadingTeams)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Loading CCR teams...',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                    Color(0xFF6B7280),
                  ),
                ),
              ],
            ),

          if (!_loadingTeams &&
              _availableTeams.isEmpty)
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(
                12,
              ),
              decoration:
              BoxDecoration(
                color:
                const Color(0xFFFFF7ED),
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
                border: Border.all(
                  color:
                  const Color(0xFFF5C28B),
                ),
              ),
              child: const Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons
                        .warning_amber_rounded,
                    size: 20,
                    color:
                    Color(0xFFC77700),
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'No active CCR teams are configured. Create a team from CCR Team Management before completing Registration.',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                        Color(0xFF7A4B00),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_selectedTeamId != null &&
              !_loadingTeams)
            Container(
              width: double.infinity,
              margin:
              const EdgeInsets.only(
                top: 4,
              ),
              padding:
              const EdgeInsets.all(
                14,
              ),
              decoration:
              BoxDecoration(
                color:
                const Color(0xFFF8F9FB),
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
                border: Border.all(
                  color:
                  const Color(0xFFE2E3E7),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 18,
                        color:
                        Color(0xFF3155C6),
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'Team Leader',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                          FontWeight.w700,
                          color:
                          Color(0xFF555A63),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    _selectedTeamLeaderName ??
                        '-',
                    style:
                    const TextStyle(
                      fontSize: 14,
                      fontWeight:
                      FontWeight.w700,
                      color:
                      Color(0xFF202124),
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'Team Members',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                      FontWeight.w700,
                      color:
                      Color(0xFF555A63),
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (_selectedTeamMembers
                      .isEmpty)
                    const Text(
                      'No members configured.',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                        Color(0xFF6B7280),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                      _selectedTeamMembers
                          .map(
                            (member) {
                          return Chip(
                            avatar:
                            const Icon(
                              Icons
                                  .person_outline,
                              size: 15,
                            ),
                            label:
                            Text(member),
                          );
                        },
                      ).toList(),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

// ============================================================
// CUSTOMER COMPLAINT DOCUMENT
// ============================================================

  Widget _buildCustomerComplaintDocument() {
    final saved =
        _savedCustomerComplaintDocument;

    final pending =
        _pendingCustomerDocument;

    return _sectionCard(
      icon:
      Icons.description_outlined,
      title:
      'Original Customer Complaint Document',
      subtitle:
      'Upload the original complaint document received from the customer.',
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          FilledButton.icon(
            onPressed:
            _saving ||
                _completing
                ? null
                : _pickCustomerComplaintDocument,
            icon: const Icon(
              Icons.upload_file_outlined,
            ),
            label:
            const Text(
              'Select Document',
            ),
          ),

          const SizedBox(height: 14),

          if (pending != null)
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(
                14,
              ),
              decoration:
              BoxDecoration(
                color:
                const Color(0xFFEFF3FF),
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
                border: Border.all(
                  color:
                  const Color(0xFFBFCBF5),
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
                      pending.fileName,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      const TextStyle(
                        fontSize: 13,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip:
                    'Remove selected document',
                    onPressed:
                    _saving ||
                        _completing
                        ? null
                        : () {
                      setState(() {
                        _pendingCustomerDocument =
                        null;
                      });
                    },
                    icon:
                    const Icon(
                      Icons.close,
                    ),
                  ),
                ],
              ),
            ),

          if (pending != null &&
              saved != null)
            const SizedBox(height: 10),

          if (saved != null)
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(
                14,
              ),
              decoration:
              BoxDecoration(
                color:
                const Color(0xFFF8F9FB),
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
                border: Border.all(
                  color:
                  const Color(0xFFE2E3E7),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons
                        .description_outlined,
                    color:
                    Color(0xFF3155C6),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      saved[
                      'original_file_name']
                          ?.toString() ??
                          saved['title']
                              ?.toString() ??
                          'Customer complaint document',
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      const TextStyle(
                        fontSize: 13,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons
                        .check_circle_outline,
                    color:
                    Color(0xFF2E9B55),
                  ),
                ],
              ),
            ),

          if (saved == null &&
              pending == null)
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(
                22,
              ),
              decoration:
              BoxDecoration(
                color:
                const Color(0xFFF8F9FB),
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
                border: Border.all(
                  color:
                  const Color(0xFFE2E3E7),
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons
                        .description_outlined,
                    size: 32,
                    color:
                    Color(0xFF9AA0A6),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No customer complaint document attached',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                      Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          const Text(
            'Supported formats: PDF, Word, Excel, PowerPoint, TXT and common image formats.',
            style: TextStyle(
              fontSize: 11,
              color:
              Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

// ============================================================
// PHOTOS
// ============================================================

  Widget _buildPhotos() {
    final savedPhotos =
    _attachments.where(
          (attachment) =>
      attachment['attachment_type']
          ?.toString() ==
          'complaint_photo',
    ).toList();

    return _sectionCard(
      icon:
      Icons.photo_library_outlined,
      title: 'Defect Photograph',
      subtitle:
      'Attach photographs related to the customer complaint.',
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FilledButton.icon(
                onPressed:
                _saving ||
                    _completing
                    ? null
                    : () =>
                    _pickPhoto(
                      ImageSource
                          .gallery,
                    ),
                icon: const Icon(
                  Icons.photo_outlined,
                ),
                label:
                const Text(
                  'Gallery',
                ),
              ),

              const SizedBox(width: 10),

              OutlinedButton.icon(
                onPressed:
                _saving ||
                    _completing
                    ? null
                    : () =>
                    _pickPhoto(
                      ImageSource
                          .camera,
                    ),
                icon: const Icon(
                  Icons.camera_alt_outlined,
                ),
                label:
                const Text(
                  'Camera',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_pendingPhotos.isNotEmpty)
            _buildPendingPhotos(),

          if (savedPhotos.isNotEmpty)
            _buildSavedAttachments(
              savedPhotos,
            ),

          if (_pendingPhotos.isEmpty &&
              savedPhotos.isEmpty)
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(
                25,
              ),
              decoration:
              BoxDecoration(
                color:
                const Color(0xFFF8F9FB),
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
                border: Border.all(
                  color:
                  const Color(0xFFE2E3E7),
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons
                        .image_not_supported_outlined,
                    size: 34,
                    color:
                    Color(0xFF9AA0A6),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No defect photographs attached',
                    style:
                    TextStyle(
                      fontSize: 13,
                      color:
                      Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPendingPhotos() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children:
      List.generate(
        _pendingPhotos.length,
            (index) {
          final photo =
          _pendingPhotos[index];

          return Stack(
            children: [
              ClipRRect(
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
                child: Image.memory(
                  photo.bytes,
                  width: 150,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              ),

              Positioned(
                right: 5,
                top: 5,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _pendingPhotos
                          .removeAt(index);
                    });
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration:
                    const BoxDecoration(
                      color: Colors.black54,
                      shape:
                      BoxShape.circle,
                    ),
                    child:
                    const Icon(
                      Icons.close,
                      size: 17,
                      color:
                      Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSavedAttachments(
      List<Map<String, dynamic>>
      savedPhotos,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        if (_pendingPhotos.isNotEmpty)
          const SizedBox(height: 18),

        const Text(
          'Saved Photos',
          style: TextStyle(
            fontSize: 13,
            fontWeight:
            FontWeight.w700,
            color:
            Color(0xFF202124),
          ),
        ),

        const SizedBox(height: 10),

        ...savedPhotos.map(
              (attachment) {
            final name =
                attachment[
                'original_file_name']
                    ?.toString() ??
                    attachment['title']
                        ?.toString() ??
                    'Attachment';

            return Container(
              margin:
              const EdgeInsets.only(
                bottom: 8,
              ),
              padding:
              const EdgeInsets.all(
                12,
              ),
              decoration:
              BoxDecoration(
                color:
                const Color(0xFFF8F9FB),
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
                border: Border.all(
                  color:
                  const Color(0xFFE2E3E7),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.image_outlined,
                    size: 20,
                    color:
                    Color(0xFF3155C6),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
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
                  const Icon(
                    Icons
                        .check_circle_outline,
                    size: 18,
                    color:
                    Color(0xFF2E9B55),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

// ============================================================
// RESPONSIVE GRID
// ============================================================

  Widget _responsiveFields(
      List<_FieldItem> fields,
      ) {
    return LayoutBuilder(
      builder:
          (context, constraints) {
        final twoColumns =
            constraints.maxWidth >= 850;

        final children =
        <Widget>[];

        for (final field in fields) {
          if (field.fullWidth ||
              !twoColumns) {
            children.add(
              SizedBox(
                width:
                double.infinity,
                child: field.widget,
              ),
            );
          } else {
            children.add(
              SizedBox(
                width:
                (constraints.maxWidth -
                    16) /
                    2,
                child: field.widget,
              ),
            );
          }
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: children,
        );
      },
    );
  }

// ============================================================
// FIELD BUILDERS
// ============================================================

  _FieldItem _textField(
      String label,
      TextEditingController controller, {
        int maxLines = 1,
        bool fullWidth = false,
      }) {
    return _FieldItem(
      fullWidth: fullWidth,
      widget:
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration:
        _inputDecoration(
          label,
        ),
      ),
    );
  }

  _FieldItem _numberField(
      String label,
      TextEditingController controller,
      ) {
    return _FieldItem(
      widget:
      TextFormField(
        controller: controller,
        keyboardType:
        const TextInputType
            .numberWithOptions(
          decimal: true,
        ),
        decoration:
        _inputDecoration(
          label,
        ),
      ),
    );
  }

  _FieldItem _dateField(
      String label,
      TextEditingController controller,
      ) {
    return _FieldItem(
      widget:
      TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () =>
            _selectDate(
              controller,
            ),
        decoration:
        _inputDecoration(
          label,
        ).copyWith(
          suffixIcon:
          const Icon(
            Icons
                .calendar_today_outlined,
            size: 19,
          ),
        ),
      ),
    );
  }

// ============================================================
// INPUT DECORATION
// ============================================================

  InputDecoration _inputDecoration(
      String label,
      ) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior:
      FloatingLabelBehavior.auto,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      border:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          10,
        ),
        borderSide:
        const BorderSide(
          color:
          Color(0xFFE2E3E7),
        ),
      ),
      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          10,
        ),
        borderSide:
        const BorderSide(
          color:
          Color(0xFFE2E3E7),
        ),
      ),
      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          10,
        ),
        borderSide:
        const BorderSide(
          color:
          Color(0xFF3155C6),
          width: 1.4,
        ),
      ),
      labelStyle:
      const TextStyle(
        fontSize: 13,
        color:
        Color(0xFF6B7280),
      ),
    );
  }

// ============================================================
// SECTION CARD
// ============================================================

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return _surfaceCard(
      child: Padding(
        padding:
        const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(
                      0xFFEFF3FF,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color:
                    const Color(
                      0xFF3155C6,
                    ),
                    size: 21,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        title,
                        style:
                        const TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.w800,
                          color:
                          Color(
                            0xFF202124,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
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
              ],
            ),

            const SizedBox(height: 20),

            child,
          ],
        ),
      ),
    );
  }

  Widget _surfaceCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color:
          const Color(0xFFE2E3E7),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 14,
            offset:
            const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _chip(
      String text,
      ) {
    return Container(
      constraints:
      const BoxConstraints(
        maxWidth: 180,
      ),
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFF5F6F8),
        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow:
        TextOverflow.ellipsis,
        style:
        const TextStyle(
          fontSize: 11,
          fontWeight:
          FontWeight.w600,
          color:
          Color(0xFF555A63),
        ),
      ),
    );
  }

// ============================================================
// BOTTOM BAR
// ============================================================

  Widget _buildBottomBar() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.fromLTRB(
        24,
        14,
        24,
        14,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color:
            const Color(
              0xFFE2E3E7,
            ),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 12,
            offset:
            const Offset(0, -4),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 1200,
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed:
                _saving ||
                    _completing
                    ? null
                    : () =>
                    _saveDraft(
                      closeAfterSave:
                      true,
                    ),
                icon: const Icon(
                  Icons.save_outlined,
                ),
                label:
                const Text(
                  'Save Draft',
                ),
              ),

              const Spacer(),

              FilledButton.icon(
                onPressed:
                _saving ||
                    _completing
                    ? null
                    : _completeRegistration,
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
                      .arrow_forward_rounded,
                ),
                label:
                Text(
                  _completing
                      ? 'Completing...'
                      : 'Complete Registration',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _complaintDateController.dispose();
    _complaintSourceController.dispose();
    _customerNameController.dispose();
    _groupNameController.dispose();
    _customerContactNameController.dispose();
    _customerContactPositionController.dispose();
    _customerContactCompanyController.dispose();
    _customerLocationController.dispose();
    _customerPartNumberController.dispose();
    _supplierPartNumberController.dispose();
    _partDescriptionController.dispose();
    _partNoController.dispose();
    _qtyController.dispose();
    _complaintDescriptionController.dispose();
    _problemDescriptionController.dispose();
    _detectedDateController.dispose();
    _detectedByController.dispose();

    super.dispose();
  }
}

// ============================================================
// FIELD ITEM
// ============================================================

class _FieldItem {
  final Widget widget;
  final bool fullWidth;

  const _FieldItem({
    required this.widget,
    this.fullWidth = false,
  });
}

// ============================================================
// PENDING PHOTO
// ============================================================

class _PendingPhoto {
  final Uint8List bytes;
  final String fileName;

  const _PendingPhoto({
    required this.bytes,
    required this.fileName,
  });
}

// ============================================================
// PENDING DOCUMENT
// ============================================================

class _PendingDocument {
  final Uint8List bytes;
  final String fileName;
  final String extension;

  const _PendingDocument({
    required this.bytes,
    required this.fileName,
    required this.extension,
  });
}
