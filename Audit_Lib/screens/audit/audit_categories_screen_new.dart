import 'package:flutter/material.dart';

import '../../models/audit/audit_model_new.dart';
import '../../models/audit/audit_section_model_new.dart';

import '../../services/audit/audit_service_new.dart';

import 'audit_checklist_screen_new.dart';
import 'audit_summary_screen_new.dart';


class NewAuditCategoriesScreen extends StatefulWidget {
  final AuditModelNew audit;

  const NewAuditCategoriesScreen({
    super.key,
    required this.audit,
  });

  @override
  State<NewAuditCategoriesScreen> createState() =>
      _NewAuditCategoriesScreenState();
}

class _NewAuditCategoriesScreenState
    extends State<NewAuditCategoriesScreen> {
  final AuditServiceNew _service =
  AuditServiceNew();

  bool loading = true;

  List<AuditSectionModelNew> sections = [];

  Map<String, int> answeredByCategory = {};

  Map<String, int> totalByCategory = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
    });

    try {
      final loadedSections =
      await _service.getSections(
        widget.audit.auditType,
      );

      final answers =
      await _service.getAnswers(
        widget.audit.auditId,
      );

      final answeredMap = <String, int>{};
      final totalMap = <String, int>{};

      for (final section in loadedSections) {
        final questions =
        await _service.getQuestions(
          section.sectionId,
        );

        totalMap[section.sectionName] =
            questions.length;

        final questionIds = questions
            .map(
              (question) =>
              question.questionId.toString(),
        )
            .toSet();

        final answered = answers.where(
              (answer) {
            final questionId =
            answer.checklistItemId.toString();

            return questionIds.contains(questionId) &&
                answer.answer.trim().isNotEmpty;
          },
        ).length;

        answeredMap[section.sectionName] =
            answered;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        sections = loadedSections;
        answeredByCategory = answeredMap;
        totalByCategory = totalMap;
        loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load audit categories: $e',
          ),
        ),
      );
    }
  }

  bool _isCategoryComplete(
      AuditSectionModelNew section,
      ) {
    final total =
        totalByCategory[section.sectionName] ?? 0;

    final answered =
        answeredByCategory[section.sectionName] ?? 0;

    return total > 0 && answered >= total;
  }

  Future<void> _openCategory(
      AuditSectionModelNew section,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AuditChecklistScreenNew(
              auditId: widget.audit.auditId,
              auditType: widget.audit.auditType,
              section: section,
            ),
      ),
    );

    await _load();
  }

  bool get _allCategoriesComplete {
    if (sections.isEmpty) {
      return false;
    }

    return sections.every(
      _isCategoryComplete,
    );
  }

  int get _completedCategories {
    return sections
        .where(_isCategoryComplete)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Audit Categories',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor:
        const Color(0xFF172033),
        elevation: 0,
      ),
      body: loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (sections.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No categories configured for this audit type.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Audit Categories',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            widget.audit.auditType,
            style: const TextStyle(
              color: Color(0xFF707784),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 20),

          _buildOverallProgress(),

          const SizedBox(height: 20),

          ...sections.map(
                (section) =>
                _buildCategoryCard(section),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed:
              _allCategoriesComplete
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AuditSummaryScreenNew(
                          auditId:
                          widget.audit.auditId,
                          auditType:
                          widget.audit.auditType,
                        ),
                  ),
                );
              }
                  : null,
              icon: const Icon(
                Icons.check_circle_outline,
              ),
              label: Text(
                _allCategoriesComplete
                    ? 'Complete Audit'
                    : 'Complete All Categories First',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallProgress() {
    final total = sections.length;

    final completed =
        _completedCategories;

    final value = total == 0
        ? 0.0
        : completed / total;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(14),
        side: const BorderSide(
          color: Color(0xFFE3E7EE),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Overall Progress',
                    style: TextStyle(
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$completed/$total',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Theme.of(context)
                        .colorScheme
                        .primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            LinearProgressIndicator(
              value: value,
              minHeight: 8,
              borderRadius:
              BorderRadius.circular(20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
      AuditSectionModelNew section,
      ) {
    final total =
        totalByCategory[section.sectionName] ??
            0;

    final answered =
        answeredByCategory[
        section.sectionName] ??
            0;

    final complete =
    _isCategoryComplete(section);

    final value = total == 0
        ? 0.0
        : answered / total;

    return Card(
      elevation: 0,
      margin:
      const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(14),
        side: const BorderSide(
          color: Color(0xFFE3E7EE),
        ),
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(14),
        onTap: () =>
            _openCategory(section),
        child: Padding(
          padding:
          const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      section.sectionName,
                      style:
                      const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  ),

                  Icon(
                    complete
                        ? Icons.check_circle
                        : Icons
                        .radio_button_unchecked,
                    color: complete
                        ? Colors.green
                        : Colors.grey,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child:
                    LinearProgressIndicator(
                      value: value,
                      minHeight: 7,
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Text(
                    '$answered/$total',
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}