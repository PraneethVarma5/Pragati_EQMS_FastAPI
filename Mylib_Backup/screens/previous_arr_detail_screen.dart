// import 'package:flutter/material.dart';
//
// import '../models/arr_record.dart';
// import '../services/pdf_service.dart';
//
// class PreviousArrDetailScreen extends StatelessWidget {
//   final ArrRecord record;
//
//   const PreviousArrDetailScreen({
//     super.key,
//     required this.record,
//   });
//
//   Map<String, dynamic> _recordToMap() {
//     return {
//       "employee_code": record.employeeCode,
//       "appraisee": record.appraisee,
//       "department": record.department,
//       "product": record.product,
//       "batch_name": record.batchName,
//       "result": record.result,
//       "certificate_no": record.certificateNo,
//       "date": record.date,
//       "false_alert_percent": record.falseAlertPercent,
//       "miss_rate": record.missRate,
//       "effectiveness": record.effectiveness,
//       "kappa": record.kappa,
//       "part_numbers": record.partNumbers,
//       "master_answers": record.masterAnswers,
//       "trail1_answers": record.trail1Answers,
//       "trail2_answers": record.trail2Answers,
//       "trail3_answers": record.trail3Answers,
//       "batch_id": record.batchId,
//     };
//   }
//
//   List<Map<String, dynamic>> _observations() {
//     final total = record.partNumbers.length;
//
//     return List.generate(total, (index) {
//       return {
//         "part_number_snap": record.partNumbers[index],
//         "master_status_snapshot":
//         record.masterAnswers[index],
//         "trail1": record.trail1Answers[index],
//         "trail2": record.trail2Answers[index],
//         "trail3": record.trail3Answers[index],
//       };
//     });
//   }
//
//   Widget info(String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 5),
//       child: Row(
//         children: [
//           SizedBox(
//             width: 130,
//             child: Text(
//               title,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(value),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget metric(
//       String name,
//       double value,
//       ) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(
//         vertical: 6,
//       ),
//       child: Row(
//         mainAxisAlignment:
//         MainAxisAlignment.spaceBetween,
//         children: [
//           Text(name),
//           Text(
//             value.toStringAsFixed(2),
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final bool hasPhoto =
//         record.candidatePhotoPath.isNotEmpty &&
//             (record.candidatePhotoPath.startsWith("http://") ||
//                 record.candidatePhotoPath.startsWith("https://"));
//
//     final bool isAcceptable =
//         record.result == "ACCEPTABLE";
//
//     final bool isMarginal =
//         record.result == "MARGINALLY ACCEPTABLE";
//
//     final Color resultColor = isAcceptable
//         ? const Color(0xFF249653)
//         : isMarginal
//         ? const Color(0xFFD88A24)
//         : const Color(0xFFD94A4A);
//
//     final Color resultBackground = isAcceptable
//         ? const Color(0xFFEAF7EF)
//         : isMarginal
//         ? const Color(0xFFFFF4E5)
//         : const Color(0xFFFDECEC);
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF6F7F9),
//
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         surfaceTintColor: Colors.transparent,
//         elevation: 0,
//
//         leading: IconButton(
//           icon: const Icon(
//             Icons.arrow_back_rounded,
//             color: Color(0xFF202124),
//           ),
//           onPressed: () => Navigator.pop(context),
//         ),
//
//         title: const Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               "Previous ARR Details",
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w700,
//                 color: Color(0xFF202124),
//               ),
//             ),
//             Text(
//               "Inspection record and report actions",
//               style: TextStyle(
//                 fontSize: 11.5,
//                 color: Color(0xFF777D86),
//               ),
//             ),
//           ],
//         ),
//       ),
//
//       body: Center(
//         child: ConstrainedBox(
//           constraints: const BoxConstraints(
//             maxWidth: 1150,
//           ),
//
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.fromLTRB(
//               28,
//               26,
//               28,
//               40,
//             ),
//
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//
//                 // HEADER
//                 Container(
//                   width: double.infinity,
//
//                   padding: const EdgeInsets.all(22),
//
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(18),
//                     border: Border.all(
//                       color: const Color(0xFFE1E4E8),
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withValues(
//                           alpha: 0.035,
//                         ),
//                         blurRadius: 18,
//                         offset: const Offset(0, 6),
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
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFEAF0FF),
//                           borderRadius:
//                           BorderRadius.circular(14),
//                         ),
//
//                         child: const Icon(
//                           Icons.assignment_turned_in_outlined,
//                           color: Color(0xFF3155C6),
//                           size: 28,
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
//                             const Text(
//                               "ARR Inspection Record",
//                               style: TextStyle(
//                                 fontSize: 21,
//                                 fontWeight: FontWeight.w700,
//                                 color: Color(0xFF202124),
//                               ),
//                             ),
//
//                             const SizedBox(height: 5),
//
//                             Text(
//                               "${record.employeeCode}  •  ${record.appraisee}",
//                               style: const TextStyle(
//                                 fontSize: 13,
//                                 color: Color(0xFF747B86),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 14,
//                           vertical: 9,
//                         ),
//
//                         decoration: BoxDecoration(
//                           color: resultBackground,
//                           borderRadius:
//                           BorderRadius.circular(10),
//                         ),
//
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(
//                               isAcceptable
//                                   ? Icons.check_circle_outline
//                                   : isMarginal
//                                   ? Icons
//                                   .remove_circle_outline
//                                   : Icons.cancel_outlined,
//                               size: 18,
//                               color: resultColor,
//                             ),
//
//                             const SizedBox(width: 7),
//
//                             Text(
//                               record.result,
//                               style: TextStyle(
//                                 fontSize: 12.5,
//                                 fontWeight: FontWeight.w700,
//                                 color: resultColor,
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
//                 // CANDIDATE + EVALUATION
//                 Row(
//                   crossAxisAlignment:
//                   CrossAxisAlignment.start,
//
//                   children: [
//
//                     // CANDIDATE INFORMATION
//                     Expanded(
//                       flex: 6,
//
//                       child: Container(
//                         padding: const EdgeInsets.all(22),
//
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius:
//                           BorderRadius.circular(18),
//                           border: Border.all(
//                             color: const Color(0xFFE1E4E8),
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withValues(
//                                 alpha: 0.025,
//                               ),
//                               blurRadius: 14,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//
//                         child: Column(
//                           crossAxisAlignment:
//                           CrossAxisAlignment.start,
//
//                           children: [
//
//                             const Row(
//                               children: [
//                                 Icon(
//                                   Icons.person_outline_rounded,
//                                   size: 20,
//                                   color: Color(0xFF3155C6),
//                                 ),
//                                 SizedBox(width: 9),
//                                 Text(
//                                   "Candidate Information",
//                                   style: TextStyle(
//                                     fontSize: 17,
//                                     fontWeight: FontWeight.w700,
//                                     color: Color(0xFF202124),
//                                   ),
//                                 ),
//                               ],
//                             ),
//
//                             const SizedBox(height: 20),
//
//                             Row(
//                               crossAxisAlignment:
//                               CrossAxisAlignment.start,
//
//                               children: [
//
//                                 Container(
//                                   width: 120,
//                                   height: 120,
//
//                                   decoration: BoxDecoration(
//                                     color: const Color(0xFFF3F5F8),
//                                     borderRadius:
//                                     BorderRadius.circular(14),
//                                     border: Border.all(
//                                       color:
//                                       const Color(0xFFE1E4E8),
//                                     ),
//                                   ),
//
//                                   clipBehavior: Clip.antiAlias,
//
//                                   child: hasPhoto
//                                       ? Image.network(
//                                     record.candidatePhotoPath,
//                                     fit: BoxFit.cover,
//                                     errorBuilder: (context, error, stackTrace) {
//                                       return const Icon(
//                                         Icons.person_outline_rounded,
//                                         size: 52,
//                                         color: Color(0xFF9AA1AA),
//                                       );
//                                     },
//                                   )
//                                       : const Icon(
//                                     Icons.person_outline_rounded,
//                                     size: 52,
//                                     color: Color(0xFF9AA1AA),
//                                   ),
//                                 ),
//
//                                 const SizedBox(width: 22),
//
//                                 Expanded(
//                                   child: Column(
//                                     children: [
//
//                                       info(
//                                         "Employee Code",
//                                         record.employeeCode,
//                                       ),
//
//                                       info(
//                                         "Candidate",
//                                         record.appraisee,
//                                       ),
//
//                                       info(
//                                         "Department",
//                                         record.department,
//                                       ),
//
//                                       info(
//                                         "Product",
//                                         record.product,
//                                       ),
//
//                                       info(
//                                         "Batch",
//                                         record.batchName,
//                                       ),
//
//                                       info(
//                                         "Certificate",
//                                         record.certificateNo,
//                                       ),
//
//                                       info(
//                                         "Date",
//                                         record.date,
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(width: 20),
//
//                     // EVALUATION
//                     Expanded(
//                       flex: 4,
//
//                       child: Container(
//                         padding: const EdgeInsets.all(22),
//
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius:
//                           BorderRadius.circular(18),
//                           border: Border.all(
//                             color: const Color(0xFFE1E4E8),
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withValues(
//                                 alpha: 0.025,
//                               ),
//                               blurRadius: 14,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//
//                         child: Column(
//                           crossAxisAlignment:
//                           CrossAxisAlignment.start,
//
//                           children: [
//
//                             const Row(
//                               children: [
//                                 Icon(
//                                   Icons.analytics_outlined,
//                                   size: 20,
//                                   color: Color(0xFF3155C6),
//                                 ),
//                                 SizedBox(width: 9),
//                                 Text(
//                                   "Evaluation Metrics",
//                                   style: TextStyle(
//                                     fontSize: 17,
//                                     fontWeight: FontWeight.w700,
//                                     color: Color(0xFF202124),
//                                   ),
//                                 ),
//                               ],
//                             ),
//
//                             const SizedBox(height: 8),
//
//                             const Text(
//                               "Performance indicators from the completed inspection.",
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Color(0xFF747B86),
//                               ),
//                             ),
//
//                             const SizedBox(height: 16),
//
//                             metric(
//                               "False Alert %",
//                               record.falseAlertPercent,
//                             ),
//
//                             const Divider(
//                               height: 1,
//                             ),
//
//                             metric(
//                               "Miss Rate %",
//                               record.missRate,
//                             ),
//
//                             const Divider(
//                               height: 1,
//                             ),
//
//                             metric(
//                               "Effectiveness %",
//                               record.effectiveness,
//                             ),
//
//                             const Divider(
//                               height: 1,
//                             ),
//
//                             metric(
//                               "Kappa %",
//                               record.kappa,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 // REPORT ACTIONS
//                 Container(
//                   width: double.infinity,
//
//                   padding: const EdgeInsets.all(22),
//
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(18),
//                     border: Border.all(
//                       color: const Color(0xFFE1E4E8),
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
//                   child: Column(
//                     crossAxisAlignment:
//                     CrossAxisAlignment.start,
//
//                     children: [
//
//                       const Row(
//                         children: [
//                           Icon(
//                             Icons.description_outlined,
//                             size: 20,
//                             color: Color(0xFF3155C6),
//                           ),
//                           SizedBox(width: 9),
//                           Text(
//                             "Observation Report",
//                             style: TextStyle(
//                               fontSize: 17,
//                               fontWeight: FontWeight.w700,
//                               color: Color(0xFF202124),
//                             ),
//                           ),
//                         ],
//                       ),
//
//                       const SizedBox(height: 5),
//
//                       const Text(
//                         "Download, print or share the inspection report.",
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Color(0xFF747B86),
//                         ),
//                       ),
//
//                       const SizedBox(height: 18),
//
//                       Row(
//                         children: [
//
//                           Expanded(
//                             child: OutlinedButton.icon(
//                               icon: const Icon(
//                                 Icons.download_outlined,
//                               ),
//
//                               label: const Text(
//                                 "Download Report",
//                               ),
//
//                               onPressed: () async {
//
//                                 await PdfService.downloadReport(
//                                   context: context,
//                                   record: _recordToMap(),
//                                   observations: _observations(),
//                                 );
//
//                               },
//
//                               style:
//                               OutlinedButton.styleFrom(
//                                 foregroundColor:
//                                 const Color(0xFF3155C6),
//
//                                 side: const BorderSide(
//                                   color:
//                                   Color(0xFFD5DCF1),
//                                 ),
//
//                                 backgroundColor:
//                                 const Color(0xFFF8FAFF),
//
//                                 padding:
//                                 const EdgeInsets.symmetric(
//                                   vertical: 14,
//                                 ),
//
//                                 shape:
//                                 RoundedRectangleBorder(
//                                   borderRadius:
//                                   BorderRadius.circular(
//                                     10,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//
//                           const SizedBox(width: 12),
//
//                           Expanded(
//                             child: OutlinedButton.icon(
//                               icon: const Icon(
//                                 Icons.print_outlined,
//                               ),
//
//                               label: const Text(
//                                 "Print Report",
//                               ),
//
//                               onPressed: () async {
//
//                                 await PdfService.printReport(
//                                   record: _recordToMap(),
//                                   observations: _observations(),
//                                 );
//
//                               },
//
//                               style:
//                               OutlinedButton.styleFrom(
//                                 foregroundColor:
//                                 const Color(0xFF3155C6),
//
//                                 side: const BorderSide(
//                                   color:
//                                   Color(0xFFD5DCF1),
//                                 ),
//
//                                 padding:
//                                 const EdgeInsets.symmetric(
//                                   vertical: 14,
//                                 ),
//
//                                 shape:
//                                 RoundedRectangleBorder(
//                                   borderRadius:
//                                   BorderRadius.circular(
//                                     10,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//
//                           const SizedBox(width: 12),
//
//                           Expanded(
//                             child: OutlinedButton.icon(
//                               icon: const Icon(
//                                 Icons.share_outlined,
//                               ),
//
//                               label: const Text(
//                                 "Share Report",
//                               ),
//
//                               onPressed: () async {
//
//                                 await PdfService.shareReport(
//                                   record: _recordToMap(),
//                                   observations: _observations(),
//                                 );
//
//                               },
//
//                               style:
//                               OutlinedButton.styleFrom(
//                                 foregroundColor:
//                                 const Color(0xFF3155C6),
//
//                                 side: const BorderSide(
//                                   color:
//                                   Color(0xFFD5DCF1),
//                                 ),
//
//                                 padding:
//                                 const EdgeInsets.symmetric(
//                                   vertical: 14,
//                                 ),
//
//                                 shape:
//                                 RoundedRectangleBorder(
//                                   borderRadius:
//                                   BorderRadius.circular(
//                                     10,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 // CERTIFICATE ACTIONS
//                 Container(
//                   width: double.infinity,
//
//                   padding: const EdgeInsets.all(22),
//
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(18),
//                     border: Border.all(
//                       color: const Color(0xFFE1E4E8),
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
//                   child: Column(
//                     crossAxisAlignment:
//                     CrossAxisAlignment.start,
//
//                     children: [
//
//                       const Row(
//                         children: [
//                           Icon(
//                             Icons.workspace_premium_outlined,
//                             size: 20,
//                             color: Color(0xFF3155C6),
//                           ),
//                           SizedBox(width: 9),
//                           Text(
//                             "Certificate",
//                             style: TextStyle(
//                               fontSize: 17,
//                               fontWeight: FontWeight.w700,
//                               color: Color(0xFF202124),
//                             ),
//                           ),
//                         ],
//                       ),
//
//                       const SizedBox(height: 5),
//
//                       const Text(
//                         "Generate or distribute the candidate certificate.",
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Color(0xFF747B86),
//                         ),
//                       ),
//
//                       const SizedBox(height: 18),
//
//                       Row(
//                         children: [
//
//                           Expanded(
//                             child: ElevatedButton.icon(
//                               icon: const Icon(
//                                 Icons.download_outlined,
//                               ),
//
//                               label: const Text(
//                                 "Download Certificate",
//                               ),
//
//                               onPressed: () async {
//                                 await PdfService
//                                     .downloadCertificate(
//                                   context: context,
//                                   record: record,
//                                 );
//                               },
//
//                               style:
//                               ElevatedButton.styleFrom(
//                                 backgroundColor:
//                                 const Color(0xFF3155C6),
//
//                                 foregroundColor:
//                                 Colors.white,
//
//                                 elevation: 1,
//
//                                 padding:
//                                 const EdgeInsets.symmetric(
//                                   vertical: 14,
//                                 ),
//
//                                 shape:
//                                 RoundedRectangleBorder(
//                                   borderRadius:
//                                   BorderRadius.circular(
//                                     10,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//
//                           const SizedBox(width: 12),
//
//                           Expanded(
//                             child: OutlinedButton.icon(
//                               icon: const Icon(
//                                 Icons.print_outlined,
//                               ),
//
//                               label: const Text(
//                                 "Print Certificate",
//                               ),
//
//                               onPressed: () async {
//                                 await PdfService
//                                     .printCertificate(
//                                   record: record,
//                                 );
//                               },
//
//                               style:
//                               OutlinedButton.styleFrom(
//                                 foregroundColor:
//                                 const Color(0xFF3155C6),
//
//                                 side: const BorderSide(
//                                   color:
//                                   Color(0xFFD5DCF1),
//                                 ),
//
//                                 padding:
//                                 const EdgeInsets.symmetric(
//                                   vertical: 14,
//                                 ),
//
//                                 shape:
//                                 RoundedRectangleBorder(
//                                   borderRadius:
//                                   BorderRadius.circular(
//                                     10,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//
//                           const SizedBox(width: 12),
//
//                           Expanded(
//                             child: OutlinedButton.icon(
//                               icon: const Icon(
//                                 Icons.share_outlined,
//                               ),
//
//                               label: const Text(
//                                 "Share Certificate",
//                               ),
//
//                               onPressed: () async {
//                                 await PdfService
//                                     .shareCertificate(
//                                   record: record,
//                                 );
//                               },
//
//                               style:
//                               OutlinedButton.styleFrom(
//                                 foregroundColor:
//                                 const Color(0xFF3155C6),
//
//                                 side: const BorderSide(
//                                   color:
//                                   Color(0xFFD5DCF1),
//                                 ),
//
//                                 padding:
//                                 const EdgeInsets.symmetric(
//                                   vertical: 14,
//                                 ),
//
//                                 shape:
//                                 RoundedRectangleBorder(
//                                   borderRadius:
//                                   BorderRadius.circular(
//                                     10,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
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
// }
import 'package:flutter/material.dart';

import '../models/arr_record.dart';
import '../services/pdf_service.dart';
import '../services/supabase_service.dart';

class PreviousArrDetailScreen extends StatefulWidget {
  final String arrId;

  const PreviousArrDetailScreen({
    super.key,
    required this.arrId,
  });

  @override
  State<PreviousArrDetailScreen> createState() =>
      _PreviousArrDetailScreenState();
}

class _PreviousArrDetailScreenState
    extends State<PreviousArrDetailScreen> {

  ArrRecord? record;

  bool isLoading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  // ============================================================
  // LOAD ONLY THE SELECTED ARR
  // ============================================================

  Future<void> _loadRecord() async {
    try {
      setState(() {
        isLoading = true;
        loadError = null;
      });

      final data =
      await SupabaseService.getCompleteArr(
        widget.arrId,
      );

      if (!mounted) return;

      final recordData =
      data['record'] as Map<String, dynamic>;

      final observations =
      List<Map<String, dynamic>>.from(
        data['observations'] ?? [],
      );

      final employee =
      data['employee'] as Map<String, dynamic>?;

      final loadedRecord =
      _buildArrRecord(
        recordData,
        observations,
        employee,
      );

      setState(() {
        record = loadedRecord;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        loadError = e.toString();
      });
    }
  }

  // ============================================================
  // CONVERT SUPABASE DATA → ArrRecord
  // ============================================================

  ArrRecord _buildArrRecord(
      Map<String, dynamic> data,
      List<Map<String, dynamic>> observations,
      Map<String, dynamic>? employee,
      ) {

    final partNumbers = <String>[];
    final masterAnswers = <int>[];
    final trail1Answers = <int>[];
    final trail2Answers = <int>[];
    final trail3Answers = <int>[];

    for (final observation in observations) {
      partNumbers.add(
        observation['part_number_snap']
            ?.toString() ??
            '',
      );

      masterAnswers.add(
        _toInt(
          observation[
          'master_status_snapshot'],
        ),
      );

      trail1Answers.add(
        _toInt(
          observation['trail1'],
        ),
      );

      trail2Answers.add(
        _toInt(
          observation['trail2'],
        ),
      );

      trail3Answers.add(
        _toInt(
          observation['trail3'],
        ),
      );
    }

    return ArrRecord(
      employeeCode:
      data['employee_code_snap']
          ?.toString() ??
          '',

      appraisee:
      employee?['employee_name']
          ?.toString() ??
          employee?['name']
              ?.toString() ??
          '',

      department:
      employee?['department']
          ?.toString() ??
          '',

      product:
      data['product']?.toString() ??
          '',

      batchName:
      data['batch_name_snap']
          ?.toString() ??
          '',

      result:
      data['classification']
          ?.toString() ??
          '',

      certificateNo:
      data['certificate_number']
          ?.toString() ??
          '',

      date:
      data['assessment_date']
          ?.toString() ??
          '',

      falseAlertPercent:
      _toDouble(
        data['false_alert_pct'],
      ),

      missRate:
      _toDouble(
        data['miss_rate_pct'],
      ),

      effectiveness:
      _toDouble(
        data['effectiveness_pct'],
      ),

      kappa:
      _toDouble(
        data['kappa_pct'],
      ),

      trail1Answers:
      trail1Answers,

      trail2Answers:
      trail2Answers,

      trail3Answers:
      trail3Answers,

      candidatePhotoPath:
      employee?['photo_url']
          ?.toString() ??
          employee?['candidate_photo_path']
              ?.toString() ??
          '',

      batchId:
      data['batch_id']
          ?.toString() ??
          '',

      partNumbers:
      partNumbers,

      masterAnswers:
      masterAnswers,
    );
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();

    return double.tryParse(
      value?.toString() ?? '',
    ) ??
        0.0;
  }

  // ============================================================
  // RECORD → MAP FOR PDF
  // ============================================================

  Map<String, dynamic> _recordToMap() {
    final r = record!;

    return {
      "employee_code": r.employeeCode,
      "appraisee": r.appraisee,
      "department": r.department,
      "product": r.product,
      "batch_name": r.batchName,
      "result": r.result,
      "certificate_no": r.certificateNo,
      "date": r.date,
      "false_alert_percent": r.falseAlertPercent,
      "miss_rate": r.missRate,
      "effectiveness": r.effectiveness,
      "kappa": r.kappa,
      "part_numbers": r.partNumbers,
      "master_answers": r.masterAnswers,
      "trail1_answers": r.trail1Answers,
      "trail2_answers": r.trail2Answers,
      "trail3_answers": r.trail3Answers,
      "batch_id": r.batchId,
    };
  }

  List<Map<String, dynamic>> _observations() {
    final r = record!;

    final total = r.partNumbers.length;

    return List.generate(
      total,
          (index) {
        return {
          "part_number_snap":
          r.partNumbers[index],

          "master_status_snapshot":
          r.masterAnswers[index],

          "trail1":
          r.trail1Answers[index],

          "trail2":
          r.trail2Answers[index],

          "trail3":
          r.trail3Answers[index],
        };
      },
    );
  }

  // ============================================================
  // SMALL UI HELPERS
  // ============================================================

  Widget info(
      String title,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget metric(
      String name,
      double value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(name),
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING SCREEN
  // ============================================================

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF3155C6),
            ),
          ),

          SizedBox(height: 18),

          Text(
            "Loading ARR Details",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF202124),
            ),
          ),

          SizedBox(height: 6),

          Text(
            "Fetching the selected inspection record...",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF747B86),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR SCREEN
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Color(0xFFC13F3F),
            ),

            const SizedBox(height: 16),

            const Text(
              "Unable to Load ARR",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202124),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              loadError ?? "Unknown error",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF747B86),
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: _loadRecord,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFF3155C6),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MAIN SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return Scaffold(
        backgroundColor:
        const Color(0xFFF6F7F9),

        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,

          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF202124),
            ),
            onPressed: () =>
                Navigator.pop(context),
          ),

          title: const Text(
            "Previous ARR Details",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF202124),
            ),
          ),
        ),

        body: _buildLoadingState(),
      );
    }

    if (loadError != null ||
        record == null) {
      return Scaffold(
        backgroundColor:
        const Color(0xFFF6F7F9),

        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,

          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF202124),
            ),
            onPressed: () =>
                Navigator.pop(context),
          ),

          title: const Text(
            "Previous ARR Details",
          ),
        ),

        body: _buildErrorState(),
      );
    }

    final r = record!;

    final bool hasPhoto =
        r.candidatePhotoPath.isNotEmpty &&
            (r.candidatePhotoPath.startsWith(
              "http://",
            ) ||
                r.candidatePhotoPath.startsWith(
                  "https://",
                ));

    final bool isAcceptable =
        r.result == "ACCEPTABLE";

    final bool isMarginal =
        r.result ==
            "MARGINALLY ACCEPTABLE";

    final Color resultColor =
    isAcceptable
        ? const Color(0xFF249653)
        : isMarginal
        ? const Color(0xFFD88A24)
        : const Color(0xFFD94A4A);

    final Color resultBackground =
    isAcceptable
        ? const Color(0xFFEAF7EF)
        : isMarginal
        ? const Color(0xFFFFF4E5)
        : const Color(0xFFFDECEC);

    return Scaffold(
      backgroundColor:
      const Color(0xFFF6F7F9),

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor:
        Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF202124),
          ),
          onPressed: () =>
              Navigator.pop(context),
        ),

        title: const Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Previous ARR Details",
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.w700,
                color: Color(0xFF202124),
              ),
            ),
            Text(
              "Inspection record and report actions",
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF777D86),
              ),
            ),
          ],
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 1150,
          ),

          child: SingleChildScrollView(
            padding:
            const EdgeInsets.fromLTRB(
              28,
              26,
              28,
              40,
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                // ==================================================
                // HEADER
                // ==================================================

                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.all(22),

                  decoration:
                  BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(
                      18,
                    ),
                    border: Border.all(
                      color: const Color(
                        0xFFE1E4E8,
                      ),
                    ),
                  ),

                  child: Row(
                    children: [

                      Container(
                        width: 54,
                        height: 54,

                        decoration:
                        BoxDecoration(
                          color: const Color(
                            0xFFEAF0FF,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            14,
                          ),
                        ),

                        child: const Icon(
                          Icons
                              .assignment_turned_in_outlined,
                          color:
                          Color(0xFF3155C6),
                          size: 28,
                        ),
                      ),

                      const SizedBox(
                        width: 16,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                          children: [

                            const Text(
                              "ARR Inspection Record",
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight:
                                FontWeight.w700,
                                color:
                                Color(0xFF202124),
                              ),
                            ),

                            const SizedBox(
                              height: 5,
                            ),

                            Text(
                              "${r.employeeCode}  •  ${r.appraisee}",
                              style:
                              const TextStyle(
                                fontSize: 13,
                                color:
                                Color(0xFF747B86),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),

                        decoration:
                        BoxDecoration(
                          color:
                          resultBackground,
                          borderRadius:
                          BorderRadius.circular(
                            10,
                          ),
                        ),

                        child: Row(
                          mainAxisSize:
                          MainAxisSize.min,

                          children: [

                            Icon(
                              isAcceptable
                                  ? Icons
                                  .check_circle_outline
                                  : isMarginal
                                  ? Icons
                                  .remove_circle_outline
                                  : Icons
                                  .cancel_outlined,
                              size: 18,
                              color:
                              resultColor,
                            ),

                            const SizedBox(
                              width: 7,
                            ),

                            Text(
                              r.result,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight:
                                FontWeight.w700,
                                color:
                                resultColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // CANDIDATE + EVALUATION
                // ==================================================

                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    Expanded(
                      flex: 6,

                      child: Container(
                        padding:
                        const EdgeInsets.all(
                          22,
                        ),

                        decoration:
                        BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                          BorderRadius.circular(
                            18,
                          ),
                          border: Border.all(
                            color: const Color(
                              0xFFE1E4E8,
                            ),
                          ),
                        ),

                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                          children: [

                            const Row(
                              children: [
                                Icon(
                                  Icons
                                      .person_outline_rounded,
                                  size: 20,
                                  color:
                                  Color(0xFF3155C6),
                                ),
                                SizedBox(
                                  width: 9,
                                ),
                                Text(
                                  "Candidate Information",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                    FontWeight.w700,
                                    color:
                                    Color(0xFF202124),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            Row(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                              children: [

                                Container(
                                  width: 120,
                                  height: 120,

                                  decoration:
                                  BoxDecoration(
                                    color:
                                    const Color(
                                      0xFFF3F5F8,
                                    ),
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                      14,
                                    ),
                                  ),

                                  clipBehavior:
                                  Clip.antiAlias,

                                  child: hasPhoto
                                      ? Image.network(
                                    r.candidatePhotoPath,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (
                                        context,
                                        error,
                                        stackTrace,
                                        ) {
                                      return const Icon(
                                        Icons
                                            .person_outline_rounded,
                                        size: 52,
                                        color:
                                        Color(0xFF9AA1AA),
                                      );
                                    },
                                  )
                                      : const Icon(
                                    Icons
                                        .person_outline_rounded,
                                    size: 52,
                                    color:
                                    Color(0xFF9AA1AA),
                                  ),
                                ),

                                const SizedBox(
                                  width: 22,
                                ),

                                Expanded(
                                  child: Column(
                                    children: [

                                      info(
                                        "Employee Code",
                                        r.employeeCode,
                                      ),

                                      info(
                                        "Candidate",
                                        r.appraisee,
                                      ),

                                      info(
                                        "Department",
                                        r.department,
                                      ),

                                      info(
                                        "Product",
                                        r.product,
                                      ),

                                      info(
                                        "Batch",
                                        r.batchName,
                                      ),

                                      info(
                                        "Certificate",
                                        r.certificateNo,
                                      ),

                                      info(
                                        "Date",
                                        r.date,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 20,
                    ),

                    Expanded(
                      flex: 4,

                      child: Container(
                        padding:
                        const EdgeInsets.all(
                          22,
                        ),

                        decoration:
                        BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                          BorderRadius.circular(
                            18,
                          ),
                          border: Border.all(
                            color: const Color(
                              0xFFE1E4E8,
                            ),
                          ),
                        ),

                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                          children: [

                            const Row(
                              children: [
                                Icon(
                                  Icons
                                      .analytics_outlined,
                                  size: 20,
                                  color:
                                  Color(0xFF3155C6),
                                ),
                                SizedBox(
                                  width: 9,
                                ),
                                Text(
                                  "Evaluation Metrics",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                    FontWeight.w700,
                                    color:
                                    Color(0xFF202124),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            const Text(
                              "Performance indicators from the completed inspection.",
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                Color(0xFF747B86),
                              ),
                            ),

                            const SizedBox(
                              height: 16,
                            ),

                            metric(
                              "False Alert %",
                              r.falseAlertPercent,
                            ),

                            const Divider(
                              height: 1,
                            ),

                            metric(
                              "Miss Rate %",
                              r.missRate,
                            ),

                            const Divider(
                              height: 1,
                            ),

                            metric(
                              "Effectiveness %",
                              r.effectiveness,
                            ),

                            const Divider(
                              height: 1,
                            ),

                            metric(
                              "Kappa %",
                              r.kappa,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // REPORT ACTIONS
                // ==================================================

                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.all(22),

                  decoration:
                  BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(
                        0xFFE1E4E8,
                      ),
                    ),
                  ),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      const Row(
                        children: [
                          Icon(
                            Icons
                                .description_outlined,
                            size: 20,
                            color:
                            Color(0xFF3155C6),
                          ),
                          SizedBox(
                            width: 9,
                          ),
                          Text(
                            "Observation Report",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                              FontWeight.w700,
                              color:
                              Color(0xFF202124),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      const Text(
                        "Download, print or share the inspection report.",
                        style: TextStyle(
                          fontSize: 12,
                          color:
                          Color(0xFF747B86),
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      Row(
                        children: [

                          Expanded(
                            child:
                            OutlinedButton.icon(
                              icon: const Icon(
                                Icons
                                    .download_outlined,
                              ),

                              label: const Text(
                                "Download Report",
                              ),

                              onPressed: () async {
                                await PdfService
                                    .downloadReport(
                                  context:
                                  context,
                                  record:
                                  _recordToMap(),
                                  observations:
                                  _observations(),
                                );
                              },
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child:
                            OutlinedButton.icon(
                              icon: const Icon(
                                Icons.print_outlined,
                              ),

                              label: const Text(
                                "Print Report",
                              ),

                              onPressed: () async {
                                await PdfService
                                    .printReport(
                                  record:
                                  _recordToMap(),
                                  observations:
                                  _observations(),
                                );
                              },
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child:
                            OutlinedButton.icon(
                              icon: const Icon(
                                Icons.share_outlined,
                              ),

                              label: const Text(
                                "Share Report",
                              ),

                              onPressed: () async {
                                await PdfService
                                    .shareReport(
                                  record:
                                  _recordToMap(),
                                  observations:
                                  _observations(),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // CERTIFICATE ACTIONS
                // ==================================================

                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.all(22),

                  decoration:
                  BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(
                        0xFFE1E4E8,
                      ),
                    ),
                  ),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      const Row(
                        children: [
                          Icon(
                            Icons
                                .workspace_premium_outlined,
                            size: 20,
                            color:
                            Color(0xFF3155C6),
                          ),
                          SizedBox(
                            width: 9,
                          ),
                          Text(
                            "Certificate",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                              FontWeight.w700,
                              color:
                              Color(0xFF202124),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      const Text(
                        "Generate or distribute the candidate certificate.",
                        style: TextStyle(
                          fontSize: 12,
                          color:
                          Color(0xFF747B86),
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      Row(
                        children: [

                          Expanded(
                            child:
                            ElevatedButton.icon(
                              icon: const Icon(
                                Icons
                                    .download_outlined,
                              ),

                              label: const Text(
                                "Download Certificate",
                              ),

                              onPressed: () async {
                                await PdfService
                                    .downloadCertificate(
                                  context:
                                  context,
                                  record: r,
                                );
                              },
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child:
                            OutlinedButton.icon(
                              icon: const Icon(
                                Icons.print_outlined,
                              ),

                              label: const Text(
                                "Print Certificate",
                              ),

                              onPressed: () async {
                                await PdfService
                                    .printCertificate(
                                  record: r,
                                );
                              },
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child:
                            OutlinedButton.icon(
                              icon: const Icon(
                                Icons.share_outlined,
                              ),

                              label: const Text(
                                "Share Certificate",
                              ),

                              onPressed: () async {
                                await PdfService
                                    .shareCertificate(
                                  record: r,
                                );
                              },
                            ),
                          ),
                        ],
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
}