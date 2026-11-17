// import'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
//
// import 'screens/home_screen.dart';
// import 'screens/candidate_screen.dart';
// import 'screens/instruction_screen.dart';
// import 'screens/assessment_screen.dart';
// import 'screens/result_screen.dart';
// import 'screens/previous_arr_screen.dart';
// import 'screens/previous_arr_detail_screen.dart';
// import 'models/arr_record.dart';
// import 'screens/certificate_screen.dart';
// import 'screens/evaluation_screen.dart';
// import 'screens/report_screen.dart';
// import 'screens/master_data_screen.dart';
// import 'screens/barcode_scan_screen.dart';
// import 'screens/scanner_assessment_screen.dart';
// import 'screens/combined_report_screen.dart';
// import 'screens/batch_selection_screen.dart';
// import 'screens/admin/admin_dashboard_screen.dart';
// import 'screens/admin/batch_management_screen.dart';
// import 'screens/admin/part_management_screen.dart';
// import 'screens/admin/qr_generator_screen.dart';
// import 'screens/admin/scan_part_screen.dart';
// import 'screens/admin/settings_screen.dart';
// import 'screens/combined_certificate_screen.dart';
// import 'screens/eqms_home_screen.dart';
//
// import 'screens/dcc/dcc_document_control_screen.dart';
// import 'screens/dcc/dcc_login_screen.dart';
// import 'screens/dcc/admin/admin_dcc_dashboard_screen.dart';
// import 'screens/dcc/admin/add_dcc_user_screen.dart';
// import 'screens/dcc/admin/user_management_screen.dart';
// import 'screens/dcc/user/user_dashboard_screen.dart';
// import 'screens/dcc/user/new_document_screen.dart';
// import 'screens/dcc/user/my_documents_screen.dart';
// import 'screens/dcc/user/dmr_request_screen.dart';
// import 'screens/dcc/user/dmr_history_screen.dart';
// import 'screens/dcc/user/released_documents_screen.dart';
// import 'screens/dcc/user/user_dmr_requests_screen.dart';
// import 'screens/dcc/dcc/dcc_dashboard_screen.dart';
// import 'screens/dcc/dcc/dcc_manage_sidebar_screen.dart';
// import 'screens/dcc/dcc/dcc_pending_documents_screen.dart';
// import 'screens/dcc/dcc/dcc_released_documents_screen.dart';
// import 'screens/dcc/dcc/dcc_dmr_requests_screen.dart';
// import 'screens/dcc/dcc/dcc_document_review_screen.dart';
// import 'screens/dcc/dcc/dcc_master_data_screen.dart';
// import 'screens/dcc/hod/hod_dashboard_screen.dart';
// import 'screens/dcc/hod/hod_dmr_requests_screen.dart';
// import 'screens/dcc/hod/hod_activity_history_screen.dart';
// import 'screens/dcc/hod/hod_document_review_screen.dart';
// import 'models/dcc/dcc_document.dart';
//
// import 'widgets/admin_guard.dart';
// import 'widgets/arr_guard.dart';
// import 'widgets/dcc_guard.dart';
// import 'services/app_notifications.dart';
//
// import 'services/question_data.dart';
// import 'services/hive_service.dart';
// import 'services/app_data.dart';
// import 'models/arr_record.dart';
// import 'models/cross_tab_result.dart';
// import 'screens/cross_tab_result_screen.dart';
// import 'services/dcc/dcc_session.dart';
// import 'services/arr_session.dart';
// import 'services/admin_session.dart';
// import 'services/session_activity.dart';
// // import 'screens/audit/audit_management_home_new.dart';
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   await dotenv.load(fileName: ".env");
//
//   await Supabase.initialize(
//     url: dotenv.env['SUPABASE_URL'] ?? '',
//     anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
//   );
//
//   await Hive.initFlutter();
//
//   await Hive.openBox('masterData');
//   await Hive.openBox('previousArr');
//
//   AppData.previousArrs = HiveService.loadPreviousArrs();
//
//   await Hive.openBox('candidateData');
//   await Hive.openBox('batchData');
//   await Hive.openBox('dccUsers');
//   await Hive.openBox('dccDocuments');
//   await Hive.openBox('dccActivities');
//   await Hive.openBox('dccDmrRequests');
//
//   await HiveService.updateFactoryMasterData(
//     questions,
//     2,
//   );
//
//   await DccSession.restoreSession();
//   await ArrSession.restoreSession();
//   await AdminSession.restoreSession();
//
//   runApp(const DigitalARRApp());
// }
//
// class DigitalARRApp extends StatelessWidget {
//   const DigitalARRApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       scaffoldMessengerKey: rootScaffoldMessengerKey,
//       debugShowCheckedModeBanner: false,
//       title: 'eQMS',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       // Any tap/scroll/keystroke anywhere in the app counts as
//       // activity and resets the 30-minute idle-logout clock shared
//       // by AdminSession, ArrSession and DccSession.
//       builder: (context, child) {
//         return Listener(
//           behavior: HitTestBehavior.translucent,
//           onPointerDown: (_) => SessionActivity.touch(),
//           onPointerMove: (_) => SessionActivity.touch(),
//           child: child ?? const SizedBox.shrink(),
//         );
//       },
//       initialRoute: '/',
//       routes: {
//         // =========================
//         // EQMS ROOT
//         // =========================
//         '/': (_) => const EqmsHomeScreen(),
//
//         // =========================
//         // DCC MODULE
//         // =========================
//         // '/AUDIT': (_) => const AuditManagementHomeNew(),
//         '/DCC': (_) => const DccDocumentControlScreen(),
//
//         '/DCC/login': (_) => const DccLoginScreen(),
//
//         // Login gate used by the public Document Control Centre's +New action.
//         // Anyone may see the button, but only a valid DCC account can continue
//         // to the folder/document creation menu.
//         '/DCC/loginForNew': (_) => const DccLoginScreen(
//           requiredRole: 'DCC',
//           redirectRoute: '/DCC/dcc/manageSidebar',
//         ),
//
//         '/DCC/admin/dashboard': (_) => const DccGuard(
//           requiredRole: 'ADMIN',
//           child: AdminDccDashboardScreen(),
//         ),
//
//         '/DCC/admin/addUser': (_) => const DccGuard(
//           requiredRole: 'ADMIN',
//           child: AddDccUserScreen(),
//         ),
//
//         '/DCC/admin/userManagement': (_) => const DccGuard(
//           requiredRole: 'ADMIN',
//           child: UserManagementScreen(),
//         ),
//
//         '/DCC/user/dashboard': (_) => const DccGuard(
//           requiredRole: 'USER',
//           child: UserDashboardScreen(),
//         ),
//
//         '/DCC/user/newDocument': (_) => const DccGuard(
//           requiredRole: 'USER',
//           child: NewDocumentScreen(),
//         ),
//
//         '/DCC/user/myDocuments': (_) => const DccGuard(
//           requiredRole: 'USER',
//           child: MyDocumentsScreen(),
//         ),
//
//         '/DCC/user/dmrRequest': (_) => const DccGuard(
//           requiredRole: 'USER',
//           child: DmrRequestScreen(),
//         ),
//
//         '/DCC/user/dmrHistory': (_) => const DccGuard(
//           requiredRole: 'USER',
//           child: DmrRequestsScreen(),
//         ),
//
//         '/DCC/user/releasedDocuments': (_) => const DccGuard(
//           requiredRole: 'USER',
//           child: ReleasedDocumentsScreen(),
//         ),
//
//         '/DCC/user/dmrRequestsList': (_) => const DccGuard(
//           requiredRole: 'USER',
//           child: UserDmrRequestsScreen(),
//         ),
//
//         '/DCC/dcc/dashboard': (_) => const DccGuard(
//           requiredRole: 'DCC',
//           child: DccDashboardScreen(),
//         ),
//
//         '/DCC/dcc/manageSidebar': (_) => const DccGuard(
//           requiredRole: 'DCC',
//           redirectRoute: '/DCC/dcc/manageSidebar',
//           child: DccManageSidebarScreen(),
//         ),
//
//         '/DCC/dcc/pendingDocuments': (_) => const DccGuard(
//           requiredRole: 'DCC',
//           child: DccPendingDocumentsScreen(),
//         ),
//
//         '/DCC/dcc/releasedDocuments': (_) => const DccGuard(
//           requiredRole: 'DCC',
//           child: DccReleasedDocumentsScreen(),
//         ),
//
//         '/DCC/dcc/dmrRequests': (_) => const DccGuard(
//           requiredRole: 'DCC',
//           child: DccDmrRequestsScreen(),
//         ),
//
//         '/DCC/dcc/masterData': (_) => const DccGuard(
//           requiredRole: 'DCC',
//           redirectRoute: '/DCC/dcc/masterData',
//           child: DccMasterDataScreen(),
//         ),
//
//         '/DCC/dcc/documentReview': (context) {
//           final args =
//               ModalRoute.of(context)?.settings.arguments;
//
//           if (args is! DccDocument) {
//             return const DccGuard(
//               requiredRole: 'DCC',
//               child: Scaffold(
//                 body: Center(
//                   child: Text('Document data is missing.'),
//                 ),
//               ),
//             );
//           }
//
//           return DccGuard(
//             requiredRole: 'DCC',
//             child: DccDocumentReviewScreen(document: args),
//           );
//         },
//
//         '/DCC/hod/dashboard': (_) => const DccGuard(
//           requiredRole: 'HOD',
//           child: HodDashboardScreen(),
//         ),
//
//         '/DCC/hod/dmrRequests': (_) => const DccGuard(
//           requiredRole: 'HOD',
//           child: HodDmrRequestsScreen(),
//         ),
//
//         '/DCC/hod/activityHistory': (_) => const DccGuard(
//           requiredRole: 'HOD',
//           child: HodActivityHistoryScreen(),
//         ),
//
//         '/DCC/hod/documentReview': (context) {
//           final args =
//               ModalRoute.of(context)?.settings.arguments;
//
//           if (args is! DccDocument) {
//             return const DccGuard(
//               requiredRole: 'HOD',
//               child: Scaffold(
//                 body: Center(
//                   child: Text('Document data is missing.'),
//                 ),
//               ),
//             );
//           }
//
//           return DccGuard(
//             requiredRole: 'HOD',
//             child: HodDocumentReviewScreen(document: args),
//           );
//         },
//
//         // =========================
//         // ARR MODULE
//         // =========================
//         '/ARR': (_) => const ArrGuard(child: HomeScreen()),
//
//         '/ARR/candidate': (_) => const ArrGuard(child: CandidateScreen()),
//
//         '/ARR/master': (_) => const ArrGuard(child: MasterDataScreen()),
//
//         '/ARR/instruction': (_) => const ArrGuard(child: InstructionScreen()),
//
//         '/ARR/batch': (_) =>
//         const ArrGuard(child: BatchSelectionScreen()),
//
//         '/ARR/scannerAssessment': (_) =>
//         const ArrGuard(child: ScannerAssessmentScreen()),
//
//         '/ARR/assessment': (_) =>
//         const ArrGuard(child: AssessmentScreen()),
//
//         '/ARR/scan': (_) =>
//         const ArrGuard(child: BarcodeScanScreen()),
//
//         '/ARR/report': (_) =>
//         const ArrGuard(child: ReportScreen()),
//
//         '/ARR/result': (_) =>
//         const ArrGuard(child: ResultScreen()),
//
//         '/ARR/previous': (_) =>
//         const ArrGuard(child: PreviousArrScreen()),
//
//         '/ARR/previousArrDetail': (context) {
//           final args =
//               ModalRoute.of(context)?.settings.arguments;
//
//           String? arrId;
//
//           // Normal route argument:
//           // Navigator.pushNamed(
//           //   context,
//           //   '/ARR/previousArrDetail',
//           //   arguments: arrId,
//           // );
//           if (args is String) {
//             arrId = args;
//           }
//
//           // Also support a Map argument if used elsewhere.
//           else if (args is Map) {
//             arrId = args['arrId']?.toString();
//           }
//
//           if (arrId == null || arrId!.isEmpty) {
//             return const ArrGuard(child: PreviousArrScreen());
//           }
//
//           return ArrGuard(
//             child: PreviousArrDetailScreen(
//               arrId: arrId!,
//             ),
//           );
//         },
//
//         '/ARR/evaluation': (_) =>
//         const ArrGuard(child: EvaluationScreen()),
//
//         '/ARR/certificate': (_) =>
//         const ArrGuard(child: CertificateScreen()),
//
//         '/ARR/combinedReport': (_) =>
//         const ArrGuard(child: CombinedReportScreen()),
//
//         '/ARR/combinedCertificate': (context) {
//           final args =
//               ModalRoute.of(context)?.settings.arguments;
//
//           if (args is! List) {
//             return const ArrGuard(
//               child: Scaffold(
//                 body: Center(
//                   child: Text(
//                     'Certificate records are missing.',
//                   ),
//                 ),
//               ),
//             );
//           }
//
//           return ArrGuard(
//             child: CombinedCertificateScreen(
//               records: List<ArrRecord>.from(args),
//             ),
//           );
//         },
//
//         '/ARR/crossTabResult': (context) {
//           final args =
//               ModalRoute.of(context)?.settings.arguments;
//
//           if (args is! Map) {
//             return const ArrGuard(
//               child: Scaffold(
//                 body: Center(
//                   child: Text(
//                     'Cross Tab data is missing.',
//                   ),
//                 ),
//               ),
//             );
//           }
//
//           final result = args['result'];
//
//           final selectedRecords =
//           args['selectedRecords'];
//
//           if (result is! CrossTabResult ||
//               selectedRecords is! List) {
//             return const ArrGuard(
//               child: Scaffold(
//                 body: Center(
//                   child: Text(
//                     'Invalid Cross Tab data.',
//                   ),
//                 ),
//               ),
//             );
//           }
//
//           return ArrGuard(
//             child: CrossTabResultScreen(
//               result: result,
//               selectedRecords:
//               List<ArrRecord>.from(selectedRecords),
//             ),
//           );
//         },
//         // =========================
//         // ADMIN MODULE
//         // =========================
//         '/ARR/admin': (_) =>
//         const ArrGuard(child: AdminGuard(child: AdminDashboardScreen())),
//
//         '/ARR/admin/batchManagement': (_) =>
//         const ArrGuard(child: AdminGuard(child: BatchManagementScreen())),
//
//         '/ARR/admin/partManagement': (_) =>
//         const ArrGuard(child: AdminGuard(child: PartManagementScreen())),
//
//         '/ARR/admin/qrGenerator': (_) =>
//         const ArrGuard(child: AdminGuard(child: QrGeneratorScreen())),
//
//         '/ARR/admin/scanPart': (_) =>
//         const ArrGuard(child: AdminGuard(child: ScanPartScreen())),
//
//         '/ARR/admin/settings': (_) =>
//         const ArrGuard(child: AdminGuard(child: SettingsScreen())),
//       },
//     );
//   }
//
// }


import'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


import 'screens/eqms_home_screen.dart';

// DCC
import 'screens/dcc/dcc_document_control_screen.dart';
import 'screens/dcc/dcc_login_screen.dart';
import 'screens/dcc/admin/admin_dcc_dashboard_screen.dart';
import 'screens/dcc/admin/add_dcc_user_screen.dart';
import 'screens/dcc/admin/user_management_screen.dart';
import 'screens/dcc/user/user_dashboard_screen.dart';
import 'screens/dcc/user/new_document_screen.dart';
import 'screens/dcc/user/my_documents_screen.dart';
import 'screens/dcc/user/dmr_request_screen.dart';
import 'screens/dcc/user/dmr_history_screen.dart';
import 'screens/dcc/user/released_documents_screen.dart';
import 'screens/dcc/user/user_dmr_requests_screen.dart';
import 'screens/dcc/dcc/dcc_dashboard_screen.dart';
import 'screens/dcc/dcc/dcc_manage_sidebar_screen.dart';
import 'screens/dcc/dcc/dcc_pending_documents_screen.dart';
import 'screens/dcc/dcc/dcc_released_documents_screen.dart';
import 'screens/dcc/dcc/dcc_dmr_requests_screen.dart';
import 'screens/dcc/dcc/dcc_document_review_screen.dart';
import 'screens/dcc/dcc/dcc_master_data_screen.dart';
import 'screens/dcc/hod/hod_dashboard_screen.dart';
import 'screens/dcc/hod/hod_dmr_requests_screen.dart';
import 'screens/dcc/hod/hod_activity_history_screen.dart';
import 'screens/dcc/hod/hod_document_review_screen.dart';
import 'models/dcc/dcc_document.dart';
import 'widgets/dcc_guard.dart';
import 'services/dcc/dcc_session.dart';



// CCR
import 'screens/ccr/ccr_admin_users_screen.dart';
import 'widgets/admin_guard.dart';
import 'services/app_notifications.dart';
import 'services/ccr/ccr_session.dart';
import 'screens/ccr/ccr_login_screen.dart';
import 'screens/ccr/ccr_admin_dashboard_screen.dart';
import 'screens/ccr/ccr_admin_records_screen.dart';
import 'services/admin_session.dart';
import 'services/session_activity.dart';
import 'screens/audit/audit_dashboard_screen.dart'
as audit_dashboard;

import 'screens/dcc/admin/admin_released_documents_screen.dart';

import 'screens/audit/start_audit_screen.dart'
as audit_start;

import 'screens/audit/audit_checklist_screen.dart'
as audit_checklist;

import 'screens/audit/audit_categories_screen.dart'
as audit_categories;

import 'screens/audit/audit_mil_report_screen.dart'
as audit_mil;

import 'screens/audit/audit_report_screen.dart'
as audit_report;

import 'screens/audit/audit_admin_login_screen.dart'
as audit_admin_login;

import 'screens/audit/audit_type_management_screen.dart'
as audit_type_management;

import 'screens/audit/audit_category_management_screen.dart'
as audit_category_management;

import 'screens/audit/audit_question_management_screen.dart'
as audit_question_management;

import 'screens/audit/audit_auditor_management_screen.dart'
as audit_auditor_management;

import 'screens/audit/audit_master_data_management_screen.dart'
as audit_master_data;

import 'screens/audit/audit_schedule_screen.dart'
as audit_schedule;
import 'screens/audit/audit_schedule_screen.dart'
as audit_schedule;

import 'screens/audit/audit_records_management_screen.dart'
as audit_records_management;

import 'screens/ccr/ccr_home_screen.dart';
import 'screens/ccr/ccr_home_screen.dart';
import 'screens/ccr/ccr_registration_screen.dart';
import 'screens/ccr/ccr_containment_screen.dart';
import 'screens/ccr/ccr_report_screen.dart';
import 'screens/ccr/ccr_team_management_screen.dart';
import 'screens/ccr/ccr_login_screen.dart';
import 'screens/ccr/ccr_admin_dashboard_screen.dart';
import 'screens/ccr/ccr_admin_records_screen.dart';

import 'screens/ncr/ncr_login_screen.dart';
import 'screens/ncr/ncr_dashboard_screen.dart';
import 'screens/ncr/ncr_admin_dashboard_screen.dart';
import 'screens/ncr/ncr_user_dashboard_screen.dart';
import 'screens/ncr/ncr_hod_dashboard_screen.dart';
import 'screens/ncr/ncr_dcc_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // Initialize Hive for modules that still use local storage.
  await Hive.initFlutter();

  // DCC local storage
  await Hive.openBox('dccUsers');
  await Hive.openBox('dccDocuments');
  await Hive.openBox('dccActivities');
  await Hive.openBox('dccDmrRequests');

  // CCR session storage
  await Hive.openBox('ccrSession');
  await CcrSession.init();

  // Restore remaining module sessions.
  await DccSession.restoreSession();

  runApp(const DigitalARRApp());
}

class DigitalARRApp extends StatelessWidget {
  const DigitalARRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'eQMS',
      theme: ThemeData(primarySwatch: Colors.blue),
      // Any tap/scroll/keystroke anywhere in the app counts as
      // activity and resets the 30-minute idle-logout clock shared
      // by AdminSession, ArrSession and DccSession.
      builder: (context, child) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            SessionActivity.touch();
          },
          onPointerMove: (_) {
            SessionActivity.touch();
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
      initialRoute: '/',
      routes: {
        // =========================
        // EQMS ROOT
        // =========================
        '/': (_) => const EqmsHomeScreen(),

        // =========================
        // DCC MODULE
        // =========================

        // =========================
// AUDIT MODULE - NEW
// =========================

        '/AUDIT': (_) =>
        const audit_dashboard.AuditDashboardScreen(),

        '/AUDIT/start': (_) =>
        const audit_start.StartAuditScreen(),

        '/AUDIT/categories': (context) {
          final auditId =
          ModalRoute.of(context)
              ?.settings
              .arguments
              ?.toString();

          if (auditId == null || auditId.isEmpty) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Audit ID is missing.',
                ),
              ),
            );
          }

          return audit_categories.AuditCategoriesScreen(
            auditId: auditId,
          );
        },

        '/AUDIT/checklist': (context) {
          final arguments =
              ModalRoute.of(context)?.settings.arguments;

          if (arguments is! Map) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Checklist information is missing.',
                ),
              ),
            );
          }

          final auditId =
          arguments['auditId']?.toString();

          final categoryId =
          arguments['categoryId']?.toString();

          if (auditId == null ||
              auditId.isEmpty ||
              categoryId == null ||
              categoryId.isEmpty) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Audit or Category ID is missing.',
                ),
              ),
            );
          }

          return audit_checklist.AuditChecklistScreen(
            auditId: auditId,
            categoryId: categoryId,
          );
        },

        '/AUDIT/mil': (context) {
          final auditId =
          ModalRoute.of(context)
              ?.settings
              .arguments
              ?.toString();

          if (auditId == null || auditId.isEmpty) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Audit ID is missing.',
                ),
              ),
            );
          }

          return audit_mil.AuditMilReportScreen(
            auditId: auditId,
          );
        },

        '/AUDIT/report': (context) {
          final auditId =
          ModalRoute.of(context)
              ?.settings
              .arguments
              ?.toString();

          if (auditId == null || auditId.isEmpty) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Audit ID is missing.',
                ),
              ),
            );
          }

          return audit_report.AuditReportScreen(
            auditId: auditId,
          );
        },

// ============================================================
// AUDIT ADMIN LOGIN
// ============================================================

        '/AUDIT/admin/login': (_) =>
        const audit_admin_login.AuditAdminLoginScreen(),

// ============================================================
// AUDIT TYPE MANAGEMENT
// ============================================================

        '/AUDIT/admin': (context) {
          final arguments =
              ModalRoute.of(context)
                  ?.settings
                  .arguments;

          if (arguments is! Map) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Admin session information is missing.',
                ),
              ),
            );
          }

          final sessionToken =
          arguments['sessionToken']?.toString();

          if (sessionToken == null ||
              sessionToken.isEmpty) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Admin session is missing.',
                ),
              ),
            );
          }

          return const audit_type_management
              .AuditTypeManagementScreen();
        },

// ============================================================
// AUDIT CATEGORY MANAGEMENT
// ============================================================

        '/AUDIT/admin/categories': (context) {
          final arguments =
              ModalRoute.of(context)?.settings.arguments;

          if (arguments is! Map) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Category information is missing.',
                ),
              ),
            );
          }

          final sessionToken =
          arguments['sessionToken']?.toString();

          final typeId =
          arguments['typeId']?.toString();

          final auditTypeName =
              arguments['auditTypeName']?.toString() ?? '';

          if (sessionToken == null ||
              sessionToken.isEmpty ||
              typeId == null ||
              typeId.isEmpty) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Admin session or Audit Type information is missing.',
                ),
              ),
            );
          }

          return audit_category_management
              .AuditCategoryManagementScreen(
            sessionToken: sessionToken,
            typeId: typeId,
            auditTypeName: auditTypeName,
          );
        },
// ============================================================
// AUDIT QUESTION MANAGEMENT
// ============================================================

        '/AUDIT/admin/questions': (context) {
          final arguments =
              ModalRoute.of(context)
                  ?.settings
                  .arguments;

          if (arguments is! Map) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Question information is missing.',
                ),
              ),
            );
          }

          final sessionToken =
          arguments['sessionToken']?.toString();

          final categoryId =
          arguments['categoryId']?.toString();

          final categoryName =
              arguments['categoryName']
                  ?.toString() ??
                  '';

          if (sessionToken == null ||
              sessionToken.isEmpty ||
              categoryId == null ||
              categoryId.isEmpty) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Admin session or Category information is missing.',
                ),
              ),
            );
          }

          return audit_question_management
              .AuditQuestionManagementScreen(
            sessionToken: sessionToken,
            categoryId: categoryId,
            categoryName: categoryName,
          );
        },

        '/AUDIT/admin/auditors': (context) {
          final arguments =
              ModalRoute.of(context)
                  ?.settings
                  .arguments;

          if (arguments is! Map) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Auditor administration information is missing.',
                ),
              ),
            );
          }

          final sessionToken =
          arguments['sessionToken']
              ?.toString();

          final email =
          arguments['email']
              ?.toString();

          if (sessionToken == null ||
              sessionToken.isEmpty) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Admin session is missing.',
                ),
              ),
            );
          }

          return audit_auditor_management
              .AuditAuditorManagementScreen(
            key: ValueKey(
              sessionToken,
            ),
          );
        },
        '/AUDIT/admin/master-data':
            (context) {
          final args =
              ModalRoute.of(context)
                  ?.settings
                  .arguments;

          return audit_master_data
              .AuditMasterDataManagementScreen();
        },
        // ============================================================
        // AUDIT SCHEDULE
        // ============================================================

        '/AUDIT/admin/schedule': (context) {
          final arguments =
              ModalRoute.of(context)
                  ?.settings
                  .arguments;

          if (arguments is! Map) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Audit schedule administration information is missing.',
                ),
              ),
            );
          }

          final sessionToken =
          arguments['sessionToken']
              ?.toString();

          if (sessionToken == null ||
              sessionToken.isEmpty) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Admin session is missing.',
                ),
              ),
            );
          }

          return audit_schedule
              .AuditScheduleScreen(
            sessionToken:
            sessionToken,
          );
        },
        // ============================================================
// AUDIT RECORDS MANAGEMENT
// ============================================================

        '/AUDIT/admin/records': (context) {
          final arguments =
              ModalRoute.of(context)
                  ?.settings
                  .arguments;

          if (arguments is! Map) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Audit Records administration information is missing.',
                ),
              ),
            );
          }

          final sessionToken =
          arguments['sessionToken']
              ?.toString()
              .trim();

          if (sessionToken == null ||
              sessionToken.isEmpty) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Admin session is missing.',
                ),
              ),
            );
          }

          return audit_records_management
              .AuditRecordsManagementScreen(
            sessionToken: sessionToken,
          );
        },
        // =========================
// NCR MODULE
// =========================

        // =========================
// NCR MODULE
// =========================

        '/NCR': (_) =>
        const NcrDashboardScreen(),

        '/NCR/login': (_) =>
        const NcrLoginScreen(),

        '/NCR/admin-dashboard': (_) =>
        const NcrAdminDashboardScreen(),

        '/NCR/user-dashboard': (_) =>
        const NcrUserDashboardScreen(),

        '/NCR/hod-dashboard': (_) =>
        const NcrHodDashboardScreen(),

        '/NCR/dcc-dashboard': (_) =>
        const NcrDccDashboardScreen(),

        // =========================
        // CCR MODULE
        // =========================
        '/CCR/admin/users': (_) =>
        const CcrAdminUsersScreen(),
        '/CCR': (_) => const CcrHomeScreen(),
        '/CCR/team-management': (_) =>
        const CcrTeamManagementScreen(),
        '/CCR/login': (_) =>
        const CcrLoginScreen(),

        '/CCR/admin': (_) =>
        const CcrAdminDashboardScreen(),

        '/CCR/admin/records': (_) =>
        const CcrAdminRecordsScreen(),
        '/CCR/registration': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments;

          if (args is! String || args.isEmpty) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'CCR ID is missing.',
                ),
              ),
            );
          }

          return CcrRegistrationScreen(
            ccrId: args,
          );
        },


        '/CCR/containment': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments;

          if (args is! String) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'CCR ID is missing.',
                ),
              ),
            );
          }

          return CcrContainmentScreen(
            ccrId: args,
          );
        },
        '/CCR/report': (context) {
          final String? ccrId =
          ModalRoute.of(context)
              ?.settings
              .arguments as String?;

          if (ccrId == null ||
              ccrId.trim().isEmpty) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'CCR ID is missing.',
                ),
              ),
            );
          }

          return CcrReportScreen(
            ccrId: ccrId,
          );
        },
        '/DCC': (_) => const DccDocumentControlScreen(),

        '/DCC/login': (_) => const DccLoginScreen(),
        '/DCC/admin/releasedDocuments': (_) => const DccGuard(
          requiredRole: 'ADMIN',
          child: AdminReleasedDocumentsScreen(),
        ),
        // Login gate used by the public Document Control Centre's +New action.
        // Anyone may see the button, but only a valid DCC account can continue
        // to the folder/document creation menu.
        '/DCC/loginForNew': (_) => const DccLoginScreen(
          requiredRole: 'DCC',
          redirectRoute: '/DCC/dcc/manageSidebar',
        ),

        '/DCC/admin/dashboard': (_) => const DccGuard(
          requiredRole: 'ADMIN',
          child: AdminDccDashboardScreen(),
        ),

        '/DCC/admin/addUser': (_) => const DccGuard(
          requiredRole: 'ADMIN',
          child: AddDccUserScreen(),
        ),

        '/DCC/admin/userManagement': (_) => const DccGuard(
          requiredRole: 'ADMIN',
          child: UserManagementScreen(),
        ),

        '/DCC/user/dashboard': (_) => const DccGuard(
          requiredRole: 'USER',
          child: UserDashboardScreen(),
        ),

        '/DCC/user/newDocument': (_) => const DccGuard(
          requiredRole: 'USER',
          child: NewDocumentScreen(),
        ),

        '/DCC/user/myDocuments': (_) => const DccGuard(
          requiredRole: 'USER',
          child: MyDocumentsScreen(),
        ),

        '/DCC/user/dmrRequest': (_) => const DccGuard(
          requiredRole: 'USER',
          child: DmrRequestScreen(),
        ),

        '/DCC/user/dmrHistory': (_) => const DccGuard(
          requiredRole: 'USER',
          child: DmrRequestsScreen(),
        ),

        '/DCC/user/releasedDocuments': (_) => const DccGuard(
          requiredRole: 'USER',
          child: ReleasedDocumentsScreen(),
        ),

        '/DCC/user/dmrRequestsList': (_) => const DccGuard(
          requiredRole: 'USER',
          child: UserDmrRequestsScreen(),
        ),

        '/DCC/dcc/dashboard': (_) => const DccGuard(
          requiredRole: 'DCC',
          child: DccDashboardScreen(),
        ),

        '/DCC/dcc/manageSidebar': (_) => const DccGuard(
          requiredRole: 'DCC',
          redirectRoute: '/DCC/dcc/manageSidebar',
          child: DccManageSidebarScreen(),
        ),

        '/DCC/dcc/pendingDocuments': (_) => const DccGuard(
          requiredRole: 'DCC',
          child: DccPendingDocumentsScreen(),
        ),

        '/DCC/dcc/releasedDocuments': (_) => const DccGuard(
          requiredRole: 'DCC',
          child: DccReleasedDocumentsScreen(),
        ),

        '/DCC/dcc/dmrRequests': (_) => const DccGuard(
          requiredRole: 'DCC',
          child: DccDmrRequestsScreen(),
        ),

        '/DCC/dcc/masterData': (_) => const DccGuard(
          requiredRole: 'DCC',
          redirectRoute: '/DCC/dcc/masterData',
          child: DccMasterDataScreen(),
        ),

        '/DCC/dcc/documentReview': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments;

          if (args is! DccDocument) {
            return const DccGuard(
              requiredRole: 'DCC',
              child: Scaffold(
                body: Center(
                  child: Text('Document data is missing.'),
                ),
              ),
            );
          }

          return DccGuard(
            requiredRole: 'DCC',
            child: DccDocumentReviewScreen(document: args),
          );
        },

        '/DCC/hod/dashboard': (_) => const DccGuard(
          requiredRole: 'HOD',
          child: HodDashboardScreen(),
        ),

        '/DCC/hod/dmrRequests': (_) => const DccGuard(
          requiredRole: 'HOD',
          child: HodDmrRequestsScreen(),
        ),

        '/DCC/hod/activityHistory': (_) => const DccGuard(
          requiredRole: 'HOD',
          child: HodActivityHistoryScreen(),
        ),

        '/DCC/hod/documentReview': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments;

          if (args is! DccDocument) {
            return const DccGuard(
              requiredRole: 'HOD',
              child: Scaffold(
                body: Center(
                  child: Text('Document data is missing.'),
                ),
              ),
            );
          }

          return DccGuard(
            requiredRole: 'HOD',
            child: HodDocumentReviewScreen(document: args),
          );
        },
      },
    );
  }
}
