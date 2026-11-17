// // import 'package:flutter/material.dart';
// //
// // import '../../services/supabase_service.dart';
import '../../services/audit/audit_admin_session.dart';
// //
// // class AuditScheduleScreen extends StatefulWidget {
// //   final String sessionToken;
// //
// //   const AuditScheduleScreen({
// //     super.key,
// //     required this.sessionToken,
// //   });
// //
// //   @override
// //   State<AuditScheduleScreen> createState() =>
// //       _AuditScheduleScreenState();
// // }
// //
// // class _AuditScheduleScreenState
// //     extends State<AuditScheduleScreen> {
// //   static const Color _background =
// //   Color(0xFFF5F7FB);
// //
// //   static const Color _purple =
// //   Color(0xFF7656C6);
// //
// //   static const Color _text =
// //   Color(0xFF172033);
// //
// //   static const Color _muted =
// //   Color(0xFF6B7280);
// //
// //   bool _loading = true;
// //   bool _saving = false;
// //
// //   String? _error;
// //
// //   DateTime _selectedDate =
// //   _dateOnly(DateTime.now());
// //
// //   DateTime _displayedMonth = DateTime(
// //     DateTime.now().year,
// //     DateTime.now().month,
// //   );
// //
// //   List<Map<String, dynamic>> _schedules =
// //   [];
// //
// //   List<Map<String, dynamic>> _auditors =
// //   [];
// //
// //   List<Map<String, dynamic>> _masters =
// //   [];
// //   List<Map<String, dynamic>> _auditTypes =
// //   [];
// //
// //   String? _selectedPlanningTypeId;
// //
// //   int _planningYear =
// //       DateTime.now().year;
// //
// //   static DateTime _dateOnly(
// //       DateTime value,
// //       ) {
// //     return DateTime(
// //       value.year,
// //       value.month,
// //       value.day,
// //     );
// //   }
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadData();
// //   }
// //
// //   // ============================================================
// //   // LOAD DATA
// //   // ============================================================
// //
// //   Future<void> _loadData() async {
// //     if (!mounted) return;
// //
// //     setState(() {
// //       _loading = true;
// //       _error = null;
// //     });
// //
// //     try {
// //       final results = await Future.wait([
// //         SupabaseService.getAllAuditSchedules()
// //             .timeout(
// //           const Duration(seconds: 20),
// //         ),
// //         SupabaseService.getActiveAuditors()
// //             .timeout(
// //           const Duration(seconds: 20),
// //         ),
// //         SupabaseService.getAdminAuditMasterData(
// //           sessionToken:
// //           widget.sessionToken,
// //         ).timeout(
// //           const Duration(seconds: 20),
// //         ),
// //         SupabaseService.getActiveAuditTypes()
// //             .timeout(
// //           const Duration(seconds: 20),
// //         ),
// //       ]);
// //
// //       if (!mounted) return;
// //
// //       final schedules =
// //       List<Map<String, dynamic>>.from(
// //         results[0] as List,
// //       );
// //
// //       final auditors =
// //       List<Map<String, dynamic>>.from(
// //         results[1] as List,
// //       );
// //
// //       final masters =
// //       List<Map<String, dynamic>>.from(
// //         results[2] as List,
// //       );
// //       final auditTypes =
// //       List<Map<String, dynamic>>.from(
// //         results[3] as List,
// //       );
// //       setState(() {
// //         _schedules = schedules;
// //         _auditors = auditors;
// //         _masters = masters;
// //         _auditTypes = auditTypes;
// //
// //         if (_selectedPlanningTypeId == null &&
// //             _auditTypes.isNotEmpty) {
// //           _selectedPlanningTypeId =
// //               _auditTypes.first['type_id']
// //                   ?.toString();
// //         }
// //
// //         _loading = false;
// //       });
// //     } catch (e) {
// //       if (!mounted) return;
// //
// //       setState(() {
// //         _loading = false;
// //         _error = e.toString();
// //       });
// //     }
// //   }
// //
// //   // ============================================================
// //   // DATE HELPERS
// //   // ============================================================
// //
// //   DateTime? _parseDate(dynamic value) {
// //     if (value == null) {
// //       return null;
// //     }
// //
// //     try {
// //       return _dateOnly(
// //         DateTime.parse(
// //           value.toString(),
// //         ),
// //       );
// //     } catch (_) {
// //       return null;
// //     }
// //   }
// //
// //   bool _sameDate(
// //       DateTime first,
// //       DateTime second,
// //       ) {
// //     return first.year == second.year &&
// //         first.month == second.month &&
// //         first.day == second.day;
// //   }
// //
// //   String _formatDate(
// //       DateTime date,
// //       ) {
// //     return '${date.day.toString().padLeft(2, '0')}/'
// //         '${date.month.toString().padLeft(2, '0')}/'
// //         '${date.year}';
// //   }
// //
// //   String _monthTitle(
// //       DateTime date,
// //       ) {
// //     const months = [
// //       'January',
// //       'February',
// //       'March',
// //       'April',
// //       'May',
// //       'June',
// //       'July',
// //       'August',
// //       'September',
// //       'October',
// //       'November',
// //       'December',
// //     ];
// //
// //     return '${months[date.month - 1]} ${date.year}';
// //   }
// //
// //   List<Map<String, dynamic>>
// //   _schedulesForDate(
// //       DateTime date,
// //       ) {
// //     return _schedules.where(
// //           (schedule) {
// //         final scheduleDate =
// //         _parseDate(
// //           schedule['audit_date'],
// //         );
// //
// //         if (scheduleDate == null) {
// //           return false;
// //         }
// //
// //         return _sameDate(
// //           scheduleDate,
// //           date,
// //         );
// //       },
// //     ).toList();
// //   }
// //
// //   // ============================================================
// //   // CALENDAR NAVIGATION
// //   // ============================================================
// //
// //   void _previousMonth() {
// //     setState(() {
// //       _displayedMonth = DateTime(
// //         _displayedMonth.year,
// //         _displayedMonth.month - 1,
// //       );
// //     });
// //   }
// //
// //   void _nextMonth() {
// //     setState(() {
// //       _displayedMonth = DateTime(
// //         _displayedMonth.year,
// //         _displayedMonth.month + 1,
// //       );
// //     });
// //   }
// //
// //   void _goToday() {
// //     final today =
// //     _dateOnly(DateTime.now());
// //
// //     setState(() {
// //       _selectedDate = today;
// //
// //       _displayedMonth = DateTime(
// //         today.year,
// //         today.month,
// //       );
// //     });
// //   }
// //
// //   // ============================================================
// //   // ADD SCHEDULE
// //   // ============================================================
// //
// //   Future<void> _addSchedule() async {
// //     if (_auditors.isEmpty) {
// //       _message(
// //         'No active auditors are available. Add an auditor first.',
// //       );
// //       return;
// //     }
// //
// //     final activeMasters =
// //     _masters.where(
// //           (master) {
// //         final active =
// //         master['active'];
// //
// //         return active == true ||
// //             active == null;
// //       },
// //     ).toList();
// //
// //     if (activeMasters.isEmpty) {
// //       _message(
// //         'No active Audit Master Data is available.',
// //       );
// //       return;
// //     }
// //
// //     await _showScheduleDialog(
// //       selectedDate: _selectedDate,
// //     );
// //   }
// //
// //   // ============================================================
// //   // EDIT SCHEDULE
// //   // ============================================================
// //
// //   Future<void> _editSchedule(
// //       Map<String, dynamic> schedule,
// //       ) async {
// //     final scheduleDate =
// //     _parseDate(
// //       schedule['audit_date'],
// //     );
// //
// //     await _showScheduleDialog(
// //       existing: schedule,
// //       selectedDate:
// //       scheduleDate ?? _selectedDate,
// //     );
// //   }
// //
// //   // ============================================================
// //   // DELETE SCHEDULE
// //   // ============================================================
// //
// //   Future<void> _deleteSchedule(
// //       Map<String, dynamic> schedule,
// //       ) async {
// //     final scheduleId =
// //     schedule['schedule_id']
// //         ?.toString();
// //
// //     if (scheduleId == null ||
// //         scheduleId.isEmpty) {
// //       _message(
// //         'Schedule ID is missing.',
// //       );
// //       return;
// //     }
// //
// //     final scheduleNumber =
// //         schedule['schedule_number']
// //             ?.toString() ??
// //             'this schedule';
// //
// //     final confirmed =
// //     await showDialog<bool>(
// //       context: context,
// //       builder: (
// //           dialogContext,
// //           ) {
// //         return AlertDialog(
// //           title: const Text(
// //             'Delete Schedule',
// //           ),
// //           content: Text(
// //             'Delete "$scheduleNumber"?',
// //           ),
// //           actions: [
// //             TextButton(
// //               onPressed: () {
// //                 Navigator.pop(
// //                   dialogContext,
// //                   false,
// //                 );
// //               },
// //               child: const Text(
// //                 'Cancel',
// //               ),
// //             ),
// //             FilledButton(
// //               onPressed: () {
// //                 Navigator.pop(
// //                   dialogContext,
// //                   true,
// //                 );
// //               },
// //               child: const Text(
// //                 'Delete',
// //               ),
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //
// //     if (confirmed != true) {
// //       return;
// //     }
// //
// //     setState(() {
// //       _saving = true;
// //     });
// //
// //     try {
// //       await SupabaseService
// //           .deleteAuditSchedule(
// //         scheduleId: scheduleId,
// //       ).timeout(
// //         const Duration(seconds: 20),
// //       );
// //
// //       if (!mounted) return;
// //
// //       setState(() {
// //         _schedules.removeWhere(
// //               (item) =>
// //           item['schedule_id']
// //               ?.toString() ==
// //               scheduleId,
// //         );
// //
// //         _saving = false;
// //       });
// //
// //       _message(
// //         'Schedule deleted successfully.',
// //       );
// //     } catch (e) {
// //       if (!mounted) return;
// //
// //       setState(() {
// //         _saving = false;
// //       });
// //
// //       _message(
// //         'Unable to delete schedule: $e',
// //       );
// //     }
// //   }
// //
// //   // ============================================================
// //   // SCHEDULE DIALOG
// //   // ============================================================
// //
// //   Future<void> _showScheduleDialog({
// //     Map<String, dynamic>? existing,
// //     required DateTime selectedDate,
// //   }) async {
// //     final isEditing =
// //         existing != null;
// //
// //     DateTime auditDate =
// //         _parseDate(
// //           existing?['audit_date'],
// //         ) ??
// //             selectedDate;
// //
// //     String? selectedMasterId =
// //     existing?['master_id']
// //         ?.toString();
// //
// //     String? selectedAuditorId =
// //     existing?['auditor_id']
// //         ?.toString();
// //
// //     String selectedStatus =
// //         existing?['status']
// //             ?.toString() ??
// //             'Planned';
// //
// //     final notesController =
// //     TextEditingController(
// //       text:
// //       existing?['notes']
// //           ?.toString() ??
// //           '',
// //     );
// //
// //     bool dialogSaving = false;
// //
// //     try {
// //       await showDialog<void>(
// //         context: context,
// //         barrierDismissible: false,
// //         builder: (
// //             dialogContext,
// //             ) {
// //           return StatefulBuilder(
// //             builder: (
// //                 context,
// //                 setDialogState,
// //                 ) {
// //               /*
// //                * IMPORTANT:
// //                *
// //                * getActiveAuditors() already returns
// //                * ONLY active auditors.
// //                *
// //                * Therefore DO NOT filter using
// //                * auditor['active'] here.
// //                */
// //               final auditors =
// //               List<Map<String, dynamic>>.from(
// //                 _auditors,
// //               );
// //
// //               final masters =
// //               _masters.where(
// //                     (master) {
// //                   final active =
// //                   master['active'];
// //
// //                   return active == true ||
// //                       active == null;
// //                 },
// //               ).toList();
// //
// //               return AlertDialog(
// //                 shape:
// //                 RoundedRectangleBorder(
// //                   borderRadius:
// //                   BorderRadius.circular(
// //                     20,
// //                   ),
// //                 ),
// //                 titlePadding:
// //                 const EdgeInsets.fromLTRB(
// //                   24,
// //                   22,
// //                   24,
// //                   10,
// //                 ),
// //                 contentPadding:
// //                 const EdgeInsets.fromLTRB(
// //                   24,
// //                   10,
// //                   24,
// //                   4,
// //                 ),
// //                 actionsPadding:
// //                 const EdgeInsets.fromLTRB(
// //                   24,
// //                   4,
// //                   24,
// //                   18,
// //                 ),
// //                 title: Row(
// //                   children: [
// //                     Container(
// //                       width: 42,
// //                       height: 42,
// //                       decoration:
// //                       BoxDecoration(
// //                         color:
// //                         const Color(
// //                           0xFFF0E9FF,
// //                         ),
// //                         borderRadius:
// //                         BorderRadius
// //                             .circular(
// //                           12,
// //                         ),
// //                       ),
// //                       child: const Icon(
// //                         Icons
// //                             .calendar_month_outlined,
// //                         color: _purple,
// //                       ),
// //                     ),
// //                     const SizedBox(
// //                       width: 12,
// //                     ),
// //                     Text(
// //                       isEditing
// //                           ? 'Edit Schedule'
// //                           : 'Schedule Audit',
// //                       style:
// //                       const TextStyle(
// //                         fontWeight:
// //                         FontWeight.w800,
// //                         color: _text,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //                 content: SizedBox(
// //                   width: 540,
// //                   child:
// //                   SingleChildScrollView(
// //                     child: Column(
// //                       mainAxisSize:
// //                       MainAxisSize.min,
// //                       children: [
// //                         // ==================================================
// //                         // DATE
// //                         // ==================================================
// //
// //                         InkWell(
// //                           borderRadius:
// //                           BorderRadius
// //                               .circular(
// //                             10,
// //                           ),
// //                           onTap:
// //                           dialogSaving
// //                               ? null
// //                               : () async {
// //                             final picked =
// //                             await showDatePicker(
// //                               context:
// //                               context,
// //                               initialDate:
// //                               auditDate,
// //                               firstDate:
// //                               DateTime(
// //                                 2020,
// //                               ),
// //                               lastDate:
// //                               DateTime(
// //                                 2100,
// //                               ),
// //                             );
// //
// //                             if (picked ==
// //                                 null) {
// //                               return;
// //                             }
// //
// //                             setDialogState(
// //                                   () {
// //                                 auditDate =
// //                                     picked;
// //                               },
// //                             );
// //                           },
// //                           child:
// //                           InputDecorator(
// //                             decoration:
// //                             const InputDecoration(
// //                               labelText:
// //                               'Audit Date *',
// //                               border:
// //                               OutlineInputBorder(),
// //                               prefixIcon:
// //                               Icon(
// //                                 Icons
// //                                     .calendar_today_outlined,
// //                               ),
// //                             ),
// //                             child: Text(
// //                               _formatDate(
// //                                 auditDate,
// //                               ),
// //                               style:
// //                               const TextStyle(
// //                                 fontWeight:
// //                                 FontWeight
// //                                     .w600,
// //                                 color: _text,
// //                               ),
// //                             ),
// //                           ),
// //                         ),
// //
// //                         const SizedBox(
// //                           height: 14,
// //                         ),
// //
// //                         // ==================================================
// //                         // MASTER DATA
// //                         // ==================================================
// //
// //                         DropdownButtonFormField<
// //                             String>(
// //                           value:
// //                           masters.any(
// //                                 (master) =>
// //                             master[
// //                             'master_id']
// //                                 ?.toString() ==
// //                                 selectedMasterId,
// //                           )
// //                               ? selectedMasterId
// //                               : null,
// //                           isExpanded: true,
// //                           menuMaxHeight: 360,
// //                           decoration:
// //                           const InputDecoration(
// //                             labelText:
// //                             'Audit Master Name *',
// //                             border:
// //                             OutlineInputBorder(),
// //                             prefixIcon:
// //                             Icon(
// //                               Icons
// //                                   .fact_check_outlined,
// //                             ),
// //                           ),
// //                           selectedItemBuilder:
// //                               (context) {
// //                             return masters
// //                                 .map(
// //                                   (
// //                                   master,
// //                                   ) {
// //                                 final name =
// //                                     master[
// //                                     'master_name']
// //                                         ?.toString()
// //                                         .trim() ??
// //                                         '';
// //
// //                                 return Align(
// //                                   alignment:
// //                                   Alignment
// //                                       .centerLeft,
// //                                   child: Text(
// //                                     name,
// //                                     maxLines:
// //                                     1,
// //                                     overflow:
// //                                     TextOverflow
// //                                         .ellipsis,
// //                                   ),
// //                                 );
// //                               },
// //                             ).toList();
// //                           },
// //                           items:
// //                           masters.map(
// //                                 (
// //                                 master,
// //                                 ) {
// //                               final name =
// //                                   master[
// //                                   'master_name']
// //                                       ?.toString()
// //                                       .trim() ??
// //                                       '';
// //
// //                               final type =
// //                                   master[
// //                                   'audit_type_name']
// //                                       ?.toString()
// //                                       .trim() ??
// //                                       '';
// //
// //                               return DropdownMenuItem<
// //                                   String>(
// //                                 value:
// //                                 master[
// //                                 'master_id']
// //                                     ?.toString(),
// //                                 child: SizedBox(
// //                                   width:
// //                                   double.infinity,
// //                                   child: Row(
// //                                     children: [
// //                                       Expanded(
// //                                         child:
// //                                         Text(
// //                                           name,
// //                                           maxLines:
// //                                           1,
// //                                           overflow:
// //                                           TextOverflow
// //                                               .ellipsis,
// //                                           style:
// //                                           const TextStyle(
// //                                             fontWeight:
// //                                             FontWeight
// //                                                 .w600,
// //                                           ),
// //                                         ),
// //                                       ),
// //                                       if (type
// //                                           .isNotEmpty) ...[
// //                                         const SizedBox(
// //                                           width:
// //                                           10,
// //                                         ),
// //                                         Flexible(
// //                                           child:
// //                                           Text(
// //                                             type,
// //                                             maxLines:
// //                                             1,
// //                                             overflow:
// //                                             TextOverflow
// //                                                 .ellipsis,
// //                                             style:
// //                                             const TextStyle(
// //                                               fontSize:
// //                                               11,
// //                                               color:
// //                                               _muted,
// //                                             ),
// //                                           ),
// //                                         ),
// //                                       ],
// //                                     ],
// //                                   ),
// //                                 ),
// //                               );
// //                             },
// //                           ).toList(),
// //                           onChanged:
// //                           dialogSaving
// //                               ? null
// //                               : (
// //                               value,
// //                               ) {
// //                             setDialogState(
// //                                   () {
// //                                 selectedMasterId =
// //                                     value;
// //                               },
// //                             );
// //                           },
// //                         ),
// //
// //                         const SizedBox(
// //                           height: 14,
// //                         ),
// //
// //                         // ==================================================
// //                         // AUDITOR
// //                         // ==================================================
// //
// //                         DropdownButtonFormField<
// //                             String>(
// //                           value:
// //                           auditors.any(
// //                                 (auditor) =>
// //                             auditor[
// //                             'auditor_id']
// //                                 ?.toString() ==
// //                                 selectedAuditorId,
// //                           )
// //                               ? selectedAuditorId
// //                               : null,
// //                           isExpanded: true,
// //                           menuMaxHeight: 360,
// //                           decoration:
// //                           const InputDecoration(
// //                             labelText:
// //                             'Assign Auditor *',
// //                             border:
// //                             OutlineInputBorder(),
// //                             prefixIcon:
// //                             Icon(
// //                               Icons
// //                                   .person_outline,
// //                             ),
// //                           ),
// //                           selectedItemBuilder:
// //                               (context) {
// //                             return auditors
// //                                 .map(
// //                                   (
// //                                   auditor,
// //                                   ) {
// //                                 final name =
// //                                     auditor[
// //                                     'auditor_name']
// //                                         ?.toString()
// //                                         .trim() ??
// //                                         '';
// //
// //                                 final employeeId =
// //                                     auditor[
// //                                     'employee_id']
// //                                         ?.toString()
// //                                         .trim() ??
// //                                         '';
// //
// //                                 return Align(
// //                                   alignment:
// //                                   Alignment
// //                                       .centerLeft,
// //                                   child: Text(
// //                                     employeeId
// //                                         .isEmpty
// //                                         ? name
// //                                         : '$name • $employeeId',
// //                                     maxLines:
// //                                     1,
// //                                     overflow:
// //                                     TextOverflow
// //                                         .ellipsis,
// //                                   ),
// //                                 );
// //                               },
// //                             ).toList();
// //                           },
// //                           items:
// //                           auditors.map(
// //                                 (
// //                                 auditor,
// //                                 ) {
// //                               final name =
// //                                   auditor[
// //                                   'auditor_name']
// //                                       ?.toString()
// //                                       .trim() ??
// //                                       '';
// //
// //                               final employeeId =
// //                                   auditor[
// //                                   'employee_id']
// //                                       ?.toString()
// //                                       .trim() ??
// //                                       '';
// //
// //                               final email =
// //                                   auditor[
// //                                   'email']
// //                                       ?.toString()
// //                                       .trim() ??
// //                                       '';
// //
// //                               return DropdownMenuItem<
// //                                   String>(
// //                                 value:
// //                                 auditor[
// //                                 'auditor_id']
// //                                     ?.toString(),
// //                                 child: SizedBox(
// //                                   width:
// //                                   double.infinity,
// //                                   child: Column(
// //                                     mainAxisAlignment:
// //                                     MainAxisAlignment
// //                                         .center,
// //                                     crossAxisAlignment:
// //                                     CrossAxisAlignment
// //                                         .start,
// //                                     children: [
// //                                       Text(
// //                                         employeeId
// //                                             .isEmpty
// //                                             ? name
// //                                             : '$name • $employeeId',
// //                                         maxLines:
// //                                         1,
// //                                         overflow:
// //                                         TextOverflow
// //                                             .ellipsis,
// //                                         style:
// //                                         const TextStyle(
// //                                           fontWeight:
// //                                           FontWeight
// //                                               .w600,
// //                                         ),
// //                                       ),
// //                                       if (email
// //                                           .isNotEmpty)
// //                                         Text(
// //                                           email,
// //                                           maxLines:
// //                                           1,
// //                                           overflow:
// //                                           TextOverflow
// //                                               .ellipsis,
// //                                           style:
// //                                           const TextStyle(
// //                                             fontSize:
// //                                             11,
// //                                             color:
// //                                             _muted,
// //                                           ),
// //                                         ),
// //                                     ],
// //                                   ),
// //                                 ),
// //                               );
// //                             },
// //                           ).toList(),
// //                           onChanged:
// //                           dialogSaving
// //                               ? null
// //                               : (
// //                               value,
// //                               ) {
// //                             setDialogState(
// //                                   () {
// //                                 selectedAuditorId =
// //                                     value;
// //                               },
// //                             );
// //                           },
// //                         ),
// //
// //                         const SizedBox(
// //                           height: 14,
// //                         ),
// //
// //                         // ==================================================
// //                         // STATUS
// //                         // ==================================================
// //
// //                         DropdownButtonFormField<
// //                             String>(
// //                           value:
// //                           selectedStatus,
// //                           isExpanded: true,
// //                           decoration:
// //                           const InputDecoration(
// //                             labelText:
// //                             'Status',
// //                             border:
// //                             OutlineInputBorder(),
// //                             prefixIcon:
// //                             Icon(
// //                               Icons
// //                                   .flag_outlined,
// //                             ),
// //                           ),
// //                           items: const [
// //                             DropdownMenuItem(
// //                               value:
// //                               'Planned',
// //                               child:
// //                               Text(
// //                                 'Planned',
// //                               ),
// //                             ),
// //                             DropdownMenuItem(
// //                               value:
// //                               'In Progress',
// //                               child:
// //                               Text(
// //                                 'In Progress',
// //                               ),
// //                             ),
// //                             DropdownMenuItem(
// //                               value:
// //                               'Completed',
// //                               child:
// //                               Text(
// //                                 'Completed',
// //                               ),
// //                             ),
// //                             DropdownMenuItem(
// //                               value:
// //                               'Cancelled',
// //                               child:
// //                               Text(
// //                                 'Cancelled',
// //                               ),
// //                             ),
// //                           ],
// //                           onChanged:
// //                           dialogSaving
// //                               ? null
// //                               : (
// //                               value,
// //                               ) {
// //                             if (value ==
// //                                 null) {
// //                               return;
// //                             }
// //
// //                             setDialogState(
// //                                   () {
// //                                 selectedStatus =
// //                                     value;
// //                               },
// //                             );
// //                           },
// //                         ),
// //
// //                         const SizedBox(
// //                           height: 14,
// //                         ),
// //
// //                         // ==================================================
// //                         // NOTES
// //                         // ==================================================
// //
// //                         TextField(
// //                           controller:
// //                           notesController,
// //                           maxLines: 3,
// //                           decoration:
// //                           const InputDecoration(
// //                             labelText:
// //                             'Notes',
// //                             hintText:
// //                             'Optional notes',
// //                             border:
// //                             OutlineInputBorder(),
// //                             prefixIcon:
// //                             Padding(
// //                               padding:
// //                               EdgeInsets.only(
// //                                 bottom: 36,
// //                               ),
// //                               child: Icon(
// //                                 Icons
// //                                     .notes_outlined,
// //                               ),
// //                             ),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //                 actions: [
// //                   TextButton(
// //                     onPressed:
// //                     dialogSaving
// //                         ? null
// //                         : () {
// //                       Navigator.pop(
// //                         dialogContext,
// //                       );
// //                     },
// //                     child: const Text(
// //                       'Cancel',
// //                     ),
// //                   ),
// //                   FilledButton.icon(
// //                     onPressed:
// //                     dialogSaving
// //                         ? null
// //                         : () async {
// //                       if (selectedMasterId ==
// //                           null ||
// //                           selectedMasterId!
// //                               .isEmpty) {
// //                         _dialogError(
// //                           dialogContext,
// //                           'Select an Audit Master Name.',
// //                         );
// //                         return;
// //                       }
// //
// //                       if (selectedAuditorId ==
// //                           null ||
// //                           selectedAuditorId!
// //                               .isEmpty) {
// //                         _dialogError(
// //                           dialogContext,
// //                           'Select an Auditor.',
// //                         );
// //                         return;
// //                       }
// //
// //                       Map<String,
// //                           dynamic>?
// //                       selectedMaster;
// //
// //                       for (final master
// //                       in masters) {
// //                         if (master[
// //                         'master_id']
// //                             ?.toString() ==
// //                             selectedMasterId) {
// //                           selectedMaster =
// //                               master;
// //                           break;
// //                         }
// //                       }
// //
// //                       Map<String,
// //                           dynamic>?
// //                       selectedAuditor;
// //
// //                       for (final auditor
// //                       in auditors) {
// //                         if (auditor[
// //                         'auditor_id']
// //                             ?.toString() ==
// //                             selectedAuditorId) {
// //                           selectedAuditor =
// //                               auditor;
// //                           break;
// //                         }
// //                       }
// //
// //                       if (selectedMaster ==
// //                           null) {
// //                         _dialogError(
// //                           dialogContext,
// //                           'Selected Audit Master could not be found.',
// //                         );
// //                         return;
// //                       }
// //
// //                       if (selectedAuditor ==
// //                           null) {
// //                         _dialogError(
// //                           dialogContext,
// //                           'Selected Auditor could not be found.',
// //                         );
// //                         return;
// //                       }
// //
// //                       final masterName =
// //                           selectedMaster[
// //                           'master_name']
// //                               ?.toString()
// //                               .trim() ??
// //                               '';
// //
// //                       final auditTypeId =
// //                       selectedMaster[
// //                       'audit_type_id']
// //                           ?.toString();
// //
// //                       final auditorName =
// //                           selectedAuditor[
// //                           'auditor_name']
// //                               ?.toString()
// //                               .trim() ??
// //                               '';
// //
// //                       final auditorEmail =
// //                           selectedAuditor[
// //                           'email']
// //                               ?.toString()
// //                               .trim() ??
// //                               '';
// //
// //                       if (masterName
// //                           .isEmpty) {
// //                         _dialogError(
// //                           dialogContext,
// //                           'Selected Audit Master is invalid.',
// //                         );
// //                         return;
// //                       }
// //
// //                       if (auditorName
// //                           .isEmpty) {
// //                         _dialogError(
// //                           dialogContext,
// //                           'Selected Auditor is invalid.',
// //                         );
// //                         return;
// //                       }
// //
// //                       setDialogState(
// //                             () {
// //                           dialogSaving =
// //                           true;
// //                         },
// //                       );
// //
// //                       try {
// //                         Map<String,
// //                             dynamic>
// //                         saved;
// //
// //                         if (isEditing) {
// //                           saved =
// //                           await SupabaseService
// //                               .updateAuditSchedule(
// //                             scheduleId:
// //                             existing[
// //                             'schedule_id']
// //                                 .toString(),
// //                             auditDate:
// //                             auditDate,
// //                             typeId:
// //                             auditTypeId,
// //                             masterId:
// //                             selectedMasterId,
// //                             masterDataName:
// //                             masterName,
// //                             auditorId:
// //                             selectedAuditorId,
// //                             auditorName:
// //                             auditorName,
// //                             auditorEmail:
// //                             auditorEmail,
// //                             status:
// //                             selectedStatus,
// //                             notes:
// //                             notesController
// //                                 .text
// //                                 .trim(),
// //                           ).timeout(
// //                             const Duration(
// //                               seconds: 20,
// //                             ),
// //                           );
// //                         } else {
// //                           saved =
// //                           await SupabaseService
// //                               .createAuditSchedule(
// //                             auditDate:
// //                             auditDate,
// //                             typeId:
// //                             auditTypeId,
// //                             masterId:
// //                             selectedMasterId,
// //                             masterDataName:
// //                             masterName,
// //                             auditorId:
// //                             selectedAuditorId,
// //                             auditorName:
// //                             auditorName,
// //                             auditorEmail:
// //                             auditorEmail,
// //                             status:
// //                             selectedStatus,
// //                             notes:
// //                             notesController
// //                                 .text
// //                                 .trim(),
// //                           ).timeout(
// //                             const Duration(
// //                               seconds: 20,
// //                             ),
// //                           );
// //                         }
// //
// //                         if (!mounted) {
// //                           return;
// //                         }
// //
// // // selectedMaster was already validated above.
// // // Copy the value into a non-null local before entering
// // // the setState closure so Dart's null-safety analysis
// // // does not lose the promotion.
// //                         final selectedAuditTypeName =
// //                             selectedMaster[
// //                             'audit_type_name']
// //                                 ?.toString()
// //                                 .trim() ??
// //                                 '';
// //
// //                         setState(() {
// //                           if (isEditing) {
// //                             final index =
// //                             _schedules.indexWhere(
// //                                   (
// //                                   item,
// //                                   ) =>
// //                               item[
// //                               'schedule_id']
// //                                   ?.toString() ==
// //                                   existing[
// //                                   'schedule_id']
// //                                       ?.toString(),
// //                             );
// //
// //                             if (index >= 0) {
// //                               _schedules[index] = {
// //                                 ..._schedules[index],
// //                                 ...saved,
// //                                 'audit_type':
// //                                 selectedAuditTypeName,
// //                               };
// //                             }
// //                           } else {
// //                             _schedules.add({
// //                               ...saved,
// //                               'audit_type':
// //                               selectedAuditTypeName,
// //                             });
// //                           }
// //
// //                           _saving = false;
// //                         });
// //                         if (!dialogContext
// //                             .mounted) {
// //                           return;
// //                         }
// //
// //                         Navigator.pop(
// //                           dialogContext,
// //                         );
// //
// //                         _message(
// //                           isEditing
// //                               ? 'Schedule updated successfully.'
// //                               : 'Audit scheduled successfully.',
// //                         );
// //                       } catch (e) {
// //                         if (!dialogContext
// //                             .mounted) {
// //                           return;
// //                         }
// //
// //                         setDialogState(
// //                               () {
// //                             dialogSaving =
// //                             false;
// //                           },
// //                         );
// //
// //                         _dialogError(
// //                           dialogContext,
// //                           'Unable to save schedule: $e',
// //                         );
// //                       }
// //                     },
// //                     icon: const Icon(
// //                       Icons
// //                           .check_circle_outline,
// //                     ),
// //                     label: Text(
// //                       isEditing
// //                           ? 'Update'
// //                           : 'Schedule',
// //                     ),
// //                   ),
// //                 ],
// //               );
// //             },
// //           );
// //         },
// //       );
// //     } finally {
// //       notesController.dispose();
// //
// //       if (mounted) {
// //         setState(() {
// //           _saving = false;
// //         });
// //       }
// //     }
// //   }
// //
// //   // ============================================================
// //   // STATUS UPDATE
// //   // ============================================================
// //
// //   Future<void> _updateStatus(
// //       Map<String, dynamic> schedule,
// //       String status,
// //       ) async {
// //     final id =
// //     schedule['schedule_id']
// //         ?.toString();
// //
// //     if (id == null || id.isEmpty) {
// //       return;
// //     }
// //
// //     final oldStatus =
// //     schedule['status']
// //         ?.toString();
// //
// //     if (oldStatus == status) {
// //       return;
// //     }
// //
// //     try {
// //       final updated =
// //       await SupabaseService
// //           .updateAuditScheduleStatus(
// //         scheduleId: id,
// //         status: status,
// //       ).timeout(
// //         const Duration(seconds: 20),
// //       );
// //
// //       if (!mounted) return;
// //
// //       final index =
// //       _schedules.indexWhere(
// //             (item) =>
// //         item['schedule_id']
// //             ?.toString() ==
// //             id,
// //       );
// //
// //       if (index >= 0) {
// //         setState(() {
// //           _schedules[index] = {
// //             ..._schedules[index],
// //             ...updated,
// //             'status': status,
// //           };
// //         });
// //       }
// //
// //       _message(
// //         'Schedule status updated.',
// //       );
// //     } catch (e) {
// //       if (!mounted) return;
// //
// //       _message(
// //         'Unable to update status: $e',
// //       );
// //     }
// //   }
// //
// //   // ============================================================
// //   // BUILD
// //   // ============================================================
// //
// //   @override
// //   Widget build(
// //       BuildContext context,
// //       ) {
// //     return Scaffold(
// //       backgroundColor:
// //       _background,
// //       appBar: AppBar(
// //         backgroundColor:
// //         Colors.white,
// //         foregroundColor:
// //         _text,
// //         elevation: 0,
// //         title: const Text(
// //           'Audit Schedule',
// //           style: TextStyle(
// //             fontWeight:
// //             FontWeight.w800,
// //           ),
// //         ),
// //         actions: [
// //           IconButton(
// //             tooltip: 'Refresh',
// //             onPressed:
// //             _loading
// //                 ? null
// //                 : _loadData,
// //             icon: const Icon(
// //               Icons.refresh_rounded,
// //             ),
// //           ),
// //           const SizedBox(
// //             width: 8,
// //           ),
// //         ],
// //       ),
// //       body: _loading
// //           ? const Center(
// //         child:
// //         CircularProgressIndicator(),
// //       )
// //           : _error != null
// //           ? _buildError()
// //           : _buildMainContent(),
// //       floatingActionButton:
// //       _loading
// //           ? null
// //           : null,
// //     );
// //   }
// //   List<Map<String, dynamic>>
// //   _getPlanningMasters() {
// //     if (_selectedPlanningTypeId ==
// //         null) {
// //       return [];
// //     }
// //
// //     final masterNames =
// //     <String>{};
// //
// //     final result =
// //     <Map<String, dynamic>>[];
// //
// //     for (final schedule in _schedules) {
// //       final typeId =
// //       schedule['type_id']
// //           ?.toString();
// //
// //       if (typeId !=
// //           _selectedPlanningTypeId) {
// //         continue;
// //       }
// //
// //       final date =
// //       _parseDate(
// //         schedule['audit_date'],
// //       );
// //
// //       if (date == null ||
// //           date.year !=
// //               _planningYear) {
// //         continue;
// //       }
// //
// //       final masterName =
// //           schedule['master_data_name']
// //               ?.toString()
// //               .trim() ??
// //               '';
// //
// //       if (masterName.isEmpty) {
// //         continue;
// //       }
// //
// //       if (masterNames
// //           .contains(masterName)) {
// //         continue;
// //       }
// //
// //       masterNames.add(masterName);
// //
// //       result.add({
// //         'master_data_name':
// //         masterName,
// //       });
// //     }
// //
// //     // Also include masters belonging to the
// //     // selected Audit Type even when there is
// //     // currently no schedule for them.
// //     for (final master in _masters) {
// //       final typeId =
// //       master['audit_type_id']
// //           ?.toString();
// //
// //       if (typeId !=
// //           _selectedPlanningTypeId) {
// //         continue;
// //       }
// //
// //       final masterName =
// //           master['master_name']
// //               ?.toString()
// //               .trim() ??
// //               '';
// //
// //       if (masterName.isEmpty ||
// //           masterNames
// //               .contains(masterName)) {
// //         continue;
// //       }
// //
// //       masterNames.add(masterName);
// //
// //       result.add({
// //         'master_data_name':
// //         masterName,
// //       });
// //     }
// //
// //     result.sort(
// //           (a, b) =>
// //           (a['master_data_name']
// //               ?.toString() ??
// //               '')
// //               .toLowerCase()
// //               .compareTo(
// //             (b['master_data_name']
// //                 ?.toString() ??
// //                 '')
// //                 .toLowerCase(),
// //           ),
// //     );
// //
// //     return result;
// //   }
// //
// //   List<Map<String, dynamic>>
// //   _getSchedulesForPlanningCell(
// //       String masterName,
// //       int month,
// //       ) {
// //     return _schedules.where(
// //           (schedule) {
// //         final typeId =
// //         schedule['type_id']
// //             ?.toString();
// //
// //         if (typeId !=
// //             _selectedPlanningTypeId) {
// //           return false;
// //         }
// //
// //         final name =
// //             schedule['master_data_name']
// //                 ?.toString()
// //                 .trim() ??
// //                 '';
// //
// //         if (name != masterName) {
// //           return false;
// //         }
// //
// //         final date =
// //         _parseDate(
// //           schedule['audit_date'],
// //         );
// //
// //         if (date == null) {
// //           return false;
// //         }
// //
// //         return date.year ==
// //             _planningYear &&
// //             date.month == month;
// //       },
// //     ).toList();
// //   }
// //
// //   String _planningCellSymbol(
// //       List<Map<String, dynamic>>
// //       schedules,
// //       ) {
// //     if (schedules.isEmpty) {
// //       return '';
// //     }
// //
// //     final hasCompleted =
// //     schedules.any(
// //           (schedule) =>
// //       schedule['status']
// //           ?.toString() ==
// //           'Completed',
// //     );
// //
// //     final hasInProgress =
// //     schedules.any(
// //           (schedule) =>
// //       schedule['status']
// //           ?.toString() ==
// //           'In Progress',
// //     );
// //
// //     final hasPlanned =
// //     schedules.any(
// //           (schedule) =>
// //       schedule['status']
// //           ?.toString() ==
// //           'Planned',
// //     );
// //
// //     if (hasCompleted) {
// //       return '✓✓';
// //     }
// //
// //     if (hasInProgress) {
// //       return '✓';
// //     }
// //
// //     if (hasPlanned) {
// //       return '✓';
// //     }
// //
// //     return '×';
// //   }
// //
// //   Color _planningCellColor(
// //       List<Map<String, dynamic>>
// //       schedules,
// //       ) {
// //     if (schedules.isEmpty) {
// //       return Colors.transparent;
// //     }
// //
// //     final hasCompleted =
// //     schedules.any(
// //           (schedule) =>
// //       schedule['status']
// //           ?.toString() ==
// //           'Completed',
// //     );
// //
// //     final hasCancelled =
// //     schedules.every(
// //           (schedule) =>
// //       schedule['status']
// //           ?.toString() ==
// //           'Cancelled',
// //     );
// //
// //     if (hasCompleted) {
// //       return const Color(
// //         0xFFE8F7EE,
// //       );
// //     }
// //
// //     if (hasCancelled) {
// //       return const Color(
// //         0xFFFDE8E8,
// //       );
// //     }
// //
// //     return const Color(
// //       0xFFF0E9FF,
// //     );
// //   }
// //
// //   Color _planningSymbolColor(
// //       List<Map<String, dynamic>>
// //       schedules,
// //       ) {
// //     if (schedules.isEmpty) {
// //       return const Color(
// //         0xFF6B7280,
// //       );
// //     }
// //
// //     final hasCompleted =
// //     schedules.any(
// //           (schedule) =>
// //       schedule['status']
// //           ?.toString() ==
// //           'Completed',
// //     );
// //
// //     final hasCancelled =
// //     schedules.every(
// //           (schedule) =>
// //       schedule['status']
// //           ?.toString() ==
// //           'Cancelled',
// //     );
// //
// //     if (hasCompleted) {
// //       return const Color(
// //         0xFF219653,
// //       );
// //     }
// //
// //     if (hasCancelled) {
// //       return const Color(
// //         0xFFD14343,
// //       );
// //     }
// //
// //     return _purple;
// //   }
// //   Widget _buildMainContent() {
// //     return Center(
// //       child: ConstrainedBox(
// //         constraints:
// //         const BoxConstraints(
// //           maxWidth: 1250,
// //         ),
// //         child: Column(
// //           children: [
// //             LayoutBuilder(
// //               builder:
// //                   (
// //                   context,
// //                   constraints,
// //                   ) {
// //                 if (constraints.maxWidth <
// //                     850) {
// //                   return Column(
// //                     children: [
// //                       _buildSmallCalendar(),
// //                       const SizedBox(
// //                         height: 18,
// //                       ),
// //                       _buildScheduledAudits(),
// //                     ],
// //                   );
// //                 }
// //
// //                 return Row(
// //                   crossAxisAlignment:
// //                   CrossAxisAlignment
// //                       .start,
// //                   children: [
// //                     SizedBox(
// //                       width: 420,
// //                       child:
// //                       _buildSmallCalendar(),
// //                     ),
// //                     const SizedBox(
// //                       width: 20,
// //                     ),
// //                     Expanded(
// //                       child:
// //                       _buildScheduledAudits(),
// //                     ),
// //                   ],
// //                 );
// //               },
// //             ),
// //
// //             // ==========================================================
// //             // YEARLY AUDIT PLANNING
// //             // ==========================================================
// //
// //             const SizedBox(
// //               height: 22,
// //             ),
// //
// //             _buildYearlyPlanning(),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ============================================================
// //   // SMALL CALENDAR
// //   // ============================================================
// //
// //   Widget _buildSmallCalendar() {
// //     final daysInMonth =
// //         DateTime(
// //           _displayedMonth.year,
// //           _displayedMonth.month + 1,
// //           0,
// //         ).day;
// //
// //     final firstWeekday =
// //         DateTime(
// //           _displayedMonth.year,
// //           _displayedMonth.month,
// //           1,
// //         ).weekday -
// //             1;
// //
// //     final cellCount =
// //         firstWeekday + daysInMonth;
// //
// //     final rowCount =
// //     (cellCount / 7).ceil();
// //
// //     return Container(
// //       decoration:
// //       BoxDecoration(
// //         color: Colors.white,
// //         borderRadius:
// //         BorderRadius.circular(
// //           18,
// //         ),
// //         border: Border.all(
// //           color:
// //           const Color(0xFFE1E5EC),
// //         ),
// //       ),
// //       padding:
// //       const EdgeInsets.all(18),
// //       child: Column(
// //         children: [
// //           Row(
// //             children: [
// //               IconButton(
// //                 tooltip:
// //                 'Previous month',
// //                 onPressed:
// //                 _previousMonth,
// //                 icon: const Icon(
// //                   Icons
// //                       .chevron_left_rounded,
// //                 ),
// //               ),
// //               Expanded(
// //                 child: Text(
// //                   _monthTitle(
// //                     _displayedMonth,
// //                   ),
// //                   textAlign:
// //                   TextAlign.center,
// //                   style:
// //                   const TextStyle(
// //                     fontSize: 18,
// //                     fontWeight:
// //                     FontWeight.w800,
// //                     color: _text,
// //                   ),
// //                 ),
// //               ),
// //               IconButton(
// //                 tooltip:
// //                 'Next month',
// //                 onPressed:
// //                 _nextMonth,
// //                 icon: const Icon(
// //                   Icons
// //                       .chevron_right_rounded,
// //                 ),
// //               ),
// //             ],
// //           ),
// //
// //           Row(
// //             children: const [
// //               _CalendarWeekDay('M'),
// //               _CalendarWeekDay('T'),
// //               _CalendarWeekDay('W'),
// //               _CalendarWeekDay('T'),
// //               _CalendarWeekDay('F'),
// //               _CalendarWeekDay('S'),
// //               _CalendarWeekDay('S'),
// //             ],
// //           ),
// //
// //           const SizedBox(
// //             height: 8,
// //           ),
// //
// //           GridView.builder(
// //             shrinkWrap: true,
// //             physics:
// //             const NeverScrollableScrollPhysics(),
// //             itemCount:
// //             rowCount * 7,
// //             gridDelegate:
// //             const SliverGridDelegateWithFixedCrossAxisCount(
// //               crossAxisCount: 7,
// //               childAspectRatio: 1.15,
// //             ),
// //             itemBuilder:
// //                 (
// //                 context,
// //                 index,
// //                 ) {
// //               if (index <
// //                   firstWeekday) {
// //                 return const SizedBox();
// //               }
// //
// //               final day =
// //                   index -
// //                       firstWeekday +
// //                       1;
// //
// //               if (day >
// //                   daysInMonth) {
// //                 return const SizedBox();
// //               }
// //
// //               final date =
// //               DateTime(
// //                 _displayedMonth
// //                     .year,
// //                 _displayedMonth
// //                     .month,
// //                 day,
// //               );
// //
// //               final schedules =
// //               _schedulesForDate(
// //                 date,
// //               );
// //
// //               final selected =
// //               _sameDate(
// //                 date,
// //                 _selectedDate,
// //               );
// //
// //               final today =
// //               _sameDate(
// //                 date,
// //                 DateTime.now(),
// //               );
// //
// //               return InkWell(
// //                 borderRadius:
// //                 BorderRadius.circular(
// //                   10,
// //                 ),
// //                 onTap: () {
// //                   setState(() {
// //                     _selectedDate =
// //                         date;
// //                   });
// //                 },
// //                 child: Container(
// //                   margin:
// //                   const EdgeInsets
// //                       .all(
// //                     2,
// //                   ),
// //                   decoration:
// //                   BoxDecoration(
// //                     color:
// //                     selected
// //                         ? const Color(
// //                       0xFFF0E9FF,
// //                     )
// //                         : Colors
// //                         .transparent,
// //                     borderRadius:
// //                     BorderRadius
// //                         .circular(
// //                       10,
// //                     ),
// //                     border:
// //                     today
// //                         ? Border.all(
// //                       color:
// //                       _purple,
// //                       width:
// //                       1.4,
// //                     )
// //                         : null,
// //                   ),
// //                   child: Column(
// //                     mainAxisAlignment:
// //                     MainAxisAlignment
// //                         .center,
// //                     children: [
// //                       Text(
// //                         '$day',
// //                         style:
// //                         TextStyle(
// //                           fontSize:
// //                           12,
// //                           fontWeight:
// //                           selected ||
// //                               today
// //                               ? FontWeight
// //                               .w800
// //                               : FontWeight
// //                               .w500,
// //                           color:
// //                           selected
// //                               ? _purple
// //                               : _text,
// //                         ),
// //                       ),
// //                       const SizedBox(
// //                         height: 3,
// //                       ),
// //                       if (schedules
// //                           .isNotEmpty)
// //                         _calendarIndicator(
// //                           schedules
// //                               .first[
// //                           'status']
// //                               ?.toString(),
// //                         ),
// //                     ],
// //                   ),
// //                 ),
// //               );
// //             },
// //           ),
// //
// //           const SizedBox(
// //             height: 14,
// //           ),
// //
// //           Row(
// //             mainAxisAlignment:
// //             MainAxisAlignment
// //                 .center,
// //             children: [
// //               _legend(
// //                 '✓',
// //                 'Planned',
// //               ),
// //               const SizedBox(
// //                 width: 14,
// //               ),
// //               _legend(
// //                 '•',
// //                 'In Progress',
// //               ),
// //               const SizedBox(
// //                 width: 14,
// //               ),
// //               _legend(
// //                 '✓✓',
// //                 'Completed',
// //               ),
// //               const SizedBox(
// //                 width: 14,
// //               ),
// //               _legend(
// //                 '×',
// //                 'Cancelled',
// //               ),
// //             ],
// //           ),
// //
// //           const SizedBox(
// //             height: 8,
// //           ),
// //
// //           TextButton(
// //             onPressed: _goToday,
// //             child:
// //             const Text(
// //               'Go to Today',
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _calendarIndicator(
// //       String? status,
// //       ) {
// //     String value;
// //
// //     switch (status) {
// //       case 'Completed':
// //         value = '✓✓';
// //         break;
// //
// //       case 'In Progress':
// //         value = '•';
// //         break;
// //
// //       case 'Cancelled':
// //         value = '×';
// //         break;
// //
// //       default:
// //         value = '✓';
// //     }
// //
// //     return Text(
// //       value,
// //       style:
// //       TextStyle(
// //         fontSize: 10,
// //         fontWeight:
// //         FontWeight.w900,
// //         color:
// //         _statusForeground(
// //           status ?? 'Planned',
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _legend(
// //       String symbol,
// //       String label,
// //       ) {
// //     return Row(
// //       mainAxisSize:
// //       MainAxisSize.min,
// //       children: [
// //         Text(
// //           symbol,
// //           style:
// //           const TextStyle(
// //             fontWeight:
// //             FontWeight.w900,
// //             color: _purple,
// //             fontSize: 12,
// //           ),
// //         ),
// //         const SizedBox(
// //           width: 4,
// //         ),
// //         Text(
// //           label,
// //           style:
// //           const TextStyle(
// //             color: _muted,
// //             fontSize: 10,
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   // ============================================================
// //   // SCHEDULED AUDITS
// //   // ============================================================
// //
// //   Widget _buildScheduledAudits() {
// //     final schedules =
// //     _schedulesForDate(
// //       _selectedDate,
// //     );
// //
// //     return Container(
// //       constraints:
// //       const BoxConstraints(
// //         minHeight: 390,
// //       ),
// //       decoration:
// //       BoxDecoration(
// //         color: Colors.white,
// //         borderRadius:
// //         BorderRadius.circular(
// //           18,
// //         ),
// //         border: Border.all(
// //           color:
// //           const Color(0xFFE1E5EC),
// //         ),
// //       ),
// //       child: Column(
// //         crossAxisAlignment:
// //         CrossAxisAlignment
// //             .stretch,
// //         children: [
// //           Padding(
// //             padding:
// //             const EdgeInsets.fromLTRB(
// //               20,
// //               18,
// //               14,
// //               16,
// //             ),
// //             child: Row(
// //               children: [
// //                 Expanded(
// //                   child: Column(
// //                     crossAxisAlignment:
// //                     CrossAxisAlignment
// //                         .start,
// //                     children: [
// //                       const Text(
// //                         'Scheduled Audits',
// //                         style:
// //                         TextStyle(
// //                           fontSize: 19,
// //                           fontWeight:
// //                           FontWeight.w800,
// //                           color: _text,
// //                         ),
// //                       ),
// //                       const SizedBox(
// //                         height: 4,
// //                       ),
// //                       Text(
// //                         _formatDate(
// //                           _selectedDate,
// //                         ),
// //                         style:
// //                         const TextStyle(
// //                           color: _muted,
// //                           fontSize: 12,
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //                 OutlinedButton.icon(
// //                   onPressed:
// //                   _saving
// //                       ? null
// //                       : _addSchedule,
// //                   icon:
// //                   const Icon(
// //                     Icons.add,
// //                     size: 18,
// //                   ),
// //                   label:
// //                   const Text(
// //                     'Schedule Audit',
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //
// //           const Divider(
// //             height: 1,
// //           ),
// //
// //           Expanded(
// //             child:
// //             schedules.isEmpty
// //                 ? _emptyScheduledAudits()
// //                 : ListView.separated(
// //               shrinkWrap: true,
// //               padding:
// //               const EdgeInsets
// //                   .all(
// //                 14,
// //               ),
// //               itemCount:
// //               schedules.length,
// //               separatorBuilder:
// //                   (
// //                   context,
// //                   index,
// //                   ) =>
// //               const SizedBox(
// //                 height: 10,
// //               ),
// //               itemBuilder:
// //                   (
// //                   context,
// //                   index,
// //                   ) {
// //                 return _buildScheduleCard(
// //                   schedules[index],
// //                 );
// //               },
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //   Widget _buildYearlyPlanning() {
// //     final masters =
// //     _getPlanningMasters();
// //
// //     const months = [
// //       'Jan',
// //       'Feb',
// //       'Mar',
// //       'Apr',
// //       'May',
// //       'Jun',
// //       'Jul',
// //       'Aug',
// //       'Sep',
// //       'Oct',
// //       'Nov',
// //       'Dec',
// //     ];
// //
// //     return Container(
// //       width: double.infinity,
// //       decoration:
// //       BoxDecoration(
// //         color: Colors.white,
// //         borderRadius:
// //         BorderRadius.circular(
// //           18,
// //         ),
// //         border: Border.all(
// //           color:
// //           const Color(
// //             0xFFE1E5EC,
// //           ),
// //         ),
// //       ),
// //       child: Column(
// //         crossAxisAlignment:
// //         CrossAxisAlignment
// //             .stretch,
// //         children: [
// //           // ========================================================
// //           // HEADER
// //           // ========================================================
// //
// //           Padding(
// //             padding:
// //             const EdgeInsets.fromLTRB(
// //               20,
// //               18,
// //               20,
// //               14,
// //             ),
// //             child: Row(
// //               children: [
// //                 Expanded(
// //                   child: Column(
// //                     crossAxisAlignment:
// //                     CrossAxisAlignment
// //                         .start,
// //                     children: [
// //                       const Text(
// //                         'Audit Planning',
// //                         style:
// //                         TextStyle(
// //                           fontSize: 19,
// //                           fontWeight:
// //                           FontWeight.w800,
// //                           color: _text,
// //                         ),
// //                       ),
// //                       const SizedBox(
// //                         height: 4,
// //                       ),
// //                       const Text(
// //                         'Yearly audit plan by Audit Master and month',
// //                         style:
// //                         TextStyle(
// //                           color: _muted,
// //                           fontSize: 12,
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //
// //                 // ==================================================
// //                 // AUDIT TYPE DROPDOWN
// //                 // ==================================================
// //
// //                 SizedBox(
// //                   width: 230,
// //                   child:
// //                   DropdownButtonFormField<
// //                       String>(
// //                     value:
// //                     _auditTypes.any(
// //                           (type) =>
// //                       type['type_id']
// //                           ?.toString() ==
// //                           _selectedPlanningTypeId,
// //                     )
// //                         ? _selectedPlanningTypeId
// //                         : null,
// //                     isExpanded: true,
// //                     decoration:
// //                     const InputDecoration(
// //                       labelText:
// //                       'Audit Type',
// //                       prefixIcon:
// //                       Icon(
// //                         Icons
// //                             .category_outlined,
// //                         size: 19,
// //                       ),
// //                       border:
// //                       OutlineInputBorder(),
// //                       contentPadding:
// //                       EdgeInsets
// //                           .symmetric(
// //                         horizontal: 12,
// //                         vertical: 10,
// //                       ),
// //                     ),
// //                     items:
// //                     _auditTypes.map(
// //                           (
// //                           type,
// //                           ) {
// //                         final id =
// //                         type['type_id']
// //                             ?.toString();
// //
// //                         final name =
// //                             type['audit_type']
// //                                 ?.toString()
// //                                 .trim() ??
// //                                 '';
// //
// //                         return DropdownMenuItem<
// //                             String>(
// //                           value: id,
// //                           child: Text(
// //                             name,
// //                             maxLines: 1,
// //                             overflow:
// //                             TextOverflow
// //                                 .ellipsis,
// //                           ),
// //                         );
// //                       },
// //                     ).toList(),
// //                     onChanged:
// //                         (
// //                         value,
// //                         ) {
// //                       setState(() {
// //                         _selectedPlanningTypeId =
// //                             value;
// //                       });
// //                     },
// //                   ),
// //                 ),
// //
// //                 const SizedBox(
// //                   width: 12,
// //                 ),
// //
// //                 // ==================================================
// //                 // YEAR
// //                 // ==================================================
// //
// //                 Container(
// //                   decoration:
// //                   BoxDecoration(
// //                     border: Border.all(
// //                       color:
// //                       const Color(
// //                         0xFFD9DDE5,
// //                       ),
// //                     ),
// //                     borderRadius:
// //                     BorderRadius
// //                         .circular(
// //                       10,
// //                     ),
// //                   ),
// //                   child: Row(
// //                     children: [
// //                       IconButton(
// //                         tooltip:
// //                         'Previous year',
// //                         onPressed:
// //                             () {
// //                           setState(() {
// //                             _planningYear--;
// //                           });
// //                         },
// //                         icon:
// //                         const Icon(
// //                           Icons
// //                               .chevron_left,
// //                           size: 19,
// //                         ),
// //                       ),
// //                       Text(
// //                         '$_planningYear',
// //                         style:
// //                         const TextStyle(
// //                           fontWeight:
// //                           FontWeight.w800,
// //                           color: _text,
// //                         ),
// //                       ),
// //                       IconButton(
// //                         tooltip:
// //                         'Next year',
// //                         onPressed:
// //                             () {
// //                           setState(() {
// //                             _planningYear++;
// //                           });
// //                         },
// //                         icon:
// //                         const Icon(
// //                           Icons
// //                               .chevron_right,
// //                           size: 19,
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //
// //           const Divider(
// //             height: 1,
// //           ),
// //
// //           // ========================================================
// //           // PLANNING TABLE
// //           // ========================================================
// //
// //           if (_auditTypes.isEmpty)
// //             const Padding(
// //               padding:
// //               EdgeInsets.all(
// //                 40,
// //               ),
// //               child: Center(
// //                 child: Text(
// //                   'No Audit Types available.',
// //                   style:
// //                   TextStyle(
// //                     color: _muted,
// //                   ),
// //                 ),
// //               ),
// //             )
// //           else if (_selectedPlanningTypeId ==
// //               null)
// //             const Padding(
// //               padding:
// //               EdgeInsets.all(
// //                 40,
// //               ),
// //               child: Center(
// //                 child: Text(
// //                   'Select an Audit Type to view the yearly plan.',
// //                   style:
// //                   TextStyle(
// //                     color: _muted,
// //                   ),
// //                 ),
// //               ),
// //             )
// //           else
// //             SingleChildScrollView(
// //               scrollDirection:
// //               Axis.horizontal,
// //               child: DataTable(
// //                 headingRowHeight:
// //                 48,
// //                 dataRowMinHeight:
// //                 54,
// //                 dataRowMaxHeight:
// //                 54,
// //                 horizontalMargin:
// //                 16,
// //                 columnSpacing:
// //                 12,
// //                 headingRowColor:
// //                 WidgetStateProperty
// //                     .resolveWith(
// //                       (
// //                       states,
// //                       ) =>
// //                   const Color(
// //                     0xFFF8F9FC,
// //                   ),
// //                 ),
// //                 columns: [
// //                   const DataColumn(
// //                     label: SizedBox(
// //                       width: 210,
// //                       child: Text(
// //                         'Audit Master',
// //                         style:
// //                         TextStyle(
// //                           fontWeight:
// //                           FontWeight.w800,
// //                           color: _text,
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                   ...months.map(
// //                         (
// //                         month,
// //                         ) {
// //                       return DataColumn(
// //                         label: SizedBox(
// //                           width: 58,
// //                           child: Center(
// //                             child: Text(
// //                               month,
// //                               style:
// //                               const TextStyle(
// //                                 fontWeight:
// //                                 FontWeight.w800,
// //                                 color:
// //                                 _text,
// //                               ),
// //                             ),
// //                           ),
// //                         ),
// //                       );
// //                     },
// //                   ),
// //                 ],
// //                 rows: masters.isEmpty
// //                     ? [
// //                   const DataRow(
// //                     cells: [
// //                       DataCell(
// //                         SizedBox(
// //                           width: 210,
// //                           child:
// //                           Text(
// //                             'No Audit Master Data',
// //                             style:
// //                             TextStyle(
// //                               color:
// //                               _muted,
// //                             ),
// //                           ),
// //                         ),
// //                       ),
// //                       DataCell(
// //                         SizedBox(),
// //                       ),
// //                       DataCell(
// //                         SizedBox(),
// //                       ),
// //                       DataCell(
// //                         SizedBox(),
// //                       ),
// //                       DataCell(
// //                         SizedBox(),
// //                       ),
// //                       DataCell(
// //                         SizedBox(),
// //                       ),
// //                       DataCell(
// //                         SizedBox(),
// //                       ),
// //                       DataCell(
// //                         SizedBox(),
// //                       ),
// //                       DataCell(
// //                         SizedBox(),
// //                       ),
// //                       DataCell(
// //                         SizedBox(),
// //                       ),
// //                       DataCell(
// //                         SizedBox(),
// //                       ),
// //                       DataCell(
// //                         SizedBox(),
// //                       ),
// //                       DataCell(
// //                         SizedBox(),
// //                       ),
// //                     ],
// //                   ),
// //                 ]
// //                     : masters.map(
// //                       (
// //                       master,
// //                       ) {
// //                     final masterName =
// //                         master[
// //                         'master_data_name']
// //                             ?.toString() ??
// //                             '';
// //
// //                     return DataRow(
// //                       cells: [
// //                         DataCell(
// //                           SizedBox(
// //                             width:
// //                             210,
// //                             child:
// //                             Text(
// //                               masterName,
// //                               maxLines:
// //                               1,
// //                               overflow:
// //                               TextOverflow
// //                                   .ellipsis,
// //                               style:
// //                               const TextStyle(
// //                                 fontWeight:
// //                                 FontWeight
// //                                     .w700,
// //                                 color:
// //                                 _text,
// //                               ),
// //                             ),
// //                           ),
// //                         ),
// //                         ...List.generate(
// //                           12,
// //                               (
// //                               index,
// //                               ) {
// //                             final month =
// //                                 index +
// //                                     1;
// //
// //                             final cellSchedules =
// //                             _getSchedulesForPlanningCell(
// //                               masterName,
// //                               month,
// //                             );
// //
// //                             final symbol =
// //                             _planningCellSymbol(
// //                               cellSchedules,
// //                             );
// //
// //                             return DataCell(
// //                               Center(
// //                                 child:
// //                                 Tooltip(
// //                                   message:
// //                                   cellSchedules.isEmpty
// //                                       ? 'No audit scheduled'
// //                                       : cellSchedules
// //                                       .map(
// //                                         (
// //                                         schedule,
// //                                         ) =>
// //                                     '${schedule['auditor_name'] ?? ''} • ${schedule['status'] ?? ''}',
// //                                   )
// //                                       .join(
// //                                     '\n',
// //                                   ),
// //                                   child:
// //                                   Container(
// //                                     width:
// //                                     38,
// //                                     height:
// //                                     32,
// //                                     alignment:
// //                                     Alignment
// //                                         .center,
// //                                     decoration:
// //                                     BoxDecoration(
// //                                       color:
// //                                       _planningCellColor(
// //                                         cellSchedules,
// //                                       ),
// //                                       borderRadius:
// //                                       BorderRadius
// //                                           .circular(
// //                                         8,
// //                                       ),
// //                                     ),
// //                                     child:
// //                                     Text(
// //                                       symbol,
// //                                       style:
// //                                       TextStyle(
// //                                         fontWeight:
// //                                         FontWeight
// //                                             .w900,
// //                                         fontSize:
// //                                         13,
// //                                         color:
// //                                         _planningSymbolColor(
// //                                           cellSchedules,
// //                                         ),
// //                                       ),
// //                                     ),
// //                                   ),
// //                                 ),
// //                               ),
// //                             );
// //                           },
// //                         ),
// //                       ],
// //                     );
// //                   },
// //                 ).toList(),
// //               ),
// //             ),
// //
// //           // ========================================================
// //           // LEGEND
// //           // ========================================================
// //
// //           Padding(
// //             padding:
// //             const EdgeInsets.fromLTRB(
// //               20,
// //               12,
// //               20,
// //               16,
// //             ),
// //             child: Row(
// //               children: [
// //                 _planningLegend(
// //                   '✓',
// //                   'Planned',
// //                 ),
// //                 const SizedBox(
// //                   width: 18,
// //                 ),
// //                 _planningLegend(
// //                   '✓',
// //                   'In Progress',
// //                 ),
// //                 const SizedBox(
// //                   width: 18,
// //                 ),
// //                 _planningLegend(
// //                   '✓✓',
// //                   'Completed',
// //                 ),
// //                 const SizedBox(
// //                   width: 18,
// //                 ),
// //                 _planningLegend(
// //                   '×',
// //                   'Cancelled',
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _planningLegend(
// //       String symbol,
// //       String label,
// //       ) {
// //     return Row(
// //       mainAxisSize:
// //       MainAxisSize.min,
// //       children: [
// //         Text(
// //           symbol,
// //           style:
// //           const TextStyle(
// //             fontSize: 12,
// //             fontWeight:
// //             FontWeight.w900,
// //             color: _purple,
// //           ),
// //         ),
// //         const SizedBox(
// //           width: 5,
// //         ),
// //         Text(
// //           label,
// //           style:
// //           const TextStyle(
// //             fontSize: 11,
// //             color: _muted,
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   Widget _emptyScheduledAudits() {
// //     return Center(
// //       child: Padding(
// //         padding:
// //         const EdgeInsets.all(
// //           35,
// //         ),
// //         child: Column(
// //           mainAxisSize:
// //           MainAxisSize.min,
// //           children: [
// //             Container(
// //               width: 58,
// //               height: 58,
// //               decoration:
// //               BoxDecoration(
// //                 color:
// //                 const Color(
// //                   0xFFF0E9FF,
// //                 ),
// //                 borderRadius:
// //                 BorderRadius.circular(
// //                   16,
// //                 ),
// //               ),
// //               child: const Icon(
// //                 Icons
// //                     .event_available_outlined,
// //                 color: _purple,
// //                 size: 28,
// //               ),
// //             ),
// //             const SizedBox(
// //               height: 12,
// //             ),
// //             const Text(
// //               'No audits scheduled',
// //               style:
// //               TextStyle(
// //                 fontSize: 16,
// //                 fontWeight:
// //                 FontWeight.w700,
// //                 color: _text,
// //               ),
// //             ),
// //             const SizedBox(
// //               height: 5,
// //             ),
// //             const Text(
// //               'Schedule an audit for this date.',
// //               textAlign:
// //               TextAlign.center,
// //               style:
// //               TextStyle(
// //                 color: _muted,
// //                 fontSize: 12,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildScheduleCard(
// //       Map<String, dynamic> schedule,
// //       ) {
// //     final status =
// //         schedule['status']
// //             ?.toString() ??
// //             'Planned';
// //
// //     final scheduleNumber =
// //         schedule['schedule_number']
// //             ?.toString() ??
// //             '';
// //
// //     final masterName =
// //         schedule['master_data_name']
// //             ?.toString() ??
// //             '';
// //
// //     final auditorName =
// //         schedule['auditor_name']
// //             ?.toString() ??
// //             '';
// //
// //     final auditorEmail =
// //         schedule['auditor_email']
// //             ?.toString() ??
// //             '';
// //
// //     final auditType =
// //         schedule['audit_type']
// //             ?.toString() ??
// //             schedule[
// //             'audit_type_name']
// //                 ?.toString() ??
// //             '';
// //
// //     return Container(
// //       padding:
// //       const EdgeInsets.all(
// //         14,
// //       ),
// //       decoration:
// //       BoxDecoration(
// //         color:
// //         const Color(0xFFFAFBFD),
// //         borderRadius:
// //         BorderRadius.circular(
// //           14,
// //         ),
// //         border: Border.all(
// //           color:
// //           const Color(0xFFE4E7ED),
// //         ),
// //       ),
// //       child: Row(
// //         crossAxisAlignment:
// //         CrossAxisAlignment
// //             .start,
// //         children: [
// //           Container(
// //             width: 42,
// //             height: 42,
// //             decoration:
// //             BoxDecoration(
// //               color:
// //               const Color(
// //                 0xFFF0E9FF,
// //               ),
// //               borderRadius:
// //               BorderRadius.circular(
// //                 12,
// //               ),
// //             ),
// //             child: Center(
// //               child:
// //               _calendarIndicator(
// //                 status,
// //               ),
// //             ),
// //           ),
// //
// //           const SizedBox(
// //             width: 12,
// //           ),
// //
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment:
// //               CrossAxisAlignment
// //                   .start,
// //               children: [
// //                 Row(
// //                   children: [
// //                     Expanded(
// //                       child: Text(
// //                         scheduleNumber,
// //                         maxLines: 1,
// //                         overflow:
// //                         TextOverflow
// //                             .ellipsis,
// //                         style:
// //                         const TextStyle(
// //                           fontWeight:
// //                           FontWeight.w800,
// //                           color: _text,
// //                           fontSize: 13,
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(
// //                       width: 8,
// //                     ),
// //                     _statusBadge(
// //                       status,
// //                     ),
// //                   ],
// //                 ),
// //
// //                 const SizedBox(
// //                   height: 5,
// //                 ),
// //
// //                 Text(
// //                   masterName,
// //                   maxLines: 1,
// //                   overflow:
// //                   TextOverflow.ellipsis,
// //                   style:
// //                   const TextStyle(
// //                     fontWeight:
// //                     FontWeight.w700,
// //                     color: _text,
// //                     fontSize: 14,
// //                   ),
// //                 ),
// //
// //                 if (auditType
// //                     .trim()
// //                     .isNotEmpty) ...[
// //                   const SizedBox(
// //                     height: 2,
// //                   ),
// //                   Text(
// //                     auditType,
// //                     maxLines: 1,
// //                     overflow:
// //                     TextOverflow
// //                         .ellipsis,
// //                     style:
// //                     const TextStyle(
// //                       color: _muted,
// //                       fontSize: 11,
// //                     ),
// //                   ),
// //                 ],
// //
// //                 const SizedBox(
// //                   height: 7,
// //                 ),
// //
// //                 Wrap(
// //                   spacing: 14,
// //                   runSpacing: 4,
// //                   children: [
// //                     _smallDetail(
// //                       Icons
// //                           .person_outline,
// //                       auditorName,
// //                     ),
// //                     if (auditorEmail
// //                         .trim()
// //                         .isNotEmpty)
// //                       _smallDetail(
// //                         Icons
// //                             .mail_outline,
// //                         auditorEmail,
// //                       ),
// //                   ],
// //                 ),
// //               ],
// //             ),
// //           ),
// //
// //           const SizedBox(
// //             width: 8,
// //           ),
// //
// //           PopupMenuButton<String>(
// //             tooltip:
// //             'Schedule actions',
// //             onSelected:
// //                 (value) {
// //               if (value == 'edit') {
// //                 _editSchedule(
// //                   schedule,
// //                 );
// //               }
// //
// //               if (value == 'delete') {
// //                 _deleteSchedule(
// //                   schedule,
// //                 );
// //               }
// //             },
// //             itemBuilder:
// //                 (context) => const [
// //               PopupMenuItem(
// //                 value: 'edit',
// //                 child: Row(
// //                   children: [
// //                     Icon(
// //                       Icons
// //                           .edit_outlined,
// //                       size: 18,
// //                     ),
// //                     SizedBox(
// //                       width: 10,
// //                     ),
// //                     Text(
// //                       'Edit',
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //               PopupMenuItem(
// //                 value: 'delete',
// //                 child: Row(
// //                   children: [
// //                     Icon(
// //                       Icons
// //                           .delete_outline,
// //                       size: 18,
// //                     ),
// //                     SizedBox(
// //                       width: 10,
// //                     ),
// //                     Text(
// //                       'Delete',
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _smallDetail(
// //       IconData icon,
// //       String text,
// //       ) {
// //     return Row(
// //       mainAxisSize:
// //       MainAxisSize.min,
// //       children: [
// //         Icon(
// //           icon,
// //           size: 14,
// //           color: _muted,
// //         ),
// //         const SizedBox(
// //           width: 4,
// //         ),
// //         ConstrainedBox(
// //           constraints:
// //           const BoxConstraints(
// //             maxWidth: 220,
// //           ),
// //           child: Text(
// //             text,
// //             maxLines: 1,
// //             overflow:
// //             TextOverflow.ellipsis,
// //             style:
// //             const TextStyle(
// //               fontSize: 11,
// //               color: _muted,
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   Widget _statusBadge(
// //       String status,
// //       ) {
// //     return Container(
// //       padding:
// //       const EdgeInsets.symmetric(
// //         horizontal: 8,
// //         vertical: 4,
// //       ),
// //       decoration:
// //       BoxDecoration(
// //         color:
// //         _statusBackground(
// //           status,
// //         ),
// //         borderRadius:
// //         BorderRadius.circular(
// //           20,
// //         ),
// //       ),
// //       child: Text(
// //         status,
// //         style:
// //         TextStyle(
// //           fontSize: 10,
// //           fontWeight:
// //           FontWeight.w700,
// //           color:
// //           _statusForeground(
// //             status,
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Color _statusBackground(
// //       String status,
// //       ) {
// //     switch (status) {
// //       case 'Completed':
// //         return const Color(
// //           0xFFE8F7EE,
// //         );
// //
// //       case 'In Progress':
// //         return const Color(
// //           0xFFFFF3D9,
// //         );
// //
// //       case 'Cancelled':
// //         return const Color(
// //           0xFFFDE8E8,
// //         );
// //
// //       default:
// //         return const Color(
// //           0xFFF0E9FF,
// //         );
// //     }
// //   }
// //
// //   Color _statusForeground(
// //       String status,
// //       ) {
// //     switch (status) {
// //       case 'Completed':
// //         return const Color(
// //           0xFF219653,
// //         );
// //
// //       case 'In Progress':
// //         return const Color(
// //           0xFFB77900,
// //         );
// //
// //       case 'Cancelled':
// //         return const Color(
// //           0xFFD14343,
// //         );
// //
// //       default:
// //         return _purple;
// //     }
// //   }
// //
// //   // ============================================================
// //   // ERROR / MESSAGE
// //   // ============================================================
// //
// //   Widget _buildError() {
// //     return Center(
// //       child: Container(
// //         constraints:
// //         const BoxConstraints(
// //           maxWidth: 620,
// //         ),
// //         margin:
// //         const EdgeInsets.all(
// //           24,
// //         ),
// //         padding:
// //         const EdgeInsets.all(
// //           28,
// //         ),
// //         decoration:
// //         BoxDecoration(
// //           color: Colors.white,
// //           borderRadius:
// //           BorderRadius.circular(
// //             18,
// //           ),
// //           border: Border.all(
// //             color:
// //             const Color(
// //               0xFFE1E5EC,
// //             ),
// //           ),
// //         ),
// //         child: Column(
// //           mainAxisSize:
// //           MainAxisSize.min,
// //           children: [
// //             Icon(
// //               Icons
// //                   .error_outline_rounded,
// //               size: 48,
// //               color:
// //               Colors.red.shade400,
// //             ),
// //             const SizedBox(
// //               height: 14,
// //             ),
// //             const Text(
// //               'Unable to load Audit Schedule',
// //               style:
// //               TextStyle(
// //                 fontSize: 18,
// //                 fontWeight:
// //                 FontWeight.w800,
// //                 color: _text,
// //               ),
// //             ),
// //             const SizedBox(
// //               height: 8,
// //             ),
// //             Text(
// //               _error ?? '',
// //               textAlign:
// //               TextAlign.center,
// //               style:
// //               const TextStyle(
// //                 color: _muted,
// //               ),
// //             ),
// //             const SizedBox(
// //               height: 18,
// //             ),
// //             FilledButton.icon(
// //               onPressed:
// //               _loadData,
// //               icon: const Icon(
// //                 Icons.refresh,
// //               ),
// //               label:
// //               const Text(
// //                 'Retry',
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   void _message(
// //       String message,
// //       ) {
// //     if (!mounted) return;
// //
// //     ScaffoldMessenger.of(context)
// //         .showSnackBar(
// //       SnackBar(
// //         content: Text(
// //           message,
// //         ),
// //         behavior:
// //         SnackBarBehavior.floating,
// //       ),
// //     );
// //   }
// //
// //   void _dialogError(
// //       BuildContext context,
// //       String message,
// //       ) {
// //     ScaffoldMessenger.of(context)
// //         .showSnackBar(
// //       SnackBar(
// //         content: Text(
// //           message,
// //         ),
// //         behavior:
// //         SnackBarBehavior.floating,
// //       ),
// //     );
// //   }
// // }
// //
// // // ============================================================
// // // CALENDAR WEEK DAY
// // // ============================================================
// //
// // class _CalendarWeekDay
// //     extends StatelessWidget {
// //   final String label;
// //
// //   const _CalendarWeekDay(
// //       this.label,
// //       );
// //
// //   @override
// //   Widget build(
// //       BuildContext context,
// //       ) {
// //     return Expanded(
// //       child: Center(
// //         child: Text(
// //           label,
// //           style:
// //           const TextStyle(
// //             fontSize: 11,
// //             fontWeight:
// //             FontWeight.w700,
// //             color:
// //             Color(0xFF6B7280),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
//
// import 'package:flutter/material.dart';
//
// import '../../services/supabase_service.dart';
//
// class AuditScheduleScreen extends StatefulWidget {
//   final String sessionToken;
//
//   const AuditScheduleScreen({
//     super.key,
//     required this.sessionToken,
//   });
//
//   @override
//   State<AuditScheduleScreen> createState() =>
//       _AuditScheduleScreenState();
// }
//
// class _AuditScheduleScreenState
//     extends State<AuditScheduleScreen> {
//   static const Color _background =
//   Color(0xFFF5F7FB);
//
//   static const Color _purple =
//   Color(0xFF7656C6);
//
//   static const Color _text =
//   Color(0xFF172033);
//
//   static const Color _muted =
//   Color(0xFF6B7280);
//
//   bool _loading = true;
//   bool _saving = false;
//
//   String? _error;
//
//   DateTime _selectedDate =
//   _dateOnly(DateTime.now());
//
//   DateTime _displayedMonth = DateTime(
//     DateTime.now().year,
//     DateTime.now().month,
//   );
//
//   List<Map<String, dynamic>> _schedules =
//   [];
//
//   List<Map<String, dynamic>> _auditors =
//   [];
//
//   List<Map<String, dynamic>> _masters =
//   [];
//   List<Map<String, dynamic>> _auditTypes =
//   [];
//
//   String? _selectedPlanningTypeId;
//
//   int _planningYear =
//       DateTime.now().year;
//
//   static DateTime _dateOnly(
//       DateTime value,
//       ) {
//     return DateTime(
//       value.year,
//       value.month,
//       value.day,
//     );
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }
//
//   // ============================================================
//   // LOAD DATA
//   // ============================================================
//
//   Future<void> _loadData() async {
//     if (!mounted) return;
//
//     setState(() {
//       _loading = true;
//       _error = null;
//     });
//
//     try {
//       final results = await Future.wait([
//         SupabaseService.getAllAuditSchedules()
//             .timeout(
//           const Duration(seconds: 20),
//         ),
//         SupabaseService.getActiveAuditors()
//             .timeout(
//           const Duration(seconds: 20),
//         ),
//         SupabaseService.getAdminAuditMasterData(
//           sessionToken:
//           widget.sessionToken,
//         ).timeout(
//           const Duration(seconds: 20),
//         ),
//         SupabaseService.getActiveAuditTypes()
//             .timeout(
//           const Duration(seconds: 20),
//         ),
//       ]);
//
//       if (!mounted) return;
//
//       final schedules =
//       List<Map<String, dynamic>>.from(
//         results[0] as List,
//       );
//
//       final auditors =
//       List<Map<String, dynamic>>.from(
//         results[1] as List,
//       );
//
//       final masters =
//       List<Map<String, dynamic>>.from(
//         results[2] as List,
//       );
//       final auditTypes =
//       List<Map<String, dynamic>>.from(
//         results[3] as List,
//       );
//       setState(() {
//         _schedules = schedules;
//         _auditors = auditors;
//         _masters = masters;
//         _auditTypes = auditTypes;
//
//         if (_selectedPlanningTypeId == null &&
//             _auditTypes.isNotEmpty) {
//           _selectedPlanningTypeId =
//               _auditTypes.first['type_id']
//                   ?.toString();
//         }
//
//         _loading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//
//       setState(() {
//         _loading = false;
//         _error = e.toString();
//       });
//     }
//   }
//
//   // ============================================================
//   // DATE HELPERS
//   // ============================================================
//
//   DateTime? _parseDate(dynamic value) {
//     if (value == null) {
//       return null;
//     }
//
//     try {
//       return _dateOnly(
//         DateTime.parse(
//           value.toString(),
//         ),
//       );
//     } catch (_) {
//       return null;
//     }
//   }
//
//   bool _sameDate(
//       DateTime first,
//       DateTime second,
//       ) {
//     return first.year == second.year &&
//         first.month == second.month &&
//         first.day == second.day;
//   }
//
//   String _formatDate(
//       DateTime date,
//       ) {
//     return '${date.day.toString().padLeft(2, '0')}/'
//         '${date.month.toString().padLeft(2, '0')}/'
//         '${date.year}';
//   }
//
//   String _monthTitle(
//       DateTime date,
//       ) {
//     const months = [
//       'January',
//       'February',
//       'March',
//       'April',
//       'May',
//       'June',
//       'July',
//       'August',
//       'September',
//       'October',
//       'November',
//       'December',
//     ];
//
//     return '${months[date.month - 1]} ${date.year}';
//   }
//
//   List<Map<String, dynamic>>
//   _schedulesForDate(
//       DateTime date,
//       ) {
//     return _schedules.where(
//           (schedule) {
//         final scheduleDate =
//         _parseDate(
//           schedule['audit_date'],
//         );
//
//         if (scheduleDate == null) {
//           return false;
//         }
//
//         return _sameDate(
//           scheduleDate,
//           date,
//         );
//       },
//     ).toList();
//   }
//
//   // ============================================================
//   // CALENDAR NAVIGATION
//   // ============================================================
//
//   void _previousMonth() {
//     setState(() {
//       _displayedMonth = DateTime(
//         _displayedMonth.year,
//         _displayedMonth.month - 1,
//       );
//     });
//   }
//
//   void _nextMonth() {
//     setState(() {
//       _displayedMonth = DateTime(
//         _displayedMonth.year,
//         _displayedMonth.month + 1,
//       );
//     });
//   }
//
//   void _goToday() {
//     final today =
//     _dateOnly(DateTime.now());
//
//     setState(() {
//       _selectedDate = today;
//
//       _displayedMonth = DateTime(
//         today.year,
//         today.month,
//       );
//     });
//   }
//
//   // ============================================================
//   // ADD SCHEDULE
//   // ============================================================
//
//   Future<void> _addSchedule() async {
//     if (_auditors.isEmpty) {
//       _message(
//         'No active auditors are available. Add an auditor first.',
//       );
//       return;
//     }
//
//     final activeMasters =
//     _masters.where(
//           (master) {
//         final active =
//         master['active'];
//
//         return active == true ||
//             active == null;
//       },
//     ).toList();
//
//     if (activeMasters.isEmpty) {
//       _message(
//         'No active Audit Master Data is available.',
//       );
//       return;
//     }
//
//     await _showScheduleDialog(
//       selectedDate: _selectedDate,
//     );
//   }
//
//   // ============================================================
//   // EDIT SCHEDULE
//   // ============================================================
//
//   Future<void> _editSchedule(
//       Map<String, dynamic> schedule,
//       ) async {
//     final scheduleDate =
//     _parseDate(
//       schedule['audit_date'],
//     );
//
//     await _showScheduleDialog(
//       existing: schedule,
//       selectedDate:
//       scheduleDate ?? _selectedDate,
//     );
//   }
//
//   // ============================================================
//   // DELETE SCHEDULE
//   // ============================================================
//
//   Future<void> _deleteSchedule(
//       Map<String, dynamic> schedule,
//       ) async {
//     final scheduleId =
//     schedule['schedule_id']
//         ?.toString();
//
//     if (scheduleId == null ||
//         scheduleId.isEmpty) {
//       _message(
//         'Schedule ID is missing.',
//       );
//       return;
//     }
//
//     final scheduleNumber =
//         schedule['schedule_number']
//             ?.toString() ??
//             'this schedule';
//
//     final confirmed =
//     await showDialog<bool>(
//       context: context,
//       builder: (
//           dialogContext,
//           ) {
//         return AlertDialog(
//           title: const Text(
//             'Delete Schedule',
//           ),
//           content: Text(
//             'Delete "$scheduleNumber"?',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(
//                   dialogContext,
//                   false,
//                 );
//               },
//               child: const Text(
//                 'Cancel',
//               ),
//             ),
//             FilledButton(
//               onPressed: () {
//                 Navigator.pop(
//                   dialogContext,
//                   true,
//                 );
//               },
//               child: const Text(
//                 'Delete',
//               ),
//             ),
//           ],
//         );
//       },
//     );
//
//     if (confirmed != true) {
//       return;
//     }
//
//     setState(() {
//       _saving = true;
//     });
//
//     try {
//       await SupabaseService
//           .deleteAuditSchedule(
//         scheduleId: scheduleId,
//       ).timeout(
//         const Duration(seconds: 20),
//       );
//
//       if (!mounted) return;
//
//       setState(() {
//         _schedules.removeWhere(
//               (item) =>
//           item['schedule_id']
//               ?.toString() ==
//               scheduleId,
//         );
//
//         _saving = false;
//       });
//
//       _message(
//         'Schedule deleted successfully.',
//       );
//     } catch (e) {
//       if (!mounted) return;
//
//       setState(() {
//         _saving = false;
//       });
//
//       _message(
//         'Unable to delete schedule: $e',
//       );
//     }
//   }
//
//   // ============================================================
//   // SCHEDULE DIALOG
//   // ============================================================
//
//   Future<void> _showScheduleDialog({
//     Map<String, dynamic>? existing,
//     required DateTime selectedDate,
//   }) async {
//     final isEditing =
//         existing != null;
//
//     DateTime auditDate =
//         _parseDate(
//           existing?['audit_date'],
//         ) ??
//             selectedDate;
//
//     String? selectedMasterId =
//     existing?['master_id']
//         ?.toString();
//
//     String? selectedAuditorId =
//     existing?['auditor_id']
//         ?.toString();
//
//     String selectedStatus =
//         existing?['status']
//             ?.toString() ??
//             'Planned';
//
//     final notesController =
//     TextEditingController(
//       text:
//       existing?['notes']
//           ?.toString() ??
//           '',
//     );
//
//     bool dialogSaving = false;
//
//     try {
//       await showDialog<void>(
//         context: context,
//         barrierDismissible: false,
//         builder: (
//             dialogContext,
//             ) {
//           return StatefulBuilder(
//             builder: (
//                 context,
//                 setDialogState,
//                 ) {
//               /*
//                * IMPORTANT:
//                *
//                * getActiveAuditors() already returns
//                * ONLY active auditors.
//                *
//                * Therefore DO NOT filter using
//                * auditor['active'] here.
//                */
//               final auditors =
//               List<Map<String, dynamic>>.from(
//                 _auditors,
//               );
//
//               final masters =
//               _masters.where(
//                     (master) {
//                   final active =
//                   master['active'];
//
//                   return active == true ||
//                       active == null;
//                 },
//               ).toList();
//
//               return AlertDialog(
//                 shape:
//                 RoundedRectangleBorder(
//                   borderRadius:
//                   BorderRadius.circular(
//                     20,
//                   ),
//                 ),
//                 titlePadding:
//                 const EdgeInsets.fromLTRB(
//                   24,
//                   22,
//                   24,
//                   10,
//                 ),
//                 contentPadding:
//                 const EdgeInsets.fromLTRB(
//                   24,
//                   10,
//                   24,
//                   4,
//                 ),
//                 actionsPadding:
//                 const EdgeInsets.fromLTRB(
//                   24,
//                   4,
//                   24,
//                   18,
//                 ),
//                 title: Row(
//                   children: [
//                     Container(
//                       width: 42,
//                       height: 42,
//                       decoration:
//                       BoxDecoration(
//                         color:
//                         const Color(
//                           0xFFF0E9FF,
//                         ),
//                         borderRadius:
//                         BorderRadius
//                             .circular(
//                           12,
//                         ),
//                       ),
//                       child: const Icon(
//                         Icons
//                             .calendar_month_outlined,
//                         color: _purple,
//                       ),
//                     ),
//                     const SizedBox(
//                       width: 12,
//                     ),
//                     Text(
//                       isEditing
//                           ? 'Edit Schedule'
//                           : 'Schedule Audit',
//                       style:
//                       const TextStyle(
//                         fontWeight:
//                         FontWeight.w800,
//                         color: _text,
//                       ),
//                     ),
//                   ],
//                 ),
//                 content: SizedBox(
//                   width: 540,
//                   child:
//                   SingleChildScrollView(
//                     child: Column(
//                       mainAxisSize:
//                       MainAxisSize.min,
//                       children: [
//                         // ==================================================
//                         // DATE
//                         // ==================================================
//
//                         InkWell(
//                           borderRadius:
//                           BorderRadius
//                               .circular(
//                             10,
//                           ),
//                           onTap:
//                           dialogSaving
//                               ? null
//                               : () async {
//                             final picked =
//                             await showDatePicker(
//                               context:
//                               context,
//                               initialDate:
//                               auditDate,
//                               firstDate:
//                               DateTime(
//                                 2020,
//                               ),
//                               lastDate:
//                               DateTime(
//                                 2100,
//                               ),
//                             );
//
//                             if (picked ==
//                                 null) {
//                               return;
//                             }
//
//                             setDialogState(
//                                   () {
//                                 auditDate =
//                                     picked;
//                               },
//                             );
//                           },
//                           child:
//                           InputDecorator(
//                             decoration:
//                             const InputDecoration(
//                               labelText:
//                               'Audit Date *',
//                               border:
//                               OutlineInputBorder(),
//                               prefixIcon:
//                               Icon(
//                                 Icons
//                                     .calendar_today_outlined,
//                               ),
//                             ),
//                             child: Text(
//                               _formatDate(
//                                 auditDate,
//                               ),
//                               style:
//                               const TextStyle(
//                                 fontWeight:
//                                 FontWeight
//                                     .w600,
//                                 color: _text,
//                               ),
//                             ),
//                           ),
//                         ),
//
//                         const SizedBox(
//                           height: 14,
//                         ),
//
//                         // ==================================================
//                         // MASTER DATA
//                         // ==================================================
//
//                         DropdownButtonFormField<
//                             String>(
//                           value:
//                           masters.any(
//                                 (master) =>
//                             master[
//                             'master_id']
//                                 ?.toString() ==
//                                 selectedMasterId,
//                           )
//                               ? selectedMasterId
//                               : null,
//                           isExpanded: true,
//                           menuMaxHeight: 360,
//                           decoration:
//                           const InputDecoration(
//                             labelText:
//                             'Audit Master Name *',
//                             border:
//                             OutlineInputBorder(),
//                             prefixIcon:
//                             Icon(
//                               Icons
//                                   .fact_check_outlined,
//                             ),
//                           ),
//                           selectedItemBuilder:
//                               (context) {
//                             return masters
//                                 .map(
//                                   (
//                                   master,
//                                   ) {
//                                 final name =
//                                     master[
//                                     'master_name']
//                                         ?.toString()
//                                         .trim() ??
//                                         '';
//
//                                 return Align(
//                                   alignment:
//                                   Alignment
//                                       .centerLeft,
//                                   child: Text(
//                                     name,
//                                     maxLines:
//                                     1,
//                                     overflow:
//                                     TextOverflow
//                                         .ellipsis,
//                                   ),
//                                 );
//                               },
//                             ).toList();
//                           },
//                           items:
//                           masters.map(
//                                 (
//                                 master,
//                                 ) {
//                               final name =
//                                   master[
//                                   'master_name']
//                                       ?.toString()
//                                       .trim() ??
//                                       '';
//
//                               final type =
//                                   master[
//                                   'audit_type_name']
//                                       ?.toString()
//                                       .trim() ??
//                                       '';
//
//                               return DropdownMenuItem<
//                                   String>(
//                                 value:
//                                 master[
//                                 'master_id']
//                                     ?.toString(),
//                                 child: SizedBox(
//                                   width:
//                                   double.infinity,
//                                   child: Row(
//                                     children: [
//                                       Expanded(
//                                         child:
//                                         Text(
//                                           name,
//                                           maxLines:
//                                           1,
//                                           overflow:
//                                           TextOverflow
//                                               .ellipsis,
//                                           style:
//                                           const TextStyle(
//                                             fontWeight:
//                                             FontWeight
//                                                 .w600,
//                                           ),
//                                         ),
//                                       ),
//                                       if (type
//                                           .isNotEmpty) ...[
//                                         const SizedBox(
//                                           width:
//                                           10,
//                                         ),
//                                         Flexible(
//                                           child:
//                                           Text(
//                                             type,
//                                             maxLines:
//                                             1,
//                                             overflow:
//                                             TextOverflow
//                                                 .ellipsis,
//                                             style:
//                                             const TextStyle(
//                                               fontSize:
//                                               11,
//                                               color:
//                                               _muted,
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           ).toList(),
//                           onChanged:
//                           dialogSaving
//                               ? null
//                               : (
//                               value,
//                               ) {
//                             setDialogState(
//                                   () {
//                                 selectedMasterId =
//                                     value;
//                               },
//                             );
//                           },
//                         ),
//
//                         const SizedBox(
//                           height: 14,
//                         ),
//
//                         // ==================================================
//                         // AUDITOR
//                         // ==================================================
//
//                         DropdownButtonFormField<
//                             String>(
//                           value:
//                           auditors.any(
//                                 (auditor) =>
//                             auditor[
//                             'auditor_id']
//                                 ?.toString() ==
//                                 selectedAuditorId,
//                           )
//                               ? selectedAuditorId
//                               : null,
//                           isExpanded: true,
//                           menuMaxHeight: 360,
//                           decoration:
//                           const InputDecoration(
//                             labelText:
//                             'Assign Auditor *',
//                             border:
//                             OutlineInputBorder(),
//                             prefixIcon:
//                             Icon(
//                               Icons
//                                   .person_outline,
//                             ),
//                           ),
//                           selectedItemBuilder:
//                               (context) {
//                             return auditors
//                                 .map(
//                                   (
//                                   auditor,
//                                   ) {
//                                 final name =
//                                     auditor[
//                                     'auditor_name']
//                                         ?.toString()
//                                         .trim() ??
//                                         '';
//
//                                 final employeeId =
//                                     auditor[
//                                     'employee_id']
//                                         ?.toString()
//                                         .trim() ??
//                                         '';
//
//                                 return Align(
//                                   alignment:
//                                   Alignment
//                                       .centerLeft,
//                                   child: Text(
//                                     employeeId
//                                         .isEmpty
//                                         ? name
//                                         : '$name • $employeeId',
//                                     maxLines:
//                                     1,
//                                     overflow:
//                                     TextOverflow
//                                         .ellipsis,
//                                   ),
//                                 );
//                               },
//                             ).toList();
//                           },
//                           items:
//                           auditors.map(
//                                 (
//                                 auditor,
//                                 ) {
//                               final name =
//                                   auditor[
//                                   'auditor_name']
//                                       ?.toString()
//                                       .trim() ??
//                                       '';
//
//                               final employeeId =
//                                   auditor[
//                                   'employee_id']
//                                       ?.toString()
//                                       .trim() ??
//                                       '';
//
//                               final email =
//                                   auditor[
//                                   'email']
//                                       ?.toString()
//                                       .trim() ??
//                                       '';
//
//                               return DropdownMenuItem<
//                                   String>(
//                                 value:
//                                 auditor[
//                                 'auditor_id']
//                                     ?.toString(),
//                                 child: SizedBox(
//                                   width:
//                                   double.infinity,
//                                   child: Column(
//                                     mainAxisAlignment:
//                                     MainAxisAlignment
//                                         .center,
//                                     crossAxisAlignment:
//                                     CrossAxisAlignment
//                                         .start,
//                                     children: [
//                                       Text(
//                                         employeeId
//                                             .isEmpty
//                                             ? name
//                                             : '$name • $employeeId',
//                                         maxLines:
//                                         1,
//                                         overflow:
//                                         TextOverflow
//                                             .ellipsis,
//                                         style:
//                                         const TextStyle(
//                                           fontWeight:
//                                           FontWeight
//                                               .w600,
//                                         ),
//                                       ),
//                                       if (email
//                                           .isNotEmpty)
//                                         Text(
//                                           email,
//                                           maxLines:
//                                           1,
//                                           overflow:
//                                           TextOverflow
//                                               .ellipsis,
//                                           style:
//                                           const TextStyle(
//                                             fontSize:
//                                             11,
//                                             color:
//                                             _muted,
//                                           ),
//                                         ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           ).toList(),
//                           onChanged:
//                           dialogSaving
//                               ? null
//                               : (
//                               value,
//                               ) {
//                             setDialogState(
//                                   () {
//                                 selectedAuditorId =
//                                     value;
//                               },
//                             );
//                           },
//                         ),
//
//                         const SizedBox(
//                           height: 14,
//                         ),
//
//                         // ==================================================
//                         // STATUS
//                         // ==================================================
//
//                         DropdownButtonFormField<
//                             String>(
//                           value:
//                           selectedStatus,
//                           isExpanded: true,
//                           decoration:
//                           const InputDecoration(
//                             labelText:
//                             'Status',
//                             border:
//                             OutlineInputBorder(),
//                             prefixIcon:
//                             Icon(
//                               Icons
//                                   .flag_outlined,
//                             ),
//                           ),
//                           items: const [
//                             DropdownMenuItem(
//                               value:
//                               'Planned',
//                               child:
//                               Text(
//                                 'Planned',
//                               ),
//                             ),
//                             DropdownMenuItem(
//                               value:
//                               'In Progress',
//                               child:
//                               Text(
//                                 'In Progress',
//                               ),
//                             ),
//                             DropdownMenuItem(
//                               value:
//                               'Completed',
//                               child:
//                               Text(
//                                 'Completed',
//                               ),
//                             ),
//                             DropdownMenuItem(
//                               value:
//                               'Cancelled',
//                               child:
//                               Text(
//                                 'Cancelled',
//                               ),
//                             ),
//                           ],
//                           onChanged:
//                           dialogSaving
//                               ? null
//                               : (
//                               value,
//                               ) {
//                             if (value ==
//                                 null) {
//                               return;
//                             }
//
//                             setDialogState(
//                                   () {
//                                 selectedStatus =
//                                     value;
//                               },
//                             );
//                           },
//                         ),
//
//                         const SizedBox(
//                           height: 14,
//                         ),
//
//                         // ==================================================
//                         // NOTES
//                         // ==================================================
//
//                         TextField(
//                           controller:
//                           notesController,
//                           maxLines: 3,
//                           decoration:
//                           const InputDecoration(
//                             labelText:
//                             'Notes',
//                             hintText:
//                             'Optional notes',
//                             border:
//                             OutlineInputBorder(),
//                             prefixIcon:
//                             Padding(
//                               padding:
//                               EdgeInsets.only(
//                                 bottom: 36,
//                               ),
//                               child: Icon(
//                                 Icons
//                                     .notes_outlined,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 actions: [
//                   TextButton(
//                     onPressed:
//                     dialogSaving
//                         ? null
//                         : () {
//                       Navigator.pop(
//                         dialogContext,
//                       );
//                     },
//                     child: const Text(
//                       'Cancel',
//                     ),
//                   ),
//                   FilledButton.icon(
//                     onPressed:
//                     dialogSaving
//                         ? null
//                         : () async {
//                       if (selectedMasterId ==
//                           null ||
//                           selectedMasterId!
//                               .isEmpty) {
//                         _dialogError(
//                           dialogContext,
//                           'Select an Audit Master Name.',
//                         );
//                         return;
//                       }
//
//                       if (selectedAuditorId ==
//                           null ||
//                           selectedAuditorId!
//                               .isEmpty) {
//                         _dialogError(
//                           dialogContext,
//                           'Select an Auditor.',
//                         );
//                         return;
//                       }
//
//                       Map<String,
//                           dynamic>?
//                       selectedMaster;
//
//                       for (final master
//                       in masters) {
//                         if (master[
//                         'master_id']
//                             ?.toString() ==
//                             selectedMasterId) {
//                           selectedMaster =
//                               master;
//                           break;
//                         }
//                       }
//
//                       Map<String,
//                           dynamic>?
//                       selectedAuditor;
//
//                       for (final auditor
//                       in auditors) {
//                         if (auditor[
//                         'auditor_id']
//                             ?.toString() ==
//                             selectedAuditorId) {
//                           selectedAuditor =
//                               auditor;
//                           break;
//                         }
//                       }
//
//                       if (selectedMaster ==
//                           null) {
//                         _dialogError(
//                           dialogContext,
//                           'Selected Audit Master could not be found.',
//                         );
//                         return;
//                       }
//
//                       if (selectedAuditor ==
//                           null) {
//                         _dialogError(
//                           dialogContext,
//                           'Selected Auditor could not be found.',
//                         );
//                         return;
//                       }
//
//                       final masterName =
//                           selectedMaster[
//                           'master_name']
//                               ?.toString()
//                               .trim() ??
//                               '';
//
//                       final auditTypeId =
//                       selectedMaster[
//                       'audit_type_id']
//                           ?.toString();
//
//                       final auditorName =
//                           selectedAuditor[
//                           'auditor_name']
//                               ?.toString()
//                               .trim() ??
//                               '';
//
//                       final auditorEmail =
//                           selectedAuditor[
//                           'email']
//                               ?.toString()
//                               .trim() ??
//                               '';
//
//                       if (masterName
//                           .isEmpty) {
//                         _dialogError(
//                           dialogContext,
//                           'Selected Audit Master is invalid.',
//                         );
//                         return;
//                       }
//
//                       if (auditorName
//                           .isEmpty) {
//                         _dialogError(
//                           dialogContext,
//                           'Selected Auditor is invalid.',
//                         );
//                         return;
//                       }
//
//                       setDialogState(
//                             () {
//                           dialogSaving =
//                           true;
//                         },
//                       );
//
//                       try {
//                         Map<String,
//                             dynamic>
//                         saved;
//
//                         if (isEditing) {
//                           saved =
//                           await SupabaseService
//                               .updateAuditSchedule(
//                             scheduleId:
//                             existing[
//                             'schedule_id']
//                                 .toString(),
//                             auditDate:
//                             auditDate,
//                             typeId:
//                             auditTypeId,
//                             masterId:
//                             selectedMasterId,
//                             masterDataName:
//                             masterName,
//                             auditorId:
//                             selectedAuditorId,
//                             auditorName:
//                             auditorName,
//                             auditorEmail:
//                             auditorEmail,
//                             status:
//                             selectedStatus,
//                             notes:
//                             notesController
//                                 .text
//                                 .trim(),
//                           ).timeout(
//                             const Duration(
//                               seconds: 20,
//                             ),
//                           );
//                         } else {
//                           saved =
//                           await SupabaseService
//                               .createAuditSchedule(
//                             auditDate:
//                             auditDate,
//                             typeId:
//                             auditTypeId,
//                             masterId:
//                             selectedMasterId,
//                             masterDataName:
//                             masterName,
//                             auditorId:
//                             selectedAuditorId,
//                             auditorName:
//                             auditorName,
//                             auditorEmail:
//                             auditorEmail,
//                             status:
//                             selectedStatus,
//                             notes:
//                             notesController
//                                 .text
//                                 .trim(),
//                           ).timeout(
//                             const Duration(
//                               seconds: 20,
//                             ),
//                           );
//                         }
//
//                         if (!mounted) {
//                           return;
//                         }
//
// // selectedMaster was already validated above.
// // Copy the value into a non-null local before entering
// // the setState closure so Dart's null-safety analysis
// // does not lose the promotion.
//                         final selectedAuditTypeName =
//                             selectedMaster[
//                             'audit_type_name']
//                                 ?.toString()
//                                 .trim() ??
//                                 '';
//
//                         setState(() {
//                           if (isEditing) {
//                             final index =
//                             _schedules.indexWhere(
//                                   (
//                                   item,
//                                   ) =>
//                               item[
//                               'schedule_id']
//                                   ?.toString() ==
//                                   existing[
//                                   'schedule_id']
//                                       ?.toString(),
//                             );
//
//                             if (index >= 0) {
//                               _schedules[index] = {
//                                 ..._schedules[index],
//                                 ...saved,
//                                 'audit_type':
//                                 selectedAuditTypeName,
//                               };
//                             }
//                           } else {
//                             _schedules.add({
//                               ...saved,
//                               'audit_type':
//                               selectedAuditTypeName,
//                             });
//                           }
//
//                           _saving = false;
//                         });
//                         if (!dialogContext
//                             .mounted) {
//                           return;
//                         }
//
//                         Navigator.pop(
//                           dialogContext,
//                         );
//
//                         _message(
//                           isEditing
//                               ? 'Schedule updated successfully.'
//                               : 'Audit scheduled successfully.',
//                         );
//                       } catch (e) {
//                         if (!dialogContext
//                             .mounted) {
//                           return;
//                         }
//
//                         setDialogState(
//                               () {
//                             dialogSaving =
//                             false;
//                           },
//                         );
//
//                         _dialogError(
//                           dialogContext,
//                           'Unable to save schedule: $e',
//                         );
//                       }
//                     },
//                     icon: const Icon(
//                       Icons
//                           .check_circle_outline,
//                     ),
//                     label: Text(
//                       isEditing
//                           ? 'Update'
//                           : 'Schedule',
//                     ),
//                   ),
//                 ],
//               );
//             },
//           );
//         },
//       );
//     } finally {
//       notesController.dispose();
//
//       if (mounted) {
//         setState(() {
//           _saving = false;
//         });
//       }
//     }
//   }
//
//   // ============================================================
//   // STATUS UPDATE
//   // ============================================================
//
//   Future<void> _updateStatus(
//       Map<String, dynamic> schedule,
//       String status,
//       ) async {
//     final id =
//     schedule['schedule_id']
//         ?.toString();
//
//     if (id == null || id.isEmpty) {
//       return;
//     }
//
//     final oldStatus =
//     schedule['status']
//         ?.toString();
//
//     if (oldStatus == status) {
//       return;
//     }
//
//     try {
//       final updated =
//       await SupabaseService
//           .updateAuditScheduleStatus(
//         scheduleId: id,
//         status: status,
//       ).timeout(
//         const Duration(seconds: 20),
//       );
//
//       if (!mounted) return;
//
//       final index =
//       _schedules.indexWhere(
//             (item) =>
//         item['schedule_id']
//             ?.toString() ==
//             id,
//       );
//
//       if (index >= 0) {
//         setState(() {
//           _schedules[index] = {
//             ..._schedules[index],
//             ...updated,
//             'status': status,
//           };
//         });
//       }
//
//       _message(
//         'Schedule status updated.',
//       );
//     } catch (e) {
//       if (!mounted) return;
//
//       _message(
//         'Unable to update status: $e',
//       );
//     }
//   }
//
//   // ============================================================
//   // BUILD
//   // ============================================================
//
//   @override
//   Widget build(
//       BuildContext context,
//       ) {
//     return Scaffold(
//       backgroundColor:
//       _background,
//       appBar: AppBar(
//         backgroundColor:
//         Colors.white,
//         foregroundColor:
//         _text,
//         elevation: 0,
//         title: const Text(
//           'Audit Schedule',
//           style: TextStyle(
//             fontWeight:
//             FontWeight.w800,
//           ),
//         ),
//         actions: [
//           IconButton(
//             tooltip: 'Refresh',
//             onPressed:
//             _loading
//                 ? null
//                 : _loadData,
//             icon: const Icon(
//               Icons.refresh_rounded,
//             ),
//           ),
//           const SizedBox(
//             width: 8,
//           ),
//         ],
//       ),
//       body: _loading
//           ? const Center(
//         child:
//         CircularProgressIndicator(),
//       )
//           : _error != null
//           ? _buildError()
//           : _buildMainContent(),
//       floatingActionButton:
//       _loading
//           ? null
//           : null,
//     );
//   }
//   List<Map<String, dynamic>>
//   _getPlanningMasters() {
//     if (_selectedPlanningTypeId ==
//         null) {
//       return [];
//     }
//
//     final masterNames =
//     <String>{};
//
//     final result =
//     <Map<String, dynamic>>[];
//
//     for (final schedule in _schedules) {
//       final typeId =
//       schedule['type_id']
//           ?.toString();
//
//       if (typeId !=
//           _selectedPlanningTypeId) {
//         continue;
//       }
//
//       final date =
//       _parseDate(
//         schedule['audit_date'],
//       );
//
//       if (date == null ||
//           date.year !=
//               _planningYear) {
//         continue;
//       }
//
//       final masterName =
//           schedule['master_data_name']
//               ?.toString()
//               .trim() ??
//               '';
//
//       if (masterName.isEmpty) {
//         continue;
//       }
//
//       if (masterNames
//           .contains(masterName)) {
//         continue;
//       }
//
//       masterNames.add(masterName);
//
//       result.add({
//         'master_data_name':
//         masterName,
//       });
//     }
//
//     // Also include masters belonging to the
//     // selected Audit Type even when there is
//     // currently no schedule for them.
//     for (final master in _masters) {
//       final typeId =
//       master['audit_type_id']
//           ?.toString();
//
//       if (typeId !=
//           _selectedPlanningTypeId) {
//         continue;
//       }
//
//       final masterName =
//           master['master_name']
//               ?.toString()
//               .trim() ??
//               '';
//
//       if (masterName.isEmpty ||
//           masterNames
//               .contains(masterName)) {
//         continue;
//       }
//
//       masterNames.add(masterName);
//
//       result.add({
//         'master_data_name':
//         masterName,
//       });
//     }
//
//     result.sort(
//           (a, b) =>
//           (a['master_data_name']
//               ?.toString() ??
//               '')
//               .toLowerCase()
//               .compareTo(
//             (b['master_data_name']
//                 ?.toString() ??
//                 '')
//                 .toLowerCase(),
//           ),
//     );
//
//     return result;
//   }
//
//   List<Map<String, dynamic>>
//   _getSchedulesForPlanningCell(
//       String masterName,
//       int month,
//       ) {
//     return _schedules.where(
//           (schedule) {
//         final typeId =
//         schedule['type_id']
//             ?.toString();
//
//         if (typeId !=
//             _selectedPlanningTypeId) {
//           return false;
//         }
//
//         final name =
//             schedule['master_data_name']
//                 ?.toString()
//                 .trim() ??
//                 '';
//
//         if (name != masterName) {
//           return false;
//         }
//
//         final date =
//         _parseDate(
//           schedule['audit_date'],
//         );
//
//         if (date == null) {
//           return false;
//         }
//
//         return date.year ==
//             _planningYear &&
//             date.month == month;
//       },
//     ).toList();
//   }
//
//   String _planningCellSymbol(
//       List<Map<String, dynamic>>
//       schedules,
//       ) {
//     if (schedules.isEmpty) {
//       return '';
//     }
//
//     final hasCompleted =
//     schedules.any(
//           (schedule) =>
//       schedule['status']
//           ?.toString() ==
//           'Completed',
//     );
//
//     final hasInProgress =
//     schedules.any(
//           (schedule) =>
//       schedule['status']
//           ?.toString() ==
//           'In Progress',
//     );
//
//     final hasPlanned =
//     schedules.any(
//           (schedule) =>
//       schedule['status']
//           ?.toString() ==
//           'Planned',
//     );
//
//     if (hasCompleted) {
//       return '✓✓';
//     }
//
//     if (hasInProgress) {
//       return '✓';
//     }
//
//     if (hasPlanned) {
//       return '✓';
//     }
//
//     return '×';
//   }
//
//   Color _planningCellColor(
//       List<Map<String, dynamic>>
//       schedules,
//       ) {
//     if (schedules.isEmpty) {
//       return Colors.transparent;
//     }
//
//     final hasCompleted =
//     schedules.any(
//           (schedule) =>
//       schedule['status']
//           ?.toString() ==
//           'Completed',
//     );
//
//     final hasCancelled =
//     schedules.every(
//           (schedule) =>
//       schedule['status']
//           ?.toString() ==
//           'Cancelled',
//     );
//
//     if (hasCompleted) {
//       return const Color(
//         0xFFE8F7EE,
//       );
//     }
//
//     if (hasCancelled) {
//       return const Color(
//         0xFFFDE8E8,
//       );
//     }
//
//     return const Color(
//       0xFFF0E9FF,
//     );
//   }
//
//   Color _planningSymbolColor(
//       List<Map<String, dynamic>>
//       schedules,
//       ) {
//     if (schedules.isEmpty) {
//       return const Color(
//         0xFF6B7280,
//       );
//     }
//
//     final hasCompleted =
//     schedules.any(
//           (schedule) =>
//       schedule['status']
//           ?.toString() ==
//           'Completed',
//     );
//
//     final hasCancelled =
//     schedules.every(
//           (schedule) =>
//       schedule['status']
//           ?.toString() ==
//           'Cancelled',
//     );
//
//     if (hasCompleted) {
//       return const Color(
//         0xFF219653,
//       );
//     }
//
//     if (hasCancelled) {
//       return const Color(
//         0xFFD14343,
//       );
//     }
//
//     return _purple;
//   }
//   Widget _buildMainContent() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.fromLTRB(
//         18,
//         18,
//         18,
//         28,
//       ),
//       child: Center(
//         child: ConstrainedBox(
//           constraints:
//           const BoxConstraints(
//             maxWidth: 1250,
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               LayoutBuilder(
//                 builder:
//                     (
//                     context,
//                     constraints,
//                     ) {
//                   if (constraints.maxWidth <
//                       850) {
//                     return Column(
//                       children: [
//                         _buildSmallCalendar(),
//                         const SizedBox(
//                           height: 18,
//                         ),
//                         _buildScheduledAudits(),
//                       ],
//                     );
//                   }
//
//                   return Row(
//                     crossAxisAlignment:
//                     CrossAxisAlignment
//                         .start,
//                     children: [
//                       SizedBox(
//                         width: 420,
//                         child:
//                         _buildSmallCalendar(),
//                       ),
//                       const SizedBox(
//                         width: 20,
//                       ),
//                       Expanded(
//                         child:
//                         _buildScheduledAudits(),
//                       ),
//                     ],
//                   );
//                 },
//               ),
//
//               // ==========================================================
//               // YEARLY AUDIT PLANNING
//               // ==========================================================
//
//               const SizedBox(
//                 height: 22,
//               ),
//
//               _buildYearlyPlanning(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ============================================================
//   // SMALL CALENDAR
//   // ============================================================
//
//   Widget _buildSmallCalendar() {
//     final daysInMonth =
//         DateTime(
//           _displayedMonth.year,
//           _displayedMonth.month + 1,
//           0,
//         ).day;
//
//     final firstWeekday =
//         DateTime(
//           _displayedMonth.year,
//           _displayedMonth.month,
//           1,
//         ).weekday -
//             1;
//
//     final cellCount =
//         firstWeekday + daysInMonth;
//
//     final rowCount =
//     (cellCount / 7).ceil();
//
//     return Container(
//       decoration:
//       BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//         BorderRadius.circular(
//           18,
//         ),
//         border: Border.all(
//           color:
//           const Color(0xFFE1E5EC),
//         ),
//       ),
//       padding:
//       const EdgeInsets.all(18),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               IconButton(
//                 tooltip:
//                 'Previous month',
//                 onPressed:
//                 _previousMonth,
//                 icon: const Icon(
//                   Icons
//                       .chevron_left_rounded,
//                 ),
//               ),
//               Expanded(
//                 child: Text(
//                   _monthTitle(
//                     _displayedMonth,
//                   ),
//                   textAlign:
//                   TextAlign.center,
//                   style:
//                   const TextStyle(
//                     fontSize: 18,
//                     fontWeight:
//                     FontWeight.w800,
//                     color: _text,
//                   ),
//                 ),
//               ),
//               IconButton(
//                 tooltip:
//                 'Next month',
//                 onPressed:
//                 _nextMonth,
//                 icon: const Icon(
//                   Icons
//                       .chevron_right_rounded,
//                 ),
//               ),
//             ],
//           ),
//
//           Row(
//             children: const [
//               _CalendarWeekDay('M'),
//               _CalendarWeekDay('T'),
//               _CalendarWeekDay('W'),
//               _CalendarWeekDay('T'),
//               _CalendarWeekDay('F'),
//               _CalendarWeekDay('S'),
//               _CalendarWeekDay('S'),
//             ],
//           ),
//
//           const SizedBox(
//             height: 8,
//           ),
//
//           GridView.builder(
//             shrinkWrap: true,
//             physics:
//             const NeverScrollableScrollPhysics(),
//             itemCount:
//             rowCount * 7,
//             gridDelegate:
//             const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 7,
//               childAspectRatio: 1.15,
//             ),
//             itemBuilder:
//                 (
//                 context,
//                 index,
//                 ) {
//               if (index <
//                   firstWeekday) {
//                 return const SizedBox();
//               }
//
//               final day =
//                   index -
//                       firstWeekday +
//                       1;
//
//               if (day >
//                   daysInMonth) {
//                 return const SizedBox();
//               }
//
//               final date =
//               DateTime(
//                 _displayedMonth
//                     .year,
//                 _displayedMonth
//                     .month,
//                 day,
//               );
//
//               final schedules =
//               _schedulesForDate(
//                 date,
//               );
//
//               final selected =
//               _sameDate(
//                 date,
//                 _selectedDate,
//               );
//
//               final today =
//               _sameDate(
//                 date,
//                 DateTime.now(),
//               );
//
//               return InkWell(
//                 borderRadius:
//                 BorderRadius.circular(
//                   10,
//                 ),
//                 onTap: () {
//                   setState(() {
//                     _selectedDate =
//                         date;
//                   });
//                 },
//                 child: Container(
//                   margin:
//                   const EdgeInsets
//                       .all(
//                     2,
//                   ),
//                   decoration:
//                   BoxDecoration(
//                     color:
//                     selected
//                         ? const Color(
//                       0xFFF0E9FF,
//                     )
//                         : Colors
//                         .transparent,
//                     borderRadius:
//                     BorderRadius
//                         .circular(
//                       10,
//                     ),
//                     border:
//                     today
//                         ? Border.all(
//                       color:
//                       _purple,
//                       width:
//                       1.4,
//                     )
//                         : null,
//                   ),
//                   child: Column(
//                     mainAxisAlignment:
//                     MainAxisAlignment
//                         .center,
//                     children: [
//                       Text(
//                         '$day',
//                         style:
//                         TextStyle(
//                           fontSize:
//                           12,
//                           fontWeight:
//                           selected ||
//                               today
//                               ? FontWeight
//                               .w800
//                               : FontWeight
//                               .w500,
//                           color:
//                           selected
//                               ? _purple
//                               : _text,
//                         ),
//                       ),
//                       const SizedBox(
//                         height: 3,
//                       ),
//                       if (schedules
//                           .isNotEmpty)
//                         _calendarIndicator(
//                           schedules
//                               .first[
//                           'status']
//                               ?.toString(),
//                         ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//
//           const SizedBox(
//             height: 14,
//           ),
//
//           Row(
//             mainAxisAlignment:
//             MainAxisAlignment
//                 .center,
//             children: [
//               _legend(
//                 '✓',
//                 'Planned',
//               ),
//               const SizedBox(
//                 width: 14,
//               ),
//               _legend(
//                 '•',
//                 'In Progress',
//               ),
//               const SizedBox(
//                 width: 14,
//               ),
//               _legend(
//                 '✓✓',
//                 'Completed',
//               ),
//               const SizedBox(
//                 width: 14,
//               ),
//               _legend(
//                 '×',
//                 'Cancelled',
//               ),
//             ],
//           ),
//
//           const SizedBox(
//             height: 8,
//           ),
//
//           TextButton(
//             onPressed: _goToday,
//             child:
//             const Text(
//               'Go to Today',
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _calendarIndicator(
//       String? status,
//       ) {
//     String value;
//
//     switch (status) {
//       case 'Completed':
//         value = '✓✓';
//         break;
//
//       case 'In Progress':
//         value = '•';
//         break;
//
//       case 'Cancelled':
//         value = '×';
//         break;
//
//       default:
//         value = '✓';
//     }
//
//     return Text(
//       value,
//       style:
//       TextStyle(
//         fontSize: 10,
//         fontWeight:
//         FontWeight.w900,
//         color:
//         _statusForeground(
//           status ?? 'Planned',
//         ),
//       ),
//     );
//   }
//
//   Widget _legend(
//       String symbol,
//       String label,
//       ) {
//     return Row(
//       mainAxisSize:
//       MainAxisSize.min,
//       children: [
//         Text(
//           symbol,
//           style:
//           const TextStyle(
//             fontWeight:
//             FontWeight.w900,
//             color: _purple,
//             fontSize: 12,
//           ),
//         ),
//         const SizedBox(
//           width: 4,
//         ),
//         Text(
//           label,
//           style:
//           const TextStyle(
//             color: _muted,
//             fontSize: 10,
//           ),
//         ),
//       ],
//     );
//   }
//
//   // ============================================================
//   // SCHEDULED AUDITS
//   // ============================================================
//
//   Widget _buildScheduledAudits() {
//     final schedules =
//     _schedulesForDate(
//       _selectedDate,
//     );
//
//     return Container(
//       decoration:
//       BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//         BorderRadius.circular(
//           18,
//         ),
//         border: Border.all(
//           color:
//           const Color(0xFFE1E5EC),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment:
//         CrossAxisAlignment
//             .stretch,
//         children: [
//           Padding(
//             padding:
//             const EdgeInsets.fromLTRB(
//               20,
//               18,
//               14,
//               16,
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment:
//                     CrossAxisAlignment
//                         .start,
//                     children: [
//                       const Text(
//                         'Scheduled Audits',
//                         style:
//                         TextStyle(
//                           fontSize: 19,
//                           fontWeight:
//                           FontWeight.w800,
//                           color: _text,
//                         ),
//                       ),
//                       const SizedBox(
//                         height: 4,
//                       ),
//                       Text(
//                         _formatDate(
//                           _selectedDate,
//                         ),
//                         style:
//                         const TextStyle(
//                           color: _muted,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 OutlinedButton.icon(
//                   onPressed:
//                   _saving
//                       ? null
//                       : _addSchedule,
//                   icon:
//                   const Icon(
//                     Icons.add,
//                     size: 18,
//                   ),
//                   label:
//                   const Text(
//                     'Schedule Audit',
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           const Divider(
//             height: 1,
//           ),
//
//           schedules.isEmpty
//               ? _emptyScheduledAudits()
//               : ListView.separated(
//             shrinkWrap: true,
//             physics:
//             const NeverScrollableScrollPhysics(),
//             padding:
//             const EdgeInsets
//                 .all(
//               14,
//             ),
//             itemCount:
//             schedules.length,
//             separatorBuilder:
//                 (
//                 context,
//                 index,
//                 ) =>
//             const SizedBox(
//               height: 10,
//             ),
//             itemBuilder:
//                 (
//                 context,
//                 index,
//                 ) {
//               return _buildScheduleCard(
//                 schedules[index],
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
//   Widget _buildYearlyPlanning() {
//     final masters =
//     _getPlanningMasters();
//
//     const months = [
//       'Jan',
//       'Feb',
//       'Mar',
//       'Apr',
//       'May',
//       'Jun',
//       'Jul',
//       'Aug',
//       'Sep',
//       'Oct',
//       'Nov',
//       'Dec',
//     ];
//
//     return Container(
//       width: double.infinity,
//       decoration:
//       BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//         BorderRadius.circular(
//           18,
//         ),
//         border: Border.all(
//           color:
//           const Color(
//             0xFFE1E5EC,
//           ),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment:
//         CrossAxisAlignment
//             .stretch,
//         children: [
//           // ========================================================
//           // HEADER
//           // ========================================================
//
//           Padding(
//             padding:
//             const EdgeInsets.fromLTRB(
//               20,
//               18,
//               20,
//               14,
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment:
//                     CrossAxisAlignment
//                         .start,
//                     children: [
//                       const Text(
//                         'Audit Planning',
//                         style:
//                         TextStyle(
//                           fontSize: 19,
//                           fontWeight:
//                           FontWeight.w800,
//                           color: _text,
//                         ),
//                       ),
//                       const SizedBox(
//                         height: 4,
//                       ),
//                       const Text(
//                         'Yearly audit plan by Audit Master and month',
//                         style:
//                         TextStyle(
//                           color: _muted,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 // ==================================================
//                 // AUDIT TYPE DROPDOWN
//                 // ==================================================
//
//                 SizedBox(
//                   width: 230,
//                   child:
//                   DropdownButtonFormField<
//                       String>(
//                     value:
//                     _auditTypes.any(
//                           (type) =>
//                       type['type_id']
//                           ?.toString() ==
//                           _selectedPlanningTypeId,
//                     )
//                         ? _selectedPlanningTypeId
//                         : null,
//                     isExpanded: true,
//                     decoration:
//                     const InputDecoration(
//                       labelText:
//                       'Audit Type',
//                       prefixIcon:
//                       Icon(
//                         Icons
//                             .category_outlined,
//                         size: 19,
//                       ),
//                       border:
//                       OutlineInputBorder(),
//                       contentPadding:
//                       EdgeInsets
//                           .symmetric(
//                         horizontal: 12,
//                         vertical: 10,
//                       ),
//                     ),
//                     items:
//                     _auditTypes.map(
//                           (
//                           type,
//                           ) {
//                         final id =
//                         type['type_id']
//                             ?.toString();
//
//                         final name =
//                             type['audit_type']
//                                 ?.toString()
//                                 .trim() ??
//                                 '';
//
//                         return DropdownMenuItem<
//                             String>(
//                           value: id,
//                           child: Text(
//                             name,
//                             maxLines: 1,
//                             overflow:
//                             TextOverflow
//                                 .ellipsis,
//                           ),
//                         );
//                       },
//                     ).toList(),
//                     onChanged:
//                         (
//                         value,
//                         ) {
//                       setState(() {
//                         _selectedPlanningTypeId =
//                             value;
//                       });
//                     },
//                   ),
//                 ),
//
//                 const SizedBox(
//                   width: 12,
//                 ),
//
//                 // ==================================================
//                 // YEAR
//                 // ==================================================
//
//                 Container(
//                   decoration:
//                   BoxDecoration(
//                     border: Border.all(
//                       color:
//                       const Color(
//                         0xFFD9DDE5,
//                       ),
//                     ),
//                     borderRadius:
//                     BorderRadius
//                         .circular(
//                       10,
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       IconButton(
//                         tooltip:
//                         'Previous year',
//                         onPressed:
//                             () {
//                           setState(() {
//                             _planningYear--;
//                           });
//                         },
//                         icon:
//                         const Icon(
//                           Icons
//                               .chevron_left,
//                           size: 19,
//                         ),
//                       ),
//                       Text(
//                         '$_planningYear',
//                         style:
//                         const TextStyle(
//                           fontWeight:
//                           FontWeight.w800,
//                           color: _text,
//                         ),
//                       ),
//                       IconButton(
//                         tooltip:
//                         'Next year',
//                         onPressed:
//                             () {
//                           setState(() {
//                             _planningYear++;
//                           });
//                         },
//                         icon:
//                         const Icon(
//                           Icons
//                               .chevron_right,
//                           size: 19,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           const Divider(
//             height: 1,
//           ),
//
//           // ========================================================
//           // PLANNING TABLE
//           // ========================================================
//
//           if (_auditTypes.isEmpty)
//             const Padding(
//               padding:
//               EdgeInsets.all(
//                 40,
//               ),
//               child: Center(
//                 child: Text(
//                   'No Audit Types available.',
//                   style:
//                   TextStyle(
//                     color: _muted,
//                   ),
//                 ),
//               ),
//             )
//           else if (_selectedPlanningTypeId ==
//               null)
//             const Padding(
//               padding:
//               EdgeInsets.all(
//                 40,
//               ),
//               child: Center(
//                 child: Text(
//                   'Select an Audit Type to view the yearly plan.',
//                   style:
//                   TextStyle(
//                     color: _muted,
//                   ),
//                 ),
//               ),
//             )
//           else
//             SingleChildScrollView(
//               scrollDirection:
//               Axis.horizontal,
//               child: DataTable(
//                 headingRowHeight:
//                 48,
//                 dataRowMinHeight:
//                 54,
//                 dataRowMaxHeight:
//                 54,
//                 horizontalMargin:
//                 16,
//                 columnSpacing:
//                 12,
//                 headingRowColor:
//                 WidgetStateProperty
//                     .resolveWith(
//                       (
//                       states,
//                       ) =>
//                   const Color(
//                     0xFFF8F9FC,
//                   ),
//                 ),
//                 columns: [
//                   const DataColumn(
//                     label: SizedBox(
//                       width: 210,
//                       child: Text(
//                         'Audit Master',
//                         style:
//                         TextStyle(
//                           fontWeight:
//                           FontWeight.w800,
//                           color: _text,
//                         ),
//                       ),
//                     ),
//                   ),
//                   ...months.map(
//                         (
//                         month,
//                         ) {
//                       return DataColumn(
//                         label: SizedBox(
//                           width: 58,
//                           child: Center(
//                             child: Text(
//                               month,
//                               style:
//                               const TextStyle(
//                                 fontWeight:
//                                 FontWeight.w800,
//                                 color:
//                                 _text,
//                               ),
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ],
//                 rows: masters.isEmpty
//                     ? [
//                   const DataRow(
//                     cells: [
//                       DataCell(
//                         SizedBox(
//                           width: 210,
//                           child:
//                           Text(
//                             'No Audit Master Data',
//                             style:
//                             TextStyle(
//                               color:
//                               _muted,
//                             ),
//                           ),
//                         ),
//                       ),
//                       DataCell(
//                         SizedBox(),
//                       ),
//                       DataCell(
//                         SizedBox(),
//                       ),
//                       DataCell(
//                         SizedBox(),
//                       ),
//                       DataCell(
//                         SizedBox(),
//                       ),
//                       DataCell(
//                         SizedBox(),
//                       ),
//                       DataCell(
//                         SizedBox(),
//                       ),
//                       DataCell(
//                         SizedBox(),
//                       ),
//                       DataCell(
//                         SizedBox(),
//                       ),
//                       DataCell(
//                         SizedBox(),
//                       ),
//                       DataCell(
//                         SizedBox(),
//                       ),
//                       DataCell(
//                         SizedBox(),
//                       ),
//                       DataCell(
//                         SizedBox(),
//                       ),
//                     ],
//                   ),
//                 ]
//                     : masters.map(
//                       (
//                       master,
//                       ) {
//                     final masterName =
//                         master[
//                         'master_data_name']
//                             ?.toString() ??
//                             '';
//
//                     return DataRow(
//                       cells: [
//                         DataCell(
//                           SizedBox(
//                             width:
//                             210,
//                             child:
//                             Text(
//                               masterName,
//                               maxLines:
//                               1,
//                               overflow:
//                               TextOverflow
//                                   .ellipsis,
//                               style:
//                               const TextStyle(
//                                 fontWeight:
//                                 FontWeight
//                                     .w700,
//                                 color:
//                                 _text,
//                               ),
//                             ),
//                           ),
//                         ),
//                         ...List.generate(
//                           12,
//                               (
//                               index,
//                               ) {
//                             final month =
//                                 index +
//                                     1;
//
//                             final cellSchedules =
//                             _getSchedulesForPlanningCell(
//                               masterName,
//                               month,
//                             );
//
//                             final symbol =
//                             _planningCellSymbol(
//                               cellSchedules,
//                             );
//
//                             return DataCell(
//                               Center(
//                                 child:
//                                 Tooltip(
//                                   message:
//                                   cellSchedules.isEmpty
//                                       ? 'No audit scheduled'
//                                       : cellSchedules
//                                       .map(
//                                         (
//                                         schedule,
//                                         ) =>
//                                     '${schedule['auditor_name'] ?? ''} • ${schedule['status'] ?? ''}',
//                                   )
//                                       .join(
//                                     '\n',
//                                   ),
//                                   child:
//                                   Container(
//                                     width:
//                                     38,
//                                     height:
//                                     32,
//                                     alignment:
//                                     Alignment
//                                         .center,
//                                     decoration:
//                                     BoxDecoration(
//                                       color:
//                                       _planningCellColor(
//                                         cellSchedules,
//                                       ),
//                                       borderRadius:
//                                       BorderRadius
//                                           .circular(
//                                         8,
//                                       ),
//                                     ),
//                                     child:
//                                     Text(
//                                       symbol,
//                                       style:
//                                       TextStyle(
//                                         fontWeight:
//                                         FontWeight
//                                             .w900,
//                                         fontSize:
//                                         13,
//                                         color:
//                                         _planningSymbolColor(
//                                           cellSchedules,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ],
//                     );
//                   },
//                 ).toList(),
//               ),
//             ),
//
//           // ========================================================
//           // LEGEND
//           // ========================================================
//
//           Padding(
//             padding:
//             const EdgeInsets.fromLTRB(
//               20,
//               12,
//               20,
//               16,
//             ),
//             child: Row(
//               children: [
//                 _planningLegend(
//                   '✓',
//                   'Planned',
//                 ),
//                 const SizedBox(
//                   width: 18,
//                 ),
//                 _planningLegend(
//                   '✓',
//                   'In Progress',
//                 ),
//                 const SizedBox(
//                   width: 18,
//                 ),
//                 _planningLegend(
//                   '✓✓',
//                   'Completed',
//                 ),
//                 const SizedBox(
//                   width: 18,
//                 ),
//                 _planningLegend(
//                   '×',
//                   'Cancelled',
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _planningLegend(
//       String symbol,
//       String label,
//       ) {
//     return Row(
//       mainAxisSize:
//       MainAxisSize.min,
//       children: [
//         Text(
//           symbol,
//           style:
//           const TextStyle(
//             fontSize: 12,
//             fontWeight:
//             FontWeight.w900,
//             color: _purple,
//           ),
//         ),
//         const SizedBox(
//           width: 5,
//         ),
//         Text(
//           label,
//           style:
//           const TextStyle(
//             fontSize: 11,
//             color: _muted,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _emptyScheduledAudits() {
//     return Center(
//       child: Padding(
//         padding:
//         const EdgeInsets.all(
//           35,
//         ),
//         child: Column(
//           mainAxisSize:
//           MainAxisSize.min,
//           children: [
//             Container(
//               width: 58,
//               height: 58,
//               decoration:
//               BoxDecoration(
//                 color:
//                 const Color(
//                   0xFFF0E9FF,
//                 ),
//                 borderRadius:
//                 BorderRadius.circular(
//                   16,
//                 ),
//               ),
//               child: const Icon(
//                 Icons
//                     .event_available_outlined,
//                 color: _purple,
//                 size: 28,
//               ),
//             ),
//             const SizedBox(
//               height: 12,
//             ),
//             const Text(
//               'No audits scheduled',
//               style:
//               TextStyle(
//                 fontSize: 16,
//                 fontWeight:
//                 FontWeight.w700,
//                 color: _text,
//               ),
//             ),
//             const SizedBox(
//               height: 5,
//             ),
//             const Text(
//               'Schedule an audit for this date.',
//               textAlign:
//               TextAlign.center,
//               style:
//               TextStyle(
//                 color: _muted,
//                 fontSize: 12,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildScheduleCard(
//       Map<String, dynamic> schedule,
//       ) {
//     final status =
//         schedule['status']
//             ?.toString() ??
//             'Planned';
//
//     final scheduleNumber =
//         schedule['schedule_number']
//             ?.toString() ??
//             '';
//
//     final masterName =
//         schedule['master_data_name']
//             ?.toString() ??
//             '';
//
//     final auditorName =
//         schedule['auditor_name']
//             ?.toString() ??
//             '';
//
//     final auditorEmail =
//         schedule['auditor_email']
//             ?.toString() ??
//             '';
//
//     final auditType =
//         schedule['audit_type']
//             ?.toString() ??
//             schedule[
//             'audit_type_name']
//                 ?.toString() ??
//             '';
//
//     return Container(
//       padding:
//       const EdgeInsets.all(
//         14,
//       ),
//       decoration:
//       BoxDecoration(
//         color:
//         const Color(0xFFFAFBFD),
//         borderRadius:
//         BorderRadius.circular(
//           14,
//         ),
//         border: Border.all(
//           color:
//           const Color(0xFFE4E7ED),
//         ),
//       ),
//       child: Row(
//         crossAxisAlignment:
//         CrossAxisAlignment
//             .start,
//         children: [
//           Container(
//             width: 42,
//             height: 42,
//             decoration:
//             BoxDecoration(
//               color:
//               const Color(
//                 0xFFF0E9FF,
//               ),
//               borderRadius:
//               BorderRadius.circular(
//                 12,
//               ),
//             ),
//             child: Center(
//               child:
//               _calendarIndicator(
//                 status,
//               ),
//             ),
//           ),
//
//           const SizedBox(
//             width: 12,
//           ),
//
//           Expanded(
//             child: Column(
//               crossAxisAlignment:
//               CrossAxisAlignment
//                   .start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         scheduleNumber,
//                         maxLines: 1,
//                         overflow:
//                         TextOverflow
//                             .ellipsis,
//                         style:
//                         const TextStyle(
//                           fontWeight:
//                           FontWeight.w800,
//                           color: _text,
//                           fontSize: 13,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(
//                       width: 8,
//                     ),
//                     _statusBadge(
//                       status,
//                     ),
//                   ],
//                 ),
//
//                 const SizedBox(
//                   height: 5,
//                 ),
//
//                 Text(
//                   masterName,
//                   maxLines: 1,
//                   overflow:
//                   TextOverflow.ellipsis,
//                   style:
//                   const TextStyle(
//                     fontWeight:
//                     FontWeight.w700,
//                     color: _text,
//                     fontSize: 14,
//                   ),
//                 ),
//
//                 if (auditType
//                     .trim()
//                     .isNotEmpty) ...[
//                   const SizedBox(
//                     height: 2,
//                   ),
//                   Text(
//                     auditType,
//                     maxLines: 1,
//                     overflow:
//                     TextOverflow
//                         .ellipsis,
//                     style:
//                     const TextStyle(
//                       color: _muted,
//                       fontSize: 11,
//                     ),
//                   ),
//                 ],
//
//                 const SizedBox(
//                   height: 7,
//                 ),
//
//                 Wrap(
//                   spacing: 14,
//                   runSpacing: 4,
//                   children: [
//                     _smallDetail(
//                       Icons
//                           .person_outline,
//                       auditorName,
//                     ),
//                     if (auditorEmail
//                         .trim()
//                         .isNotEmpty)
//                       _smallDetail(
//                         Icons
//                             .mail_outline,
//                         auditorEmail,
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//
//           const SizedBox(
//             width: 8,
//           ),
//
//           PopupMenuButton<String>(
//             tooltip:
//             'Schedule actions',
//             onSelected:
//                 (value) {
//               if (value == 'edit') {
//                 _editSchedule(
//                   schedule,
//                 );
//               }
//
//               if (value == 'delete') {
//                 _deleteSchedule(
//                   schedule,
//                 );
//               }
//             },
//             itemBuilder:
//                 (context) => const [
//               PopupMenuItem(
//                 value: 'edit',
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons
//                           .edit_outlined,
//                       size: 18,
//                     ),
//                     SizedBox(
//                       width: 10,
//                     ),
//                     Text(
//                       'Edit',
//                     ),
//                   ],
//                 ),
//               ),
//               PopupMenuItem(
//                 value: 'delete',
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons
//                           .delete_outline,
//                       size: 18,
//                     ),
//                     SizedBox(
//                       width: 10,
//                     ),
//                     Text(
//                       'Delete',
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _smallDetail(
//       IconData icon,
//       String text,
//       ) {
//     return Row(
//       mainAxisSize:
//       MainAxisSize.min,
//       children: [
//         Icon(
//           icon,
//           size: 14,
//           color: _muted,
//         ),
//         const SizedBox(
//           width: 4,
//         ),
//         ConstrainedBox(
//           constraints:
//           const BoxConstraints(
//             maxWidth: 220,
//           ),
//           child: Text(
//             text,
//             maxLines: 1,
//             overflow:
//             TextOverflow.ellipsis,
//             style:
//             const TextStyle(
//               fontSize: 11,
//               color: _muted,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _statusBadge(
//       String status,
//       ) {
//     return Container(
//       padding:
//       const EdgeInsets.symmetric(
//         horizontal: 8,
//         vertical: 4,
//       ),
//       decoration:
//       BoxDecoration(
//         color:
//         _statusBackground(
//           status,
//         ),
//         borderRadius:
//         BorderRadius.circular(
//           20,
//         ),
//       ),
//       child: Text(
//         status,
//         style:
//         TextStyle(
//           fontSize: 10,
//           fontWeight:
//           FontWeight.w700,
//           color:
//           _statusForeground(
//             status,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Color _statusBackground(
//       String status,
//       ) {
//     switch (status) {
//       case 'Completed':
//         return const Color(
//           0xFFE8F7EE,
//         );
//
//       case 'In Progress':
//         return const Color(
//           0xFFFFF3D9,
//         );
//
//       case 'Cancelled':
//         return const Color(
//           0xFFFDE8E8,
//         );
//
//       default:
//         return const Color(
//           0xFFF0E9FF,
//         );
//     }
//   }
//
//   Color _statusForeground(
//       String status,
//       ) {
//     switch (status) {
//       case 'Completed':
//         return const Color(
//           0xFF219653,
//         );
//
//       case 'In Progress':
//         return const Color(
//           0xFFB77900,
//         );
//
//       case 'Cancelled':
//         return const Color(
//           0xFFD14343,
//         );
//
//       default:
//         return _purple;
//     }
//   }
//
//   // ============================================================
//   // ERROR / MESSAGE
//   // ============================================================
//
//   Widget _buildError() {
//     return Center(
//       child: Container(
//         constraints:
//         const BoxConstraints(
//           maxWidth: 620,
//         ),
//         margin:
//         const EdgeInsets.all(
//           24,
//         ),
//         padding:
//         const EdgeInsets.all(
//           28,
//         ),
//         decoration:
//         BoxDecoration(
//           color: Colors.white,
//           borderRadius:
//           BorderRadius.circular(
//             18,
//           ),
//           border: Border.all(
//             color:
//             const Color(
//               0xFFE1E5EC,
//             ),
//           ),
//         ),
//         child: Column(
//           mainAxisSize:
//           MainAxisSize.min,
//           children: [
//             Icon(
//               Icons
//                   .error_outline_rounded,
//               size: 48,
//               color:
//               Colors.red.shade400,
//             ),
//             const SizedBox(
//               height: 14,
//             ),
//             const Text(
//               'Unable to load Audit Schedule',
//               style:
//               TextStyle(
//                 fontSize: 18,
//                 fontWeight:
//                 FontWeight.w800,
//                 color: _text,
//               ),
//             ),
//             const SizedBox(
//               height: 8,
//             ),
//             Text(
//               _error ?? '',
//               textAlign:
//               TextAlign.center,
//               style:
//               const TextStyle(
//                 color: _muted,
//               ),
//             ),
//             const SizedBox(
//               height: 18,
//             ),
//             FilledButton.icon(
//               onPressed:
//               _loadData,
//               icon: const Icon(
//                 Icons.refresh,
//               ),
//               label:
//               const Text(
//                 'Retry',
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _message(
//       String message,
//       ) {
//     if (!mounted) return;
//
//     ScaffoldMessenger.of(context)
//         .showSnackBar(
//       SnackBar(
//         content: Text(
//           message,
//         ),
//         behavior:
//         SnackBarBehavior.floating,
//       ),
//     );
//   }
//
//   void _dialogError(
//       BuildContext context,
//       String message,
//       ) {
//     ScaffoldMessenger.of(context)
//         .showSnackBar(
//       SnackBar(
//         content: Text(
//           message,
//         ),
//         behavior:
//         SnackBarBehavior.floating,
//       ),
//     );
//   }
// }
//
// // ============================================================
// // CALENDAR WEEK DAY
// // ============================================================
//
// class _CalendarWeekDay
//     extends StatelessWidget {
//   final String label;
//
//   const _CalendarWeekDay(
//       this.label,
//       );
//
//   @override
//   Widget build(
//       BuildContext context,
//       ) {
//     return Expanded(
//       child: Center(
//         child: Text(
//           label,
//           style:
//           const TextStyle(
//             fontSize: 11,
//             fontWeight:
//             FontWeight.w700,
//             color:
//             Color(0xFF6B7280),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';

class AuditScheduleScreen extends StatefulWidget {
  final String sessionToken;

  const AuditScheduleScreen({
    super.key,
    required this.sessionToken,
  });

  @override
  State<AuditScheduleScreen> createState() =>
      _AuditScheduleScreenState();
}

class _AuditScheduleScreenState
    extends State<AuditScheduleScreen> {
  static const Color _background =
  Color(0xFFF5F7FB);

  static const Color _purple =
  Color(0xFF7656C6);

  static const Color _text =
  Color(0xFF172033);

  static const Color _muted =
  Color(0xFF6B7280);

  bool _loading = true;
  bool _saving = false;

  String? _error;

  DateTime _selectedDate =
  _dateOnly(DateTime.now());

  DateTime _displayedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  List<Map<String, dynamic>> _schedules =
  [];

  List<Map<String, dynamic>> _auditors =
  [];

  List<Map<String, dynamic>> _masters =
  [];
  List<Map<String, dynamic>> _auditTypes =
  [];

  String? _selectedPlanningTypeId;

  int _planningYear =
      DateTime.now().year;

  static DateTime _dateOnly(
      DateTime value,
      ) {
    return DateTime(
      value.year,
      value.month,
      value.day,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        SupabaseService.getAllAuditSchedules()
            .timeout(
          const Duration(seconds: 20),
        ),
        SupabaseService.getActiveAuditors()
            .timeout(
          const Duration(seconds: 20),
        ),
        SupabaseService.getAdminAuditMasterData(
          sessionToken:
          widget.sessionToken,
        ).timeout(
          const Duration(seconds: 20),
        ),
        SupabaseService.getActiveAuditTypes()
            .timeout(
          const Duration(seconds: 20),
        ),
      ]);

      if (!mounted) return;

      final schedules =
      List<Map<String, dynamic>>.from(
        results[0] as List,
      );

      final auditors =
      List<Map<String, dynamic>>.from(
        results[1] as List,
      );

      final masters =
      List<Map<String, dynamic>>.from(
        results[2] as List,
      );
      final auditTypes =
      List<Map<String, dynamic>>.from(
        results[3] as List,
      );
      setState(() {
        _schedules = schedules;
        _auditors = auditors;
        _masters = masters;
        _auditTypes = auditTypes;

        if (_selectedPlanningTypeId == null &&
            _auditTypes.isNotEmpty) {
          _selectedPlanningTypeId =
              _auditTypes.first['type_id']
                  ?.toString();
        }

        _loading = false;
      });
    } catch (e) {
      if (await AuditAdminSession.handleSessionExpired(context, e)) {
        return;
      }
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    try {
      return _dateOnly(
        DateTime.parse(
          value.toString(),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  bool _sameDate(
      DateTime first,
      DateTime second,
      ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _formatDate(
      DateTime date,
      ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _monthTitle(
      DateTime date,
      ) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  List<Map<String, dynamic>>
  _schedulesForDate(
      DateTime date,
      ) {
    return _schedules.where(
          (schedule) {
        final scheduleDate =
        _parseDate(
          schedule['audit_date'],
        );

        if (scheduleDate == null) {
          return false;
        }

        return _sameDate(
          scheduleDate,
          date,
        );
      },
    ).toList();
  }

  // ============================================================
  // CALENDAR NAVIGATION
  // ============================================================

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
      );
    });
  }

  void _goToday() {
    final today =
    _dateOnly(DateTime.now());

    setState(() {
      _selectedDate = today;

      _displayedMonth = DateTime(
        today.year,
        today.month,
      );
    });
  }

  // ============================================================
  // ADD SCHEDULE
  // ============================================================

  Future<void> _addSchedule() async {
    if (_auditors.isEmpty) {
      _message(
        'No active auditors are available. Add an auditor first.',
      );
      return;
    }

    final activeMasters =
    _masters.where(
          (master) {
        final active =
        master['active'];

        return active == true ||
            active == null;
      },
    ).toList();

    if (activeMasters.isEmpty) {
      _message(
        'No active Audit Master Data is available.',
      );
      return;
    }

    await _showScheduleDialog(
      selectedDate: _selectedDate,
    );
  }

  // ============================================================
  // EDIT SCHEDULE
  // ============================================================

  Future<void> _editSchedule(
      Map<String, dynamic> schedule,
      ) async {
    final scheduleDate =
    _parseDate(
      schedule['audit_date'],
    );

    await _showScheduleDialog(
      existing: schedule,
      selectedDate:
      scheduleDate ?? _selectedDate,
    );
  }

  // ============================================================
  // DELETE SCHEDULE
  // ============================================================

  Future<void> _deleteSchedule(
      Map<String, dynamic> schedule,
      ) async {
    final scheduleId =
    schedule['schedule_id']
        ?.toString();

    if (scheduleId == null ||
        scheduleId.isEmpty) {
      _message(
        'Schedule ID is missing.',
      );
      return;
    }

    final scheduleNumber =
        schedule['schedule_number']
            ?.toString() ??
            'this schedule';

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (
          dialogContext,
          ) {
        return AlertDialog(
          title: const Text(
            'Delete Schedule',
          ),
          content: Text(
            'Delete "$scheduleNumber"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Delete',
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
      await SupabaseService
          .deleteAuditSchedule(
        scheduleId: scheduleId,
      ).timeout(
        const Duration(seconds: 20),
      );

      if (!mounted) return;

      setState(() {
        _schedules.removeWhere(
              (item) =>
          item['schedule_id']
              ?.toString() ==
              scheduleId,
        );

        _saving = false;
      });

      _message(
        'Schedule deleted successfully.',
      );
    } catch (e) {
      if (await AuditAdminSession.handleSessionExpired(context, e)) {
        return;
      }
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _message(
        'Unable to delete schedule: $e',
      );
    }
  }

  // ============================================================
  // SCHEDULE DIALOG
  // ============================================================

  Future<void> _showScheduleDialog({
    Map<String, dynamic>? existing,
    required DateTime selectedDate,
  }) async {
    final isEditing =
        existing != null;

    DateTime auditDate =
        _parseDate(
          existing?['audit_date'],
        ) ??
            selectedDate;

    String? selectedMasterId =
    existing?['master_id']
        ?.toString();

    String? selectedAuditorId =
    existing?['auditor_id']
        ?.toString();

    String selectedStatus =
        existing?['status']
            ?.toString() ??
            'Planned';

    final notesController =
    TextEditingController(
      text:
      existing?['notes']
          ?.toString() ??
          '',
    );

    bool dialogSaving = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (
            dialogContext,
            ) {
          return StatefulBuilder(
            builder: (
                context,
                setDialogState,
                ) {
              /*
               * IMPORTANT:
               *
               * getActiveAuditors() already returns
               * ONLY active auditors.
               *
               * Therefore DO NOT filter using
               * auditor['active'] here.
               */
              final auditors =
              List<Map<String, dynamic>>.from(
                _auditors,
              );

              final masters =
              _masters.where(
                    (master) {
                  final active =
                  master['active'];

                  return active == true ||
                      active == null;
                },
              ).toList();

              return AlertDialog(
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
                titlePadding:
                const EdgeInsets.fromLTRB(
                  24,
                  22,
                  24,
                  10,
                ),
                contentPadding:
                const EdgeInsets.fromLTRB(
                  24,
                  10,
                  24,
                  4,
                ),
                actionsPadding:
                const EdgeInsets.fromLTRB(
                  24,
                  4,
                  24,
                  18,
                ),
                title: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration:
                      BoxDecoration(
                        color:
                        const Color(
                          0xFFF0E9FF,
                        ),
                        borderRadius:
                        BorderRadius
                            .circular(
                          12,
                        ),
                      ),
                      child: const Icon(
                        Icons
                            .calendar_month_outlined,
                        color: _purple,
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Text(
                      isEditing
                          ? 'Edit Schedule'
                          : 'Schedule Audit',
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.w800,
                        color: _text,
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 540,
                  child:
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        // ==================================================
                        // DATE
                        // ==================================================

                        InkWell(
                          borderRadius:
                          BorderRadius
                              .circular(
                            10,
                          ),
                          onTap:
                          dialogSaving
                              ? null
                              : () async {
                            final picked =
                            await showDatePicker(
                              context:
                              context,
                              initialDate:
                              auditDate,
                              firstDate:
                              DateTime(
                                2020,
                              ),
                              lastDate:
                              DateTime(
                                2100,
                              ),
                            );

                            if (picked ==
                                null) {
                              return;
                            }

                            setDialogState(
                                  () {
                                auditDate =
                                    picked;
                              },
                            );
                          },
                          child:
                          InputDecorator(
                            decoration:
                            const InputDecoration(
                              labelText:
                              'Audit Date *',
                              border:
                              OutlineInputBorder(),
                              prefixIcon:
                              Icon(
                                Icons
                                    .calendar_today_outlined,
                              ),
                            ),
                            child: Text(
                              _formatDate(
                                auditDate,
                              ),
                              style:
                              const TextStyle(
                                fontWeight:
                                FontWeight
                                    .w600,
                                color: _text,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // ==================================================
                        // MASTER DATA
                        // ==================================================

                        DropdownButtonFormField<
                            String>(
                          value:
                          masters.any(
                                (master) =>
                            master[
                            'master_id']
                                ?.toString() ==
                                selectedMasterId,
                          )
                              ? selectedMasterId
                              : null,
                          isExpanded: true,
                          menuMaxHeight: 360,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Audit Master Name *',
                            border:
                            OutlineInputBorder(),
                            prefixIcon:
                            Icon(
                              Icons
                                  .fact_check_outlined,
                            ),
                          ),
                          selectedItemBuilder:
                              (context) {
                            return masters
                                .map(
                                  (
                                  master,
                                  ) {
                                final name =
                                    master[
                                    'master_name']
                                        ?.toString()
                                        .trim() ??
                                        '';

                                return Align(
                                  alignment:
                                  Alignment
                                      .centerLeft,
                                  child: Text(
                                    name,
                                    maxLines:
                                    1,
                                    overflow:
                                    TextOverflow
                                        .ellipsis,
                                  ),
                                );
                              },
                            ).toList();
                          },
                          items:
                          masters.map(
                                (
                                master,
                                ) {
                              final name =
                                  master[
                                  'master_name']
                                      ?.toString()
                                      .trim() ??
                                      '';

                              final type =
                                  master[
                                  'audit_type_name']
                                      ?.toString()
                                      .trim() ??
                                      '';

                              return DropdownMenuItem<
                                  String>(
                                value:
                                master[
                                'master_id']
                                    ?.toString(),
                                child: SizedBox(
                                  width:
                                  double.infinity,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child:
                                        Text(
                                          name,
                                          maxLines:
                                          1,
                                          overflow:
                                          TextOverflow
                                              .ellipsis,
                                          style:
                                          const TextStyle(
                                            fontWeight:
                                            FontWeight
                                                .w600,
                                          ),
                                        ),
                                      ),
                                      if (type
                                          .isNotEmpty) ...[
                                        const SizedBox(
                                          width:
                                          10,
                                        ),
                                        Flexible(
                                          child:
                                          Text(
                                            type,
                                            maxLines:
                                            1,
                                            overflow:
                                            TextOverflow
                                                .ellipsis,
                                            style:
                                            const TextStyle(
                                              fontSize:
                                              11,
                                              color:
                                              _muted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ).toList(),
                          onChanged:
                          dialogSaving
                              ? null
                              : (
                              value,
                              ) {
                            setDialogState(
                                  () {
                                selectedMasterId =
                                    value;
                              },
                            );
                          },
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // ==================================================
                        // AUDITOR
                        // ==================================================

                        DropdownButtonFormField<
                            String>(
                          value:
                          auditors.any(
                                (auditor) =>
                            auditor[
                            'auditor_id']
                                ?.toString() ==
                                selectedAuditorId,
                          )
                              ? selectedAuditorId
                              : null,
                          isExpanded: true,
                          menuMaxHeight: 360,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Assign Auditor *',
                            border:
                            OutlineInputBorder(),
                            prefixIcon:
                            Icon(
                              Icons
                                  .person_outline,
                            ),
                          ),
                          selectedItemBuilder:
                              (context) {
                            return auditors
                                .map(
                                  (
                                  auditor,
                                  ) {
                                final name =
                                    auditor[
                                    'auditor_name']
                                        ?.toString()
                                        .trim() ??
                                        '';

                                final employeeId =
                                    auditor[
                                    'employee_id']
                                        ?.toString()
                                        .trim() ??
                                        '';

                                return Align(
                                  alignment:
                                  Alignment
                                      .centerLeft,
                                  child: Text(
                                    employeeId
                                        .isEmpty
                                        ? name
                                        : '$name • $employeeId',
                                    maxLines:
                                    1,
                                    overflow:
                                    TextOverflow
                                        .ellipsis,
                                  ),
                                );
                              },
                            ).toList();
                          },
                          items:
                          auditors.map(
                                (
                                auditor,
                                ) {
                              final name =
                                  auditor[
                                  'auditor_name']
                                      ?.toString()
                                      .trim() ??
                                      '';

                              final employeeId =
                                  auditor[
                                  'employee_id']
                                      ?.toString()
                                      .trim() ??
                                      '';

                              final email =
                                  auditor[
                                  'email']
                                      ?.toString()
                                      .trim() ??
                                      '';

                              return DropdownMenuItem<
                                  String>(
                                value:
                                auditor[
                                'auditor_id']
                                    ?.toString(),
                                child: SizedBox(
                                  width:
                                  double.infinity,
                                  child: Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                    crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                    children: [
                                      Text(
                                        employeeId
                                            .isEmpty
                                            ? name
                                            : '$name • $employeeId',
                                        maxLines:
                                        1,
                                        overflow:
                                        TextOverflow
                                            .ellipsis,
                                        style:
                                        const TextStyle(
                                          fontWeight:
                                          FontWeight
                                              .w600,
                                        ),
                                      ),
                                      if (email
                                          .isNotEmpty)
                                        Text(
                                          email,
                                          maxLines:
                                          1,
                                          overflow:
                                          TextOverflow
                                              .ellipsis,
                                          style:
                                          const TextStyle(
                                            fontSize:
                                            11,
                                            color:
                                            _muted,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ).toList(),
                          onChanged:
                          dialogSaving
                              ? null
                              : (
                              value,
                              ) {
                            setDialogState(
                                  () {
                                selectedAuditorId =
                                    value;
                              },
                            );
                          },
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // ==================================================
                        // STATUS
                        // ==================================================

                        DropdownButtonFormField<
                            String>(
                          value:
                          selectedStatus,
                          isExpanded: true,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Status',
                            border:
                            OutlineInputBorder(),
                            prefixIcon:
                            Icon(
                              Icons
                                  .flag_outlined,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value:
                              'Planned',
                              child:
                              Text(
                                'Planned',
                              ),
                            ),
                            DropdownMenuItem(
                              value:
                              'In Progress',
                              child:
                              Text(
                                'In Progress',
                              ),
                            ),
                            DropdownMenuItem(
                              value:
                              'Completed',
                              child:
                              Text(
                                'Completed',
                              ),
                            ),
                            DropdownMenuItem(
                              value:
                              'Cancelled',
                              child:
                              Text(
                                'Cancelled',
                              ),
                            ),
                          ],
                          onChanged:
                          dialogSaving
                              ? null
                              : (
                              value,
                              ) {
                            if (value ==
                                null) {
                              return;
                            }

                            setDialogState(
                                  () {
                                selectedStatus =
                                    value;
                              },
                            );
                          },
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // ==================================================
                        // NOTES
                        // ==================================================

                        TextField(
                          controller:
                          notesController,
                          maxLines: 3,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Notes',
                            hintText:
                            'Optional notes',
                            border:
                            OutlineInputBorder(),
                            prefixIcon:
                            Padding(
                              padding:
                              EdgeInsets.only(
                                bottom: 36,
                              ),
                              child: Icon(
                                Icons
                                    .notes_outlined,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                    dialogSaving
                        ? null
                        : () {
                      Navigator.pop(
                        dialogContext,
                      );
                    },
                    child: const Text(
                      'Cancel',
                    ),
                  ),
                  FilledButton.icon(
                    onPressed:
                    dialogSaving
                        ? null
                        : () async {
                      if (selectedMasterId ==
                          null ||
                          selectedMasterId!
                              .isEmpty) {
                        _dialogError(
                          dialogContext,
                          'Select an Audit Master Name.',
                        );
                        return;
                      }

                      if (selectedAuditorId ==
                          null ||
                          selectedAuditorId!
                              .isEmpty) {
                        _dialogError(
                          dialogContext,
                          'Select an Auditor.',
                        );
                        return;
                      }

                      Map<String,
                          dynamic>?
                      selectedMaster;

                      for (final master
                      in masters) {
                        if (master[
                        'master_id']
                            ?.toString() ==
                            selectedMasterId) {
                          selectedMaster =
                              master;
                          break;
                        }
                      }

                      Map<String,
                          dynamic>?
                      selectedAuditor;

                      for (final auditor
                      in auditors) {
                        if (auditor[
                        'auditor_id']
                            ?.toString() ==
                            selectedAuditorId) {
                          selectedAuditor =
                              auditor;
                          break;
                        }
                      }

                      if (selectedMaster ==
                          null) {
                        _dialogError(
                          dialogContext,
                          'Selected Audit Master could not be found.',
                        );
                        return;
                      }

                      if (selectedAuditor ==
                          null) {
                        _dialogError(
                          dialogContext,
                          'Selected Auditor could not be found.',
                        );
                        return;
                      }

                      final masterName =
                          selectedMaster[
                          'master_name']
                              ?.toString()
                              .trim() ??
                              '';

                      final auditTypeId =
                      selectedMaster[
                      'audit_type_id']
                          ?.toString();

                      final auditorName =
                          selectedAuditor[
                          'auditor_name']
                              ?.toString()
                              .trim() ??
                              '';

                      final auditorEmail =
                          selectedAuditor[
                          'email']
                              ?.toString()
                              .trim() ??
                              '';

                      if (masterName
                          .isEmpty) {
                        _dialogError(
                          dialogContext,
                          'Selected Audit Master is invalid.',
                        );
                        return;
                      }

                      if (auditorName
                          .isEmpty) {
                        _dialogError(
                          dialogContext,
                          'Selected Auditor is invalid.',
                        );
                        return;
                      }

                      setDialogState(
                            () {
                          dialogSaving =
                          true;
                        },
                      );

                      try {
                        Map<String,
                            dynamic>
                        saved;

                        if (isEditing) {
                          saved =
                          await SupabaseService
                              .updateAuditSchedule(
                            scheduleId:
                            existing[
                            'schedule_id']
                                .toString(),
                            auditDate:
                            auditDate,
                            typeId:
                            auditTypeId,
                            masterId:
                            selectedMasterId,
                            masterDataName:
                            masterName,
                            auditorId:
                            selectedAuditorId,
                            auditorName:
                            auditorName,
                            auditorEmail:
                            auditorEmail,
                            status:
                            selectedStatus,
                            notes:
                            notesController
                                .text
                                .trim(),
                          ).timeout(
                            const Duration(
                              seconds: 20,
                            ),
                          );
                        } else {
                          saved =
                          await SupabaseService
                              .createAuditSchedule(
                            auditDate:
                            auditDate,
                            typeId:
                            auditTypeId,
                            masterId:
                            selectedMasterId,
                            masterDataName:
                            masterName,
                            auditorId:
                            selectedAuditorId,
                            auditorName:
                            auditorName,
                            auditorEmail:
                            auditorEmail,
                            status:
                            selectedStatus,
                            notes:
                            notesController
                                .text
                                .trim(),
                          ).timeout(
                            const Duration(
                              seconds: 20,
                            ),
                          );
                        }

                        if (!mounted) {
                          return;
                        }

// selectedMaster was already validated above.
// Copy the value into a non-null local before entering
// the setState closure so Dart's null-safety analysis
// does not lose the promotion.
                        final selectedAuditTypeName =
                            selectedMaster[
                            'audit_type_name']
                                ?.toString()
                                .trim() ??
                                '';

                        setState(() {
                          if (isEditing) {
                            final index =
                            _schedules.indexWhere(
                                  (
                                  item,
                                  ) =>
                              item[
                              'schedule_id']
                                  ?.toString() ==
                                  existing[
                                  'schedule_id']
                                      ?.toString(),
                            );

                            if (index >= 0) {
                              _schedules[index] = {
                                ..._schedules[index],
                                ...saved,
                                'audit_type':
                                selectedAuditTypeName,
                              };
                            }
                          } else {
                            _schedules.add({
                              ...saved,
                              'audit_type':
                              selectedAuditTypeName,
                            });
                          }

                          _saving = false;
                        });
                        if (!dialogContext
                            .mounted) {
                          return;
                        }

                        Navigator.pop(
                          dialogContext,
                        );

                        _message(
                          isEditing
                              ? 'Schedule updated successfully.'
                              : 'Audit scheduled successfully.',
                        );
                      } catch (e) {
                        if (await AuditAdminSession.handleSessionExpired(context, e)) {
                          return;
                        }
                        if (!dialogContext
                            .mounted) {
                          return;
                        }

                        setDialogState(
                              () {
                            dialogSaving =
                            false;
                          },
                        );

                        _dialogError(
                          dialogContext,
                          'Unable to save schedule: $e',
                        );
                      }
                    },
                    icon: const Icon(
                      Icons
                          .check_circle_outline,
                    ),
                    label: Text(
                      isEditing
                          ? 'Update'
                          : 'Schedule',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      notesController.dispose();

      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // STATUS UPDATE
  // ============================================================

  Future<void> _updateStatus(
      Map<String, dynamic> schedule,
      String status,
      ) async {
    final id =
    schedule['schedule_id']
        ?.toString();

    if (id == null || id.isEmpty) {
      return;
    }

    final oldStatus =
    schedule['status']
        ?.toString();

    if (oldStatus == status) {
      return;
    }

    try {
      final updated =
      await SupabaseService
          .updateAuditScheduleStatus(
        scheduleId: id,
        status: status,
      ).timeout(
        const Duration(seconds: 20),
      );

      if (!mounted) return;

      final index =
      _schedules.indexWhere(
            (item) =>
        item['schedule_id']
            ?.toString() ==
            id,
      );

      if (index >= 0) {
        setState(() {
          _schedules[index] = {
            ..._schedules[index],
            ...updated,
            'status': status,
          };
        });
      }

      _message(
        'Schedule status updated.',
      );
    } catch (e) {
      if (await AuditAdminSession.handleSessionExpired(context, e)) {
        return;
      }
      if (!mounted) return;

      _message(
        'Unable to update status: $e',
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      _background,
      appBar: AppBar(
        backgroundColor:
        Colors.white,
        foregroundColor:
        _text,
        elevation: 0,
        title: const Text(
          'Audit Schedule',
          style: TextStyle(
            fontWeight:
            FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
            _loading
                ? null
                : _loadData,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(
            width: 8,
          ),
        ],
      ),
      body: _loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : _error != null
          ? _buildError()
          : _buildMainContent(),
      floatingActionButton:
      _loading
          ? null
          : null,
    );
  }
  List<Map<String, dynamic>>
  _getPlanningMasters() {
    if (_selectedPlanningTypeId == null) {
      return [];
    }

    final result = <Map<String, dynamic>>[];
    final seen = <String>{};

    String normalise(String value) =>
        value.trim().toLowerCase();

    // Always start with the master-data records for the selected type.
    // This keeps the planning grid independent of whether an audit has
    // already been scheduled for that master.
    for (final master in _masters) {
      final typeId = master['audit_type_id']?.toString();

      if (typeId != _selectedPlanningTypeId) {
        continue;
      }

      final masterId = master['master_id']?.toString();
      final masterName =
          master['master_name']?.toString().trim() ?? '';

      if (masterName.isEmpty) {
        continue;
      }

      final key = masterId?.isNotEmpty == true
          ? 'id:$masterId'
          : 'name:${normalise(masterName)}';

      if (seen.add(key)) {
        result.add({
          'master_id': masterId,
          'master_data_name': masterName,
        });
      }
    }

    // Also include names coming from schedules. This is deliberately a
    // fallback because older/existing schedule rows may have the copied
    // master name but not a matching type_id. The schedule itself is the
    // source of truth for displaying an already scheduled audit.
    for (final schedule in _schedules) {
      final date = _parseDate(schedule['audit_date']);

      if (date == null || date.year != _planningYear) {
        continue;
      }

      final scheduleTypeId = schedule['type_id']?.toString();
      final scheduleMasterId =
          schedule['master_data_id']?.toString() ??
              schedule['master_id']?.toString();

      final scheduleMasterName =
          schedule['master_data_name']?.toString().trim() ?? '';

      // Accept the schedule when its type matches OR when the schedule has
      // a master ID/name that belongs to one of the selected masters. This
      // prevents a stale/copied type value from hiding a real scheduled audit.
      bool belongsToSelectedType =
          scheduleTypeId == _selectedPlanningTypeId;

      if (!belongsToSelectedType && scheduleMasterId != null) {
        belongsToSelectedType = result.any(
              (master) =>
          master['master_id']?.toString() == scheduleMasterId,
        );
      }

      if (!belongsToSelectedType && scheduleMasterName.isNotEmpty) {
        belongsToSelectedType = result.any(
              (master) =>
          normalise(master['master_data_name']?.toString() ?? '') ==
              normalise(scheduleMasterName),
        );
      }

      if (!belongsToSelectedType || scheduleMasterName.isEmpty) {
        continue;
      }

      final alreadyPresent = result.any(
            (master) =>
        normalise(master['master_data_name']?.toString() ?? '') ==
            normalise(scheduleMasterName),
      );

      if (!alreadyPresent) {
        result.add({
          'master_id': scheduleMasterId,
          'master_data_name': scheduleMasterName,
        });
      }
    }

    result.sort(
          (a, b) =>
          (a['master_data_name']?.toString() ?? '')
              .toLowerCase()
              .compareTo(
            (b['master_data_name']?.toString() ?? '')
                .toLowerCase(),
          ),
    );

    return result;
  }

  List<Map<String, dynamic>>
  _getSchedulesForPlanningCell(
      Map<String, dynamic> master,
      int month,
      ) {
    final planningMasterId =
    master['master_id']?.toString().trim();

    final planningMasterName =
        master['master_data_name']?.toString().trim() ?? '';

    String normalise(String value) =>
        value.trim().toLowerCase();

    return _schedules.where(
          (schedule) {
        // --------------------------------------------------------
        // 1. YEAR + MONTH MUST MATCH
        // --------------------------------------------------------
        final date = _parseDate(
          schedule['audit_date'],
        );

        if (date == null ||
            date.year != _planningYear ||
            date.month != month) {
          return false;
        }

        // --------------------------------------------------------
        // 2. MASTER MATCH
        //
        // The master UUID is preferred, but the application also
        // stores the master name on the schedule. Older schedule
        // rows or manually-created rows can have inconsistent/null
        // IDs, so NEVER reject a valid schedule merely because the
        // IDs differ when the names clearly match.
        // --------------------------------------------------------
        final scheduleMasterId =
            schedule['master_data_id']?.toString().trim() ??
                schedule['master_id']?.toString().trim();

        final scheduleMasterName =
            schedule['master_data_name']
                ?.toString()
                .trim() ??
                '';

        final idMatches =
            planningMasterId != null &&
                planningMasterId.isNotEmpty &&
                scheduleMasterId != null &&
                scheduleMasterId.isNotEmpty &&
                planningMasterId == scheduleMasterId;

        final nameMatches =
            planningMasterName.isNotEmpty &&
                scheduleMasterName.isNotEmpty &&
                normalise(planningMasterName) ==
                    normalise(scheduleMasterName);

        // Either stable ID OR copied master name is enough.
        // This is the important fix for the missing September tick.
        return idMatches || nameMatches;
      },
    ).toList();
  }

  String _planningCellSymbol(
      List<Map<String, dynamic>> schedules,
      ) {
    if (schedules.isEmpty) {
      return '';
    }

    final hasCompleted = schedules.any(
          (schedule) =>
      schedule['status']?.toString() == 'Completed',
    );

    final hasInProgress = schedules.any(
          (schedule) =>
      schedule['status']?.toString() == 'In Progress',
    );

    final hasPlanned = schedules.any(
          (schedule) =>
      schedule['status']?.toString() == 'Planned',
    );

    final hasCancelled = schedules.any(
          (schedule) =>
      schedule['status']?.toString() == 'Cancelled',
    );

    if (hasCompleted) {
      return '✓✓';
    }

    if (hasInProgress) {
      return '✓';
    }

    if (hasPlanned) {
      return '✓';
    }

    if (hasCancelled) {
      return '×';
    }

    return '';
  }

  Color _planningCellColor(
      List<Map<String, dynamic>>
      schedules,
      ) {
    if (schedules.isEmpty) {
      return Colors.transparent;
    }

    final hasCompleted =
    schedules.any(
          (schedule) =>
      schedule['status']
          ?.toString() ==
          'Completed',
    );

    final hasCancelled =
    schedules.every(
          (schedule) =>
      schedule['status']
          ?.toString() ==
          'Cancelled',
    );

    if (hasCompleted) {
      return const Color(
        0xFFE8F7EE,
      );
    }

    if (hasCancelled) {
      return const Color(
        0xFFFDE8E8,
      );
    }

    return const Color(
      0xFFF0E9FF,
    );
  }

  Color _planningSymbolColor(
      List<Map<String, dynamic>>
      schedules,
      ) {
    if (schedules.isEmpty) {
      return const Color(
        0xFF6B7280,
      );
    }

    final hasCompleted =
    schedules.any(
          (schedule) =>
      schedule['status']
          ?.toString() ==
          'Completed',
    );

    final hasCancelled =
    schedules.every(
          (schedule) =>
      schedule['status']
          ?.toString() ==
          'Cancelled',
    );

    if (hasCompleted) {
      return const Color(
        0xFF219653,
      );
    }

    if (hasCancelled) {
      return const Color(
        0xFFD14343,
      );
    }

    return _purple;
  }
  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 1250,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LayoutBuilder(
                builder:
                    (
                    context,
                    constraints,
                    ) {
                  if (constraints.maxWidth <
                      850) {
                    return Column(
                      children: [
                        _buildSmallCalendar(),
                        const SizedBox(
                          height: 18,
                        ),
                        _buildScheduledAudits(),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      SizedBox(
                        width: 420,
                        child:
                        _buildSmallCalendar(),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      Expanded(
                        child:
                        _buildScheduledAudits(),
                      ),
                    ],
                  );
                },
              ),

              // ==========================================================
              // YEARLY AUDIT PLANNING
              // ==========================================================

              const SizedBox(
                height: 22,
              ),

              _buildYearlyPlanning(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SMALL CALENDAR
  // ============================================================

  Widget _buildSmallCalendar() {
    final daysInMonth =
        DateTime(
          _displayedMonth.year,
          _displayedMonth.month + 1,
          0,
        ).day;

    final firstWeekday =
        DateTime(
          _displayedMonth.year,
          _displayedMonth.month,
          1,
        ).weekday -
            1;

    final cellCount =
        firstWeekday + daysInMonth;

    final rowCount =
    (cellCount / 7).ceil();

    return Container(
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
          const Color(0xFFE1E5EC),
        ),
      ),
      padding:
      const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip:
                'Previous month',
                onPressed:
                _previousMonth,
                icon: const Icon(
                  Icons
                      .chevron_left_rounded,
                ),
              ),
              Expanded(
                child: Text(
                  _monthTitle(
                    _displayedMonth,
                  ),
                  textAlign:
                  TextAlign.center,
                  style:
                  const TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.w800,
                    color: _text,
                  ),
                ),
              ),
              IconButton(
                tooltip:
                'Next month',
                onPressed:
                _nextMonth,
                icon: const Icon(
                  Icons
                      .chevron_right_rounded,
                ),
              ),
            ],
          ),

          Row(
            children: const [
              _CalendarWeekDay('M'),
              _CalendarWeekDay('T'),
              _CalendarWeekDay('W'),
              _CalendarWeekDay('T'),
              _CalendarWeekDay('F'),
              _CalendarWeekDay('S'),
              _CalendarWeekDay('S'),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          GridView.builder(
            shrinkWrap: true,
            physics:
            const NeverScrollableScrollPhysics(),
            itemCount:
            rowCount * 7,
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.15,
            ),
            itemBuilder:
                (
                context,
                index,
                ) {
              if (index <
                  firstWeekday) {
                return const SizedBox();
              }

              final day =
                  index -
                      firstWeekday +
                      1;

              if (day >
                  daysInMonth) {
                return const SizedBox();
              }

              final date =
              DateTime(
                _displayedMonth
                    .year,
                _displayedMonth
                    .month,
                day,
              );

              final schedules =
              _schedulesForDate(
                date,
              );

              final selected =
              _sameDate(
                date,
                _selectedDate,
              );

              final today =
              _sameDate(
                date,
                DateTime.now(),
              );

              return InkWell(
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
                onTap: () {
                  setState(() {
                    _selectedDate =
                        date;
                  });
                },
                child: Container(
                  margin:
                  const EdgeInsets
                      .all(
                    2,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    selected
                        ? const Color(
                      0xFFF0E9FF,
                    )
                        : Colors
                        .transparent,
                    borderRadius:
                    BorderRadius
                        .circular(
                      10,
                    ),
                    border:
                    today
                        ? Border.all(
                      color:
                      _purple,
                      width:
                      1.4,
                    )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                    children: [
                      Text(
                        '$day',
                        style:
                        TextStyle(
                          fontSize:
                          12,
                          fontWeight:
                          selected ||
                              today
                              ? FontWeight
                              .w800
                              : FontWeight
                              .w500,
                          color:
                          selected
                              ? _purple
                              : _text,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      if (schedules
                          .isNotEmpty)
                        _calendarIndicator(
                          schedules
                              .first[
                          'status']
                              ?.toString(),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(
            height: 14,
          ),

          Row(
            mainAxisAlignment:
            MainAxisAlignment
                .center,
            children: [
              _legend(
                '✓',
                'Planned',
              ),
              const SizedBox(
                width: 14,
              ),
              _legend(
                '•',
                'In Progress',
              ),
              const SizedBox(
                width: 14,
              ),
              _legend(
                '✓✓',
                'Completed',
              ),
              const SizedBox(
                width: 14,
              ),
              _legend(
                '×',
                'Cancelled',
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          TextButton(
            onPressed: _goToday,
            child:
            const Text(
              'Go to Today',
            ),
          ),
        ],
      ),
    );
  }

  Widget _calendarIndicator(
      String? status,
      ) {
    String value;

    switch (status) {
      case 'Completed':
        value = '✓✓';
        break;

      case 'In Progress':
        value = '•';
        break;

      case 'Cancelled':
        value = '×';
        break;

      default:
        value = '✓';
    }

    return Text(
      value,
      style:
      TextStyle(
        fontSize: 10,
        fontWeight:
        FontWeight.w900,
        color:
        _statusForeground(
          status ?? 'Planned',
        ),
      ),
    );
  }

  Widget _legend(
      String symbol,
      String label,
      ) {
    return Row(
      mainAxisSize:
      MainAxisSize.min,
      children: [
        Text(
          symbol,
          style:
          const TextStyle(
            fontWeight:
            FontWeight.w900,
            color: _purple,
            fontSize: 12,
          ),
        ),
        const SizedBox(
          width: 4,
        ),
        Text(
          label,
          style:
          const TextStyle(
            color: _muted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SCHEDULED AUDITS
  // ============================================================

  Widget _buildScheduledAudits() {
    final schedules =
    _schedulesForDate(
      _selectedDate,
    );

    return Container(
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
          const Color(0xFFE1E5EC),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .stretch,
        children: [
          Padding(
            padding:
            const EdgeInsets.fromLTRB(
              20,
              18,
              14,
              16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      const Text(
                        'Scheduled Audits',
                        style:
                        TextStyle(
                          fontSize: 19,
                          fontWeight:
                          FontWeight.w800,
                          color: _text,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        _formatDate(
                          _selectedDate,
                        ),
                        style:
                        const TextStyle(
                          color: _muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed:
                  _saving
                      ? null
                      : _addSchedule,
                  icon:
                  const Icon(
                    Icons.add,
                    size: 18,
                  ),
                  label:
                  const Text(
                    'Schedule Audit',
                  ),
                ),
              ],
            ),
          ),

          const Divider(
            height: 1,
          ),

          schedules.isEmpty
              ? _emptyScheduledAudits()
              : ListView.separated(
            shrinkWrap: true,
            physics:
            const NeverScrollableScrollPhysics(),
            padding:
            const EdgeInsets
                .all(
              14,
            ),
            itemCount:
            schedules.length,
            separatorBuilder:
                (
                context,
                index,
                ) =>
            const SizedBox(
              height: 10,
            ),
            itemBuilder:
                (
                context,
                index,
                ) {
              return _buildScheduleCard(
                schedules[index],
              );
            },
          ),
        ],
      ),
    );
  }
  Widget _buildYearlyPlanning() {
    final masters =
    _getPlanningMasters();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Container(
      width: double.infinity,
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
            0xFFE1E5EC,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .stretch,
        children: [
          // ========================================================
          // HEADER
          // ========================================================

          Padding(
            padding:
            const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              14,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      const Text(
                        'Audit Planning',
                        style:
                        TextStyle(
                          fontSize: 19,
                          fontWeight:
                          FontWeight.w800,
                          color: _text,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      const Text(
                        'Yearly audit plan by Audit Master and month',
                        style:
                        TextStyle(
                          color: _muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // AUDIT TYPE DROPDOWN
                // ==================================================

                SizedBox(
                  width: 230,
                  child:
                  DropdownButtonFormField<
                      String>(
                    value:
                    _auditTypes.any(
                          (type) =>
                      type['type_id']
                          ?.toString() ==
                          _selectedPlanningTypeId,
                    )
                        ? _selectedPlanningTypeId
                        : null,
                    isExpanded: true,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'Audit Type',
                      prefixIcon:
                      Icon(
                        Icons
                            .category_outlined,
                        size: 19,
                      ),
                      border:
                      OutlineInputBorder(),
                      contentPadding:
                      EdgeInsets
                          .symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items:
                    _auditTypes.map(
                          (
                          type,
                          ) {
                        final id =
                        type['type_id']
                            ?.toString();

                        final name =
                            type['audit_type']
                                ?.toString()
                                .trim() ??
                                '';

                        return DropdownMenuItem<
                            String>(
                          value: id,
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                          ),
                        );
                      },
                    ).toList(),
                    onChanged:
                        (
                        value,
                        ) {
                      setState(() {
                        _selectedPlanningTypeId =
                            value;
                      });
                    },
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                // ==================================================
                // YEAR
                // ==================================================

                Container(
                  decoration:
                  BoxDecoration(
                    border: Border.all(
                      color:
                      const Color(
                        0xFFD9DDE5,
                      ),
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      10,
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip:
                        'Previous year',
                        onPressed:
                            () {
                          setState(() {
                            _planningYear--;
                          });
                        },
                        icon:
                        const Icon(
                          Icons
                              .chevron_left,
                          size: 19,
                        ),
                      ),
                      Text(
                        '$_planningYear',
                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight.w800,
                          color: _text,
                        ),
                      ),
                      IconButton(
                        tooltip:
                        'Next year',
                        onPressed:
                            () {
                          setState(() {
                            _planningYear++;
                          });
                        },
                        icon:
                        const Icon(
                          Icons
                              .chevron_right,
                          size: 19,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(
            height: 1,
          ),

          // ========================================================
          // PLANNING TABLE
          // ========================================================

          if (_auditTypes.isEmpty)
            const Padding(
              padding:
              EdgeInsets.all(
                40,
              ),
              child: Center(
                child: Text(
                  'No Audit Types available.',
                  style:
                  TextStyle(
                    color: _muted,
                  ),
                ),
              ),
            )
          else if (_selectedPlanningTypeId ==
              null)
            const Padding(
              padding:
              EdgeInsets.all(
                40,
              ),
              child: Center(
                child: Text(
                  'Select an Audit Type to view the yearly plan.',
                  style:
                  TextStyle(
                    color: _muted,
                  ),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection:
              Axis.horizontal,
              child: DataTable(
                headingRowHeight:
                48,
                dataRowMinHeight:
                54,
                dataRowMaxHeight:
                54,
                horizontalMargin:
                16,
                columnSpacing:
                12,
                headingRowColor:
                WidgetStateProperty
                    .resolveWith(
                      (
                      states,
                      ) =>
                  const Color(
                    0xFFF8F9FC,
                  ),
                ),
                columns: [
                  const DataColumn(
                    label: SizedBox(
                      width: 210,
                      child: Text(
                        'Audit Master',
                        style:
                        TextStyle(
                          fontWeight:
                          FontWeight.w800,
                          color: _text,
                        ),
                      ),
                    ),
                  ),
                  ...months.map(
                        (
                        month,
                        ) {
                      return DataColumn(
                        label: SizedBox(
                          width: 58,
                          child: Center(
                            child: Text(
                              month,
                              style:
                              const TextStyle(
                                fontWeight:
                                FontWeight.w800,
                                color:
                                _text,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                rows: masters.isEmpty
                    ? [
                  const DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 210,
                          child:
                          Text(
                            'No Audit Master Data',
                            style:
                            TextStyle(
                              color:
                              _muted,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(),
                      ),
                      DataCell(
                        SizedBox(),
                      ),
                      DataCell(
                        SizedBox(),
                      ),
                      DataCell(
                        SizedBox(),
                      ),
                      DataCell(
                        SizedBox(),
                      ),
                      DataCell(
                        SizedBox(),
                      ),
                      DataCell(
                        SizedBox(),
                      ),
                      DataCell(
                        SizedBox(),
                      ),
                      DataCell(
                        SizedBox(),
                      ),
                      DataCell(
                        SizedBox(),
                      ),
                      DataCell(
                        SizedBox(),
                      ),
                      DataCell(
                        SizedBox(),
                      ),
                    ],
                  ),
                ]
                    : masters.map(
                      (
                      master,
                      ) {
                    final masterName =
                        master['master_data_name']
                            ?.toString()
                            .trim() ??
                            '';

                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width:
                            210,
                            child:
                            Text(
                              masterName,
                              maxLines:
                              1,
                              overflow:
                              TextOverflow
                                  .ellipsis,
                              style:
                              const TextStyle(
                                fontWeight:
                                FontWeight
                                    .w700,
                                color:
                                _text,
                              ),
                            ),
                          ),
                        ),
                        ...List.generate(
                          12,
                              (
                              index,
                              ) {
                            final month =
                                index +
                                    1;

                            final cellSchedules =
                            _getSchedulesForPlanningCell(
                              master,
                              month,
                            );

                            final symbol =
                            _planningCellSymbol(
                              cellSchedules,
                            );

                            return DataCell(
                              Center(
                                child:
                                Tooltip(
                                  message:
                                  cellSchedules.isEmpty
                                      ? 'No audit scheduled'
                                      : cellSchedules
                                      .map(
                                        (
                                        schedule,
                                        ) =>
                                    '${schedule['auditor_name'] ?? ''} • ${schedule['status'] ?? ''}',
                                  )
                                      .join(
                                    '\n',
                                  ),
                                  child:
                                  Container(
                                    width:
                                    38,
                                    height:
                                    32,
                                    alignment:
                                    Alignment
                                        .center,
                                    decoration:
                                    BoxDecoration(
                                      color:
                                      _planningCellColor(
                                        cellSchedules,
                                      ),
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                        8,
                                      ),
                                    ),
                                    child:
                                    Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          symbol,
                                          style:
                                          TextStyle(
                                            fontWeight:
                                            FontWeight.w900,
                                            fontSize: 13,
                                            color:
                                            _planningSymbolColor(
                                              cellSchedules,
                                            ),
                                          ),
                                        ),
                                        if (cellSchedules.length > 1)
                                          Text(
                                            '${cellSchedules.length}',
                                            style: const TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w700,
                                              color: _muted,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ).toList(),
              ),
            ),

          // ========================================================
          // LEGEND
          // ========================================================

          Padding(
            padding:
            const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              16,
            ),
            child: Row(
              children: [
                _planningLegend(
                  '✓',
                  'Planned',
                ),
                const SizedBox(
                  width: 18,
                ),
                _planningLegend(
                  '✓',
                  'In Progress',
                ),
                const SizedBox(
                  width: 18,
                ),
                _planningLegend(
                  '✓✓',
                  'Completed',
                ),
                const SizedBox(
                  width: 18,
                ),
                _planningLegend(
                  '×',
                  'Cancelled',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _planningLegend(
      String symbol,
      String label,
      ) {
    return Row(
      mainAxisSize:
      MainAxisSize.min,
      children: [
        Text(
          symbol,
          style:
          const TextStyle(
            fontSize: 12,
            fontWeight:
            FontWeight.w900,
            color: _purple,
          ),
        ),
        const SizedBox(
          width: 5,
        ),
        Text(
          label,
          style:
          const TextStyle(
            fontSize: 11,
            color: _muted,
          ),
        ),
      ],
    );
  }

  Widget _emptyScheduledAudits() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          35,
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xFFF0E9FF,
                ),
                borderRadius:
                BorderRadius.circular(
                  16,
                ),
              ),
              child: const Icon(
                Icons
                    .event_available_outlined,
                color: _purple,
                size: 28,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              'No audits scheduled',
              style:
              TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.w700,
                color: _text,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            const Text(
              'Schedule an audit for this date.',
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                color: _muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(
      Map<String, dynamic> schedule,
      ) {
    final status =
        schedule['status']
            ?.toString() ??
            'Planned';

    final scheduleNumber =
        schedule['schedule_number']
            ?.toString() ??
            '';

    final masterName =
        schedule['master_data_name']
            ?.toString() ??
            '';

    final auditorName =
        schedule['auditor_name']
            ?.toString() ??
            '';

    final auditorEmail =
        schedule['auditor_email']
            ?.toString() ??
            '';

    final auditType =
        schedule['audit_type']
            ?.toString() ??
            schedule[
            'audit_type_name']
                ?.toString() ??
            '';

    return Container(
      padding:
      const EdgeInsets.all(
        14,
      ),
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFFAFBFD),
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color:
          const Color(0xFFE4E7ED),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFFF0E9FF,
              ),
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
            child: Center(
              child:
              _calendarIndicator(
                status,
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        scheduleNumber,
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight.w800,
                          color: _text,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    _statusBadge(
                      status,
                    ),
                  ],
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  masterName,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.w700,
                    color: _text,
                    fontSize: 14,
                  ),
                ),

                if (auditType
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    auditType,
                    maxLines: 1,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style:
                    const TextStyle(
                      color: _muted,
                      fontSize: 11,
                    ),
                  ),
                ],

                const SizedBox(
                  height: 7,
                ),

                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    _smallDetail(
                      Icons
                          .person_outline,
                      auditorName,
                    ),
                    if (auditorEmail
                        .trim()
                        .isNotEmpty)
                      _smallDetail(
                        Icons
                            .mail_outline,
                        auditorEmail,
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          PopupMenuButton<String>(
            tooltip:
            'Schedule actions',
            onSelected:
                (value) {
              if (value == 'edit') {
                _editSchedule(
                  schedule,
                );
              }

              if (value == 'delete') {
                _deleteSchedule(
                  schedule,
                );
              }
            },
            itemBuilder:
                (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons
                          .edit_outlined,
                      size: 18,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Edit',
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons
                          .delete_outline,
                      size: 18,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Delete',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallDetail(
      IconData icon,
      String text,
      ) {
    return Row(
      mainAxisSize:
      MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: _muted,
        ),
        const SizedBox(
          width: 4,
        ),
        ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 220,
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style:
            const TextStyle(
              fontSize: 11,
              color: _muted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(
      String status,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration:
      BoxDecoration(
        color:
        _statusBackground(
          status,
        ),
        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        status,
        style:
        TextStyle(
          fontSize: 10,
          fontWeight:
          FontWeight.w700,
          color:
          _statusForeground(
            status,
          ),
        ),
      ),
    );
  }

  Color _statusBackground(
      String status,
      ) {
    switch (status) {
      case 'Completed':
        return const Color(
          0xFFE8F7EE,
        );

      case 'In Progress':
        return const Color(
          0xFFFFF3D9,
        );

      case 'Cancelled':
        return const Color(
          0xFFFDE8E8,
        );

      default:
        return const Color(
          0xFFF0E9FF,
        );
    }
  }

  Color _statusForeground(
      String status,
      ) {
    switch (status) {
      case 'Completed':
        return const Color(
          0xFF219653,
        );

      case 'In Progress':
        return const Color(
          0xFFB77900,
        );

      case 'Cancelled':
        return const Color(
          0xFFD14343,
        );

      default:
        return _purple;
    }
  }

  // ============================================================
  // ERROR / MESSAGE
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Container(
        constraints:
        const BoxConstraints(
          maxWidth: 620,
        ),
        margin:
        const EdgeInsets.all(
          24,
        ),
        padding:
        const EdgeInsets.all(
          28,
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
              0xFFE1E5EC,
            ),
          ),
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Icon(
              Icons
                  .error_outline_rounded,
              size: 48,
              color:
              Colors.red.shade400,
            ),
            const SizedBox(
              height: 14,
            ),
            const Text(
              'Unable to load Audit Schedule',
              style:
              TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.w800,
                color: _text,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              _error ?? '',
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                color: _muted,
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            FilledButton.icon(
              onPressed:
              _loadData,
              icon: const Icon(
                Icons.refresh,
              ),
              label:
              const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _message(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  void _dialogError(
      BuildContext context,
      String message,
      ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================================
// CALENDAR WEEK DAY
// ============================================================

class _CalendarWeekDay
    extends StatelessWidget {
  final String label;

  const _CalendarWeekDay(
      this.label,
      );

  @override
  Widget build(
      BuildContext context,
      ) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style:
          const TextStyle(
            fontSize: 11,
            fontWeight:
            FontWeight.w700,
            color:
            Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}