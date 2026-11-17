import 'package:flutter/material.dart';

import '../../services/audit_pdf_service.dart';
import '../../services/supabase_service.dart';

class AuditReportScreen extends StatefulWidget {
  final String auditId;

  const AuditReportScreen({
    super.key,
    required this.auditId,
  });

  @override
  State<AuditReportScreen> createState() =>
      _AuditReportScreenState();
}

class _AuditReportScreenState
    extends State<AuditReportScreen> {
  Map<String, dynamic>? _audit;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _answers = [];
  List<Map<String, dynamic>> _milItems = [];

  bool _loading = true;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  // ============================================================
  // LOAD REPORT
  // ============================================================

  Future<void> _loadReport() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final report =
      await SupabaseService.getAuditReport(
        widget.auditId,
      ).timeout(
        const Duration(seconds: 20),
      );

      if (!mounted) return;

      setState(() {
        _audit = report['audit'] == null
            ? null
            : Map<String, dynamic>.from(
          report['audit'],
        );

        _categories =
        List<Map<String, dynamic>>.from(
          report['categories'] ?? [],
        );

        _answers =
        List<Map<String, dynamic>>.from(
          report['answers'] ?? [],
        );

        _milItems =
        List<Map<String, dynamic>>.from(
          report['mil_items'] ?? [],
        );

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showError(
        'Unable to load Audit Report: $e',
      );
    }
  }

  // ============================================================
  // DOWNLOAD
  // ============================================================

  Future<void> _downloadReport() async {
    if (_loading || _downloading) {
      return;
    }

    setState(() {
      _downloading = true;
    });

    try {
      await AuditPdfService.downloadAuditReport(
        widget.auditId,
      );

      if (!mounted) return;

      _showMessage(
        'Audit Report downloaded successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Unable to download Audit Report: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
        });
      }
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _value(
      dynamic value, {
        String fallback = '-',
      }) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    return text.isEmpty ? fallback : text;
  }

  String _date(dynamic value) {
    final text = _value(value);

    if (text == '-') {
      return '-';
    }

    if (text.length >= 10) {
      return text.substring(0, 10);
    }

    return text;
  }

  double _number(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  String _hours(dynamic value) {
    return _number(value).toStringAsFixed(2);
  }

  // ============================================================
  // FINDINGS
  // ============================================================

  List<Map<String, dynamic>> get _findings {
    return _answers
        .where(
          (answer) =>
      answer['answer']
          ?.toString()
          .trim() ==
          'No',
    )
        .toList();
  }

  int get _criticalCount {
    return _findings.where(
          (finding) =>
      finding['defect_type']
          ?.toString()
          .trim() ==
          'Critical',
    ).length;
  }

  int get _majorCount {
    return _findings.where(
          (finding) =>
      finding['defect_type']
          ?.toString()
          .trim() ==
          'Major',
    ).length;
  }

  int get _minorCount {
    return _findings.where(
          (finding) =>
      finding['defect_type']
          ?.toString()
          .trim() ==
          'Minor',
    ).length;
  }

  double get _cph {
    final hours =
    _number(
      _audit?['total_audit_hours'],
    );

    if (hours <= 0) {
      return 0;
    }

    return _findings.length / hours;
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _auditStatus() {
    return _value(
      _audit?['status'],
    );
  }

  String _milStatus() {
    final direct =
    _audit?['mil_status']
        ?.toString()
        .trim();

    if (direct != null &&
        direct.isNotEmpty) {
      return direct;
    }

    if (_milItems.isEmpty) {
      return 'Not Generated';
    }

    final allClosed =
    _milItems.every(
          (item) =>
      item['overall_status']
          ?.toString()
          .trim() ==
          'Closed',
    );

    return allClosed ? 'Closed' : 'Open';
  }

  // ============================================================
  // REPORT ROW
  // ============================================================

  Map<String, dynamic> get _reportRow {
    return {
      'sno': 1,
      'mil_number':
      _value(
        _audit?['mil_number'],
      ),
      'audit_type':
      _value(
        _audit?['audit_type'],
      ),
      'audited_date':
      _date(
        _audit?['audit_date'],
      ),
      'vendor':
      _value(
        _audit?['vendor'],
      ),
      'site':
      _value(
        _audit?['site'],
      ),
      'lob':
      _value(
        _audit?['lob'],
      ),
      'program':
      _value(
        _audit?['program'],
      ),
      'line':
      _value(
        _audit?['line'],
      ),
      'apn':
      _value(
        _audit?['apn'],
      ),
      'status':
      _auditStatus(),
      'mil_status':
      _milStatus(),
      'total_audited_hours':
      _hours(
        _audit?['total_audit_hours'],
      ),
      'critical':
      _criticalCount,
      'major':
      _majorCount,
      'minor':
      _minorCount,
      'cph':
      _cph.toStringAsFixed(2),
    };
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Audit Report',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip:
            'Download Audit Report',
            onPressed:
            _loading || _downloading
                ? null
                : _downloadReport,
            icon: _downloading
                ? const SizedBox(
              width: 20,
              height: 20,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Icon(
              Icons.download_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed:
            _loading
                ? null
                : _loadReport,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
          child:
          CircularProgressIndicator(),
        )
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_audit == null) {
      return const Center(
        child: Text(
          'Audit information is not available.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReport,
      child: SingleChildScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 1800,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                _buildReportHeader(),

                const SizedBox(
                  height: 18,
                ),

                _buildReportTable(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildReportHeader() {
    final auditType =
    _value(
      _audit?['audit_type'],
    );

    final status =
    _auditStatus();

    final milStatus =
    _milStatus();

    return Card(
      elevation: 0,
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(14),
        side: BorderSide(
          color:
          Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration:
              BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer,
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
              ),
              child: Icon(
                Icons
                    .fact_check_outlined,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer,
              ),
            ),
            const SizedBox(
              width: 14,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Audit Report',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    auditType,
                    style: TextStyle(
                      color:
                      Colors.grey.shade700,
                      fontWeight:
                      FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _statusChip(
              'Audit',
              status,
            ),
            const SizedBox(
              width: 10,
            ),
            _statusChip(
              'MIL',
              milStatus,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MAIN REPORT TABLE
  // ============================================================

  Widget _buildReportTable() {
    final row =
        _reportRow;

    return Card(
      elevation: 0,
      clipBehavior:
      Clip.antiAlias,
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(14),
        side: BorderSide(
          color:
          Colors.grey.shade300,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection:
        Axis.horizontal,
        child: DataTable(
          headingRowHeight: 58,
          dataRowMinHeight: 70,
          dataRowMaxHeight: 90,
          columnSpacing: 20,
          horizontalMargin: 18,
          headingTextStyle:
          const TextStyle(
            fontWeight:
            FontWeight.w800,
            fontSize: 13,
          ),
          columns: const [
            DataColumn(
              label: Text('SNo'),
            ),
            DataColumn(
              label: Text('MIL number'),
            ),
            DataColumn(
              label: Text('Audit type'),
            ),
            DataColumn(
              label: Text('Audited date'),
            ),
            DataColumn(
              label: Text('Vendor'),
            ),
            DataColumn(
              label: Text('Site'),
            ),
            DataColumn(
              label: Text('LOB'),
            ),
            DataColumn(
              label: Text('Program'),
            ),
            DataColumn(
              label: Text('Line'),
            ),
            DataColumn(
              label: Text('APN'),
            ),
            DataColumn(
              label: Text('Status'),
            ),
            DataColumn(
              label: Text('Audit report'),
            ),
            DataColumn(
              label: Text('MIL Report'),
            ),
            DataColumn(
              label:
              Text('Total audited hours'),
            ),
            DataColumn(
              label:
              Text('No. of Critical findings'),
            ),
            DataColumn(
              label:
              Text('No. Of Major findings'),
            ),
            DataColumn(
              label:
              Text('No. Of Minor findings'),
            ),
            DataColumn(
              label: Text('CPH'),
            ),
          ],
          rows: [
            DataRow(
              cells: [
                DataCell(
                  _cellText(
                    row['sno'],
                  ),
                ),
                DataCell(
                  _cellText(
                    row['mil_number'],
                  ),
                ),
                DataCell(
                  _cellText(
                    row['audit_type'],
                  ),
                ),
                DataCell(
                  _cellText(
                    row['audited_date'],
                  ),
                ),
                DataCell(
                  _cellText(
                    row['vendor'],
                  ),
                ),
                DataCell(
                  _cellText(
                    row['site'],
                  ),
                ),
                DataCell(
                  _cellText(
                    row['lob'],
                  ),
                ),
                DataCell(
                  _cellText(
                    row['program'],
                  ),
                ),
                DataCell(
                  _cellText(
                    row['line'],
                  ),
                ),
                DataCell(
                  _cellText(
                    row['apn'],
                  ),
                ),
                DataCell(
                  _statusChip(
                    '',
                    row['status']
                        ?.toString() ??
                        '-',
                  ),
                ),
                DataCell(
                  _reportAction(
                    tooltip:
                    'Download Audit Report',
                    icon:
                    Icons.download_outlined,
                    onPressed:
                    _downloading
                        ? null
                        : _downloadReport,
                  ),
                ),
                DataCell(
                  _reportAction(
                    tooltip:
                    'Open MIL Report',
                    icon:
                    Icons
                        .assignment_outlined,
                    onPressed:
                    _openMilReport,
                  ),
                ),
                DataCell(
                  _cellText(
                    row[
                    'total_audited_hours'],
                  ),
                ),
                DataCell(
                  _numberCell(
                    row['critical'],
                  ),
                ),
                DataCell(
                  _numberCell(
                    row['major'],
                  ),
                ),
                DataCell(
                  _numberCell(
                    row['minor'],
                  ),
                ),
                DataCell(
                  _cellText(
                    row['cph'],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MIL NAVIGATION
  // ============================================================

  Future<void> _openMilReport() async {
    await Navigator.pushNamed(
      context,
      '/AUDIT/mil',
      arguments: widget.auditId,
    );

    if (!mounted) return;

    await _loadReport();
  }

  // ============================================================
  // TABLE HELPERS
  // ============================================================

  Widget _cellText(
      dynamic value,
      ) {
    return Text(
      _value(value),
      maxLines: 3,
      overflow:
      TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 13,
      ),
    );
  }

  Widget _numberCell(
      dynamic value,
      ) {
    return Center(
      child: Text(
        _value(value),
        style: const TextStyle(
          fontWeight:
          FontWeight.w600,
        ),
      ),
    );
  }

  Widget _reportAction({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 21,
      ),
    );
  }

  Widget _statusChip(
      String prefix,
      String status,
      ) {
    final clean =
    status.trim().isEmpty
        ? '-'
        : status.trim();

    Color background;
    Color foreground;

    switch (
    clean.toLowerCase()) {
      case 'completed':
      case 'closed':
        background =
            Colors.green.shade100;
        foreground =
            Colors.green.shade800;
        break;

      case 'submitted':
        background =
            Colors.blue.shade100;
        foreground =
            Colors.blue.shade800;
        break;

      case 'in progress':
      case 'open':
        background =
            Colors.orange.shade100;
        foreground =
            Colors.orange.shade800;
        break;

      case 'draft':
        background =
            Colors.grey.shade200;
        foreground =
            Colors.grey.shade800;
        break;

      default:
        background =
            Colors.grey.shade100;
        foreground =
            Colors.grey.shade700;
    }

    final label =
    prefix.trim().isEmpty
        ? clean
        : '$prefix: $clean';

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
      BoxDecoration(
        color: background,
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight:
          FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGES
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
}