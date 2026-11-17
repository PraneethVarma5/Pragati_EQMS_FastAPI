// import 'package:flutter/material.dart';
// import '../services/app_data.dart';
//
// class InstructionScreen extends StatefulWidget {
//   const InstructionScreen({super.key});
//
//   @override
//   State<InstructionScreen> createState() => _InstructionScreenState();
// }
//
// class _InstructionScreenState extends State<InstructionScreen> {
//   bool agreed = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Instructions")),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             const Text('''
// Digital ARR Assessment Instructions
//
// • Select the required Batch before starting.
//
// • Scan the Part QR Code to load the part.
//
// • Inspect the physical part.
//
// • Select PASS or FAIL.
//
// • Once submitted, an answer cannot be changed.
//
// • Complete all parts in Trial 1 to unlock Trial 2.
//
// • Complete all parts in Trial 2 to unlock Trial 3.
//
// • Final ARR Evaluation is generated after all three trials.
//
// • Any issue facing during the assessment contact the Appraiser or Higher Officals
// '''),
//
//             CheckboxListTile(
//               value: agreed,
//               onChanged: (v) {
//                 setState(() {
//                   agreed = v!;
//                 });
//               },
//               title: const Text("I have read all instructions clearly"),
//             ),
//
//             const Spacer(),
//
//             SizedBox(
//               width: double.infinity,
//               height: 55,
//               child: ElevatedButton(
//                 onPressed: agreed
//                     ? () {
//                   final batchId = AppData.selectedBatchId;
//                   final batchName = AppData.selectedBatchName;
//
//                   AppData.resetAssessment();
//
//                   AppData.selectedBatchId = batchId;
//                   AppData.selectedBatchName = batchName;
//
//                   AppData.currentTrail = 1;
//
//                   Navigator.pushNamed(
//                     context,
//                     '/scannerAssessment',
//                   );
//                 }
//                     : null,
//                 child: const Text("Start Assessment"),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import '../services/app_data.dart';
//
// class InstructionScreen extends StatefulWidget {
//   const InstructionScreen({super.key});
//
//   @override
//   State<InstructionScreen> createState() => _InstructionScreenState();
// }
//
// class _InstructionScreenState extends State<InstructionScreen> {
//   bool agreed = false;
//
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: const Text("Instructions")),
// //       body: Padding(
// //         padding: const EdgeInsets.all(20),
// //         child: Column(
// //           children: [
// //             const Text('''
// // Digital ARR Assessment Instructions
// //
// // • Select the required Batch before starting.
// //
// // • Scan the Part QR Code to load the part.
// //
// // • Inspect the physical part.
// //
// // • Select PASS or FAIL.
// //
// // • Once submitted, an answer cannot be changed.
// //
// // • Complete all parts in Trial 1 to unlock Trial 2.
// //
// // • Complete all parts in Trial 2 to unlock Trial 3.
// //
// // • Final ARR Evaluation is generated after all three trials.
// //
// // • Any issue facing during the assessment contact the Appraiser or Higher Officals
// // '''),
// //
// //             CheckboxListTile(
// //               value: agreed,
// //               onChanged: (v) {
// //                 setState(() {
// //                   agreed = v!;
// //                 });
// //               },
// //               title: const Text("I have read all instructions clearly"),
// //             ),
// //
// //             const Spacer(),
// //
// //             SizedBox(
// //               width: double.infinity,
// //               height: 55,
// //               child: ElevatedButton(
// //                 onPressed: agreed
// //                     ? () {
// //                   final batchId = AppData.selectedBatchId;
// //                   final batchName = AppData.selectedBatchName;
// //
// //                   // Candidate details and photo were captured on the
// //                   // Candidate Screen, before the batch was even selected.
// //                   // resetAssessment() clears them (it's meant to clear
// //                   // stale assessment results only), so they must be
// //                   // saved here and restored below, the same way the
// //                   // selected batch already is.
// //                   final employeeCode = AppData.employeeCode;
// //                   final appraiseeName = AppData.appraiseeName;
// //                   final department = AppData.department;
// //                   final productName = AppData.productName;
// //                   final candidatePhoto = AppData.candidatePhoto;
// //                   final candidatePhotoPath = AppData.candidatePhotoPath;
// //
// //                   AppData.resetAssessment();
// //
// //                   AppData.selectedBatchId = batchId;
// //                   AppData.selectedBatchName = batchName;
// //
// //                   AppData.employeeCode = employeeCode;
// //                   AppData.appraiseeName = appraiseeName;
// //                   AppData.department = department;
// //                   AppData.productName = productName;
// //                   AppData.candidatePhoto = candidatePhoto;
// //                   AppData.candidatePhotoPath = candidatePhotoPath;
// //
// //                   AppData.currentTrail = 1;
// //
// //                   Navigator.pushNamed(
// //                     context,
// //                     '/scannerAssessment',
// //                   );
// //                 }
// //                     : null,
// //                 child: const Text("Start Assessment"),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
//   @override
//   Widget build(BuildContext context) {
//     final batchName =
//     AppData.selectedBatchName.isEmpty
//         ? "Selected Batch"
//         : AppData.selectedBatchName;
//
//     final batchId =
//     AppData.selectedBatchId.isEmpty
//         ? "-"
//         : AppData.selectedBatchId;
//
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
//
//             Container(
//               width: 42,
//               height: 42,
//
//               decoration: BoxDecoration(
//                 color: const Color(0xFFEAF0FF),
//                 borderRadius:
//                 BorderRadius.circular(11),
//               ),
//
//               child: const Icon(
//                 Icons.fact_check_outlined,
//                 color: Color(0xFF3155C6),
//                 size: 23,
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
//
//               children: [
//
//                 Text(
//                   "ARR Assessment",
//                   style: TextStyle(
//                     fontSize: 19,
//                     fontWeight:
//                     FontWeight.w700,
//                     color: Color(0xFF202124),
//                     height: 1.1,
//                   ),
//                 ),
//
//                 SizedBox(height: 4),
//
//                 Text(
//                   "Instructions & assessment preparation",
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
//               36,
//             ),
//
//             child: Column(
//               crossAxisAlignment:
//               CrossAxisAlignment.start,
//
//               children: [
//
//                 // PAGE HEADER
//                 Container(
//                   width: double.infinity,
//
//                   padding:
//                   const EdgeInsets.all(24),
//
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//
//                     borderRadius:
//                     BorderRadius.circular(16),
//
//                     border: Border.all(
//                       color:
//                       const Color(0xFFE1E5EA),
//                     ),
//
//                     boxShadow: [
//                       BoxShadow(
//                         color:
//                         Colors.black.withValues(
//                           alpha: 0.025,
//                         ),
//                         blurRadius: 14,
//                         offset:
//                         const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//
//                   child: Row(
//                     children: [
//
//                       Container(
//                         width: 54,
//                         height: 54,
//
//                         decoration:
//                         BoxDecoration(
//                           color:
//                           const Color(0xFFEAF0FF),
//                           borderRadius:
//                           BorderRadius.circular(
//                             13,
//                           ),
//                         ),
//
//                         child: const Icon(
//                           Icons.rule_folder_outlined,
//                           color:
//                           Color(0xFF3155C6),
//                           size: 28,
//                         ),
//                       ),
//
//                       const SizedBox(width: 16),
//
//                       const Expanded(
//                         child: Column(
//                           crossAxisAlignment:
//                           CrossAxisAlignment.start,
//
//                           children: [
//
//                             Text(
//                               "Before You Begin",
//                               style: TextStyle(
//                                 fontSize: 21,
//                                 fontWeight:
//                                 FontWeight.w700,
//                                 color:
//                                 Color(0xFF202124),
//                               ),
//                             ),
//
//                             SizedBox(height: 5),
//
//                             Text(
//                               "Review the assessment procedure carefully before starting the inspection.",
//                               style: TextStyle(
//                                 fontSize: 12.5,
//                                 color:
//                                 Color(0xFF747B86),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 const SizedBox(height: 18),
//
//                 // SELECTED BATCH
//                 Container(
//                   width: double.infinity,
//
//                   padding:
//                   const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 16,
//                   ),
//
//                   decoration: BoxDecoration(
//                     color:
//                     const Color(0xFFF8FAFF),
//
//                     borderRadius:
//                     BorderRadius.circular(12),
//
//                     border: Border.all(
//                       color:
//                       const Color(0xFFDCE4F8),
//                     ),
//                   ),
//
//                   child: Row(
//                     children: [
//
//                       Container(
//                         width: 38,
//                         height: 38,
//
//                         decoration:
//                         BoxDecoration(
//                           color:
//                           const Color(0xFFEAF0FF),
//                           borderRadius:
//                           BorderRadius.circular(
//                             9,
//                           ),
//                         ),
//
//                         child: const Icon(
//                           Icons.inventory_2_outlined,
//                           size: 20,
//                           color:
//                           Color(0xFF3155C6),
//                         ),
//                       ),
//
//                       const SizedBox(width: 12),
//
//                       const Text(
//                         "Selected Batch",
//                         style: TextStyle(
//                           fontSize: 11,
//                           fontWeight:
//                           FontWeight.w600,
//                           color:
//                           Color(0xFF747B86),
//                         ),
//                       ),
//
//                       const SizedBox(width: 14),
//
//                       Text(
//                         batchName,
//                         style: const TextStyle(
//                           fontSize: 13,
//                           fontWeight:
//                           FontWeight.w700,
//                           color:
//                           Color(0xFF202124),
//                         ),
//                       ),
//
//                       const SizedBox(width: 12),
//
//                       Container(
//                         padding:
//                         const EdgeInsets.symmetric(
//                           horizontal: 9,
//                           vertical: 5,
//                         ),
//
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius:
//                           BorderRadius.circular(7),
//                           border: Border.all(
//                             color:
//                             const Color(
//                               0xFFDCE1E8,
//                             ),
//                           ),
//                         ),
//
//                         child: Text(
//                           "ID: $batchId",
//                           style:
//                           const TextStyle(
//                             fontSize: 10,
//                             fontWeight:
//                             FontWeight.w600,
//                             color:
//                             Color(0xFF687282),
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
//                   "Assessment Procedure",
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight:
//                     FontWeight.w700,
//                     color:
//                     Color(0xFF202124),
//                   ),
//                 ),
//
//                 const SizedBox(height: 5),
//
//                 const Text(
//                   "Follow these steps throughout the ARR assessment.",
//                   style: TextStyle(
//                     fontSize: 12,
//                     color:
//                     Color(0xFF747B86),
//                   ),
//                 ),
//
//                 const SizedBox(height: 14),
//
//                 // INSTRUCTION GRID
//                 LayoutBuilder(
//                   builder:
//                       (context, constraints) {
//
//                     final cardWidth =
//                         (constraints.maxWidth -
//                             16) /
//                             2;
//
//                     return Wrap(
//                       spacing: 16,
//                       runSpacing: 16,
//
//                       children: [
//
//                         _instructionCard(
//                           width: cardWidth,
//                           number: "01",
//                           title:
//                           "Scan the Part",
//                           description:
//                           "Use the handheld scanner to scan the part QR code and load the inspection item.",
//                           icon:
//                           Icons.qr_code_scanner_rounded,
//                         ),
//
//                         _instructionCard(
//                           width: cardWidth,
//                           number: "02",
//                           title:
//                           "Inspect the Part",
//                           description:
//                           "Physically inspect the part against the required inspection criteria.",
//                           icon:
//                           Icons.search_outlined,
//                         ),
//
//                         _instructionCard(
//                           width: cardWidth,
//                           number: "03",
//                           title:
//                           "Select PASS or FAIL",
//                           description:
//                           "Record the inspection result after completing the physical inspection.",
//                           icon:
//                           Icons.fact_check_outlined,
//                         ),
//
//                         _instructionCard(
//                           width: cardWidth,
//                           number: "04",
//                           title:
//                           "Submit Once",
//                           description:
//                           "Once a value is submitted, it cannot be changed.",
//                           icon:
//                           Icons.lock_outline_rounded,
//                         ),
//
//                         _instructionCard(
//                           width: cardWidth,
//                           number: "05",
//                           title:
//                           "Complete Trial 1",
//                           description:
//                           "Finish all parts in Trial 1 to unlock Trial 2.",
//                           icon:
//                           Icons.looks_one_outlined,
//                         ),
//
//                         _instructionCard(
//                           width: cardWidth,
//                           number: "06",
//                           title:
//                           "Complete Trial 2",
//                           description:
//                           "Finish all parts in Trial 2 to unlock Trial 3.",
//                           icon:
//                           Icons.looks_two_outlined,
//                         ),
//
//                         _instructionCard(
//                           width: cardWidth,
//                           number: "07",
//                           title:
//                           "Complete Trial 3",
//                           description:
//                           "Complete the final trial to finish the assessment.",
//                           icon:
//                           Icons.looks_3_outlined,
//                         ),
//
//                         _instructionCard(
//                           width: cardWidth,
//                           number: "08",
//                           title:
//                           "Final Evaluation",
//                           description:
//                           "The final ARR evaluation is generated after all three trials are completed.",
//                           icon:
//                           Icons.assessment_outlined,
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//
//                 const SizedBox(height: 22),
//
//                 // IMPORTANT NOTE
//                 Container(
//                   width: double.infinity,
//
//                   padding:
//                   const EdgeInsets.all(18),
//
//                   decoration: BoxDecoration(
//                     color:
//                     const Color(0xFFFFFAF0),
//
//                     borderRadius:
//                     BorderRadius.circular(12),
//
//                     border: Border.all(
//                       color:
//                       const Color(0xFFF0DFC0),
//                     ),
//                   ),
//
//                   child: Row(
//                     crossAxisAlignment:
//                     CrossAxisAlignment.start,
//
//                     children: [
//
//                       const Icon(
//                         Icons.info_outline_rounded,
//                         size: 20,
//                         color:
//                         Color(0xFF9A6B18),
//                       ),
//
//                       const SizedBox(width: 12),
//
//                       const Expanded(
//                         child: Column(
//                           crossAxisAlignment:
//                           CrossAxisAlignment.start,
//
//                           children: [
//
//                             Text(
//                               "Need assistance?",
//                               style: TextStyle(
//                                 fontSize: 12.5,
//                                 fontWeight:
//                                 FontWeight.w700,
//                                 color:
//                                 Color(0xFF76520F),
//                               ),
//                             ),
//
//                             SizedBox(height: 4),
//
//                             Text(
//                               "If you face any issue during the assessment, contact the Appraiser or authorized higher official.",
//                               style: TextStyle(
//                                 fontSize: 11.5,
//                                 height: 1.4,
//                                 color:
//                                 Color(0xFF80652C),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 // AGREEMENT + START
//                 Container(
//                   width: double.infinity,
//
//                   padding:
//                   const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 16,
//                   ),
//
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//
//                     borderRadius:
//                     BorderRadius.circular(14),
//
//                     border: Border.all(
//                       color:
//                       const Color(0xFFE1E5EA),
//                     ),
//                   ),
//
//                   child: Row(
//                     children: [
//
//                       Checkbox(
//                         value: agreed,
//
//                         activeColor:
//                         const Color(0xFF3155C6),
//
//                         onChanged: (value) {
//                           setState(() {
//                             agreed =
//                                 value ?? false;
//                           });
//                         },
//                       ),
//
//                       const Expanded(
//                         child: Column(
//                           crossAxisAlignment:
//                           CrossAxisAlignment.start,
//
//                           children: [
//
//                             Text(
//                               "I have read and understood the instructions",
//                               style: TextStyle(
//                                 fontSize: 12.5,
//                                 fontWeight:
//                                 FontWeight.w600,
//                                 color:
//                                 Color(0xFF202124),
//                               ),
//                             ),
//
//                             SizedBox(height: 3),
//
//                             Text(
//                               "I understand that submitted inspection results cannot be changed.",
//                               style: TextStyle(
//                                 fontSize: 10.5,
//                                 color:
//                                 Color(0xFF7A8494),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//
//                       const SizedBox(width: 20),
//
//                       SizedBox(
//                         width: 205,
//                         height: 46,
//
//                         child: ElevatedButton.icon(
//                           onPressed: agreed
//                               ? () {
//
//                             final batchId =
//                                 AppData
//                                     .selectedBatchId;
//
//                             final batchName =
//                                 AppData
//                                     .selectedBatchName;
//
//                             final employeeCode =
//                                 AppData
//                                     .employeeCode;
//
//                             final appraiseeName =
//                                 AppData
//                                     .appraiseeName;
//
//                             final department =
//                                 AppData
//                                     .department;
//
//                             final productName =
//                                 AppData
//                                     .productName;
//
//                             final candidatePhoto =
//                                 AppData
//                                     .candidatePhoto;
//
//                             final candidatePhotoPath =
//                                 AppData
//                                     .candidatePhotoPath;
//
//                             AppData.resetAssessment();
//
//                             AppData
//                                 .selectedBatchId =
//                                 batchId;
//
//                             AppData
//                                 .selectedBatchName =
//                                 batchName;
//
//                             AppData.employeeCode =
//                                 employeeCode;
//
//                             AppData.appraiseeName =
//                                 appraiseeName;
//
//                             AppData.department =
//                                 department;
//
//                             AppData.productName =
//                                 productName;
//
//                             AppData.candidatePhoto =
//                                 candidatePhoto;
//
//                             AppData
//                                 .candidatePhotoPath =
//                                 candidatePhotoPath;
//
//                             AppData.currentTrail =
//                             1;
//
//                             Navigator.pushNamed(
//                               context,
//                               '/scannerAssessment',
//                             );
//                           }
//                               : null,
//
//                           icon: const Icon(
//                             Icons.play_arrow_rounded,
//                             size: 20,
//                           ),
//
//                           label: const Text(
//                             "Start Assessment",
//                             style: TextStyle(
//                               fontSize: 12.5,
//                               fontWeight:
//                               FontWeight.w600,
//                             ),
//                           ),
//
//                           style:
//                           ElevatedButton.styleFrom(
//                             backgroundColor:
//                             const Color(
//                               0xFF3155C6,
//                             ),
//
//                             disabledBackgroundColor:
//                             const Color(
//                               0xFFE2E5EA,
//                             ),
//
//                             foregroundColor:
//                             Colors.white,
//
//                             disabledForegroundColor:
//                             const Color(
//                               0xFF9299A4,
//                             ),
//
//                             elevation: 0,
//
//                             shape:
//                             RoundedRectangleBorder(
//                               borderRadius:
//                               BorderRadius.circular(
//                                 9,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _instructionCard({
//     required double width,
//     required String number,
//     required String title,
//     required String description,
//     required IconData icon,
//   }) {
//     return Container(
//       width: width,
//       constraints: const BoxConstraints(
//         minHeight: 118,
//       ),
//
//       padding: const EdgeInsets.all(17),
//
//       decoration: BoxDecoration(
//         color: Colors.white,
//
//         borderRadius:
//         BorderRadius.circular(13),
//
//         border: Border.all(
//           color: const Color(0xFFE1E5EA),
//         ),
//
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(
//               alpha: 0.018,
//             ),
//             blurRadius: 9,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//
//       child: Row(
//         crossAxisAlignment:
//         CrossAxisAlignment.start,
//
//         children: [
//
//           Container(
//             width: 42,
//             height: 42,
//
//             decoration: BoxDecoration(
//               color: const Color(0xFFF0F4FF),
//               borderRadius:
//               BorderRadius.circular(10),
//             ),
//
//             child: Icon(
//               icon,
//               size: 21,
//               color: const Color(0xFF3155C6),
//             ),
//           ),
//
//           const SizedBox(width: 13),
//
//           Expanded(
//             child: Column(
//               crossAxisAlignment:
//               CrossAxisAlignment.start,
//
//               children: [
//
//                 Row(
//                   children: [
//
//                     Text(
//                       number,
//                       style: const TextStyle(
//                         fontSize: 9.5,
//                         fontWeight:
//                         FontWeight.w700,
//                         color:
//                         Color(0xFF3155C6),
//                       ),
//                     ),
//
//                     const SizedBox(width: 8),
//
//                     Expanded(
//                       child: Text(
//                         title,
//                         style:
//                         const TextStyle(
//                           fontSize: 13,
//                           fontWeight:
//                           FontWeight.w700,
//                           color:
//                           Color(0xFF202124),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 const SizedBox(height: 7),
//
//                 Text(
//                   description,
//                   style: const TextStyle(
//                     fontSize: 11,
//                     height: 1.4,
//                     color:
//                     Color(0xFF747B86),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import '../services/app_data.dart';

class InstructionScreen extends StatefulWidget {
  const InstructionScreen({super.key});

  @override
  State<InstructionScreen> createState() =>
      _InstructionScreenState();
}

class _InstructionScreenState extends State<InstructionScreen> {
  bool agreed = false;

  @override
  Widget build(BuildContext context) {
    final batchName = AppData.selectedBatchName.isEmpty
        ? "Selected Batch"
        : AppData.selectedBatchName;

    final batchId = AppData.selectedBatchId.isEmpty
        ? "-"
        : AppData.selectedBatchId;

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
                Icons.fact_check_outlined,
                color: Color(0xFF3155C6),
                size: 23,
              ),
            ),

            const SizedBox(width: 14),

            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "ARR Assessment",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202124),
                    height: 1.1,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  "Instructions & assessment preparation",
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
            maxWidth: 1180,
          ),

          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 16,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // =====================================================
                // HEADER
                // =====================================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE1E5EA),
                    ),
                  ),

                  child: Row(
                    children: [

                      Container(
                        width: 46,
                        height: 46,

                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF0FF),
                          borderRadius:
                          BorderRadius.circular(11),
                        ),

                        child: const Icon(
                          Icons.rule_folder_outlined,
                          color: Color(0xFF3155C6),
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: 13),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [

                            Text(
                              "Before You Begin",
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight:
                                FontWeight.w700,
                                color:
                                Color(0xFF202124),
                              ),
                            ),

                            SizedBox(height: 3),

                            Text(
                              "Complete the inspection flow in sequence.",
                              style: TextStyle(
                                fontSize: 11,
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

                const SizedBox(height: 12),

                // =====================================================
                // SELECTED BATCH
                // =====================================================

                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),

                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFF),
                    borderRadius:
                    BorderRadius.circular(11),
                    border: Border.all(
                      color: const Color(0xFFDCE4F8),
                    ),
                  ),

                  child: Row(
                    children: [

                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 19,
                        color: Color(0xFF3155C6),
                      ),

                      const SizedBox(width: 10),

                      const Text(
                        "Selected Batch",
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight:
                          FontWeight.w600,
                          color:
                          Color(0xFF747B86),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          batchName,
                          overflow:
                          TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight:
                            FontWeight.w700,
                            color:
                            Color(0xFF202124),
                          ),
                        ),
                      ),

                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                          BorderRadius.circular(6),
                          border: Border.all(
                            color:
                            const Color(0xFFDCE1E8),
                          ),
                        ),

                        child: Text(
                          "ID: $batchId",
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight:
                            FontWeight.w600,
                            color:
                            Color(0xFF687282),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // =====================================================
                // FLOW TITLE
                // =====================================================

                const Text(
                  "Assessment Flow",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202124),
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  "Submitted results cannot be changed.",
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF747B86),
                  ),
                ),

                const SizedBox(height: 10),

                // =====================================================
                // COMPACT FLOW
                // =====================================================

                Row(
                  children: [

                    _flowStep(
                      number: "01",
                      title: "Select Batch",
                      description: "Choose batch",
                      icon: Icons.inventory_2_outlined,
                    ),

                    _flowArrow(),

                    _flowStep(
                      number: "02",
                      title: "Scan Part",
                      description: "Scan QR",
                      icon: Icons.qr_code_scanner_rounded,
                    ),

                    _flowArrow(),

                    _flowStep(
                      number: "03",
                      title: "Inspect",
                      description: "Physical check",
                      icon: Icons.search_outlined,
                    ),

                    _flowArrow(),

                    _flowStep(
                      number: "04",
                      title: "PASS / FAIL",
                      description: "Record result",
                      icon: Icons.fact_check_outlined,
                    ),

                    _flowArrow(),

                    _flowStep(
                      number: "05",
                      title: "Trial 1",
                      description: "Complete parts",
                      icon: Icons.looks_one_outlined,
                    ),

                    _flowArrow(),

                    _flowStep(
                      number: "06",
                      title: "Trial 2",
                      description: "After Trial 1",
                      icon: Icons.looks_two_outlined,
                    ),

                    _flowArrow(),

                    _flowStep(
                      number: "07",
                      title: "Trial 3",
                      description: "Final trial",
                      icon: Icons.looks_3_outlined,
                    ),

                    _flowArrow(),

                    _flowStep(
                      number: "08",
                      title: "Evaluation",
                      description: "Final results",
                      icon: Icons.assessment_outlined,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // =====================================================
                // IMPORTANT
                // =====================================================

                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),

                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFAF0),
                    borderRadius:
                    BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFF0DFC0),
                    ),
                  ),

                  child: Row(
                    children: [

                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Color(0xFF9A6B18),
                      ),

                      const SizedBox(width: 10),

                      const Expanded(
                        child: Text(
                          "Results cannot be changed after submission. "
                              "Trial 2 unlocks after Trial 1, Trial 3 after Trial 2.",
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.3,
                            color: Color(0xFF80652C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // =====================================================
                // AGREEMENT + START
                // =====================================================

                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(11),
                    border: Border.all(
                      color: const Color(0xFFE1E5EA),
                    ),
                  ),

                  child: Row(
                    children: [

                      Checkbox(
                        value: agreed,
                        activeColor:
                        const Color(0xFF3155C6),

                        visualDensity:
                        VisualDensity.compact,

                        onChanged: (value) {
                          setState(() {
                            agreed = value ?? false;
                          });
                        },
                      ),

                      const Expanded(
                        child: Text(
                          "I have read and understood the instructions.",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                            FontWeight.w600,
                            color:
                            Color(0xFF202124),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      SizedBox(
                        width: 190,
                        height: 42,

                        child: ElevatedButton.icon(
                          onPressed:
                          agreed
                              ? _startAssessment
                              : null,

                          icon: const Icon(
                            Icons.play_arrow_rounded,
                            size: 19,
                          ),

                          label: const Text(
                            "Start Assessment",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),

                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(0xFF3155C6),

                            disabledBackgroundColor:
                            const Color(0xFFE2E5EA),

                            foregroundColor:
                            Colors.white,

                            disabledForegroundColor:
                            const Color(0xFF9299A4),

                            elevation: 0,

                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // START ASSESSMENT
  // ===============================================================

  void _startAssessment() {
    final batchId =
        AppData.selectedBatchId;

    final batchName =
        AppData.selectedBatchName;

    final employeeCode =
        AppData.employeeCode;

    final appraiseeName =
        AppData.appraiseeName;

    final department =
        AppData.department;

    final productName =
        AppData.productName;

    final candidatePhoto =
        AppData.candidatePhoto;

    final candidatePhotoPath =
        AppData.candidatePhotoPath;

    AppData.resetAssessment();

    AppData.selectedBatchId =
        batchId;

    AppData.selectedBatchName =
        batchName;

    AppData.employeeCode =
        employeeCode;

    AppData.appraiseeName =
        appraiseeName;

    AppData.department =
        department;

    AppData.productName =
        productName;

    AppData.candidatePhoto =
        candidatePhoto;

    AppData.candidatePhotoPath =
        candidatePhotoPath;

    AppData.currentTrail = 1;

    Navigator.pushNamed(
      context,
      '/ARR/scannerAssessment',
    );
  }

  // ===============================================================
  // FLOW STEP
  // ===============================================================

  Widget _flowStep({
    required String number,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return SizedBox(
      width: 112,
      height: 116,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 9,
        ),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: const Color(0xFFE1E5EA),
          ),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Stack(
              clipBehavior: Clip.none,
              children: [

                Container(
                  width: 38,
                  height: 38,

                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(10),
                  ),

                  child: Icon(
                    icon,
                    size: 20,
                    color: const Color(0xFF3155C6),
                  ),
                ),

                Positioned(
                  top: -6,
                  right: -6,

                  child: Container(
                    width: 18,
                    height: 18,

                    decoration: const BoxDecoration(
                      color: Color(0xFF3155C6),
                      shape: BoxShape.circle,
                    ),

                    alignment: Alignment.center,

                    child: Text(
                      number,
                      style: const TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 7),

            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202124),
              ),
            ),

            const SizedBox(height: 3),

            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 8,
                height: 1.15,
                color: Color(0xFF7A8494),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ===============================================================
  // FLOW ARROW
  // ===============================================================

  Widget _flowArrow() {
    return SizedBox(
      width: 28,
      child: const Icon(
        Icons.arrow_forward_rounded,
        size: 20,
        color: Color(0xFF9AA3B2),
      ),
    );
  }
}