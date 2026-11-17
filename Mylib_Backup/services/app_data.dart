import '../models/arr_record.dart';
import 'dart:typed_data';

class AppData {
  static String employeeCode = "";

  static String appraiseeName = "";

  static String department = "";

  static String productName = "";

  static Uint8List? candidatePhoto;

  static String candidatePhotoPath = "";

  static String selectedBatchId = "";

  static String selectedBatchName = "";

  /// Master parts loaded from Supabase for the current ARR.
  static List<Map<String, dynamic>> masterParts = [];

  static int currentTrail = 1;

  static List<int> trail1Answers = [];

  static List<int> trail2Answers = [];

  static List<int> trail3Answers = [];

  static List<ArrRecord> previousArrs = [];

  static String finalClassification = "";

  static double falseAlertPercent = 0;

  static double missRate = 0;

  static double effectiveness = 0;

  static double kappa = 0;

  static String certificateNo = "";

  /// Supabase ID of the currently completed ARR.
  static String savedArrId = "";
  static void resetAssessment() {
    currentTrail = 1;

    trail1Answers = <int>[];
    trail2Answers = <int>[];
    trail3Answers = <int>[];

    finalClassification = "";

    falseAlertPercent = 0;

    missRate = 0;

    effectiveness = 0;

    kappa = 0;

    certificateNo = "";

    savedArrId = "";

    masterParts = [];

    candidatePhoto = null;

    candidatePhotoPath = "";

    employeeCode = "";

    appraiseeName = "";

    department = "";

    productName = "";

// Do NOT reset selected batch.
// It is selected before starting the assessment.
//
// selectedBatchId = "";
// selectedBatchName = "";
  }
  static String falseAlertStatus() {

    if (falseAlertPercent <= 5) {
      return "ACCEPTABLE";
    }

    if (falseAlertPercent < 10) {
      return "MARGINALLY ACCEPTABLE";
    }

    return "NOT ACCEPTABLE";

  }
  static String missRateStatus() {

    if (missRate < 2) {
      return "ACCEPTABLE";
    }

    if (missRate <= 5) {
      return "MARGINALLY ACCEPTABLE";
    }

    return "NOT ACCEPTABLE";

  }
  static String effectivenessStatus() {

    if (effectiveness >= 90) {
      return "ACCEPTABLE";
    }

    if (effectiveness >= 80) {
      return "MARGINALLY ACCEPTABLE";
    }

    return "NOT ACCEPTABLE";

  }
  static String kappaStatus() {

    if (kappa >= 80) {
      return "ACCEPTABLE";
    }

    if (kappa >= 60) {
      return "MARGINALLY ACCEPTABLE";
    }

    return "NOT ACCEPTABLE";

  }
}
