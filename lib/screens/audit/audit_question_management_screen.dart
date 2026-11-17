import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../services/audit/audit_admin_session.dart';

class AuditQuestionManagementScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final String sessionToken;

  const AuditQuestionManagementScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.sessionToken,
  });

  @override
  State<AuditQuestionManagementScreen> createState() =>
      _AuditQuestionManagementScreenState();
}

class _AuditQuestionManagementScreenState
    extends State<AuditQuestionManagementScreen> {
  bool _loading = true;

  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      final result =
      await SupabaseService.getAdminAuditQuestions(
        sessionToken: widget.sessionToken,
        categoryId: widget.categoryId,
      ).timeout(
        const Duration(seconds: 20),
      );

      if (!mounted) return;

      final questions =
      List<Map<String, dynamic>>.from(
        result,
      );

      questions.sort(
            (a, b) {
          final aNumber =
              int.tryParse(
                a['question_number']
                    ?.toString() ??
                    '',
              ) ??
                  0;

          final bNumber =
              int.tryParse(
                b['question_number']
                    ?.toString() ??
                    '',
              ) ??
                  0;

          return aNumber.compareTo(
            bNumber,
          );
        },
      );

      setState(() {
        _questions = questions;
      });
    } catch (e) {
      if (await AuditAdminSession.handleSessionExpired(context, e)) {
        return;
      }
      if (!mounted) return;

      _showError(
        'Unable to load Questions: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _showQuestionDialog({
    Map<String, dynamic>? existing,
  }) async {
    final numberController =
    TextEditingController(
      text:
      existing?['question_number']
          ?.toString() ??
          '',
    );

    final questionController =
    TextEditingController(
      text:
      existing?['question']
          ?.toString() ??
          '',
    );

    final descriptionController =
    TextEditingController(
      text:
      existing?['description']
          ?.toString() ??
          '',
    );

    bool active =
        existing?['active'] as bool? ?? true;

    final bool isEditing =
        existing != null;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          bool saving = false;

          return StatefulBuilder(
            builder: (
                context,
                setDialogState,
                ) {
              Future<void> save() async {
                final questionNumber =
                int.tryParse(
                  numberController.text.trim(),
                );

                final question =
                questionController.text
                    .trim();

                if (questionNumber == null ||
                    questionNumber <= 0) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter a valid Question Number.',
                      ),
                    ),
                  );
                  return;
                }

                if (question.isEmpty) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Question is required.',
                      ),
                    ),
                  );
                  return;
                }

                if (saving) return;

                setDialogState(() {
                  saving = true;
                });

                try {
                  final Map<String, dynamic>
                  result;

                  if (isEditing) {
                    final questionId =
                    existing[
                    'question_id']
                        ?.toString();

                    if (questionId == null ||
                        questionId.isEmpty) {
                      throw Exception(
                        'Question ID is missing.',
                      );
                    }

                    result =
                    await SupabaseService
                        .updateAdminAuditQuestion(
                      sessionToken:
                      widget.sessionToken,
                      questionId:
                      questionId,
                      questionNumber:
                      questionNumber,
                      question: question,
                      description:
                      descriptionController
                          .text
                          .trim()
                          .isEmpty
                          ? null
                          : descriptionController
                          .text
                          .trim(),
                      active: active,
                    ).timeout(
                      const Duration(seconds: 20),
                    );
                  } else {
                    result =
                    await SupabaseService
                        .createAdminAuditQuestion(
                      sessionToken:
                      widget.sessionToken,
                      categoryId:
                      widget.categoryId,
                      questionNumber:
                      questionNumber,
                      question: question,
                      description:
                      descriptionController
                          .text
                          .trim()
                          .isEmpty
                          ? null
                          : descriptionController
                          .text
                          .trim(),
                      active: active,
                    ).timeout(
                      const Duration(seconds: 20),
                    );
                  }

                  if (!mounted) return;

                  final updated =
                  Map<String, dynamic>.from(
                    result,
                  );

                  setState(() {
                    if (isEditing) {
                      final id =
                      updated['question_id']
                          ?.toString();

                      final index =
                      _questions.indexWhere(
                            (row) =>
                        row['question_id']
                            ?.toString() ==
                            id,
                      );

                      if (index >= 0) {
                        _questions[index] =
                            updated;
                      }
                    } else {
                      _questions.add(updated);
                    }

                    _questions.sort(
                          (a, b) {
                        final aNumber =
                            int.tryParse(
                              a['question_number']
                                  ?.toString() ??
                                  '',
                            ) ??
                                0;

                        final bNumber =
                            int.tryParse(
                              b['question_number']
                                  ?.toString() ??
                                  '',
                            ) ??
                                0;

                        return aNumber
                            .compareTo(
                          bNumber,
                        );
                      },
                    );
                  });

                  if (dialogContext.mounted) {
                    Navigator.pop(
                      dialogContext,
                    );
                  }

                  _showMessage(
                    isEditing
                        ? 'Question updated successfully.'
                        : 'Question created successfully.',
                  );
                } catch (e) {
                  if (await AuditAdminSession.handleSessionExpired(context, e)) {
                    return;
                  }
                  if (!dialogContext.mounted) {
                    return;
                  }

                  setDialogState(() {
                    saving = false;
                  });

                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Unable to save Question: $e',
                      ),
                      backgroundColor:
                      Colors.red.shade700,
                    ),
                  );
                }
              }

              return AlertDialog(
                title: Text(
                  isEditing
                      ? 'Edit Question'
                      : 'Create Question',
                ),
                content: SizedBox(
                  width: 650,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        TextField(
                          controller:
                          numberController,
                          enabled: !saving,
                          keyboardType:
                          TextInputType.number,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Question Number',
                            border:
                            OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        TextField(
                          controller:
                          questionController,
                          enabled: !saving,
                          maxLines: 4,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Question',
                            border:
                            OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        TextField(
                          controller:
                          descriptionController,
                          enabled: !saving,
                          maxLines: 4,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Description',
                            border:
                            OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        SwitchListTile(
                          contentPadding:
                          EdgeInsets.zero,
                          title:
                          const Text(
                            'Active',
                          ),
                          value: active,
                          onChanged: saving
                              ? null
                              : (value) {
                            setDialogState(
                                  () {
                                active =
                                    value;
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () =>
                        Navigator.pop(
                          dialogContext,
                        ),
                    child:
                    const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed:
                    saving ? null : save,
                    icon: saving
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(
                      Icons.save_outlined,
                    ),
                    label: Text(
                      saving
                          ? 'Saving...'
                          : 'Save',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      numberController.dispose();
      questionController.dispose();
      descriptionController.dispose();
    }
  }

  Future<void> _deleteQuestion(
      Map<String, dynamic> question,
      ) async {
    final questionId =
    question['question_id']?.toString();

    if (questionId == null ||
        questionId.isEmpty) {
      _showError(
        'Question ID is missing.',
      );
      return;
    }

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
          const Text('Delete Question'),
          content: Text(
            'Delete Question ${question['question_number'] ?? ''}?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                    context,
                    false,
                  ),
              child:
              const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                    context,
                    true,
                  ),
              style:
              FilledButton.styleFrom(
                backgroundColor:
                Colors.red.shade700,
              ),
              child:
              const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await SupabaseService
          .deleteAdminAuditQuestion(
        sessionToken:
        widget.sessionToken,
        questionId: questionId,
      ).timeout(
        const Duration(seconds: 20),
      );

      if (!mounted) return;

      setState(() {
        _questions.removeWhere(
              (row) =>
          row['question_id']
              ?.toString() ==
              questionId,
        );
      });

      _showMessage(
        'Question deleted successfully.',
      );
    } catch (e) {
      if (await AuditAdminSession.handleSessionExpired(context, e)) {
        return;
      }
      if (!mounted) return;

      _showError(
        'Unable to delete Question: $e',
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        Colors.red.shade700,
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Questions • ${widget.categoryName}',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
            _loading ? null : _loadQuestions,
            icon:
            const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton:
      FloatingActionButton.extended(
        onPressed:
        _loading
            ? null
            : () =>
            _showQuestionDialog(),
        icon:
        const Icon(Icons.add),
        label:
        const Text('Add Question'),
      ),
      body: _loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : _questions.isEmpty
          ? const Center(
        child: Padding(
          padding:
          EdgeInsets.all(24),
          child: Text(
            'No questions are configured for this category.',
            textAlign:
            TextAlign.center,
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh:
        _loadQuestions,
        child: ListView.builder(
          padding:
          const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            100,
          ),
          itemCount:
          _questions.length,
          itemBuilder:
              (context, index) {
            final question =
            _questions[index];

            final number =
                question[
                'question_number']
                    ?.toString() ??
                    '';

            final text =
                question['question']
                    ?.toString() ??
                    '';

            final description =
                question[
                'description']
                    ?.toString() ??
                    '';

            final active =
                question['active']
                as bool? ??
                    true;

            return Card(
              margin:
              const EdgeInsets.only(
                bottom: 12,
              ),
              child: Padding(
                padding:
                const EdgeInsets.all(
                  16,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .stretch,
                  children: [
                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        CircleAvatar(
                          child:
                          Text(
                            number,
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Text(
                            text,
                            style:
                            const TextStyle(
                              fontSize: 17,
                              fontWeight:
                              FontWeight
                                  .w700,
                            ),
                          ),
                        ),
                        Chip(
                          label:
                          Text(
                            active
                                ? 'Active'
                                : 'Inactive',
                          ),
                        ),
                        PopupMenuButton<
                            String>(
                          onSelected:
                              (value) {
                            if (value ==
                                'edit') {
                              _showQuestionDialog(
                                existing:
                                question,
                              );
                            } else if (value ==
                                'delete') {
                              _deleteQuestion(
                                question,
                              );
                            }
                          },
                          itemBuilder:
                              (context) =>
                          const [
                            PopupMenuItem(
                              value:
                              'edit',
                              child: Text(
                                'Edit',
                              ),
                            ),
                            PopupMenuItem(
                              value:
                              'delete',
                              child: Text(
                                'Delete',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (description
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        description,
                        style:
                        TextStyle(
                          color: Colors
                              .grey
                              .shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}