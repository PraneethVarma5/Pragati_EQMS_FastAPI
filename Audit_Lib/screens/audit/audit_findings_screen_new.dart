import 'package:flutter/material.dart';

import '../../services/audit/audit_service_new.dart';

class AuditFindingsScreenNew extends StatefulWidget {
  final dynamic auditId;

  const AuditFindingsScreenNew({
    super.key,
    required this.auditId,
  });

  @override
  State<AuditFindingsScreenNew> createState() =>
      _AuditFindingsScreenNewState();
}

class _AuditFindingsScreenNewState
    extends State<AuditFindingsScreenNew> {
  final AuditServiceNew _service =
  AuditServiceNew();

  List<Map<String, dynamic>> _findings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final findings =
      await _service.getFindings(widget.auditId);

      if (!mounted) {
        return;
      }

      setState(() {
        _findings = findings;
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
            'Unable to load findings: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Findings'),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _findings.isEmpty
          ? const Center(
        child: Text(
          'No findings recorded for this audit.',
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _findings.length,
          itemBuilder: (context, index) {
            return _buildFindingCard(
              _findings[index],
              index + 1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildFindingCard(
      Map<String, dynamic> finding,
      int index,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ExpansionTile(
        title: Text(
          'Finding $index',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        childrenPadding:
        const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),
        children: [
          _valueRow(
            'Finding',
            finding['finding'],
          ),
          _valueRow(
            'Finding Type',
            finding['finding_type'],
          ),
          _valueRow(
            'Description',
            finding['description'],
          ),
          _valueRow(
            'Defect',
            finding['defect'],
          ),
        ],
      ),
    );
  }

  Widget _valueRow(
      String label,
      dynamic value,
      ) {
    final text =
        value?.toString().trim() ?? '';

    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}