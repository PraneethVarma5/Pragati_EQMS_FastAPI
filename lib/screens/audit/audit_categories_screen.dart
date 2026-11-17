import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';

class AuditCategoriesScreen extends StatefulWidget {
  final String auditId;

  const AuditCategoriesScreen({
    super.key,
    required this.auditId,
  });

  @override
  State<AuditCategoriesScreen> createState() =>
      _AuditCategoriesScreenState();
}

class _AuditCategoriesScreenState
    extends State<AuditCategoriesScreen> {
  List<Map<String, dynamic>> _categories = [];

  Map<String, Map<String, dynamic>>
  _progressByCategory = {};

  Map<String, dynamic>? _audit;

  bool _loading = true;
  bool _saving = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      final audit =
      await SupabaseService.getAuditById(
        widget.auditId,
      ).timeout(
        const Duration(seconds: 20),
      );

      if (audit == null) {
        throw Exception(
          'Audit not found.',
        );
      }

      final typeId =
      audit['type_id']?.toString();

      if (typeId == null ||
          typeId.isEmpty) {
        throw Exception(
          'Audit Type is missing for this audit.',
        );
      }

      final categories =
      await SupabaseService
          .getAuditCategories(
        typeId,
      ).timeout(
        const Duration(seconds: 20),
      );

      final progress =
      await SupabaseService
          .getAuditCategoryProgress(
        widget.auditId,
      ).timeout(
        const Duration(seconds: 20),
      );

      final progressMap =
      <String, Map<String, dynamic>>{};

      for (final row in progress) {
        final categoryId =
        row['category_id']?.toString();

        if (categoryId != null &&
            categoryId.isNotEmpty) {
          progressMap[categoryId] =
          Map<String, dynamic>.from(
            row,
          );
        }
      }

      // ----------------------------------------------------------
      // Ensure every active category has a progress record.
      // ----------------------------------------------------------

      for (final category in categories) {
        final categoryId =
        category['category_id']
            ?.toString();

        if (categoryId == null ||
            categoryId.isEmpty) {
          continue;
        }

        if (!progressMap.containsKey(
          categoryId,
        )) {
          final created =
          await SupabaseService
              .createAuditCategoryProgress(
            auditId: widget.auditId,
            categoryId: categoryId,
          ).timeout(
            const Duration(seconds: 20),
          );

          progressMap[categoryId] =
              created;
        }
      }

      if (!mounted) return;

      setState(() {
        _audit = audit;
        _categories = categories;
        _progressByCategory =
            progressMap;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showError(
        'Unable to load categories: $e',
      );
    }
  }

  // ============================================================
  // CATEGORY COMPLETION
  // ============================================================

  bool _isCompleted(
      String categoryId,
      ) {
    return _progressByCategory[
    categoryId]
    ?['completed'] ==
        true;
  }

  // ============================================================
  // OPEN CATEGORY
  // ============================================================

  Future<void> _openCategory(
      Map<String, dynamic> category,
      ) async {
    final categoryId =
    category['category_id']
        ?.toString();

    if (categoryId == null ||
        categoryId.isEmpty) {
      _showError(
        'Category ID is missing.',
      );
      return;
    }

    await Navigator.pushNamed(
      context,
      '/AUDIT/checklist',
      arguments: {
        'auditId': widget.auditId,
        'categoryId': categoryId,
      },
    );

    if (!mounted) return;

    await _loadData();
  }

  // ============================================================
  // SAVE PROGRESS
  // ============================================================

  Future<void> _saveProgress() async {
    if (_saving ||
        _submitting) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      // Checklist answers are already persisted
      // while the user works.
      //
      // Refreshing here ensures that the category
      // completion state displayed on this screen
      // matches the database.

      await _loadData();

      if (!mounted) return;

      _showMessage(
        'Audit progress saved.',
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Unable to save progress: $e',
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
  // SUBMIT AUDIT
  // ============================================================

  Future<void> _submitAudit() async {
    if (_submitting ||
        _saving) {
      return;
    }

    final completedCount =
        _categories.where(
              (category) {
            final id =
            category['category_id']
                ?.toString();

            if (id == null ||
                id.isEmpty) {
              return false;
            }

            return _isCompleted(id);
          },
        ).length;

    final allCategoriesCompleted =
        _categories.isNotEmpty &&
            completedCount ==
                _categories.length;

    if (!allCategoriesCompleted) {
      _showError(
        'Complete all categories before submitting the audit.',
      );
      return;
    }

    // ----------------------------------------------------------
    // Confirm submission
    // ----------------------------------------------------------

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Submit Audit',
          ),
          content: const Text(
            'All audit categories are completed. '
                'Once submitted, the audit will move to the '
                'MIL Report stage.',
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
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              icon: const Icon(
                Icons.check_circle_outline,
              ),
              label: const Text(
                'Submit Audit',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _submitting = true;
    });

    try {
      // ----------------------------------------------------------
      // Database function validates:
      //
      // 1. Every active category is complete
      // 2. Every active question is answered
      // 3. Every No has description
      // 4. Every No has defect type
      // 5. Audit is changed to Submitted
      // 6. MIL items are generated
      // ----------------------------------------------------------

      final success =
      await SupabaseService
          .submitAudit(
        widget.auditId,
      ).timeout(
        const Duration(seconds: 30),
      );

      if (!success) {
        throw Exception(
          'Audit submission was not completed.',
        );
      }

      if (!mounted) return;

      // ----------------------------------------------------------
      // Refresh audit state from database.
      // ----------------------------------------------------------

      final updatedAudit =
      await SupabaseService.getAuditById(
        widget.auditId,
      ).timeout(
        const Duration(seconds: 20),
      );

      if (!mounted) return;

      setState(() {
        _audit = updatedAudit;
        _submitting = false;
      });

      _showMessage(
        'Audit submitted successfully. Opening MIL Report...',
      );

      // ----------------------------------------------------------
      // Open MIL Report automatically.
      // ----------------------------------------------------------

      await Future.delayed(
        const Duration(
          milliseconds: 500,
        ),
      );

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/AUDIT/mil',
        arguments: widget.auditId,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
      });

      _showError(
        'Unable to submit audit: $e',
      );
    }
  }

  // ============================================================
  // OPEN MIL REPORT
  // ============================================================

  void _openMilReport() {
    Navigator.pushNamed(
      context,
      '/AUDIT/mil',
      arguments: widget.auditId,
    );
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(
      String message,
      ) {
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

  // ============================================================
  // SHOW ERROR
  // ============================================================

  void _showError(
      String message,
      ) {
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

  // ============================================================
  // STATUS HELPERS
  // ============================================================

  String _auditStatus() {
    return _audit?['status']
        ?.toString() ??
        'Draft';
  }

  bool _isSubmitted() {
    final status =
    _auditStatus();

    return status ==
        'Submitted' ||
        status == 'Completed';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final completedCount =
        _categories.where(
              (category) {
            final id =
            category['category_id']
                ?.toString();

            if (id == null ||
                id.isEmpty) {
              return false;
            }

            return _isCompleted(id);
          },
        ).length;

    final totalCategories =
        _categories.length;

    final allCategoriesCompleted =
        totalCategories > 0 &&
            completedCount ==
                totalCategories;

    final submitted =
    _isSubmitted();

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'Audit Categories',
          style: TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
            _loading ||
                _saving ||
                _submitting
                ? null
                : _loadData,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: _loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 1100,
          ),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .stretch,

            children: [
              // ==================================================
              // AUDIT PROGRESS CARD
              // ==================================================

              Padding(
                padding:
                const EdgeInsets
                    .fromLTRB(
                  20,
                  20,
                  20,
                  10,
                ),

                child: Card(
                  elevation: 0,

                  child: Padding(
                    padding:
                    const EdgeInsets
                        .all(
                      18,
                    ),

                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons
                                  .fact_check_outlined,
                              size: 32,
                            ),

                            const SizedBox(
                              width: 14,
                            ),

                            Expanded(
                              child:
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                                children: [
                                  const Text(
                                    'Audit Progress',
                                    style:
                                    TextStyle(
                                      fontSize:
                                      20,
                                      fontWeight:
                                      FontWeight
                                          .w800,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 4,
                                  ),

                                  Text(
                                    '$completedCount / $totalCategories categories completed',
                                    style:
                                    TextStyle(
                                      color: Colors
                                          .grey
                                          .shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ------------------------------------------------
                            // SAVE PROGRESS
                            // ------------------------------------------------

                            OutlinedButton.icon(
                              onPressed:
                              _saving ||
                                  _submitting
                                  ? null
                                  : _saveProgress,

                              icon: _saving
                                  ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                CircularProgressIndicator(
                                  strokeWidth:
                                  2,
                                ),
                              )
                                  : const Icon(
                                Icons
                                    .save_outlined,
                              ),

                              label:
                              Text(
                                _saving
                                    ? 'Saving...'
                                    : 'Save Progress',
                              ),
                            ),
                          ],
                        ),

                        // ==================================================
                        // SUBMISSION SECTION
                        // ==================================================

                        // if (allCategoriesCompleted ||
                        //     submitted) ...[
                        //   const SizedBox(
                        //     height: 18,
                        //   ),
                        //
                        //   const Divider(
                        //     height: 1,
                        //   ),
                        //
                        //   const SizedBox(
                        //     height: 18,
                        //   ),
                        //
                        //   Container(
                        //     width:
                        //     double.infinity,
                        //
                        //     padding:
                        //     const EdgeInsets
                        //         .all(
                        //       14,
                        //     ),
                        //
                        //     decoration:
                        //     BoxDecoration(
                        //       color:
                        //       const Color(
                        //         0xFFF8F5FC,
                        //       ),
                        //
                        //       borderRadius:
                        //       BorderRadius
                        //           .circular(
                        //         10,
                        //       ),
                        //
                        //       border:
                        //       Border.all(
                        //         color:
                        //         const Color(
                        //           0xFFE3D8F5,
                        //         ),
                        //       ),
                        //     ),
                        //
                        //     child: Row(
                        //       children: [
                        //         Container(
                        //           width: 42,
                        //           height: 42,
                        //           decoration:
                        //           BoxDecoration(
                        //             color:
                        //             const Color(
                        //               0xFFEDE3FF,
                        //             ),
                        //             borderRadius:
                        //             BorderRadius
                        //                 .circular(
                        //               10,
                        //             ),
                        //           ),
                        //           child:
                        //           Icon(
                        //             submitted
                        //                 ? Icons
                        //                 .check_circle_outline
                        //                 : Icons
                        //                 .task_alt_outlined,
                        //             color:
                        //             const Color(
                        //               0xFF7655B7,
                        //             ),
                        //           ),
                        //         ),
                        //
                        //         const SizedBox(
                        //           width: 12,
                        //         ),
                        //
                        //         Expanded(
                        //           child:
                        //           Column(
                        //             crossAxisAlignment:
                        //             CrossAxisAlignment
                        //                 .start,
                        //             children: [
                        //               Text(
                        //                 submitted
                        //                     ? 'Audit Submitted'
                        //                     : 'All Categories Completed',
                        //                 style:
                        //                 const TextStyle(
                        //                   fontWeight:
                        //                   FontWeight
                        //                       .w700,
                        //                   fontSize:
                        //                   15,
                        //                 ),
                        //               ),
                        //
                        //               const SizedBox(
                        //                 height: 3,
                        //               ),
                        //
                        //               Text(
                        //                 submitted
                        //                     ? 'The audit is ready for MIL Report.'
                        //                     : 'Submit the audit to generate the MIL Report.',
                        //                 style:
                        //                 TextStyle(
                        //                   fontSize:
                        //                   12,
                        //                   color: Colors
                        //                       .grey
                        //                       .shade700,
                        //                 ),
                        //               ),
                        //             ],
                        //           ),
                        //         ),
                        //
                        //         const SizedBox(
                        //           width: 12,
                        //         ),
                        //
                        //         if (!submitted)
                        //           ElevatedButton.icon(
                        //             onPressed:
                        //             _submitting
                        //                 ? null
                        //                 : _submitAudit,
                        //
                        //             icon: _submitting
                        //                 ? const SizedBox(
                        //               width: 17,
                        //               height: 17,
                        //               child:
                        //               CircularProgressIndicator(
                        //                 strokeWidth:
                        //                 2,
                        //               ),
                        //             )
                        //                 : const Icon(
                        //               Icons
                        //                   .check_circle_outline,
                        //             ),
                        //
                        //             label:
                        //             Text(
                        //               _submitting
                        //                   ? 'Submitting...'
                        //                   : 'Submit Audit',
                        //             ),
                        //           )
                        //         else
                        //           ElevatedButton.icon(
                        //             onPressed:
                        //             _openMilReport,
                        //
                        //             icon:
                        //             const Icon(
                        //               Icons
                        //                   .arrow_forward,
                        //             ),
                        //
                        //             label:
                        //             const Text(
                        //               'Open MIL Report',
                        //             ),
                        //           ),
                        //       ],
                        //     ),
                        //   ),
                        // ],
                      ],
                    ),
                  ),
                ),
              ),

              // ==================================================
              // CATEGORY LIST
              // ==================================================

              Expanded(
                child:
                _categories.isEmpty
                    ? const Center(
                  child:
                  Padding(
                    padding:
                    EdgeInsets
                        .all(
                      24,
                    ),
                    child:
                    Text(
                      'No active categories are configured for this Audit Type.',
                      textAlign:
                      TextAlign
                          .center,
                    ),
                  ),
                )
                    : RefreshIndicator(
                  onRefresh:
                  _loadData,

                  child:
                  ListView
                      .builder(
                    padding:
                    const EdgeInsets
                        .fromLTRB(
                      20,
                      10,
                      20,
                      30,
                    ),

                    itemCount:
                    _categories
                        .length,

                    itemBuilder:
                        (
                        context,
                        index,
                        ) {
                      final category =
                      _categories[
                      index];

                      final id =
                      category[
                      'category_id']
                          ?.toString();

                      final name =
                          category[
                          'category_name']
                              ?.toString() ??
                              '';

                      final description =
                          category[
                          'description']
                              ?.toString() ??
                              '';

                      final completed =
                          id !=
                              null &&
                              _isCompleted(
                                id,
                              );

                      return Card(
                        elevation:
                        0,

                        margin:
                        const EdgeInsets
                            .only(
                          bottom:
                          12,
                        ),

                        child:
                        ListTile(
                          contentPadding:
                          const EdgeInsets
                              .symmetric(
                            horizontal:
                            18,
                            vertical:
                            8,
                          ),

                          leading:
                          CircleAvatar(
                            child:
                            Text(
                              '${index + 1}',
                            ),
                          ),

                          title:
                          Text(
                            name,
                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight
                                  .w700,
                            ),
                          ),

                          subtitle:
                          description
                              .trim()
                              .isEmpty
                              ? null
                              : Text(
                            description,
                          ),

                          trailing:
                          Row(
                            mainAxisSize:
                            MainAxisSize
                                .min,
                            children: [
                              Chip(
                                label:
                                Text(
                                  completed
                                      ? 'Completed'
                                      : 'Pending',
                                ),
                              ),

                              const SizedBox(
                                width:
                                8,
                              ),

                              const Icon(
                                Icons
                                    .chevron_right,
                              ),
                            ],
                          ),

                          onTap:
                              () =>
                              _openCategory(
                                category,
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // ============================================================
// SUBMIT AUDIT
// ============================================================

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  24,
                ),
                child: _buildSubmitButton(
                  allCategoriesCompleted:
                  allCategoriesCompleted,
                  submitted: submitted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ============================================================
// SUBMIT BUTTON
// ============================================================

  Widget _buildSubmitButton({
    required bool allCategoriesCompleted,
    required bool submitted,
  }) {
    if (submitted) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _submitting
              ? null
              : _openMilReport,
          icon: const Icon(
            Icons.arrow_forward,
          ),
          label: const Padding(
            padding: EdgeInsets.symmetric(
              vertical: 14,
            ),
            child: Text(
              'Open MIL Report',
            ),
          ),
        ),
      );
    }

    final bool enabled =
        allCategoriesCompleted &&
            !_submitting &&
            !_saving;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _submitting
            ? null
            : () {
          if (!allCategoriesCompleted) {
            _showError(
              'Complete all categories to continue',
            );
            return;
          }

          _submitAudit();
        },

        style: OutlinedButton.styleFrom(
          minimumSize:
          const Size(
            double.infinity,
            52,
          ),

          foregroundColor: enabled
              ? const Color(0xFF7655B7)
              : const Color(0xFF8B8F98),

          side: BorderSide(
            color: enabled
                ? const Color(0xFF7655B7)
                : const Color(0xFFD0D3D8),
            width: 1.2,
          ),

          backgroundColor: enabled
              ? const Color(0xFFF7F2FF)
              : const Color(0xFFF0F1F3),

          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              10,
            ),
          ),
        ),

        icon: _submitting
            ? const SizedBox(
          width: 18,
          height: 18,
          child:
          CircularProgressIndicator(
            strokeWidth: 2,
          ),
        )
            : Icon(
          Icons
              .check_circle_outline,
        ),

        label: Text(
          _submitting
              ? 'Submitting...'
              : 'Submit Audit',
          style: const TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),
      ),
    );
  }
}