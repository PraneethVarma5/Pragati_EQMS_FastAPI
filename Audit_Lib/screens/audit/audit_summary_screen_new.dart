import 'package:flutter/material.dart';

import '../../models/audit/audit_summary_model_new.dart';
import '../../services/audit/audit_summary_service_new.dart';

class AuditSummaryScreenNew extends StatefulWidget {
  final dynamic auditId;
  final String auditType;

  const AuditSummaryScreenNew({
    super.key,
    required this.auditId,
    required this.auditType,
  });

  @override
  State<AuditSummaryScreenNew> createState() =>
      _AuditSummaryScreenNewState();
}

class _AuditSummaryScreenNewState
    extends State<AuditSummaryScreenNew> {
  final AuditSummaryServiceNew _service =
  AuditSummaryServiceNew();

  AuditSummaryModelNew? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final summary = await _service.buildSummary(
        auditId: widget.auditId,
        auditType: widget.auditType,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _summary = summary;
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
          content: Text(
            'Unable to load audit summary: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Summary'),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _summary == null
          ? const Center(
        child: Text(
          'No summary available.',
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCompletionCard(
              context,
              title: 'Category Completion',
              value:
              _summary!.categoryCompletion,
              text:
              '${_summary!.completedCategories}/${_summary!.totalCategories}',
            ),
            const SizedBox(height: 12),
            _buildCompletionCard(
              context,
              title: 'Question Completion',
              value:
              _summary!.questionCompletion,
              text:
              '${_summary!.answeredQuestions}/${_summary!.totalQuestions}',
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              context,
              title: 'Findings',
              value:
              '${_summary!.totalFindings}',
            ),
            const SizedBox(height: 24),
            _buildStatusCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionCard(
      BuildContext context, {
        required String title,
        required double value,
        required String text,
      }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: value,
              minHeight: 9,
              borderRadius:
              BorderRadius.circular(20),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${(value * 100).round()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      BuildContext context, {
        required String title,
        required String value,
      }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color:
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final complete = _summary!.isComplete;

    return Card(
      child: ListTile(
        leading: Icon(
          complete
              ? Icons.check_circle
              : Icons.pending_actions,
          color: complete
              ? Colors.green
              : Colors.orange,
        ),
        title: Text(
          complete
              ? 'Audit Ready for Completion'
              : 'Audit Still In Progress',
        ),
        subtitle: Text(
          complete
              ? 'All configured questions have been answered.'
              : 'Some configured questions are still unanswered.',
        ),
      ),
    );
  }
}