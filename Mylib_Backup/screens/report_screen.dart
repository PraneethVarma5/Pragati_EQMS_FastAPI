import 'package:flutter/material.dart';
import '../services/app_data.dart';
import '../services/hive_service.dart';
import '../models/question.dart';
import '../services/question_data.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    List<Question> masterQuestions =
    HiveService.loadBatchQuestions(
      AppData.selectedBatchId,
    );

    if (masterQuestions.isEmpty) {
      masterQuestions = List.from(questions);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("ARR Observation Report"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            const Text(
              "TRIAL OBSERVATION REPORT",

              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 5,

              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  children: [
                    reportRow("Employee Code", AppData.employeeCode),

                    reportRow("Appraisee", AppData.appraiseeName),

                    reportRow("Department", AppData.department),

                    reportRow("Product", AppData.productName),

                    reportRow("Total Parts", "${masterQuestions.length}"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            Table(
              border: TableBorder.all(),

              columnWidths: const {
                0: FlexColumnWidth(1.4),

                1: FlexColumnWidth(2.5),

                2: FlexColumnWidth(1),

                3: FlexColumnWidth(1),

                4: FlexColumnWidth(1),

                5: FlexColumnWidth(1),
              },

              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Color(0xffEAEAEA)),

                  children: [
                    tableCell("Part No", true),

                    tableCell("Part Name", true),

                    tableCell("T1", true),

                    tableCell("T2", true),

                    tableCell("T3", true),

                    tableCell("Master", true),
                  ],
                ),

                ...List.generate(masterQuestions.length, (index) {
                  return TableRow(
                    children: [
                      tableCell(masterQuestions[index].partNo, false),

                      tableCell(masterQuestions[index].partName, false),

                      tableCell(
                        AppData.trail1Answers.isNotEmpty
                            ? AppData.trail1Answers[index].toString()
                            : "-",
                        false,
                      ),

                      tableCell(
                        AppData.trail2Answers.isNotEmpty
                            ? AppData.trail2Answers[index].toString()
                            : "-",
                        false,
                      ),

                      tableCell(
                        AppData.trail3Answers.isNotEmpty
                            ? AppData.trail3Answers[index].toString()
                            : "-",
                        false,
                      ),

                      tableCell(
                        masterQuestions[index].initialStatus.toString(),
                        false,
                      ),
                    ],
                  );
                }),
              ],
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/evaluation');
                },

                child: const Text("Proceed To Evaluation"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget reportRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),

      child: Row(
        children: [
          Expanded(
            flex: 2,

            child: Text(
              title,

              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }
}

class tableCell extends StatelessWidget {
  final String text;

  final bool heading;

  const tableCell(this.text, this.heading, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),

      child: Text(
        text,

        textAlign: TextAlign.center,

        style: TextStyle(
          fontWeight: heading ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
