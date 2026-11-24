import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/ccr/ccr_api_client.dart';
import '../../models/ccr/ccr_case.dart';
import '../../services/ccr/ccr_service.dart';
import 'ccr_closure_screen.dart';

class CcrEvidenceScreen extends StatefulWidget {
  const CcrEvidenceScreen({
    super.key,
    required this.ccrId,
  });

  final String ccrId;

  @override
  State<CcrEvidenceScreen> createState() =>
      _CcrEvidenceScreenState();
}

class _CcrEvidenceScreenState
    extends State<CcrEvidenceScreen> {

  final CcrService _ccrService =
  CcrService();

  final ImagePicker _imagePicker =
  ImagePicker();

  CcrCase? _ccr;

  List<Map<String, dynamic>> _actions =
  <Map<String, dynamic>>[];

  Map<String, List<Map<String, dynamic>>>
  _evidenceByAction =
  <String, List<Map<String, dynamic>>>{};

  final Map<String, List<_PendingEvidence>>
  _pendingEvidence =
  <String, List<_PendingEvidence>>{};

  bool _loading = true;
  bool _saving = false;
  bool _completing = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _load() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final CcrCase? ccr =
      await _ccrService.getCcrById(
        widget.ccrId,
      );

      if (ccr == null) {
        throw Exception(
          'The selected customer complaint could not be found.',
        );
      }

      final dynamic rawActions =
      await CcrApiClient.get(
        '/cases/${widget.ccrId}/corrective-actions',
      );

      final List<Map<String, dynamic>> actions =
      _asMapList(rawActions);

      final dynamic rawEvidence =
      await CcrApiClient.get(
        '/cases/${widget.ccrId}/action-evidence',
      );

      final List<Map<String, dynamic>> evidence =
      _asMapList(rawEvidence);

      final Map<String, List<Map<String, dynamic>>>
      grouped =
      <String, List<Map<String, dynamic>>>{};

      for (final Map<String, dynamic> item
      in evidence) {
        final String actionId =
            item['corrective_action_id']
                ?.toString() ??
                '';

        if (actionId.isEmpty) {
          continue;
        }

        grouped
            .putIfAbsent(
          actionId,
              () => <Map<String, dynamic>>[],
        )
            .add(item);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _ccr = ccr;
        _actions = actions;
        _evidenceByAction = grouped;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = _cleanError(e);
      });
    }
  }
  // ============================================================
  // PICK MULTIPLE IMAGES
  // ============================================================

  Future<void> _pickEvidence({
    required String actionId,
    required String evidenceType,
  }) async {
    try {
      final List<XFile> picked =
      await _imagePicker.pickMultiImage(
        imageQuality: 90,
      );

      if (picked.isEmpty) {
        return;
      }

      final List<_PendingEvidence>
      selected =
      <_PendingEvidence>[];

      for (final XFile file in picked) {
        final Uint8List bytes =
        await file.readAsBytes();

        selected.add(
          _PendingEvidence(
            evidenceType: evidenceType,
            bytes: bytes,
            fileName: file.name,
          ),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        final List<_PendingEvidence>
        existing =
            _pendingEvidence[actionId] ??
                <_PendingEvidence>[];

        existing.addAll(selected);

        _pendingEvidence[actionId] =
            existing;
      });

      _showMessage(
        '${selected.length} $evidenceType image${selected.length == 1 ? '' : 's'} selected. Save Draft to upload.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanError(e),
        error: true,
      );
    }
  }

  // ============================================================
  // REMOVE PENDING IMAGE
  // ============================================================

  void _removePendingEvidence({
    required String actionId,
    required _PendingEvidence evidence,
  }) {
    final List<_PendingEvidence>? items =
    _pendingEvidence[actionId];

    if (items == null) {
      return;
    }

    setState(() {
      items.remove(evidence);

      if (items.isEmpty) {
        _pendingEvidence.remove(actionId);
      }
    });
  }

  // ============================================================
  // DELETE SAVED IMAGE
  // ============================================================

  Future<void> _deleteSavedEvidence(
      Map<String, dynamic> evidence,
      ) async {
    if (_saving || _completing) {
      return;
    }

    final dynamic rawAttachment =
    evidence['ccr_attachments'];

    if (rawAttachment is! Map) {
      _showMessage(
        'Attachment information is missing.',
        error: true,
      );
      return;
    }

    final Map<String, dynamic>
    attachment =
    Map<String, dynamic>.from(
      rawAttachment,
    );

    final String evidenceId =
        evidence['id']?.toString() ??
            '';

    final String attachmentId =
        attachment['id']?.toString() ??
            '';

    final String bucket =
        attachment['storage_bucket']
            ?.toString() ??
            '';

    final String path =
        attachment['storage_path']
            ?.toString() ??
            '';

    if (evidenceId.isEmpty ||
        attachmentId.isEmpty) {
      _showMessage(
        'The selected evidence record is incomplete.',
        error: true,
      );
      return;
    }

    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          title: const Text(
            'Delete Image',
          ),
          content: const Text(
            'This image will be permanently removed from the CCR evidence.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                    dialogContext,
                    false,
                  ),
              child:
              const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                    dialogContext,
                    true,
                  ),
              style:
              FilledButton.styleFrom(
                backgroundColor:
                const Color(
                  0xFFB42318,
                ),
              ),
              child:
              const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await CcrApiClient.delete(
        '/action-evidence/$evidenceId',
      );
      // --------------------------------------------------------
      // 4. Remove immediately from local UI
      // --------------------------------------------------------

      for (final List<Map<String, dynamic>>
      list in _evidenceByAction.values) {
        list.removeWhere(
              (
              Map<String, dynamic> item,
              ) =>
          item['id']?.toString() ==
              evidenceId,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {});

      _showMessage(
        'Image deleted successfully.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanError(e),
        error: true,
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
  // SAVE DRAFT
  // ============================================================

  Future<void> _saveDraft() async {
    if (_saving || _completing) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _uploadPendingEvidence();

      await _load();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Corrective action evidence saved successfully.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanError(e),
        error: true,
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
  // UPLOAD PENDING IMAGES
  // ============================================================

  Future<void> _uploadPendingEvidence() async {
    if (_pendingEvidence.isEmpty) {
      return;
    }

    final Map<String, List<_PendingEvidence>>
    pending =
    <String, List<_PendingEvidence>>{};

    for (final MapEntry<String, List<_PendingEvidence>>
    entry in _pendingEvidence.entries) {
      pending[entry.key] =
      List<_PendingEvidence>.from(entry.value);
    }

    for (final MapEntry<String, List<_PendingEvidence>>
    entry in pending.entries) {
      final String actionId = entry.key;

      final List<_PendingEvidence> items =
          entry.value;

      for (final _PendingEvidence item in items) {
        final String extension =
        _fileExtension(item.fileName);

        final String typeKey =
        item.evidenceType.trim().toLowerCase();

        final String attachmentType =
        typeKey == 'before'
            ? 'corrective_action_before'
            : 'corrective_action_after';

        // 1. Upload file and create attachment metadata.
        final dynamic rawAttachment =
        await CcrApiClient.uploadFileBytes(
          path: '/cases/${widget.ccrId}/attachments',
          bytes: item.bytes,
          fileName: item.fileName,
          fields: <String, String>{
            'attachment_type': attachmentType,
            'title': '$typeKey corrective action evidence',
            'description':
            'Evidence supporting the implemented corrective action.',
          },
        );

        if (rawAttachment is! Map) {
          throw Exception(
            'The server did not return attachment information.',
          );
        }

        final Map<String, dynamic> attachment =
        Map<String, dynamic>.from(rawAttachment);

        final String attachmentId =
            attachment['id']?.toString() ?? '';

        if (attachmentId.isEmpty) {
          throw Exception(
            'The uploaded attachment ID is missing.',
          );
        }

        // 2. Create corrective action evidence record.
        await CcrApiClient.post(
          '/action-evidence',
          body: <String, dynamic>{
            'data': <String, dynamic>{
              'corrective_action_id': actionId,
              'evidence_type': typeKey,
              'title': '$typeKey corrective action evidence',
              'description':
              'Evidence supporting the implemented corrective action.',
              'attachment_id': attachmentId,
            },
          },
        );

        // 3. Remove only the successfully uploaded item.
        final List<_PendingEvidence>? current =
        _pendingEvidence[actionId];

        current?.remove(item);

        if (current != null && current.isEmpty) {
          _pendingEvidence.remove(actionId);
        }
      }
    }
  }

  // ============================================================
  // COMPLETE
  // ============================================================

  Future<void> _complete() async {
    if (_saving || _completing) {
      return;
    }

    setState(() {
      _completing = true;
    });

    try {
      await _uploadPendingEvidence();

      await _load();

      final String? validation =
      _validateEvidence();

      if (validation != null) {
        if (!mounted) {
          return;
        }

        _showMessage(
          validation,
          error: true,
        );

        return;
      }
      await CcrApiClient.post(
        '/cases/${widget.ccrId}/workflow/advance',
      );
      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CcrClosureScreen(
                ccrId: widget.ccrId,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanError(e),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _completing = false;
        });
      }
    }
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  String? _validateEvidence() {
    if (_actions.isEmpty) {
      return 'No corrective action plans were found.';
    }

    for (final Map<String, dynamic>
    action in _actions) {
      final String actionId =
          action['id']?.toString() ??
              '';

      if (actionId.isEmpty) {
        continue;
      }

      final List<Map<String, dynamic>>
      evidence =
          _evidenceByAction[actionId] ??
              <Map<String, dynamic>>[];

      final bool hasBefore =
      evidence.any(
            (Map<String, dynamic> item) =>
        item['evidence_type']
            ?.toString()
            .trim()
            .toLowerCase() ==
            'before',
      );

      final bool hasAfter =
      evidence.any(
            (Map<String, dynamic> item) =>
        item['evidence_type']
            ?.toString()
            .trim()
            .toLowerCase() ==
            'after',
      );

      final List<_PendingEvidence>
      pending =
          _pendingEvidence[actionId] ??
              <_PendingEvidence>[];

      final bool pendingBefore =
      pending.any(
            (_PendingEvidence item) =>
        item.evidenceType
            .trim()
            .toLowerCase() ==
            'before',
      );

      final bool pendingAfter =
      pending.any(
            (_PendingEvidence item) =>
        item.evidenceType
            .trim()
            .toLowerCase() ==
            'after',
      );

      if (!hasBefore &&
          !pendingBefore) {
        return 'Before evidence is required for every corrective action.';
      }

      if (!hasAfter &&
          !pendingAfter) {
        return 'After evidence is required for every corrective action.';
      }
    }

    return null;
  }

  // ============================================================
  // SIGNED URL
  // ============================================================

  Future<String?> _signedUrl(
      Map<String, dynamic> attachment,
      ) async {
    final String attachmentId =
        attachment['id']?.toString() ?? '';

    if (attachmentId.isEmpty) {
      return null;
    }

    return '${CcrApiClient.baseUrl}'
        '/api/v1/ccr/attachments/$attachmentId/file';
  }
  // ============================================================
  // EXISTING IMAGE PREVIEW
  // ============================================================

  Widget _evidencePreview(
      Map<String, dynamic> evidence,
      ) {
    final dynamic rawAttachment =
    evidence['ccr_attachments'];

    if (rawAttachment is! Map) {
      return const Center(
        child: Icon(
          Icons.broken_image_outlined,
        ),
      );
    }

    final Map<String, dynamic>
    attachment =
    Map<String, dynamic>.from(
      rawAttachment,
    );

    return FutureBuilder<String?>(
      future: _signedUrl(
        attachment,
      ),
      builder: (
          BuildContext context,
          AsyncSnapshot<String?> snapshot,
          ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
            CircularProgressIndicator(),
          );
        }

        final String? url =
            snapshot.data;

        if (url == null ||
            url.isEmpty) {
          return const Center(
            child: Icon(
              Icons
                  .broken_image_outlined,
              size: 32,
            ),
          );
        }

        return ClipRRect(
          borderRadius:
          BorderRadius.circular(9),
          child: Image.network(
            url,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder:
                (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
                ) {
              return const Center(
                child: Icon(
                  Icons
                      .broken_image_outlined,
                  size: 32,
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // PENDING PREVIEW
  // ============================================================

  Widget _pendingPreview(
      _PendingEvidence evidence,
      ) {
    return ClipRRect(
      borderRadius:
      BorderRadius.circular(9),
      child: Image.memory(
        evidence.bytes,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  // ============================================================
  // ACTION CARD
  // ============================================================

  Widget _actionCard(
      Map<String, dynamic> action,
      int index,
      ) {
    final String actionId =
        action['id']?.toString() ??
            '';

    final List<Map<String, dynamic>>
    evidence =
        _evidenceByAction[actionId] ??
            <Map<String, dynamic>>[];

    final List<Map<String, dynamic>>
    before =
    evidence
        .where(
          (
          Map<String, dynamic> item,
          ) =>
      item['evidence_type']
          ?.toString()
          .trim()
          .toLowerCase() ==
          'before',
    )
        .toList();

    final List<Map<String, dynamic>>
    after =
    evidence
        .where(
          (
          Map<String, dynamic> item,
          ) =>
      item['evidence_type']
          ?.toString()
          .trim()
          .toLowerCase() ==
          'after',
    )
        .toList();

    final List<_PendingEvidence>
    pending =
        _pendingEvidence[actionId] ??
            <_PendingEvidence>[];

    final List<_PendingEvidence>
    pendingBefore =
    pending
        .where(
          (_PendingEvidence item) =>
      item.evidenceType
          .trim()
          .toLowerCase() ==
          'before',
    )
        .toList();

    final List<_PendingEvidence>
    pendingAfter =
    pending
        .where(
          (_PendingEvidence item) =>
      item.evidenceType
          .trim()
          .toLowerCase() ==
          'after',
    )
        .toList();

    return _surfaceCard(
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(
                Icons.build_circle_outlined,
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Text(
                  'Corrective Action ${index + 1}',
                  style:
                  const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
              _badge(
                'Before',
                before.isNotEmpty ||
                    pendingBefore.isNotEmpty,
              ),
              const SizedBox(
                width: 8,
              ),
              _badge(
                'After',
                after.isNotEmpty ||
                    pendingAfter.isNotEmpty,
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          _readOnly(
            'Problem Statement',
            action['problem_statement'],
          ),

          const SizedBox(
            height: 12,
          ),

          _readOnly(
            'Occurrence Root Cause',
            action['occurrence_root_cause'],
          ),

          const SizedBox(
            height: 12,
          ),

          _readOnly(
            'Non-Detection Root Cause',
            action['detection_root_cause'],
          ),

          const SizedBox(
            height: 12,
          ),

          _readOnly(
            'Corrective Action',
            action['corrective_action'],
          ),

          const SizedBox(
            height: 12,
          ),

          _readOnly(
            'DRI',
            action['dri'],
          ),

          const SizedBox(
            height: 12,
          ),

          _readOnly(
            'Result Before',
            action['result_before'],
          ),

          const SizedBox(
            height: 12,
          ),

          _readOnly(
            'Result After',
            action['result_after'],
          ),

          const SizedBox(
            height: 18,
          ),

          const Divider(),

          const SizedBox(
            height: 14,
          ),

          LayoutBuilder(
            builder: (
                BuildContext context,
                BoxConstraints constraints,
                ) {
              if (constraints.maxWidth <
                  700) {
                return Column(
                  children: [
                    _evidenceBox(
                      actionId:
                      actionId,
                      title: 'Before',
                      existing:
                      before,
                      pending:
                      pendingBefore,
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    _evidenceBox(
                      actionId:
                      actionId,
                      title: 'After',
                      existing:
                      after,
                      pending:
                      pendingAfter,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _evidenceBox(
                      actionId:
                      actionId,
                      title: 'Before',
                      existing:
                      before,
                      pending:
                      pendingBefore,
                    ),
                  ),
                  const SizedBox(
                    width: 14,
                  ),
                  Expanded(
                    child: _evidenceBox(
                      actionId:
                      actionId,
                      title: 'After',
                      existing:
                      after,
                      pending:
                      pendingAfter,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EVIDENCE BOX
  // ============================================================

  Widget _evidenceBox({
    required String actionId,
    required String title,
    required List<Map<String, dynamic>>
    existing,
    required List<_PendingEvidence>
    pending,
  }) {
    final int totalCount =
        existing.length + pending.length;

    return Container(
      constraints:
      const BoxConstraints(
        minHeight: 300,
      ),
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFF8F9FB),
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color:
          const Color(0xFFE2E5EA),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.fromLTRB(
              14,
              10,
              8,
              8,
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style:
                  const TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                if (totalCount > 0)
                  Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      const Color(
                        0xFFEFF3FF,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(
                        6,
                      ),
                    ),
                    child: Text(
                      '$totalCount',
                      style:
                      const TextStyle(
                        fontSize: 10,
                        fontWeight:
                        FontWeight.w700,
                        color:
                        Color(
                          0xFF3155C6,
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  tooltip:
                  'Add multiple $title images',
                  onPressed:
                  _saving ||
                      _completing
                      ? null
                      : () =>
                      _pickEvidence(
                        actionId:
                        actionId,
                        evidenceType:
                        title,
                      ),
                  icon:
                  const Icon(
                    Icons
                        .add_photo_alternate_outlined,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          const Divider(
            height: 1,
          ),

          Padding(
            padding:
            const EdgeInsets.all(10),
            child:
            totalCount == 0
                ? SizedBox(
              height: 230,
              child:
              _emptyEvidence(
                title,
              ),
            )
                : _imageGrid(
              actionId:
              actionId,
              existing:
              existing,
              pending:
              pending,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // IMAGE GRID
  // ============================================================

  Widget _imageGrid({
    required String actionId,
    required List<Map<String, dynamic>>
    existing,
    required List<_PendingEvidence>
    pending,
  }) {
    final int total =
        existing.length +
            pending.length;

    return GridView.builder(
      shrinkWrap: true,
      physics:
      const NeverScrollableScrollPhysics(),
      itemCount: total,
      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (
          BuildContext context,
          int index,
          ) {
        if (index <
            existing.length) {
          return _existingImageTile(
            existing[index],
          );
        }

        final int pendingIndex =
            index - existing.length;

        return _pendingImageTile(
          actionId: actionId,
          evidence:
          pending[pendingIndex],
        );
      },
    );
  }

  // ============================================================
  // SAVED IMAGE TILE
  // ============================================================

  Widget _existingImageTile(
      Map<String, dynamic> evidence,
      ) {
    return Container(
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(10),
        border: Border.all(
          color:
          const Color(0xFFE0E3E8),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding:
              const EdgeInsets.all(4),
              child:
              _evidencePreview(
                evidence,
              ),
            ),
          ),

          // Saved label
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 7,
                vertical: 4,
              ),
              decoration:
              BoxDecoration(
                color: Colors.black
                    .withValues(
                  alpha: 0.65,
                ),
                borderRadius:
                BorderRadius
                    .circular(6),
              ),
              child: const Text(
                'Saved',
                style:
                TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
          ),

          // DELETE BUTTON
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color:
              const Color(0xFFB42318),
              shape:
              const CircleBorder(),
              child: InkWell(
                customBorder:
                const CircleBorder(),
                onTap:
                _saving ||
                    _completing
                    ? null
                    : () =>
                    _deleteSavedEvidence(
                      evidence,
                    ),
                child:
                const Padding(
                  padding:
                  EdgeInsets.all(6),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PENDING IMAGE TILE
  // ============================================================

  Widget _pendingImageTile({
    required String actionId,
    required _PendingEvidence evidence,
  }) {
    return Container(
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(10),
        border: Border.all(
          color:
          const Color(0xFFE0E3E8),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding:
              const EdgeInsets.all(4),
              child:
              _pendingPreview(
                evidence,
              ),
            ),
          ),

          // Pending label
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 7,
                vertical: 4,
              ),
              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xFF7655C9,
                ),
                borderRadius:
                BorderRadius
                    .circular(6),
              ),
              child: const Text(
                'Pending upload',
                style:
                TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
          ),

          // DELETE PENDING IMAGE
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color:
              const Color(0xFFB42318),
              shape:
              const CircleBorder(),
              child: InkWell(
                customBorder:
                const CircleBorder(),
                onTap:
                _saving ||
                    _completing
                    ? null
                    : () =>
                    _removePendingEvidence(
                      actionId:
                      actionId,
                      evidence:
                      evidence,
                    ),
                child:
                const Padding(
                  padding:
                  EdgeInsets.all(6),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY EVIDENCE
  // ============================================================

  Widget _emptyEvidence(
      String title,
      ) {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          const Icon(
            Icons
                .photo_library_outlined,
            size: 36,
            color:
            Color(0xFF9AA1AB),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            'No $title evidence added',
            style:
            const TextStyle(
              fontSize: 12,
              color:
              Color(0xFF7B838D),
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          const Text(
            'Use the image button to add one or more images.',
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              fontSize: 11,
              color:
              Color(0xFF9AA1AB),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // READ ONLY
  // ============================================================

  Widget _readOnly(
      String label,
      dynamic value,
      ) {
    final String text =
        value?.toString().trim() ?? '';

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
          const TextStyle(
            fontSize: 12,
            fontWeight:
            FontWeight.w600,
            color:
            Color(0xFF626873),
          ),
        ),
        const SizedBox(
          height: 6,
        ),
        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.all(12),
          decoration:
          BoxDecoration(
            color:
            const Color(0xFFF8F9FB),
            borderRadius:
            BorderRadius.circular(10),
            border: Border.all(
              color:
              const Color(0xFFE2E5EA),
            ),
          ),
          child: Text(
            text.isEmpty
                ? '-'
                : text,
            style:
            const TextStyle(
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BADGE
  // ============================================================

  Widget _badge(
      String text,
      bool complete,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration:
      BoxDecoration(
        color: complete
            ? const Color(0xFFEAF7EF)
            : const Color(0xFFF3F4F6),
        borderRadius:
        BorderRadius.circular(8),
      ),
      child: Text(
        complete
            ? '$text ✓'
            : text,
        style:
        TextStyle(
          fontSize: 11,
          fontWeight:
          FontWeight.w700,
          color: complete
              ? const Color(0xFF2E9B55)
              : const Color(0xFF626873),
        ),
      ),
    );
  }

  // ============================================================
  // SURFACE
  // ============================================================

  Widget _surfaceCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(20),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color:
          const Color(0xFFE3E6EB),
        ),
      ),
      child: child,
    );
  }

  // ============================================================
  // ICON BOX
  // ============================================================

  Widget _iconBox(
      IconData icon,
      ) {
    return Container(
      width: 40,
      height: 40,
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFEFF3FF),
        borderRadius:
        BorderRadius.circular(11),
      ),
      child: Icon(
        icon,
        color:
        const Color(0xFF3155C6),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _appBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor:
      Colors.white,
      foregroundColor:
      const Color(0xFF172033),
      title: Row(
        children: [
          _iconBox(
            Icons.photo_library_outlined,
          ),
          const SizedBox(
            width: 12,
          ),
          Text(
            _ccr?.displayNumber ??
                'CCR',
            style:
            const TextStyle(
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed:
          _loading ||
              _saving ||
              _completing
              ? null
              : _load,
          icon:
          const Icon(
            Icons.refresh_rounded,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    if (_loading) {
      return const Scaffold(
        backgroundColor:
        Color(0xFFF5F7FB),
        body: Center(
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor:
        const Color(0xFFF5F7FB),
        appBar: _appBar(),
        body: _errorView(),
      );
    }

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),
      appBar: _appBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 1250,
            ),
            child:
            SingleChildScrollView(
              padding:
              const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(
                    height: 20,
                  ),
                  _summary(),
                  const SizedBox(
                    height: 18,
                  ),
                  if (_actions.isEmpty)
                    _surfaceCard(
                      child:
                      const Text(
                        'No corrective actions found.',
                      ),
                    )
                  else
                    ...List.generate(
                      _actions.length,
                          (
                          int index,
                          ) =>
                          Padding(
                            padding:
                            const EdgeInsets
                                .only(
                              bottom: 18,
                            ),
                            child:
                            _actionCard(
                              _actions[index],
                              index,
                            ),
                          ),
                    ),
                  _actionBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header() {
    return Row(
      children: [
        const Icon(
          Icons.photo_library_outlined,
          size: 24,
          color:
          Color(0xFF3155C6),
        ),
        const SizedBox(
          width: 12,
        ),
        const Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Evidence of Corrective Action',
                style:
                TextStyle(
                  fontSize: 20,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
              SizedBox(
                height: 4,
              ),
              Text(
                'Record objective evidence supporting the implemented corrective action.',
                style:
                TextStyle(
                  fontSize: 12.5,
                  color:
                  Color(0xFF7A818C),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _summary() {
    return _surfaceCard(
      child: Row(
        children: [
          _iconBox(
            Icons.assignment_outlined,
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  _ccr?.displayNumber ??
                      'CCR',
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  _ccr?.problemDescription ??
                      '-',
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 12.5,
                    color:
                    Color(0xFF747B86),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BAR
  // ============================================================

  Widget _actionBar() {
    return _surfaceCard(
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed:
            _saving ||
                _completing
                ? null
                : _saveDraft,
            icon:
            const Icon(
              Icons.save_outlined,
            ),
            label:
            const Text(
              'Save Draft',
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          FilledButton.icon(
            onPressed:
            _saving ||
                _completing
                ? null
                : _complete,
            style:
            FilledButton.styleFrom(
              backgroundColor:
              const Color(
                0xFF7655C9,
              ),
            ),
            icon:
            _completing
                ? const SizedBox(
              width: 17,
              height: 17,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
                color:
                Colors.white,
              ),
            )
                : const Icon(
              Icons.arrow_forward,
            ),
            label:
            const Text(
              'Complete & Continue',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR VIEW
  // ============================================================

  Widget _errorView() {
    return Center(
      child: _surfaceCard(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 42,
              color:
              Color(0xFFE14B4B),
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              'Could not load Evidence',
              style:
              TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              _error ?? '',
              textAlign:
              TextAlign.center,
            ),
            const SizedBox(
              height: 18,
            ),
            FilledButton(
              onPressed: _load,
              child:
              const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  List<Map<String, dynamic>>
  _asMapList(dynamic value) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map(
          (Map item) =>
      Map<String, dynamic>.from(
        item,
      ),
    )
        .toList();
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  String _fileExtension(
      String fileName,
      ) {
    final int index =
    fileName.lastIndexOf('.');

    if (index < 0) {
      return 'jpg';
    }

    final String extension =
    fileName
        .substring(index + 1)
        .trim()
        .toLowerCase();

    return extension.isEmpty
        ? 'jpg'
        : extension;
  }

  String _contentType(
      String extension,
      ) {
    switch (extension) {
      case 'png':
        return 'image/png';

      case 'webp':
        return 'image/webp';

      case 'gif':
        return 'image/gif';

      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  String _cleanError(
      dynamic error,
      ) {
    return error
        .toString()
        .replaceFirst(
      'Exception: ',
      '',
    );
  }

  void _showMessage(
      String message, {
        bool error = false,
      }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
        Text(message),
        backgroundColor:
        error
            ? const Color(
          0xFFC62828,
        )
            : null,
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// ============================================================
// PENDING EVIDENCE MODEL
// ============================================================

class _PendingEvidence {
  final String evidenceType;
  final Uint8List bytes;
  final String fileName;

  const _PendingEvidence({
    required this.evidenceType,
    required this.bytes,
    required this.fileName,
  });
}