import 'package:flutter/material.dart';

import '../../models/audit/audit_model_new.dart';
import '../../services/audit/audit_service_new.dart';

class AuditHistoryScreenNew extends StatefulWidget {
  const AuditHistoryScreenNew({
    super.key,
  });

  @override
  State<AuditHistoryScreenNew> createState() =>
      _AuditHistoryScreenNewState();
}

class _AuditHistoryScreenNewState
    extends State<AuditHistoryScreenNew> {
  final AuditServiceNew _service =
  AuditServiceNew();

  List<AuditModelNew> _audits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final audits =
      await _service.getAudits();

      if (!mounted) {
        return;
      }

      setState(() {
        _audits = audits;
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
            'Unable to load audit history: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit History'),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _audits.isEmpty
          ? const Center(
        child: Text(
          'No audits found.',
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _audits.length,
          itemBuilder: (context, index) {
            return _buildAuditCard(
              _audits[index],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAuditCard(
      AuditModelNew audit,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.all(16),
        title: Text(
          audit.milNumber.isEmpty
              ? 'Audit'
              : audit.milNumber,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding:
          const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                audit.auditType,
              ),
              if (audit.vendor.isNotEmpty)
                Text(
                  audit.vendor,
                ),
              if (audit.site.isNotEmpty)
                Text(
                  audit.site,
                ),
              if (audit.auditDate.isNotEmpty)
                Text(
                  audit.auditDate,
                ),
            ],
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
      ),
    );
  }
}