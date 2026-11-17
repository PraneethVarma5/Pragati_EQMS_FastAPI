import 'package:flutter/material.dart';

import '../../models/audit/audit_answer_model_new.dart';
import '../../models/audit/audit_question_model_new.dart';
import '../../models/audit/audit_section_model_new.dart';
import '../../services/audit/audit_service_new.dart';
import '../../widgets/audit/audit_question_card_new.dart';

class AuditChecklistScreenNew
    extends StatefulWidget {
  final dynamic auditId;
  final String auditType;
  final AuditSectionModelNew section;

  const AuditChecklistScreenNew({
    super.key,
    required this.auditId,
    required this.auditType,
    required this.section,
  });

  @override
  State<AuditChecklistScreenNew> createState() =>
      _AuditChecklistScreenNewState();
}
class _AuditChecklistScreenNewState
    extends State<AuditChecklistScreenNew> {
  final AuditServiceNew _service = AuditServiceNew();

  List<AuditQuestionModelNew> _questions = [];
  Map<String, AuditAnswerModelNew> _answers = {};

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });

    try {
      final questions = await _service.getQuestions(
        widget.section.sectionId,
      );

      final answers = await _service.getAnswers(
        widget.auditId,
      );

      final answerMap = <String, AuditAnswerModelNew>{};

      for (final answer in answers) {
        answerMap[answer.checklistItemId.toString()] = answer;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _questions = questions;
        _answers = answerMap;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load checklist: $e'),
        ),
      );
    }
  }

  Future<void> _saveQuestion(
      AuditQuestionModelNew question,
      String answer,
      String description,
      String defect,
      String finding,
      String findingType,
      ) async {
    try {
      await _service.saveAnswer(
        auditId: widget.auditId,
        checklistItemId: question.questionId,
        auditType: widget.auditType,
        category: widget.section.sectionName,
        question: question.questionText,
        answer: answer,
        description: description,
        defect: defect,
        finding: finding,
        findingType: findingType,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save answer: $e'),
        ),
      );
    }
  }

  Future<void> _saveAll() async {
    setState(() {
      _saving = true;
    });

    try {
      for (final question in _questions) {
        final key = question.questionId.toString();
        final existing = _answers[key];

        await _service.saveAnswer(
          auditId: widget.auditId,
          checklistItemId: question.questionId,
          auditType: widget.auditType,
          category: widget.section.sectionName,
          question: question.questionText,
          answer: existing?.answer ?? '',
          description: existing?.description ?? '',
          defect: existing?.defect ?? '',
          finding: existing?.finding ?? '',
          findingType: existing?.findingType ?? '',
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checklist saved successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save checklist: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  int get _answeredCount {
    return _questions.where((question) {
      final answer = _answers[question.questionId.toString()];

      return answer != null &&
          answer.answer.trim().isNotEmpty;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final total = _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.section.sectionName),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Column(
        children: [
          _buildProgress(total),

          Expanded(
            child: _questions.isEmpty
                ? const Center(
              child: Text(
                'No questions are configured for this category.',
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];

                final existing = _answers[
                question.questionId.toString()];

                return AuditQuestionCardNew(
                  question: question,
                  answer: existing?.answer ?? '',
                  description:
                  existing?.description ?? '',
                  defect: existing?.defect ?? '',
                  finding: existing?.finding ?? '',
                  findingType:
                  existing?.findingType ?? '',
                  onAnswerChanged: (value) {
                    _updateAnswer(
                      question,
                      answer: value,
                    );
                  },
                  onDescriptionChanged: (value) {
                    _updateAnswer(
                      question,
                      description: value,
                    );
                  },
                  onDefectChanged: (value) {
                    _updateAnswer(
                      question,
                      defect: value,
                    );
                  },
                  onFindingChanged: (value) {
                    _updateAnswer(
                      question,
                      finding: value,
                    );
                  },
                  onFindingTypeChanged: (value) {
                    _updateAnswer(
                      question,
                      findingType: value,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _loading || _questions.isEmpty
          ? null
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveAll,
              child: _saving
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Save Checklist',
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updateAnswer(
      AuditQuestionModelNew question, {
        String? answer,
        String? description,
        String? defect,
        String? finding,
        String? findingType,
      }) {
    final key = question.questionId.toString();
    final existing = _answers[key];

    final updated = AuditAnswerModelNew(
      answerId: existing?.answerId,
      auditId: widget.auditId,
      checklistItemId: question.questionId,
      auditType: widget.auditType,
      category: widget.section.sectionName,
      question: question.questionText,
      answer: answer ?? existing?.answer ?? '',
      description:
      description ?? existing?.description ?? '',
      defect: defect ?? existing?.defect ?? '',
      finding: finding ?? existing?.finding ?? '',
      findingType:
      findingType ?? existing?.findingType ?? '',
    );

    setState(() {
      _answers[key] = updated;
    });
  }

  Widget _buildProgress(int total) {
    final answered = _answeredCount;

    final percentage = total == 0
        ? 0.0
        : answered / total;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$answered/$total completed',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(percentage * 100).round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            minHeight: 7,
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
    );
  }
}