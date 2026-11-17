import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/dcc/dcc_master_data.dart';
import '../../../services/dcc/dcc_master_data_service.dart';
import '../../../services/dcc/dcc_session.dart';
import '../../../services/realtime_service.dart';

const List<String> kDccDocumentTypes = ['SOP', 'Manual', 'Procedure'];

class DccMasterDataScreen extends StatefulWidget {
  const DccMasterDataScreen({super.key});

  @override
  State<DccMasterDataScreen> createState() => _DccMasterDataScreenState();
}

class _DccMasterDataScreenState extends State<DccMasterDataScreen> {
  List<DccMasterData> _entries = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  RealtimeChannel? _masterDataChannel;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeToLiveUpdates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _masterDataChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToLiveUpdates() {
    _masterDataChannel = RealtimeService.subscribeToTable(
      table: 'dcc_master_data',
      onInsert: (_) {
        _load();
      },
      onUpdate: (_) {
        _load();
      },
    );
  }
  Future<void> _load() async {
    setState(() => _isLoading = true);

    try {
      final entries = await DccMasterDataService.getAllEntries();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load master data: $e')),
      );
    }
  }

  List<DccMasterData> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _entries;

    return _entries.where((e) {
      return e.documentNo.toLowerCase().contains(query) ||
          e.documentName.toLowerCase().contains(query);
    }).toList();
  }
  Future<void> _exportMasterData() async {
    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No master data available to export.'),
        ),
      );
      return;
    }

    try {
      final excel = Excel.createExcel();

      final defaultSheet =
      excel.getDefaultSheet();

      if (defaultSheet != null &&
          defaultSheet != 'Master Data') {
        excel.rename(
          defaultSheet,
          'Master Data',
        );
      }

      final sheet =
      excel['Master Data'];

      sheet.appendRow([
        TextCellValue('Document No'),
        TextCellValue('Document Name'),
        TextCellValue('Document Type'),
        TextCellValue('Department'),
        TextCellValue('Candidate Name'),
        TextCellValue('Candidate Email'),
        TextCellValue('Created By Name'),
        TextCellValue('Created By Email'),
        TextCellValue('Rev'),
      ]);

      for (final entry in _entries) {
        sheet.appendRow([
          TextCellValue(entry.documentNo),
          TextCellValue(entry.documentName),
          TextCellValue(entry.documentType),
          TextCellValue(entry.department),
          TextCellValue(entry.candidateName),
          TextCellValue(entry.candidateEmail),
          TextCellValue(entry.createdByName),
          TextCellValue(entry.createdByEmail),
          IntCellValue(entry.revision),
        ]);
      }

      final List<int>? encodedBytes =
      excel.encode();

      if (encodedBytes == null) {
        throw Exception(
          'Unable to generate Excel file.',
        );
      }

      final Uint8List bytes =
      Uint8List.fromList(encodedBytes);
      final fileName =
          'DCC_Master_Data_${DateTime.now().year}'
          '${DateTime.now().month.toString().padLeft(2, '0')}'
          '${DateTime.now().day.toString().padLeft(2, '0')}.xlsx';

      final savedFile =
      await FilePicker.platform.saveFile(
        dialogTitle:
        'Export DCC Master Data',
        fileName: fileName,
        bytes: bytes,
      );

      if (!mounted) return;

      if (savedFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Master data exported successfully.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not export master data: $e',
          ),
        ),
      );
    }
  }

  void _showEntryDialog({DccMasterData? existing}) {
    final formKey = GlobalKey<FormState>();
    final docNoController =
    TextEditingController(text: existing?.documentNo ?? '');
    final docNameController =
    TextEditingController(text: existing?.documentName ?? '');
    final departmentController =
    TextEditingController(text: existing?.department ?? '');
    final candidateNameController =
    TextEditingController(text: existing?.candidateName ?? '');
    final candidateEmailController =
    TextEditingController(text: existing?.candidateEmail ?? '');
    final docTypeController =
    TextEditingController(text: existing?.documentType ?? '');
    final revisionController = TextEditingController();
    bool submitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;

              setDialogState(() => submitting = true);

              try {
                final currentUser = DccSession.currentUser;
                final manualRevisionText = revisionController.text.trim();
                final manualRevision = manualRevisionText.isEmpty
                    ? null
                    : int.tryParse(manualRevisionText);
                if (manualRevisionText.isNotEmpty &&
                    (manualRevision == null || manualRevision < 0)) {
                  setDialogState(() => submitting = false);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Revision must be a non-negative number.')),
                  );
                  return;
                }

                await DccMasterDataService.upsertEntry(
                  DccMasterData(
                    documentNo: docNoController.text.trim(),
                    documentName: docNameController.text.trim(),
                    documentType: docTypeController.text.trim(),
                    department: departmentController.text.trim(),
                    candidateName: candidateNameController.text.trim(),
                    candidateEmail:
                    candidateEmailController.text.trim().toLowerCase(),
                    createdByName: currentUser?.name ?? '',
                    createdByEmail: currentUser?.email ?? '',
                    revision: existing?.revision ?? 0,
                  ),
                  manualRevision: manualRevision,
                );

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Master data saved.')),
                  );
                  _load();
                }
              } catch (e) {
                if (!dialogContext.mounted) return;
                setDialogState(() => submitting = false);
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Could not save: $e')),
                );
              }
            }

            return AlertDialog(
              title: Text(
                existing == null ? 'Add Master Data' : 'Edit Master Data',
              ),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: docNoController,
                          enabled: existing == null,
                          decoration: const InputDecoration(
                            labelText: 'Document No',
                          ),
                          validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: docNameController,
                          decoration: const InputDecoration(
                            labelText: 'Document Name',
                          ),
                          validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: docTypeController,
                          decoration: const InputDecoration(
                            labelText: 'Document Type',
                            hintText: 'e.g. SOP, Manual, Procedure',
                          ),
                          validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: departmentController,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                          ),
                          validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: candidateNameController,
                          decoration: const InputDecoration(
                            labelText: 'Candidate Name (assignee)',
                          ),
                          validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: candidateEmailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Candidate Email',
                          ),
                          validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: revisionController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Revision No (optional)',
                            hintText: existing == null
                                ? 'Leave blank to start at Rev 0'
                                : 'Leave blank to auto-increment from Rev ${existing.revision}',
                          ),
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.isEmpty) return null;
                            final parsed = int.tryParse(value);
                            return parsed == null || parsed < 0
                                ? 'Enter a non-negative number'
                                : null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: submitting ? null : submit,
                  child: submitting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(DccMasterData entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Master Data'),
        content: Text(
          'Remove master data for "${entry.documentNo}"? '
              'Users will no longer get auto-filled details for this document number.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DccMasterDataService.deleteEntry(entry.documentNo);
      if (mounted) _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Master Data'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              onPressed: _isLoading
                  ? null
                  : _exportMasterData,
              icon: const Icon(
                Icons.download_outlined,
              ),
              label: const Text('Export'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEntryDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Master Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter a document\'s details here before the New Document '
                  'process starts. When a User types this Document No while '
                  'creating a document, the rest of the fields will auto-fill.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by document no or name...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                  ? const Center(
                child: Text(
                  'No master data entries yet.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              )
                  : ListView.separated(
                itemCount: _filtered.length,
                separatorBuilder: (_, _) =>
                const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final entry = _filtered[index];

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(
                        color: Color(0xFFE4E8F0),
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        '${entry.documentNo} — ${entry.documentName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${entry.documentType} • ${entry.department} • Rev ${entry.revision} • '
                            'Assigned to ${entry.candidateName}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () =>
                                _showEntryDialog(existing: entry),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDelete(entry),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
