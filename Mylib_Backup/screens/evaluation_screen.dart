import 'package:flutter/material.dart';
import '../services/evaluation_service.dart';
import '../services/app_data.dart';
import '../models/arr_record.dart';
import '../services/hive_service.dart';

class EvaluationScreen extends StatelessWidget {
  const EvaluationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final resultData = EvaluationService.calculate(
      masterParts: AppData.masterParts,
    );
    AppData.finalClassification = resultData["classification"];

    AppData.falseAlertPercent = resultData["falseAlertPercent"];

    AppData.missRate = resultData["missRate"];

    AppData.effectiveness = resultData["effectiveness"];

    AppData.kappa = resultData["kappa"];

    try {

      AppData.certificateNo =
          HiveService.generateCertificateNumber(
            employeeCode: AppData.employeeCode,
            appraisee: AppData.appraiseeName,
            department: AppData.department,
          );
      debugPrint(
        "Generated Certificate: ${AppData.certificateNo}",
      );

    } catch (e) {

      WidgetsBinding.instance.addPostFrameCallback((_) {

        if (context.mounted) {

          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),

          );

          Navigator.pop(context);

        }

      });

      return const Scaffold();

    }
    String today =
        "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";

    AppData.previousArrs = HiveService.loadPreviousArrs();
    final batchQuestions =
    HiveService.loadBatchQuestions(
      AppData.selectedBatchId,
    );
    AppData.previousArrs.add(
      ArrRecord(
        employeeCode: AppData.employeeCode,
        appraisee: AppData.appraiseeName,
        department: AppData.department,
        product: AppData.productName,
        batchName: AppData.selectedBatchName,
        result: AppData.finalClassification,
        certificateNo: AppData.certificateNo,
        date: today,

        falseAlertPercent: AppData.falseAlertPercent,
        missRate: AppData.missRate,
        effectiveness: AppData.effectiveness,
        kappa: AppData.kappa,

        trail1Answers: List<int>.from(AppData.trail1Answers),
        trail2Answers: List<int>.from(AppData.trail2Answers),
        trail3Answers: List<int>.from(AppData.trail3Answers),


        candidatePhotoPath:
        AppData.candidatePhotoPath,

        batchId:
        AppData.selectedBatchId,

        partNumbers:
        batchQuestions
            .map((e) => e.partNo)
            .toList(),

        masterAnswers:
        batchQuestions
            .map((e) => e.initialStatus)
            .toList(),
      ),
    );

    HiveService.savePreviousArrs(AppData.previousArrs);
    return Scaffold(
      appBar: AppBar(title: const Text("ARR Evaluation Report")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            Card(
              elevation: 5,

              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  children: [
                    const Text(
                      "Evaluation Metrics",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Divider(),

                    reportRow(
                      "False Alert Count",
                      resultData["falseAlert"].toString(),
                    ),

                    reportRow(
                      "Miss Alert Count",
                      resultData["missAlert"].toString(),
                    ),

                    reportRow(
                      "False Alert %",
                      resultData["falseAlertPercent"].toStringAsFixed(2),
                    ),

                    reportRow(
                      "Miss Rate %",
                      resultData["missRate"].toStringAsFixed(2),
                    ),

                    reportRow(
                      "Effectiveness %",
                      resultData["effectiveness"].toStringAsFixed(2),
                    ),

                    reportRow("P1", resultData["p1"].toStringAsFixed(3)),

                    reportRow("P0", resultData["p0"].toStringAsFixed(3)),

                    reportRow(
                      "PChance",
                      resultData["pChance"].toStringAsFixed(3),
                    ),

                    reportRow(
                      "Kappa %",
                      resultData["kappa"].toStringAsFixed(2),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: resultData["classification"] == "ACCEPTABLE"
                    ? Colors.green.shade100
                    : resultData["classification"] == "MARGINALLY ACCEPTABLE"
                    ? Colors.orange.shade100
                    : Colors.red.shade100,

                borderRadius: BorderRadius.circular(15),
              ),

              child: Column(
                children: [
                  const Text("Final Result", style: TextStyle(fontSize: 18)),

                  const SizedBox(height: 10),

                  Text(
                    resultData["classification"],

                    textAlign: TextAlign.center,

                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              icon: const Icon(Icons.workspace_premium),

              onPressed: () {
                Navigator.pushNamed(context, '/certificate');
              },

              label: const Text("Generate Certificate"),
            ),
          ],
        ),
      ),
    );
  }

  Widget reportRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),

          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
