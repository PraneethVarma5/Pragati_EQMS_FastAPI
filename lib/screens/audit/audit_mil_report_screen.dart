// import 'package:flutter/material.dart';
//
// import '../../services/supabase_service.dart';
// import '../../services/audit_pdf_service.dart';
//
// class AuditMilReportScreen extends StatefulWidget {
//   final String auditId;
//
//   const AuditMilReportScreen({
//     super.key,
//     required this.auditId,
//   });
//
//   @override
//   State<AuditMilReportScreen> createState() =>
//       _AuditMilReportScreenState();
// }
//
// class _AuditMilReportScreenState
//     extends State<AuditMilReportScreen> {
//   List<Map<String, dynamic>> _items = [];
//
//   final Map<String, TextEditingController>
//   _rootCauseControllers = {};
//
//   final Map<String, TextEditingController>
//   _correctiveActionControllers = {};
//
//   final Map<String, TextEditingController>
//   _driNameControllers = {};
//
//   final Map<String, TextEditingController>
//   _driMailControllers = {};
//
//   final Map<String, TextEditingController>
//   _deadlineControllers = {};
//
//   final Map<String, String?> _statuses = {};
//
//   bool _loading = true;
//   bool _saving = false;
//   bool _milClosed = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadMilItems();
//   }
//
//   @override
//   void dispose() {
//     _disposeControllers();
//     super.dispose();
//   }
//
//   void _disposeControllers() {
//     for (final controller
//     in _rootCauseControllers.values) {
//       controller.dispose();
//     }
//
//     for (final controller
//     in _correctiveActionControllers.values) {
//       controller.dispose();
//     }
//
//     for (final controller
//     in _driNameControllers.values) {
//       controller.dispose();
//     }
//
//     for (final controller
//     in _driMailControllers.values) {
//       controller.dispose();
//     }
//
//     for (final controller
//     in _deadlineControllers.values) {
//       controller.dispose();
//     }
//
//     _rootCauseControllers.clear();
//     _correctiveActionControllers.clear();
//     _driNameControllers.clear();
//     _driMailControllers.clear();
//     _deadlineControllers.clear();
//     _statuses.clear();
//   }
//
//   Future<void> _loadMilItems() async {
//     try {
//       final audit =
//       await SupabaseService.getAuditMilStatus(
//         widget.auditId,
//       );
//
//       final milClosed =
//           audit['mil_status']
//               ?.toString()
//               .trim()
//               .toLowerCase() ==
//               'closed';
//
//       final items =
//       await SupabaseService.getAuditMilItems(
//         widget.auditId,
//       ).timeout(
//         const Duration(seconds: 20),
//       );
//
//       // Dispose old controllers before rebuilding them.
//       _disposeControllers();
//
//       for (final item in items) {
//         final id =
//         item['mil_item_id']?.toString();
//
//         if (id == null || id.isEmpty) {
//           continue;
//         }
//
//         _rootCauseControllers[id] =
//             TextEditingController(
//               text:
//               item['root_cause']?.toString() ?? '',
//             );
//
//         _correctiveActionControllers[id] =
//             TextEditingController(
//               text:
//               item['corrective_action']
//                   ?.toString() ??
//                   '',
//             );
//
//         _driNameControllers[id] =
//             TextEditingController(
//               text:
//               item['dri_name']?.toString() ?? '',
//             );
//
//         _driMailControllers[id] =
//             TextEditingController(
//               text:
//               item['dri_mail']?.toString() ?? '',
//             );
//
//         _deadlineControllers[id] =
//             TextEditingController(
//               text:
//               item['deadline']?.toString() ?? '',
//             );
//
//         _statuses[id] =
//             item['overall_status']?.toString() ??
//                 'Open';
//       }
//
//       if (!mounted) return;
//
//       setState(() {
//         _items = items;
//         _milClosed = milClosed;
//         _loading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//
//       setState(() {
//         _loading = false;
//       });
//
//       _showError(
//         'Unable to load MIL Report: $e',
//       );
//     }
//   }
//
//   Future<void> _selectDeadline(
//       String itemId,
//       ) async {
//     if (_milClosed) {
//       return;
//     }
//
//     final controller =
//     _deadlineControllers[itemId];
//
//     if (controller == null) {
//       return;
//     }
//
//     DateTime initialDate = DateTime.now();
//
//     if (controller.text.trim().isNotEmpty) {
//       final parsed = DateTime.tryParse(
//         controller.text.trim(),
//       );
//
//       if (parsed != null) {
//         initialDate = parsed;
//       }
//     }
//
//     final selected = await showDatePicker(
//       context: context,
//       initialDate: initialDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//     );
//
//     if (selected == null) {
//       return;
//     }
//
//     final month =
//     selected.month.toString().padLeft(2, '0');
//
//     final day =
//     selected.day.toString().padLeft(2, '0');
//
//     controller.text =
//     '${selected.year}-$month-$day';
//   }
//
//   Future<void> _saveMilItem(
//       Map<String, dynamic> item,
//       ) async {
//     if (_milClosed) {
//       return;
//     }
//
//     final id =
//     item['mil_item_id']?.toString();
//
//     if (id == null || id.isEmpty) {
//       return;
//     }
//
//     await SupabaseService.updateAuditMilItem(
//       milItemId: id,
//       rootCause:
//       _rootCauseControllers[id]
//           ?.text
//           .trim(),
//       correctiveAction:
//       _correctiveActionControllers[id]
//           ?.text
//           .trim(),
//       driName:
//       _driNameControllers[id]
//           ?.text
//           .trim(),
//       driMail:
//       _driMailControllers[id]
//           ?.text
//           .trim(),
//       deadline:
//       _deadlineControllers[id]
//           ?.text
//           .trim(),
//       overallStatus:
//       _statuses[id],
//     );
//   }
//
//   Future<void> _saveReport() async {
//     if (_saving || _milClosed) {
//       return;
//     }
//
//     setState(() {
//       _saving = true;
//     });
//
//     try {
//       for (final item in _items) {
//         await _saveMilItem(item);
//       }
//
//       await _loadMilItems();
//
//       if (!mounted) return;
//
//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'MIL Report saved successfully.',
//           ),
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//
//       _showError(
//         'Unable to save MIL Report: $e',
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _saving = false;
//         });
//       }
//     }
//   }
//
//   Future<void> _closeMil() async {
//     if (_saving || _milClosed) {
//       return;
//     }
//
//     final hasOpenItems = _items.any(
//           (item) =>
//       (_statuses[
//       item['mil_item_id']
//           ?.toString()] ??
//           item['overall_status']?.toString() ??
//           'Open') !=
//           'Closed',
//     );
//
//     if (hasOpenItems) {
//       _showError(
//         'Every MIL item must be Closed before closing the MIL.',
//       );
//       return;
//     }
//
//     setState(() {
//       _saving = true;
//     });
//
//     try {
//       await SupabaseService.closeAuditMil(
//         widget.auditId,
//       );
//
//       if (!mounted) return;
//
//       await _loadMilItems();
//
//       if (!mounted) return;
//
//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'MIL closed successfully. Audit completed.',
//           ),
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//
//       _showError(
//         'Unable to close MIL: $e',
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _saving = false;
//         });
//       }
//     }
//   }
//
//   Future<void> _downloadMilReport() async {
//     if (_saving) {
//       return;
//     }
//
//     try {
//       await AuditPdfService.downloadMilReport(
//         widget.auditId,
//       );
//
//       if (!mounted) return;
//
//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'MIL Report downloaded successfully.',
//           ),
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//
//       _showError(
//         'Unable to download MIL Report: $e',
//       );
//     }
//   }
//
//   void _showError(String message) {
//     if (!mounted) return;
//
//     ScaffoldMessenger.of(context)
//         .showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red.shade700,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             const Text('MIL Report'),
//             if (_milClosed) ...[
//               const SizedBox(width: 12),
//               Container(
//                 padding:
//                 const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 5,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.green.shade100,
//                   borderRadius:
//                   BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   'CLOSED',
//                   style: TextStyle(
//                     color: Colors.green.shade800,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//         actions: [
//           IconButton(
//             tooltip: 'Download MIL Report',
//             onPressed:
//             _saving ? null : _downloadMilReport,
//             icon: const Icon(
//               Icons.download_outlined,
//             ),
//           ),
//
//           if (!_milClosed)
//             IconButton(
//               tooltip: 'Save MIL Report',
//               onPressed:
//               _saving ? null : _saveReport,
//               icon: _saving
//                   ? const SizedBox(
//                 width: 20,
//                 height: 20,
//                 child:
//                 CircularProgressIndicator(
//                   strokeWidth: 2,
//                 ),
//               )
//                   : const Icon(
//                 Icons.save_outlined,
//               ),
//             ),
//         ],
//       ),
//       body: SafeArea(
//         child: _loading
//             ? const Center(
//           child:
//           CircularProgressIndicator(),
//         )
//             : _buildBody(),
//       ),
//     );
//   }
//
//   Widget _buildBody() {
//     if (_items.isEmpty) {
//       return const Center(
//         child: Padding(
//           padding: EdgeInsets.all(24),
//           child: Text(
//             'No MIL items were generated for this audit.',
//             textAlign: TextAlign.center,
//           ),
//         ),
//       );
//     }
//
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24),
//       child: Center(
//         child: ConstrainedBox(
//           constraints:
//           const BoxConstraints(
//             maxWidth: 1200,
//           ),
//           child: Column(
//             crossAxisAlignment:
//             CrossAxisAlignment.stretch,
//             children: [
//               _buildSummary(),
//               const SizedBox(height: 20),
//
//               ...List.generate(
//                 _items.length,
//                     (index) => _buildMilCard(
//                   _items[index],
//                   index,
//                 ),
//               ),
//
//               if (!_milClosed) ...[
//                 const SizedBox(height: 12),
//                 _buildSaveButton(),
//                 const SizedBox(height: 12),
//                 _buildCloseButton(),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSummary() {
//     final closed = _items.where(
//           (item) {
//         final id =
//         item['mil_item_id']?.toString();
//
//         final status =
//             _statuses[id] ??
//                 item['overall_status']
//                     ?.toString() ??
//                 'Open';
//
//         return status == 'Closed';
//       },
//     ).length;
//
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Row(
//           children: [
//             Icon(
//               _milClosed
//                   ? Icons.lock_outline
//                   : Icons.assignment_late_outlined,
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 _milClosed
//                     ? 'MIL Report - Closed'
//                     : 'MIL Items: ${_items.length}',
//                 style: Theme.of(context)
//                     .textTheme
//                     .titleLarge
//                     ?.copyWith(
//                   fontWeight:
//                   FontWeight.bold,
//                 ),
//               ),
//             ),
//             Text(
//               '$closed / ${_items.length} Closed',
//               style: const TextStyle(
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMilCard(
//       Map<String, dynamic> item,
//       int index,
//       ) {
//     final id =
//         item['mil_item_id']?.toString() ?? '';
//
//     final question =
//         item['question']?.toString() ?? '';
//
//     final description =
//         item['description']?.toString() ?? '';
//
//     final defectType =
//         item['defect_type']?.toString() ?? '';
//
//     return Card(
//       margin:
//       const EdgeInsets.only(bottom: 18),
//       elevation: 1,
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment:
//           CrossAxisAlignment.start,
//           children: [
//             Row(
//               crossAxisAlignment:
//               CrossAxisAlignment.start,
//               children: [
//                 CircleAvatar(
//                   child: Text(
//                     '${index + 1}',
//                   ),
//                 ),
//                 const SizedBox(width: 14),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment:
//                     CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         question,
//                         style: Theme.of(context)
//                             .textTheme
//                             .titleMedium
//                             ?.copyWith(
//                           fontWeight:
//                           FontWeight.bold,
//                         ),
//                       ),
//                       if (description
//                           .isNotEmpty) ...[
//                         const SizedBox(height: 8),
//                         Text(description),
//                       ],
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Chip(
//                   label: Text(defectType),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 20),
//
//             _buildInput(
//               'Root Cause',
//               _rootCauseControllers[id],
//               maxLines: 3,
//             ),
//
//             const SizedBox(height: 14),
//
//             _buildInput(
//               'Corrective Action',
//               _correctiveActionControllers[id],
//               maxLines: 3,
//             ),
//
//             const SizedBox(height: 14),
//
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildInput(
//                     'DRI Name',
//                     _driNameControllers[id],
//                     maxLines: 1,
//                   ),
//                 ),
//                 const SizedBox(width: 14),
//                 Expanded(
//                   child: _buildInput(
//                     'DRI Mail',
//                     _driMailControllers[id],
//                     maxLines: 1,
//                     keyboardType:
//                     TextInputType.emailAddress,
//                   ),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 14),
//
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller:
//                     _deadlineControllers[id],
//                     readOnly: true,
//                     enabled: !_milClosed,
//                     onTap: _milClosed
//                         ? null
//                         : () =>
//                         _selectDeadline(id),
//                     decoration:
//                     InputDecoration(
//                       labelText: 'Deadline',
//                       border:
//                       const OutlineInputBorder(),
//                       filled: _milClosed,
//                       suffixIcon: const Icon(
//                         Icons
//                             .calendar_today_outlined,
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(width: 14),
//
//                 Expanded(
//                   child:
//                   DropdownButtonFormField<
//                       String>(
//                     value: _statuses[id],
//                     items: const [
//                       DropdownMenuItem(
//                         value: 'Open',
//                         child: Text('Open'),
//                       ),
//                       DropdownMenuItem(
//                         value: 'In Progress',
//                         child: Text(
//                           'In Progress',
//                         ),
//                       ),
//                       DropdownMenuItem(
//                         value: 'Closed',
//                         child: Text('Closed'),
//                       ),
//                     ],
//                     onChanged: _milClosed
//                         ? null
//                         : (value) {
//                       setState(() {
//                         _statuses[id] =
//                             value;
//                       });
//                     },
//                     decoration:
//                     const InputDecoration(
//                       labelText:
//                       'Overall Status',
//                       border:
//                       OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInput(
//       String label,
//       TextEditingController? controller, {
//         int maxLines = 1,
//         TextInputType? keyboardType,
//       }) {
//     return TextField(
//       controller: controller,
//       readOnly: _milClosed,
//       enabled: !_milClosed,
//       maxLines: maxLines,
//       keyboardType: keyboardType,
//       decoration: InputDecoration(
//         labelText: label,
//         border: const OutlineInputBorder(),
//         filled: _milClosed,
//       ),
//     );
//   }
//
//   Widget _buildSaveButton() {
//     return SizedBox(
//       height: 52,
//       child: ElevatedButton.icon(
//         onPressed:
//         _saving || _milClosed
//             ? null
//             : _saveReport,
//         icon: const Icon(
//           Icons.save_outlined,
//         ),
//         label: Text(
//           _saving
//               ? 'Saving...'
//               : 'Save MIL Report',
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCloseButton() {
//     return SizedBox(
//       height: 52,
//       child: OutlinedButton.icon(
//         onPressed:
//         _saving || _milClosed
//             ? null
//             : _closeMil,
//         icon: const Icon(
//           Icons.lock_outline,
//         ),
//         label: const Text('Close MIL'),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../services/audit_pdf_service.dart';

class AuditMilReportScreen extends StatefulWidget {
  final String auditId;

  const AuditMilReportScreen({
    super.key,
    required this.auditId,
  });

  @override
  State<AuditMilReportScreen> createState() =>
      _AuditMilReportScreenState();
}

class _AuditMilReportScreenState
    extends State<AuditMilReportScreen> {
  List<Map<String, dynamic>> _items = [];

  final Map<String, TextEditingController>
  _rootCauseControllers = {};

  final Map<String, TextEditingController>
  _correctiveActionControllers = {};

  final Map<String, TextEditingController>
  _driNameControllers = {};

  final Map<String, TextEditingController>
  _driMailControllers = {};

  final Map<String, TextEditingController>
  _deadlineControllers = {};

  final Map<String, String> _statuses = {};

  bool _loading = true;
  bool _saving = false;
  bool _milClosed = false;

  @override
  void initState() {
    super.initState();
    _loadMilItems();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  // ============================================================
  // CONTROLLER CLEANUP
  // ============================================================

  void _disposeControllers() {
    for (final controller
    in _rootCauseControllers.values) {
      controller.dispose();
    }

    for (final controller
    in _correctiveActionControllers.values) {
      controller.dispose();
    }

    for (final controller
    in _driNameControllers.values) {
      controller.dispose();
    }

    for (final controller
    in _driMailControllers.values) {
      controller.dispose();
    }

    for (final controller
    in _deadlineControllers.values) {
      controller.dispose();
    }

    _rootCauseControllers.clear();
    _correctiveActionControllers.clear();
    _driNameControllers.clear();
    _driMailControllers.clear();
    _deadlineControllers.clear();
    _statuses.clear();
  }

  // ============================================================
  // LOAD MIL
  // ============================================================

  Future<void> _loadMilItems() async {
    try {
      final audit =
      await SupabaseService.getAuditMilStatus(
        widget.auditId,
      );

      final milStatus =
      audit['mil_status']
          ?.toString()
          .trim()
          .toLowerCase();

      final items =
      await SupabaseService.getAuditMilItems(
        widget.auditId,
      ).timeout(
        const Duration(seconds: 20),
      );

      _disposeControllers();

      for (final item in items) {
        final id =
        item['mil_item_id']
            ?.toString()
            .trim();

        if (id == null || id.isEmpty) {
          continue;
        }

        _rootCauseControllers[id] =
            TextEditingController(
              text:
              item['root_cause']
                  ?.toString() ??
                  '',
            );

        _correctiveActionControllers[id] =
            TextEditingController(
              text:
              item['corrective_action']
                  ?.toString() ??
                  '',
            );

        _driNameControllers[id] =
            TextEditingController(
              text:
              item['dri_name']
                  ?.toString() ??
                  '',
            );

        _driMailControllers[id] =
            TextEditingController(
              text:
              item['dri_mail']
                  ?.toString() ??
                  '',
            );

        _deadlineControllers[id] =
            TextEditingController(
              text:
              item['deadline']
                  ?.toString() ??
                  '',
            );

        final status =
        item['overall_status']
            ?.toString()
            .trim();

        _statuses[id] =
        status == 'Closed' ||
            status == 'In Progress' ||
            status == 'Open'
            ? status!
            : 'Open';
      }

      if (!mounted) return;

      setState(() {
        _items = items;
        _milClosed =
            milStatus == 'closed';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showError(
        'Unable to load MIL Report: $e',
      );
    }
  }

  // ============================================================
  // DEADLINE
  // ============================================================

  Future<void> _selectDeadline(
      String id,
      ) async {
    if (_milClosed) {
      return;
    }

    final controller =
    _deadlineControllers[id];

    if (controller == null) {
      return;
    }

    DateTime initialDate =
    DateTime.now();

    if (controller.text
        .trim()
        .isNotEmpty) {
      final parsed =
      DateTime.tryParse(
        controller.text.trim(),
      );

      if (parsed != null) {
        initialDate = parsed;
      }
    }

    final selected =
    await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate:
      DateTime(2000),
      lastDate:
      DateTime(2100),
    );

    if (selected == null) {
      return;
    }

    final month =
    selected.month
        .toString()
        .padLeft(2, '0');

    final day =
    selected.day
        .toString()
        .padLeft(2, '0');

    controller.text =
    '${selected.year}-$month-$day';
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _saveReport() async {
    if (_saving || _milClosed) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      for (final item in _items) {
        final id =
        item['mil_item_id']
            ?.toString()
            .trim();

        if (id == null || id.isEmpty) {
          continue;
        }

        await SupabaseService
            .updateAuditMilItem(
          milItemId: id,
          rootCause:
          _rootCauseControllers[id]
              ?.text
              .trim(),
          correctiveAction:
          _correctiveActionControllers[
          id]
              ?.text
              .trim(),
          driName:
          _driNameControllers[id]
              ?.text
              .trim(),
          driMail:
          _driMailControllers[id]
              ?.text
              .trim(),
          deadline:
          _deadlineControllers[id]
              ?.text
              .trim(),
          overallStatus:
          _statuses[id],
        );
      }

      await _loadMilItems();

      if (!mounted) return;

      _showMessage(
        'MIL Report saved successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Unable to save MIL Report: $e',
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
  // CLOSE MIL
  // ============================================================

  Future<void> _closeMil() async {
    if (_saving || _milClosed) {
      return;
    }

    final hasOpenItems =
    _items.any(
          (item) {
        final id =
        item['mil_item_id']
            ?.toString()
            .trim();

        return _statuses[id] !=
            'Closed';
      },
    );

    if (hasOpenItems) {
      _showError(
        'Every MIL item must be Closed before closing the MIL.',
      );
      return;
    }

    final confirmed =
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title:
          const Text(
            'Close MIL Report',
          ),
          content:
          const Text(
            'Once the MIL is closed, all MIL fields will become read-only and the Audit will be completed.\n\nContinue?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                    context,
                    false,
                  ),
              child:
              const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                    context,
                    true,
                  ),
              child:
              const Text(
                'Close MIL',
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
      await SupabaseService.closeAuditMil(
        widget.auditId,
      );

      if (!mounted) return;

      await _loadMilItems();

      if (!mounted) return;

      _showMessage(
        'MIL closed successfully. Audit completed.',
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Unable to close MIL: $e',
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
  // DOWNLOAD
  // ============================================================

  Future<void> _downloadMilReport() async {
    if (_saving) {
      return;
    }

    try {
      await AuditPdfService
          .downloadMilReport(
        widget.auditId,
      );

      if (!mounted) return;

      _showMessage(
        'MIL Report downloaded successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Unable to download MIL Report: $e',
      );
    }
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
        title: Row(
          children: [
            const Text(
              'MIL Report',
              style: TextStyle(
                fontWeight:
                FontWeight.w700,
              ),
            ),
            if (_milClosed) ...[
              const SizedBox(width: 12),
              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration:
                BoxDecoration(
                  color:
                  Colors.green.shade100,
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  'CLOSED',
                  style: TextStyle(
                    color:
                    Colors.green.shade800,
                    fontWeight:
                    FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip:
            'Download MIL Report',
            onPressed:
            _saving
                ? null
                : _downloadMilReport,
            icon: const Icon(
              Icons.download_outlined,
            ),
          ),
          if (!_milClosed)
            IconButton(
              tooltip:
              'Save MIL Report',
              onPressed:
              _saving
                  ? null
                  : _saveReport,
              icon: _saving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Icon(
                Icons.save_outlined,
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
    if (_items.isEmpty) {
      return const Center(
        child: Text(
          'No MIL items were generated for this audit.',
        ),
      );
    }

    return SingleChildScrollView(
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
              _buildHeader(),

              const SizedBox(
                height: 18,
              ),

              ...List.generate(
                _items.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildMilFindingCard(_items[index], index),
                ),
              ),

              if (!_milClosed) ...[
                const SizedBox(
                  height: 18,
                ),
                _buildBottomActions(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final closedCount =
        _items.where(
              (item) {
            final id =
            item['mil_item_id']
                ?.toString();

            return _statuses[id] ==
                'Closed';
          },
        ).length;

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
                color:
                Theme.of(context)
                    .colorScheme
                    .primaryContainer,
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
              ),
              child: Icon(
                _milClosed
                    ? Icons.lock_outline
                    : Icons
                    .assignment_late_outlined,
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
                  Text(
                    _milClosed
                        ? 'MIL Report - Closed'
                        : 'MIL Report',
                    style:
                    const TextStyle(
                      fontSize: 22,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    _milClosed
                        ? 'This report is read-only.'
                        : 'Enter root cause, corrective action and ownership details.',
                    style: TextStyle(
                      color:
                      Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$closedCount / ${_items.length} Closed',
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MIL FINDING CARD
  // ============================================================

  Widget _buildMilFindingCard(
      Map<String, dynamic> item,
      int index,
      ) {
    final id = item['mil_item_id']?.toString().trim() ?? '';
    final issue = _value(item['question']);
    final category = _value(item['defect_type']);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 17,
                  child: Text('${index + 1}'),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Text(
                      'MIL Finding',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: _categoryCell(category),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _infoField('Issue', issue),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 14.0;
                final fieldWidth = (constraints.maxWidth - gap * 2) / 3;
                return Wrap(
                  spacing: gap,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      child: _buildInput(
                        'Root Cause',
                        _rootCauseControllers[id],
                        maxLines: 3,
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: _buildInput(
                        'Corrective Action',
                        _correctiveActionControllers[id],
                        maxLines: 3,
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: _buildInput(
                        'DRI Name',
                        _driNameControllers[id],
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: _buildInput(
                        'Mail ID',
                        _driMailControllers[id],
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: _deadlineField(id),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: _statusField(id),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value.isEmpty ? '-' : value,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildInput(
      String label,
      TextEditingController? controller, {
        int maxLines = 1,
        TextInputType? keyboardType,
      }) {
    return TextField(
      controller: controller,
      readOnly: _milClosed,
      enabled: !_milClosed,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        filled: _milClosed,
      ),
    );
  }

  Widget _deadlineField(String id) {
    return TextField(
      controller: _deadlineControllers[id],
      enabled: !_milClosed,
      readOnly: true,
      onTap: _milClosed ? null : () => _selectDeadline(id),
      decoration: InputDecoration(
        labelText: 'Deadline',
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        filled: _milClosed,
      ),
    );
  }

  Widget _statusField(String id) {
    return DropdownButtonFormField<String>(
      value: _statuses[id] ?? 'Open',
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Overall Status',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(value: 'Open', child: Text('Open')),
        DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
        DropdownMenuItem(value: 'Closed', child: Text('Closed')),
      ],
      onChanged: _milClosed
          ? null
          : (value) {
              if (value == null) return;
              setState(() => _statuses[id] = value);
            },
    );
  }

  // ============================================================
  // TABLE (kept for reference; card layout is used by the screen)
  // ============================================================

  Widget _buildTable() {
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
          dataRowMinHeight: 90,
          dataRowMaxHeight: 150,
          columnSpacing: 18,
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
              label: Text('Issue'),
            ),
            DataColumn(
              label:
              Text('Finding category'),
            ),
            DataColumn(
              label: Text('Root cause'),
            ),
            DataColumn(
              label:
              Text('Corrective action'),
            ),
            DataColumn(
              label: Text('DRI Name'),
            ),
            DataColumn(
              label: Text('Mail ID'),
            ),
            DataColumn(
              label: Text('Deadline'),
            ),
            DataColumn(
              label:
              Text('Overall Status'),
            ),
          ],
          rows: List.generate(
            _items.length,
                (index) {
              final item =
              _items[index];

              final id =
                  item['mil_item_id']
                      ?.toString()
                      .trim() ??
                      '';

              final issue =
              _value(
                item['question'],
              );

              final findingCategory =
              _value(
                item['defect_type'],
              );

              return DataRow(
                cells: [
                  DataCell(
                    Center(
                      child: Text(
                        '${index + 1}',
                      ),
                    ),
                  ),

                  DataCell(
                    _textCell(
                      issue,
                      width: 300,
                    ),
                  ),

                  DataCell(
                    _categoryCell(
                      findingCategory,
                    ),
                  ),

                  DataCell(
                    _editableCell(
                      _rootCauseControllers[
                      id],
                      width: 250,
                    ),
                  ),

                  DataCell(
                    _editableCell(
                      _correctiveActionControllers[
                      id],
                      width: 280,
                    ),
                  ),

                  DataCell(
                    _editableCell(
                      _driNameControllers[id],
                      width: 170,
                    ),
                  ),

                  DataCell(
                    _editableCell(
                      _driMailControllers[id],
                      width: 210,
                      keyboardType:
                      TextInputType
                          .emailAddress,
                    ),
                  ),

                  DataCell(
                    _deadlineCell(
                      id,
                    ),
                  ),

                  DataCell(
                    _statusDropdown(
                      id,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TABLE CELLS
  // ============================================================

  Widget _textCell(
      String value, {
        double width = 220,
      }) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        maxLines: 5,
        overflow:
        TextOverflow.ellipsis,
      ),
    );
  }

  Widget _categoryCell(
      String value,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.orange.shade100,
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        value,
        style: TextStyle(
          color:
          Colors.orange.shade900,
          fontWeight:
          FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _editableCell(
      TextEditingController? controller, {
        double width = 220,
        TextInputType? keyboardType,
      }) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        enabled: !_milClosed,
        readOnly: _milClosed,
        maxLines: 3,
        keyboardType:
        keyboardType,
        decoration:
        InputDecoration(
          border:
          const OutlineInputBorder(),
          isDense: true,
          filled: _milClosed,
          fillColor:
          _milClosed
              ? Colors.grey.shade100
              : null,
        ),
      ),
    );
  }

  Widget _deadlineCell(
      String id,
      ) {
    return SizedBox(
      width: 150,
      child: TextField(
        controller:
        _deadlineControllers[id],
        enabled: !_milClosed,
        readOnly: true,
        onTap: _milClosed
            ? null
            : () =>
            _selectDeadline(id),
        decoration:
        InputDecoration(
          border:
          const OutlineInputBorder(),
          isDense: true,
          suffixIcon:
          const Icon(
            Icons
                .calendar_today_outlined,
            size: 18,
          ),
          filled: _milClosed,
          fillColor:
          _milClosed
              ? Colors.grey.shade100
              : null,
        ),
      ),
    );
  }

  Widget _statusDropdown(
      String id,
      ) {
    return SizedBox(
      width: 150,
      child:
      DropdownButtonFormField<
          String>(
        value:
        _statuses[id] ??
            'Open',
        isExpanded: true,
        decoration:
        const InputDecoration(
          border:
          OutlineInputBorder(),
          isDense: true,
        ),
        items: const [
          DropdownMenuItem(
            value: 'Open',
            child: Text('Open'),
          ),
          DropdownMenuItem(
            value: 'In Progress',
            child:
            Text('In Progress'),
          ),
          DropdownMenuItem(
            value: 'Closed',
            child:
            Text('Closed'),
          ),
        ],
        onChanged: _milClosed
            ? null
            : (value) {
          if (value == null) {
            return;
          }

          setState(() {
            _statuses[id] =
                value;
          });
        },
      ),
    );
  }

  // ============================================================
  // BOTTOM ACTIONS
  // ============================================================

  Widget _buildBottomActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed:
            _saving
                ? null
                : _saveReport,
            icon: const Icon(
              Icons.save_outlined,
            ),
            label: Text(
              _saving
                  ? 'Saving...'
                  : 'Save MIL Report',
            ),
          ),
        ),
        const SizedBox(
          width: 14,
        ),
        Expanded(
          child: FilledButton.icon(
            onPressed:
            _saving
                ? null
                : _closeMil,
            icon: const Icon(
              Icons.lock_outline,
            ),
            label:
            const Text(
              'Close MIL',
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _value(
      dynamic value,
      ) {
    final text =
        value?.toString().trim() ??
            '';

    return text.isEmpty
        ? '-'
        : text;
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
}