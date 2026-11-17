import 'package:flutter/material.dart';
import '../services/question_data.dart';
import '../services/app_data.dart';
import '../services/hive_service.dart';
import '../models/question.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  late List<Question> masterQuestions;

  @override
  void initState() {
    super.initState();

    masterQuestions = HiveService.loadBatchQuestions(
      AppData.selectedBatchId,
    );

    if (masterQuestions.isEmpty) {
      masterQuestions = questions
          .map(
            (q) => Question(
              partNo: q.partNo,
              partName: q.partName,
              initialStatus: q.initialStatus,
              barcode: q.barcode,
              batchId: q.batchId,

            ),
          )
          .toList();
    }

    answers.clear();

    submittedQuestions.clear();

    currentQuestion = 0;

    selectedAnswer = null;
  }

  int currentQuestion = 0;

  int? selectedAnswer;

  Map<int, int> answers = {};

  Set<int> submittedQuestions = {};

  void submitAnswer() {
    if (selectedAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select PASS or FAIL")),
      );

      return;
    }

    answers[currentQuestion] = selectedAnswer!;

    submittedQuestions.add(currentQuestion);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✓ Answer Locked"),
        duration: Duration(milliseconds: 800),
      ),
    );

    if (submittedQuestions.length == masterQuestions.length) {
      List<int> finalAnswers = [];

      for (int i = 0; i < masterQuestions.length; i++) {
        finalAnswers.add(answers[i] ?? 0);
      }

      if (AppData.currentTrail == 1) {
        AppData.trail1Answers = finalAnswers;

        AppData.currentTrail = 2;

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/assessment',
              (route) => false,
        );

        return;
      }

      if (AppData.currentTrail == 2) {
        AppData.trail2Answers = finalAnswers;

        AppData.currentTrail = 3;

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/assessment',
              (route) => false,
        );

        return;
      }

      AppData.trail3Answers = finalAnswers;

      Navigator.pushReplacementNamed(
        context,
        '/evaluation',
      );

      return;
    }
    int nextQuestion = -1;

    for (int i = 0; i < masterQuestions.length; i++) {
      if (!submittedQuestions.contains(i)) {
        nextQuestion = i;

        break;
      }
    }

    if (nextQuestion != -1) {
      setState(() {
        currentQuestion = nextQuestion;

        selectedAnswer = answers.containsKey(nextQuestion)
            ? answers[nextQuestion]
            : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (masterQuestions.isEmpty) {
      return const Scaffold(body: Center(child: Text("No Master Data Found")));
    }
    final question = masterQuestions[currentQuestion];

    bool locked = submittedQuestions.contains(currentQuestion);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              "Trial ${AppData.currentTrail} - Part ${currentQuestion + 1}/${masterQuestions.length}",
            ),

            Text(
              "${submittedQuestions.length} Completed",
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            LinearProgressIndicator(
              value: masterQuestions.isEmpty
                  ? 0
                  : submittedQuestions.length / masterQuestions.length,
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,

              children: [
                trailChip(
                  "Trial 1",
                  AppData.currentTrail > 1,
                  AppData.currentTrail == 1,
                ),

                trailChip(
                  "Trial 2",
                  AppData.currentTrail > 2,
                  AppData.currentTrail == 2,
                ),

                trailChip("Trial 3", false, AppData.currentTrail == 3),
              ],
            ),

            const SizedBox(height: 20),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                icon: const Icon(Icons.list),

                label: const Text("Part Serial Numbers"),

                onPressed: () {
                  showModalBottomSheet(
                    context: context,

                    builder: (context) {
                      return Column(
                        children: [
                          const SizedBox(height: 15),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 15,
                                    height: 15,
                                    color: Colors.green,
                                  ),

                                  const SizedBox(width: 5),

                                  const Text("Submitted"),
                                ],
                              ),

                              Row(
                                children: [
                                  Container(
                                    width: 15,
                                    height: 15,
                                    color: Colors.orange,
                                  ),

                                  const SizedBox(width: 5),

                                  const Text("Current"),
                                ],
                              ),

                              Row(
                                children: [
                                  Container(
                                    width: 15,
                                    height: 15,
                                    color: Colors.grey,
                                  ),

                                  const SizedBox(width: 5),

                                  const Text("Pending"),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),

                              child: GridView.builder(
                                itemCount: masterQuestions.length,

                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,

                                      mainAxisSpacing: 10,

                                      crossAxisSpacing: 10,
                                    ),

                                itemBuilder: (context, index) {
                                  bool submitted = submittedQuestions.contains(
                                    index,
                                  );

                                  return ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: submitted
                                          ? Colors.green
                                          : currentQuestion == index
                                          ? Colors.orange
                                          : Colors.grey,

                                      foregroundColor: Colors.white,
                                    ),

                                    onPressed: () {
                                      if (submitted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Question Already Submitted",
                                            ),
                                          ),
                                        );

                                        return;
                                      }

                                      setState(() {
                                        currentQuestion = index;

                                        selectedAnswer = answers[index];
                                      });

                                      Navigator.pop(context);
                                    },

                                    child: Text("Q${index + 1}"),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    const Icon(
                      Icons.qr_code_scanner,
                      size: 90,
                      color: Colors.blue,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Scan the Part Barcode",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Open Scanner"),
                        onPressed: () async {
                          final barcode = await Navigator.pushNamed(
                            context,
                            '/scan',
                          );

                          if (barcode == null) return;

                          int index = masterQuestions.indexWhere(
                            (q) => q.barcode == barcode,
                          );

                          if (index == -1) {
                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Unknown Barcode")),
                            );

                            return;
                          }

                          if (submittedQuestions.contains(index)) {
                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Part Already Submitted"),
                              ),
                            );

                            return;
                          }

                          setState(() {
                            currentQuestion = index;

                            selectedAnswer = answers[index];
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            RadioListTile<int>(
              value: 1,
              groupValue: selectedAnswer,
              title: const Text("PASS"),
              onChanged: locked
                  ? null
                  : (value) {
                      setState(() {
                        selectedAnswer = value;
                      });
                    },
            ),

            RadioListTile<int>(
              value: 0,
              groupValue: selectedAnswer,
              title: const Text("FAIL"),
              onChanged: locked
                  ? null
                  : (value) {
                      setState(() {
                        selectedAnswer = value;
                      });
                    },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,

              height: 55,

              child: ElevatedButton(
                onPressed: locked ? null : submitAnswer,

                child: const Text("Submit Answer"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget trailChip(String title, bool completed, bool current) {
    Color color = Colors.grey;

    if (completed) {
      color = Colors.green;
    } else if (current) {
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),

      decoration: BoxDecoration(
        color: color,

        borderRadius: BorderRadius.circular(25),
      ),

      child: Text(
        title,

        style: const TextStyle(
          color: Colors.white,

          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
