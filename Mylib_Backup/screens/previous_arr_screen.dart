// import 'package:flutter/material.dart';
// import '../services/app_data.dart';
// import 'previous_arr_detail_screen.dart';
// import 'cross_tab_selection_screen.dart';
// import '../models/arr_record.dart';
// import '../services/supabase_service.dart';
//
// class PreviousArrScreen extends StatefulWidget {
//   const PreviousArrScreen({super.key});
//
//   @override
//   State<PreviousArrScreen> createState() =>
//       _PreviousArrScreenState();
// }
//
// class _PreviousArrScreenState
//     extends State<PreviousArrScreen> {
//
//   final TextEditingController searchController =
//   TextEditingController();
//
//   String search = "";
//   String filter = "All";
//   DateTimeRange? customRange;
//
//   bool isLoading = true;
//   String? loadError;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _loadPreviousArrs();
//   }
//
//   @override
//   void dispose() {
//     searchController.dispose();
//
//     super.dispose();
//   }
//
//   Future<void> _loadPreviousArrs() async {
//     try {
//       setState(() {
//         isLoading = true;
//         loadError = null;
//       });
//
//       final rows =
//       await SupabaseService.getPreviousArrs();
//
//       final records = <ArrRecord>[];
//
//       for (final row in rows) {
//         final arrId =
//             row['arr_id']?.toString() ?? '';
//
//         final employeeId =
//             row['employee_id']?.toString() ?? '';
//
//         final employee =
//         employeeId.isEmpty
//             ? null
//             : await SupabaseService
//             .getEmployeeForArr(employeeId);
//
//         final observations =
//         await SupabaseService
//             .getArrObservations(arrId);
//
//         observations.sort((a, b) {
//           final aPart =
//               a['part_number_snap']
//                   ?.toString() ??
//                   '';
//
//           final bPart =
//               b['part_number_snap']
//                   ?.toString() ??
//                   '';
//
//           return aPart.compareTo(bPart);
//         });
//
//         records.add(
//           ArrRecord(
//             employeeCode:
//             row['employee_code_snap']
//                 ?.toString() ??
//                 employee?['employee_code']
//                     ?.toString() ??
//                 '',
//
//             appraisee:
//             employee?['full_name']
//                 ?.toString() ??
//                 '',
//
//             department:
//             employee?['department']
//                 ?.toString() ??
//                 '',
//
//             product:
//             row['product']
//                 ?.toString() ??
//                 employee?['product']
//                     ?.toString() ??
//                 '',
//
//             batchName:
//             row['batch_name_snap']
//                 ?.toString() ??
//                 '',
//
//             result:
//             row['classification']
//                 ?.toString() ??
//                 '',
//
//             certificateNo:
//             row['certificate_number']
//                 ?.toString() ??
//                 '',
//
//             date: _formatDate(
//               row['assessment_date']
//                   ?.toString() ??
//                   '',
//             ),
//
//             falseAlertPercent:
//             _toDouble(
//               row['false_alert_pct'],
//             ),
//
//             missRate:
//             _toDouble(
//               row['miss_rate_pct'],
//             ),
//
//             effectiveness:
//             _toDouble(
//               row['effectiveness_pct'],
//             ),
//
//             kappa:
//             _toDouble(
//               row['kappa_pct'],
//             ),
//
//             trail1Answers:
//             observations
//                 .map(
//                   (e) => _toInt(
//                 e['trail1'],
//               ),
//             )
//                 .toList(),
//
//             trail2Answers:
//             observations
//                 .map(
//                   (e) => _toInt(
//                 e['trail2'],
//               ),
//             )
//                 .toList(),
//
//             trail3Answers:
//             observations
//                 .map(
//                   (e) => _toInt(
//                 e['trail3'],
//               ),
//             )
//                 .toList(),
//
//             partNumbers:
//             observations
//                 .map(
//                   (e) =>
//               e['part_number_snap']
//                   ?.toString() ??
//                   '',
//             )
//                 .toList(),
//
//             masterAnswers:
//             observations
//                 .map(
//                   (e) => _toInt(
//                 e['master_status_snapshot'],
//               ),
//             )
//                 .toList(),
//
//             batchId:
//             row['batch_id']
//                 ?.toString() ??
//                 '',
//
//             candidatePhotoPath:
//             employee?['photo_path']
//                 ?.toString() ??
//                 '',
//           ),
//         );
//       }
//
//       if (!mounted) {
//         return;
//       }
//
//       setState(() {
//         AppData.previousArrs = records;
//         isLoading = false;
//       });
//     } catch (e) {
//       if (!mounted) {
//         return;
//       }
//
//       setState(() {
//         isLoading = false;
//         loadError = e.toString();
//       });
//     }
//   }
//
//   double _toDouble(dynamic value) {
//     if (value is num) {
//       return value.toDouble();
//     }
//
//     return double.tryParse(
//       value?.toString() ?? '',
//     ) ??
//         0.0;
//   }
//
//   int _toInt(dynamic value) {
//     if (value is num) {
//       return value.toInt();
//     }
//
//     return int.tryParse(
//       value?.toString() ?? '',
//     ) ??
//         0;
//   }
//
//   String _formatDate(String value) {
//     if (value.isEmpty) {
//       return '';
//     }
//
//     final date = DateTime.tryParse(value);
//
//     if (date == null) {
//       return value;
//     }
//
//     return '${date.day.toString().padLeft(2, '0')}/'
//         '${date.month.toString().padLeft(2, '0')}/'
//         '${date.year}';
//   }
//
//   Widget _filterOption({
//     required IconData icon,
//     required String title,
//     required bool selected,
//     required VoidCallback onTap,
//   }) {
//     return ListTile(
//       contentPadding:
//       const EdgeInsets.symmetric(horizontal: 4),
//
//       leading: Container(
//         width: 38,
//         height: 38,
//         decoration: BoxDecoration(
//           color: selected
//               ? const Color(0xFFEAF0FF)
//               : const Color(0xFFF5F6F8),
//           borderRadius:
//           BorderRadius.circular(10),
//         ),
//         child: Icon(
//           icon,
//           size: 20,
//           color: selected
//               ? const Color(0xFF3155C6)
//               : const Color(0xFF62666D),
//         ),
//       ),
//
//       title: Text(
//         title,
//         style: TextStyle(
//           fontSize: 14,
//           fontWeight:
//           selected
//               ? FontWeight.w700
//               : FontWeight.w500,
//           color:
//           const Color(0xFF202124),
//         ),
//       ),
//
//       trailing: selected
//           ? const Icon(
//         Icons.check_rounded,
//         color: Color(0xFF3155C6),
//       )
//           : null,
//
//       onTap: onTap,
//     );
//   }
//
//   Widget _summaryBadge(String label,
//       int value,
//       Color color,) {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 13,
//         vertical: 9,
//       ),
//
//       decoration: BoxDecoration(
//         color: color.withValues(alpha: 0.07),
//         borderRadius:
//         BorderRadius.circular(10),
//         border: Border.all(
//           color: color.withValues(alpha: 0.15),
//         ),
//       ),
//
//       child: Column(
//         children: [
//           Text(
//             value.toString(),
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w800,
//               color: color,
//             ),
//           ),
//
//           const SizedBox(height: 2),
//
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 9.5,
//               fontWeight: FontWeight.w600,
//               color: Color(0xFF747982),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _recordCard(BuildContext context,
//       dynamic record,) {
//     final result = record.result;
//
//     final bool acceptable =
//         result == "ACCEPTABLE";
//
//     final bool marginal =
//         result == "MARGINALLY ACCEPTABLE";
//
//     final Color statusColor =
//     acceptable
//         ? const Color(0xFF249653)
//         : marginal
//         ? const Color(0xFFD88A24)
//         : const Color(0xFFD94A4A);
//
//     final Color statusBackground =
//     acceptable
//         ? const Color(0xFFEAF7EF)
//         : marginal
//         ? const Color(0xFFFFF4E5)
//         : const Color(0xFFFCEBEC);
//
//     return Container(
//       margin: const EdgeInsets.only(
//         bottom: 12,
//       ),
//
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//         BorderRadius.circular(16),
//
//         border: Border.all(
//           color: const Color(0xFFE1E4E8),
//         ),
//
//         boxShadow: [
//           BoxShadow(
//             color:
//             Colors.black.withValues(
//               alpha: 0.025,
//             ),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//
//       child: Padding(
//         padding: const EdgeInsets.all(18),
//
//         child: Row(
//           children: [
//
//             Container(
//               width: 48,
//               height: 48,
//
//               decoration: BoxDecoration(
//                 color:
//                 const Color(0xFFEAF0FF),
//                 borderRadius:
//                 BorderRadius.circular(13),
//               ),
//
//               child: const Icon(
//                 Icons.person_outline_rounded,
//                 color: Color(0xFF3155C6),
//                 size: 25,
//               ),
//             ),
//
//             const SizedBox(width: 15),
//
//             Expanded(
//               flex: 3,
//               child: Column(
//                 crossAxisAlignment:
//                 CrossAxisAlignment.start,
//                 children: [
//
//                   Text(
//                     record.appraisee
//                         .toString()
//                         .trim()
//                         .isEmpty
//                         ? "Unnamed Candidate"
//                         : record.appraisee,
//                     style: const TextStyle(
//                       fontSize: 15.5,
//                       fontWeight:
//                       FontWeight.w700,
//                       color:
//                       Color(0xFF202124),
//                     ),
//                   ),
//
//                   const SizedBox(height: 6),
//
//                   Row(
//                     children: [
//
//                       const Icon(
//                         Icons.badge_outlined,
//                         size: 14,
//                         color:
//                         Color(0xFF858991),
//                       ),
//
//                       const SizedBox(width: 5),
//
//                       Text(
//                         record.employeeCode,
//                         style:
//                         const TextStyle(
//                           fontSize: 11.5,
//                           color:
//                           Color(0xFF747982),
//                         ),
//                       ),
//
//                       const SizedBox(width: 16),
//
//                       const Icon(
//                         Icons.calendar_today_outlined,
//                         size: 13,
//                         color:
//                         Color(0xFF858991),
//                       ),
//
//                       const SizedBox(width: 5),
//
//                       Text(
//                         record.date,
//                         style:
//                         const TextStyle(
//                           fontSize: 11.5,
//                           color:
//                           Color(0xFF747982),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//
//             Expanded(
//               flex: 2,
//               child: Column(
//                 crossAxisAlignment:
//                 CrossAxisAlignment.start,
//                 children: [
//
//                   const Text(
//                     "Certificate",
//                     style: TextStyle(
//                       fontSize: 10.5,
//                       color:
//                       Color(0xFF858991),
//                     ),
//                   ),
//
//                   const SizedBox(height: 4),
//
//                   Text(
//                     record.certificateNo
//                         .toString()
//                         .trim()
//                         .isEmpty
//                         ? "Not available"
//                         : record.certificateNo,
//                     style: const TextStyle(
//                       fontSize: 12.5,
//                       fontWeight:
//                       FontWeight.w600,
//                       color:
//                       Color(0xFF41454B),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             Container(
//               padding:
//               const EdgeInsets.symmetric(
//                 horizontal: 13,
//                 vertical: 8,
//               ),
//
//               decoration: BoxDecoration(
//                 color: statusBackground,
//                 borderRadius:
//                 BorderRadius.circular(9),
//               ),
//
//               child: Text(
//                 result,
//                 style: TextStyle(
//                   fontSize: 11,
//                   fontWeight:
//                   FontWeight.w700,
//                   color: statusColor,
//                 ),
//               ),
//             ),
//
//             const SizedBox(width: 14),
//
//             OutlinedButton.icon(
//               onPressed: () {
//
//                 Navigator.pushNamed(
//                   context,
//                   '/ARR/previousArrDetail',
//                   arguments: record,
//                 );
//
//               },
//
//               icon: const Icon(
//                 Icons.visibility_outlined,
//                 size: 17,
//               ),
//
//               label: const Text(
//                 "View",
//               ),
//
//               style:
//               OutlinedButton.styleFrom(
//                 foregroundColor:
//                 const Color(0xFF3155C6),
//
//                 side: const BorderSide(
//                   color: Color(0xFFD5DCF1),
//                 ),
//
//                 padding:
//                 const EdgeInsets.symmetric(
//                   horizontal: 14,
//                   vertical: 11,
//                 ),
//
//                 shape:
//                 RoundedRectangleBorder(
//                   borderRadius:
//                   BorderRadius.circular(9),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _emptyState() {
//     return Center(
//       child: Container(
//         width: 430,
//         padding: const EdgeInsets.all(32),
//
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius:
//           BorderRadius.circular(18),
//           border: Border.all(
//             color: const Color(0xFFE1E4E8),
//           ),
//         ),
//
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//
//             Container(
//               width: 64,
//               height: 64,
//
//               decoration: BoxDecoration(
//                 color:
//                 const Color(0xFFF0F2F5),
//                 borderRadius:
//                 BorderRadius.circular(18),
//               ),
//
//               child: const Icon(
//                 Icons.folder_open_outlined,
//                 size: 32,
//                 color: Color(0xFF777D86),
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             const Text(
//               "No Records Found",
//               style: TextStyle(
//                 fontSize: 17,
//                 fontWeight:
//                 FontWeight.w700,
//                 color:
//                 Color(0xFF202124),
//               ),
//             ),
//
//             const SizedBox(height: 6),
//
//             const Text(
//               "No previous ARR inspections match the current search or filter.",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 12.5,
//                 color:
//                 Color(0xFF777D86),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // @override
//   // Widget build(BuildContext context) {
//   //   Future<void> showFilterSheet() async {
//   //
//   //     showModalBottomSheet(
//   //
//   //       context: context,
//   //
//   //       shape: const RoundedRectangleBorder(
//   //
//   //         borderRadius: BorderRadius.vertical(
//   //           top: Radius.circular(20),
//   //         ),
//   //
//   //       ),
//   //
//   //       builder: (_) {
//   //
//   //         return SafeArea(
//   //
//   //           child: Column(
//   //
//   //             mainAxisSize: MainAxisSize.min,
//   //
//   //             children: [
//   //
//   //               ListTile(
//   //
//   //                 leading: const Icon(Icons.list),
//   //
//   //                 title: const Text("All Records"),
//   //
//   //                 onTap: () {
//   //
//   //                   Navigator.pop(context);
//   //
//   //                   setState(() {
//   //
//   //                     filter = "All";
//   //
//   //                     customRange = null;
//   //
//   //                   });
//   //
//   //                 },
//   //
//   //               ),
//   //
//   //               ListTile(
//   //
//   //                 leading: const Icon(Icons.today),
//   //
//   //                 title: const Text("Today"),
//   //
//   //                 onTap: () {
//   //
//   //                   Navigator.pop(context);
//   //
//   //                   setState(() {
//   //
//   //                     filter = "Today";
//   //
//   //                     customRange = null;
//   //
//   //                   });
//   //
//   //                 },
//   //
//   //               ),
//   //
//   //               ListTile(
//   //
//   //                 leading: const Icon(Icons.history),
//   //
//   //                 title: const Text("Yesterday"),
//   //
//   //                 onTap: () {
//   //
//   //                   Navigator.pop(context);
//   //
//   //                   setState(() {
//   //
//   //                     filter = "Yesterday";
//   //
//   //                     customRange = null;
//   //
//   //                   });
//   //
//   //                 },
//   //
//   //               ),
//   //
//   //               ListTile(
//   //
//   //                 leading: const Icon(Icons.calendar_view_week),
//   //
//   //                 title: const Text("Last 7 Days"),
//   //
//   //                 onTap: () {
//   //
//   //                   Navigator.pop(context);
//   //
//   //                   setState(() {
//   //
//   //                     filter = "Last 7 Days";
//   //
//   //                     customRange = null;
//   //
//   //                   });
//   //
//   //                 },
//   //
//   //               ),
//   //
//   //               ListTile(
//   //
//   //                 leading: const Icon(Icons.calendar_month),
//   //
//   //                 title: const Text("Last 30 Days"),
//   //
//   //                 onTap: () {
//   //
//   //                   Navigator.pop(context);
//   //
//   //                   setState(() {
//   //
//   //                     filter = "Last 30 Days";
//   //
//   //                     customRange = null;
//   //
//   //                   });
//   //
//   //                 },
//   //
//   //               ),
//   //
//   //               ListTile(
//   //
//   //                 leading: const Icon(Icons.date_range),
//   //
//   //                 title: const Text("Custom Date Range"),
//   //
//   //                 onTap: () async {
//   //
//   //                   Navigator.pop(context);
//   //
//   //                   final range =
//   //                   await showDateRangePicker(
//   //
//   //                     context: context,
//   //
//   //                     firstDate: DateTime(2020),
//   //
//   //                     lastDate: DateTime(2100),
//   //
//   //                   );
//   //
//   //                   if (range != null) {
//   //
//   //                     setState(() {
//   //
//   //                       customRange = range;
//   //
//   //                       filter = "Custom";
//   //
//   //                     });
//   //
//   //                   }
//   //
//   //                 },
//   //
//   //               ),
//   //
//   //             ],
//   //
//   //           ),
//   //
//   //         );
//   //
//   //       },
//   //
//   //     );
//   //
//   //   }
//   @override
//   Widget build(BuildContext context) {
//     Future<void> showFilterSheet() async {
//       await showModalBottomSheet(
//         context: context,
//         backgroundColor: Colors.white,
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(
//             top: Radius.circular(22),
//           ),
//         ),
//         builder: (_) {
//           return SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(
//                 24,
//                 18,
//                 24,
//                 24,
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     width: 42,
//                     height: 4,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFD5D8DE),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                   ),
//
//                   const SizedBox(height: 18),
//
//                   const Align(
//                     alignment: Alignment.centerLeft,
//                     child: Text(
//                       "Filter Records",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w700,
//                         color: Color(0xFF202124),
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 14),
//
//                   _filterOption(
//                     icon: Icons.list_alt_rounded,
//                     title: "All Records",
//                     selected: filter == "All",
//                     onTap: () {
//                       Navigator.pop(context);
//
//                       setState(() {
//                         filter = "All";
//                         customRange = null;
//                       });
//                     },
//                   ),
//
//                   _filterOption(
//                     icon: Icons.today_rounded,
//                     title: "Today",
//                     selected: filter == "Today",
//                     onTap: () {
//                       Navigator.pop(context);
//
//                       setState(() {
//                         filter = "Today";
//                         customRange = null;
//                       });
//                     },
//                   ),
//
//                   _filterOption(
//                     icon: Icons.history_rounded,
//                     title: "Yesterday",
//                     selected: filter == "Yesterday",
//                     onTap: () {
//                       Navigator.pop(context);
//
//                       setState(() {
//                         filter = "Yesterday";
//                         customRange = null;
//                       });
//                     },
//                   ),
//
//                   _filterOption(
//                     icon: Icons.date_range_rounded,
//                     title: "Last 7 Days",
//                     selected: filter == "Last 7 Days",
//                     onTap: () {
//                       Navigator.pop(context);
//
//                       setState(() {
//                         filter = "Last 7 Days";
//                         customRange = null;
//                       });
//                     },
//                   ),
//
//                   _filterOption(
//                     icon: Icons.calendar_month_rounded,
//                     title: "Last 30 Days",
//                     selected: filter == "Last 30 Days",
//                     onTap: () {
//                       Navigator.pop(context);
//
//                       setState(() {
//                         filter = "Last 30 Days";
//                         customRange = null;
//                       });
//                     },
//                   ),
//
//                   _filterOption(
//                     icon: Icons.event_rounded,
//                     title: "Custom Date Range",
//                     selected: filter == "Custom",
//                     onTap: () async {
//                       Navigator.pop(context);
//
//                       final range =
//                       await showDateRangePicker(
//                         context: context,
//                         firstDate: DateTime(2020),
//                         lastDate: DateTime(2100),
//                       );
//
//                       if (range != null) {
//                         setState(() {
//                           customRange = range;
//                           filter = "Custom";
//                         });
//                       }
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       );
//     }
//
//     final now = DateTime.now();
//
//     final filteredRecords =
//     AppData.previousArrs.where((record) {
//       final employeeMatch =
//           record.employeeCode
//               .trim()
//               .toLowerCase()
//               .contains(search) ||
//               record.appraisee
//                   .trim()
//                   .toLowerCase()
//                   .contains(search);
//
//       if (!employeeMatch) {
//         return false;
//       }
//
//       DateTime? assessmentDate;
//
//       try {
//         final parts = record.date.split('/');
//
//         assessmentDate = DateTime(
//           int.parse(parts[2]),
//           int.parse(parts[1]),
//           int.parse(parts[0]),
//         );
//       } catch (_) {
//         return filter == "All";
//       }
//
//       final dateOnly = DateTime(
//         assessmentDate.year,
//         assessmentDate.month,
//         assessmentDate.day,
//       );
//
//       final today = DateTime(
//         now.year,
//         now.month,
//         now.day,
//       );
//
//       switch (filter) {
//         case "Today":
//           return dateOnly == today;
//
//         case "Yesterday":
//           final yesterday = today.subtract(
//             const Duration(days: 1),
//           );
//
//           return dateOnly == yesterday;
//
//         case "Last 7 Days":
//           final start = today.subtract(
//             const Duration(days: 7),
//           );
//
//           return !dateOnly.isBefore(start) &&
//               !dateOnly.isAfter(today);
//
//         case "Last 30 Days":
//           final start = today.subtract(
//             const Duration(days: 30),
//           );
//
//           return !dateOnly.isBefore(start) &&
//               !dateOnly.isAfter(today);
//
//         case "Custom":
//           if (customRange == null) {
//             return true;
//           }
//
//           final start = DateTime(
//             customRange!.start.year,
//             customRange!.start.month,
//             customRange!.start.day,
//           );
//
//           final end = DateTime(
//             customRange!.end.year,
//             customRange!.end.month,
//             customRange!.end.day,
//           );
//
//           return !dateOnly.isBefore(start) &&
//               !dateOnly.isAfter(end);
//
//         default:
//           return true;
//       }
//     }).toList();
//
//     final totalCount =
//         filteredRecords.length;
//
//     final acceptableCount =
//         filteredRecords
//             .where(
//               (record) =>
//           record.result == "ACCEPTABLE",
//         )
//             .length;
//
//     final marginalCount =
//         filteredRecords
//             .where(
//               (record) =>
//           record.result ==
//               "MARGINALLY ACCEPTABLE",
//         )
//             .length;
//
//     final failedCount =
//         filteredRecords
//             .where(
//               (record) =>
//           record.result != "ACCEPTABLE" &&
//               record.result !=
//                   "MARGINALLY ACCEPTABLE",
//         )
//             .length;
//
//     return Scaffold(
//       backgroundColor:
//       const Color(0xFFF6F7F9),
//
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         surfaceTintColor:
//         Colors.transparent,
//         elevation: 0,
//
//         leading: IconButton(
//           icon: const Icon(
//             Icons.arrow_back_rounded,
//             color: Color(0xFF202124),
//           ),
//           onPressed: () =>
//               Navigator.pop(context),
//         ),
//
//         title: const Column(
//           crossAxisAlignment:
//           CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               "Previous ARR Records",
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight:
//                 FontWeight.w700,
//                 color:
//                 Color(0xFF202124),
//               ),
//             ),
//
//             Text(
//               "View and review completed inspections",
//               style: TextStyle(
//                 fontSize: 11.5,
//                 color:
//                 Color(0xFF777D86),
//               ),
//             ),
//           ],
//         ),
//
//         actions: [
//           Padding(
//             padding:
//             const EdgeInsets.only(
//               right: 24,
//             ),
//             child: OutlinedButton.icon(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) =>
//                     const CrossTabSelectionScreen(),
//                   ),
//                 );
//               },
//
//               icon: const Icon(
//                 Icons.table_chart_outlined,
//                 size: 18,
//               ),
//
//               label: const Text(
//                 "Cross Tab Report",
//               ),
//
//               style:
//               OutlinedButton.styleFrom(
//                 foregroundColor:
//                 const Color(0xFF3155C6),
//
//                 side:
//                 const BorderSide(
//                   color:
//                   Color(0xFFD6DCEB),
//                 ),
//
//                 padding:
//                 const EdgeInsets.symmetric(
//                   horizontal: 15,
//                   vertical: 11,
//                 ),
//
//                 shape:
//                 RoundedRectangleBorder(
//                   borderRadius:
//                   BorderRadius.circular(
//                     10,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//
//       body: Center(
//         child: ConstrainedBox(
//           constraints:
//           const BoxConstraints(
//             maxWidth: 1250,
//           ),
//
//           child: Column(
//             children: [
//               Padding(
//                 padding:
//                 const EdgeInsets.fromLTRB(
//                   28,
//                   26,
//                   28,
//                   18,
//                 ),
//
//                 child: Container(
//                   width: double.infinity,
//
//                   padding:
//                   const EdgeInsets.all(22),
//
//                   decoration:
//                   BoxDecoration(
//                     color: Colors.white,
//
//                     borderRadius:
//                     BorderRadius.circular(
//                       18,
//                     ),
//
//                     border: Border.all(
//                       color:
//                       const Color(
//                         0xFFE1E4E8,
//                       ),
//                     ),
//
//                     boxShadow: [
//                       BoxShadow(
//                         color:
//                         Colors.black
//                             .withValues(
//                           alpha: 0.035,
//                         ),
//                         blurRadius: 18,
//                         offset:
//                         const Offset(
//                           0,
//                           6,
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 52,
//                         height: 52,
//
//                         decoration:
//                         BoxDecoration(
//                           color:
//                           const Color(
//                             0xFFEAF0FF,
//                           ),
//
//                           borderRadius:
//                           BorderRadius
//                               .circular(
//                             14,
//                           ),
//                         ),
//
//                         child: const Icon(
//                           Icons
//                               .folder_copy_outlined,
//                           color:
//                           Color(
//                             0xFF3155C6,
//                           ),
//                           size: 27,
//                         ),
//                       ),
//
//                       const SizedBox(
//                         width: 16,
//                       ),
//
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment:
//                           CrossAxisAlignment
//                               .start,
//                           children: [
//                             const Text(
//                               "Inspection History",
//                               style:
//                               TextStyle(
//                                 fontSize: 21,
//                                 fontWeight:
//                                 FontWeight
//                                     .w700,
//                                 color:
//                                 Color(
//                                   0xFF202124,
//                                 ),
//                               ),
//                             ),
//
//                             const SizedBox(
//                               height: 5,
//                             ),
//
//                             const Text(
//                               "Review completed ARR inspections and their results.",
//                               style:
//                               TextStyle(
//                                 fontSize: 13,
//                                 color:
//                                 Color(
//                                   0xFF747B86,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//
//                       _summaryBadge(
//                         "Total",
//                         totalCount,
//                         const Color(
//                           0xFF3155C6,
//                         ),
//                       ),
//
//                       const SizedBox(
//                         width: 10,
//                       ),
//
//                       _summaryBadge(
//                         "Acceptable",
//                         acceptableCount,
//                         const Color(
//                           0xFF249653,
//                         ),
//                       ),
//
//                       const SizedBox(
//                         width: 10,
//                       ),
//
//                       _summaryBadge(
//                         "Marginal",
//                         marginalCount,
//                         const Color(
//                           0xFFD88A24,
//                         ),
//                       ),
//
//                       const SizedBox(
//                         width: 10,
//                       ),
//
//                       _summaryBadge(
//                         "Failed",
//                         failedCount,
//                         const Color(
//                           0xFFD94A4A,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               Padding(
//                 padding:
//                 const EdgeInsets.symmetric(
//                   horizontal: 28,
//                 ),
//
//                 child: Container(
//                   padding:
//                   const EdgeInsets.all(12),
//
//                   decoration:
//                   BoxDecoration(
//                     color: Colors.white,
//
//                     borderRadius:
//                     BorderRadius.circular(
//                       14,
//                     ),
//
//                     border: Border.all(
//                       color:
//                       const Color(
//                         0xFFE1E4E8,
//                       ),
//                     ),
//                   ),
//
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: TextField(
//                           controller:
//                           searchController,
//
//                           onChanged: (value) {
//                             setState(() {
//                               search = value
//                                   .trim()
//                                   .toLowerCase();
//                             });
//                           },
//
//                           decoration:
//                           InputDecoration(
//                             hintText:
//                             "Search employee ID or candidate name",
//
//                             prefixIcon:
//                             const Icon(
//                               Icons.search_rounded,
//                               size: 21,
//                             ),
//
//                             filled: true,
//
//                             fillColor:
//                             const Color(
//                               0xFFF7F8FA,
//                             ),
//
//                             border:
//                             OutlineInputBorder(
//                               borderRadius:
//                               BorderRadius
//                                   .circular(
//                                 10,
//                               ),
//                               borderSide:
//                               BorderSide.none,
//                             ),
//
//                             enabledBorder:
//                             OutlineInputBorder(
//                               borderRadius:
//                               BorderRadius
//                                   .circular(
//                                 10,
//                               ),
//                               borderSide:
//                               const BorderSide(
//                                 color:
//                                 Color(
//                                   0xFFE2E5E9,
//                                 ),
//                               ),
//                             ),
//
//                             focusedBorder:
//                             OutlineInputBorder(
//                               borderRadius:
//                               BorderRadius
//                                   .circular(
//                                 10,
//                               ),
//                               borderSide:
//                               const BorderSide(
//                                 color:
//                                 Color(
//                                   0xFF3155C6,
//                                 ),
//                                 width: 1.4,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//
//                       const SizedBox(
//                         width: 12,
//                       ),
//
//                       OutlinedButton.icon(
//                         onPressed:
//                         showFilterSheet,
//
//                         icon: const Icon(
//                           Icons.tune_rounded,
//                           size: 18,
//                         ),
//
//                         label: Text(
//                           filter == "All"
//                               ? "Filter"
//                               : filter ==
//                               "Custom"
//                               ? "Custom Range"
//                               : filter,
//                         ),
//
//                         style:
//                         OutlinedButton
//                             .styleFrom(
//                           foregroundColor:
//                           const Color(
//                             0xFF3155C6,
//                           ),
//
//                           side:
//                           const BorderSide(
//                             color:
//                             Color(
//                               0xFFD5DCF1,
//                             ),
//                           ),
//
//                           backgroundColor:
//                           const Color(
//                             0xFFF8FAFF,
//                           ),
//
//                           padding:
//                           const EdgeInsets
//                               .symmetric(
//                             horizontal: 16,
//                             vertical: 15,
//                           ),
//
//                           shape:
//                           RoundedRectangleBorder(
//                             borderRadius:
//                             BorderRadius
//                                 .circular(
//                               10,
//                             ),
//                           ),
//                         ),
//                       ),
//
//                       if (filter != "All") ...[
//                         const SizedBox(
//                           width: 8,
//                         ),
//
//                         IconButton(
//                           tooltip:
//                           "Clear filter",
//
//                           onPressed: () {
//                             setState(() {
//                               filter = "All";
//                               customRange =
//                               null;
//                             });
//                           },
//
//                           icon: const Icon(
//                             Icons.close_rounded,
//                             size: 20,
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//
//               const SizedBox(
//                 height: 14,
//               ),
//
//               if (filter != "All")
//                 Padding(
//                   padding:
//                   const EdgeInsets.symmetric(
//                     horizontal: 28,
//                   ),
//
//                   child: Align(
//                     alignment:
//                     Alignment.centerLeft,
//
//                     child: Container(
//                       padding:
//                       const EdgeInsets
//                           .symmetric(
//                         horizontal: 12,
//                         vertical: 8,
//                       ),
//
//                       decoration:
//                       BoxDecoration(
//                         color:
//                         const Color(
//                           0xFFEAF0FF,
//                         ),
//
//                         borderRadius:
//                         BorderRadius
//                             .circular(
//                           9,
//                         ),
//                       ),
//
//                       child: Row(
//                         mainAxisSize:
//                         MainAxisSize.min,
//                         children: [
//                           const Icon(
//                             Icons
//                                 .filter_alt_rounded,
//                             size: 16,
//                             color:
//                             Color(
//                               0xFF3155C6,
//                             ),
//                           ),
//
//                           const SizedBox(
//                             width: 7,
//                           ),
//
//                           Text(
//                             filter == "Custom"
//                                 ? "${customRange!.start.day}/${customRange!
//                                 .start.month}/${customRange!.start.year}"
//                                 " - "
//                                 "${customRange!.end.day}/${customRange!.end
//                                 .month}/${customRange!.end.year}"
//                                 : filter,
//
//                             style:
//                             const TextStyle(
//                               fontSize: 12,
//                               fontWeight:
//                               FontWeight
//                                   .w600,
//                               color:
//                               Color(
//                                 0xFF3155C6,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//
//               const SizedBox(
//                 height: 10,
//               ),
//
//               Expanded(
//                 child: filteredRecords.isEmpty
//                     ? _emptyState()
//                     : ListView.builder(
//                   padding:
//                   const EdgeInsets
//                       .fromLTRB(
//                     28,
//                     6,
//                     28,
//                     32,
//                   ),
//
//                   itemCount:
//                   filteredRecords
//                       .length,
//
//                   itemBuilder:
//                       (context, index) {
//                     final record =
//                     filteredRecords[
//                     index];
//
//                     return _recordCard(
//                       context,
//                       record,
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';

import '../services/app_data.dart';
import 'previous_arr_detail_screen.dart';
import 'cross_tab_selection_screen.dart';
import '../models/arr_record.dart';
import '../services/supabase_service.dart';

class PreviousArrScreen extends StatefulWidget {
  const PreviousArrScreen({super.key});

  @override
  State<PreviousArrScreen> createState() =>
      _PreviousArrScreenState();
}

class _PreviousArrScreenState extends State<PreviousArrScreen> {
  final TextEditingController searchController =
  TextEditingController();

  String search = "";
  String filter = "All";
  DateTimeRange? customRange;

  bool isLoading = true;
  String? loadError;

  final Map<String, String> _arrIdsByCertificate = {};

  @override
  void initState() {
    super.initState();
    _loadPreviousArrs();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPreviousArrs() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
          loadError = null;
        });
      }

      // Only fetch the lightweight ARR list.
      // Employee details and observations are NOT loaded here.
      final rows =
      await SupabaseService.getPreviousArrList();

      final records = <ArrRecord>[];

      _arrIdsByCertificate.clear();

      for (final row in rows) {
        final arrId =
            row['arr_id']?.toString().trim() ?? '';

        final certificateNumber =
            row['certificate_number']?.toString().trim() ?? '';

        if (arrId.isNotEmpty &&
            certificateNumber.isNotEmpty) {
          _arrIdsByCertificate[certificateNumber] = arrId;
        }

        records.add(
          ArrRecord(
            employeeCode:
            row['employee_code_snap']
                ?.toString() ??
                '',

            // These fields are intentionally empty.
            // They are loaded when the user opens details.
            appraisee: '',
            department: '',

            product:
            row['product']
                ?.toString() ??
                '',

            batchName:
            row['batch_name_snap']
                ?.toString() ??
                '',

            result:
            row['classification']
                ?.toString() ??
                '',

            certificateNo:
            row['certificate_number']
                ?.toString() ??
                '',

            date: _formatDate(
              row['assessment_date']
                  ?.toString() ??
                  '',
            ),

            falseAlertPercent:
            _toDouble(
              row['false_alert_pct'],
            ),

            missRate:
            _toDouble(
              row['miss_rate_pct'],
            ),

            effectiveness:
            _toDouble(
              row['effectiveness_pct'],
            ),

            kappa:
            _toDouble(
              row['kappa_pct'],
            ),

            // Detail data is deliberately empty here.
            trail1Answers: const [],
            trail2Answers: const [],
            trail3Answers: const [],
            partNumbers: const [],
            masterAnswers: const [],

            batchId:
            row['batch_id']
                ?.toString() ??
                '',

            // Photo belongs to the detailed record.
            // It is intentionally empty in the lightweight list.
            candidatePhotoPath: '',
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        AppData.previousArrs = records;
        isLoading = false;
        loadError = null;
      });

    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        loadError = e.toString();
      });
    }
  }

  int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    ) ??
        0;
  }

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    ) ??
        0.0;
  }

  String _formatDate(String value) {
    if (value.isEmpty) {
      return '';
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Widget _filterOption({
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 4),

      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFEAF0FF)
              : const Color(0xFFF5F6F8),
          borderRadius:
          BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: selected
              ? const Color(0xFF3155C6)
              : const Color(0xFF62666D),
        ),
      ),

      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected
              ? FontWeight.w700
              : FontWeight.w500,
          color: const Color(0xFF202124),
        ),
      ),

      trailing: selected
          ? const Icon(
        Icons.check_rounded,
        color: Color(0xFF3155C6),
      )
          : null,

      onTap: onTap,
    );
  }

  Widget _summaryBadge(
      String label,
      int value,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 9,
      ),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius:
        BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),

      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF747982),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordCard(
      BuildContext context,
      ArrRecord record,
      ) {
    final result = record.result;

    final bool acceptable =
        result == "ACCEPTABLE";

    final bool marginal =
        result == "MARGINALLY ACCEPTABLE";

    final Color statusColor = acceptable
        ? const Color(0xFF249653)
        : marginal
        ? const Color(0xFFD88A24)
        : const Color(0xFFD94A4A);

    final Color statusBackground = acceptable
        ? const Color(0xFFEAF7EF)
        : marginal
        ? const Color(0xFFFFF4E5)
        : const Color(0xFFFCEBEC);

    return Container(
      margin:
      const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(16),

        border: Border.all(
          color: const Color(0xFFE1E4E8),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.025,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      padding: const EdgeInsets.all(18),

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color:
              const Color(0xFFEAF0FF),
              borderRadius:
              BorderRadius.circular(14),
            ),

            child: const Icon(
              Icons.person_outline_rounded,
              color: Color(0xFF3155C6),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  record.employeeCode,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF202124),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  record.appraisee,
                  style: const TextStyle(
                    fontSize: 13,
                    color:
                    Color(0xFF62666D),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '${record.batchName} • ${record.date}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color:
                    Color(0xFF8A8F98),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),

            decoration: BoxDecoration(
              color: statusBackground,
              borderRadius:
              BorderRadius.circular(9),
            ),

            child: Text(
              result,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),

          const SizedBox(width: 14),

          OutlinedButton.icon(
            onPressed: () {
              final arrId =
              _arrIdsByCertificate[record.certificateNo];

              if (arrId == null || arrId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Unable to open ARR details. ARR ID is missing.",
                    ),
                  ),
                );
                return;
              }

              Navigator.pushNamed(
                context,
                '/ARR/previousArrDetail',
                arguments: arrId,
              );
            },

            icon: const Icon(
              Icons.visibility_outlined,
              size: 17,
            ),

            label: const Text(
              "View",
            ),

            style:
            OutlinedButton.styleFrom(
              foregroundColor:
              const Color(0xFF3155C6),

              side: const BorderSide(
                color: Color(0xFFD5DCF1),
              ),

              padding:
              const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),

              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Container(
        width: 430,
        padding: const EdgeInsets.all(32),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE1E4E8),
          ),
        ),

        child: Column(
          mainAxisSize:
          MainAxisSize.min,

          children: [
            Container(
              width: 64,
              height: 64,

              decoration: BoxDecoration(
                color:
                const Color(0xFFF0F2F5),
                borderRadius:
                BorderRadius.circular(18),
              ),

              child: const Icon(
                Icons.folder_open_outlined,
                size: 32,
                color: Color(0xFF777D86),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "No Records Found",
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                FontWeight.w700,
                color:
                Color(0xFF202124),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "No previous ARR inspections match the current search or filter.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color:
                Color(0xFF777D86),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child:
            CircularProgressIndicator(
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 14),
          Text(
            "Loading previous ARR records...",
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisSize:
        MainAxisSize.min,

        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 44,
            color: Colors.redAccent,
          ),

          const SizedBox(height: 12),

          const Text(
            "Unable to load ARR records",
            style: TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          SizedBox(
            width: 500,
            child: Text(
              loadError ?? "Unknown error",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color:
                Color(0xFF777D86),
              ),
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _loadPreviousArrs,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label:
            const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterSheet(
      BuildContext context,
      ) async {
    await showModalBottomSheet(
      context: context,

      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),

      builder: (_) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.all(16),

            child: Column(
              mainAxisSize:
              MainAxisSize.min,

              children: [
                Container(
                  width: 42,
                  height: 4,

                  decoration:
                  BoxDecoration(
                    color:
                    const Color(
                      0xFFD5D8DE,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Align(
                  alignment:
                  Alignment.centerLeft,

                  child: Text(
                    "Filter Records",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.w700,
                      color:
                      Color(0xFF202124),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                _filterOption(
                  icon:
                  Icons.list_alt_rounded,
                  title: "All Records",
                  selected:
                  filter == "All",
                  onTap: () {
                    Navigator.pop(context);

                    setState(() {
                      filter = "All";
                      customRange = null;
                    });
                  },
                ),

                _filterOption(
                  icon:
                  Icons.today_rounded,
                  title: "Today",
                  selected:
                  filter == "Today",
                  onTap: () {
                    Navigator.pop(context);

                    setState(() {
                      filter = "Today";
                      customRange = null;
                    });
                  },
                ),

                _filterOption(
                  icon:
                  Icons.history_rounded,
                  title: "Yesterday",
                  selected:
                  filter == "Yesterday",
                  onTap: () {
                    Navigator.pop(context);

                    setState(() {
                      filter = "Yesterday";
                      customRange = null;
                    });
                  },
                ),

                _filterOption(
                  icon:
                  Icons.date_range_rounded,
                  title: "Last 7 Days",
                  selected:
                  filter == "Last 7 Days",
                  onTap: () {
                    Navigator.pop(context);

                    setState(() {
                      filter = "Last 7 Days";
                      customRange = null;
                    });
                  },
                ),

                _filterOption(
                  icon:
                  Icons.calendar_month_rounded,
                  title: "Last 30 Days",
                  selected:
                  filter == "Last 30 Days",
                  onTap: () {
                    Navigator.pop(context);

                    setState(() {
                      filter = "Last 30 Days";
                      customRange = null;
                    });
                  },
                ),

                _filterOption(
                  icon:
                  Icons.event_rounded,
                  title: "Custom Date Range",
                  selected:
                  filter == "Custom",
                  onTap: () async {
                    Navigator.pop(context);

                    final range =
                    await showDateRangePicker(
                      context: context,
                      firstDate:
                      DateTime(2020),
                      lastDate:
                      DateTime(2100),
                    );

                    if (range != null &&
                        mounted) {
                      setState(() {
                        customRange = range;
                        filter = "Custom";
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final now = DateTime.now();

    final filteredRecords =
    AppData.previousArrs.where(
          (record) {
        final query =
        search.trim().toLowerCase();

        final employeeMatch =
            record.employeeCode
                .trim()
                .toLowerCase()
                .contains(query) ||
                record.appraisee
                    .trim()
                    .toLowerCase()
                    .contains(query);

        if (!employeeMatch) {
          return false;
        }

        DateTime? assessmentDate;

        try {
          final parts =
          record.date.split('/');

          assessmentDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        } catch (_) {
          return filter == "All";
        }

        final dateOnly = DateTime(
          assessmentDate.year,
          assessmentDate.month,
          assessmentDate.day,
        );

        final today = DateTime(
          now.year,
          now.month,
          now.day,
        );

        switch (filter) {
          case "Today":
            return dateOnly == today;

          case "Yesterday":
            final yesterday =
            today.subtract(
              const Duration(days: 1),
            );

            return dateOnly ==
                yesterday;

          case "Last 7 Days":
            final start =
            today.subtract(
              const Duration(days: 7),
            );

            return !dateOnly
                .isBefore(start) &&
                !dateOnly
                    .isAfter(today);

          case "Last 30 Days":
            final start =
            today.subtract(
              const Duration(days: 30),
            );

            return !dateOnly
                .isBefore(start) &&
                !dateOnly
                    .isAfter(today);

          case "Custom":
            if (customRange ==
                null) {
              return true;
            }

            final start = DateTime(
              customRange!.start.year,
              customRange!.start.month,
              customRange!.start.day,
            );

            final end = DateTime(
              customRange!.end.year,
              customRange!.end.month,
              customRange!.end.day,
            );

            return !dateOnly
                .isBefore(start) &&
                !dateOnly
                    .isAfter(end);

          default:
            return true;
        }
      },
    ).toList();

    final totalCount =
        filteredRecords.length;

    final acceptableCount =
        filteredRecords
            .where(
              (record) =>
          record.result ==
              "ACCEPTABLE",
        )
            .length;

    final marginalCount =
        filteredRecords
            .where(
              (record) =>
          record.result ==
              "MARGINALLY ACCEPTABLE",
        )
            .length;

    final failedCount =
        filteredRecords
            .where(
              (record) =>
          record.result !=
              "ACCEPTABLE" &&
              record.result !=
                  "MARGINALLY ACCEPTABLE",
        )
            .length;

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

          mainAxisSize:
          MainAxisSize.min,

          children: [
            Text(
              "Previous ARR Records",
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.w700,
                color:
                Color(0xFF202124),
              ),
            ),

            Text(
              "View and review completed inspections",
              style: TextStyle(
                fontSize: 11.5,
                color:
                Color(0xFF777D86),
              ),
            ),
          ],
        ),

        actions: [
          Padding(
            padding:
            const EdgeInsets.only(
              right: 24,
            ),

            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const CrossTabSelectionScreen(),
                  ),
                );
              },

              icon: const Icon(
                Icons.table_chart_outlined,
                size: 18,
              ),

              label:
              const Text(
                "Cross Tab Report",
              ),

              style:
              OutlinedButton.styleFrom(
                foregroundColor:
                const Color(
                  0xFF3155C6,
                ),

                side:
                const BorderSide(
                  color:
                  Color(0xFFD6DCEB),
                ),

                padding:
                const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 11,
                ),

                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      body: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 1250,
          ),

          child: Column(
            children: [
              Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  28,
                  26,
                  28,
                  18,
                ),

                child: Container(
                  width:
                  double.infinity,

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
                      color:
                      const Color(
                        0xFFE1E4E8,
                      ),
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(
                          alpha: 0.035,
                        ),
                        blurRadius: 18,
                        offset:
                        const Offset(
                          0,
                          6,
                        ),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      _summaryBadge(
                        "TOTAL",
                        totalCount,
                        const Color(
                          0xFF3155C6,
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      _summaryBadge(
                        "PASSED",
                        acceptableCount,
                        const Color(
                          0xFF249653,
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      _summaryBadge(
                        "MARGINAL",
                        marginalCount,
                        const Color(
                          0xFFD88A24,
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      _summaryBadge(
                        "FAILED",
                        failedCount,
                        const Color(
                          0xFFD94A4A,
                        ),
                      ),

                      const Spacer(),

                      SizedBox(
                        width: 260,
                        child:
                        TextField(
                          controller:
                          searchController,

                          onChanged:
                              (value) {
                            setState(() {
                              search =
                                  value;
                            });
                          },

                          decoration:
                          InputDecoration(
                            prefixIcon:
                            const Icon(
                              Icons
                                  .search_rounded,
                              size: 20,
                            ),

                            hintText:
                            "Search employee or candidate",

                            border:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                10,
                              ),
                              borderSide:
                              const BorderSide(
                                color:
                                Color(
                                  0xFFD5DCF1,
                                ),
                              ),
                            ),

                            enabledBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                10,
                              ),
                              borderSide:
                              const BorderSide(
                                color:
                                Color(
                                  0xFFD5DCF1,
                                ),
                              ),
                            ),

                            contentPadding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      OutlinedButton.icon(
                        onPressed: () =>
                            _showFilterSheet(
                              context,
                            ),

                        icon: const Icon(
                          Icons.tune_rounded,
                          size: 18,
                        ),

                        label: Text(
                          filter == "All"
                              ? "Filter"
                              : filter ==
                              "Custom"
                              ? "Custom Range"
                              : filter,
                        ),

                        style:
                        OutlinedButton.styleFrom(
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

                          backgroundColor:
                          const Color(
                            0xFFF8FAFF,
                          ),

                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 16,
                            vertical: 15,
                          ),

                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              10,
                            ),
                          ),
                        ),
                      ),

                      if (filter != "All")
                        IconButton(
                          tooltip:
                          "Clear filter",

                          onPressed: () {
                            setState(() {
                              filter = "All";
                              customRange =
                              null;
                            });
                          },

                          icon: const Icon(
                            Icons
                                .close_rounded,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              if (filter != "All")
                Padding(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 28,
                  ),

                  child: Align(
                    alignment:
                    Alignment.centerLeft,

                    child: Container(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),

                      decoration:
                      BoxDecoration(
                        color:
                        const Color(
                          0xFFEAF0FF,
                        ),

                        borderRadius:
                        BorderRadius.circular(
                          9,
                        ),
                      ),

                      child: Row(
                        mainAxisSize:
                        MainAxisSize.min,

                        children: [
                          const Icon(
                            Icons
                                .filter_alt_rounded,
                            size: 16,
                            color:
                            Color(
                              0xFF3155C6,
                            ),
                          ),

                          const SizedBox(
                            width: 7,
                          ),

                          Text(
                            filter == "Custom"
                                ? "${customRange!.start.day}/${customRange!.start.month}/${customRange!.start.year}"
                                " - "
                                "${customRange!.end.day}/${customRange!.end.month}/${customRange!.end.year}"
                                : filter,

                            style:
                            const TextStyle(
                              fontSize: 12,
                              fontWeight:
                              FontWeight.w600,
                              color:
                              Color(
                                0xFF3155C6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(
                height: 10,
              ),

              Expanded(
                child: isLoading
                    ? _loadingState()
                    : loadError != null
                    ? _errorState()
                    : filteredRecords
                    .isEmpty
                    ? _emptyState()
                    : ListView.builder(
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                    28,
                    6,
                    28,
                    32,
                  ),

                  itemCount:
                  filteredRecords
                      .length,

                  itemBuilder:
                      (context,
                      index) {
                    final record =
                    filteredRecords[
                    index];

                    return _recordCard(
                      context,
                      record,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}