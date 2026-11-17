// import 'package:flutter/material.dart';
// import '../services/app_data.dart';
// import '../services/pdf_service.dart';
// class CombinedCertificateScreen extends StatelessWidget {
//   const CombinedCertificateScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     debugPrint(
//       "Certificate Screen: ${AppData.certificateNo}",
//     );
//     final today = DateTime.now();
//
//     final validTill =
//     AppData.finalClassification == "NOT ACCEPTABLE"
//         ? today
//         : DateTime(
//       today.year,
//       today.month + 3,
//       today.day,
//     );
//
//     return Scaffold(
//       appBar: AppBar(title: const Text("ARR Certificate"), centerTitle: true),
//
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//
//         child: Card(
//           elevation: 8,
//
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//
//           child: Padding(
//             padding: const EdgeInsets.all(18),
//
//             child: Column(
//               children: [
//                 Image.asset("assets/full_logo.png", height: 90),
//
//                 const SizedBox(height: 12),
//
//                 const Text(
//                   "ARR CERTIFICATE",
//                   style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//                 ),
//
//                 const Divider(thickness: 2),
//
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//
//                   children: [
//                     Expanded(
//                       flex: 3,
//
//                       child: Column(
//                         children: [
//                           infoRow("Name", AppData.appraiseeName),
//
//                           infoRow("Department", AppData.department),
//                           infoRow(
//                             "Employee Code",
//                             AppData.employeeCode,
//                           ),
//                           infoRow(
//                             "Date of Test",
//                             "${today.day}/${today.month}/${today.year}",
//                           ),
//
//                           infoRow("Product Name", AppData.productName),
//
//                           infoRow(
//                             "Batch",
//                             AppData.selectedBatchName,
//                           ),
//
//                           infoRow("DOJ", "01/01/2024"),
//                         ],
//                       ),
//                     ),
//
//                     const SizedBox(width: 15),
//                     Expanded(
//                       flex: 2,
//
//                       child: Column(
//                         children: [
//                           const Text(
//                             "Photo",
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//
//                           const SizedBox(height: 8),
//
//                           Container(
//                             height: 150,
//
//                             decoration: BoxDecoration(border: Border.all()),
//
//                             child: AppData.candidatePhoto == null
//                                 ? const Center(
//                               child: Icon(Icons.person, size: 70),
//                             )
//                                 : Image.file(
//                               AppData.candidatePhoto!,
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 40),
//
//                 Table(
//                   border: TableBorder.all(),
//
//                   columnWidths: const {
//                     0: FlexColumnWidth(2.8),
//
//                     1: FlexColumnWidth(1.8),
//
//                     2: FlexColumnWidth(2.8),
//                   },
//
//                   children: [
//                     const TableRow(
//                       decoration: BoxDecoration(color: Color(0xffEAEAEA)),
//
//                       children: [
//                         tableHeading("Test Parameter"),
//
//                         tableHeading("Actual"),
//
//                         tableHeading("Result"),
//                       ],
//                     ),
//
//                     tableData(
//                       "False Alert",
//                       "${AppData.falseAlertPercent.toStringAsFixed(2)}%",
//                       AppData.falseAlertStatus(),
//                     ),
//
//                     tableData(
//                       "Miss Rate",
//                       "${AppData.missRate.toStringAsFixed(2)}%",
//                       AppData.missRateStatus(),
//                     ),
//
//                     tableData(
//                       "Effectiveness",
//                       "${AppData.effectiveness.toStringAsFixed(2)}%",
//                       AppData.effectivenessStatus(),
//                     ),
//
//                     tableData(
//                       "Kappa",
//                       "${AppData.kappa.toStringAsFixed(2)}%",
//                       AppData.kappaStatus(),
//                     ),
//
//                     tableData("Final Result", "", AppData.finalClassification),
//                   ],
//                 ),
//
//                 const SizedBox(height: 25),
//
//                 infoRow("Certificate No", AppData.certificateNo),
//
//                 infoRow(
//                   "Certificate Validity",
//                   "${validTill.day}/${validTill.month}/${validTill.year}",
//                 ),
//
//                 const SizedBox(height: 25),
//
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     onPressed: () async {
//                       await PdfService.downloadCombinedCertificate(
//                         context: context,
//                       );
//                     },
//                     icon: const Icon(Icons.download),
//                     label: const Text("Download Certificate"),
//                   ),
//                 ),
//
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     onPressed: () async {
//                       await PdfService.printCombinedCertificate();
//                     },
//                     icon: const Icon(Icons.print),
//                     label: const Text("Print Certificate"),
//                   ),
//                 ),
//
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     onPressed: () async {
//                       await PdfService.shareCombinedCertificate();
//                     },
//                     icon: const Icon(Icons.share),
//                     label: const Text("Share Certificate"),
//                   ),
//                 ),
//                 const SizedBox(height: 15),
//
//                 ElevatedButton(
//                   onPressed: () {
//                     Navigator.pushNamedAndRemoveUntil(
//                       context,
//                       '/',
//                           (route) => false,
//                     );
//                   },
//
//                   child: const Text("Back To Home"),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget infoRow(String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//
//       child: Row(
//         children: [
//           Expanded(
//             flex: 2,
//
//             child: Text(
//               title,
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//
//           Expanded(flex: 3, child: Text(value)),
//         ],
//       ),
//     );
//   }
// }
//
// class tableHeading extends StatelessWidget {
//   final String text;
//
//   const tableHeading(this.text, {super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     debugPrint(
//       "Certificate Screen: ${AppData.certificateNo}",
//     );
//     return Padding(
//       padding: const EdgeInsets.all(8),
//
//       child: Text(
//         text,
//         textAlign: TextAlign.center,
//
//         style: const TextStyle(fontWeight: FontWeight.bold),
//       ),
//     );
//   }
// }
//
// TableRow tableData(String p1, String p2, String p3) {
//   Widget cell(String t) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
//
//       child: Text(t, textAlign: TextAlign.center),
//     );
//   }
//
//   return TableRow(children: [cell(p1), cell(p2), cell(p3)]);
// }


import 'package:flutter/material.dart';
import '../models/arr_record.dart';
import '../services/pdf_service.dart';

class CombinedCertificateScreen extends StatelessWidget {

  final List<ArrRecord> records;

  const CombinedCertificateScreen({
    super.key,
    required this.records,
  });

  Map<String, dynamic> _recordToMap(ArrRecord record) {
    return {
      "employee_code": record.employeeCode,
      "appraisee": record.appraisee,
      "department": record.department,
      "product": record.product,
      "batch_name": record.batchName,
      "result": record.result,
      "certificate_no": record.certificateNo,
      "date": record.date,
      "false_alert_percent": record.falseAlertPercent,
      "miss_rate": record.missRate,
      "effectiveness": record.effectiveness,
      "kappa": record.kappa,
      "trail1_answers": record.trail1Answers,
      "trail2_answers": record.trail2Answers,
      "trail3_answers": record.trail3Answers,
      "candidate_photo_path": record.candidatePhotoPath,
      "batch_id": record.batchId,
      "part_numbers": record.partNumbers,
      "master_answers": record.masterAnswers,
    };
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Combined Certificates"),
      ),

      body: Column(
        children: [

          Expanded(
            child: ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {

                final record = records[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),

                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text("${index + 1}"),
                    ),

                    title: Text(record.appraisee),

                    subtitle: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text("Employee : ${record.employeeCode}"),
                        Text("Certificate : ${record.certificateNo}"),
                        Text("Result : ${record.result}"),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(),

          Padding(
            padding: const EdgeInsets.all(12),

            child: Column(
              children: [

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text(
                      "Download Combined Certificate",
                    ),
                    onPressed: () async {
                      await PdfService.downloadCombinedCertificate(
                        context: context,
                        records: records
                            .map(_recordToMap)
                            .toList(),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text(
                      "Print Combined Certificate",
                    ),
                    onPressed: () async {
                      await PdfService.printCombinedCertificate(
                        records: records
                            .map(_recordToMap)
                            .toList(),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text(
                      "Share Combined Certificate",
                    ),
                    onPressed: () async {
                      await PdfService.printCombinedCertificate(
                        records: records
                            .map(_recordToMap)
                            .toList(),
                      );
                    },
                  ),
                ),

              ],
            ),
          ),

        ],
      ),
    );
  }
}
