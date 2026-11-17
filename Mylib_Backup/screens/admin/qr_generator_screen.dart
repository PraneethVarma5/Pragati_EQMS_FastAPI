import'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() =>
      _QrGeneratorScreenState();
}

class _QrGeneratorScreenState
    extends State<QrGeneratorScreen> {

  final controller = TextEditingController();

  final ScreenshotController screenshotController =
  ScreenshotController();

  String qrData = "";

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

        content: Text(
          "QR saved successfully",
        ),

      ),

    );

  }

  @override
  Widget build(BuildContext context) {
    final hasQr = qrData.isNotEmpty;

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

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "QR Generator",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202124),
              ),
            ),

            Text(
              "Create and export QR codes",
              style: TextStyle(
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
            maxWidth: 1100,
          ),

          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              28,
              28,
              28,
              40,
            ),

            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                // --------------------------------------------------
                // LEFT: QR INPUT
                // --------------------------------------------------

                Expanded(
                  flex: 5,

                  child: Container(
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
                            alpha: 0.035,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        Row(
                          children: [

                            Container(
                              width: 50,
                              height: 50,

                              decoration: BoxDecoration(
                                color:
                                const Color(
                                  0xFFEAF0FF,
                                ),

                                borderRadius:
                                BorderRadius.circular(
                                  14,
                                ),
                              ),

                              child: const Icon(
                                Icons.qr_code_2_rounded,
                                color:
                                Color(0xFF3155C6),
                                size: 27,
                              ),
                            ),

                            const SizedBox(width: 15),

                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    "QR Code Data",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                      FontWeight.w700,
                                      color:
                                      Color(0xFF202124),
                                    ),
                                  ),

                                  SizedBox(height: 4),

                                  Text(
                                    "Enter the value you want to encode.",
                                    style: TextStyle(
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

                        const SizedBox(height: 28),

                        TextField(
                          controller: controller,

                          minLines: 2,
                          maxLines: 4,

                          decoration: InputDecoration(
                            labelText: "QR Text",
                            hintText:
                            "Example: BATCH01-P001",

                            prefixIcon: const Padding(
                              padding:
                              EdgeInsets.only(
                                bottom: 28,
                              ),
                              child: Icon(
                                Icons.data_object_rounded,
                              ),
                            ),

                            filled: true,

                            fillColor:
                            const Color(0xFFF8F9FB),

                            border:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                11,
                              ),
                              borderSide:
                              BorderSide.none,
                            ),

                            enabledBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                11,
                              ),
                              borderSide:
                              const BorderSide(
                                color:
                                Color(0xFFE1E4E8),
                              ),
                            ),

                            focusedBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                11,
                              ),
                              borderSide:
                              const BorderSide(
                                color:
                                Color(0xFF3155C6),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,

                          child: ElevatedButton.icon(
                            onPressed: () {
                              final value =
                              controller.text.trim();

                              if (value.isEmpty) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Enter QR text first.",
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                qrData = value;
                              });
                            },

                            icon: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 18,
                            ),

                            label: const Text(
                              "Generate QR Code",
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
                  ),
                ),

                const SizedBox(width: 20),

                // --------------------------------------------------
                // RIGHT: QR PREVIEW
                // --------------------------------------------------

                Expanded(
                  flex: 5,

                  child: Container(
                    constraints:
                    const BoxConstraints(
                      minHeight: 390,
                    ),

                    padding:
                    const EdgeInsets.all(24),

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
                      children: [

                        const Align(
                          alignment:
                          Alignment.centerLeft,

                          child: Text(
                            "Preview",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                              FontWeight.w700,
                              color:
                              Color(0xFF202124),
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        Align(
                          alignment:
                          Alignment.centerLeft,

                          child: Text(
                            hasQr
                                ? "Your generated QR code"
                                : "Generate a QR code to preview it here.",
                            style: const TextStyle(
                              fontSize: 12.5,
                              color:
                              Color(0xFF747B86),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Expanded(
                          child: Center(
                            child: hasQr
                                ? Screenshot(
                              controller:
                              screenshotController,

                              child: Container(
                                padding:
                                const EdgeInsets.all(
                                  20,
                                ),

                                decoration:
                                BoxDecoration(
                                  color:
                                  Colors.white,

                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    14,
                                  ),

                                  border:
                                  Border.all(
                                    color:
                                    const Color(
                                      0xFFE1E4E8,
                                    ),
                                  ),
                                ),

                                child:
                                QrImageView(
                                  data: qrData,
                                  size: 230,
                                  backgroundColor:
                                  Colors.white,
                                ),
                              ),
                            )
                                : Container(
                              width: 230,
                              height: 230,

                              decoration:
                              BoxDecoration(
                                color:
                                const Color(
                                  0xFFF5F6F8,
                                ),

                                borderRadius:
                                BorderRadius
                                    .circular(
                                  14,
                                ),
                              ),

                              child: const Column(
                                mainAxisAlignment:
                                MainAxisAlignment
                                    .center,

                                children: [

                                  Icon(
                                    Icons
                                        .qr_code_2_rounded,
                                    size: 65,
                                    color:
                                    Color(
                                      0xFFB0B5BC,
                                    ),
                                  ),

                                  SizedBox(
                                    height: 12,
                                  ),

                                  Text(
                                    "No QR generated",
                                    style:
                                    TextStyle(
                                      fontSize: 13,
                                      fontWeight:
                                      FontWeight
                                          .w600,
                                      color:
                                      Color(
                                        0xFF7A8088,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        if (hasQr) ...[
                          const SizedBox(height: 18),

                          Row(
                            children: [

                              Expanded(
                                child:
                                OutlinedButton.icon(
                                  onPressed: saveQr,

                                  icon: const Icon(
                                    Icons
                                        .download_outlined,
                                    size: 18,
                                  ),

                                  label: const Text(
                                    "Save",
                                  ),

                                  style:
                                  OutlinedButton
                                      .styleFrom(
                                    foregroundColor:
                                    const Color(
                                      0xFF3155C6,
                                    ),

                                    side:
                                    const BorderSide(
                                      color:
                                      Color(
                                        0xFFD5DCF1,
                                      ),
                                    ),

                                    padding:
                                    const EdgeInsets
                                        .symmetric(
                                      vertical: 13,
                                    ),

                                    shape:
                                    RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                        10,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child:
                                ElevatedButton.icon(
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

                                    await Share
                                        .shareXFiles(
                                      [file],
                                    );
                                  },

                                  icon: const Icon(
                                    Icons
                                        .share_outlined,
                                    size: 18,
                                  ),

                                  label: const Text(
                                    "Share",
                                  ),

                                  style:
                                  ElevatedButton
                                      .styleFrom(
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
                                      vertical: 13,
                                    ),

                                    shape:
                                    RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                        10,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
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