import'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/home_screen.dart';
import 'screens/candidate_screen.dart';
import 'screens/instruction_screen.dart';
import 'screens/assessment_screen.dart';
import 'screens/result_screen.dart';
import 'screens/previous_arr_screen.dart';
import 'screens/previous_arr_detail_screen.dart';
import 'models/arr_record.dart';
import 'screens/certificate_screen.dart';
import 'screens/evaluation_screen.dart';
import 'screens/report_screen.dart';
import 'screens/master_data_screen.dart';
import 'screens/barcode_scan_screen.dart';
import 'screens/scanner_assessment_screen.dart';
import 'screens/combined_report_screen.dart';
import 'screens/batch_selection_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/batch_management_screen.dart';
import 'screens/admin/part_management_screen.dart';
import 'screens/admin/qr_generator_screen.dart';
import 'screens/admin/scan_part_screen.dart';
import 'screens/admin/settings_screen.dart';
import 'screens/combined_certificate_screen.dart';
import 'screens/eqms_home_screen.dart';

import 'services/question_data.dart';
import 'services/hive_service.dart';
import 'services/app_data.dart';
import 'models/arr_record.dart';
import 'models/cross_tab_result.dart';
import 'screens/cross_tab_result_screen.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  await Hive.initFlutter();

  await Hive.openBox('masterData');
  await Hive.openBox('previousArr');

  AppData.previousArrs = HiveService.loadPreviousArrs();

  await Hive.openBox('candidateData');
  await Hive.openBox('batchData');
  await Hive.openBox('dccUsers');
  await Hive.openBox('dccDocuments');
  await Hive.openBox('dccActivities');
  await Hive.openBox('dccDmrRequests');

  await HiveService.updateFactoryMasterData(questions, 2);
  runApp(const DigitalARRApp());
}

class DigitalARRApp extends StatelessWidget {
  const DigitalARRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Digital ARR',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        // =========================
        // EQMS ROOT
        // =========================
        '/': (_) => const EqmsHomeScreen(),

        // =========================
        // ARR MODULE
        // =========================
        '/ARR': (_) => const HomeScreen(),

        '/ARR/candidate': (_) => const CandidateScreen(),

        '/ARR/master': (_) => const MasterDataScreen(),

        '/ARR/instruction': (_) => const InstructionScreen(),

        '/ARR/batch': (_) =>
        const BatchSelectionScreen(),

        '/ARR/scannerAssessment': (_) =>
        const ScannerAssessmentScreen(),

        '/ARR/assessment': (_) =>
        const AssessmentScreen(),

        '/ARR/scan': (_) =>
        const BarcodeScanScreen(),

        '/ARR/report': (_) =>
        const ReportScreen(),

        '/ARR/result': (_) =>
        const ResultScreen(),

        '/ARR/previous': (_) =>
        const PreviousArrScreen(),

        '/ARR/previousArrDetail': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments;

          String? arrId;

          // Normal route argument:
          // Navigator.pushNamed(
          //   context,
          //   '/ARR/previousArrDetail',
          //   arguments: arrId,
          // );
          if (args is String) {
            arrId = args;
          }

          // Also support a Map argument if used elsewhere.
          else if (args is Map) {
            arrId = args['arrId']?.toString();
          }

          if (arrId == null || arrId!.isEmpty) {
            return const PreviousArrScreen();
          }

          return PreviousArrDetailScreen(
            arrId: arrId!,
          );
        },

        '/ARR/evaluation': (_) =>
        const EvaluationScreen(),

        '/ARR/certificate': (_) =>
        const CertificateScreen(),

        '/ARR/combinedReport': (_) =>
        const CombinedReportScreen(),

        '/ARR/combinedCertificate': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments;

          if (args is! List) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Certificate records are missing.',
                ),
              ),
            );
          }

          return CombinedCertificateScreen(
            records: List<ArrRecord>.from(args),
          );
        },

        '/ARR/crossTabResult': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments;

          if (args is! Map) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Cross Tab data is missing.',
                ),
              ),
            );
          }

          final result = args['result'];

          final selectedRecords =
          args['selectedRecords'];

          if (result is! CrossTabResult ||
              selectedRecords is! List) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Invalid Cross Tab data.',
                ),
              ),
            );
          }

          return CrossTabResultScreen(
            result: result,
            selectedRecords:
            List<ArrRecord>.from(selectedRecords),
          );
        },
        // =========================
        // ADMIN MODULE
        // =========================
        '/ARR/admin': (_) =>
        const AdminDashboardScreen(),

        '/ARR/admin/batchManagement': (_) =>
        const BatchManagementScreen(),

        '/ARR/admin/partManagement': (_) =>
        const PartManagementScreen(),

        '/ARR/admin/qrGenerator': (_) =>
        const QrGeneratorScreen(),

        '/ARR/admin/scanPart': (_) =>
        const ScanPartScreen(),

        '/ARR/admin/settings': (_) =>
        const SettingsScreen(),
      },
    );
  }
}
