import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../models/dcc/dcc_document.dart';
import '../../../models/dcc/dcc_folder.dart';
import '../../../models/dcc/dcc_master_data.dart';
import '../../../services/dcc/dcc_document_service.dart';
import '../../../services/dcc/dcc_folder_service.dart';
import '../../../services/dcc/dcc_master_data_service.dart';
import '../../../services/dcc/dcc_session.dart';
import '../../../services/dcc/dcc_storage_service.dart';

class DccManageSidebarScreen extends StatefulWidget {
  const DccManageSidebarScreen({super.key});

  @override
  State<DccManageSidebarScreen> createState() =>
      _DccManageSidebarScreenState();
}

class _DccManageSidebarScreenState extends State<DccManageSidebarScreen> {
  List<DccFolder> _folders = [];
  List<DccDocument> _documents = [];
  bool _loadingFolders = true;
  String? _selectedFolderName;

  bool get _isDcc =>
      DccSession.currentUser?.role.trim().toUpperCase() == 'DCC';

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    try {
      final results = await Future.wait([
        DccFolderService.getFolders(),
        DccDocumentService.getDocuments(),
      ]);
      if (!mounted) return;
      setState(() {
        _folders = results[0] as List<DccFolder>;
        _documents = (results[1] as List<DccDocument>)
            .where((document) => document.status == 'RELEASED')
            .toList();
        _loadingFolders = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingFolders = false);
      _showMessage('Unable to load folders: $e', error: true);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteFolder(DccFolder folder) async {
    if (!_isDcc) return;

    final documentsInFolder = _documents.where(
      (document) =>
          document.folderName.trim().toLowerCase() ==
          folder.name.trim().toLowerCase(),
    ).toList();

    if (documentsInFolder.isNotEmpty) {
      _showMessage(
        'Cannot delete "${folder.name}" because it contains '
        '${documentsInFolder.length} document(s). Delete the documents first.',
        error: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Delete Folder',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Delete the "${folder.name}" folder? This folder is empty.',
          style: const TextStyle(
            color: Color(0xFF4B5563),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Delete Folder'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD83A3A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await DccFolderService.deleteFolder(folder.id);
      if (_selectedFolderName == folder.name) {
        _selectedFolderName = null;
      }
      await _loadFolders();
      _showMessage('Folder deleted successfully.');
    } catch (e) {
      _showMessage('Could not delete folder: $e', error: true);
    }
  }

  Future<void> _deleteDocument(DccDocument document) async {
    if (!_isDcc) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Delete Document',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Delete "${document.documentName}" (${document.documentNo}) '
          'from the "${document.folderName}" folder? '
          'This will also remove the released PDF from storage.',
          style: const TextStyle(
            color: Color(0xFF4B5563),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Delete Document'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD83A3A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final path = document.releasedPdfPath.trim();
      if (path.isNotEmpty) {
        await DccStorageService.deleteFile(path);
      }
      await DccDocumentService.deleteDocument(
        document,
      );
      await _loadFolders();
      _showMessage('Document deleted successfully.');
    } catch (e) {
      _showMessage('Could not delete document: $e', error: true);
    }
  }

  Future<void> _addFolder() async {
    if (!_isDcc) return;

    final controller = TextEditingController();
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> create() async {
              final name = controller.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Folder name is required.')),
                );
                return;
              }

              setDialogState(() => saving = true);
              try {
                await DccFolderService.createFolder(name);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                await _loadFolders();
                _showMessage('Folder created and visible to everyone.');
              } catch (e) {
                if (!dialogContext.mounted) return;
                setDialogState(() => saving = false);
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Could not create folder: $e')),
                );
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Add Folder',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              content: SizedBox(
                width: 420,
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => saving ? null : create(),
                  decoration: InputDecoration(
                    labelText: 'Folder Name',
                    hintText: 'Enter folder name',
                    prefixIcon: const Icon(Icons.folder_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: saving ? null : create,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Folder'),
                ),
              ],
            );
          },
        );
      },
    );

    // Dispose after the dialog's closing frame so Flutter's TextField
    // is no longer attached to this controller.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });  }

  Future<void> _addDocument() async {
    if (!_isDcc) return;

    if (_folders.isEmpty) {
      _showMessage(
        'Create a sidebar folder before adding a document.',
        error: true,
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final documentNoController = TextEditingController();
    final documentNameController = TextEditingController();
    String selectedFolder = _folders.first.name;
    PlatformFile? selectedFile;
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> pickDocument() async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf'],
                withData: true,
              );

              if (result == null || result.files.isEmpty) return;
              final file = result.files.single;
              if (file.bytes == null || file.bytes!.isEmpty) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('The selected PDF could not be read.'),
                    ),
                  );
                }
                return;
              }

              setDialogState(() => selectedFile = file);
            }

            Future<void> upload() async {
              if (!formKey.currentState!.validate()) return;

              final Uint8List? bytes = selectedFile?.bytes;
              if (bytes == null || bytes.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please select a PDF document.')),
                );
                return;
              }

              setDialogState(() => saving = true);

              try {
                final user = DccSession.currentUser;
                if (user == null || !_isDcc) {
                  throw Exception('DCC session is required.');
                }

                final documentNo = documentNoController.text.trim();
                final documentName = documentNameController.text.trim();
                final existing =
                    await DccMasterDataService.getByDocumentNo(documentNo);

                // No revision field is shown on this screen by design:
                // first document starts at Rev 0, and an existing document
                // automatically moves to the next revision.
                final revision = existing == null ? 0 : existing.revision + 1;
                final documentId =
                    DateTime.now().microsecondsSinceEpoch.toString();

                final storagePath =
                    await DccStorageService.uploadConvertedPdf(
                  fileBytes: bytes,
                  documentId: documentId,
                  revision: revision,
                  originalFileName: selectedFile!.name,
                );

                await DccDocumentService.addDocument(
                  DccDocument(
                    id: documentId,
                    documentNo: documentNo,
                    documentName: documentName,
                    documentType: existing?.documentType ?? '',
                    department: existing?.department ?? '',
                    candidateName: existing?.candidateName ?? '',
                    employeeId: '',
                    folderName: selectedFolder,
                    attachmentPath: '',
                    attachmentName: '',
                    releasedPdfPath: storagePath,
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
                    documentNo: documentNo,
                    documentName: documentName,
                    documentType: existing?.documentType ?? '',
                    department: existing?.department ?? '',
                    candidateName: existing?.candidateName ?? '',
                    candidateEmail: existing?.candidateEmail ?? '',
                    createdByName: user.name,
                    createdByEmail: user.email,
                    revision: revision,
                  ),
                  manualRevision: revision,
                );

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                _showMessage(
                  'Document uploaded to "$selectedFolder" as Rev $revision.',
                );
              } catch (e) {
                if (!dialogContext.mounted) return;
                setDialogState(() => saving = false);
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Could not upload document: $e')),
                );
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Add Document',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              content: SizedBox(
                width: 520,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Upload a controlled PDF and place it in one of the sidebar folders.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7A8292),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _field(
                          controller: documentNoController,
                          label: 'Document Number',
                          hint: 'Enter document number',
                          icon: Icons.tag_rounded,
                        ),
                        const SizedBox(height: 14),
                        _field(
                          controller: documentNameController,
                          label: 'Document Name',
                          hint: 'Enter document name',
                          icon: Icons.description_outlined,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: selectedFolder,
                          decoration: InputDecoration(
                            labelText: 'Sidebar Folder',
                            prefixIcon: const Icon(Icons.folder_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _folders
                              .map(
                                (folder) => DropdownMenuItem<String>(
                                  value: folder.name,
                                  child: Text(
                                    folder.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: saving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setDialogState(
                                      () => selectedFolder = value,
                                    );
                                  }
                                },
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: saving ? null : pickDocument,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F9FC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFDCE2EC),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF3FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.picture_as_pdf_outlined,
                                    color: Color(0xFF3155D9),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedFile?.name ?? 'Upload PDF',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF172033),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      const Text(
                                        'PDF files only',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF7A8292),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.upload_rounded,
                                  color: Color(0xFF3155D9),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: saving ? null : upload,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: const Text('Upload Document'),
                ),
              ],
            );
          },
        );
      },
    );

    // Wait until the dialog has been removed from the widget tree
    // before disposing controllers used by its TextFields.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      documentNoController.dispose();
      documentNameController.dispose();
    });  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Required' : null,
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(30, 28, 30, 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add and Manage SideBar Folders',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF172033),
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Create folders and upload controlled documents that are visible to everyone on the DCC home page.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7A8292),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _actionCard(
                                icon: Icons.create_new_folder_outlined,
                                title: 'Add Folder',
                                subtitle:
                                    'Create a new sidebar folder visible to everyone.',
                                buttonLabel: 'Add Folder',
                                onPressed: _addFolder,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _actionCard(
                                icon: Icons.upload_file_outlined,
                                title: 'Add Document',
                                subtitle:
                                    'Upload a PDF and place it inside an existing sidebar folder.',
                                buttonLabel: 'Add Document',
                                onPressed: _addDocument,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        _buildFolderList(),
                      ],
                    ),
                  ),
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE4E8F0)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF8F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_outlined,
                    size: 17, color: Color(0xFF3C8C45)),
                SizedBox(width: 7),
                Text(
                  'DCC Access',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3C8C45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF3155D9), size: 26),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            style: const TextStyle(
              height: 1.45,
              fontSize: 13,
              color: Color(0xFF7A8292),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(
              title == 'Add Folder'
                  ? Icons.add_rounded
                  : Icons.cloud_upload_outlined,
              size: 18,
            ),
            label: Text(buttonLabel),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sidebar Folders',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Manage folders and documents visible on the DCC home page.',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF7A8292),
            ),
          ),
          const SizedBox(height: 16),
          if (_loadingFolders)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_folders.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'No sidebar folders yet. Use Add Folder to create the first one.',
                style: TextStyle(color: Color(0xFF7A8292)),
              ),
            )
          else
            Column(
              children: _folders.map((folder) {
                final folderDocuments = _documents.where(
                  (document) =>
                      document.folderName.trim().toLowerCase() ==
                      folder.name.trim().toLowerCase(),
                ).toList();

                final expanded = _selectedFolderName == folder.name;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFD),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE1E6EF)),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => setState(() {
                          _selectedFolderName =
                              expanded ? null : folder.name;
                        }),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF3FF),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: const Icon(
                                  Icons.folder_outlined,
                                  color: Color(0xFF3155D9),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      folder.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF172033),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${folderDocuments.length} document(s)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF7A8292),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: folderDocuments.isEmpty
                                    ? 'Delete folder'
                                    : 'Delete documents in this folder first',
                                onPressed: folderDocuments.isNotEmpty
                                    ? null
                                    : () => _deleteFolder(folder),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 19,
                                ),
                                color: const Color(0xFFD83A3A),
                              ),
                              Icon(
                                expanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: const Color(0xFF7A8292),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (expanded)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(68, 0, 16, 16),
                          child: folderDocuments.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    'This folder is empty.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF7A8292),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: folderDocuments.map((document) {
                                    return Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFFE4E8F0),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.picture_as_pdf_outlined,
                                            size: 20,
                                            color: Color(0xFF3155D9),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  document.documentName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF172033),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${document.documentNo}  •  Rev ${document.revision}',
                                                  style: const TextStyle(
                                                    fontSize: 11.5,
                                                    color: Color(0xFF7A8292),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Delete document',
                                            onPressed: () =>
                                                _deleteDocument(document),
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 19,
                                            ),
                                            color: const Color(0xFFD83A3A),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }


}
