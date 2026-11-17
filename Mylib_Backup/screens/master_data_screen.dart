import 'package:flutter/material.dart';
import '../services/question_data.dart';
import '../services/hive_service.dart';
import '../models/question.dart';

class MasterDataScreen extends StatefulWidget {
  const MasterDataScreen({super.key});

  @override
  State<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataScreenState extends State<MasterDataScreen> {
  late List<Question> masterQuestions;

  @override
  void initState() {
    super.initState();

    masterQuestions = HiveService.loadMasterData();

    if (masterQuestions.isEmpty) {
      masterQuestions = List.from(questions);
    }
  }

  Future<void> saveData() async {
    await HiveService.saveMasterData(masterQuestions);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Master Data Saved Successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Master Data"), centerTitle: true),

      body: Column(
        children: [
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,

              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10, left: 10, right: 10),

                itemCount: masterQuestions.length,

                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),

                    child: ListTile(
                      title: Text(
                        "${masterQuestions[index].partNo} - ${masterQuestions[index].partName}",
                      ),

                      subtitle: Text(
                        "Status : ${masterQuestions[index].initialStatus}\n"
                        "Barcode : ${masterQuestions[index].barcode}",
                      ),

                      trailing: DropdownButton<int>(
                        value: masterQuestions[index].initialStatus,

                        items: const [
                          DropdownMenuItem(value: 1, child: Text("PASS (1)")),

                          DropdownMenuItem(value: 0, child: Text("FAIL (0)")),
                        ],

                        onChanged: (value) {
                          setState(() {
                            masterQuestions[index].initialStatus = value!;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(15),

              child: SizedBox(
                width: double.infinity,

                height: 55,

                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),

                  label: const Text(
                    "Save Master Data",
                    style: TextStyle(fontSize: 18),
                  ),

                  onPressed: saveData,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
