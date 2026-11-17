import 'package:flutter/material.dart';
import '../services/app_data.dart';
import '../services/question_data.dart';
import '../models/arr_record.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final answers = ModalRoute.of(context)!.settings.arguments as List<int>;
    if (AppData.currentTrail == 1) {
      AppData.trail1Answers = answers;
    } else if (AppData.currentTrail == 2) {
      AppData.trail2Answers = answers;
    } else {
      AppData.trail3Answers = answers;
    }
    int correct = 0;

    for (int i = 0; i < questions.length; i++) {
      if (answers[i] == questions[i].initialStatus) {
        correct++;
      }
    }

    double score = (correct / questions.length) * 100;

    bool passed = score >= 50;
    String certificateNo = "CERT-${DateTime.now().millisecondsSinceEpoch}";
    // if (AppData.previousArrs.isEmpty ||
    //     AppData.previousArrs.last.appraisee !=
    //         AppData.appraiseeName) {
    //
    //   AppData.previousArrs.add(
    //
    //     ArrRecord(
    //
    //       appraiser:
    //       AppData.appraiserName,
    //
    //       appraisee:
    //       AppData.appraiseeName,
    //
    //       result:
    //       passed
    //           ? "PASS"
    //           : "FAIL",
    //
    //       score:
    //       "${score.toStringAsFixed(0)}%",
    //
    //       certificateNo:
    //       certificateNo,
    //     ),
    //   );
    // }
    return Scaffold(
      appBar: AppBar(title: const Text("Assessment Result")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Icon(
                  passed ? Icons.check_circle : Icons.cancel,

                  size: 120,

                  color: passed ? Colors.green : Colors.red,
                ),

                const SizedBox(height: 20),

                Text(
                  passed ? "PASS" : "FAIL",

                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "Correct Answers : $correct / ${questions.length}",
                  style: const TextStyle(fontSize: 20),
                ),

                const SizedBox(height: 10),
                Text("Candidate: ${AppData.appraiseeName}"),
                Text(
                  "Score : ${score.toStringAsFixed(0)}%",
                  style: const TextStyle(fontSize: 24),
                ),

                const SizedBox(height: 40),
                if (passed)
                  ElevatedButton(
                    onPressed: () {
                      if (AppData.currentTrail < 3) {
                        AppData.currentTrail++;

                        Navigator.pushNamedAndRemoveUntil(
                          context,

                          '/assessment',

                          (route) => false,
                        );
                      } else {
                        Navigator.pushNamed(context, '/evaluation');
                      }
                    },

                    child: Text(
                      AppData.currentTrail < 3
                          ? "Start Trial ${AppData.currentTrail + 1}"
                          : "Generate Evaluation",
                    ),
                  )
                else
                  const Text(
                    "Certificate Not Eligible",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    );
                  },
                  child: const Text("Home"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
