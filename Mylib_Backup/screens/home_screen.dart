// import 'package:flutter/material.dart';
// import '../services/app_data.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() =>
//       _HomeScreenState();
// }
//
// class _HomeScreenState
//     extends State<HomeScreen>  {
//   DateTimeRange? customRange;
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//
//     setState(() {});
//   }
//   Map<String, int> getStats(List records) {
//
//     int total = records.length;
//
//     int pass = records
//         .where((e) => e.result == "ACCEPTABLE")
//         .length;
//
//     int fail = records
//         .where((e) =>
//     e.result == "UNACCEPTABLE" ||
//         e.result == "NOT ACCEPTABLE")
//         .length;
//
//     return {
//       "total": total,
//       "pass": pass,
//       "fail": fail,
//     };
//   }
//
//   List getTodayRecords() {
//
//     final today = DateTime.now();
//
//     return AppData.previousArrs.where((e) {
//
//       final p = e.date.split('/');
//
//       final d = DateTime(
//         int.parse(p[2]),
//         int.parse(p[1]),
//         int.parse(p[0]),
//       );
//
//       return d.year == today.year &&
//           d.month == today.month &&
//           d.day == today.day;
//
//     }).toList();
//
//   }
//
//   List getYesterdayRecords() {
//
//     final yesterday =
//     DateTime.now().subtract(
//       const Duration(days: 1),
//     );
//
//     return AppData.previousArrs.where((e) {
//
//       final p = e.date.split('/');
//
//       final d = DateTime(
//         int.parse(p[2]),
//         int.parse(p[1]),
//         int.parse(p[0]),
//       );
//
//       return d.year == yesterday.year &&
//           d.month == yesterday.month &&
//           d.day == yesterday.day;
//
//     }).toList();
//
//   }
//   List getCustomRecords() {
//
//     if (customRange == null) {
//       return [];
//     }
//
//     return AppData.previousArrs.where((e) {
//
//       final p = e.date.split('/');
//
//       final d = DateTime(
//         int.parse(p[2]),
//         int.parse(p[1]),
//         int.parse(p[0]),
//       );
//
//       return !d.isBefore(customRange!.start) &&
//           !d.isAfter(customRange!.end);
//
//     }).toList();
//
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Digital ARR"), centerTitle: true),
//         body: SafeArea(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//           children: [
//             const SizedBox(height: 40),
//
//             Image.asset('assets/full_logo.png', height: 90),
//
//             const SizedBox(height: 20),
//
//             const SizedBox(height: 40),
//             Column(
//
//               children: [
//
//                 _statsCard(
//                   "Overall",
//                   getStats(AppData.previousArrs),
//                 ),
//
//                 const SizedBox(height: 12),
//
//                 _statsCard(
//                   "Today",
//                   getStats(getTodayRecords()),
//                 ),
//
//                 const SizedBox(height: 12),
//
//                 _statsCard(
//                   "Yesterday",
//                   getStats(getYesterdayRecords()),
//                 ),
//
//                 const SizedBox(height: 12),
//
//                 Card(
//
//                   child: Padding(
//
//                     padding: const EdgeInsets.all(12),
//
//                     child: Column(
//
//                       children: [
//
//                         Row(
//
//                           mainAxisAlignment:
//                           MainAxisAlignment.spaceBetween,
//
//                           children: [
//
//                             const Text(
//                               "Custom Date",
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 18,
//                               ),
//                             ),
//
//                             ElevatedButton.icon(
//
//                               icon: const Icon(Icons.date_range),
//
//                               label: const Text("Select"),
//
//                               onPressed: () async {
//
//                                 final range =
//                                 await showDateRangePicker(
//
//                                   context: context,
//
//                                   firstDate: DateTime(2020),
//
//                                   lastDate: DateTime(2100),
//
//                                 );
//
//                                 if (range != null) {
//
//                                   setState(() {
//
//                                     customRange = range;
//
//                                   });
//
//                                 }
//
//                               },
//
//                             ),
//
//                           ],
//
//                         ),
//
//                         if (customRange != null)
//
//                           Padding(
//
//                             padding:
//                             const EdgeInsets.only(top: 12),
//
//                             child: _statsRow(
//                               getStats(getCustomRecords()),
//                             ),
//
//                           ),
//
//                       ],
//
//                     ),
//
//                   ),
//
//                 ),
//
//               ],
//
//             ),
//             SizedBox(
//               width: double.infinity,
//               height: 55,
//               child: ElevatedButton(
//                 onPressed: () {
//                   AppData.currentTrail = 1;
//
//                   AppData.resetAssessment();
//
//                   AppData.finalClassification = "";
//
//                   AppData.certificateNo = "";
//                   Navigator.pushNamed(context, '/candidate');
//                 },
//                 child: const Text("New ARR"),
//               ),
//             ),
//
//             const SizedBox(height: 20),
//
//             SizedBox(
//               width: double.infinity,
//               height: 55,
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.pushNamed(context, '/previous');
//                 },
//                 child: const Text("View Previous ARRs"),
//               ),
//             ),
//             const SizedBox(height: 15),
//             const SizedBox(height: 15),
//
//             ElevatedButton.icon(
//               icon: const Icon(Icons.admin_panel_settings),
//
//               label: const Text("Admin Panel"),
//
//               onPressed: () {
//                 final controller = TextEditingController();
//
//                 showDialog(
//                   context: context,
//                   useSafeArea: true,
//
//                   builder: (context) {
//                     return
//                         AlertDialog(
//                           insetPadding: const EdgeInsets.symmetric(
//                             horizontal: 40,
//                             vertical: 24,
//                           ),
//
//                           title: const Text("Admin Password"),
//
//                           content: ConstrainedBox(
//                             constraints: const BoxConstraints(
//                               maxWidth: 320,
//                             ),
//                             child: TextField(
//                               controller: controller,
//                               obscureText: true,
//                               textInputAction: TextInputAction.done,
//                               decoration: const InputDecoration(
//                                 hintText: "Enter Password",
//                                 border: OutlineInputBorder(),
//                                 contentPadding: EdgeInsets.symmetric(
//                                   horizontal: 12,
//                                   vertical: 12,
//                                 ),
//                               ),
//                             ),
//                           ),
//
//                           actions: [
//                         TextButton(
//                           onPressed: () {
//                             Navigator.pop(context);
//                           },
//
//                           child: const Text("Cancel"),
//                         ),
//
//                         ElevatedButton(
//                           onPressed: () {
//                             if (controller.text == "admin123") {
//                               Navigator.pop(context);
//
//                               Navigator.pushNamed(context, '/admin');
//                             } else {
//                               Navigator.pop(context);
//
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                   content: Text("Incorrect Admin Password"),
//                                   backgroundColor: Colors.red,
//                                 ),
//
//                               );
//                             }
//                           },
//
//                           child: const Text("Open"),
//                         ),
//                       ],
//                     );
//                   },
//                 );
//               },
//             ),
//
//           ],
//         ),
//       ),
//         ),
//     );
//   }
// }
// import '../services/email_service.dart';
// import 'package:flutter/material.dart';
// import '../services/app_data.dart';
// import '../services/hive_service.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../services/app_data.dart';
import '../services/email_service.dart';
import '../services/hive_service.dart';
import '../services/supabase_service.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  DateTimeRange? customRange;

  String selectedFilter = "Overall";

// ============================================================
// DASHBOARD STATISTICS
// These are independent from Previous ARR records.
// ============================================================

  int _totalArr = 0;
  int _passedArr = 0;
  int _failedArr = 0;

  bool _loadingDashboardStats = true;

  bool _sendingOtp = false;

  bool _verifyingOtp = false;

  Timer? _otpTimer;

  int _secondsRemaining = 60;

  bool _canResendOtp = false;

  @override
  void initState() {
    super.initState();

    _loadDashboardStats();
  }

  Map<String, int> _filterStats = {
    "total": 0,
    "pass": 0,
    "fail": 0,
  };

  bool _loadingFilterStats = false;

  Future<void> _loadStatsForFilter(
      String filter, {
        DateTimeRange? range,
      }) async {

    if (!mounted) return;

    setState(() {
      _loadingFilterStats = true;
    });

    try {

      DateTime? startDate;
      DateTime? endDate;

      final now = DateTime.now();

      if (filter == "Today") {

        final today = DateTime(
          now.year,
          now.month,
          now.day,
        );

        startDate = today;
        endDate = today;

      } else if (filter == "Yesterday") {

        final yesterday = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(
          const Duration(days: 1),
        );

        startDate = yesterday;
        endDate = yesterday;

      } else if (filter == "Custom" && range != null) {

        startDate = DateTime(
          range.start.year,
          range.start.month,
          range.start.day,
        );

        endDate = DateTime(
          range.end.year,
          range.end.month,
          range.end.day,
        );
      }

      final stats =
      await SupabaseService.getArrDashboardStats(
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) return;

      setState(() {

        _filterStats = {
          "total": stats["total"] ?? 0,
          "pass": stats["passed"] ?? 0,
          "fail": stats["failed"] ?? 0,
        };

        _loadingFilterStats = false;
      });

    } catch (e) {

      if (!mounted) return;

      setState(() {
        _loadingFilterStats = false;
      });

      debugPrint(
        "Dashboard filter stats error: $e",
      );
    }
  }
  @override
  void dispose() {

    _otpTimer?.cancel();

    super.dispose();

  }
  void _startOtpTimer() {

    _otpTimer?.cancel();

    _secondsRemaining = 60;

    _canResendOtp = false;

    _otpTimer = Timer.periodic(

      const Duration(seconds: 1),

          (timer) {

        if (_secondsRemaining == 0) {

          timer.cancel();

          if (mounted) {

            setState(() {

              _canResendOtp = true;

            });

          }

        } else {

          if (mounted) {

            setState(() {

              _secondsRemaining--;

            });

          }

        }

      },

    );

  }
  Future<void> _loadDashboardStats() async {

    try {

      final stats =
      await SupabaseService.getArrDashboardStats();

      if (!mounted) return;

      setState(() {

        _totalArr =
            stats['total'] ?? 0;

        _passedArr =
            stats['passed'] ?? 0;

        _failedArr =
            stats['failed'] ?? 0;

        _loadingDashboardStats = false;
      });

    } catch (e) {

      if (!mounted) return;

      setState(() {

        _loadingDashboardStats = false;
      });
    }
  }
// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     appBar: AppBar(
//       title: const Text("Digital ARR"),
//       centerTitle: true,
//     ),
//
//     body: SafeArea(
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//
//         child: Column(
//           children: [
//
//             const SizedBox(height: 20),
//
//             Image.asset(
//               'assets/full_logo.png',
//               height: 90,
//             ),
//
//             const SizedBox(height: 60),
//
//             Builder(
//
//               builder: (context) {
//
//                 Map<String, int> stats =
//                 getStats(AppData.previousArrs);
//
//                 String title = "Overall Statistics";
//
//                 IconData icon = Icons.analytics;
//
//                 Color color = Colors.blue;
//
//                 if (selectedFilter == "Today") {
//
//                   stats = getStats(getTodayRecords());
//
//                   title = "Today's Statistics";
//
//                   icon = Icons.today;
//
//                   color = Colors.green;
//
//                 }
//
//                 if (selectedFilter == "Yesterday") {
//
//                   stats = getStats(getYesterdayRecords());
//
//                   title = "Yesterday's Statistics";
//
//                   icon = Icons.history;
//
//                   color = Colors.orange;
//
//                 }
//
//                 if (selectedFilter == "Custom") {
//
//                   stats = getStats(getCustomRecords());
//
//                   title = "Custom Date Statistics";
//
//                   icon = Icons.date_range;
//
//                   color = Colors.deepPurple;
//
//                 }
//
//                 return Column(
//
//                   children: [
//
//                 AnimatedSwitcher(
//                 duration: const Duration(milliseconds: 300),
//                 child: Container(
//                 key: ValueKey(selectedFilter),
//                 child: _statsCard(
//                 title,
//                 stats,
//                 icon,
//                 color,
//                 ),
//                 ),
//                 ),
//
//                     const SizedBox(height: 20),
//
//                 SizedBox(
//                 width: double.infinity,
//                 child: SegmentedButton<String>(
//                   style: ButtonStyle(
//                     visualDensity: VisualDensity.compact,
//                     padding: WidgetStateProperty.all(
//                       const EdgeInsets.symmetric(
//                         horizontal: 6,
//                         vertical: 10,
//                       ),
//                     ),
//                   ),
//                 showSelectedIcon: false,
//
//                 segments: const [
//
//                   ButtonSegment(
//                     value: "Overall",
//                     label: const Text(
//                       "All",
//                       style: TextStyle(fontSize: 12),
//                     ),
//                     icon: const Icon(Icons.analytics_outlined, size: 18),
//                   ),
//
//                 ButtonSegment(
//                 value: "Today",
//                   label: const Text(
//                     "Today",
//                     style: TextStyle(fontSize: 12),
//                   ),
//                 icon: Icon(Icons.today_outlined),
//                 ),
//
//                 ButtonSegment(
//                 value: "Yesterday",
//                   label: const Text(
//                     "Last day",
//                     style: TextStyle(fontSize: 12),
//                   ),
//                 icon: Icon(Icons.history),
//                 ),
//
//                 ButtonSegment(
//                 value: "Custom",
//                   label: const Text(
//                     "Range",
//                     style: TextStyle(fontSize: 12),//10.9),
//                   ),
//                 icon: Icon(Icons.date_range),
//                 ),
//
//                 ],
//
//                 selected: {selectedFilter},
//
//                 onSelectionChanged: (value) async {
//
//                 if (value.first == "Custom") {
//
//                 final range = await showDateRangePicker(
//
//                 context: context,
//
//                 firstDate: DateTime(2020),
//
//                 lastDate: DateTime(2100),
//
//                 );
//
//                 if (range != null) {
//
//                 setState(() {
//
//                 customRange = range;
//
//                 selectedFilter = "Custom";
//
//                 });
//
//                 }
//
//                 } else {
//
//                 setState(() {
//
//                 selectedFilter = value.first;
//
//                 });
//
//                 }
//
//                 },
//
//                 ),
//                 ),
//
//                 const SizedBox(height: 60),
//
//                   ],
//                 );
//
//               },
//
//             ),
//             SizedBox(
//               width: double.infinity,
//               height: 55,
//               child: ElevatedButton(
//                 onPressed: () async {
//                   AppData.resetAssessment();
//
//                   await Navigator.pushNamed(
//                     context,
//                     '/candidate',
//                   );
//
//                   if (mounted) {
//                     setState(() {});
//                   }
//                 },
//                 child: const Text("New ARR"),
//               ),
//             ),
//
//             const SizedBox(height: 20),
//
//             SizedBox(
//               width: double.infinity,
//               height: 55,
//               child: ElevatedButton(
//                 onPressed: () async {
//                   await Navigator.pushNamed(
//                     context,
//                     '/previous',
//                   );
//
//                   if (mounted) {
//                     setState(() {});
//                   }
//                 },
//                 child: const Text("View Previous ARRs"),
//               ),
//             ),
//
//             const SizedBox(height: 20),
//
//             SizedBox(
//               width: double.infinity,
//               height: 55,
//               child: ElevatedButton.icon(
//
//                 icon: const Icon(
//                   Icons.admin_panel_settings,
//                 ),
//
//                 label: const Text(
//                   "Admin Panel",
//                 ),
//
//                 onPressed: () {
//                   final controller =
//                   TextEditingController();
//
//                   showDialog(
//
//                     context: context,
//
//                     builder: (context) {
//                       return AlertDialog(
//
//                         title: const Text(
//                           "Admin Password",
//                         ),
//
//                         content: Column(
//
//                           mainAxisSize: MainAxisSize.min,
//
//                           children: [
//
//                             TextField(
//
//                               controller: controller,
//
//                               obscureText: true,
//
//                               decoration: const InputDecoration(
//
//                                 hintText: "Enter Password",
//
//                                 border: OutlineInputBorder(),
//
//                               ),
//
//                             ),
//
//                             const SizedBox(height: 10),
//
//                             Align(
//
//                               alignment: Alignment.centerRight,
//
//                               child: TextButton(
//
//                                 onPressed: () {
//
//                                   Navigator.pop(context);
//
//                                   _showForgotPasswordDialog();
//
//                                 },
//
//                                 child: const Text(
//                                   "Forgot Password?",
//                                 ),
//
//                               ),
//
//                             ),
//
//                           ],
//
//                         ),
//
//                         actions: [
//
//                           TextButton(
//
//                             onPressed: () {
//                               Navigator.pop(context);
//                             },
//
//                             child: const Text("Cancel"),
//
//                           ),
//
//                           TextButton(
//
//                             onPressed: () {
//
//                               Navigator.pop(context);
//
//                               _showChangePasswordDialog();
//
//                             },
//
//                             child: const Text("Change Password"),
//
//                           ),
//
//                           ElevatedButton(
//
//                             onPressed: () {
//
//                               if (controller.text ==
//                                   HiveService.getAdminPassword()) {
//
//                                 Navigator.pop(context);
//
//                                 Navigator.pushNamed(
//                                   context,
//                                   '/admin',
//                                 );
//
//                               } else {
//
//                                 Navigator.pop(context);
//
//                                 ScaffoldMessenger.of(context).showSnackBar(
//
//                                   const SnackBar(
//                                     content: Text("Incorrect Admin Password"),
//                                     backgroundColor: Colors.red,
//                                   ),
//
//                                 );
//
//                               }
//
//                             },
//
//                             child: const Text("Open"),
//
//                           ),
//
//                         ],
//                       );
//                     },
//
//                   );
//                 },
//
//               ),
//             ),
//
//             const SizedBox(height: 20),
//
//           ],
//         ),
//       ),
//     ),
//   );
// }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,

        titleSpacing: 24,

        title: Row(
          children: [
            Image.asset(
              'assets/full_logo.png',
              height: 38,
              fit: BoxFit.contain,
            ),

            const SizedBox(width: 14),

            Container(
              width: 1,
              height: 28,
              color: Colors.grey.withValues(alpha: 0.25),
            ),

            const SizedBox(width: 14),

            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Digital ARR",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202124),
                  ),
                ),
                Text(
                  "Attribute Repeatability & Reproducibility",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),

        actions: [
          Container(
            margin: const EdgeInsets.only(right: 24),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EE),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFB8DFC3),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: Color(0xFF249447),
                ),
                SizedBox(width: 7),
                Text(
                  "System Ready",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF237A3A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              32,
              28,
              32,
              40,
            ),

            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1250,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // --------------------------------------------------
                  // HEADER
                  // --------------------------------------------------

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 24,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFE5E5EA),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),

                    child: Row(
                      children: [

                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF3FF),
                            borderRadius: BorderRadius.circular(14),
                          ),

                          child: const Icon(
                            Icons.dashboard_rounded,
                            size: 28,
                            color: Color(0xFF3155C6),
                          ),
                        ),

                        const SizedBox(width: 18),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,

                            children: [
                              Text(
                                "ARR Dashboard",
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF202124),
                                ),
                              ),

                              SizedBox(height: 5),

                              Text(
                                "Manage inspections, review results and access previous ARR records.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B6F76),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),

                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F6F8),
                            borderRadius: BorderRadius.circular(10),
                          ),

                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.assignment_turned_in_outlined,
                                size: 18,
                                color: Color(0xFF555A63),
                              ),

                              const SizedBox(width: 8),

                              Text(
                                "${AppData.previousArrs.length} Records",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF555A63),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // --------------------------------------------------
                  // STATISTICS
                  // --------------------------------------------------

                  Builder(
                    builder: (context) {

                      Map<String, int> stats;

                      String title = "Overall Statistics";

                      IconData icon = Icons.analytics_rounded;

                      Color color = const Color(0xFF3155C6);

                      if (selectedFilter == "Overall") {

                        stats = {
                          "total": _totalArr,
                          "pass": _passedArr,
                          "fail": _failedArr,
                        };

                      } else {

                        stats = _filterStats;

                        if (selectedFilter == "Today") {

                          title = "Today's Statistics";
                          icon = Icons.today_rounded;
                          color = const Color(0xFF2E9B55);

                        } else if (selectedFilter == "Yesterday") {

                          title = "Yesterday's Statistics";
                          icon = Icons.history_rounded;
                          color = const Color(0xFFE58A25);

                        } else if (selectedFilter == "Custom") {

                          title = "Custom Date Statistics";
                          icon = Icons.date_range_rounded;
                          color = const Color(0xFF7655C9);
                        }
                      }

                      return Column(
                        children: [

                          AnimatedSwitcher(
                            duration:
                            const Duration(milliseconds: 250),

                            child: Container(
                              key: ValueKey(
                                "$selectedFilter-${_loadingFilterStats}",
                              ),

                              child: _loadingFilterStats &&
                                  selectedFilter != "Overall"

                                  ? const SizedBox(
                                height: 120,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )

                                  : _statsCard(
                                title,
                                stats,
                                icon,
                                color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // FILTER BAR
                          Container(
                            padding: const EdgeInsets.all(5),

                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                              BorderRadius.circular(14),

                              border: Border.all(
                                color: const Color(0xFFE2E3E7),
                              ),
                            ),

                            child: SegmentedButton<String>(
                              showSelectedIcon: false,

                              style: ButtonStyle(
                                visualDensity:
                                VisualDensity.compact,

                                padding:
                                WidgetStateProperty.all(
                                  const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                ),

                                textStyle:
                                WidgetStateProperty.all(
                                  const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                shape:
                                WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(10),
                                  ),
                                ),
                              ),

                              segments: const [

                                ButtonSegment(
                                  value: "Overall",

                                  label: Text("All"),

                                  icon: Icon(
                                    Icons.analytics_outlined,
                                    size: 18,
                                  ),
                                ),

                                ButtonSegment(
                                  value: "Today",

                                  label: Text("Today"),

                                  icon: Icon(
                                    Icons.today_outlined,
                                    size: 18,
                                  ),
                                ),

                                ButtonSegment(
                                  value: "Yesterday",

                                  label: Text("Last Day"),

                                  icon: Icon(
                                    Icons.history_outlined,
                                    size: 18,
                                  ),
                                ),

                                ButtonSegment(
                                  value: "Custom",

                                  label: Text("Date Range"),

                                  icon: Icon(
                                    Icons.date_range_outlined,
                                    size: 18,
                                  ),
                                ),
                              ],

                              selected: {
                                selectedFilter,
                              },

                              onSelectionChanged:
                                  (value) async {

                                final filter = value.first;

                                if (filter == "Custom") {

                                  final range =
                                  await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );

                                  if (range == null) {
                                    return;
                                  }

                                  setState(() {
                                    customRange = range;
                                    selectedFilter = "Custom";
                                  });

                                  await _loadStatsForFilter(
                                    "Custom",
                                    range: range,
                                  );

                                } else if (filter == "Overall") {

                                  setState(() {
                                    selectedFilter = "Overall";
                                    _loadingFilterStats = false;
                                  });

                                } else {

                                  setState(() {
                                    selectedFilter = filter;
                                  });

                                  await _loadStatsForFilter(
                                    filter,
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // --------------------------------------------------
                  // ACTIONS
                  // --------------------------------------------------

                  const Text(
                    "Quick Actions",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF202124),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      Expanded(
                        child: _homeActionCard(
                          icon: Icons.add_circle_outline_rounded,
                          title: "New ARR",
                          subtitle:
                          "Start a new inspection",
                          color:
                          const Color(0xFF3155C6),

                          onPressed: () async {

                            AppData.resetAssessment();

                            await Navigator.pushNamed(
                              context,
                              '/ARR/candidate',
                            );

                            if (mounted) {
                              setState(() {});
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: _homeActionCard(
                          icon:
                          Icons.folder_open_outlined,
                          title: "Previous ARRs",
                          subtitle:
                          "View completed inspections",
                          color:
                          const Color(0xFF7655C9),

                          onPressed: () async {

                            await Navigator.pushNamed(
                              context,
                              '/ARR/previous',
                            );

                            if (mounted) {
                              setState(() {});
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: _homeActionCard(
                          icon:
                          Icons.admin_panel_settings_outlined,
                          title: "Admin Panel",
                          subtitle:
                          "Manage application settings",
                          color:
                          const Color(0xFF4F5663),

                          onPressed: () {

                            final controller =
                            TextEditingController();

                            showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (dialogContext) {
                                bool obscurePassword = true;

                                return StatefulBuilder(
                                  builder: (context, setDialogState) {
                                    return Dialog(
                                      backgroundColor: Colors.transparent,
                                      insetPadding: const EdgeInsets.symmetric(
                                        horizontal: 40,
                                        vertical: 24,
                                      ),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 460,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(28),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: const Color(0xFFE2E5EA),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.12),
                                                blurRadius: 30,
                                                offset: const Offset(0, 12),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [

                                              // HEADER
                                              Row(
                                                children: [

                                                  Container(
                                                    width: 50,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF0F3FF),
                                                      borderRadius:
                                                      BorderRadius.circular(14),
                                                    ),
                                                    child: const Icon(
                                                      Icons.admin_panel_settings_outlined,
                                                      color: Color(0xFF3155C6),
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
                                                          "Admin Access",
                                                          style: TextStyle(
                                                            fontSize: 20,
                                                            fontWeight: FontWeight.w700,
                                                            color: Color(0xFF202124),
                                                          ),
                                                        ),

                                                        SizedBox(height: 4),

                                                        Text(
                                                          "Enter your administrator password to continue.",
                                                          style: TextStyle(
                                                            fontSize: 12.5,
                                                            color: Color(0xFF747982),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 26),

                                              // PASSWORD LABEL
                                              const Text(
                                                "Administrator Password",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF3F4349),
                                                ),
                                              ),

                                              const SizedBox(height: 8),

                                              // PASSWORD FIELD
                                              TextField(
                                                controller: controller,
                                                obscureText: obscurePassword,
                                                autofocus: true,
                                                textInputAction: TextInputAction.done,
                                                onSubmitted: (_) {

                                                  if (controller.text ==
                                                      HiveService.getAdminPassword()) {

                                                    Navigator.pop(dialogContext);

                                                    Navigator.pushNamed(
                                                      this.context,
                                                      '/ARR/admin',

                                                    );

                                                  } else {

                                                    Navigator.pop(dialogContext);

                                                    ScaffoldMessenger.of(this.context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          "Incorrect Admin Password",
                                                        ),
                                                        backgroundColor:
                                                        Color(0xFFD94A4A),
                                                      ),
                                                    );
                                                  }
                                                },
                                                decoration: InputDecoration(
                                                  hintText: "Enter password",
                                                  hintStyle: const TextStyle(
                                                    color: Color(0xFF9A9EA5),
                                                    fontSize: 13,
                                                  ),

                                                  prefixIcon: const Icon(
                                                    Icons.lock_outline_rounded,
                                                    size: 20,
                                                    color: Color(0xFF6F747C),
                                                  ),

                                                  suffixIcon: IconButton(
                                                    tooltip: obscurePassword
                                                        ? "Show password"
                                                        : "Hide password",

                                                    icon: Icon(
                                                      obscurePassword
                                                          ? Icons.visibility_outlined
                                                          : Icons.visibility_off_outlined,
                                                      size: 20,
                                                      color: const Color(0xFF6F747C),
                                                    ),

                                                    onPressed: () {
                                                      setDialogState(() {
                                                        obscurePassword =
                                                        !obscurePassword;
                                                      });
                                                    },
                                                  ),

                                                  filled: true,
                                                  fillColor: const Color(0xFFF8F9FB),

                                                  contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 16,
                                                  ),

                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(12),
                                                    borderSide: BorderSide.none,
                                                  ),

                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(12),
                                                    borderSide: const BorderSide(
                                                      color: Color(0xFFE0E3E8),
                                                    ),
                                                  ),

                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(12),
                                                    borderSide: const BorderSide(
                                                      color: Color(0xFF3155C6),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(height: 8),

                                              // FORGOT PASSWORD
                                              Align(
                                                alignment: Alignment.centerRight,
                                                child: TextButton(
                                                  onPressed: () {

                                                    Navigator.pop(dialogContext);

                                                    _showForgotPasswordDialog();
                                                  },

                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                    const Color(0xFF3155C6),
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 4,
                                                    ),
                                                  ),

                                                  child: const Text(
                                                    "Forgot Password?",
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(height: 18),

                                              // ACTIONS
                                              Row(
                                                children: [

                                                  Expanded(
                                                    child: OutlinedButton(
                                                      onPressed: () {
                                                        Navigator.pop(dialogContext);
                                                      },

                                                      style: OutlinedButton.styleFrom(
                                                        foregroundColor:
                                                        const Color(0xFF555A63),
                                                        padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 14,
                                                        ),
                                                        side: const BorderSide(
                                                          color: Color(0xFFD9DDE3),
                                                        ),
                                                        shape:
                                                        RoundedRectangleBorder(
                                                          borderRadius:
                                                          BorderRadius.circular(11),
                                                        ),
                                                      ),

                                                      child: const Text(
                                                        "Cancel",
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                  const SizedBox(width: 12),

                                                  Expanded(
                                                    child: OutlinedButton(
                                                      onPressed: () {

                                                        Navigator.pop(dialogContext);

                                                        _showChangePasswordDialog();
                                                      },

                                                      style: OutlinedButton.styleFrom(
                                                        foregroundColor:
                                                        const Color(0xFF3155C6),
                                                        padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 14,
                                                        ),
                                                        side: const BorderSide(
                                                          color: Color(0xFFD5DCF1),
                                                        ),
                                                        backgroundColor:
                                                        const Color(0xFFF8FAFF),
                                                        shape:
                                                        RoundedRectangleBorder(
                                                          borderRadius:
                                                          BorderRadius.circular(11),
                                                        ),
                                                      ),

                                                      child: const Text(
                                                        "Change Password",
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                  const SizedBox(width: 12),

                                                  Expanded(
                                                    child: ElevatedButton(
                                                      onPressed: () {

                                                        if (controller.text ==
                                                            HiveService
                                                                .getAdminPassword()) {

                                                          Navigator.pop(
                                                            dialogContext,
                                                          );

                                                          Navigator.pushNamed(
                                                            this.context,
                                                            '/ARR/admin',
                                                          );

                                                        } else {

                                                          Navigator.pop(
                                                            dialogContext,
                                                          );

                                                          ScaffoldMessenger.of(
                                                            this.context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "Incorrect Admin Password",
                                                              ),
                                                              backgroundColor:
                                                              Color(0xFFD94A4A),
                                                            ),
                                                          );
                                                        }
                                                      },

                                                      style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                        const Color(0xFF3155C6),
                                                        foregroundColor:
                                                        Colors.white,
                                                        elevation: 0,
                                                        padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 14,
                                                        ),
                                                        shape:
                                                        RoundedRectangleBorder(
                                                          borderRadius:
                                                          BorderRadius.circular(11),
                                                        ),
                                                      ),

                                                      child: const Text(
                                                        "Open Admin",
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w600,
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
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // --------------------------------------------------
                  // FOOTER
                  // --------------------------------------------------

                  Center(
                    child: Text(
                      "Digital ARR  •  Inspection Management System",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF8A8E95),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
// Future<void> _showChangePasswordDialog() async {
//
//   final currentController = TextEditingController();
//
//   final newController = TextEditingController();
//
//   final confirmController = TextEditingController();
//   final passwordNotifier = ValueNotifier<String>("");
//
//   showDialog(
//
//     context: context,
//
//     builder: (context) {
//
//       return AlertDialog(
//
//         title: const Text("Change Password"),
//
//         content: SingleChildScrollView(
//
//           child: Column(
//
//             mainAxisSize: MainAxisSize.min,
//
//             children: [
//
//               TextField(
//
//                 controller: currentController,
//
//                 obscureText: true,
//
//                 decoration: const InputDecoration(
//                   labelText: "Current Password",
//                 ),
//
//               ),
//
//               const SizedBox(height: 12),
//
//               TextField(
//                 controller: newController,
//                 obscureText: true,
//
//                 onChanged: (value) {
//                   passwordNotifier.value = value;
//                 },
//
//                 decoration: const InputDecoration(
//                   labelText: "New Password",
//                 ),
//               ),
//               ValueListenableBuilder<String>(
//                 valueListenable: passwordNotifier,
//
//                 builder: (context, password, _) {
//
//                   bool upper =
//                   RegExp(r'[A-Z]').hasMatch(password);
//
//                   bool lower =
//                   RegExp(r'[a-z]').hasMatch(password);
//
//                   bool number =
//                   RegExp(r'[0-9]').hasMatch(password);
//
//                   bool special =
//                   RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password);
//
//                   bool length =
//                       password.length >= 8;
//
//                   bool spaces =
//                   !password.contains(" ");
//
//                   Widget item(
//                       bool ok,
//                       String text,
//                       ) {
//                     return Row(
//                       children: [
//
//                         Icon(
//                           ok
//                               ? Icons.check_circle
//                               : Icons.cancel,
//                           size: 18,
//                           color:
//                           ok
//                               ? Colors.green
//                               : Colors.red,
//                         ),
//
//                         const SizedBox(width: 6),
//
//                         Text(text),
//
//                       ],
//                     );
//                   }
//
//                   return Column(
//
//                     crossAxisAlignment:
//                     CrossAxisAlignment.start,
//
//                     children: [
//
//                       const SizedBox(height: 10),
//
//                       item(length, "Minimum 8 characters"),
//
//                       item(upper, "1 uppercase letter"),
//
//                       item(lower, "1 lowercase letter"),
//
//                       item(number, "1 number"),
//
//                       item(special, "1 special character"),
//
//                       item(spaces, "No spaces"),
//
//                     ],
//
//                   );
//
//                 },
//
//               ),
//
//               const SizedBox(height: 12),
//
//               TextField(
//
//                 controller: confirmController,
//
//                 obscureText: true,
//
//                 decoration: const InputDecoration(
//                   labelText: "Confirm Password",
//                 ),
//
//               ),
//
//             ],
//
//           ),
//
//         ),
//
//         actions: [
//
//           TextButton(
//
//             onPressed: () {
//
//               Navigator.pop(context);
//
//             },
//
//             child: const Text("Cancel"),
//
//           ),
//
//           ValueListenableBuilder<String>(
//           valueListenable: passwordNotifier,
//
//       builder: (context, password, _) {
//
//       final isValid = RegExp(
//       r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>])[^\s]{8,}$',
//       ).hasMatch(password);
//
//       return ElevatedButton(
//
//       onPressed: isValid
//       ? () async {
//
//       if (currentController.text !=
//       HiveService.getAdminPassword()) {
//
//       ScaffoldMessenger.of(this.context)
//           .showSnackBar(
//
//       const SnackBar(
//       content: Text("Current password is incorrect."),
//       backgroundColor: Colors.red,
//       ),
//
//       );
//
//       return;
//
//       }
//
//       if (newController.text !=
//       confirmController.text) {
//
//       ScaffoldMessenger.of(this.context)
//           .showSnackBar(
//
//       const SnackBar(
//       content: Text("Passwords do not match."),
//       backgroundColor: Colors.red,
//       ),
//
//       );
//
//       return;
//
//       }
//
//       if (newController.text ==
//       currentController.text) {
//
//       ScaffoldMessenger.of(this.context)
//           .showSnackBar(
//
//       const SnackBar(
//       content: Text(
//       "New password cannot be same as current password.",
//       ),
//       backgroundColor: Colors.red,
//       ),
//
//       );
//
//       return;
//
//       }
//
//       await HiveService.setAdminPassword(
//       newController.text,
//       );
//
//       Navigator.pop(context);
//
//       ScaffoldMessenger.of(this.context)
//           .showSnackBar(
//
//       const SnackBar(
//       content: Text("Password changed successfully."),
//       backgroundColor: Colors.green,
//       ),
//
//       );
//
//       }
//           : null,
//
//       child: const Text("Save"),
//
//       );
//
//       },
//
//       ),
//         ],
//       );
//
//     },
//
//   );
//
// }
  Future<void> _showChangePasswordDialog() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    final passwordNotifier = ValueNotifier<String>("");

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        bool obscureCurrent = true;
        bool obscureNew = true;
        bool obscureConfirm = true;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 520,
                ),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE2E5EA),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // HEADER
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F3FF),
                                borderRadius:
                                BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.lock_reset_rounded,
                                color: Color(0xFF3155C6),
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
                                    "Change Password",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF202124),
                                    ),
                                  ),

                                  SizedBox(height: 4),

                                  Text(
                                    "Update the administrator password securely.",
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF747982),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 26),

                        // CURRENT PASSWORD
                        const Text(
                          "Current Password",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3F4349),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextField(
                          controller: currentController,
                          obscureText: obscureCurrent,
                          decoration: InputDecoration(
                            hintText: "Enter current password",
                            hintStyle: const TextStyle(
                              color: Color(0xFF9A9EA5),
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                              color: Color(0xFF6F747C),
                            ),
                            suffixIcon: IconButton(
                              tooltip: obscureCurrent
                                  ? "Show password"
                                  : "Hide password",
                              icon: Icon(
                                obscureCurrent
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: const Color(0xFF6F747C),
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  obscureCurrent =
                                  !obscureCurrent;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FB),
                            contentPadding:
                            const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E3E8),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF3155C6),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // NEW PASSWORD
                        const Text(
                          "New Password",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3F4349),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextField(
                          controller: newController,
                          obscureText: obscureNew,
                          onChanged: (value) {
                            passwordNotifier.value = value;
                          },
                          decoration: InputDecoration(
                            hintText: "Enter new password",
                            hintStyle: const TextStyle(
                              color: Color(0xFF9A9EA5),
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.password_outlined,
                              size: 20,
                              color: Color(0xFF6F747C),
                            ),
                            suffixIcon: IconButton(
                              tooltip: obscureNew
                                  ? "Show password"
                                  : "Hide password",
                              icon: Icon(
                                obscureNew
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: const Color(0xFF6F747C),
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  obscureNew =
                                  !obscureNew;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FB),
                            contentPadding:
                            const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E3E8),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF3155C6),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // PASSWORD REQUIREMENTS
                        ValueListenableBuilder<String>(
                          valueListenable: passwordNotifier,
                          builder: (context, password, _) {
                            final upper =
                            RegExp(r'[A-Z]')
                                .hasMatch(password);

                            final lower =
                            RegExp(r'[a-z]')
                                .hasMatch(password);

                            final number =
                            RegExp(r'[0-9]')
                                .hasMatch(password);

                            final special =
                            RegExp(
                              r'[!@#\$%^&*(),.?":{}|<>]',
                            ).hasMatch(password);

                            final length =
                                password.length >= 8;

                            final spaces =
                            !password.contains(" ");

                            Widget requirement(
                                bool valid,
                                String text,
                                ) {
                              return Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      valid
                                          ? Icons.check_circle_rounded
                                          : Icons.circle_outlined,
                                      size: 15,
                                      color: valid
                                          ? const Color(0xFF2E9B55)
                                          : const Color(0xFF9A9EA5),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        text,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: valid
                                              ? const Color(0xFF2E9B55)
                                              : const Color(0xFF747982),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FB),
                                borderRadius:
                                BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [

                                  const Text(
                                    "Password requirements",
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF555A63),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  Row(
                                    children: [
                                      requirement(
                                        length,
                                        "8+ characters",
                                      ),
                                      requirement(
                                        upper,
                                        "Uppercase",
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  Row(
                                    children: [
                                      requirement(
                                        lower,
                                        "Lowercase",
                                      ),
                                      requirement(
                                        number,
                                        "Number",
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  Row(
                                    children: [
                                      requirement(
                                        special,
                                        "Special character",
                                      ),
                                      requirement(
                                        spaces,
                                        "No spaces",
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 18),

                        // CONFIRM PASSWORD
                        const Text(
                          "Confirm New Password",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3F4349),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextField(
                          controller: confirmController,
                          obscureText: obscureConfirm,
                          decoration: InputDecoration(
                            hintText: "Re-enter new password",
                            hintStyle: const TextStyle(
                              color: Color(0xFF9A9EA5),
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.verified_user_outlined,
                              size: 20,
                              color: Color(0xFF6F747C),
                            ),
                            suffixIcon: IconButton(
                              tooltip: obscureConfirm
                                  ? "Show password"
                                  : "Hide password",
                              icon: Icon(
                                obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: const Color(0xFF6F747C),
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  obscureConfirm =
                                  !obscureConfirm;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FB),
                            contentPadding:
                            const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E3E8),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF3155C6),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        // ACTIONS
                        Row(
                          children: [

                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                  const Color(0xFF555A63),
                                  padding:
                                  const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFD9DDE3),
                                  ),
                                  shape:
                                  RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(11),
                                  ),
                                ),
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: ValueListenableBuilder<String>(
                                valueListenable: passwordNotifier,
                                builder:
                                    (context, password, _) {

                                  final isValid = RegExp(
                                    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>])[^\s]{8,}$',
                                  ).hasMatch(password);

                                  return ElevatedButton(
                                    onPressed: isValid
                                        ? () async {

                                      if (currentController
                                          .text !=
                                          HiveService
                                              .getAdminPassword()) {

                                        ScaffoldMessenger
                                            .of(this.context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Current password is incorrect.",
                                            ),
                                            backgroundColor:
                                            Color(0xFFD94A4A),
                                          ),
                                        );

                                        return;
                                      }

                                      if (newController.text !=
                                          confirmController.text) {

                                        ScaffoldMessenger
                                            .of(this.context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Passwords do not match.",
                                            ),
                                            backgroundColor:
                                            Color(0xFFD94A4A),
                                          ),
                                        );

                                        return;
                                      }

                                      if (newController.text ==
                                          currentController.text) {

                                        ScaffoldMessenger
                                            .of(this.context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "New password cannot be same as current password.",
                                            ),
                                            backgroundColor:
                                            Color(0xFFD94A4A),
                                          ),
                                        );

                                        return;
                                      }

                                      await HiveService
                                          .setAdminPassword(
                                        newController.text,
                                      );

                                      Navigator.pop(
                                        dialogContext,
                                      );

                                      ScaffoldMessenger
                                          .of(this.context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Password changed successfully.",
                                          ),
                                          backgroundColor:
                                          Color(0xFF2E9B55),
                                        ),
                                      );
                                    }
                                        : null,

                                    style:
                                    ElevatedButton.styleFrom(
                                      backgroundColor:
                                      const Color(0xFF3155C6),
                                      foregroundColor:
                                      Colors.white,
                                      disabledBackgroundColor:
                                      const Color(0xFFE5E8EE),
                                      disabledForegroundColor:
                                      const Color(0xFF9A9EA5),
                                      elevation: 0,
                                      padding:
                                      const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape:
                                      RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(11),
                                      ),
                                    ),

                                    child: const Text(
                                      "Save Password",
                                      style: TextStyle(
                                        fontWeight:
                                        FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
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
          },
        );
      },
    );
  }
  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();

    _sendingOtp = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 480,
                ),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE2E5EA),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [

                      // HEADER
                      Row(
                        children: [

                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F3FF),
                              borderRadius:
                              BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.mark_email_unread_outlined,
                              color: Color(0xFF3155C6),
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
                                  "Forgot Password",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF202124),
                                  ),
                                ),

                                SizedBox(height: 4),

                                Text(
                                  "Verify your registered email to reset the admin password.",
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF747982),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 26),

                      // EMAIL LABEL
                      const Text(
                        "Registered Email",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3F4349),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // EMAIL FIELD
                      TextField(
                        controller: emailController,
                        autofocus: true,
                        keyboardType:
                        TextInputType.emailAddress,
                        textInputAction:
                        TextInputAction.done,
                        decoration: InputDecoration(
                          hintText:
                          "Enter registered email",
                          hintStyle: const TextStyle(
                            color: Color(0xFF9A9EA5),
                            fontSize: 13,
                          ),

                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            size: 20,
                            color: Color(0xFF6F747C),
                          ),

                          filled: true,
                          fillColor:
                          const Color(0xFFF8F9FB),

                          contentPadding:
                          const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),

                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                            borderSide:
                            BorderSide.none,
                          ),

                          enabledBorder:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                            borderSide:
                            const BorderSide(
                              color: Color(0xFFE0E3E8),
                            ),
                          ),

                          focusedBorder:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                            borderSide:
                            const BorderSide(
                              color: Color(0xFF3155C6),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // INFORMATION BOX
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FB),
                          borderRadius:
                          BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [

                            const Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: Color(0xFF6F747C),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                "A one-time password will be sent to your registered email address.",
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: Color(0xFF666C75),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 26),

                      // ACTIONS
                      Row(
                        children: [

                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(
                                  dialogContext,
                                );
                              },

                              style:
                              OutlinedButton.styleFrom(
                                foregroundColor:
                                const Color(0xFF555A63),

                                padding:
                                const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),

                                side: const BorderSide(
                                  color: Color(0xFFD9DDE3),
                                ),

                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(11),
                                ),
                              ),

                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  fontWeight:
                                  FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: ElevatedButton(
                              onPressed: _sendingOtp
                                  ? null
                                  : () async {

                                final email =
                                emailController
                                    .text
                                    .trim();

                                if (email.isEmpty) {

                                  ScaffoldMessenger
                                      .of(this.context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Enter your registered email.",
                                      ),
                                      backgroundColor:
                                      Color(0xFFD94A4A),
                                    ),
                                  );

                                  return;
                                }

                                if (email
                                    .toLowerCase() !=
                                    HiveService
                                        .getAdminEmail()
                                        .trim()
                                        .toLowerCase()) {

                                  ScaffoldMessenger
                                      .of(this.context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Registered email not found.",
                                      ),
                                      backgroundColor:
                                      Color(0xFFD94A4A),
                                    ),
                                  );

                                  return;
                                }

                                setDialogState(() {
                                  _sendingOtp = true;
                                });

                                final sent =
                                await EmailService
                                    .sendOtp(
                                  toEmail: email,
                                );

                                if (!mounted) {
                                  return;
                                }

                                setDialogState(() {
                                  _sendingOtp = false;
                                });

                                if (!sent) {

                                  ScaffoldMessenger
                                      .of(this.context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Failed to send OTP.",
                                      ),
                                      backgroundColor:
                                      Color(0xFFD94A4A),
                                    ),
                                  );

                                  return;
                                }

                                Navigator.pop(
                                  dialogContext,
                                );

                                _startOtpTimer();

                                ScaffoldMessenger
                                    .of(this.context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "OTP sent to your registered email.",
                                    ),
                                    backgroundColor:
                                    Color(0xFF2E9B55),
                                  ),
                                );

                                _showOtpDialog();
                              },

                              style:
                              ElevatedButton.styleFrom(
                                backgroundColor:
                                const Color(0xFF3155C6),

                                foregroundColor:
                                Colors.white,

                                disabledBackgroundColor:
                                const Color(0xFFE5E8EE),

                                disabledForegroundColor:
                                const Color(0xFF9A9EA5),

                                elevation: 0,

                                padding:
                                const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),

                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(11),
                                ),
                              ),

                              child: _sendingOtp
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Text(
                                "Send OTP",
                                style: TextStyle(
                                  fontWeight:
                                  FontWeight.w600,
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
            );
          },
        );
      },
    );
  }
  Future<void> _showOtpDialog() async {

    final otpController = TextEditingController();

    _verifyingOtp = false;

    Timer? dialogTimer;

    showDialog(

      context: context,

      barrierDismissible: false,

builder: (dialogContext) {

return StatefulBuilder(

          builder: (context, setDialogState) {
            dialogTimer ??= Timer.periodic(

              const Duration(seconds: 1),

                  (_) {

                if (Navigator.canPop(dialogContext)) {

                  setDialogState(() {});

                }

              },

            );

            return AlertDialog(

              title: const Text("Verify OTP"),

              content: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

                  Pinput(
                    controller: otpController,
                    length: 6,
                    autofocus: true,
                    keyboardType: TextInputType.number,

                    defaultPinTheme: PinTheme(
                      width: 50,
                      height: 56,
                      textStyle: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.deepPurple,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    focusedPinTheme: PinTheme(
                      width: 50,
                      height: 56,
                      textStyle: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.green,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    onChanged: (_) {

                      setDialogState(() {});

                    },

                  ),

                  const SizedBox(height: 20),

                  Column(

                    children: [

                      Text(

                        "Attempts Remaining : ${EmailService.attemptsLeft}",

                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),

                      ),

                      // const SizedBox(height: 6),
                      //
                      // Text(
                      //
                      //   "OTP expires in ${EmailService.getRemainingSeconds()} sec",
                      //
                      //   style: const TextStyle(
                      //     color: Colors.grey,
                      //     fontSize: 12,
                      //   ),
                      //
                      // ),

                    ],

                  ),

                  const SizedBox(height: 15),

                  !_canResendOtp

                      ? Text(

                    "Resend OTP in $_secondsRemaining s",

                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,

                    ),

                  )

                      : TextButton(

                    onPressed: () async {

                      final sent = await EmailService.sendOtp(

                        toEmail:
                        HiveService.getAdminEmail(),

                      );

                      if (sent) {

                        _startOtpTimer();

                        setDialogState(() {});

                        ScaffoldMessenger.of(this.context)
                            .showSnackBar(

                          const SnackBar(

                            content: Text(

                              "New OTP sent successfully.",

                            ),

                            backgroundColor: Colors.green,

                          ),

                        );

                      }

                    },

                    child: const Text(

                      "Resend OTP",

                    ),

                  ),

                ],

              ),

              actions: [

                TextButton(

                  onPressed: () {

                    dialogTimer?.cancel();

                    Navigator.pop(dialogContext);

                  },

                  child: const Text("Cancel"),

                ),

                ElevatedButton(

                  onPressed: otpController.text.length != 6 ||

                      _verifyingOtp

                      ? null

                      : () async {

                    setDialogState(() {

                      _verifyingOtp = true;

                    });

                    await Future.delayed(

                      const Duration(

                        milliseconds: 400,

                      ),

                    );

                    final success =
                    EmailService.verifyOtp(

                      otpController.text.trim(),

                    );

                    setDialogState(() {

                      _verifyingOtp = false;

                    });

                    if (!success) {

                      ScaffoldMessenger.of(this.context)
                          .showSnackBar(

                        SnackBar(

                          content: Text(

                            EmailService.attemptsLeft == 0

                                ? "Maximum attempts exceeded. Please resend OTP."

                                : "Incorrect / Expired OTP\nAttempts Left : ${EmailService.attemptsLeft}",

                          ),

                          backgroundColor: Colors.red,

                        ),

                      );

                      setDialogState(() {});

                      return;

                    }

                    EmailService.clearOtp();

                    dialogTimer?.cancel();

                    Navigator.pop(dialogContext);

                    FocusScope.of(this.context).unfocus();

                    ScaffoldMessenger.of(this.context)
                        .showSnackBar(

                      const SnackBar(

                        content: Text(

                          "OTP verified successfully, Reset your password.",

                        ),

                        backgroundColor: Colors.green,

                      ),

                    );

                    _showResetPasswordDialog();

                  },

                  child: _verifyingOtp

                      ? const SizedBox(

                    width: 18,

                    height: 18,

                    child: CircularProgressIndicator(

                      strokeWidth: 2,

                      color: Colors.white,

                    ),

                  )

                      : const Text("Verify"),

                ),

              ],

            );

          },

        );

      },

    );

  }
// Future<void> _showResetPasswordDialog() async {
//
//   final newController = TextEditingController();
//
//   final confirmController = TextEditingController();
//
//   final passwordNotifier = ValueNotifier<String>("");
//
//   showDialog(
//
//     context: context,
//
//     barrierDismissible: false,
//
//     builder: (context) {
//
//       return AlertDialog(
//
//         title: const Text(
//           "Reset Password",
//         ),
//
//         content: SingleChildScrollView(
//
//           child: Column(
//
//             mainAxisSize: MainAxisSize.min,
//
//             children: [
//
//               TextField(
//
//                 controller: newController,
//
//                 obscureText: true,
//
//                 onChanged: (value) {
//
//                   passwordNotifier.value = value;
//
//                 },
//
//                 decoration: const InputDecoration(
//
//                   labelText: "New Password",
//
//                 ),
//
//               ),
//
//               const SizedBox(height: 10),
//
//               ValueListenableBuilder<String>(
//
//                 valueListenable: passwordNotifier,
//
//                 builder: (context, password, _) {
//
//                   final upper =
//                   RegExp(r'[A-Z]').hasMatch(password);
//
//                   final lower =
//                   RegExp(r'[a-z]').hasMatch(password);
//
//                   final number =
//                   RegExp(r'\d').hasMatch(password);
//
//                   final special =
//                   RegExp(r'[!@#\$%^&*(),.?":{}|<>]')
//                       .hasMatch(password);
//
//                   final length =
//                       password.length >= 8;
//
//                   final spaces =
//                   !password.contains(" ");
//
//                   Widget item(
//                       bool ok,
//                       String text,
//                       ) {
//
//                     return Row(
//
//                       children: [
//
//                         Icon(
//
//                           ok
//                               ? Icons.check_circle
//                               : Icons.cancel,
//
//                           size: 18,
//
//                           color: ok
//                               ? Colors.green
//                               : Colors.red,
//
//                         ),
//
//                         const SizedBox(width: 6),
//
//                         Text(text),
//
//                       ],
//
//                     );
//
//                   }
//
//                   return Column(
//
//                     crossAxisAlignment:
//                     CrossAxisAlignment.start,
//
//                     children: [
//
//                       item(length, "Minimum 8 characters"),
//
//                       item(upper, "Uppercase"),
//
//                       item(lower, "Lowercase"),
//
//                       item(number, "Number"),
//
//                       item(special, "Special Character"),
//
//                       item(spaces, "No Spaces"),
//
//                     ],
//
//                   );
//
//                 },
//
//               ),
//
//               const SizedBox(height: 12),
//
//               TextField(
//
//                 controller: confirmController,
//
//                 obscureText: true,
//
//                 decoration: const InputDecoration(
//
//                   labelText: "Confirm Password",
//
//                 ),
//
//               ),
//
//             ],
//
//           ),
//
//         ),
//
//         actions: [
//
//           TextButton(
//
//             onPressed: () {
//
//               Navigator.pop(context);
//
//             },
//
//             child: const Text("Cancel"),
//
//           ),
//
//           ValueListenableBuilder<String>(
//
//             valueListenable: passwordNotifier,
//
//             builder: (context, password, _) {
//
//               final valid = RegExp(
//
//                 r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>])[^\s]{8,}$',
//
//               ).hasMatch(password);
//
//               return ElevatedButton(
//
//                 onPressed: valid
//                     ? () async {
//
//                   if (newController.text !=
//                       confirmController.text) {
//
//                     ScaffoldMessenger.of(this.context)
//                         .showSnackBar(
//
//                       const SnackBar(
//
//                         content: Text(
//                           "Passwords do not match.",
//                         ),
//
//                         backgroundColor: Colors.red,
//
//                       ),
//
//                     );
//
//                     return;
//
//                   }
//
//                   await HiveService
//                       .setAdminPassword(
//                     newController.text,
//                   );
//
//                   EmailService.clearOtp();
//
//                   Navigator.pop(context);
//
//                   ScaffoldMessenger.of(this.context)
//                       .showSnackBar(
//
//                     const SnackBar(
//
//                       content: Text(
//                         "Password reset successfully Please login with your new password.",
//                       ),
//
//                       backgroundColor: Colors.green,
//
//                     ),
//
//                   );
//
//                 }
//                     : null,
//
//                 child: const Text(
//                   "Reset",
//                 ),
//
//               );
//
//             },
//
//           ),
//
//         ],
//
//       );
//
//     },
//
//   );
//
// }
  Widget _homeActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E3E7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
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
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 25,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF202124),
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF777B82),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }
//
// // Widget _statsCard(
// //     String title,
// //     Map<String,int> stats,
// //     IconData icon,
// //     Color color,
// //     ) {
// //   return Card(
// //     elevation: 5,
// //     shape: RoundedRectangleBorder(
// //       borderRadius: BorderRadius.circular(15),
// //     ),
// //     child: Padding(
// //       padding: const EdgeInsets.all(15),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //
// //           Row(
// //             children: [
// //
// //               Icon(
// //                 icon,
// //                 color: color,
// //                 size: 28,
// //               ),
// //
// //               const SizedBox(width: 10),
// //
// //               Text(
// //                 title,
// //                 style: const TextStyle(
// //                   fontSize: 18,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //
// //             ],
// //           ),
// //
// //           const SizedBox(height: 18),
// //
// //           _statsRow(stats),
// //
// //         ],
// //       ),
// //     ),
// //   );
// // }
  Widget _statsCard(
      String title,
      Map<String, int> stats,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E3E7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 23,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF202124),
                      ),
                    ),

                    const SizedBox(height: 3),

                    const Text(
                      "Inspection performance overview",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF858991),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  "${stats["total"]} Total",
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF62666D),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _statsRow(stats),
        ],
      ),
    );
  }
  // // Widget _statsRow(
// //     Map<String, int> stats,
// //     ) {
// //   return Row(
// //     mainAxisAlignment: MainAxisAlignment.spaceAround,
// //     children: [
// //
// //       _item(
// //         "Total",
// //         stats["total"]!,
// //         Colors.blue,
// //       ),
// //
// //       _item(
// //         "Pass",
// //         stats["pass"]!,
// //         Colors.green,
// //       ),
// //
// //       _item(
// //         "Fail",
// //         stats["fail"]!,
// //         Colors.red,
// //       ),
// //
// //     ],
// //   );
// // }
  Widget _statsRow(
      Map<String, int> stats,
      ) {
    return Row(
      children: [

        Expanded(
          child: _item(
            "Total",
            stats["total"] ?? 0,
            const Color(0xFF3155C6),
            Icons.assignment_outlined,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: _item(
            "Pass",
            stats["pass"] ?? 0,
            const Color(0xFF2E9B55),
            Icons.check_circle_outline_rounded,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: _item(
            "Fail",
            stats["fail"] ?? 0,
            const Color(0xFFD94A4A),
            Icons.cancel_outlined,
          ),
        ),
      ],
    );
  }
  Widget _item(
      String title,
      int value,
      Color color,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [

          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF747982),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
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
//   Widget _item(
//       String title,
//       int value,
//       Color color,
//       IconData icon,
//       ) {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 18,
//         vertical: 17,
//       ),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF8F9FB),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: const Color(0xFFE5E7EB),
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 42,
//             height: 42,
//             decoration: BoxDecoration(
//               color: color.withValues(alpha: 0.10),
//               borderRadius: BorderRadius.circular(11),
//             ),
//             child: Icon(
//               icon,
//               color: color,
//               size: 22,
//             ),
//           ),
//
//           const SizedBox(width: 14),
//
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF747982),
//                   ),
//                 ),
//
//                 const SizedBox(height: 3),
//
//                 Text(
//                   value.toString(),
//                   style: TextStyle(
//                     fontSize: 25,
//                     fontWeight: FontWeight.w800,
//                     color: color,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
  Future<void> _showResetPasswordDialog() async {
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    final passwordNotifier = ValueNotifier<String>("");
    final confirmNotifier = ValueNotifier<String>("");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool obscureNew = true;
        bool obscureConfirm = true;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,

              insetPadding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 24,
              ),

              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                ),

                child: Container(
                  padding: const EdgeInsets.all(28),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),

                    border: Border.all(
                      color: const Color(0xFFE2E5EA),
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.12,
                        ),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),

                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        // ==================================================
                        // HEADER
                        // ==================================================

                        Row(
                          children: [

                            Container(
                              width: 50,
                              height: 50,

                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F3FF),
                                borderRadius:
                                BorderRadius.circular(14),
                              ),

                              child: const Icon(
                                Icons.lock_reset_rounded,
                                color: Color(0xFF3155C6),
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
                                    "Reset Password",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight:
                                      FontWeight.w700,
                                      color:
                                      Color(0xFF202124),
                                    ),
                                  ),

                                  SizedBox(height: 4),

                                  Text(
                                    "Create a new administrator password.",
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color:
                                      Color(0xFF747982),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 26),

                        // ==================================================
                        // NEW PASSWORD LABEL
                        // ==================================================

                        const Text(
                          "New Password",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3F4349),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ==================================================
                        // NEW PASSWORD FIELD
                        // ==================================================

                        TextField(
                          controller: newController,
                          obscureText: obscureNew,
                          autofocus: true,

                          onChanged: (value) {
                            passwordNotifier.value = value;
                            setDialogState(() {});
                          },

                          decoration: InputDecoration(
                            hintText: "Enter new password",

                            hintStyle: const TextStyle(
                              color: Color(0xFF9A9EA5),
                              fontSize: 13,
                            ),

                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                              color: Color(0xFF6F747C),
                            ),

                            suffixIcon: IconButton(
                              tooltip: obscureNew
                                  ? "Show password"
                                  : "Hide password",

                              icon: Icon(
                                obscureNew
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,

                                size: 20,
                                color:
                                const Color(0xFF6F747C),
                              ),

                              onPressed: () {
                                setDialogState(() {
                                  obscureNew =
                                  !obscureNew;
                                });
                              },
                            ),

                            filled: true,
                            fillColor:
                            const Color(0xFFF8F9FB),

                            contentPadding:
                            const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),

                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                              borderSide:
                              BorderSide.none,
                            ),

                            enabledBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                              borderSide:
                              const BorderSide(
                                color: Color(0xFFE0E3E8),
                              ),
                            ),

                            focusedBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                              borderSide:
                              const BorderSide(
                                color: Color(0xFF3155C6),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ==================================================
                        // PASSWORD REQUIREMENTS
                        // ==================================================

                        ValueListenableBuilder<String>(
                          valueListenable:
                          passwordNotifier,

                          builder:
                              (context, password, _) {

                            final hasUpper =
                            RegExp(r'[A-Z]')
                                .hasMatch(password);

                            final hasLower =
                            RegExp(r'[a-z]')
                                .hasMatch(password);

                            final hasNumber =
                            RegExp(r'[0-9]')
                                .hasMatch(password);

                            final hasSpecial =
                            RegExp(
                              r'[!@#\$%^&*(),.?":{}|<>]',
                            ).hasMatch(password);

                            final hasLength =
                                password.length >= 8;

                            final hasNoSpaces =
                            !password.contains(" ");

                            Widget requirement(
                                bool valid,
                                String text,
                                ) {
                              return Expanded(
                                child: Row(
                                  children: [

                                    Icon(
                                      valid
                                          ? Icons
                                          .check_circle_rounded
                                          : Icons
                                          .circle_outlined,

                                      size: 15,

                                      color: valid
                                          ? const Color(
                                        0xFF2E9B55,
                                      )
                                          : const Color(
                                        0xFF9A9EA5,
                                      ),
                                    ),

                                    const SizedBox(width: 6),

                                    Flexible(
                                      child: Text(
                                        text,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: valid
                                              ? const Color(
                                            0xFF2E9B55,
                                          )
                                              : const Color(
                                            0xFF747982,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Container(
                              width: double.infinity,

                              padding:
                              const EdgeInsets.all(14),

                              decoration: BoxDecoration(
                                color:
                                const Color(0xFFF8F9FB),

                                borderRadius:
                                BorderRadius.circular(12),

                                border: Border.all(
                                  color:
                                  const Color(0xFFE5E7EB),
                                ),
                              ),

                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,

                                children: [

                                  const Text(
                                    "Password requirements",
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight:
                                      FontWeight.w700,
                                      color:
                                      Color(0xFF555A63),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  Row(
                                    children: [

                                      requirement(
                                        hasLength,
                                        "8+ characters",
                                      ),

                                      requirement(
                                        hasUpper,
                                        "Uppercase",
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  Row(
                                    children: [

                                      requirement(
                                        hasLower,
                                        "Lowercase",
                                      ),

                                      requirement(
                                        hasNumber,
                                        "Number",
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  Row(
                                    children: [

                                      requirement(
                                        hasSpecial,
                                        "Special character",
                                      ),

                                      requirement(
                                        hasNoSpaces,
                                        "No spaces",
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // ==================================================
                        // CONFIRM PASSWORD LABEL
                        // ==================================================

                        const Text(
                          "Confirm New Password",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3F4349),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ==================================================
                        // CONFIRM PASSWORD FIELD
                        // ==================================================

                        TextField(
                          controller: confirmController,
                          obscureText: obscureConfirm,

                          onChanged: (value) {
                            confirmNotifier.value = value;
                            setDialogState(() {});
                          },

                          decoration: InputDecoration(
                            hintText:
                            "Re-enter new password",

                            hintStyle: const TextStyle(
                              color: Color(0xFF9A9EA5),
                              fontSize: 13,
                            ),

                            prefixIcon: const Icon(
                              Icons.verified_user_outlined,
                              size: 20,
                              color: Color(0xFF6F747C),
                            ),

                            suffixIcon: IconButton(
                              tooltip: obscureConfirm
                                  ? "Show password"
                                  : "Hide password",

                              icon: Icon(
                                obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,

                                size: 20,
                                color:
                                const Color(0xFF6F747C),
                              ),

                              onPressed: () {
                                setDialogState(() {
                                  obscureConfirm =
                                  !obscureConfirm;
                                });
                              },
                            ),

                            filled: true,
                            fillColor:
                            const Color(0xFFF8F9FB),

                            contentPadding:
                            const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),

                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                              borderSide:
                              BorderSide.none,
                            ),

                            enabledBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                              borderSide:
                              const BorderSide(
                                color: Color(0xFFE0E3E8),
                              ),
                            ),

                            focusedBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                              borderSide:
                              const BorderSide(
                                color: Color(0xFF3155C6),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ==================================================
                        // PASSWORD MATCH STATUS
                        // ==================================================

                        ValueListenableBuilder<String>(
                          valueListenable:
                          confirmNotifier,

                          builder:
                              (context, confirm, _) {

                            if (confirm.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            final matches =
                                newController.text ==
                                    confirm;

                            return Row(
                              children: [

                                Icon(
                                  matches
                                      ? Icons
                                      .check_circle_rounded
                                      : Icons
                                      .error_outline_rounded,

                                  size: 16,

                                  color: matches
                                      ? const Color(0xFF2E9B55)
                                      : const Color(0xFFD94A4A),
                                ),

                                const SizedBox(width: 6),

                                Text(
                                  matches
                                      ? "Passwords match"
                                      : "Passwords do not match",

                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight:
                                    FontWeight.w600,
                                    color: matches
                                        ? const Color(
                                      0xFF2E9B55,
                                    )
                                        : const Color(
                                      0xFFD94A4A,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 26),

                        // ==================================================
                        // ACTION BUTTONS
                        // ==================================================

                        Row(
                          children: [

                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(
                                    dialogContext,
                                  );
                                },

                                style:
                                OutlinedButton.styleFrom(
                                  foregroundColor:
                                  const Color(
                                    0xFF555A63,
                                  ),

                                  padding:
                                  const EdgeInsets
                                      .symmetric(
                                    vertical: 14,
                                  ),

                                  side:
                                  const BorderSide(
                                    color:
                                    Color(0xFFD9DDE3),
                                  ),

                                  shape:
                                  RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(
                                      11,
                                    ),
                                  ),
                                ),

                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child:
                              ValueListenableBuilder<
                                  String>(
                                valueListenable:
                                passwordNotifier,

                                builder:
                                    (context, password, _) {

                                  final validPassword =
                                  RegExp(
                                    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>])[^\s]{8,}$',
                                  ).hasMatch(password);

                                  final passwordsMatch =
                                      newController.text ==
                                          confirmController
                                              .text;

                                  final canReset =
                                      validPassword &&
                                          passwordsMatch;

                                  return ElevatedButton(
                                    onPressed: canReset
                                        ? () async {

                                      await HiveService
                                          .setAdminPassword(
                                        newController.text,
                                      );

                                      EmailService
                                          .clearOtp();

                                      Navigator.pop(
                                        dialogContext,
                                      );

                                      ScaffoldMessenger
                                          .of(
                                        this.context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Password reset successfully. Please login with your new password.",
                                          ),
                                          backgroundColor:
                                          Color(
                                            0xFF2E9B55,
                                          ),
                                        ),
                                      );
                                    }
                                        : null,

                                    style:
                                    ElevatedButton.styleFrom(
                                      backgroundColor:
                                      const Color(
                                        0xFF3155C6,
                                      ),

                                      foregroundColor:
                                      Colors.white,

                                      disabledBackgroundColor:
                                      const Color(
                                        0xFFE5E8EE,
                                      ),

                                      disabledForegroundColor:
                                      const Color(
                                        0xFF9A9EA5,
                                      ),

                                      elevation: 0,

                                      padding:
                                      const EdgeInsets
                                          .symmetric(
                                        vertical: 14,
                                      ),

                                      shape:
                                      RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius
                                            .circular(
                                          11,
                                        ),
                                      ),
                                    ),

                                    child: const Text(
                                      "Reset Password",
                                      style: TextStyle(
                                        fontWeight:
                                        FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
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
          },
        );
      },
    );
  }
}
