import 'package:flutter/material.dart';

import '../../models/ncr/ncr_user.dart';
import '../../services/ncr/ncr_service.dart';
import '../../services/ncr/ncr_session.dart';

class NcrCreateScreen extends StatefulWidget {
  const NcrCreateScreen({super.key});

  @override
  State<NcrCreateScreen> createState() =>
      _NcrCreateScreenState();
}

class _NcrCreateScreenState
    extends State<NcrCreateScreen> {
  final _formKey =
  GlobalKey<FormState>();

  final _processController =
  TextEditingController();

  final _clauseController =
  TextEditingController();

  final _standardController =
  TextEditingController();

  final _iaNoController =
  TextEditingController();

  final _findingController =
  TextEditingController();

  final _requirementController =
  TextEditingController();

  List<NcrUser> _users = [];

  NcrUser? _selectedAuditee;
  NcrUser? _selectedAuditor;

  DateTime? _selectedDate;

  bool _loadingUsers = true;
  bool _saving = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _loadUsers();
  }

  @override
  void dispose() {
    _processController.dispose();
    _clauseController.dispose();
    _standardController.dispose();
    _iaNoController.dispose();
    _findingController.dispose();
    _requirementController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD USERS
  // ============================================================

  Future<void> _loadUsers() async {
    try {
      final users =
      await NcrService.getActiveUsers();

      if (!mounted) {
        return;
      }

      setState(() {
        _users = users;
        _loadingUsers = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingUsers = false;
        _errorMessage =
            e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final selected =
    await showDatePicker(
      context: context,
      initialDate:
      _selectedDate ?? now,
      firstDate:
      DateTime(2000),
      lastDate:
      DateTime(2100),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _selectedDate = selected;
    });
  }

  // ============================================================
  // CREATE NCR
  // ============================================================

  Future<void> _createNcr() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAuditee == null) {
      _showError(
        'Please select the Auditee.',
      );
      return;
    }

    if (_selectedAuditor == null) {
      _showError(
        'Please select the Auditor.',
      );
      return;
    }

    if (_selectedDate == null) {
      _showError(
        'Please select the Audit Date.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final ncr =
      await NcrService.createNcr(
        processFunction:
        _processController.text,

        clauseSection:
        _clauseController.text,

        auditeeId:
        _selectedAuditee!.id,

        standard:
        _standardController.text,

        iaNo:
        _iaNoController.text,

        auditorId:
        _selectedAuditor!.id,

        auditDate:
        _selectedDate!,

        findingStatement:
        _findingController.text,

        requirementClauseReference:
        _requirementController.text,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'NCR ${ncr.reportNo.isEmpty ? ncr.ncrNumber : ncr.reportNo} created successfully.',
            ),
            behavior:
            SnackBarBehavior.floating,
          ),
        );

      Navigator.pop(
        context,
        ncr,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
        _errorMessage =
            e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // FIELD
  // ============================================================

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border:
        const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return '$label is required.';
        }

        return null;
      },
    );
  }

  // ============================================================
  // USER DROPDOWN
  // ============================================================

  Widget _userDropdown({
    required String label,
    required IconData icon,
    required NcrUser? value,
    required ValueChanged<NcrUser?> onChanged,
  }) {
    return DropdownButtonFormField<NcrUser>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border:
        const OutlineInputBorder(),
      ),
      items: _users.map(
            (user) {
          return DropdownMenuItem<NcrUser>(
            value: user,
            child: Text(
              '${user.fullName} (${user.email})',
              overflow:
              TextOverflow.ellipsis,
            ),
          );
        },
      ).toList(),
      onChanged:
      _loadingUsers ? null : onChanged,
      validator: (value) {
        if (value == null) {
          return '$label is required.';
        }

        return null;
      },
    );
  }

  // ============================================================
  // DATE FIELD
  // ============================================================

  Widget _dateField() {
    final dateText =
    _selectedDate == null
        ? ''
        : '${_selectedDate!.day.toString().padLeft(2, '0')}/'
        '${_selectedDate!.month.toString().padLeft(2, '0')}/'
        '${_selectedDate!.year}';

    return InkWell(
      onTap:
      _saving ? null : _pickDate,
      borderRadius:
      BorderRadius.circular(4),
      child: InputDecorator(
        decoration:
        const InputDecoration(
          labelText: 'Date',
          prefixIcon:
          Icon(Icons.calendar_today),
          border:
          OutlineInputBorder(),
        ),
        child: Text(
          dateText.isEmpty
              ? 'Select audit date'
              : dateText,
          style: TextStyle(
            color: dateText.isEmpty
                ? Colors.grey.shade600
                : Colors.black87,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _section({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xFFE2E7EF),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final currentUser =
        NcrSession.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    if (!NcrSession.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title:
          const Text('Raise New NCR'),
        ),
        body: const Center(
          child: Text(
            'Only an NCR Admin can create an NCR.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
        Colors.white,
        surfaceTintColor:
        Colors.white,
        title: const Text(
          'Raise New NCR',
          style: TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),
      ),

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.all(28),
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
                  // ==================================================
                  // HEADER
                  // ==================================================

                  const Text(
                    'Create Non-Conformance Report',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight:
                      FontWeight.w800,
                      color:
                      Color(0xFF172033),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Enter the audit finding and assign the NCR to the responsible NCR users.',
                    style: TextStyle(
                      color:
                      Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // ERROR
                  // ==================================================

                  if (_errorMessage != null)
                    Container(
                      width:
                      double.infinity,
                      margin:
                      const EdgeInsets.only(
                        bottom: 20,
                      ),
                      padding:
                      const EdgeInsets.all(
                        16,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        Colors.red.shade50,
                        borderRadius:
                        BorderRadius.circular(
                          12,
                        ),
                        border:
                        Border.all(
                          color:
                          Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color:
                            Colors.red.shade700,
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color:
                                Colors.red.shade800,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ==================================================
                  // AUDIT INFORMATION
                  // ==================================================

                  _section(
                    title:
                    'Audit Information',
                    child:
                    LayoutBuilder(
                      builder:
                          (
                          context,
                          constraints,
                          ) {
                        final twoColumns =
                            constraints
                                .maxWidth >=
                                700;

                        final fields =
                        [
                          _field(
                            controller:
                            _processController,
                            label:
                            'Process / Function',
                            icon:
                            Icons.account_tree_outlined,
                          ),

                          _field(
                            controller:
                            _clauseController,
                            label:
                            'Clause / Section',
                            icon:
                            Icons.article_outlined,
                          ),

                          _field(
                            controller:
                            _standardController,
                            label:
                            'Standard(s)',
                            icon:
                            Icons.menu_book_outlined,
                          ),

                          _field(
                            controller:
                            _iaNoController,
                            label:
                            'IA No',
                            icon:
                            Icons.numbers,
                          ),

                          _userDropdown(
                            label:
                            'Auditee Name',
                            icon:
                            Icons.person_outline,
                            value:
                            _selectedAuditee,
                            onChanged:
                                (value) {
                              setState(() {
                                _selectedAuditee =
                                    value;
                              });
                            },
                          ),

                          _userDropdown(
                            label:
                            'Auditor Name',
                            icon:
                            Icons.person_search_outlined,
                            value:
                            _selectedAuditor,
                            onChanged:
                                (value) {
                              setState(() {
                                _selectedAuditor =
                                    value;
                              });
                            },
                          ),

                          _dateField(),
                        ];

                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children:
                          fields.map(
                                (field) {
                              return SizedBox(
                                width:
                                twoColumns
                                    ? (constraints.maxWidth -
                                    16) /
                                    2
                                    : constraints
                                    .maxWidth,
                                child:
                                field,
                              );
                            },
                          ).toList(),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // FINDING
                  // ==================================================

                  _section(
                    title:
                    'Non-Conformity Details',
                    child: Column(
                      children: [
                        _field(
                          controller:
                          _findingController,
                          label:
                          'Audit Finding / Nonconformity Statement',
                          icon:
                          Icons.warning_amber_outlined,
                          maxLines: 6,
                          hint:
                          'Enter the observed non-conformity...',
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        _field(
                          controller:
                          _requirementController,
                          label:
                          'Requirement / Clause Reference',
                          icon:
                          Icons.rule_outlined,
                          maxLines: 4,
                          hint:
                          'Enter the applicable requirement or clause reference...',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // AUTOMATIC NUMBER INFO
                  // ==================================================

                  Container(
                    width:
                    double.infinity,
                    padding:
                    const EdgeInsets.all(
                      18,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      const Color(0xFFEFF7FF),
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                      border:
                      Border.all(
                        color:
                        const Color(0xFFD7E9FA),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color:
                          Color(0xFF3155D9),
                        ),
                        SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Text(
                            'Report No. will be generated automatically by the database when the NCR is created.',
                            style:
                            TextStyle(
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // BUTTONS
                  // ==================================================

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed:
                        _saving
                            ? null
                            : () {
                          Navigator.pop(
                            context,
                          );
                        },
                        child:
                        const Text(
                          'Cancel',
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      FilledButton.icon(
                        onPressed:
                        _saving
                            ? null
                            : _createNcr,
                        icon:
                        _saving
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                          CircularProgressIndicator(
                            strokeWidth:
                            2,
                          ),
                        )
                            : const Icon(
                          Icons
                              .add_task,
                        ),
                        label: Text(
                          _saving
                              ? 'Creating...'
                              : 'Create NCR',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}