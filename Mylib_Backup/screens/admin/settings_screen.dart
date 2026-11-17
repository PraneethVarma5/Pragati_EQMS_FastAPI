import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:open_filex/open_filex.dart';
import '../../services/download_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String folder = "Not Selected";

  @override
  void initState() {
    super.initState();
    loadFolder();
  }

  Future<void> loadFolder() async {
    final path = await DownloadService.getFolder();

    setState(() {
      folder = path ?? "Not Selected";
    });
  }

  Future<void> changeFolder() async {
    final path = await DownloadService.pickFolder();

    if (path != null) {
      setState(() {
        folder = path;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Download folder updated."),
        ),
      );
    }
  }

  // Future<void> openFolder() async {
  //   if (folder == "Not Selected") return;
  //
  //   await OpenFilex.open(folder);
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text("Admin Settings"),
  //     ),
  //     body: ListView(
  //       padding: const EdgeInsets.all(16),
  //       children: [
  //
  //         Card(
  //           child: ListTile(
  //             leading: const Icon(Icons.folder),
  //             title: const Text("Download Folder"),
  //             subtitle: Text(folder),
  //           ),
  //         ),
  //
  //         const SizedBox(height: 15),
  //
  //         SizedBox(
  //           width: double.infinity,
  //           child: ElevatedButton.icon(
  //             icon: const Icon(Icons.folder_open),
  //             label: const Text("Change Folder"),
  //             onPressed: changeFolder,
  //           ),
  //         ),
  //
  //         const SizedBox(height: 10),
  //
  //         // SizedBox(
  //         //   width: double.infinity,
  //         //   child: ElevatedButton.icon(
  //         //     icon: const Icon(Icons.open_in_new),
  //         //     label: const Text("Open Folder"),
  //         //     onPressed: openFolder,
  //         //   ),
  //         // ),
  //
  //         const SizedBox(height: 25),
  //
  //         const Card(
  //           child: ListTile(
  //             leading: Icon(Icons.info),
  //             title: Text("Version"),
  //             subtitle: Text("Digital ARR v1.0"),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,

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
              "Settings",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202124),
              ),
            ),
            Text(
              "Manage application preferences",
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

          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              32,
              30,
              32,
              40,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // PAGE HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),

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
                        width: 54,
                        height: 54,

                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF0FF),
                          borderRadius:
                          BorderRadius.circular(15),
                        ),

                        child: const Icon(
                          Icons.settings_outlined,
                          color: Color(0xFF3155C6),
                          size: 28,
                        ),
                      ),

                      const SizedBox(width: 16),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [

                            Text(
                              "Application Settings",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF202124),
                              ),
                            ),

                            SizedBox(height: 5),

                            Text(
                              "Configure where Digital ARR stores generated reports and certificates.",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF747B86),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // DOWNLOAD SETTINGS
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),

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

                      Row(
                        children: [

                          Container(
                            width: 42,
                            height: 42,

                            decoration: BoxDecoration(
                              color:
                              const Color(0xFFF0F3FA),
                              borderRadius:
                              BorderRadius.circular(12),
                            ),

                            child: const Icon(
                              Icons.folder_outlined,
                              color: Color(0xFF3155C6),
                              size: 22,
                            ),
                          ),

                          const SizedBox(width: 13),

                          const Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [

                              Text(
                                "Download Location",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF202124),
                                ),
                              ),

                              SizedBox(height: 3),

                              Text(
                                "Choose where generated files are saved.",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF747B86),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(17),

                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FB),
                          borderRadius:
                          BorderRadius.circular(12),

                          border: Border.all(
                            color: const Color(0xFFE1E4E8),
                          ),
                        ),

                        child: Row(
                          children: [

                            const Icon(
                              Icons.folder_rounded,
                              color: Color(0xFF3155C6),
                              size: 25,
                            ),

                            const SizedBox(width: 13),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [

                                  const Text(
                                    "Current folder",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                      FontWeight.w600,
                                      color:
                                      Color(0xFF777D86),
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    folder,
                                    maxLines: 2,
                                    overflow:
                                    TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight:
                                      FontWeight.w500,
                                      color:
                                      Color(0xFF202124),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 48,

                        child: ElevatedButton.icon(
                          onPressed: changeFolder,

                          icon: const Icon(
                            Icons.folder_open_outlined,
                            size: 20,
                          ),

                          label: const Text(
                            "Change Download Folder",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(0xFF3155C6),

                            foregroundColor:
                            Colors.white,

                            elevation: 0,

                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(11),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // APPLICATION INFORMATION
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),

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

                  child: Row(
                    children: [

                      Container(
                        width: 42,
                        height: 42,

                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F3F5),
                          borderRadius:
                          BorderRadius.circular(12),
                        ),

                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF5F6368),
                          size: 22,
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [

                            Text(
                              "Application Information",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF202124),
                              ),
                            ),

                            SizedBox(height: 4),

                            Text(
                              "Digital ARR",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF5F6368),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 8,
                        ),

                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius:
                          BorderRadius.circular(9),
                        ),

                        child: const Text(
                          "Version 1.0",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5F6368),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Center(
                  child: Text(
                    "Digital ARR  •  Inspection Management System",
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade500,
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