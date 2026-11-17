import 'package:flutter/material.dart';

import '../services/app_data.dart';
import '../services/supabase_service.dart';
import '../services/pdf_service.dart';

class CombinedReportScreen extends StatefulWidget {
  const CombinedReportScreen({super.key});

  @override
  State<CombinedReportScreen> createState() =>
      _CombinedReportScreenState();
}

class _CombinedReportScreenState
    extends State<CombinedReportScreen> {

  bool isLoading = true;

  String? errorMessage;

  Map<String, dynamic>? arrRecord;

  Map<String, dynamic>? employee;

  List<Map<String, dynamic>> observations = [];

  @override
  void initState() {
    super.initState();

    _loadArr();
  }

  Future<void> _loadArr() async {
    try {
      final arrId =
      AppData.savedArrId.trim();

      if (arrId.isEmpty) {
        throw Exception(
          'No completed ARR was selected.',
        );
      }

      final result =
      await SupabaseService.getCompleteArr(
        arrId,
      );

      if (!mounted) return;

      setState(() {
        arrRecord =
        Map<String, dynamic>.from(
          result['record'] as Map,
        );

        final employeeData =
        result['employee'];

        employee =
        employeeData == null
            ? null
            : Map<String, dynamic>.from(
          employeeData as Map,
        );

        observations =
        List<Map<String, dynamic>>.from(
          result['observations'] as List,
        );

        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }
  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null || arrRecord == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "ARR Observation Report",
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Icon(
                  Icons.cloud_off_outlined,
                  size: 48,
                  color: Color(0xFFC62828),
                ),

                const SizedBox(height: 16),

                const Text(
                  "Unable to Load ARR",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  errorMessage ??
                      "ARR record was not found.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF747B86),
                  ),
                ),

                const SizedBox(height: 18),

                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                      errorMessage = null;
                    });

                    _loadArr();
                  },
                  icon: const Icon(
                    Icons.refresh_rounded,
                  ),
                  label: const Text(
                    "Retry",
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final record = arrRecord!;

    final resultData = {
      "classification":
      record["classification"] ?? "UNACCEPTABLE",

      "falseAlert":
      record["false_alert_count"] ?? 0,

      "missAlert":
      record["miss_alert_count"] ?? 0,

      "falseAlertPercent":
      (record["false_alert_pct"] ?? 0).toDouble(),

      "missRate":
      (record["miss_rate_pct"] ?? 0).toDouble(),

      "effectiveness":
      (record["effectiveness_pct"] ?? 0).toDouble(),

      "p1":
      (record["p1"] ?? 0).toDouble(),

      "p0":
      (record["p0"] ?? 0).toDouble(),

      "pChance":
      (record["p_chance"] ?? 0).toDouble(),

      "kappa":
      (record["kappa_pct"] ?? 0).toDouble(),
    };

    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,

          leading: IconButton(
            tooltip: "Back",
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF263238),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),

          titleSpacing: 8,

          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "ARR Observation Report",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202124),
                ),
              ),

              SizedBox(height: 2),

              Text(
                "Attribute Repeatability & Reproducibility",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF7A8494),
                ),
              ),
            ],
          ),

          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: PopupMenuButton<String>(
                tooltip: "Report options",

                offset: const Offset(0, 48),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),

                color: Colors.white,

                onSelected: (value) async {
                  try {
                    if (value == "print") {
                      await PdfService.printReport(
                        record: arrRecord!,
                        observations: observations,
                      );
                    }

                    if (value == "download") {
                      if (!context.mounted) return;

                      await PdfService.downloadReport(
                        context: context,
                        record: arrRecord!,
                        observations: observations,
                      );
                    }

                    if (value == "share") {
                      await PdfService.shareReport(
                        record: arrRecord!,
                        observations: observations,
                      );
                    }
                  } catch (e) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Unable to complete this action: $e",
                        ),
                        backgroundColor:
                        const Color(0xFFC62828),
                      ),
                    );
                  }
                },

                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: "print",
                    child: Row(
                      children: [
                        Icon(
                          Icons.print_outlined,
                          size: 20,
                          color: Color(0xFF4E5663),
                        ),

                        SizedBox(width: 12),

                        Text(
                          "Print Report",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF202124),
                          ),
                        ),
                      ],
                    ),
                  ),

                  PopupMenuItem<String>(
                    value: "download",
                    child: Row(
                      children: [
                        Icon(
                          Icons.download_outlined,
                          size: 20,
                          color: Color(0xFF4E5663),
                        ),

                        SizedBox(width: 12),

                        Text(
                          "Download PDF",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF202124),
                          ),
                        ),
                      ],
                    ),
                  ),

                  PopupMenuItem<String>(
                    value: "share",
                    child: Row(
                      children: [
                        Icon(
                          Icons.share_outlined,
                          size: 20,
                          color: Color(0xFF4E5663),
                        ),

                        SizedBox(width: 12),

                        Text(
                          "Share Report",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF202124),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                child: Container(
                  width: 42,
                  height: 42,

                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE1E5EA),
                    ),
                  ),

                  child: const Icon(
                    Icons.menu_rounded,
                    size: 22,
                    color: Color(0xFF4E5663),
                  ),
                ),
              ),
            ),
          ],
        ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            const Text(
              "TRAIL OBSERVATION REPORT",

              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),


          const SizedBox(height: 25),

            Container(
              width: double.infinity,

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFE2E7EF),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),

              padding: const EdgeInsets.all(22),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  // SECTION HEADER
                  Row(
                    children: [

                      Container(
                        width: 42,
                        height: 42,

                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF3FF),
                          borderRadius: BorderRadius.circular(10),
                        ),

                        child: const Icon(
                          Icons.assignment_ind_outlined,
                          size: 22,
                          color: Color(0xFF3155C6),
                        ),
                      ),

                      const SizedBox(width: 12),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [

                            Text(
                              "Assessment Details",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF202124),
                              ),
                            ),

                            SizedBox(height: 3),

                            Text(
                              "Candidate and inspection information",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7A8494),
                              ),
                            ),

                          ],
                        ),
                      ),

                      // CERTIFICATE BADGE
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),

                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFE1E5EA),
                          ),
                        ),

                        child: Text(
                          record['certificate_number']
                              ?.toString() ??
                              "No Certificate",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4E5663),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  Container(
                    height: 1,
                    color: const Color(0xFFE9EDF2),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      // CANDIDATE PHOTO
                      Container(
                        width: 108,
                        height: 128,

                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFDDE3EB),
                          ),
                        ),

                        clipBehavior: Clip.antiAlias,

                        child: AppData.candidatePhoto == null
                            ? const Icon(
                          Icons.person_outline_rounded,
                          size: 48,
                          color: Color(0xFF9AA4B2),
                        )
                            : Image.memory(
                          AppData.candidatePhoto!,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(width: 24),

                      // INFORMATION
                      Expanded(
                        child: Column(
                          children: [

                            Row(
                              children: [

                                Expanded(
                                  child: _desktopInfoItem(
                                    "Candidate",
                                    employee?['full_name']
                                        ?.toString() ??
                                        "Not available",
                                    Icons.person_outline_rounded,
                                  ),
                                ),

                                const SizedBox(width: 18),

                                Expanded(
                                  child: _desktopInfoItem(
                                    "Employee Code",
                                    record['employee_code_snap']
                                        ?.toString() ??
                                        "Not available",
                                    Icons.badge_outlined,
                                  ),
                                ),

                                const SizedBox(width: 18),

                                Expanded(
                                  child: _desktopInfoItem(
                                    "Department",
                                    employee?['department']
                                        ?.toString() ??
                                        "Not available",
                                    Icons.business_outlined,
                                  ),
                                ),

                              ],
                            ),

                            const SizedBox(height: 18),

                            Row(
                              children: [

                                Expanded(
                                  child: _desktopInfoItem(
                                    "Product",
                                    record['product']
                                        ?.toString() ??
                                        "Not available",
                                    Icons.precision_manufacturing_outlined,
                                  ),
                                ),

                                const SizedBox(width: 18),

                                Expanded(
                                  child: _desktopInfoItem(
                                    "Batch",
                                    record['batch_name_snap']
                                        ?.toString() ??
                                        "Not available",
                                    Icons.inventory_2_outlined,
                                  ),
                                ),

                                const SizedBox(width: 18),

                                Expanded(
                                  child: _desktopInfoItem(
                                    "Certificate",
                                    record['certificate_number']
                                        ?.toString() ??
                                        "Not available",
                                    Icons.verified_outlined,
                                  ),
                                ),

                              ],
                            ),

                          ],
                        ),
                      ),

                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 25),

            Container(
              width: double.infinity,

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                BorderRadius.circular(14),

                border: Border.all(
                  color: const Color(0xFFE2E7EF),
                ),

                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),

              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    // SECTION HEADER
                    Row(
                      children: [

                        Container(
                          width: 42,
                          height: 42,

                          decoration: BoxDecoration(
                            color:
                            const Color(0xFFEEF3FF),

                            borderRadius:
                            BorderRadius.circular(10),
                          ),

                          child: const Icon(
                            Icons.table_chart_outlined,
                            size: 22,
                            color: Color(0xFF3155C6),
                          ),
                        ),

                        const SizedBox(width: 12),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,

                            children: [

                              Text(
                                "Observation Results",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                  FontWeight.w700,
                                  color:
                                  Color(0xFF202124),
                                ),
                              ),

                              SizedBox(height: 3),

                              Text(
                                "Comparison of trial observations against the master status",
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                  Color(0xFF7A8494),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),

                          decoration: BoxDecoration(
                            color:
                            const Color(0xFFF5F7FA),

                            borderRadius:
                            BorderRadius.circular(8),

                            border: Border.all(
                              color:
                              const Color(0xFFE1E5EA),
                            ),
                          ),

                          child: Text(
                            "${observations.length} Parts",

                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight:
                              FontWeight.w600,
                              color:
                              Color(0xFF596273),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Container(
                      height: 1,
                      color: const Color(0xFFE9EDF2),
                    ),

                    const SizedBox(height: 16),

                    // TABLE
                    ClipRRect(
                      borderRadius:
                      BorderRadius.circular(10),

                      child: Table(
                        border: TableBorder(
                          horizontalInside:
                          const BorderSide(
                            color:
                            Color(0xFFE7EBF0),
                          ),

                          verticalInside:
                          const BorderSide(
                            color:
                            Color(0xFFE7EBF0),
                          ),

                          top: const BorderSide(
                            color:
                            Color(0xFFE1E5EA),
                          ),

                          bottom: const BorderSide(
                            color:
                            Color(0xFFE1E5EA),
                          ),

                          left: const BorderSide(
                            color:
                            Color(0xFFE1E5EA),
                          ),

                          right: const BorderSide(
                            color:
                            Color(0xFFE1E5EA),
                          ),
                        ),

                        columnWidths: const {

                          0: FlexColumnWidth(2.2),

                          1: FlexColumnWidth(1),

                          2: FlexColumnWidth(1),

                          3: FlexColumnWidth(1),

                          4: FlexColumnWidth(1),
                        },

                        children: [

                          // HEADER
                          const TableRow(
                            decoration: BoxDecoration(
                              color:
                              Color(0xFFF4F6F9),
                            ),

                            children: [

                              tableCell(
                                "Part No",
                                true,
                              ),

                              tableCell(
                                "Trial 1",
                                true,
                              ),

                              tableCell(
                                "Trial 2",
                                true,
                              ),

                              tableCell(
                                "Trial 3",
                                true,
                              ),

                              tableCell(
                                "Master",
                                true,
                              ),
                            ],
                          ),

                          // DATA FROM SUPABASE
                          ...List.generate(
                            observations.length,
                                (index) {

                              final observation =
                              observations[index];

                              final partNumber =
                                  observation[
                                  "part_number_snap"]
                                      ?.toString() ??
                                      "-";

                              final master =
                                  observation[
                                  "master_status_snapshot"]
                                      ?.toString() ??
                                      "-";

                              final trail1 =
                                  observation["trail1"]
                                      ?.toString() ??
                                      "-";

                              final trail2 =
                                  observation["trail2"]
                                      ?.toString() ??
                                      "-";

                              final trail3 =
                                  observation["trail3"]
                                      ?.toString() ??
                                      "-";

                              final masterValue =
                              int.tryParse(master);

                              final trail1Value =
                              int.tryParse(trail1);

                              final trail2Value =
                              int.tryParse(trail2);

                              final trail3Value =
                              int.tryParse(trail3);

                              return TableRow(
                                decoration:
                                BoxDecoration(
                                  color: index.isEven
                                      ? Colors.white
                                      : const Color(
                                    0xFFFAFBFC,
                                  ),
                                ),

                                children: [

                                  tableCell(
                                    partNumber,
                                    false,
                                  ),

                                  tableCell(
                                    trail1,
                                    false,

                                    wrong:
                                    trail1Value != null &&
                                        masterValue != null &&
                                        trail1Value !=
                                            masterValue,
                                  ),

                                  tableCell(
                                    trail2,
                                    false,

                                    wrong:
                                    trail2Value != null &&
                                        masterValue != null &&
                                        trail2Value !=
                                            masterValue,
                                  ),

                                  tableCell(
                                    trail3,
                                    false,

                                    wrong:
                                    trail3Value != null &&
                                        masterValue != null &&
                                        trail3Value !=
                                            masterValue,
                                  ),

                                  tableCell(
                                    master,
                                    false,
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      //       const SizedBox(height: 30),
      // Card(
      //   elevation: 5,
      //   child: Padding(
      //     padding: const EdgeInsets.all(20),
      //     child: Column(
      //       children: [
      //         const Text(
      //           "Evaluation Metrics",
      //           style: TextStyle(
      //             fontSize: 22,
      //             fontWeight: FontWeight.bold,
      //           ),
      //         ),
      //
      //         const Divider(),
      //
      //         reportRow(
      //           "False Alert Count",
      //           resultData["falseAlert"].toString(),
      //         ),
      //
      //         reportRow(
      //           "Miss Alert Count",
      //           resultData["missAlert"].toString(),
      //         ),
      //
      //         reportRow(
      //           "False Alert %",
      //           resultData["falseAlertPercent"]
      //               .toStringAsFixed(2),
      //         ),
      //
      //         reportRow(
      //           "Miss Rate %",
      //           resultData["missRate"]
      //               .toStringAsFixed(2),
      //         ),
      //
      //         reportRow(
      //           "Effectiveness %",
      //           resultData["effectiveness"]
      //               .toStringAsFixed(2),
      //         ),
      //
      //         reportRow(
      //           "P1",
      //           resultData["p1"]
      //               .toStringAsFixed(3),
      //         ),
      //
      //         reportRow(
      //           "P0",
      //           resultData["p0"]
      //               .toStringAsFixed(3),
      //         ),
      //
      //         reportRow(
      //           "PChance",
      //           resultData["pChance"]
      //               .toStringAsFixed(3),
      //         ),
      //
      //         reportRow(
      //           "Kappa %",
      //           resultData["kappa"]
      //               .toStringAsFixed(2),
      //         ),
      //       ],
      //     ),
      //   ),
      // ),
            const SizedBox(height: 30),

            Container(
              width: double.infinity,

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFE2E7EF),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),

              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  // SECTION HEADER
                  Row(
                    children: [

                      Container(
                        width: 42,
                        height: 42,

                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF3FF),
                          borderRadius:
                          BorderRadius.circular(10),
                        ),

                        child: const Icon(
                          Icons.analytics_outlined,
                          size: 22,
                          color: Color(0xFF3155C6),
                        ),
                      ),

                      const SizedBox(width: 12),

                      const Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [

                          Text(
                            "Evaluation Metrics",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                              FontWeight.w700,
                              color:
                              Color(0xFF202124),
                            ),
                          ),

                          SizedBox(height: 3),

                          Text(
                            "Statistical results of the assessment",
                            style: TextStyle(
                              fontSize: 12,
                              color:
                              Color(0xFF7A8494),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // PRIMARY METRICS
                  Row(
                    children: [

                      Expanded(
                        child: _metricCard(
                          "Effectiveness",
                          "${(resultData["effectiveness"] ?? 0.0).toDouble().toStringAsFixed(2)}%",
                          Icons.speed_outlined,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: _metricCard(
                          "False Alert",
                          "${(resultData["falseAlertPercent"] ?? 0.0).toDouble().toStringAsFixed(2)}%",
                          Icons.warning_outlined,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: _metricCard(
                          "Miss Rate",
                          "${(resultData["missRate"] ?? 0.0).toDouble().toStringAsFixed(2)}%",
                          Icons.error_outline,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: _metricCard(
                          "Kappa",
                          "${(resultData["kappa"] ?? 0.0).toDouble().toStringAsFixed(2)}%",
                          Icons.assessment_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // TECHNICAL METRICS
                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 15,
                    ),

                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFE6EAF0),
                      ),
                    ),

                    child: Row(
                      children: [

                        const SizedBox(
                          width: 125,
                          child: Text(
                            "Technical Metrics",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF596273),
                            ),
                          ),
                        ),

                        Expanded(
                          child: _technicalMetric(
                            "False Alert Count",
                            "${resultData["falseAlert"] ?? 0}",
                          ),
                        ),

                        Expanded(
                          child: _technicalMetric(
                            "Miss Alert Count",
                            "${resultData["missAlert"] ?? 0}",
                          ),
                        ),

                        Expanded(
                          child: _technicalMetric(
                            "P1",
                            (resultData["p1"] ?? 0.0)
                                .toDouble()
                                .toStringAsFixed(3),
                          ),
                        ),

                        Expanded(
                          child: _technicalMetric(
                            "P0",
                            (resultData["p0"] ?? 0.0)
                                .toDouble()
                                .toStringAsFixed(3),
                          ),
                        ),

                        Expanded(
                          child: _technicalMetric(
                            "P Chance",
                            (resultData["pChance"] ?? 0.0)
                                .toDouble()
                                .toStringAsFixed(3),
                          ),
                        ),
                      ],
                    ),
                  ),

// CLOSE Evaluation Metrics Column
                ],
              ),

// CLOSE Evaluation Metrics Container
            ),

            const SizedBox(height: 30),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

                  // SECTION HEADER
                  Row(
                    children: [


                    ],
                  ),

                  const SizedBox(height: 22),

                  Center(
                    child: Container(
                      width: 560,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE2E7EF),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),

                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          const Text(
                            "Assessment Outcome",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF202124),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 10,
                            ),

                            decoration: BoxDecoration(
                              color: resultData["classification"] ==
                                  "ACCEPTABLE"
                                  ? const Color(0xFFEAF7EE)
                                  : resultData["classification"] ==
                                  "MARGINALLY ACCEPTABLE"
                                  ? const Color(0xFFFFF6DF)
                                  : const Color(0xFFFFEEEE),

                              borderRadius: BorderRadius.circular(8),
                            ),

                            child: Text(
                              resultData["classification"],
                              textAlign: TextAlign.center,

                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,

                                color: resultData["classification"] ==
                                    "ACCEPTABLE"
                                    ? const Color(0xFF237A3B)
                                    : resultData["classification"] ==
                                    "MARGINALLY ACCEPTABLE"
                                    ? const Color(0xFF996C00)
                                    : const Color(0xFFC62828),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            resultData["classification"] ==
                                "ACCEPTABLE"
                                ? "Assessment meets the required criteria."
                                : resultData["classification"] ==
                                "MARGINALLY ACCEPTABLE"
                                ? "Assessment is within the marginal acceptance range and requires review."
                                : "Assessment does not meet the required acceptance criteria.",

                            textAlign: TextAlign.center,

                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7A8494),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
            Center(
              child: SizedBox(
                width: 280,
                height: 50,

                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.workspace_premium_outlined,
                    size: 21,
                  ),

                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      "/ARR/certificate",
                    );
                  },

                  label: const Text(
                    "Generate Certificate",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF3155C6),

                    foregroundColor:
                    Colors.white,

                    elevation: 0,

                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
          ],
        ),
      ),
    );
  }
  Widget _resultMetric(
      String title,
      String value,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),

      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),

        borderRadius:
        BorderRadius.circular(9),

        border: Border.all(
          color: const Color(0xFFE6EAF0),
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Text(
            title,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7A8494),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF202124),
            ),
          ),
        ],
      ),
    );
  }
  Widget _metricCard(
      String title,
      String value,
      IconData icon,
      ) {
    return Container(
      height: 108,

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),

        borderRadius:
        BorderRadius.circular(11),

        border: Border.all(
          color: const Color(0xFFE3E7ED),
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Row(
            children: [

              Icon(
                icon,
                size: 18,
                color: const Color(0xFF3155C6),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight:
                    FontWeight.w600,
                    color:
                    Color(0xFF7A8494),
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF202124),
            ),
          ),
        ],
      ),
    );
  }

  Widget _technicalMetric(
      String title,
      String value,
      ) {
    return Row(
      children: [

        Text(
          "$title:",
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7A8494),
          ),
        ),

        const SizedBox(width: 7),

        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF202124),
          ),
        ),
      ],
    );
  }
  Widget _desktopInfoItem(
      String title,
      String value,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),

      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFE6EAF0),
        ),
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            size: 18,
            color: const Color(0xFF3155C6),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7A8494),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value.isEmpty ? "Not available" : value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF202124),
                  ),
                ),

              ],
            ),
          ),
        ],
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
  final bool wrong;

  const tableCell(
      this.text,
      this.heading, {
        this.wrong = false,
        super.key,
      });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: heading || wrong
              ? FontWeight.bold
              : FontWeight.normal,
          color: wrong ? Colors.red : Colors.black,
        ),
      ),
    );
  }
}