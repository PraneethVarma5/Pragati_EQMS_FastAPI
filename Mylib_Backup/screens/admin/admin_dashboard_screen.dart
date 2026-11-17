import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text(
  //         "Administration",
  //       ),
  //       centerTitle: true,
  //     ),
  //
  //     body: GridView.count(
  //       padding: const EdgeInsets.all(16),
  //       crossAxisCount: 2,
  //       mainAxisSpacing: 15,
  //       crossAxisSpacing: 15,
  //       childAspectRatio: 1.15,
  //
  //       children: [
  //
  //         _card(
  //           context,
  //           Icons.inventory,
  //           "Batch Management",
  //           "/batchManagement",
  //         ),
  //
  //
  //
  //         _card(
  //           context,
  //           Icons.qr_code_scanner,
  //           "Scan Part QR",
  //           "/scanPart",
  //         ),
  //
  //         _card(
  //           context,
  //           Icons.qr_code_2,
  //           "QR Generator",
  //           "/qrGenerator",
  //
  //         ),
  //         _card(
  //           context,
  //           Icons.settings,
  //           "Settings",
  //           "/settings",
  //         ),
  //
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
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF202124),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          "Administration",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF202124),
          ),
        ),

        centerTitle: false,
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1250,
          ),

          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              32,
              28,
              32,
              40,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                // Page Header
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
                        width: 52,
                        height: 52,

                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF0FF),
                          borderRadius: BorderRadius.circular(14),
                        ),

                        child: const Icon(
                          Icons.admin_panel_settings_outlined,
                          color: Color(0xFF3155C6),
                          size: 28,
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [

                            const Text(
                              "Admin Dashboard",
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF202124),
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              "Manage batches, QR operations and application settings.",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 8,
                        ),

                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8F3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFB9DFC5),
                          ),
                        ),

                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            Icon(
                              Icons.circle,
                              size: 8,
                              color: Color(0xFF24934A),
                            ),

                            SizedBox(width: 7),

                            Text(
                              "Admin Mode",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF237B40),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  "Administration Tools",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202124),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  "Access and manage core Digital ARR functions.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,

                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,

                  childAspectRatio: 3.2,

                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),

                  children: [

                    _card(
                      context,
                      Icons.inventory_2_outlined,
                      "Batch Management",
                      "/ARR/admin/batchManagement",
                    ),

                    _card(
                      context,
                      Icons.qr_code_scanner_rounded,
                      "Scan Part QR",
                      "/ARR/admin/scanPart",
                    ),

                    _card(
                      context,
                      Icons.qr_code_2_rounded,
                      "QR Generator",
                      "/ARR/admin/qrGenerator",
                    ),

                    _card(
                      context,
                      Icons.settings_outlined,
                      "Settings",
                      "/ARR/admin/settings",
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

  // Widget _card(
  //     BuildContext context,
  //     IconData icon,
  //     String title,
  //     String route,
  //     ) {
  //   return InkWell(
  //     onTap: () {
  //
  //       Navigator.pushNamed(
  //         context,
  //         route,
  //       );
  //
  //     },
  //
  //     borderRadius: BorderRadius.circular(15),
  //
  //     child: Card(
  //       elevation: 5,
  //
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(15),
  //       ),
  //
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //
  //         children: [
  //
  //           Icon(
  //             icon,
  //             size: 48,
  //           ),
  //
  //           const SizedBox(height: 10),
  //
  //           Text(
  //             title,
  //             textAlign: TextAlign.center,
  //             style: const TextStyle(
  //               fontSize: 15,
  //               fontWeight: FontWeight.w600,
  //             ),
  //           ),
  //
  //         ],
  //       ),
  //     ),
  //   );
  // }
  Widget _card(
      BuildContext context,
      IconData icon,
      String title,
      String route,
      ) {
    return Material(
      color: Colors.white,

      borderRadius: BorderRadius.circular(16),

      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            route,
          );
        },

        borderRadius: BorderRadius.circular(16),

        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 18,
          ),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),

            border: Border.all(
              color: const Color(0xFFE1E4E8),
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.035,
                ),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),

          child: Row(
            children: [

              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(13),
                ),

                child: Icon(
                  icon,
                  color: const Color(0xFF3155C6),
                  size: 25,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,

                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF202124),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _description(title),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Container(
                width: 32,
                height: 32,

                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(9),
                ),

                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF777C84),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  String _description(String title) {
    switch (title) {
      case "Batch Management":
        return "Create and manage inspection batches";

      case "Scan Part QR":
        return "Scan and identify inspection parts";

      case "QR Generator":
        return "Generate QR codes for parts";

      case "Settings":
        return "Configure application preferences";

      default:
        return "Manage Digital ARR";
    }
  }
}