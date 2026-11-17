import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/question.dart';
import '../../services/supabase_service.dart';

class PartEditorScreen extends StatefulWidget {

  final String batchId;
  final Question? part;

  const PartEditorScreen({
    super.key,
    required this.batchId,
    this.part,
  });

  @override
  State<PartEditorScreen> createState() =>
      _PartEditorScreenState();

}

class _PartEditorScreenState
    extends State<PartEditorScreen> {

  late TextEditingController partNoController;

  late TextEditingController qrController;

  int masterStatus = 1;
  int sequenceOrder = 0;

  bool isLoading = false;
  bool isSaving = false;
  final ScreenshotController screenshotController =
  ScreenshotController();
  //bool autoGenerateQR = true;

  @override
  void initState() {
    super.initState();

    partNoController = TextEditingController(
      text: widget.part?.partNo ?? "",
    );

    qrController = TextEditingController(
      text: widget.part?.barcode ?? "",
    );

    masterStatus =
        widget.part?.initialStatus ?? 1;

    sequenceOrder =
        widget.part?.sequenceOrder ?? 0;
  }

  @override
  void dispose() {
    partNoController.dispose();
    qrController.dispose();

    super.dispose();
  }

  // Future<void> _loadPartFromSupabase() async {
  //   final id = widget.partId?.trim();
  //
  //   if (id == null || id.isEmpty) {
  //     return;
  //   }
  //
  //   setState(() {
  //     isLoading = true;
  //   });
  //
  //   try {
  //     final response =
  //     await SupabaseService.getPartById(id);
  //
  //     if (response == null) {
  //       throw Exception(
  //         "Part was not found in Supabase.",
  //       );
  //     }
  //
  //     final dbBatchId =
  //         response['batch_id']?.toString() ?? '';
  //
  //     if (dbBatchId.isNotEmpty &&
  //         dbBatchId != widget.batchId) {
  //       throw Exception(
  //         "This part does not belong to the selected batch.",
  //       );
  //     }
  //
  //     if (!mounted) return;
  //
  //     setState(() {
  //       partNoController.text =
  //           response['part_number']?.toString() ?? '';
  //
  //       qrController.text =
  //           response['barcode_value']?.toString() ?? '';
  //
  //       masterStatus =
  //       response['master_status'] is int
  //           ? response['master_status'] as int
  //           : int.tryParse(
  //         response['master_status']
  //             ?.toString() ??
  //             '',
  //       ) ??
  //           1;
  //
  //       sequenceOrder =
  //       response['sequence_order'] is int
  //           ? response['sequence_order'] as int
  //           : int.tryParse(
  //         response['sequence_order']
  //             ?.toString() ??
  //             '',
  //       ) ??
  //           0;
  //
  //       isLoading = false;
  //     });
  //   } catch (e) {
  //     if (!mounted) return;
  //
  //     setState(() {
  //       isLoading = false;
  //     });
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           "Unable to load part: $e",
  //         ),
  //       ),
  //     );
  //   }
  // }
  // Future<void> _loadPartFromSupabase() async {
  //   final id = widget.partId?.trim();
  //
  //   if (id == null || id.isEmpty) {
  //     return;
  //   }
  //
  //   setState(() {
  //     isLoading = true;
  //   });
  //
  //   try {
  //     final response =
  //     await SupabaseService.getPartById(id);
  //
  //     if (response == null) {
  //       throw Exception(
  //         "Part was not found in Supabase.",
  //       );
  //     }
  //
  //     final dbBatchId =
  //         response['batch_id']?.toString() ?? '';
  //
  //     if (dbBatchId.isNotEmpty &&
  //         dbBatchId != widget.batchId) {
  //       throw Exception(
  //         "This part does not belong to the selected batch.",
  //       );
  //     }
  //
  //     if (!mounted) return;
  //
  //     setState(() {
  //       partNoController.text =
  //           response['part_number']?.toString() ?? '';
  //
  //       partNameController.text =
  //           response['part_name']?.toString() ?? '';
  //
  //       qrController.text =
  //           response['barcode_value']?.toString() ?? '';
  //
  //       masterStatus =
  //       response['master_status'] is int
  //           ? response['master_status'] as int
  //           : int.tryParse(
  //         response['master_status']
  //             ?.toString() ??
  //             '',
  //       ) ??
  //           1;
  //
  //       sequenceOrder =
  //       response['sequence_order'] is int
  //           ? response['sequence_order'] as int
  //           : int.tryParse(
  //         response['sequence_order']
  //             ?.toString() ??
  //             '',
  //       ) ??
  //           0;
  //     });
  //   } catch (e) {
  //     if (!mounted) return;
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           "Unable to get part details from database: $e",
  //         ),
  //       ),
  //     );
  //   } finally {
  //     if (!mounted) return;
  //
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }
  //auto qr generate code
  // String generateQRCode() {
  //
  //   if (!autoGenerateQR) {
  //
  //     return qrController.text.trim();
  //
  //   }
  //
  //   final part =
  //   partNoController.text.trim();
  //
  //   return "${widget.batchId}-$part";
  //
  // }

  String generateQRCode() {

    final part = partNoController.text.trim();

    return "${widget.batchId}-$part";

  }
  Future<void> saveQr() async {

    // await Permission.storage.request();

    Uint8List? image =
    await screenshotController.capture();

    if (image == null) return;

    await ImageGallerySaverPlus.saveImage(
      image,
      quality: 100,
      name:
      "QR_${DateTime.now().millisecondsSinceEpoch}",
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("QR saved successfully"),
      ),
    );
  }
  Widget _statusOption({
    required int value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final selected = masterStatus == value;

    return Material(
      color: Colors.transparent,

      child: InkWell(
        borderRadius: BorderRadius.circular(13),

        onTap: () {
          setState(() {
            masterStatus = value;
          });
        },

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),

          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.07)
                : const Color(0xFFF8F9FB),

            borderRadius: BorderRadius.circular(13),

            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.55)
                  : const Color(0xFFE1E4E8),

              width: selected ? 1.5 : 1,
            ),
          ),

          child: Row(
            children: [

              Container(
                width: 42,
                height: 42,

                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: 0.12)
                      : const Color(0xFFEFF1F4),

                  borderRadius:
                  BorderRadius.circular(11),
                ),

                child: Icon(
                  icon,
                  color: selected
                      ? color
                      : const Color(0xFF777D86),
                  size: 23,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    Text(
                      title,

                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                        FontWeight.w700,
                        color: selected
                            ? color
                            : const Color(
                          0xFF202124,
                        ),
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,

                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(
                          0xFF747B86,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              AnimatedContainer(
                duration:
                const Duration(
                  milliseconds: 160,
                ),

                width: 20,
                height: 20,

                decoration: BoxDecoration(
                  shape: BoxShape.circle,

                  border: Border.all(
                    color: selected
                        ? color
                        : const Color(
                      0xFFB9BEC5,
                    ),

                    width: 2,
                  ),
                ),

                child: selected
                    ? Center(
                  child: Container(
                    width: 10,
                    height: 10,

                    decoration:
                    BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _showQrPreview(BuildContext context) async {
    final qrData = qrController.text.trim();

    if (qrData.isEmpty) {
      return;
    }

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(
            24,
            22,
            24,
            8,
          ),

          contentPadding: const EdgeInsets.fromLTRB(
            24,
            12,
            24,
            8,
          ),

          actionsPadding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            18,
          ),

          title: const Row(
            children: [
              Icon(
                Icons.qr_code_2_rounded,
                color: Color(0xFF3155C6),
                size: 24,
              ),

              SizedBox(width: 10),

              Text(
                "QR Preview",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          content: SizedBox(
            width: 380,

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [

                Container(
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                    BorderRadius.circular(14),

                    border: Border.all(
                      color: const Color(0xFFE1E4E8),
                    ),
                  ),

                  child: Screenshot(
                    controller:
                    screenshotController,

                    child: Container(
                      color: Colors.white,

                      padding:
                      const EdgeInsets.all(14),

                      child: QrImageView(
                        data: qrData,

                        size: 240,

                        backgroundColor:
                        Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,

                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),

                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7F9),
                    borderRadius:
                    BorderRadius.circular(10),
                  ),

                  child: Row(
                    children: [

                      const Icon(
                        Icons.data_object_rounded,
                        size: 17,
                        color: Color(0xFF747B86),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          qrData,

                          overflow:
                          TextOverflow.ellipsis,

                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight:
                            FontWeight.w600,
                            color:
                            Color(0xFF555B64),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          actions: [

            TextButton.icon(
              onPressed: saveQr,

              icon: const Icon(
                Icons.download_outlined,
                size: 18,
              ),

              label: const Text(
                "Save",
              ),
            ),

            TextButton.icon(
              onPressed: () async {
                final image =
                await screenshotController
                    .capture();

                if (image == null) {
                  return;
                }

                final file =
                XFile.fromData(
                  image,

                  mimeType:
                  "image/png",

                  name: "QR.png",
                );

                await Share.shareXFiles(
                  [file],
                );
              },

              icon: const Icon(
                Icons.share_outlined,
                size: 18,
              ),

              label: const Text(
                "Share",
              ),
            ),

            const SizedBox(width: 6),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },

              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(
                  0xFF3155C6,
                ),

                foregroundColor:
                Colors.white,

                padding:
                const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),

                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(9),
                ),
              ),

              child: const Text(
                "Close",
              ),
            ),
          ],
        );
      },
    );
  }
  Future<void> _savePart(BuildContext context) async {
    if (isSaving) return;

    final partNo =
    partNoController.text.trim();

    final qrCode =
    qrController.text.trim();

    if (partNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Enter Part Number.",
          ),
        ),
      );
      return;
    }

    if (qrCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "QR Code cannot be empty.",
          ),
        ),
      );
      return;
    }

    if (masterStatus != 0 &&
        masterStatus != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Invalid master status.",
          ),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      if (widget.part == null) {
        await SupabaseService.createPart(
          batchId: widget.batchId,
          partNumber: partNo,
          masterStatus: masterStatus,
          barcode: qrCode,
          sequenceOrder: 1,
        );
      } else {
        if (widget.part!.partId.isEmpty) {
          throw Exception(
            "Part ID is missing. Cannot update this part.",
          );
        }

        await SupabaseService.updatePart(
          partId: widget.part!.partId,
          partNo: partNo,
          initialStatus: masterStatus,
          barcode: qrCode,
          sequenceOrder:
          widget.part!.sequenceOrder,
          isActive: true,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.part == null
                ? "Part created successfully."
                : "Part updated successfully.",
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Unable to save part: $e",
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });
    }
  }
  // @override
  // Widget build(BuildContext context) {
  //
  //   return Scaffold(
  //
  //     appBar: AppBar(
  //
  //       title: Text(
  //
  //         widget.part == null
  //
  //             ? "Add Part"
  //
  //             : "Edit Part",
  //
  //       ),
  //
  //     ),
  //
  //     body: SingleChildScrollView(
  //
  //       padding: const EdgeInsets.all(20),
  //
  //       child: Column(
  //
  //         children: [
  //
  //           TextField(
  //
  //             controller: partNoController,
  //
  //             decoration: const InputDecoration(
  //
  //               labelText: "Part Number",
  //
  //               border: OutlineInputBorder(),
  //
  //             ),
  //
  //           ),
  //
  //           const SizedBox(height: 20),
  //
  //           TextField(
  //
  //             controller: qrController,
  //             decoration: const InputDecoration(
  //
  //               labelText: "QR Code",
  //               hintText: "Enter text to encode in QR",
  //               border: OutlineInputBorder(),
  //
  //             ),
  //
  //           ),
  //           const SizedBox(height: 20),
  //           Card(
  //
  //             child: Column(
  //
  //               children: [
  //
  //                 RadioListTile(
  //
  //                   value: 1,
  //
  //                   groupValue: masterStatus,
  //
  //                   title: const Text("PASS"),
  //
  //                   onChanged: (value) {
  //
  //                     setState(() {
  //
  //                       masterStatus = value!;
  //
  //                     });
  //
  //                   },
  //
  //                 ),
  //
  //                 RadioListTile(
  //
  //                   value: 0,
  //
  //                   groupValue: masterStatus,
  //
  //                   title: const Text("FAIL"),
  //
  //                   onChanged: (value) {
  //
  //                     setState(() {
  //
  //                       masterStatus = value!;
  //
  //                     });
  //
  //                   },
  //
  //                 ),
  //
  //               ],
  //
  //             ),
  //
  //           ),
  //
  //           const SizedBox(height: 30),
  //
  //           SizedBox(
  //
  //             width: double.infinity,
  //
  //             child: ElevatedButton.icon(
  //
  //               icon: const Icon(Icons.qr_code),
  //
  //               label: const Text(
  //
  //                 "Generate QR",
  //
  //               ),
  //
  //               onPressed: () {
  //
  //                 if (partNoController.text.trim().isEmpty) {
  //
  //                   ScaffoldMessenger.of(context).showSnackBar(
  //                     const SnackBar(
  //                       content: Text("Enter Part Number first."),
  //                     ),
  //                   );
  //
  //                   return;
  //                 }
  //
  //                 if (qrController.text.trim().isEmpty) {
  //                   ScaffoldMessenger.of(context).showSnackBar(
  //                     const SnackBar(
  //                       content: Text("Enter QR text."),
  //                     ),
  //                   );
  //                   return;
  //                 }
  //
  //                 setState(() {});
  //
  //                 showDialog(
  //                   context: context,
  //                   builder: (_) => AlertDialog(
  //                     title: const Text("QR Preview"),
  //                     content: Screenshot(
  //                       controller: screenshotController,
  //                       child: Container(
  //                         color: Colors.white,
  //                         padding: const EdgeInsets.all(12),
  //                         child: SizedBox(
  //                           width: 220,
  //                           height: 220,
  //                           child: QrImageView(
  //                             data: qrController.text,
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //
  //                     actions: [
  //
  //                       TextButton.icon(
  //
  //                         onPressed: saveQr,
  //
  //                         icon: const Icon(Icons.download),
  //
  //                         label: const Text("Save"),
  //
  //                       ),
  //
  //                       TextButton.icon(
  //
  //                         onPressed: () async {
  //
  //                           Uint8List? image =
  //                           await screenshotController.capture();
  //
  //                           if (image == null) return;
  //
  //                           final file = XFile.fromData(
  //                             image,
  //                             mimeType: "image/png",
  //                             name: "QR.png",
  //                           );
  //
  //                           await Share.shareXFiles(
  //                             [file],
  //                           );
  //
  //                         },
  //
  //                         icon: const Icon(Icons.share),
  //
  //                         label: const Text("Share"),
  //
  //                       ),
  //
  //                       TextButton(
  //
  //                         onPressed: () {
  //
  //                           Navigator.pop(context);
  //
  //                         },
  //
  //                         child: const Text("Close"),
  //
  //                       ),
  //
  //                     ],
  //                   ),
  //                 );
  //
  //               },
  //
  //             ),
  //
  //           ),
  //
  //           const SizedBox(height: 15),
  //
  //           SizedBox(
  //
  //             width: double.infinity,
  //
  //             child: ElevatedButton.icon(
  //
  //               icon: const Icon(Icons.save),
  //
  //               label: const Text("Save"),
  //
  //               onPressed: () async {
  //
  //                 if (partNoController.text.trim().isEmpty) {
  //
  //                   ScaffoldMessenger.of(context).showSnackBar(
  //
  //                     const SnackBar(
  //
  //                       content: Text(
  //                         "Enter Part Number",
  //                       ),
  //
  //                     ),
  //
  //                   );
  //
  //                   return;
  //
  //                 }
  //
  //                 // qrController.text = generateQRCode();
  //
  //                 // showDialog(
  //                 //
  //                 //   context: context,
  //                 //
  //                 //   builder: (_) => AlertDialog(
  //                 //
  //                 //     title: const Text("Generated QR"),
  //                 //
  //                 //     content: SizedBox(
  //                 //
  //                 //       width: 220,
  //                 //
  //                 //       height: 220,
  //                 //
  //                 //       child: QrImageView(
  //                 //
  //                 //         data: qrController.text,
  //                 //
  //                 //       ),
  //                 //
  //                 //     ),
  //                 //
  //                 //     actions: [
  //                 //
  //                 //       TextButton(
  //                 //
  //                 //         onPressed: () {
  //                 //
  //                 //           Navigator.pop(context);
  //                 //
  //                 //         },
  //                 //
  //                 //         child: const Text("Close"),
  //                 //
  //                 //       ),
  //                 //
  //                 //     ],
  //                 //
  //                 //   ),
  //
  //                 // );
  //
  //                 if (qrController.text.trim().isEmpty) {
  //
  //                   ScaffoldMessenger.of(context).showSnackBar(
  //
  //                     const SnackBar(
  //
  //                       content: Text(
  //                         "QR Code cannot be empty",
  //                       ),
  //
  //                     ),
  //
  //                   );
  //
  //                   return;
  //
  //                 }
  //
  //                 final newPart = Question(
  //
  //                   partNo: partNoController.text.trim(),
  //
  //                   partName: "",
  //
  //                   initialStatus: masterStatus,
  //
  //                   barcode: qrController.text.trim(),
  //
  //                   batchId: widget.batchId,
  //
  //                 );
  //
  //                 try {
  //
  //                   if (widget.part == null) {
  //
  //                     await HiveService.addPart(newPart);
  //
  //                   } else {
  //
  //                     await HiveService.updatePart(
  //                       oldPart: widget.part!,
  //                       newPart: newPart,
  //                     );                    }
  //
  //                   if (!mounted) return;
  //
  //                   Navigator.pop(context, true);
  //
  //                 } catch (e) {
  //
  //                   if (!mounted) return;
  //
  //                   ScaffoldMessenger.of(context).showSnackBar(
  //
  //                     SnackBar(
  //
  //                       content: Text(e.toString()),
  //
  //                     ),
  //
  //                   );
  //
  //                 }
  //
  //               },
  //
  //             ),
  //
  //           ),
  //
  //         ],
  //
  //       ),
  //
  //     ),
  //
  //   );
  //
  // }
  // @override
  // Widget build(BuildContext context) {
  //   final isEditing = widget.part != null;
  //
  //   return Scaffold(
  //     backgroundColor: const Color(0xFFF7F8FA),
  //
  //     appBar: AppBar(
  //       backgroundColor: Colors.white,
  //       surfaceTintColor: Colors.transparent,
  //       elevation: 0,
  //
  //       leading: IconButton(
  //         icon: const Icon(
  //           Icons.arrow_back_rounded,
  //           color: Color(0xFF202124),
  //         ),
  //         onPressed: () => Navigator.pop(context),
  //       ),
  //
  //       title: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Text(
  //             isEditing ? "Edit Part" : "Add Part",
  //             style: const TextStyle(
  //               fontSize: 20,
  //               fontWeight: FontWeight.w700,
  //               color: Color(0xFF202124),
  //             ),
  //           ),
  //
  //           Text(
  //             isEditing
  //                 ? "Update inspection part details"
  //                 : "Create a new inspection part",
  //             style: const TextStyle(
  //               fontSize: 11,
  //               color: Color(0xFF777D86),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //       body: Center(
  //     child: ConstrainedBox(
  //         constraints: const BoxConstraints(
  //           maxWidth: 1050,
  //         ),
  //
  //         child: SingleChildScrollView(
  //           padding: const EdgeInsets.fromLTRB(
  //             28,
  //             28,
  //             28,
  //             40,
  //           ),
  //
  //           child: Column(
  //             crossAxisAlignment:
  //             CrossAxisAlignment.start,
  //
  //             children: [
  //
  //               // PAGE HEADER
  //               Container(
  //                 width: double.infinity,
  //
  //                 padding: const EdgeInsets.all(22),
  //
  //                 decoration: BoxDecoration(
  //                   color: Colors.white,
  //
  //                   borderRadius:
  //                   BorderRadius.circular(18),
  //
  //                   border: Border.all(
  //                     color: const Color(0xFFE1E4E8),
  //                   ),
  //
  //                   boxShadow: [
  //                     BoxShadow(
  //                       color: Colors.black.withValues(
  //                         alpha: 0.035,
  //                       ),
  //                       blurRadius: 18,
  //                       offset: const Offset(0, 6),
  //                     ),
  //                   ],
  //                 ),
  //
  //                 child: Row(
  //                   children: [
  //
  //                     Container(
  //                       width: 52,
  //                       height: 52,
  //
  //                       decoration: BoxDecoration(
  //                         color:
  //                         const Color(0xFFEAF0FF),
  //
  //                         borderRadius:
  //                         BorderRadius.circular(14),
  //                       ),
  //
  //                       child: const Icon(
  //                         Icons.precision_manufacturing_outlined,
  //                         color: Color(0xFF3155C6),
  //                         size: 27,
  //                       ),
  //                     ),
  //
  //                     const SizedBox(width: 16),
  //
  //                     Expanded(
  //                       child: Column(
  //                         crossAxisAlignment:
  //                         CrossAxisAlignment.start,
  //
  //                         children: [
  //
  //                           Text(
  //                             isEditing
  //                                 ? "Edit Inspection Part"
  //                                 : "New Inspection Part",
  //
  //                             style: const TextStyle(
  //                               fontSize: 21,
  //                               fontWeight:
  //                               FontWeight.w700,
  //                               color:
  //                               Color(0xFF202124),
  //                             ),
  //                           ),
  //
  //                           const SizedBox(height: 5),
  //
  //                           const Text(
  //                             "Configure the part number, QR information and master status.",
  //                             style: TextStyle(
  //                               fontSize: 13,
  //                               color: Color(0xFF747B86),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //
  //               const SizedBox(height: 20),
  //
  //               // MAIN FORM
  //               Container(
  //                 width: double.infinity,
  //
  //                 padding: const EdgeInsets.all(24),
  //
  //                 decoration: BoxDecoration(
  //                   color: Colors.white,
  //
  //                   borderRadius:
  //                   BorderRadius.circular(18),
  //
  //                   border: Border.all(
  //                     color: const Color(0xFFE1E4E8),
  //                   ),
  //
  //                   boxShadow: [
  //                     BoxShadow(
  //                       color: Colors.black.withValues(
  //                         alpha: 0.025,
  //                       ),
  //                       blurRadius: 14,
  //                       offset: const Offset(0, 4),
  //                     ),
  //                   ],
  //                 ),
  //
  //                 child: Column(
  //                   crossAxisAlignment:
  //                   CrossAxisAlignment.start,
  //
  //                   children: [
  //
  //                     const Text(
  //                       "Part Details",
  //                       style: TextStyle(
  //                         fontSize: 17,
  //                         fontWeight: FontWeight.w700,
  //                         color: Color(0xFF202124),
  //                       ),
  //                     ),
  //
  //                     const SizedBox(height: 5),
  //
  //                     const Text(
  //                       "Enter the information used during inspection.",
  //                       style: TextStyle(
  //                         fontSize: 12.5,
  //                         color: Color(0xFF747B86),
  //                       ),
  //                     ),
  //
  //                     const SizedBox(height: 20),
  //
  //                     Row(
  //                       crossAxisAlignment:
  //                       CrossAxisAlignment.start,
  //
  //                       children: [
  //
  //                         Expanded(
  //                           child: TextField(
  //                             controller:
  //                             partNoController,
  //
  //                             decoration:
  //                             InputDecoration(
  //                               labelText:
  //                               "Part Number",
  //
  //                               hintText:
  //                               "Example: P001",
  //
  //                               prefixIcon:
  //                               const Icon(
  //                                 Icons.tag_rounded,
  //                               ),
  //
  //                               filled: true,
  //
  //                               fillColor:
  //                               const Color(
  //                                 0xFFF8F9FB,
  //                               ),
  //
  //                               border:
  //                               OutlineInputBorder(
  //                                 borderRadius:
  //                                 BorderRadius
  //                                     .circular(
  //                                   11,
  //                                 ),
  //
  //                                 borderSide:
  //                                 BorderSide.none,
  //                               ),
  //
  //                               enabledBorder:
  //                               OutlineInputBorder(
  //                                 borderRadius:
  //                                 BorderRadius
  //                                     .circular(
  //                                   11,
  //                                 ),
  //
  //                                 borderSide:
  //                                 const BorderSide(
  //                                   color:
  //                                   Color(
  //                                     0xFFE1E4E8,
  //                                   ),
  //                                 ),
  //                               ),
  //
  //                               focusedBorder:
  //                               OutlineInputBorder(
  //                                 borderRadius:
  //                                 BorderRadius
  //                                     .circular(
  //                                   11,
  //                                 ),
  //
  //                                 borderSide:
  //                                 const BorderSide(
  //                                   color:
  //                                   Color(
  //                                     0xFF3155C6,
  //                                   ),
  //
  //                                   width: 1.5,
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //
  //                         const SizedBox(width: 18),
  //
  //                         Expanded(
  //                           child: TextField(
  //                             controller:
  //                             qrController,
  //
  //                             decoration:
  //                             InputDecoration(
  //                               labelText:
  //                               "QR Code",
  //
  //                               hintText:
  //                               "Enter QR text",
  //
  //                               prefixIcon:
  //                               const Icon(
  //                                 Icons.qr_code_2_rounded,
  //                               ),
  //
  //                               filled: true,
  //
  //                               fillColor:
  //                               const Color(
  //                                 0xFFF8F9FB,
  //                               ),
  //
  //                               border:
  //                               OutlineInputBorder(
  //                                 borderRadius:
  //                                 BorderRadius
  //                                     .circular(
  //                                   11,
  //                                 ),
  //
  //                                 borderSide:
  //                                 BorderSide.none,
  //                               ),
  //
  //                               enabledBorder:
  //                               OutlineInputBorder(
  //                                 borderRadius:
  //                                 BorderRadius
  //                                     .circular(
  //                                   11,
  //                                 ),
  //
  //                                 borderSide:
  //                                 const BorderSide(
  //                                   color:
  //                                   Color(
  //                                     0xFFE1E4E8,
  //                                   ),
  //                                 ),
  //                               ),
  //
  //                               focusedBorder:
  //                               OutlineInputBorder(
  //                                 borderRadius:
  //                                 BorderRadius
  //                                     .circular(
  //                                   11,
  //                                 ),
  //
  //                                 borderSide:
  //                                 const BorderSide(
  //                                   color:
  //                                   Color(
  //                                     0xFF3155C6,
  //                                   ),
  //
  //                                   width: 1.5,
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //
  //                     const SizedBox(height: 28),
  //
  //                     // MASTER STATUS
  //                     const Text(
  //                       "Master Status",
  //                       style: TextStyle(
  //                         fontSize: 15,
  //                         fontWeight: FontWeight.w700,
  //                         color: Color(0xFF202124),
  //                       ),
  //                     ),
  //
  //                     const SizedBox(height: 5),
  //
  //                     const Text(
  //                       "Select the expected inspection result for this part.",
  //                       style: TextStyle(
  //                         fontSize: 12,
  //                         color: Color(0xFF747B86),
  //                       ),
  //                     ),
  //
  //                     const SizedBox(height: 14),
  //
  //                     Row(
  //                       children: [
  //
  //                         Expanded(
  //                           child: _statusOption(
  //                             value: 1,
  //                             title: "PASS",
  //                             subtitle:
  //                             "Part meets requirements",
  //                             icon:
  //                             Icons.check_circle_outline_rounded,
  //                             color:
  //                             const Color(0xFF249653),
  //                           ),
  //                         ),
  //
  //                         const SizedBox(width: 14),
  //
  //                         Expanded(
  //                           child: _statusOption(
  //                             value: 0,
  //                             title: "FAIL",
  //                             subtitle:
  //                             "Part does not meet requirements",
  //                             icon:
  //                             Icons.cancel_outlined,
  //                             color:
  //                             const Color(0xFFD94A4A),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //
  //               const SizedBox(height: 20),
  //
  //               // ACTIONS
  //               Row(
  //                 children: [
  //
  //                   Expanded(
  //                     child: OutlinedButton.icon(
  //                       onPressed: () {
  //                         if (partNoController.text
  //                             .trim()
  //                             .isEmpty) {
  //                           ScaffoldMessenger.of(
  //                             context,
  //                           ).showSnackBar(
  //                             const SnackBar(
  //                               content: Text(
  //                                 "Enter Part Number first.",
  //                               ),
  //                             ),
  //                           );
  //                           return;
  //                         }
  //
  //                         if (qrController.text
  //                             .trim()
  //                             .isEmpty) {
  //                           ScaffoldMessenger.of(
  //                             context,
  //                           ).showSnackBar(
  //                             const SnackBar(
  //                               content: Text(
  //                                 "Enter QR text.",
  //                               ),
  //                             ),
  //                           );
  //                           return;
  //                         }
  //
  //                         setState(() {});
  //
  //                         _showQrPreview(context);
  //                       },
  //
  //                       icon: const Icon(
  //                         Icons.qr_code_2_rounded,
  //                       ),
  //
  //                       label: const Text(
  //                         "Generate QR",
  //                       ),
  //
  //                       style:
  //                       OutlinedButton.styleFrom(
  //                         foregroundColor:
  //                         const Color(
  //                           0xFF3155C6,
  //                         ),
  //
  //                         side:
  //                         const BorderSide(
  //                           color: Color(
  //                             0xFFD5DCF1,
  //                           ),
  //                         ),
  //
  //                         backgroundColor:
  //                         const Color(
  //                           0xFFF8FAFF,
  //                         ),
  //
  //                         padding:
  //                         const EdgeInsets
  //                             .symmetric(
  //                           vertical: 15,
  //                         ),
  //
  //                         shape:
  //                         RoundedRectangleBorder(
  //                           borderRadius:
  //                           BorderRadius.circular(
  //                             11,
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //
  //                   const SizedBox(width: 14),
  //
  //                   Expanded(
  //                     child: ElevatedButton.icon(
  //                       onPressed: isSaving
  //                           ? null
  //                           : () async {
  //                         await _savePart(
  //                           context,
  //                         );
  //                       },
  //
  //                       icon: const Icon(
  //                         Icons.save_outlined,
  //                       ),
  //
  //                       label: isSaving
  //                           ? const SizedBox(
  //                         width: 18,
  //                         height: 18,
  //                         child:
  //                         CircularProgressIndicator(
  //                           strokeWidth: 2,
  //                           color: Colors.white,
  //                         ),
  //                       )
  //                           : Text(
  //                         isEditing
  //                             ? "Update Part"
  //                             : "Save Part",
  //                       ),
  //
  //                       style:
  //                       ElevatedButton.styleFrom(
  //                         backgroundColor:
  //                         const Color(
  //                           0xFF3155C6,
  //                         ),
  //
  //                         foregroundColor:
  //                         Colors.white,
  //
  //                         elevation: 1,
  //
  //                         padding:
  //                         const EdgeInsets
  //                             .symmetric(
  //                           vertical: 15,
  //                         ),
  //
  //                         shape:
  //                         RoundedRectangleBorder(
  //                           borderRadius:
  //                           BorderRadius.circular(
  //                             11,
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //     ),
  //     ),
  //
  //         if (isLoading)
  //           Container(
  //             color: Colors.black.withValues(
  //               alpha: 0.12,
  //             ),
  //             child: const Center(
  //               child: Card(
  //                 child: Padding(
  //                   padding: EdgeInsets.all(22),
  //                   child: Column(
  //                     mainAxisSize:
  //                     MainAxisSize.min,
  //                     children: [
  //                       CircularProgressIndicator(),
  //                       SizedBox(height: 14),
  //                       Text(
  //                         "Loading part details...",
  //                         style: TextStyle(
  //                           fontWeight:
  //                           FontWeight.w600,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //   ),
  //   ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {

    final bool isEditing =
        widget.part != null;

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
              isEditing ? "Edit Part" : "Add Part",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202124),
              ),
            ),

            Text(
              isEditing
                  ? "Update inspection part details"
                  : "Create a new inspection part",
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF777D86),
              ),
            ),
          ],
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1050,
          ),

          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              28,
              28,
              28,
              40,
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                // PAGE HEADER
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
                          Icons
                              .precision_manufacturing_outlined,
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

                            Text(
                              isEditing
                                  ? "Edit Inspection Part"
                                  : "New Inspection Part",

                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight:
                                FontWeight.w700,
                                color:
                                Color(0xFF202124),
                              ),
                            ),

                            const SizedBox(height: 5),

                            const Text(
                              "Configure the part number, QR information and master status.",
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                Color(0xFF747B86),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // MAIN FORM
                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(24),

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
                          alpha: 0.025,
                        ),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      const Text(
                        "Part Details",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                          FontWeight.w700,
                          color:
                          Color(0xFF202124),
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        "Enter the information used during inspection.",
                        style: TextStyle(
                          fontSize: 12.5,
                          color:
                          Color(0xFF747B86),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [

                          // PART NUMBER
                          Expanded(
                            child: TextField(
                              controller:
                              partNoController,

                              decoration:
                              InputDecoration(
                                labelText:
                                "Part Number",

                                hintText:
                                "Example: P001",

                                prefixIcon:
                                const Icon(
                                  Icons.tag_rounded,
                                ),

                                filled: true,

                                fillColor:
                                const Color(
                                  0xFFF8F9FB,
                                ),

                                border:
                                OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    11,
                                  ),

                                  borderSide:
                                  BorderSide.none,
                                ),

                                enabledBorder:
                                OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    11,
                                  ),

                                  borderSide:
                                  const BorderSide(
                                    color:
                                    Color(
                                      0xFFE1E4E8,
                                    ),
                                  ),
                                ),

                                focusedBorder:
                                OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    11,
                                  ),

                                  borderSide:
                                  const BorderSide(
                                    color:
                                    Color(
                                      0xFF3155C6,
                                    ),

                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 18),

                          // QR CODE
                          Expanded(
                            child: TextField(
                              controller:
                              qrController,

                              decoration:
                              InputDecoration(
                                labelText:
                                "QR Code",

                                hintText:
                                "Enter QR text",

                                prefixIcon:
                                const Icon(
                                  Icons
                                      .qr_code_2_rounded,
                                ),

                                filled: true,

                                fillColor:
                                const Color(
                                  0xFFF8F9FB,
                                ),

                                border:
                                OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    11,
                                  ),

                                  borderSide:
                                  BorderSide.none,
                                ),

                                enabledBorder:
                                OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    11,
                                  ),

                                  borderSide:
                                  const BorderSide(
                                    color:
                                    Color(
                                      0xFFE1E4E8,
                                    ),
                                  ),
                                ),

                                focusedBorder:
                                OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    11,
                                  ),

                                  borderSide:
                                  const BorderSide(
                                    color:
                                    Color(
                                      0xFF3155C6,
                                    ),

                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // MASTER STATUS
                      const Text(
                        "Master Status",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                          FontWeight.w700,
                          color:
                          Color(0xFF202124),
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        "Select the expected inspection result for this part.",
                        style: TextStyle(
                          fontSize: 12,
                          color:
                          Color(0xFF747B86),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [

                          Expanded(
                            child: _statusOption(
                              value: 1,
                              title: "PASS",
                              subtitle:
                              "Part meets requirements",
                              icon:
                              Icons
                                  .check_circle_outline_rounded,
                              color:
                              const Color(
                                0xFF249653,
                              ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: _statusOption(
                              value: 0,
                              title: "FAIL",
                              subtitle:
                              "Part does not meet requirements",
                              icon:
                              Icons
                                  .cancel_outlined,
                              color:
                              const Color(
                                0xFFD94A4A,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ACTIONS
                Row(
                  children: [

                    // GENERATE QR
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (partNoController
                              .text
                              .trim()
                              .isEmpty) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Enter Part Number first.",
                                ),
                              ),
                            );
                            return;
                          }

                          if (qrController
                              .text
                              .trim()
                              .isEmpty) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Enter QR text.",
                                ),
                              ),
                            );
                            return;
                          }

                          _showQrPreview(context);
                        },

                        icon: const Icon(
                          Icons.qr_code_2_rounded,
                        ),

                        label: const Text(
                          "Generate QR",
                        ),

                        style:
                        OutlinedButton.styleFrom(
                          foregroundColor:
                          const Color(
                            0xFF3155C6,
                          ),

                          side:
                          const BorderSide(
                            color: Color(
                              0xFFD5DCF1,
                            ),
                          ),

                          backgroundColor:
                          const Color(
                            0xFFF8FAFF,
                          ),

                          padding:
                          const EdgeInsets
                              .symmetric(
                            vertical: 15,
                          ),

                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              11,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // SAVE / UPDATE
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () async {
                          await _savePart(
                            context,
                          );
                        },

                        icon: const Icon(
                          Icons.save_outlined,
                        ),

                        label: isSaving
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                            Colors.white,
                          ),
                        )
                            : Text(
                          isEditing
                              ? "Update Part"
                              : "Save Part",
                        ),

                        style:
                        ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(
                            0xFF3155C6,
                          ),

                          foregroundColor:
                          Colors.white,

                          elevation: 1,

                          padding:
                          const EdgeInsets
                              .symmetric(
                            vertical: 15,
                          ),

                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              11,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}