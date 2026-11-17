// import 'package:flutter/material.dart';
// import '../models/batch.dart';
// import '../services/app_data.dart';
// import '../services/batch_service.dart';
//
// class BatchSelectionScreen extends StatefulWidget {
//   const BatchSelectionScreen({super.key});
//
//   @override
//   State<BatchSelectionScreen> createState() =>
//       _BatchSelectionScreenState();
// }
//
// class _BatchSelectionScreenState
//     extends State<BatchSelectionScreen> {
//
//   List<Batch> batches = [];
//
//   @override
//   void initState() {
//     super.initState();
//
//     batches = BatchService.loadBatches()
//         .where((e) => e.active)
//         .toList();
//
//     if (batches.isEmpty) {
//
//       batches.add(
//
//         Batch(
//
//           id: "BATCH001",
//
//           name: "Default Batch",
//
//           description:
//           "Factory Master Batch",
//
//           createdOn: DateTime.now(),
//
//         ),
//
//       );
//
//       BatchService.saveBatches(
//         batches,
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF6F8FB),
//
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         surfaceTintColor: Colors.transparent,
//         toolbarHeight: 72,
//
//         leading: IconButton(
//           icon: const Icon(
//             Icons.arrow_back_rounded,
//             color: Color(0xFF202124),
//           ),
//           onPressed: () => Navigator.pop(context),
//         ),
//
//         title: Row(
//           children: [
//             Container(
//               width: 42,
//               height: 42,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFEAF0FF),
//                 borderRadius: BorderRadius.circular(11),
//               ),
//               child: const Icon(
//                 Icons.inventory_2_outlined,
//                 color: Color(0xFF3155C6),
//                 size: 22,
//               ),
//             ),
//
//             const SizedBox(width: 14),
//
//             const Column(
//               crossAxisAlignment:
//               CrossAxisAlignment.start,
//               mainAxisAlignment:
//               MainAxisAlignment.center,
//               children: [
//                 Text(
//                   "Select Batch",
//                   style: TextStyle(
//                     fontSize: 19,
//                     fontWeight: FontWeight.w700,
//                     color: Color(0xFF202124),
//                     height: 1.1,
//                   ),
//                 ),
//
//                 SizedBox(height: 4),
//
//                 Text(
//                   "Choose the inspection batch to continue",
//                   style: TextStyle(
//                     fontSize: 11.5,
//                     color: Color(0xFF7A8494),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//
//       body: Center(
//         child: ConstrainedBox(
//           constraints: const BoxConstraints(
//             maxWidth: 1120,
//           ),
//
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.fromLTRB(
//               28,
//               28,
//               28,
//               40,
//             ),
//
//             child: Column(
//               crossAxisAlignment:
//               CrossAxisAlignment.start,
//               children: [
//
//                 // PAGE HEADER
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(24),
//
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius:
//                     BorderRadius.circular(16),
//                     border: Border.all(
//                       color: const Color(0xFFE1E5EA),
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withValues(
//                           alpha: 0.025,
//                         ),
//                         blurRadius: 14,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//
//                   child: Row(
//                     children: [
//
//                       Container(
//                         width: 52,
//                         height: 52,
//                         decoration: BoxDecoration(
//                           color:
//                           const Color(0xFFEAF0FF),
//                           borderRadius:
//                           BorderRadius.circular(13),
//                         ),
//                         child: const Icon(
//                           Icons.fact_check_outlined,
//                           color: Color(0xFF3155C6),
//                           size: 27,
//                         ),
//                       ),
//
//                       const SizedBox(width: 16),
//
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment:
//                           CrossAxisAlignment.start,
//                           children: [
//
//                             const Text(
//                               "Inspection Batch",
//                               style: TextStyle(
//                                 fontSize: 20,
//                                 fontWeight:
//                                 FontWeight.w700,
//                                 color:
//                                 Color(0xFF202124),
//                               ),
//                             ),
//
//                             const SizedBox(height: 5),
//
//                             const Text(
//                               "Select an active batch for this ARR assessment.",
//                               style: TextStyle(
//                                 fontSize: 12.5,
//                                 color:
//                                 Color(0xFF747B86),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//
//                       // BATCH COUNT
//                       Container(
//                         padding:
//                         const EdgeInsets.symmetric(
//                           horizontal: 14,
//                           vertical: 9,
//                         ),
//
//                         decoration: BoxDecoration(
//                           color:
//                           const Color(0xFFF1F4FA),
//                           borderRadius:
//                           BorderRadius.circular(9),
//                         ),
//
//                         child: Text(
//                           "${batches.length} Active "
//                               "${batches.length == 1 ? "Batch" : "Batches"}",
//                           style: const TextStyle(
//                             fontSize: 11.5,
//                             fontWeight:
//                             FontWeight.w600,
//                             color:
//                             Color(0xFF3155C6),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 const SizedBox(height: 22),
//
//                 const Text(
//                   "Available Batches",
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w700,
//                     color: Color(0xFF202124),
//                   ),
//                 ),
//
//                 const SizedBox(height: 5),
//
//                 const Text(
//                   "Choose the batch containing the required inspection parts.",
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Color(0xFF747B86),
//                   ),
//                 ),
//
//                 const SizedBox(height: 14),
//
//                 // BATCH GRID
//                 GridView.builder(
//                   shrinkWrap: true,
//                   physics:
//                   const NeverScrollableScrollPhysics(),
//
//                   gridDelegate:
//                   const SliverGridDelegateWithMaxCrossAxisExtent(
//                     maxCrossAxisExtent: 520,
//                     mainAxisExtent: 150,
//                     crossAxisSpacing: 16,
//                     mainAxisSpacing: 16,
//                   ),
//
//                   itemCount: batches.length,
//
//                   itemBuilder: (_, index) {
//                     final batch = batches[index];
//
//                     return _buildBatchCard(
//                       context,
//                       batch,
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBatchCard(
//       BuildContext context,
//       Batch batch,
//       ) {
//     return Material(
//       color: Colors.white,
//
//       borderRadius: BorderRadius.circular(14),
//
//       child: InkWell(
//         borderRadius: BorderRadius.circular(14),
//
//         onTap: () {
//           AppData.selectedBatchId = batch.id;
//           AppData.selectedBatchName = batch.name;
//
//           Navigator.pushReplacementNamed(
//             context,
//             "/instruction",
//           );
//         },
//
//         child: Container(
//           padding: const EdgeInsets.all(20),
//
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(14),
//
//             border: Border.all(
//               color: const Color(0xFFE1E5EA),
//             ),
//
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withValues(
//                   alpha: 0.018,
//                 ),
//                 blurRadius: 10,
//                 offset: const Offset(0, 3),
//               ),
//             ],
//           ),
//
//           child: Row(
//             children: [
//
//               // ICON
//               Container(
//                 width: 48,
//                 height: 48,
//
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFF0F4FF),
//                   borderRadius:
//                   BorderRadius.circular(12),
//                 ),
//
//                 child: const Icon(
//                   Icons.inventory_2_outlined,
//                   color: Color(0xFF3155C6),
//                   size: 24,
//                 ),
//               ),
//
//               const SizedBox(width: 16),
//
//               // DETAILS
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment:
//                   CrossAxisAlignment.start,
//                   mainAxisAlignment:
//                   MainAxisAlignment.center,
//
//                   children: [
//
//                     Text(
//                       batch.name,
//                       maxLines: 1,
//                       overflow:
//                       TextOverflow.ellipsis,
//
//                       style: const TextStyle(
//                         fontSize: 15,
//                         fontWeight:
//                         FontWeight.w700,
//                         color:
//                         Color(0xFF202124),
//                       ),
//                     ),
//
//                     const SizedBox(height: 6),
//
//                     Text(
//                       batch.description.isEmpty
//                           ? "No description available"
//                           : batch.description,
//
//                       maxLines: 2,
//                       overflow:
//                       TextOverflow.ellipsis,
//
//                       style: const TextStyle(
//                         fontSize: 11.5,
//                         height: 1.35,
//                         color:
//                         Color(0xFF747B86),
//                       ),
//                     ),
//
//                     const SizedBox(height: 8),
//
//                     Text(
//                       "Batch ID: ${batch.id}",
//                       maxLines: 1,
//                       overflow:
//                       TextOverflow.ellipsis,
//
//                       style: const TextStyle(
//                         fontSize: 10.5,
//                         fontWeight:
//                         FontWeight.w600,
//                         color:
//                         Color(0xFF8A93A1),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               const SizedBox(width: 12),
//
//               // ACTION
//               Container(
//                 width: 36,
//                 height: 36,
//
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFF3F5F9),
//                   borderRadius:
//                   BorderRadius.circular(9),
//                 ),
//
//                 child: const Icon(
//                   Icons.arrow_forward_rounded,
//                   size: 19,
//                   color: Color(0xFF5F6875),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
// }
import 'package:flutter/material.dart';

import '../services/app_data.dart';
import '../services/supabase_service.dart';

class BatchSelectionScreen extends StatefulWidget {
  const BatchSelectionScreen({super.key});

  @override
  State<BatchSelectionScreen> createState() =>
      _BatchSelectionScreenState();
}

class _BatchSelectionScreenState
    extends State<BatchSelectionScreen> {

  List<Map<String, dynamic>> batches = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    try {
      final result =
      await SupabaseService.getActiveBatches();

      if (!mounted) return;

      setState(() {
        batches = result;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        batches = [];
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 72,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF202124),
          ),
          onPressed: () => Navigator.pop(context),
        ),

        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFF3155C6),
                size: 22,
              ),
            ),

            const SizedBox(width: 14),

            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Select Batch",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202124),
                    height: 1.1,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  "Choose the inspection batch to continue",
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF7A8494),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1120,
          ),

          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              28,
              28,
              28,
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
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE1E5EA),
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
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF0FF),
                          borderRadius:
                          BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.fact_check_outlined,
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
                              "Inspection Batch",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF202124),
                              ),
                            ),

                            const SizedBox(height: 5),

                            const Text(
                              "Select an active batch for this ARR assessment.",
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF747B86),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // BATCH COUNT
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),

                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F4FA),
                          borderRadius:
                          BorderRadius.circular(9),
                        ),

                        child: Text(
                          "${batches.length} Active "
                              "${batches.length == 1 ? "Batch" : "Batches"}",
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3155C6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  "Available Batches",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202124),
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  "Choose the batch containing the required inspection parts.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF747B86),
                  ),
                ),

                const SizedBox(height: 14),

                // LOADING
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 60,
                      ),
                      child: CircularProgressIndicator(),
                    ),
                  )

                // ERROR
                else if (errorMessage != null)
                  _buildErrorState()

                // NO BATCHES
                else if (batches.isEmpty)
                    _buildEmptyState()

                  // BATCH GRID
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics:
                      const NeverScrollableScrollPhysics(),

                      gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 520,
                        mainAxisExtent: 150,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),

                      itemCount: batches.length,

                      itemBuilder: (_, index) {
                        final batch = batches[index];

                        return _buildBatchCard(
                          context,
                          batch,
                        );
                      },
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE1E5EA),
        ),
      ),

      child: Column(
        children: [

          const Icon(
            Icons.cloud_off_outlined,
            size: 42,
            color: Color(0xFF7A8494),
          ),

          const SizedBox(height: 12),

          const Text(
            "Unable to load batches",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF202124),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            errorMessage ?? "Unknown error",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF747B86),
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                isLoading = true;
                errorMessage = null;
              });

              _loadBatches();
            },

            icon: const Icon(
              Icons.refresh_rounded,
              size: 18,
            ),

            label: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE1E5EA),
        ),
      ),

      child: const Column(
        children: [

          Icon(
            Icons.inventory_2_outlined,
            size: 46,
            color: Color(0xFF9AA3AF),
          ),

          SizedBox(height: 12),

          Text(
            "No Active Batches",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF202124),
            ),
          ),

          SizedBox(height: 6),

          Text(
            "No active inspection batches are currently available.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFF747B86),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BATCH CARD
  // ============================================================

  Widget _buildBatchCard(
      BuildContext context,
      Map<String, dynamic> batch,
      ) {
    final String batchId =
        batch['batch_id']?.toString() ?? '';

    final String batchCode =
        batch['batch_code']?.toString() ?? '';

    final String batchName =
        batch['batch_name']?.toString() ?? 'Unnamed Batch';

    return Material(
      color: Colors.white,

      borderRadius: BorderRadius.circular(14),

      child: InkWell(
        borderRadius: BorderRadius.circular(14),

        onTap: () {
          AppData.selectedBatchId = batchId;
          AppData.selectedBatchName = batchName;

          Navigator.pushReplacementNamed(
            context,
            "/ARR/instruction",
          );
        },

        child: Container(
          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),

            border: Border.all(
              color: const Color(0xFFE1E5EA),
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.018,
                ),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),

          child: Row(
            children: [

              // ICON
              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius:
                  BorderRadius.circular(12),
                ),

                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF3155C6),
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // DETAILS
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  mainAxisAlignment:
                  MainAxisAlignment.center,

                  children: [

                    Text(
                      batchName,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w700,
                        color:
                        Color(0xFF202124),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      batchCode.isEmpty
                          ? "Inspection Batch"
                          : batchCode,

                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color:
                        Color(0xFF747B86),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Batch ID: $batchId",
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight:
                        FontWeight.w600,
                        color:
                        Color(0xFF8A93A1),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ACTION
              Container(
                width: 36,
                height: 36,

                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5F9),
                  borderRadius:
                  BorderRadius.circular(9),
                ),

                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 19,
                  color: Color(0xFF5F6875),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}