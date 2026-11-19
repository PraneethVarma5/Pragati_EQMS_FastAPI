import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/dcc/dcc_document.dart';
import '../../models/dcc/dcc_folder.dart';
import '../../models/dcc/dcc_master_data.dart';
import '../../services/dcc/dcc_document_service.dart';
import '../../services/dcc/dcc_storage_service.dart';
import '../../services/dcc/dcc_folder_service.dart';
import '../../services/dcc/dcc_master_data_service.dart';
import '../../services/dcc/dcc_session.dart';
import '../../services/realtime_service.dart';
import '../../services/dcc/dcc_api_client.dart';
class DccDocumentControlScreen extends StatefulWidget {
  const DccDocumentControlScreen({super.key});

  @override
  State<DccDocumentControlScreen> createState() =>
      _DccDocumentControlScreenState();
}

class _DccDocumentControlScreenState
    extends State<DccDocumentControlScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  String _selectedCategory = 'All Documents';

  List<DccFolder> _folders = [];
  List<DccDocument> _documents = [];

  bool _isLoading = true;

  RealtimeChannel? _documentsChannel;

  bool get _isDccUser =>
      DccSession.currentUser?.role.trim().toUpperCase() == 'DCC';

  @override
  void initState() {
    super.initState();
    _loadReleasedDocuments();
    _loadFolders();
    _subscribeToLiveUpdates();
  }

  void _subscribeToLiveUpdates() {
    _documentsChannel = RealtimeService.subscribeToTable(
      table: 'dcc_documents',
      onInsert: (_) {
        _loadReleasedDocuments();
      },
      onUpdate: (_) {
        _loadReleasedDocuments();
      },
    );
  }

  Future<void> _loadFolders() async {
    try {
      final folders = await DccFolderService.getFolders();
      if (!mounted) return;
      setState(() {
        _folders = folders;
        if (_selectedCategory != 'All Documents' &&
            !_folders.any((folder) => folder.name == _selectedCategory)) {
          _selectedCategory = 'All Documents';
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load folders: $e')),
      );
    }
  }

  Future<void> _showNewMenu() async {
    if (!_isDccUser) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('New Folder'),
              subtitle: const Text('Create a folder visible to everyone'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showCreateFolderDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('Add Document'),
              subtitle: const Text('Upload a released document'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showUploadDocumentDialog();
              },
            ),
          ],
        ),
      ),
    );
  }
  String _formatDate(String value) {
    final parsedDate = DateTime.tryParse(value);

    if (parsedDate == null) {
      return value;
    }

    return '${parsedDate.day.toString().padLeft(2, '0')}.'
        '${parsedDate.month.toString().padLeft(2, '0')}.'
        '${parsedDate.year}';
  }
  Future<void> _showCreateFolderDialog() async {
    if (!_isDccUser) return;
    final controller = TextEditingController();
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('New Folder'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Folder name',
              hintText: 'e.g. Quality Manuals',
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final name = controller.text.trim();
                      if (name.isEmpty) return;
                      setDialogState(() => saving = true);
                      try {
                        await DccFolderService.createFolder(name);
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        await _loadFolders();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Folder created. Everyone can now see it.')),
                          );
                        }
                      } catch (e) {
                        if (!dialogContext.mounted) return;
                        setDialogState(() => saving = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Could not create folder: $e')),
                        );
                      }
                    },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  Future<void> _showUploadDocumentDialog() async {
    if (!_isDccUser) return;
    if (_folders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a folder before adding a document.')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final docNo = TextEditingController();
    final docName = TextEditingController();
    final docType = TextEditingController();
    final department = TextEditingController();
    final candidate = TextEditingController();
    String selectedFolder = _folders.first.name;
    PlatformFile? selectedFile;
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add Document'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(controller: docNo, decoration: const InputDecoration(labelText: 'Document No'), validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 10),
                    TextFormField(controller: docName, decoration: const InputDecoration(labelText: 'Document Name'), validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 10),
                    TextFormField(controller: docType, decoration: const InputDecoration(labelText: 'Document Type'), validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 10),
                    TextFormField(controller: department, decoration: const InputDecoration(labelText: 'Department'), validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 10),
                    TextFormField(controller: candidate, decoration: const InputDecoration(labelText: 'Candidate / Assignee (optional)')),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedFolder,
                      decoration: const InputDecoration(labelText: 'Folder'),
                      items: _folders.map((folder) => DropdownMenuItem(value: folder.name, child: Text(folder.name))).toList(),
                      onChanged: saving ? null : (value) => setDialogState(() => selectedFolder = value!),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: saving
                            ? null
                            : () async {
                                final result = await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['pdf'],
                                  withData: true,
                                );
                                if (result != null && result.files.single.bytes != null) {
                                  setDialogState(() => selectedFile = result.files.single);
                                }
                              },
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: Text(selectedFile?.name ?? 'Select PDF'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      if (selectedFile?.bytes == null || selectedFile!.bytes!.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Select a PDF document.')));
                        return;
                      }
                      setDialogState(() => saving = true);
                      try {
                        final user = DccSession.currentUser;
                        if (user == null || !_isDccUser) throw Exception('DCC session not found.');

                        final master = await DccMasterDataService.getByDocumentNo(docNo.text.trim());
                        final revision = master?.revision ?? 0;
                        final documentId = DateTime.now().microsecondsSinceEpoch.toString();
                        final path = await DccStorageService.uploadConvertedPdf(
                          fileBytes: selectedFile!.bytes!,
                          documentId: documentId,
                          revision: revision,
                          originalFileName: selectedFile!.name,
                        );

                        await DccDocumentService.addDocument(
                          DccDocument(
                            id: documentId,
                            documentNo: docNo.text.trim(),
                            documentName: docName.text.trim(),
                            documentType: docType.text.trim(),
                            department: department.text.trim(),
                            candidateName: candidate.text.trim(),
                            employeeId: '',
                            folderName: selectedFolder,
                            attachmentPath: '',
                            attachmentName: '',
                            releasedPdfPath: path,
                            releasedPdfName: selectedFile!.name,
                            createdByName: user.name,
                            createdByEmail: user.email,
                            releasedByName: user.name,
                            releasedByEmail: user.email,
                            hodName: '',
                            hodEmail: '',
                            status: 'RELEASED',
                            revision: revision,
                            revisionDate: DateTime.now().toIso8601String(),
                          ),
                        );

                        await DccMasterDataService.upsertEntry(
                          DccMasterData(
                            documentNo: docNo.text.trim(),
                            documentName: docName.text.trim(),
                            documentType: docType.text.trim(),
                            department: department.text.trim(),
                            candidateName: candidate.text.trim(),
                            candidateEmail: '',
                            createdByName: user.name,
                            createdByEmail: user.email,
                            revision: revision,
                          ),
                          manualRevision: revision,
                        );

                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        await _loadReleasedDocuments();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded and released.')));
                        }
                      } catch (e) {
                        if (!dialogContext.mounted) return;
                        setDialogState(() => saving = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Could not upload document: $e')));
                      }
                    },
              child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Upload'),
            ),
          ],
        ),
      ),
    );
    docNo.dispose();
    docName.dispose();
    docType.dispose();
    department.dispose();
    candidate.dispose();
  }

  Future<void> _loadReleasedDocuments() async {
if (!mounted) return;

setState(() {
_isLoading = true;
});

try {
  final documents =
      await DccDocumentService.getReleasedDocuments();

      final released = documents
          .where(
            (document) =>
        document.status == 'RELEASED',
      )
          .toList();

      final latestReleasedByDocumentNo =
      <String, DccDocument>{};

      for (final document in released) {
        final documentKey =
        document.documentNo.trim().toLowerCase();

        final existing =
        latestReleasedByDocumentNo[documentKey];

        if (existing == null ||
            document.revision > existing.revision) {
          latestReleasedByDocumentNo[documentKey] =
              document;
        }
      }

      final latestReleased =
      latestReleasedByDocumentNo.values.toList();

      latestReleased.sort(
            (a, b) {
          final documentCompare =
          a.documentNo.trim().toLowerCase().compareTo(
            b.documentNo.trim().toLowerCase(),
          );

          if (documentCompare != 0) {
            return documentCompare;
          }

          return b.revision.compareTo(
            a.revision,
          );
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _documents = latestReleased;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load released documents: $e',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _documentsChannel?.unsubscribe();
    super.dispose();
  }

  bool _isLatestRevision(
      DccDocument document,
      ) {
    final sameDocuments = _documents.where(
          (item) =>
      item.documentNo.trim().toLowerCase() ==
          document.documentNo.trim().toLowerCase(),
    );

    if (sameDocuments.isEmpty) {
      return true;
    }

    final latestRevision = sameDocuments
        .map((item) => item.revision)
        .reduce(
          (a, b) => a > b ? a : b,
    );

    return document.revision == latestRevision;
  }

  String _revisionStatus(
      DccDocument document,
      ) {
    return _isLatestRevision(document)
        ? 'Current Revision'
        : 'Previous Revision';
  }

  List<DccDocument> get _filteredDocuments {
    final search =
    _searchController.text.trim().toLowerCase();

    return _documents.where((document) {
      final matchesCategory =
          _selectedCategory == 'All Documents' ||
              document.folderName.trim().toLowerCase() ==
                  _selectedCategory.trim().toLowerCase();

      final matchesSearch =
          search.isEmpty ||
              document.documentNo
                  .toLowerCase()
                  .contains(search) ||
              document.documentName
                  .toLowerCase()
                  .contains(search) ||
              document.documentType
                  .toLowerCase()
                  .contains(search) ||
              document.department
                  .toLowerCase()
                  .contains(search) ||
              document.folderName
                  .toLowerCase()
                  .contains(search);

      return matchesCategory && matchesSearch;
    }).toList();
  }
  void _openLogin() {
    Navigator.pushNamed(
      context,
      '/DCC/login',
    );
  }

  void _handleNewPressed() {
    // +New is intentionally visible to everyone. Every click opens the DCC
    // login gate first. Only a valid DCC account is allowed to continue to
    // the folder/document creation menu.
    Navigator.pushNamed(
      context,
      '/DCC/loginForNew',
    );
  }

  bool _isOpeningDocument = false;

  Future<void> _viewDocument(DccDocument document) async {
    if (_isOpeningDocument) return;

    setState(() {
      _isOpeningDocument = true;
    });

    try {
      final pdfPath = document.releasedPdfPath.trim();

      if (pdfPath.isEmpty) {
        throw Exception('Released PDF is not available for this document.');
      }

      // Released documents use the public FastAPI endpoint.
      final url = DccApiClient.fileUrl(pdfPath);

      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.platformDefault,
      );

      if (!launched) {
        throw Exception('The browser could not open the released PDF.');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open released PDF: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningDocument = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final documents = _filteredDocuments;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSidebar(),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          _buildPageHeader(),

                          const SizedBox(height: 22),

                          Expanded(
                            child: _isLoading
                                ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Color(0xFF3155D9),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Loading released documents...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            )
                                : _buildDocumentTable(
                              documents,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE4E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
            tooltip: 'Back',
          ),

          const SizedBox(width: 12),

          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: Color(0xFF3155D9),
              size: 23,
            ),
          ),

          const SizedBox(width: 14),

          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Document Control Centre',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF172033),
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Controlled Document Repository',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7A8292),
                ),
              ),
            ],
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _handleNewPressed,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New'),
            ),
          ),

          OutlinedButton.icon(
            onPressed: _openLogin,
            icon: const Icon(
              Icons.login_rounded,
              size: 18,
            ),
            label: const Text(
              'LOGIN',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3155D9),
              side: const BorderSide(
                color: Color(0xFF3155D9),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 24, 20, 12),
            child: Text(
              'FOLDERS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Color(0xFF9AA2B1),
              ),
            ),
          ),
          _sidebarItem('All Documents', Icons.folder_open_outlined),
          ..._folders.map((folder) => _sidebarItem(folder.name, Icons.folder_outlined)),
          const Spacer(),
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/DCC/dcc/masterData'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: const Row(
                children: [
                  Icon(Icons.storage_rounded, size: 18, color: Color(0xFF7A8292)),
                  SizedBox(width: 12),
                  Expanded(child: Text('Master Data', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)))),
                ],
              ),
            ),
          ),
          const Divider(color: Color(0xFFE4E8F0)),
          const Padding(
            padding: EdgeInsets.all(22),
            child: Row(
              children: [
                Icon(Icons.public_rounded, size: 17, color: Color(0xFF6B7280)),
                SizedBox(width: 9),
                Text('Public View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(String name, IconData icon) {
    final selected = _selectedCategory == name;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = name),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF3FF) : Colors.transparent,
          border: selected ? const Border(right: BorderSide(color: Color(0xFF3155D9), width: 3)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? const Color(0xFF3155D9) : const Color(0xFF7A8292)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? const Color(0xFF3155D9) : const Color(0xFF4B5563),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Released Documents',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF172033),
                ),
              ),
              SizedBox(height: 5),
              Text(
                'View controlled documents available for public access.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          width: 330,
          child: TextField(
            controller: _searchController,
            onChanged: (_) {
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: 'Search document...',
              prefixIcon: const Icon(
                Icons.search_rounded,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
              const EdgeInsets.symmetric(
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE4E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE4E8F0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF3155D9),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildDocumentTable(List<DccDocument> documents) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE4E8F0),
            ),
          ),
          child: documents.isEmpty
              ? const Center(
            child: Text(
              'No released documents found.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          )
              : SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SizedBox(
              width: constraints.maxWidth,
              child: DataTable(
                horizontalMargin: 16,
                columnSpacing: constraints.maxWidth < 900 ? 12 : 24,
                headingRowHeight: 52,
                dataRowMinHeight: 62,
                dataRowMaxHeight: 72,
                headingRowColor:
                WidgetStateProperty.all(
                  const Color(0xFFF8F9FC),
                ),
                columns: const [
                  DataColumn(label: Text('Document No')),
                  DataColumn(label: Text('Document Name')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Rev')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Release Status')),
                  DataColumn(label: Text('PDF Document')),
                ],
                rows: documents.map((document) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          document.documentNo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF172033),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          document.documentName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DataCell(Text(document.documentType)),
                      DataCell(Text('Rev ${document.revision}')),
                      DataCell(Text(_formatDate(document.revisionDate))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Released',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        TextButton.icon(
                          onPressed: () => _viewDocument(document),
                          icon: const Icon(
                            Icons.visibility_outlined,
                            size: 17,
                          ),
                          label: const Text('View'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF3155D9),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

}
