import 'package:flutter/material.dart';

import '../../models/batch.dart';
import '../../models/question.dart';
import '../../services/excel_import_service.dart';
import '../../services/supabase_service.dart';

import 'part_editor_screen.dart';

class PartManagementScreen extends StatefulWidget {
  const PartManagementScreen({super.key});

  @override
  State<PartManagementScreen> createState() =>
      _PartManagementScreenState();
}

class _PartManagementScreenState
    extends State<PartManagementScreen> {

  late Batch batch;

  List<Question> parts = [];
  final TextEditingController searchController =
  TextEditingController();

  List<Question> filteredParts = [];

  bool isLoading = true;
  bool isProcessing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)
            ?.settings
            .arguments;

    if (args is! Batch) {

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text(
            "No batch selected.",
          ),

        ),

      );

      return;

    }

    batch = args;

    load();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final response =
      await SupabaseService.getActiveParts(
        batch.id,
      );

      final loadedParts = response.map((data) {
        return Question(
          partId:
          data['part_id']?.toString() ?? '',

          partNo:
          data['part_number']?.toString() ?? '',

          partName:
          data['part_name']?.toString() ?? '',

          initialStatus:
          data['master_status'] is int
              ? data['master_status'] as int
              : int.tryParse(
            data['master_status']?.toString() ?? '',
          ) ?? 1,

          barcode:
          data['barcode_value']?.toString() ?? '',

          batchId:
          data['batch_id']?.toString() ?? batch.id,

          sequenceOrder:
          data['sequence_order'] is int
              ? data['sequence_order'] as int
              : int.tryParse(
            data['sequence_order']?.toString() ?? '',
          ) ?? 0,
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        parts = loadedParts;
        filteredParts =
        List<Question>.from(loadedParts);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Unable to load parts: $e",
          ),
        ),
      );
    }
  }
  // void search(String value) {
  //
  //   filteredParts = parts.where((part) {
  //
  //     final query = value.toLowerCase();
  //
  //     return part.partNo
  //         .toLowerCase()
  //         .contains(query);
  //
  //   }).toList();
  //
  //   setState(() {});
  //
  // }
  void search(String value) {
    final query = value.trim().toLowerCase();

    setState(() {
      filteredParts = parts.where((part) {
        final partNo =
        part.partNo.toLowerCase();

        final partName =
        part.partName.toLowerCase();

        final barcode =
        part.barcode.toLowerCase();

        return partNo.contains(query) ||
            partName.contains(query) ||
            barcode.contains(query);
      }).toList();
    });
  }
  Widget _summaryCard(
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      width: 125,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE4E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 19,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF747B86),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _partCard(
      BuildContext context,
      Question part,
      int index,
      ) {
    final isPass = part.initialStatus == 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE1E4E8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.025,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 15,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: Text(
                "${index + 1}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3155C6),
                ),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          part.partNo,
                          overflow:
                          TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight:
                            FontWeight.w700,
                            color:
                            Color(0xFF202124),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isPass
                              ? const Color(
                            0xFFE8F5EC,
                          )
                              : const Color(
                            0xFFFDECEC,
                          ),
                          borderRadius:
                          BorderRadius.circular(7),
                        ),
                        child: Text(
                          isPass ? "PASS" : "FAIL",
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight:
                            FontWeight.w700,
                            color: isPass
                                ? const Color(
                              0xFF1D7A43,
                            )
                                : const Color(
                              0xFFC43D3D,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  if (part.partName.isNotEmpty)
                    Padding(
                      padding:
                      const EdgeInsets.only(
                        bottom: 5,
                      ),
                      child: Text(
                        part.partName,
                        overflow:
                        TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color:
                          Color(0xFF555B64),
                        ),
                      ),
                    ),

                  Row(
                    children: [
                      const Icon(
                        Icons.qr_code_2_rounded,
                        size: 16,
                        color: Color(0xFF7A8088),
                      ),

                      const SizedBox(width: 7),

                      Flexible(
                        child: Text(
                          part.barcode.isEmpty
                              ? "No QR / barcode assigned"
                              : part.barcode,
                          overflow:
                          TextOverflow.ellipsis,
                          style:
                          const TextStyle(
                            fontSize: 12,
                            color:
                            Color(0xFF747B86),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            PopupMenuButton<int>(
              tooltip: "Part options",

              icon: const Icon(
                Icons.more_vert_rounded,
                color: Color(0xFF6F7680),
              ),

              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(12),
              ),

              itemBuilder: (_) => [
                const PopupMenuItem<int>(
                  value: 1,
                  child: ListTile(
                    contentPadding:
                    EdgeInsets.zero,
                    leading: Icon(
                      Icons.edit_outlined,
                      size: 20,
                    ),
                    title: Text("Edit"),
                  ),
                ),

                const PopupMenuItem<int>(
                  value: 2,
                  child: ListTile(
                    contentPadding:
                    EdgeInsets.zero,
                    leading: Icon(
                      Icons.qr_code_2_rounded,
                      size: 20,
                    ),
                    title: Text("View QR"),
                  ),
                ),

                const PopupMenuItem<int>(
                  value: 3,
                  child: ListTile(
                    contentPadding:
                    EdgeInsets.zero,
                    leading: Icon(
                      Icons.archive_outlined,
                      size: 20,
                    ),
                    title: Text("Archive"),
                  ),
                ),

                const PopupMenuDivider(),

                const PopupMenuItem<int>(
                  value: 4,
                  child: ListTile(
                    contentPadding:
                    EdgeInsets.zero,
                    leading: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red,
                    ),
                    title: Text(
                      "Delete",
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],

              onSelected: (value) async {
                switch (value) {
                  case 1:
                    final result =
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PartEditorScreen(
                              batchId: batch.id,
                              part: part,
                            ),
                      ),
                    );

                    if (result == true) {
                      await load();
                    }

                    break;

                  case 2:
                    if (part.barcode.isEmpty) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "No QR / barcode is assigned to this part.",
                          ),
                        ),
                      );

                      return;
                    }

                    await showDialog(
                      context: context,
                      builder: (_) {
                        return AlertDialog(
                          title: const Text(
                            "Part QR Code",
                          ),
                          content: SelectableText(
                            part.barcode,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(
                                  context,
                                );
                              },
                              child: const Text(
                                "Close",
                              ),
                            ),
                          ],
                        );
                      },
                    );

                    break;

                  case 3:
                    try {
                      if (mounted) {
                        setState(() {
                          isProcessing = true;
                        });
                      }

                      await SupabaseService
                          .updatePartStatus(
                        partId: part.partId,
                        isActive: false,
                      );

                      await load();

                      if (mounted) {
                        setState(() {
                          isProcessing = false;
                        });
                      }

                      if (!mounted) return;

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Part archived successfully.",
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      setState(() {
                        isProcessing = false;
                      });
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Unable to archive part: $e",
                          ),
                        ),
                      );
                    }

                    break;

                  case 4:
                    final confirmed =
                    await showDialog<bool>(
                      context: context,
                      builder: (_) =>
                          AlertDialog(
                            title: const Text(
                              "Delete Part?",
                            ),
                            content: Text(
                              "Delete ${part.partNo} from this batch?\n\nThis permanently removes the part from Supabase.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                    false,
                                  );
                                },
                                child:
                                const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                    true,
                                  );
                                },
                                style:
                                ElevatedButton.styleFrom(
                                  backgroundColor:
                                  Colors.red,
                                  foregroundColor:
                                  Colors.white,
                                ),
                                child:
                                const Text("Delete"),
                              ),
                            ],
                          ),
                    );

                    if (confirmed != true) {
                      return;
                    }

                    try {
                      if (part.partId.isEmpty) {
                        throw Exception(
                          "Part ID is missing.",
                        );
                      }

                      if (mounted) {
                        setState(() {
                          isProcessing = true;
                        });
                      }

                      await SupabaseService
                          .deletePart(
                        part.partId,
                      );

                      await load();

                      if (mounted) {
                        setState(() {
                          isProcessing = false;
                        });
                      }

                      if (!mounted) return;

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Part deleted successfully.",
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      setState(() {
                        isProcessing = false;
                      });
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Unable to delete part: $e",
                          ),
                        ),
                      );
                    }

                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  Widget _emptyPartsState() {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: const Color(0xFFE1E4E8),
        ),
      ),

      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [

            Container(
              width: 68,
              height: 68,

              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(18),
              ),

              child: const Icon(
                Icons.inventory_2_outlined,
                size: 32,
                color: Color(0xFF7A8088),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              parts.isEmpty
                  ? "No parts added"
                  : "No matching parts",
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202124),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              parts.isEmpty
                  ? "Add a part or import your master data from Excel."
                  : "Try a different part number.",
              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF747B86),
              ),
            ),

            if (parts.isEmpty) ...[
              const SizedBox(height: 18),

              OutlinedButton.icon(
                onPressed: () async {
                  final result =
                  await Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (_) =>
                          PartEditorScreen(
                            batchId: batch.id,
                          ),
                    ),
                  );

                  if (result == true) {
                    load();
                  }
                },

                icon: const Icon(
                  Icons.add_rounded,
                  size: 18,
                ),

                label: const Text(
                  "Add Part",
                ),

                style: OutlinedButton.styleFrom(
                  foregroundColor:
                  const Color(0xFF3155C6),

                  side: const BorderSide(
                    color: Color(0xFF3155C6),
                  ),

                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  // @override
  // Widget build(BuildContext context) {
  //
  //   return Scaffold(
  //
  //     appBar: AppBar(
  //
  //       title: Text(batch.name),
  //
  //       actions: [
  //
  //         Padding(
  //           padding: const EdgeInsets.only(right: 8),
  //           child: TextButton.icon(
  //
  //             icon: const Icon(
  //               Icons.upload_file,
  //               size: 20,
  //             ),
  //
  //             label: const Text(
  //               "Import Parts from Excel",
  //               textAlign: TextAlign.center,
  //               style: TextStyle(
  //                 fontSize: 11,
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //
  //             onPressed: () async {
  //
  //               final result =
  //               await ExcelImportService.importBatch(
  //
  //                 batchId: batch.id,
  //
  //               );
  //
  //               if (!mounted) return;
  //
  //               showDialog(
  //                 context: context,
  //                 builder: (_) => AlertDialog(
  //                   title: Text(
  //                     result.success
  //                         ? "Import Successful"
  //                         : "Import Failed",
  //                   ),
  //                   content: SingleChildScrollView(
  //                     child: Text(result.message),
  //                   ),
  //                   actions: [
  //                     TextButton(
  //                       onPressed: () {
  //                         Navigator.pop(context);
  //                       },
  //                       child: const Text("OK"),
  //                     ),
  //                   ],
  //                 ),
  //               );
  //
  //               if (result.success) {
  //                 load();
  //               }
  //
  //             },
  //
  //           ),
  //         ),
  //
  //       ],
  //     ),
  //     floatingActionButton:
  //     FloatingActionButton.extended(
  //
  //       icon: const Icon(Icons.add),
  //
  //       label: const Text("Add Part"),
  //
  //       onPressed: () async {
  //
  //         final result = await Navigator.push(
  //
  //           context,
  //
  //           MaterialPageRoute(
  //
  //             builder: (_) => PartEditorScreen(
  //
  //               batchId: batch.id,
  //
  //             ),
  //
  //           ),
  //
  //         );
  //
  //         if (result == true) {
  //
  //           load();
  //
  //         }
  //
  //       },
  //
  //     ),
  //
  //     body: Column(
  //
  //       children: [
  //
  //         Padding(
  //
  //           padding: const EdgeInsets.all(12),
  //
  //           child: TextField(
  //
  //             controller: searchController,
  //
  //             onChanged: search,
  //
  //             decoration: const InputDecoration(
  //
  //               prefixIcon: Icon(Icons.search),
  //
  //               hintText: "Search Part Number",
  //
  //               border: OutlineInputBorder(),
  //
  //             ),
  //
  //           ),
  //
  //         ),
  //
  //         Expanded(
  //
  //           child: ListView.builder(
  //
  //             itemCount: filteredParts.length,
  //
  //             itemBuilder: (_, index) {
  //
  //               final part = filteredParts[index];
  //
  //               return Card(
  //
  //                 margin: const EdgeInsets.all(8),
  //
  //                 child: ListTile(
  //
  //                   leading: CircleAvatar(
  //
  //                     child: Text(
  //                       "${index + 1}",
  //                     ),
  //
  //                   ),
  //
  //                   title: Text(
  //                     part.partNo,
  //                   ),
  //
  //                   subtitle: Text(
  //                     part.barcode,
  //                   ),
  //
  //                   trailing: PopupMenuButton(
  //
  //                     itemBuilder: (_) => [
  //
  //                       const PopupMenuItem(
  //                         value: 1,
  //                         child: Text("Edit"),
  //                       ),
  //
  //                       const PopupMenuItem(
  //                         value: 2,
  //                         child: Text("Generate QR"),
  //                       ),
  //
  //                       const PopupMenuItem(
  //                         value: 3,
  //                         child: Text("Delete"),
  //                       ),
  //
  //                     ],
  //
  //                     onSelected: (value) async {
  //
  //                       switch (value) {
  //
  //                         case 1:
  //
  //                           final result = await Navigator.push(
  //
  //                             context,
  //
  //                             MaterialPageRoute(
  //
  //                               builder: (_) => PartEditorScreen(
  //
  //                                 batchId: batch.id,
  //
  //                                 part: part,
  //
  //                               ),
  //
  //                             ),
  //
  //                           );
  //
  //                           if (result == true) {
  //
  //                             load();
  //
  //                           }
  //
  //                           break;
  //
  //                         case 2:
  //
  //                           ScaffoldMessenger.of(context).showSnackBar(
  //
  //                             SnackBar(
  //
  //                               content: Text(
  //
  //                                 "QR : ${part.barcode}",
  //
  //                               ),
  //
  //                             ),
  //
  //                           );
  //
  //                           break;
  //
  //                         case 3:
  //
  //                           await HiveService.deletePart(part);
  //
  //                           load();
  //
  //                           break;
  //
  //                       }
  //
  //                     },
  //
  //                   ),
  //                 ),
  //
  //               );
  //
  //             },
  //
  //           ),
  //
  //         ),
  //
  //       ],
  //
  //     ),
  //   );
  //
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF202124),
          ),
          onPressed: () => Navigator.pop(context),
        ),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              batch.name,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202124),
              ),
            ),

            const Text(
              "Part Management",
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF777D86),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: OutlinedButton.icon(
              onPressed: () async {
                final result =
                await ExcelImportService.importBatch(
                  batchId: batch.id,
                );

                if (!mounted) return;

                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(
                      result.success
                          ? "Import Successful"
                          : "Import Failed",
                    ),

                    content: SingleChildScrollView(
                      child: Text(result.message),
                    ),

                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );

                if (result.success) {
                  load();
                }
              },

              icon: const Icon(
                Icons.upload_file_rounded,
                size: 18,
              ),

              label: const Text(
                "Import from Excel",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),

              style: OutlinedButton.styleFrom(
                foregroundColor:
                const Color(0xFF3155C6),

                side: const BorderSide(
                  color: Color(0xFFD5DCF1),
                ),

                backgroundColor:
                const Color(0xFFF8FAFF),

                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton:
      FloatingActionButton.extended(
        backgroundColor:
        const Color(0xFF3155C6),

        foregroundColor: Colors.white,

        elevation: 3,

        icon: const Icon(
          Icons.add_rounded,
        ),

        label: const Text(
          "Add Part",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PartEditorScreen(
                batchId: batch.id,
              ),
            ),
          );

          if (result == true) {
            load();
          }
        },
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1250,
          ),

          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              28,
              24,
              28,
              90,
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                // --------------------------------------------------
                // HEADER CARD
                // --------------------------------------------------

                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(22),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                    BorderRadius.circular(18),

                    border: Border.all(
                      color: const Color(0xFFE1E4E8),
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.035,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [

                      Container(
                        width: 52,
                        height: 52,

                        decoration: BoxDecoration(
                          color:
                          const Color(0xFFEAF0FF),

                          borderRadius:
                          BorderRadius.circular(14),
                        ),

                        child: const Icon(
                          Icons.precision_manufacturing_outlined,
                          color: Color(0xFF3155C6),
                          size: 27,
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [

                            const Text(
                              "Inspection Parts",
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight:
                                FontWeight.w700,
                                color:
                                Color(0xFF202124),
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              "Manage parts and master inspection data for this batch.",
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 20),

                      _summaryCard(
                        "Total Parts",
                        parts.length.toString(),
                        Icons.inventory_2_outlined,
                        const Color(0xFF3155C6),
                      ),

                      const SizedBox(width: 12),

                      _summaryCard(
                        "PASS Master",
                        parts
                            .where(
                              (part) =>
                          part.initialStatus == 1,
                        )
                            .length
                            .toString(),
                        Icons.check_circle_outline_rounded,
                        const Color(0xFF249653),
                      ),

                      const SizedBox(width: 12),

                      _summaryCard(
                        "FAIL Master",
                        parts
                            .where(
                              (part) =>
                          part.initialStatus == 0,
                        )
                            .length
                            .toString(),
                        Icons.cancel_outlined,
                        const Color(0xFFD94A4A),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --------------------------------------------------
                // SEARCH
                // --------------------------------------------------

                Container(
                  padding: const EdgeInsets.all(6),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                    BorderRadius.circular(14),

                    border: Border.all(
                      color: const Color(0xFFE1E4E8),
                    ),
                  ),

                  child: TextField(
                    controller: searchController,

                    onChanged: search,

                    decoration:
                    InputDecoration(
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color:
                        Color(0xFF6F7680),
                      ),

                      hintText:
                      "Search by part number",

                      hintStyle:
                      const TextStyle(
                        fontSize: 13,
                        color:
                        Color(0xFF8A9098),
                      ),

                      suffixIcon:
                      searchController
                          .text
                          .isNotEmpty
                          ? IconButton(
                        icon:
                        const Icon(
                          Icons
                              .clear_rounded,
                        ),

                        onPressed: () {
                          searchController
                              .clear();

                          search("");
                        },
                      )
                          : null,

                      filled: true,

                      fillColor:
                      const Color(0xFFF8F9FB),

                      border:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(
                          10,
                        ),
                        borderSide:
                        BorderSide.none,
                      ),

                      contentPadding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // --------------------------------------------------
                // SECTION TITLE
                // --------------------------------------------------

                Row(
                  children: [

                    const Text(
                      "Parts",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.w700,
                        color:
                        Color(0xFF202124),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Container(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),

                      decoration:
                      BoxDecoration(
                        color:
                        const Color(0xFFEFF1F5),
                        borderRadius:
                        BorderRadius.circular(
                          20,
                        ),
                      ),

                      child: Text(
                        "${filteredParts.length}",
                        style:
                        const TextStyle(
                          fontSize: 12,
                          fontWeight:
                          FontWeight.w700,
                          color:
                          Color(0xFF5F6368),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // --------------------------------------------------
                // PART LIST
                // --------------------------------------------------

                Expanded(
                  child: filteredParts.isEmpty
                      ? _emptyPartsState()
                      : ListView.separated(
                    itemCount:
                    filteredParts.length,

                    separatorBuilder:
                        (_, __) =>
                    const SizedBox(
                      height: 10,
                    ),

                    itemBuilder:
                        (_, index) {
                      final part =
                      filteredParts[
                      index];

                      return _partCard(
                        context,
                        part,
                        index,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}