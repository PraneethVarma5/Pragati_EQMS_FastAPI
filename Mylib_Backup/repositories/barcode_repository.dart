import '../services/app_data.dart';
import '../services/hive_service.dart';

class BarcodeRepository {
  BarcodeRepository._();

  static int? getIndex(String barcode) {
    final questions = HiveService.loadBatchQuestions(
      AppData.selectedBatchId,
    );

    // for (int i = 0; i < questions.length; i++) {
    //   if (questions[i].barcode == barcode) {
    //     return i;
    //   }
    // }
    print("Scanned Barcode : $barcode");
    print("Selected Batch : ${AppData.selectedBatchId}");
    print("Total Questions : ${questions.length}");

    for (int i = 0; i < questions.length; i++) {
      print(
        "Question $i -> Part=${questions[i].partNo}  Barcode=${questions[i].barcode}",
      );

      if (questions[i].barcode.trim() == barcode.trim()) {
        print("MATCH FOUND");

        return i;
      }
    }

    print("NO MATCH FOUND");

    return null;
  }
}