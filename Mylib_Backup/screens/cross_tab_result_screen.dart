import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/arr_record.dart';
import '../models/cross_tab_result.dart';
import '../services/pdf_service.dart';
import 'combined_certificate_screen.dart';

class CrossTabResultScreen extends StatelessWidget {

  final CrossTabResult result;

  final List<ArrRecord> selectedRecords;

  const CrossTabResultScreen({
    super.key,
    required this.result,
    required this.selectedRecords,
  });

  static const Color borderColor = Color(0xffd7d7d7);

  static const Color headerColor = Color(0xfff4f4f4);

  static const Color wrongColor = Colors.red;

  static const double cellWidth = 58;

  static const double partWidth = 90;

  static const double masterWidth = 70;
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),

        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 72,

          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F2937),

          titleSpacing: 24,

          title: SizedBox(
            height: 72,

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,

              children: [

                Container(
                  width: 42,
                  height: 42,

                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(11),
                  ),

                  child: const Icon(
                    Icons.analytics_outlined,
                    size: 22,
                    color: Color(0xFF3155C6),
                  ),
                ),

                const SizedBox(width: 14),

                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(
                      "Cross Tab Report",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.25,
                        height: 1.1,
                        color: Color(0xFF202124),
                      ),
                    ),

                    SizedBox(height: 5),

                    Text(
                      "Attribute Repeatability & Reproducibility",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        height: 1.1,
                        color: Color(0xFF7A8494),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(
                right: 18,
                top: 10,
                bottom: 10,
              ),
              child: PopupMenuButton<String>(
                tooltip: "Report actions",
                offset: const Offset(0, 52),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),

                elevation: 8,
                color: Colors.white,

                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: const Color(0xFFE1E5EA),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.menu_rounded,
                      size: 23,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),

                onSelected: (value) {
                  _handleMenuSelection(
                    context,
                    value,
                  );
                },

                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: "download",
                    child: ListTile(
                      leading: Icon(
                        Icons.download_outlined,
                        color: Color(0xFF374151),
                      ),
                      title: Text("Download"),
                    ),
                  ),

                  PopupMenuItem(
                    value: "share",
                    child: ListTile(
                      leading: Icon(
                        Icons.share_outlined,
                        color: Color(0xFF374151),
                      ),
                      title: Text("Share"),
                    ),
                  ),

                  PopupMenuItem(
                    value: "print",
                    child: ListTile(
                      leading: Icon(
                        Icons.print_outlined,
                        color: Color(0xFF374151),
                      ),
                      title: Text("Print"),
                    ),
                  ),

                  PopupMenuDivider(),

                  PopupMenuItem(
                    value: "certificate",
                    child: ListTile(
                      leading: Icon(
                        Icons.workspace_premium_outlined,
                        color: Color(0xFF374151),
                      ),
                      title: Text("Combined Certificate"),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 18),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(58),

            child: Container(
              alignment: Alignment.centerLeft,

              padding: const EdgeInsets.symmetric(
                horizontal: 28,
              ),

              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFF1F3F5),
                  ),
                  bottom: BorderSide(
                    color: Color(0xFFE5E7EB),
                  ),
                ),
              ),

              child: TabBar(
                isScrollable: true,

                tabAlignment: TabAlignment.start,

                dividerColor: Colors.transparent,

                indicatorSize: TabBarIndicatorSize.label,

                indicatorWeight: 3,

                indicatorColor: const Color(0xFF4F46E5),

                labelColor: const Color(0xFF4F46E5),

                unselectedLabelColor:
                const Color(0xFF6B7280),

                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),

                unselectedLabelStyle:
                const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),

                tabs: const [
                  Tab(
                    icon: Icon(
                      Icons.input_outlined,
                      size: 18,
                    ),
                    text: "Data Entry",
                  ),

                  Tab(
                    icon: Icon(
                      Icons.calculate_outlined,
                      size: 18,
                    ),
                    text: "Calculations",
                  ),

                  Tab(
                    icon: Icon(
                      Icons.bar_chart_outlined,
                      size: 18,
                    ),
                    text: "Statistics",
                  ),

                  Tab(
                    icon: Icon(
                      Icons.grid_view_outlined,
                      size: 18,
                    ),
                    text: "Cross Tab",
                  ),

                  Tab(
                    icon: Icon(
                      Icons.summarize_outlined,
                      size: 18,
                    ),
                    text: "ARR Summary",
                  ),
                ],
              ),
            ),
          ),
        ),

        body: TabBarView(
          children: [
            _buildDataEntry(),
            _buildCalculations(),
            _buildStatistics(),
            _buildCrossTab(),
            _buildSummary(),
          ],
        ),
      ),
    );
  }
  void _handleMenuSelection(
      BuildContext context,
      String value,
      ) {

    switch (value) {

      case "download":

        PdfService.downloadCrossTabReport(

          context: context,

          result: result,

        );

        break;

      case "share":

        PdfService.shareCrossTabReport(

          result: result,

        );

        break;

      case "print":

        PdfService.printCrossTabReport(

          result: result,

        );

        break;

      case "certificate":

        Navigator.pushNamed(
          context,
          '/ARR/combinedCertificate',
          arguments: selectedRecords,
        );

        break;

    }

  }
  Widget cell({
    required String text,
    double width = cellWidth,
    double height = 42,
    bool header = false,
    bool bold = false,
    Color textColor = Colors.black,
  }) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,

      decoration: BoxDecoration(
        color: header
            ? const Color(0xFFF1F4FA)
            : Colors.white,

        border: Border(
          right: BorderSide(
            color: const Color(0xFFE1E4E8),
            width: 0.8,
          ),
          bottom: BorderSide(
            color: const Color(0xFFE1E4E8),
            width: 0.8,
          ),
        ),
      ),

      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 4,
      ),

      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,

        style: TextStyle(
          fontSize: header ? 11.5 : 11,
          fontWeight: bold || header
              ? FontWeight.w700
              : FontWeight.w500,
          color: header
              ? const Color(0xFF3155C6)
              : textColor,
          height: 1.2,
        ),
      ),
    );
  }
  Widget _buildDataEntry() {
    final dataEntry = result.dataEntry;

    if (dataEntry.isEmpty) {
      return const Center(
        child: Text(
          "No Data Available",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      );
    }

    final firstRow = dataEntry.first;

    final operators =
        firstRow.operatorTrials;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4FA),
              border: Border.all(
                color: const Color(0xFFD7D7D7),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "DATA ENTRY",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFE1E4E8),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Scrollbar(
                    thumbVisibility: true,
                    notificationPredicate:
                        (notification) =>
                    notification.depth == 1,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: _dataEntryContentWidth(),
                        child: Column(
                          children: [
                            _buildDataEntryGroupHeader(operators),
                            Table(
                              border: TableBorder.all(
                                color: const Color(0xFFE1E4E8),
                              ),
                              defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                              children: [

                                TableRow(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF8F9FB),
                                  ),
                                  children: [

                                    cell(
                                      text: "",
                                      width: partWidth,
                                      height: 38,
                                      header: true,
                                    ),

                                    cell(
                                      text: "",
                                      width: masterWidth,
                                      height: 38,
                                      header: true,
                                    ),

                                    ...operators.expand(
                                          (_) => [
                                        cell(
                                          text: "T1",
                                          width: cellWidth,
                                          height: 38,
                                          header: true,
                                          bold: true,
                                        ),
                                        cell(
                                          text: "T2",
                                          width: cellWidth,
                                          height: 38,
                                          header: true,
                                          bold: true,
                                        ),
                                        cell(
                                          text: "T3",
                                          width: cellWidth,
                                          height: 38,
                                          header: true,
                                          bold: true,
                                        ),
                                      ],
                                    ),

                                    cell(
                                      text: "",
                                      width: 80,
                                      height: 38,
                                      header: true,
                                    ),

                                    cell(
                                      text: "",
                                      width: 90,
                                      height: 38,
                                      header: true,
                                    ),
                                  ],
                                ),

                                ...result.dataEntry.map(
                                      (row) {
                                    final allSame = row.operatorTrials.isNotEmpty &&
                                        row.operatorTrials.every(
                                              (operator) =>
                                          operator.trial1 == operator.trial2 &&
                                              operator.trial2 == operator.trial3,
                                        );

                                    final allCorrect = row.operatorTrials.isNotEmpty &&
                                        row.operatorTrials.every(
                                              (operator) =>
                                          operator.trial1 == row.expert &&
                                              operator.trial2 == row.expert &&
                                              operator.trial3 == row.expert,
                                        );

                                    final fixedOperators = List.generate(
                                      operators.length,
                                          (index) {
                                        if (index < row.operatorTrials.length) {
                                          return row.operatorTrials[index];
                                        }
                                        return null;
                                      },
                                    );

                                    return TableRow(
                                      children: [

                                        cell(
                                          text: row.partNumber,
                                          width: partWidth,
                                          bold: true,
                                        ),

                                        cell(
                                          text: row.expert.toString(),
                                          width: masterWidth,
                                          bold: true,
                                        ),

                                        ...fixedOperators.expand(
                                              (operator) => [

                                            cell(
                                              text: operator == null
                                                  ? ""
                                                  : operator.trial1.toString(),
                                              width: cellWidth,
                                              textColor: operator == null
                                                  ? Colors.black
                                                  : operator.trial1 == row.expert
                                                  ? Colors.black
                                                  : wrongColor,
                                            ),

                                            cell(
                                              text: operator == null
                                                  ? ""
                                                  : operator.trial2.toString(),
                                              width: cellWidth,
                                              textColor: operator == null
                                                  ? Colors.black
                                                  : operator.trial2 == row.expert
                                                  ? Colors.black
                                                  : wrongColor,
                                            ),

                                            cell(
                                              text: operator == null
                                                  ? ""
                                                  : operator.trial3.toString(),
                                              width: cellWidth,
                                              textColor: operator == null
                                                  ? Colors.black
                                                  : operator.trial3 == row.expert
                                                  ? Colors.black
                                                  : wrongColor,
                                            ),
                                          ],
                                        ),

                                        cell(
                                          text: allSame ? "1" : "0",
                                          width: 80,
                                          bold: true,
                                          textColor:
                                          allSame ? Colors.green : wrongColor,
                                        ),

                                        cell(
                                          text: allCorrect ? "1" : "0",
                                          width: 90,
                                          bold: true,
                                          textColor:
                                          allCorrect ? Colors.green : wrongColor,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFE1E4E8),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildDataEntryFooter(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Operator name/employee-code group banner, rendered as a plain Row
  /// ABOVE the data Table (not as a TableRow) so that every TableRow in
  /// the Table below keeps an identical cell count (2 + 3*N + 2). Mixing
  /// a merged one-cell-per-operator row into the same Table as the
  /// T1/T2/T3 sub-header row would make the row lengths irregular and
  /// crash at runtime, so the grouping label lives outside the Table and
  /// is aligned to match the Table's column widths instead.
  Widget _buildDataEntryGroupHeader(List operators) {
    final contentWidth =
        _dataEntryContentWidth() + 24;

    return SizedBox(
      width: contentWidth,
      height: 40,
      child: ClipRect(
        child: Row(
          children: [
            SizedBox(
              width: partWidth,
              height: 40,
            ),

            SizedBox(
              width: masterWidth,
              height: 40,
            ),

            ...operators.map(
                  (operator) => Container(
                width: cellWidth * 3,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: headerColor,
                  border: Border.all(
                    color: borderColor,
                  ),
                ),
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 4,
                ),
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      operator.candidateName,
                      textAlign:
                      TextAlign.center,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),

                    Text(
                      operator.employeeCode,
                      textAlign:
                      TextAlign.center,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      const TextStyle(
                        fontSize: 10,
                        color:
                        Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              width: 80,
              height: 40,
            ),

            const SizedBox(
              width: 90,
              height: 40,
            ),
          ],
        ),
      ),
    );
  }
  double _dataEntryContentWidth() {

    final operatorCount =
        result.dataEntry.first.operatorTrials.length;

    return partWidth +
        masterWidth +
        (operatorCount * cellWidth * 3) +
        80 +
        90 +
        24;
  }

  Widget _buildDataEntryFooter() {

    final operators = result.dataEntry.first.operatorTrials;

    return SizedBox(

      width: _dataEntryContentWidth(),

      child: Padding(

        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            _footerOperatorRow(
              title: "% APPRAISER SCORE",
              operatorTrials: operators,
            ),

            const SizedBox(height: 8),

            _footerOperatorRow(
              title: "% SCORE VS. ATTRIBUTE",
              operatorTrials: operators,
            ),

            const SizedBox(height: 28),

            _footerSingleRow(
              title: "SCREEN % EFFECTIVE SCORE",
            ),

            const SizedBox(height: 8),

            _footerSingleRow(
              title: "SCREEN % EFFECTIVE SCORE VS. ATTRIBUTE",
            ),

            const SizedBox(height: 8),

            _footerSingleRow(
              title: "ATTRIBUTE INSPECTION ACCURACY %",
              titleColor: Colors.amber,
            ),

          ],

        ),

      ),

    );

  }
  Widget _footerOperatorRow({

    required String title,

    required List operatorTrials,

  }) {

    late final List values;

    switch (title) {
      case "% APPRAISER SCORE":
        values = result.statisticalReport["appraiserScores"] as List;
        break;

      case "% SCORE VS. ATTRIBUTE":
        values = result.statisticalReport["attributeScores"] as List;
        break;

      case "SCREEN % EFFECTIVE SCORE":
        values = result.statisticalReport["screenEffectiveScores"] as List;
        break;

      case "SCREEN % EFFECTIVE SCORE VS. ATTRIBUTE":
        values = result.statisticalReport["screenEffectiveScoresVsAttribute"] as List;
        break;

      default:
        values = List.filled(operatorTrials.length, 0.0);
    }

    return Padding(

      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),

      child: Row(

        children: [

          SizedBox(

            width: partWidth + masterWidth,

            child: Text(

              title,

              style: const TextStyle(

                fontWeight: FontWeight.bold,

                fontSize: 18,

              ),

            ),

          ),

          ...List.generate(

            operatorTrials.length,

                (index) => SizedBox(

              width: cellWidth * 3,

              child: Center(

                child: Text(

                  "${(values[index] as num).toStringAsFixed(2)}%",

                  style: const TextStyle(

                    fontWeight: FontWeight.bold,

                    fontSize: 17,

                  ),

                ),

              ),

            ),

          ),

        ],

      ),

    );

  }

  Widget _footerSingleRow({

    required String title,

    Color titleColor = Colors.black,

  }) {

    double value = 0;

    switch (title) {

      case "SCREEN % EFFECTIVE SCORE":
        value =
            ((result.statisticalReport["effectiveScore"]["score"] as num)
                .toDouble()) *
                100;
        break;

      case "SCREEN % EFFECTIVE SCORE VS. ATTRIBUTE":
        value =
            (result.statisticalReport["effectiveScoreVsAttribute"]["score"]
            as num)
                .toDouble();
        break;

      case "ATTRIBUTE INSPECTION ACCURACY %":
        value =
            ((result.statisticalReport["attributeInspectionAccuracy"]["score"]
            as num)
                .toDouble()) *
                100;
        break;
    }

    return SizedBox(

      width: _dataEntryContentWidth(),

      child: Row(

        children: [

          const Spacer(),

          Text(

            title,

            style: TextStyle(

              color: titleColor,

              fontWeight: FontWeight.bold,

              fontSize: 18,

            ),

          ),

          const SizedBox(width: 12),

          Text(

            "${value.toStringAsFixed(2)}%",

            style: const TextStyle(

              fontWeight: FontWeight.bold,

              fontSize: 18,

            ),

          ),

        ],

      ),

    );

  }
  Widget _buildCalculations() {

    if (result.calculations.isEmpty) {
      return const Center(
        child: Text("No Calculation Data"),
      );
    }

    return SingleChildScrollView(

      scrollDirection: Axis.horizontal,

      child: SizedBox(

        width: _calculationContentWidth(),

        child: SingleChildScrollView(

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              _buildCalculationHeader(),

              ...result.calculations.map(
                    (row) => _buildCalculationRow(row),
              ),

              const SizedBox(height: 25),

              _buildCalculationFooter(),

              const SizedBox(height: 30),

            ],

          ),

        ),

      ),

    );

  }
  double _calculationContentWidth() {

    final operatorCount =
        result.calculations.first.operators.length;

    return 75 +
        70 +
        (operatorCount * cellWidth * 7) +
        90 +
        100;

  }
  Widget _buildCalculationFooter() {

    final operators =
        result.calculations.first.operators;

    return SizedBox(

      width: _calculationContentWidth(),

      child: Padding(

        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),

        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            _calculationFooterRow(
              "Appraiser Score",
              operators,
              "",
            ),

            _calculationFooterRow(
              "Samples",
              operators,
              result.statisticalReport["sampleCount"].toString(),
            ),

            _calculationFooterRow(
              "Ops*Tries",
              operators,
              result.statisticalReport["opsTries"].toString(),
            ),

            _calculationFooterRow(
              "Defects",
              operators,
              result.statisticalReport["defects"].toString(),
            ),

            const SizedBox(height: 18),

            Row(

              children: [

                const Spacer(),

                const SizedBox(
                  width: 90,
                  child: Center(
                    child: Text("--"),
                  ),
                ),

                const SizedBox(
                  width: 100,
                  child: Center(
                    child: Text("--"),
                  ),
                ),

              ],

            ),

          ],

        ),

      ),

    );

  }
  Widget _calculationFooterRow(

      String title,

      List operators,

      String value,

      ) {

    return Padding(

      padding: const EdgeInsets.symmetric(
        vertical: 3,
      ),

      child: Row(

        children: [

          SizedBox(

            width: 145,

            child: Text(

              title,

              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),

            ),

          ),

          ...List.generate(

            operators.length,

                (index) => SizedBox(

              width: cellWidth * 7,

              child: Center(

                child: Text(
                  title == "Appraiser Score"
                      ? "${(result.statisticalReport["appraiserScores"][index] as num).toStringAsFixed(2)}%"
                      : value.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),

                ),

              ),

            ),

          ),

        ],

      ),

    );

  }
  Widget _buildCalculationHeader() {

    final operators =
        result.calculations.first.operators;

    return Row(

      children: [

        cell(
          text: "Sample",
          width: 75,
          header: true,
          bold: true,
          height: 60,
        ),

        cell(
          text: "Expert",
          width: 70,
          header: true,
          bold: true,
          height: 60,
        ),

        ...operators.map(

              (op) => Container(

            width: cellWidth * 7,

            height: 60,

            decoration: BoxDecoration(

              color: headerColor,

              border: Border.all(
                color: borderColor,
              ),

            ),

            child: Column(

              mainAxisAlignment:
              MainAxisAlignment.center,

              children: [

                Text(

                  op.candidateName,

                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),

                ),

                Text(
                  op.employeeCode,
                  style: const TextStyle(
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 4),

                const Row(

                  children: [

                    Expanded(child: Center(child: Text("T1"))),

                    Expanded(child: Center(child: Text("T2"))),

                    Expanded(child: Center(child: Text("T3"))),

                    Expanded(child: Center(child: Text("Same"))),

                    Expanded(child: Center(child: Text("Correct"))),

                    Expanded(child: Center(child: Text("OverKill"))),

                    Expanded(child: Center(child: Text("Escape"))),

                  ],

                ),

              ],

            ),

          ),

        ),

        cell(
          text: "All Same",
          width: 90,
          header: true,
          bold: true,
          height: 60,
        ),

        cell(
          text: "All Correct",
          width: 100,
          header: true,
          bold: true,
          height: 60,
        ),

      ],

    );

  }
  Widget _buildCalculationRow(
      CalculationRow row,
      ) {

    final allSame =
    row.operators.every(
          (e) => e.same == 1,
    );

    final allCorrect =
    row.operators.every(
          (e) => e.correct == 1,
    );

    return Row(

      children: [

        cell(
          text: row.sampleNo.toString(),
          width: 75,
          bold: true,
        ),

        cell(
          text: row.expert,
          width: 70,
          bold: true,
        ),

        ...row.operators.expand(

              (op) => [

            cell(text: op.trial1),

            cell(text: op.trial2),

            cell(text: op.trial3),

            cell(
              text: op.same.toString(),
              textColor:
              op.same == 1
                  ? Colors.green
                  : Colors.red,
            ),

            cell(
              text: op.correct.toString(),
              textColor:
              op.correct == 1
                  ? Colors.green
                  : Colors.red,
            ),

            cell(
              text: op.overkill.toString(),
              textColor:
              op.overkill > 0
                  ? Colors.red
                  : Colors.black,
            ),

            cell(
              text: op.escape.toString(),
              textColor:
              op.escape > 0
                  ? Colors.red
                  : Colors.black,
            ),

          ],

        ),

        cell(
          text: allSame ? "1" : "0",
          width: 90,
          bold: true,
          textColor:
          allSame
              ? Colors.green
              : Colors.red,
        ),

        cell(
          text: allCorrect ? "1" : "0",
          width: 100,
          bold: true,
          textColor:
          allCorrect
              ? Colors.green
              : Colors.red,
        ),

      ],

    );

  }

  Widget _buildStatistics() {

    if (result.dataEntry.isEmpty) {
      return const Center(
        child: Text(
          "No Data Available",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      );
    }

    return SingleChildScrollView(

      padding: const EdgeInsets.all(16),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          _buildAppraiserStatistics(),

          const SizedBox(height: 30),

          _buildScoreVsAttribute(),

          const SizedBox(height: 30),

          _buildEffectiveScore(),

          const SizedBox(height: 30),

          _buildEffectiveScoreVsAttribute(),

          const SizedBox(height: 30),

          _buildInspectionAccuracy(),

        ],

      ),

    );

  }

  Widget _statTitle(String title) {

    return Container(

      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),

      color: Colors.grey.shade300,

      child: Text(

        title,

        textAlign: TextAlign.center,

        style: const TextStyle(

          fontWeight: FontWeight.bold,

          fontSize: 15,

        ),

      ),

    );

  }
  Widget _statisticsTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    const primaryColor = Color(0xFF3155C6);
    const borderColor = Color(0xFFE1E4E8);
    const headerBackground = Color(0xFFF1F4FA);
    const alternateBackground = Color(0xFFFAFBFC);
    const textColor = Color(0xFF374151);
    const mutedColor = Color(0xFF6B7280);

    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),

      clipBehavior: Clip.antiAlias,

      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,

        child: DataTable(
          horizontalMargin: 16,
          columnSpacing: 28,

          headingRowHeight: 58,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 58,

          dividerThickness: 0.8,

          headingRowColor:
          WidgetStateProperty.all(
            headerBackground,
          ),

          dataRowColor:
          WidgetStateProperty.resolveWith(
                (states) {
              final index =
              states.contains(
                WidgetState.selected,
              );

              return null;
            },
          ),

          border: TableBorder(
            top: BorderSide(
              color: borderColor,
            ),
            bottom: BorderSide(
              color: borderColor,
            ),
            horizontalInside: BorderSide(
              color: borderColor,
              width: 0.7,
            ),
          ),

          columns: List.generate(
            headers.length,
                (index) {
              final header = headers[index];

              return DataColumn(
                label: SizedBox(
                  width: index == 0 ? 155 : 110,

                  child: Text(
                    header,
                    textAlign: TextAlign.center,

                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,

                      color: index == 0
                          ? textColor
                          : primaryColor,

                      height: 1.25,
                    ),
                  ),
                ),
              );
            },
          ),

          rows: List.generate(
            rows.length,
                (rowIndex) {
              final row = rows[rowIndex];

              final parameter =
              row.isNotEmpty
                  ? row.first
                  : "";

              final isCalculated =
              parameter
                  .toLowerCase()
                  .contains(
                "calculated score",
              );

              final isTotal =
              parameter
                  .toLowerCase()
                  .contains(
                "total",
              );

              final isMatched =
              parameter
                  .toLowerCase()
                  .contains(
                "matched",
              );

              final isLimit =
                  parameter
                      .toLowerCase()
                      .contains("ucl") ||
                      parameter
                          .toLowerCase()
                          .contains("lcl");

              return DataRow(
                color:
                WidgetStateProperty.resolveWith(
                      (states) {
                    if (isCalculated) {
                      return const Color(
                        0xFFF0FDF4,
                      );
                    }

                    if (isTotal) {
                      return const Color(
                        0xFFF8FAFC,
                      );
                    }

                    if (rowIndex.isEven) {
                      return Colors.white;
                    }

                    return alternateBackground;
                  },
                ),

                cells: List.generate(
                  row.length,
                      (columnIndex) {
                    final value =
                    row[columnIndex];

                    final isFirstColumn =
                        columnIndex == 0;

                    Color valueColor =
                        textColor;

                    FontWeight weight =
                        FontWeight.w500;

                    if (isFirstColumn) {
                      weight =
                          FontWeight.w600;
                    }

                    if (isCalculated &&
                        !isFirstColumn) {
                      valueColor =
                      const Color(
                        0xFF15803D,
                      );

                      weight =
                          FontWeight.w700;
                    }

                    if (isMatched &&
                        !isFirstColumn) {
                      valueColor =
                          primaryColor;

                      weight =
                          FontWeight.w700;
                    }

                    if (isLimit &&
                        !isFirstColumn) {
                      valueColor =
                          mutedColor;

                      weight =
                          FontWeight.w600;
                    }

                    return DataCell(
                      SizedBox(
                        width:
                        isFirstColumn
                            ? 155
                            : 110,

                        child: Text(
                          value,

                          textAlign:
                          isFirstColumn
                              ? TextAlign
                              .left
                              : TextAlign
                              .center,

                          maxLines: 2,
                          overflow:
                          TextOverflow
                              .ellipsis,

                          style: TextStyle(
                            fontSize:
                            isFirstColumn
                                ? 11.5
                                : 11,

                            fontWeight:
                            weight,

                            color:
                            valueColor,

                            height: 1.25,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  Widget _statisticsStockChart({
    required String title,
    required List<double> scores,
    required List<double> ucl,
    required List<double> lcl,
  }) {
    final operators = result.dataEntry.first.operatorTrials;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE1E4E8),
        ),
      ),

      child: SizedBox(
        height: 330,

        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 110,

            minX: 0,
            maxX: (scores.length - 1)
                .toDouble()
                .clamp(0, double.infinity),

            gridData: FlGridData(
              show: true,
              horizontalInterval: 10,
              verticalInterval: 1,
            ),

            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: const Color(0xFFD1D5DB),
              ),
            ),

            titlesData: FlTitlesData(

              topTitles: const AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                ),
              ),

              rightTitles: const AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                ),
              ),

              leftTitles: AxisTitles(
                axisNameWidget: const Text(
                  "% Efficiency",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 10,
                  reservedSize: 42,

                  getTitlesWidget: (value, meta) {
                    return Text(
                      "${value.toInt()}",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6B7280),
                      ),
                    );
                  },
                ),
              ),

              bottomTitles: AxisTitles(
                axisNameWidget: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 42,

                  getTitlesWidget: (value, meta) {
                    if ((value - value.roundToDouble()).abs() >
                        1e-6) {
                      return const SizedBox();
                    }

                    final index = value.round();

                    if (index < 0 ||
                        index >= operators.length) {
                      return const SizedBox();
                    }

                    final name =
                        operators[index].candidateName;

                    return Padding(
                      padding:
                      const EdgeInsets.only(top: 6),

                      child: SizedBox(
                        width: 80,

                        child: Text(
                          name.isEmpty
                              ? "Operator"
                              : name,
                          maxLines: 2,
                          overflow:
                          TextOverflow.ellipsis,
                          textAlign: TextAlign.center,

                          style: const TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            lineBarsData: [

              LineChartBarData(
                spots: List.generate(
                  scores.length,
                      (i) => FlSpot(
                    i.toDouble(),
                    ucl[i],
                  ),
                ),

                isCurved: false,

                color: const Color(0xFFDD0806),

                barWidth: 2,

                dotData: const FlDotData(
                  show: true,
                ),
              ),

              LineChartBarData(
                spots: List.generate(
                  scores.length,
                      (i) => FlSpot(
                    i.toDouble(),
                    scores[i],
                  ),
                ),

                isCurved: false,

                color: const Color(0xFF1FB714),

                barWidth: 2,

                dotData: const FlDotData(
                  show: true,
                ),
              ),

              LineChartBarData(
                spots: List.generate(
                  scores.length,
                      (i) => FlSpot(
                    i.toDouble(),
                    lcl[i],
                  ),
                ),

                isCurved: false,

                color: const Color(0xFFDD0806),

                barWidth: 2,

                dashArray: [6, 4],

                dotData: const FlDotData(
                  show: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statisticsStockChartLegend() {
    Widget swatch(Color color, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          swatch(const Color(0xFFDD0806), "95% UCL / LCL"),
          swatch(const Color(0xFF1FB714), "Calculated Score"),
        ],
      ),
    );
  }
  Widget _buildAppraiserStatistics() {

    final headers = <String>[
      "Parameter",
    ];

    final first =
        result.dataEntry.first.operatorTrials;

    for (final op in first) {

      headers.add(
        "${op.candidateName}\n(${op.employeeCode})",
      );

    }

    final rows = <List<String>>[];

    rows.add([
      "Total Inspected",
      ...first.map((_) => result.dataEntry.length.toString()),
    ]);

    final operatorStats =
    result.statisticalReport["operators"] as List;

    rows.add([
      "# Matched",
      ...operatorStats.map(
              (e) => e["matched"].toString()),
    ]);

    rows.add([
      "95% UCL",
      ...operatorStats.map(
              (e) => "${((e["ucl95"] as num) * 100).toStringAsFixed(2)}%"),
    ]);

    rows.add([
      "Calculated Score",
      ...operatorStats.map(
            (e) =>
        "${(((e["calculatedScore"] ?? 0) as num).toDouble() * 100).toStringAsFixed(2)}%",
      ),
    ]);

    rows.add([
      "95% LCL",
      ...operatorStats.map(
              (e) => "${((e["lcl95"] as num) * 100).toStringAsFixed(2)}%"),
    ]);

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        _statTitle("% Appraiser"),

        const SizedBox(height: 10),

        _statisticsTable(
          headers: headers,
          rows: rows,
        ),

        const SizedBox(height: 20),

        _statisticsStockChart(
          title: "% Appraiser",
          scores: (result.statisticalReport["appraiserScores"] as List)
              .map((e) => (e as num).toDouble())
              .toList(),
          ucl: (result.statisticalReport["operators"] as List)
              .map((e) => ((e["ucl95"] as num).toDouble()) * 100)
              .toList(),
          lcl: (result.statisticalReport["operators"] as List)
              .map((e) => ((e["lcl95"] as num).toDouble()) * 100)
              .toList(),
        ),

        _statisticsStockChartLegend(),

      ],

    );

  }

  Widget _buildScoreVsAttribute() {

    final headers = <String>[
      "Parameter",
    ];

    final first =
        result.dataEntry.first.operatorTrials;

    for (final op in first) {

      headers.add(
        "${op.candidateName}\n(${op.employeeCode})",
      );

    }

    final rows = <List<String>>[];

    final operatorStats =
    result.statisticalReport["operators"] as List;
    rows.add([
      "Total Inspected",
      ...first.map((_) => result.dataEntry.length.toString()),
    ]);



    rows.add([
      "95% UCL",
      ...operatorStats.map(
              (e) =>
          "${((e["attributeUcl95"] as num) * 100).toStringAsFixed(2)}%"),
    ]);

    rows.add([
      "95% LCL",
      ...operatorStats.map(
              (e) =>
          "${((e["attributeLcl95"] as num) * 100).toStringAsFixed(2)}%"),
    ]);


    rows.add([
      "# Matched",
      ...operatorStats.map(
              (e) => e["matched"].toString()),
    ]);

    rows.add([
      "Calculated Score",
      ...operatorStats.map(
              (e) =>
          "${((result.statisticalReport["attributeScores"] as List)[operatorStats.indexOf(e)] as num).toStringAsFixed(2)}%"),
    ]);

    rows.add([
      "Escape / Miss Rate",
      ...operatorStats.map(
              (e) => e["escape"].toString()),
    ]);

    rows.add([
      "False Alarm Rate",
      ...operatorStats.map(
              (e) => e["overkill"].toString()),
    ]);
    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        _statTitle("% Score vs Attribute"),

        const SizedBox(height: 10),

        _statisticsTable(
          headers: headers,
          rows: rows,
        ),

        const SizedBox(height: 20),

        _statisticsStockChart(
          title: "% Score vs Attribute",
          scores: (result.statisticalReport["attributeScores"] as List)
              .map((e) => (e as num).toDouble())
              .toList(),
          ucl: (result.statisticalReport["operators"] as List)
              .map((e) => ((e["attributeUcl95"] as num).toDouble()) * 100)
              .toList(),
          lcl: (result.statisticalReport["operators"] as List)
              .map((e) => ((e["attributeLcl95"] as num).toDouble()) * 100)
              .toList(),
        ),

        _statisticsStockChartLegend(),

      ],

    );
  }

  Widget _buildEffectiveScore() {

    final headers = [
      "Parameter",
      "Value",
    ];

    final rows = <List<String>>[];

    rows.add([
      "Total Inspected",
      result.dataEntry.length.toString(),
    ]);

    rows.add([
      "# Agreement",
      result.statisticalReport["effectiveScore"]["yesCount"].toString(),
    ]);

    rows.add([
      "95% UCL",
      "${(((result.statisticalReport["effectiveScore"]["ucl95"] as num).toDouble()) * 100).toStringAsFixed(2)}%",
    ]);

    rows.add([
      "Calculated Score",
      "${(((result.statisticalReport["effectiveScore"]["score"] as num).toDouble()) * 100).toStringAsFixed(2)}%",
    ]);

    rows.add([
      "95% LCL",
      "${(((result.statisticalReport["effectiveScore"]["lcl95"] as num).toDouble()) * 100).toStringAsFixed(2)}%",
    ]);

    return Column(

      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [

        _statTitle("% Effective Score"),

        const SizedBox(height: 10),

        _statisticsTable(

          headers: headers,

          rows: rows,

        ),

      ],

    );

  }
  Widget _buildInspectionAccuracy() {

    final headers = [
      "Parameter",
      "Value",
    ];

    final rows = <List<String>>[];

    rows.add([
      "Total Opportunities",
      result.statisticalReport["attributeInspectionAccuracy"]["total"]
          .toString(),
    ]);

    rows.add([
      "# Accurate",
      result.statisticalReport["attributeInspectionAccuracy"]["correct"].toString(),
    ]);

    rows.add([
      "95% UCL",
      "${(((result.statisticalReport["attributeInspectionAccuracy"]["ucl95"] as num).toDouble()) * 100).toStringAsFixed(2)}%",
    ]);

    rows.add([
      "Calculated Score",
      "${(((result.statisticalReport["attributeInspectionAccuracy"]["score"] as num).toDouble()) * 100).toStringAsFixed(2)}%",
    ]);

    rows.add([
      "95% LCL",
      "${(((result.statisticalReport["attributeInspectionAccuracy"]["lcl95"] as num).toDouble()) * 100).toStringAsFixed(2)}%",
    ]);

    return Column(

      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [

        _statTitle(
          "Attribute Inspection Accuracy",
        ),

        const SizedBox(height: 10),

        _statisticsTable(

          headers: headers,

          rows: rows,

        ),

      ],

    );

  }

  Widget _buildEffectiveScoreVsAttribute() {

    final headers = [
      "Parameter",
      "Value",
    ];

    final rows = <List<String>>[];

    rows.add([
      "Total Inspected",
      result.dataEntry.length.toString(),
    ]);

    rows.add([
      "# Agreement",
      result.statisticalReport["effectiveScoreVsAttribute"]["yesCount"].toString(),
    ]);

    rows.add([
      "95% UCL",
      "${(((result.statisticalReport["effectiveScoreVsAttribute"]["ucl95"] as num).toDouble()) * 100).toStringAsFixed(2)}%",
    ]);

    rows.add([
      "Calculated Score",
      "${((result.statisticalReport["effectiveScoreVsAttribute"]["score"] ?? 0) as num).toStringAsFixed(2)}%",
    ]);

    rows.add([
      "95% LCL",
      "${(((result.statisticalReport["effectiveScoreVsAttribute"]["lcl95"] as num).toDouble()) * 100).toStringAsFixed(2)}%",
    ]);
    return Column(

      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [

        _statTitle(
          "% Effective Score vs Attribute",
        ),

        const SizedBox(height: 10),

        _statisticsTable(

          headers: headers,

          rows: rows,

        ),

      ],

    );

  }
  Widget _buildCrossTab() {

    final operators =
    result.crossTab["operators"] as List<Map<String, dynamic>>;

    if (operators.isEmpty) {
      return const Center(
        child: Text(
          "No Cross Tab Data Available",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFF7F8FA),

      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Container(
              width: double.infinity,

              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE1E4E8),
                ),
              ),

              child: Row(
                children: [

                  Container(
                    width: 42,
                    height: 42,

                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF0FF),
                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: const Icon(
                      Icons.grid_view_rounded,
                      size: 21,
                      color: Color(0xFF3155C6),
                    ),
                  ),

                  const SizedBox(width: 13),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          "Cross Tab Analysis",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF202124),
                          ),
                        ),

                        SizedBox(height: 3),

                        Text(
                          "Comparison of individual appraisers with the known standard.",
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF747B86),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),

                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F4FA),
                      borderRadius: BorderRadius.circular(8),
                    ),

                    child: Text(
                      "${operators.length} Appraisers",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3155C6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            ...List.generate(
              operators.length,
                  (index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index == operators.length - 1
                      ? 0
                      : 24,
                ),
                child: _buildCrossTabCard(
                  index,
                  operators[index],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildCrossTabCard(
      int index,
      Map<String, dynamic> operator,
      ) {

    final letter = String.fromCharCode(65 + index);

    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE1E4E8),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),

      clipBehavior: Clip.antiAlias,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // --------------------------------------------------
          // OPERATOR HEADER
          // --------------------------------------------------

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),

            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE1E4E8),
                ),
              ),
            ),

            child: Row(
              children: [

                Container(
                  width: 38,
                  height: 38,

                  alignment: Alignment.center,

                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(10),
                  ),

                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3155C6),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        operator["candidateName"]?.toString().isNotEmpty == true
                            ? operator["candidateName"].toString()
                            : "Appraiser $letter",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF202124),
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        operator["employeeCode"]?.toString() ?? "",
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF747B86),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),

                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4FA),
                    borderRadius: BorderRadius.circular(7),
                  ),

                  child: Text(
                    "${operator["total"] ?? 0} Samples",
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3155C6),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --------------------------------------------------
          // TWO INNER CARDS
          // --------------------------------------------------

          Padding(
            padding: const EdgeInsets.all(16),

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ------------------------------------------------
                // CROSSTABULATION CARD
                // ------------------------------------------------

                Expanded(
                  flex: 1,
                  child: _buildCrossMatrix(
                    index,
                    operator,
                  ),
                ),

                const SizedBox(width: 16),

                // ------------------------------------------------
                // KAPPA CARD
                // ------------------------------------------------

                Expanded(
                  flex: 1,
                  child: _buildKappaBox(
                    index,
                    operator,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _crossCell(
      String text, {
        bool bold = false,
        Alignment alignment = Alignment.center,
      }) {
    return Container(
      height: 24,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }

  // Widget _buildCrossMatrix(
  //     int index,
  //     Map<String, dynamic> operator,
  //     ) {
  //   final letter = String.fromCharCode(65 + index);
  //
  //   final pp = operator["PP"] as int;
  //   final pf = operator["FP"] as int;
  //   final fp = operator["PF"] as int;
  //   final ff = operator["FF"] as int;
  //   final total = operator["total"] as int;
  //   final rowPass = pp + pf;
  //   final rowFail = fp + ff;
  //
  //   final colPass = pp + fp;
  //   final colFail = pf + ff;
  //
  //   final double expPPVal = total == 0 ? 0 : (rowPass * colPass) / total;
  //   final double expPFVal = total == 0 ? 0 : (rowPass * colFail) / total;
  //   final double expFPVal = total == 0 ? 0 : (rowFail * colPass) / total;
  //   final double expFFVal = total == 0 ? 0 : (rowFail * colFail) / total;
  //
  //   final expPP = expPPVal.toStringAsFixed(2);
  //   final expPF = expPFVal.toStringAsFixed(2);
  //   final expFP = expFPVal.toStringAsFixed(2);
  //   final expFF = expFFVal.toStringAsFixed(2);
  //
  //   final double expColPassTotal = expPPVal + expFPVal;
  //   final double expColFailTotal = expPFVal + expFFVal;
  //   final double expGrandTotal = expColPassTotal + expColFailTotal;
  //
  //   Widget cell(
  //       String text, {
  //         bool bold = false,
  //         double height = 34,
  //       }) {
  //     return Container(
  //       alignment: Alignment.center,
  //       height: height,
  //       child: Text(
  //         text,
  //         style: TextStyle(
  //           fontWeight:
  //           bold ? FontWeight.bold : FontWeight.normal,
  //         ),
  //       ),
  //     );
  //   }
  //
  //   return SizedBox(
  //     width: 430,
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           "$letter to Expert Crosstabulation",
  //           style: const TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //
  //         const SizedBox(height: 10),
  //
  //         Table(
  //           border: TableBorder.all(),
  //           columnWidths: const {
  //             0: FixedColumnWidth(60),
  //             1: FixedColumnWidth(165),
  //             2: FixedColumnWidth(70),
  //             3: FixedColumnWidth(70),
  //             4: FixedColumnWidth(65),
  //           },
  //           children: [
  //
  //             TableRow(
  //               children: [
  //                 cell(""),
  //                 cell(""),
  //                 cell("Expert", bold: true),
  //                 cell(""),
  //                 cell("Total", bold: true),
  //               ],
  //             ),
  //
  //             TableRow(
  //               children: [
  //                 cell(""),
  //                 cell(""),
  //                 cell("Pass", bold: true),
  //                 cell("Fail", bold: true),
  //                 cell(""),
  //               ],
  //             ),
  //
  //             _crossRow(
  //               letter,
  //               "Pass",
  //               "$pp",
  //               "$pf",
  //               "$rowPass",
  //             ),
  //
  //             _crossRow(
  //               "",
  //               "Expected Count",
  //               expPP,
  //               expPF,
  //               rowPass.toString(),
  //             ),
  //
  //             _crossRow(
  //               "",
  //               "Fail",
  //               "$fp",
  //               "$ff",
  //               "$rowFail",
  //             ),
  //
  //             _crossRow(
  //               "",
  //               "Expected Count",
  //               expFP,
  //               expFF,
  //               rowFail.toString(),
  //             ),
  //
  //             _crossRow(
  //               "Total",
  //               "Count",
  //               "$colPass",
  //               "$colFail",
  //               "$total",
  //             ),
  //
  //             _crossRow(
  //               "",
  //               "Expected Count",
  //               expColPassTotal.toStringAsFixed(2),
  //               expColFailTotal.toStringAsFixed(2),
  //               expGrandTotal.toStringAsFixed(2),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }
  // TableRow _crossRow(
  //
  //     String c1,
  //
  //     String c2,
  //
  //     String c3,
  //
  //     String c4,
  //
  //     String c5,
  //
  //     ) {
  //
  //
  //   return TableRow(
  //
  //     children: [
  //
  //       _crossCell(c1),
  //
  //       _crossCell(c2),
  //
  //       _crossCell(c3),
  //
  //       _crossCell(c4),
  //
  //       _crossCell(c5),
  //
  //     ],
  //
  //   );
  //
  // }
  Widget _buildCrossMatrix(
      int index,
      Map<String, dynamic> operator,
      ) {

    final letter = String.fromCharCode(65 + index);

    final pp = operator["PP"] as int;
    final pf = operator["FP"] as int;
    final fp = operator["PF"] as int;
    final ff = operator["FF"] as int;
    final total = operator["total"] as int;

    final rowPass = pp + pf;
    final rowFail = fp + ff;

    final colPass = pp + fp;
    final colFail = pf + ff;

    final double expPPVal =
    total == 0 ? 0 : (rowPass * colPass) / total;

    final double expPFVal =
    total == 0 ? 0 : (rowPass * colFail) / total;

    final double expFPVal =
    total == 0 ? 0 : (rowFail * colPass) / total;

    final double expFFVal =
    total == 0 ? 0 : (rowFail * colFail) / total;

    final double expColPassTotal =
        expPPVal + expFPVal;

    final double expColFailTotal =
        expPFVal + expFFVal;

    final double expGrandTotal =
        expColPassTotal + expColFailTotal;

    String number(double value) {
      return value.toStringAsFixed(2);
    }

    Widget matrixCell(
        String text, {
          bool bold = false,
          Color? background,
          Color? textColor,
          Alignment alignment = Alignment.center,
          double height = 42,
        }) {
      return Container(
        height: height,
        alignment: alignment,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: background ?? Colors.white,
          border: Border.all(
            color: const Color(0xFFE1E4E8),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
            bold ? FontWeight.w700 : FontWeight.w500,
            color:
            textColor ?? const Color(0xFF374151),
          ),
        ),
      );
    }

    Widget sectionLabel(String text) {
      return Container(
        height: 36,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF7F8FB),
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFE1E4E8),
            ),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
          ),
        ),
      );
    }

    Widget dataRow({
      required String label,
      required String pass,
      required String fail,
      required String totalValue,
      bool expected = false,
      bool totalRow = false,
    }) {
      return Row(
        children: [

          SizedBox(
            width: 150,
            child: matrixCell(
              label,
              bold: !expected,
              background: expected
                  ? const Color(0xFFFAFBFC)
                  : Colors.white,
              textColor: expected
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF374151),
              alignment: Alignment.centerLeft,
            ),
          ),

          SizedBox(
            width: 82,
            child: matrixCell(
              pass,
              bold: totalRow,
              background: totalRow
                  ? const Color(0xFFF1F4FA)
                  : expected
                  ? const Color(0xFFFAFBFC)
                  : Colors.white,
            ),
          ),

          SizedBox(
            width: 82,
            child: matrixCell(
              fail,
              bold: totalRow,
              background: totalRow
                  ? const Color(0xFFF1F4FA)
                  : expected
                  ? const Color(0xFFFAFBFC)
                  : Colors.white,
            ),
          ),

          SizedBox(
            width: 82,
            child: matrixCell(
              totalValue,
              bold: true,
              background: totalRow
                  ? const Color(0xFFF1F4FA)
                  : expected
                  ? const Color(0xFFFAFBFC)
                  : Colors.white,
              textColor: totalRow
                  ? const Color(0xFF3155C6)
                  : const Color(0xFF374151),
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE1E4E8),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),

      clipBehavior: Clip.antiAlias,

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          // --------------------------------------------------
          // TABLE TITLE
          // --------------------------------------------------

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),

            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE1E4E8),
                ),
              ),
            ),

            child: Row(
              children: [

                Container(
                  width: 34,
                  height: 34,

                  alignment: Alignment.center,

                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FF),
                    borderRadius:
                    BorderRadius.circular(9),
                  ),

                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3155C6),
                    ),
                  ),
                ),

                const SizedBox(width: 11),

                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [

                      Text(
                        "Crosstabulation",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF202124),
                        ),
                      ),

                      SizedBox(height: 2),

                      Text(
                        "Appraiser compared with Expert",
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF747B86),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),

                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4FA),
                    borderRadius:
                    BorderRadius.circular(7),
                  ),

                  child: Text(
                    "$total Samples",
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3155C6),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --------------------------------------------------
          // COLUMN HEADER
          // --------------------------------------------------

          sectionLabel("Observed Count"),

          Row(
            children: [

              SizedBox(
                width: 150,
                child: matrixCell(
                  "Appraiser",
                  bold: true,
                  background:
                  const Color(0xFFF1F4FA),
                  textColor:
                  const Color(0xFF3155C6),
                ),
              ),

              SizedBox(
                width: 82,
                child: matrixCell(
                  "Expert\nPass",
                  bold: true,
                  background:
                  const Color(0xFFF1F4FA),
                  textColor:
                  const Color(0xFF3155C6),
                ),
              ),

              SizedBox(
                width: 82,
                child: matrixCell(
                  "Expert\nFail",
                  bold: true,
                  background:
                  const Color(0xFFF1F4FA),
                  textColor:
                  const Color(0xFF3155C6),
                ),
              ),

              SizedBox(
                width: 82,
                child: matrixCell(
                  "Total",
                  bold: true,
                  background:
                  const Color(0xFFF1F4FA),
                  textColor:
                  const Color(0xFF3155C6),
                ),
              ),
            ],
          ),

          // --------------------------------------------------
          // OBSERVED PASS
          // --------------------------------------------------

          dataRow(
            label: "Pass",
            pass: "$pp",
            fail: "$pf",
            totalValue: "$rowPass",
          ),

          // --------------------------------------------------
          // EXPECTED PASS
          // --------------------------------------------------

          dataRow(
            label: "Expected Count",
            pass: number(expPPVal),
            fail: number(expPFVal),
            totalValue: "$rowPass",
            expected: true,
          ),

          // --------------------------------------------------
          // OBSERVED FAIL
          // --------------------------------------------------

          dataRow(
            label: "Fail",
            pass: "$fp",
            fail: "$ff",
            totalValue: "$rowFail",
          ),

          // --------------------------------------------------
          // EXPECTED FAIL
          // --------------------------------------------------

          dataRow(
            label: "Expected Count",
            pass: number(expFPVal),
            fail: number(expFFVal),
            totalValue: "$rowFail",
            expected: true,
          ),

          // --------------------------------------------------
          // TOTAL
          // --------------------------------------------------

          const SizedBox(height: 6),

          dataRow(
            label: "Total Count",
            pass: "$colPass",
            fail: "$colFail",
            totalValue: "$total",
            totalRow: true,
          ),

          // --------------------------------------------------
          // EXPECTED TOTAL
          // --------------------------------------------------

          dataRow(
            label: "Expected Count",
            pass: number(expColPassTotal),
            fail: number(expColFailTotal),
            totalValue: number(expGrandTotal),
            expected: true,
          ),

          const SizedBox(height: 8),

          // --------------------------------------------------
          // LEGEND
          // --------------------------------------------------

          Padding(
            padding: const EdgeInsets.fromLTRB(
              14,
              4,
              14,
              14,
            ),

            child: Row(
              children: [

                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4FA),
                    borderRadius:
                    BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(width: 6),

                const Text(
                  "Observed / total values",
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF747B86),
                  ),
                ),

                const SizedBox(width: 16),

                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFBFC),
                    borderRadius:
                    BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(width: 6),

                const Text(
                  "Expected count",
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF747B86),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // Widget _buildKappaBox(
  //     int index,
  //     Map<String, dynamic> operator,
  //     ) {
  //   final title = String.fromCharCode(65 + index);
  //
  //   final map =
  //   (result.crossTab["operators"] as List<Map<String, dynamic>>)[index];
  //
  //   return Align(
  //     alignment: Alignment.centerLeft,
  //     child: Container(
  //       decoration: BoxDecoration(
  //         border: Border.all(),
  //       ),
  //       padding: const EdgeInsets.all(12),
  //       child: Column(
  //         crossAxisAlignment:
  //         CrossAxisAlignment.start,
  //         children: [
  //
  //           Text(
  //             "Kappa $title - Expert",
  //             style: const TextStyle(
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //
  //           const SizedBox(height: 20),
  //
  //           Row(
  //             children: [
  //               const Text("Po ="),
  //               const SizedBox(width: 35),
  //               Text(
  //                 (operator["observedAgreement"] as num)
  //                     .toStringAsFixed(4),
  //               ),
  //             ],
  //           ),
  //
  //           const SizedBox(height: 8),
  //
  //           Row(
  //             children: [
  //               const Text("Pe ="),
  //               const SizedBox(width: 35),
  //               Text(
  //                 (operator["chanceAgreement"] as num)
  //                     .toStringAsFixed(4),
  //               ),
  //             ],
  //           ),
  //
  //           const SizedBox(height: 20),
  //
  //           const Center(
  //             child: Text(
  //               "κ = (Po − Pe) / (1 − Pe)",
  //               style: TextStyle(
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //           ),
  //
  //           const SizedBox(height: 10),
  //
  //           Center(
  //             child: Text(
  //               (operator["kappa"] as num).toStringAsFixed(4),
  //               style: const TextStyle(
  //                 fontWeight: FontWeight.bold,
  //                 fontSize: 17,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  Widget _buildKappaBox(
      int index,
      Map<String, dynamic> operator,
      ) {

    final title = String.fromCharCode(65 + index);

    final kappa =
    (operator["kappa"] as num).toDouble();

    final po =
    (operator["observedAgreement"] as num)
        .toDouble();

    final pe =
    (operator["chanceAgreement"] as num)
        .toDouble();

    Color kappaColor;

    if (kappa >= 0.75) {
      kappaColor = const Color(0xFF15803D);
    } else if (kappa >= 0.40) {
      kappaColor = const Color(0xFFD97706);
    } else {
      kappaColor = const Color(0xFFDC2626);
    }

    Widget valueCard({
      required String label,
      required String value,
      required IconData icon,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FB),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [

              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: const Color(0xFF3155C6),
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF747B86),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF202124),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE1E4E8),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          // --------------------------------------------------
          // HEADER
          // --------------------------------------------------

          Row(
            children: [

              Container(
                width: 36,
                height: 36,

                alignment: Alignment.center,

                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius:
                  BorderRadius.circular(9),
                ),

                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3155C6),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    Text(
                      "Kappa Analysis",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF202124),
                      ),
                    ),

                    SizedBox(height: 2),

                    Text(
                      "Agreement between Appraiser and Expert",
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF747B86),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: kappaColor.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(7),
                ),

                child: Text(
                  kappa.toStringAsFixed(4),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: kappaColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --------------------------------------------------
          // VALUES
          // --------------------------------------------------

          Row(
            children: [

              valueCard(
                label: "Observed Agreement",
                value: po.toStringAsFixed(4),
                icon: Icons.check_circle_outline,
              ),

              const SizedBox(width: 10),

              valueCard(
                label: "Chance Agreement",
                value: pe.toStringAsFixed(4),
                icon: Icons.calculate_outlined,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // --------------------------------------------------
          // FORMULA
          // --------------------------------------------------

          Container(
            width: double.infinity,

            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),

            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FB),
              borderRadius:
              BorderRadius.circular(9),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                const Text(
                  "Kappa Formula",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF747B86),
                  ),
                ),

                const SizedBox(height: 6),

                const Center(
                  child: Text(
                    "κ = (Po − Pe) / (1 − Pe)",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Center(
                  child: Text(
                    "κ = ${kappa.toStringAsFixed(4)}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: kappaColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSummary() {
    final summary = result.arrSummary;

    final operators = result.dataEntry.isNotEmpty
        ? result.dataEntry.first.operatorTrials
        : <OperatorTrials>[];

    final operatorCount = operators.length;

    List<dynamic> safeList(String key) {
      final value = summary[key];

      if (value is List) {
        return value;
      }

      return [];
    }

    String formatValue(
        dynamic value, {
          String suffix = "",
        }) {
      if (value == null) {
        return "-";
      }

      if (value is num) {
        return "${value.toStringAsFixed(2)}$suffix";
      }

      return value.toString();
    }

    final repeatability =
    safeList("repeatabilityByOperator");

    final reproducibility =
    safeList("reproducibilityByOperator");

    final kappa =
    safeList("kappaByOperator");

    final missRate =
    safeList("missRateByOperator");

    final falseAlert =
    safeList("falseAlertByOperator");

    final overallStatus =
        summary["overallStatus"]?.toString() ??
            "Not Available";

    Color statusColor;

    switch (overallStatus.toLowerCase()) {
      case "acceptable":
        statusColor = const Color(0xFF15803D);
        break;

      case "marginally acceptable":
        statusColor = const Color(0xFFD97706);
        break;

      default:
        statusColor = const Color(0xFFDC2626);
    }

    Widget statusBadge(String status) {
      Color color;

      switch (status.toLowerCase()) {
        case "acceptable":
          color = const Color(0xFF15803D);
          break;

        case "marginally acceptable":
          color = const Color(0xFFD97706);
          break;

        default:
          color = const Color(0xFFDC2626);
      }

      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          status,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    Widget metricCard({
      required String title,
      required String value,
      required IconData icon,
    }) {
      return Expanded(
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 92,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE1E4E8),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4FA),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: const Color(0xFF3155C6),
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF747B86),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF202124),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget summarySectionHeader() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF7F8FB),
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFE1E4E8),
            ),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.fact_check_outlined,
              size: 19,
              color: Color(0xFF3155C6),
            ),

            SizedBox(width: 9),

            Text(
              "Evaluation Summary",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202124),
              ),
            ),
          ],
        ),
      );
    }

    Widget summaryRow({
      required String number,
      required String criteria,
      required String status,
      required List<dynamic> values,
      String suffix = "",
      String? overallValue,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 13,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFE8EAED),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4FA),
                borderRadius:
                BorderRadius.circular(8),
              ),
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3155C6),
                ),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              flex: 5,
              child: Text(
                criteria,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
            ),

            const SizedBox(width: 16),

            SizedBox(
              width: 145,
              child: Center(
                child: statusBadge(status),
              ),
            ),

            if (values.isNotEmpty)
              ...List.generate(
                values.length,
                    (index) {
                  return SizedBox(
                    width: 115,
                    child: Center(
                      child: Text(
                        formatValue(
                          values[index],
                          suffix: suffix,
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  );
                },
              ),

            if (overallValue != null)
              SizedBox(
                width: operatorCount * 115,
                child: Center(
                  child: Text(
                    overallValue,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3155C6),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    Widget operatorHeader() {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF1F4FA),
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFE1E4E8),
            ),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 28,
            ),

            const SizedBox(width: 14),

            const Expanded(
              flex: 5,
              child: Text(
                "Evaluation Criteria",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
            ),

            const SizedBox(width: 16),

            const SizedBox(
              width: 145,
              child: Center(
                child: Text(
                  "Result",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ),

            ...operators.map(
                  (operator) {
                return SizedBox(
                  width: 115,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Color(0xFF3155C6),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        operator.candidateName.isEmpty
                            ? "Operator"
                            : operator.candidateName,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight:
                          FontWeight.w700,
                          color:
                          Color(0xFF202124),
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        operator.employeeCode,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 9,
                          color:
                          Color(0xFF747B86),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFF7F8FA),

      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

            // --------------------------------------------------
            // PAGE HEADER
            // --------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(12),
                border: Border.all(
                  color:
                  const Color(0xFFE1E4E8),
                ),
              ),

              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,

                    decoration: BoxDecoration(
                      color:
                      const Color(0xFFEAF0FF),
                      borderRadius:
                      BorderRadius.circular(11),
                    ),

                    child: const Icon(
                      Icons.assessment_outlined,
                      size: 22,
                      color:
                      Color(0xFF3155C6),
                    ),
                  ),

                  const SizedBox(width: 13),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ARR Summary",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.w700,
                            color:
                            Color(0xFF202124),
                          ),
                        ),

                        SizedBox(height: 3),

                        Text(
                          "Overall repeatability, reproducibility and inspection performance.",
                          style: TextStyle(
                            fontSize: 11.5,
                            color:
                            Color(0xFF747B86),
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
                      const Color(0xFFF1F4FA),
                      borderRadius:
                      BorderRadius.circular(8),
                    ),

                    child: Text(
                      "$operatorCount Operators",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight:
                        FontWeight.w600,
                        color:
                        Color(0xFF3155C6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // OVERALL RESULT
            // --------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(12),
                border: Border.all(
                  color:
                  const Color(0xFFE1E4E8),
                ),
              ),

              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,

                    decoration: BoxDecoration(
                      color:
                      statusColor.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                      BorderRadius.circular(11),
                    ),

                    child: Icon(
                      overallStatus
                          .toLowerCase() ==
                          "acceptable"
                          ? Icons
                          .check_circle_outline
                          : Icons
                          .info_outline,
                      color: statusColor,
                      size: 23,
                    ),
                  ),

                  const SizedBox(width: 13),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Overall Assessment",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                            FontWeight.w700,
                            color:
                            Color(0xFF202124),
                          ),
                        ),

                        SizedBox(height: 3),

                        Text(
                          "Final ARR evaluation status based on the calculated criteria.",
                          style: TextStyle(
                            fontSize: 10.5,
                            color:
                            Color(0xFF747B86),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),

                    decoration: BoxDecoration(
                      color:
                      statusColor.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                      BorderRadius.circular(8),
                    ),

                    child: Text(
                      overallStatus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),


            // --------------------------------------------------
            // EVALUATION TABLE
            // --------------------------------------------------

            Container(
              width: double.infinity,

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(12),
                border: Border.all(
                  color:
                  const Color(0xFFE1E4E8),
                ),
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  summarySectionHeader(),

                  SingleChildScrollView(
                    scrollDirection:
                    Axis.horizontal,

                    child: SizedBox(
                      width:
                      28 +
                          14 +
                          420 +
                          16 +
                          145 +
                          (operatorCount * 115),

                      child: Column(
                        children: [

                          operatorHeader(),

                          summaryRow(
                            number: "1",
                            criteria:
                            "Agreement within appraisers on all trials",
                            status:
                            summary[
                            "repeatabilityStatus"]
                                ?.toString() ??
                                "-",
                            values:
                            repeatability,
                            suffix: "%",
                          ),

                          summaryRow(
                            number: "2",
                            criteria:
                            "Agreement within appraisers & with known Standard",
                            status:
                            summary[
                            "reproducibilityStatus"]
                                ?.toString() ??
                                "-",
                            values:
                            reproducibility,
                            suffix: "%",
                          ),

                          summaryRow(
                            number: "3",
                            criteria:
                            "Agreement within & between appraisers",
                            status:
                            summary[
                            "agreementStatus"]
                                ?.toString() ??
                                "-",
                            values: const [],
                            overallValue:
                            summary["agreement"]
                            is num
                                ? "${(summary["agreement"] as num).toStringAsFixed(2)}%"
                                : "-",
                          ),

                          summaryRow(
                            number: "4",
                            criteria:
                            "Agreement within & between appraisers AND with known Standard",
                            status:
                            summary[
                            "effectivenessStatus"]
                                ?.toString() ??
                                "-",
                            values: const [],
                            overallValue:
                            summary["effectiveness"]
                            is num
                                ? "${(summary["effectiveness"] as num).toStringAsFixed(2)}%"
                                : "-",
                          ),

                          summaryRow(
                            number: "5",
                            criteria:
                            "Kappa [Individual Appraiser w.r.t. known Standard]",
                            status:
                            summary[
                            "kappaStatus"]
                                ?.toString() ??
                                "-",
                            values: kappa,
                          ),

                          summaryRow(
                            number: "6",
                            criteria:
                            "Miss Rate",
                            status:
                            summary[
                            "missRateStatus"]
                                ?.toString() ??
                                "-",
                            values: missRate,
                            suffix: "%",
                          ),

                          summaryRow(
                            number: "7",
                            criteria:
                            "False Alarm Rate",
                            status:
                            summary[
                            "falseAlertStatus"]
                                ?.toString() ??
                                "-",
                            values: falseAlert,
                            suffix: "%",
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // --------------------------------------------------
            // FINAL CONCLUSION
            // --------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(12),
                border: Border.all(
                  color:
                  const Color(0xFFE1E4E8),
                ),
              ),

              child: Row(
                children: [
                  Icon(
                    overallStatus.toLowerCase() ==
                        "acceptable"
                        ? Icons
                        .check_circle_rounded
                        : Icons
                        .error_outline_rounded,
                    color: statusColor,
                    size: 24,
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Final Conclusion",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                            FontWeight.w700,
                            color:
                            Color(0xFF202124),
                          ),
                        ),

                        SizedBox(height: 3),

                        Text(
                          "The ARR result is determined from repeatability, reproducibility, agreement, effectiveness and attribute performance.",
                          style: TextStyle(
                            fontSize: 10.5,
                            color:
                            Color(0xFF747B86),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),

                    decoration: BoxDecoration(
                      color:
                      statusColor.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                      BorderRadius.circular(8),
                    ),

                    child: Text(
                      overallStatus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _summaryDesktopHeader(
      List<OperatorTrials> operators,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F4FA),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE1E4E8),
          ),
        ),
      ),
      child: Row(
        children: [

          const SizedBox(
            width: 60,
            child: Text(
              "No.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
          ),

          const Expanded(
            flex: 4,
            child: Text(
              "Evaluation Criteria",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
          ),

          const SizedBox(
            width: 150,
            child: Text(
              "Result",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
          ),

          ...operators.map(
                (operator) => SizedBox(
              width: 125,
              child: Column(
                children: [

                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Color(0xFF3155C6),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    operator.candidateName.isEmpty
                        ? "Operator"
                        : operator.candidateName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF202124),
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    operator.employeeCode,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFF747B86),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _summaryDesktopRow({
    required String number,
    required String criteria,
    required String status,
    required List<dynamic> values,
    String suffix = "",
    String? overallValue,
  }) {
    Color statusColor;

    switch (status.toLowerCase()) {
      case "acceptable":
        statusColor = const Color(0xFF15803D);
        break;

      case "marginally acceptable":
        statusColor = const Color(0xFFD97706);
        break;

      default:
        statusColor = const Color(0xFFDC2626);
    }

    String formatValue(dynamic value) {
      if (value == null) {
        return "-";
      }

      if (value is num) {
        return "${value.toStringAsFixed(2)}$suffix";
      }

      return value.toString();
    }

    return Container(
      constraints: const BoxConstraints(
        minHeight: 58,
      ),

      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),

      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE8EAED),
          ),
        ),
      ),

      child: Row(
        children: [

          SizedBox(
            width: 60,
            child: Container(
              width: 28,
              height: 28,

              decoration: BoxDecoration(
                color: const Color(0xFFF1F4FA),
                borderRadius: BorderRadius.circular(8),
              ),

              alignment: Alignment.center,

              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3155C6),
                ),
              ),
            ),
          ),

          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(
                right: 20,
              ),
              child: Text(
                criteria,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
            ),
          ),

          SizedBox(
            width: 150,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: statusColor.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(7),
                ),

                child: Text(
                  status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ),
          ),

          ...List.generate(
            values.length,
                (index) => SizedBox(
              width: 125,
              child: Center(
                child: Text(
                  formatValue(values[index]),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ),
          ),

          if (overallValue != null)
            SizedBox(
              width: 125,
              child: Center(
                child: Text(
                  overallValue,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3155C6),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _summaryConclusion() {
    final status =
        result.arrSummary["overallStatus"]
            ?.toString() ??
            "Not Available";

    Color statusColor;

    switch (status.toLowerCase()) {
      case "acceptable":
        statusColor = const Color(0xFF15803D);
        break;

      case "marginally acceptable":
        statusColor = const Color(0xFFD97706);
        break;

      default:
        statusColor = const Color(0xFFDC2626);
    }

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE1E4E8),
        ),
      ),

      child: Row(
        children: [

          Container(
            width: 40,
            height: 40,

            decoration: BoxDecoration(
              color: statusColor.withValues(
                alpha: 0.10,
              ),
              borderRadius:
              BorderRadius.circular(10),
            ),

            child: Icon(
              status.toLowerCase() ==
                  "acceptable"
                  ? Icons.check_circle_outline
                  : Icons.info_outline,
              color: statusColor,
              size: 21,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                Text(
                  "Overall Conclusion",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202124),
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  "Overall assessment result based on the ARR evaluation.",
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF747B86),
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),

            decoration: BoxDecoration(
              color: statusColor.withValues(
                alpha: 0.10,
              ),
              borderRadius:
              BorderRadius.circular(8),
            ),

            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


//
// import 'package:flutter/material.dart';
//
// import '../models/arr_record.dart';
// import '../models/cross_tab_result.dart';
// import '../services/pdf_service.dart';
// import '../screens/combined_certificate_screen.dart';
//
// class CrossTabResultScreen extends StatelessWidget {
//   final CrossTabResult result;
//   final List<ArrRecord> selectedRecords;
//
//   const CrossTabResultScreen({
//     super.key,
//     required this.result,
//     required this.selectedRecords,
//   });
//
//   static const double cellWidth = 110;
//
//   static const Color primaryBlue = Color(0xFF3155C6);
//   static const Color lightBlue = Color(0xFFF1F4FA);
//   static const Color borderColor = Color(0xFFE1E4E8);
//
//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 5,
//       child: Scaffold(
//         backgroundColor: const Color(0xFFF7F9FC),
//
//         appBar: AppBar(
//           title: const Text(
//             'Cross Tab Report',
//             style: TextStyle(
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           centerTitle: false,
//
//           actions: [
//             PopupMenuButton<String>(
//               onSelected: (value) {
//                 _handleMenuSelection(
//                   context,
//                   value,
//                 );
//               },
//               itemBuilder: (context) => const [
//                 PopupMenuItem(
//                   value: 'download',
//                   child: ListTile(
//                     leading: Icon(Icons.download_outlined),
//                     title: Text('Download'),
//                   ),
//                 ),
//                 PopupMenuItem(
//                   value: 'share',
//                   child: ListTile(
//                     leading: Icon(Icons.share_outlined),
//                     title: Text('Share'),
//                   ),
//                 ),
//                 PopupMenuItem(
//                   value: 'print',
//                   child: ListTile(
//                     leading: Icon(Icons.print_outlined),
//                     title: Text('Print'),
//                   ),
//                 ),
//                 PopupMenuItem(
//                   value: 'certificate',
//                   child: ListTile(
//                     leading: Icon(Icons.badge_outlined),
//                     title: Text('Combined Certificate'),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//
//           bottom: const PreferredSize(
//             preferredSize: Size.fromHeight(52),
//             child: Padding(
//               padding: EdgeInsets.symmetric(
//                 horizontal: 12,
//               ),
//               child: TabBar(
//                 isScrollable: true,
//                 tabAlignment: TabAlignment.start,
//
//                 dividerColor: Colors.transparent,
//
//                 indicatorSize:
//                 TabBarIndicatorSize.label,
//
//                 indicatorWeight: 3,
//
//                 indicatorColor: primaryBlue,
//
//                 labelColor: primaryBlue,
//
//                 unselectedLabelColor:
//                 Color(0xFF6B7280),
//
//                 labelStyle: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600,
//                 ),
//
//                 unselectedLabelStyle:
//                 TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w500,
//                 ),
//
//                 tabs: [
//                   Tab(
//                     icon: Icon(
//                       Icons.input_outlined,
//                       size: 18,
//                     ),
//                     text: 'Data Entry',
//                   ),
//                   Tab(
//                     icon: Icon(
//                       Icons.calculate_outlined,
//                       size: 18,
//                     ),
//                     text: 'Calculations',
//                   ),
//                   Tab(
//                     icon: Icon(
//                       Icons.bar_chart_outlined,
//                       size: 18,
//                     ),
//                     text: 'Statistics',
//                   ),
//                   Tab(
//                     icon: Icon(
//                       Icons.grid_view_outlined,
//                       size: 18,
//                     ),
//                     text: 'Cross Tab',
//                   ),
//                   Tab(
//                     icon: Icon(
//                       Icons.summarize_outlined,
//                       size: 18,
//                     ),
//                     text: 'ARR Summary',
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//
//         body: TabBarView(
//           children: [
//             _buildDataEntry(),
//             _buildCalculations(),
//             _buildStatistics(),
//             _buildCrossTab(),
//             _buildSummary(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _handleMenuSelection(
//       BuildContext context,
//       String value,
//       ) {
//     switch (value) {
//       case 'download':
//         PdfService.downloadCrossTabReport(
//           context: context,
//           result: result,
//         );
//         break;
//
//       case 'share':
//         PdfService.shareCrossTabReport(
//           result: result,
//         );
//         break;
//
//       case 'print':
//         PdfService.printCrossTabReport(
//           result: result,
//         );
//         break;
//
//       case 'certificate':
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) =>
//                 CombinedCertificateScreen(
//                   records: selectedRecords,
//                 ),
//           ),
//         );
//         break;
//     }
//   }
//
//   Widget cell({
//     required String text,
//     double width = cellWidth,
//     double height = 42,
//     bool header = false,
//     bool bold = false,
//     Color textColor = Colors.black,
//   }) {
//     return Container(
//       width: width,
//       height: height,
//
//       alignment: Alignment.center,
//
//       decoration: BoxDecoration(
//         color: header
//             ? lightBlue
//             : Colors.white,
//
//         border: const Border(
//           right: BorderSide(
//             color: borderColor,
//             width: 0.8,
//           ),
//           bottom: BorderSide(
//             color: borderColor,
//             width: 0.8,
//           ),
//         ),
//       ),
//
//       padding: const EdgeInsets.symmetric(
//         horizontal: 6,
//         vertical: 4,
//       ),
//
//       child: Text(
//         text,
//         textAlign: TextAlign.center,
//         maxLines: 2,
//         overflow: TextOverflow.ellipsis,
//
//         style: TextStyle(
//           fontSize: header ? 11.5 : 11,
//
//           fontWeight:
//           bold || header
//               ? FontWeight.w700
//               : FontWeight.w500,
//
//           color: header
//               ? primaryBlue
//               : textColor,
//
//           height: 1.2,
//         ),
//       ),
//     );
//   }
//
//   Widget _sectionTitle(
//       String title,
//       String subtitle,
//       ) {
//     return Container(
//       width: double.infinity,
//
//       margin: const EdgeInsets.only(
//         bottom: 12,
//       ),
//
//       padding: const EdgeInsets.symmetric(
//         horizontal: 16,
//         vertical: 13,
//       ),
//
//       decoration: BoxDecoration(
//         color: Colors.white,
//
//         borderRadius:
//         BorderRadius.circular(10),
//
//         border: Border.all(
//           color: borderColor,
//         ),
//       ),
//
//       child: Column(
//         crossAxisAlignment:
//         CrossAxisAlignment.start,
//
//         children: [
//           Text(
//             title,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//
//           const SizedBox(height: 3),
//
//           Text(
//             subtitle,
//             style: const TextStyle(
//               fontSize: 12,
//               color: Color(0xFF747B86),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _emptyState(
//       String message,
//       ) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(30),
//
//         child: Column(
//           mainAxisSize:
//           MainAxisSize.min,
//
//           children: [
//             const Icon(
//               Icons.analytics_outlined,
//               size: 46,
//               color: Color(0xFF9AA3B2),
//             ),
//
//             const SizedBox(height: 12),
//
//             Text(
//               message,
//               textAlign: TextAlign.center,
//
//               style: const TextStyle(
//                 fontSize: 15,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF747B86),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _scrollTable({
//     required List<Widget> rows,
//   }) {
//     return Scrollbar(
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//
//         child: Column(
//           crossAxisAlignment:
//           CrossAxisAlignment.start,
//
//           children: rows,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDataEntry() {
//     final dataEntry =
//         result.dataEntry;
//
//     if (dataEntry.isEmpty) {
//       return _emptyState(
//         'No Data Available',
//       );
//     }
//
//     final operators =
//         dataEntry.first.operatorTrials;
//
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(12),
//
//       child: Column(
//         crossAxisAlignment:
//         CrossAxisAlignment.start,
//
//         children: [
//           _sectionTitle(
//             'Data Entry',
//             'Recorded inspection results for all selected candidates.',
//           ),
//
//           _scrollTable(
//             rows: [
//               Row(
//                 children: [
//                   cell(
//                     text: 'Part No',
//                     header: true,
//                     bold: true,
//                   ),
//
//                   cell(
//                     text: 'Expert',
//                     header: true,
//                     bold: true,
//                   ),
//
//                   ...operators.expand(
//                         (operator) => [
//                       cell(
//                         text:
//                         operator.candidateName,
//                         header: true,
//                         bold: true,
//                       ),
//                       cell(
//                         text: 'T1',
//                         header: true,
//                       ),
//                       cell(
//                         text: 'T2',
//                         header: true,
//                       ),
//                       cell(
//                         text: 'T3',
//                         header: true,
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//
//               ...dataEntry.map(
//                     (row) {
//                   return Row(
//                     children: [
//                       cell(
//                         text: row.partNumber,
//                         bold: true,
//                       ),
//
//                       cell(
//                         text:
//                         row.expert.toString(),
//                       ),
//
//                       ...row.operatorTrials
//                           .expand(
//                             (operator) => [
//                           cell(
//                             text: operator
//                                 .candidateName,
//                           ),
//                           cell(
//                             text: operator.trial1
//                                 .toString(),
//                             textColor:
//                             _answerColor(
//                               operator.trial1,
//                             ),
//                           ),
//                           cell(
//                             text: operator.trial2
//                                 .toString(),
//                             textColor:
//                             _answerColor(
//                               operator.trial2,
//                             ),
//                           ),
//                           cell(
//                             text: operator.trial3
//                                 .toString(),
//                             textColor:
//                             _answerColor(
//                               operator.trial3,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   );
//                 },
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Color _answerColor(
//       int value,
//       ) {
//     return value == 1
//         ? Colors.black87
//         : Colors.red;
//   }
//
//   Widget _buildCalculations() {
//     final calculations =
//         result.calculations;
//
//     if (calculations.isEmpty) {
//       return _emptyState(
//         'No calculation data available.',
//       );
//     }
//
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(12),
//
//       child: Column(
//         crossAxisAlignment:
//         CrossAxisAlignment.start,
//
//         children: [
//           _sectionTitle(
//             'Calculations',
//             'Part-level calculation matrix.',
//           ),
//
//           _scrollTable(
//             rows: [
//               Row(
//                 children: [
//                   cell(
//                     text: 'Part No',
//                     header: true,
//                   ),
//
//                   cell(
//                     text: 'Expert',
//                     header: true,
//                   ),
//
//                   ..._calculationHeaders(
//                     calculations.first.operators.length,
//                   ),
//                 ],
//               ),
//
//               ...calculations.map(
//                     (row) {
//                   return Row(
//                     children: [
//                       cell(
//                         text: row.partNumber,
//                         bold: true,
//                       ),
//
//                       cell(
//                         text:
//                         row.expert.toString(),
//                       ),
//
//                       ...row.operators
//                           .expand(
//                             (operator) => [
//                           cell(
//                             text:
//                             operator.same
//                                 .toString(),
//                           ),
//                           cell(
//                             text:
//                             operator.correct
//                                 .toString(),
//                           ),
//                           cell(
//                             text:
//                             operator.overkill
//                                 .toString(),
//                             textColor:
//                             operator.overkill >
//                                 0
//                                 ? Colors.red
//                                 : Colors.black87,
//                           ),
//                           cell(
//                             text:
//                             operator.escape
//                                 .toString(),
//                             textColor:
//                             operator.escape >
//                                 0
//                                 ? Colors.red
//                                 : Colors.black87,
//                           ),
//                         ],
//                       ),
//                     ],
//                   );
//                 },
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   List<Widget> _calculationHeaders(
//       int count,
//       ) {
//     final List<Widget> widgets =
//     [];
//
//     for (int i = 0;
//     i < count;
//     i++) {
//       widgets.add(
//         cell(
//           text: 'Same',
//           header: true,
//         ),
//       );
//
//       widgets.add(
//         cell(
//           text: 'Correct',
//           header: true,
//         ),
//       );
//
//       widgets.add(
//         cell(
//           text: 'Overkill',
//           header: true,
//         ),
//       );
//
//       widgets.add(
//         cell(
//           text: 'Escape',
//           header: true,
//         ),
//       );
//     }
//
//     return widgets;
//   }
//
//   Widget _buildStatistics() {
//     final statistics =
//         result.statisticalReport;
//
//     final operators =
//     _safeList(
//       statistics['operators'],
//     );
//
//     final totals =
//     _safeMap(
//       statistics['totals'],
//     );
//
//     if (operators.isEmpty &&
//         totals.isEmpty) {
//       return _emptyState(
//         'No statistical data available.',
//       );
//     }
//
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(12),
//
//       child: Column(
//         crossAxisAlignment:
//         CrossAxisAlignment.start,
//
//         children: [
//           _sectionTitle(
//             'Statistics',
//             'Repeatability, reproducibility and operator statistics.',
//           ),
//
//           if (operators.isNotEmpty)
//             _operatorStatisticsTable(
//               operators,
//             ),
//
//           const SizedBox(height: 18),
//
//           if (totals.isNotEmpty)
//             _statisticsTotals(
//               totals,
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _operatorStatisticsTable(
//       List<Map<String, dynamic>> operators,
//       ) {
//     return _scrollTable(
//       rows: [
//         Row(
//           children: [
//             cell(
//               text: 'Operator',
//               header: true,
//             ),
//             cell(
//               text: 'Repeatability',
//               header: true,
//             ),
//             cell(
//               text: 'Attribute',
//               header: true,
//             ),
//             cell(
//               text: 'Overkill',
//               header: true,
//             ),
//             cell(
//               text: 'Escape',
//               header: true,
//             ),
//           ],
//         ),
//
//         ...operators.asMap().entries.map(
//               (entry) {
//             final index =
//                 entry.key;
//
//             final operator =
//                 entry.value;
//
//             return Row(
//               children: [
//                 cell(
//                   text: _value(
//                     operator,
//                     'employeeCode',
//                     fallback:
//                     'Operator ${index + 1}',
//                   ),
//                   bold: true,
//                 ),
//
//                 cell(
//                   text: _percentValue(
//                     operator,
//                     'calculatedScore',
//                   ),
//                 ),
//
//                 cell(
//                   text: _percentValue(
//                     operator,
//                     'attributeScore',
//                   ),
//                 ),
//
//                 cell(
//                   text: _percentValue(
//                     operator,
//                     'overkillRatePercent',
//                   ),
//                 ),
//
//                 cell(
//                   text: _percentValue(
//                     operator,
//                     'escapeRatePercent',
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ],
//     );
//   }
//
//   Widget _statisticsTotals(
//       Map<String, dynamic> totals,
//       ) {
//     final entries =
//     totals.entries.toList();
//
//     return Card(
//       elevation: 0,
//
//       margin: EdgeInsets.zero,
//
//       shape: RoundedRectangleBorder(
//         borderRadius:
//         BorderRadius.circular(10),
//         side: const BorderSide(
//           color: borderColor,
//         ),
//       ),
//
//       child: Padding(
//         padding:
//         const EdgeInsets.all(16),
//
//         child: Column(
//           crossAxisAlignment:
//           CrossAxisAlignment.start,
//
//           children: [
//             const Text(
//               'Totals',
//               style: TextStyle(
//                 fontSize: 15,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//
//             const SizedBox(height: 10),
//
//             ...entries.map(
//                   (entry) {
//                 return Padding(
//                   padding:
//                   const EdgeInsets.symmetric(
//                     vertical: 5,
//                   ),
//
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           entry.key,
//                           style:
//                           const TextStyle(
//                             color:
//                             Color(0xFF747B86),
//                           ),
//                         ),
//                       ),
//
//                       Text(
//                         _display(
//                           entry.value,
//                         ),
//                         style:
//                         const TextStyle(
//                           fontWeight:
//                           FontWeight.w700,
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCrossTab() {
//     final crossTab =
//         result.crossTab;
//
//     final operators =
//     _safeList(
//       crossTab['operators'],
//     );
//
//     final totals =
//     _safeMap(
//       crossTab['totals'],
//     );
//
//     if (operators.isEmpty &&
//         totals.isEmpty) {
//       return _emptyState(
//         'No Cross Tab data available.',
//       );
//     }
//
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(12),
//
//       child: Column(
//         crossAxisAlignment:
//         CrossAxisAlignment.start,
//
//         children: [
//           _sectionTitle(
//             'Cross Tab',
//             'Agreement and error classification by operator.',
//           ),
//
//           if (operators.isNotEmpty)
//             _scrollTable(
//               rows: [
//                 Row(
//                   children: [
//                     cell(
//                       text: 'Operator',
//                       header: true,
//                     ),
//                     cell(
//                       text: 'PP',
//                       header: true,
//                     ),
//                     cell(
//                       text: 'PF',
//                       header: true,
//                     ),
//                     cell(
//                       text: 'FP',
//                       header: true,
//                     ),
//                     cell(
//                       text: 'FF',
//                       header: true,
//                     ),
//                     cell(
//                       text: 'Total',
//                       header: true,
//                     ),
//                     cell(
//                       text: 'Agreement',
//                       header: true,
//                     ),
//                     cell(
//                       text: 'Kappa',
//                       header: true,
//                     ),
//                     cell(
//                       text: 'Overkill',
//                       header: true,
//                     ),
//                     cell(
//                       text: 'Escape',
//                       header: true,
//                     ),
//                   ],
//                 ),
//
//                 ...operators.asMap().entries.map(
//                       (entry) {
//                     final index =
//                         entry.key;
//
//                     final operator =
//                         entry.value;
//
//                     return Row(
//                       children: [
//                         cell(
//                           text: _value(
//                             operator,
//                             'employeeCode',
//                             fallback:
//                             'Operator ${index + 1}',
//                           ),
//                           bold: true,
//                         ),
//
//                         cell(
//                           text: _numberValue(
//                             operator,
//                             'PP',
//                           ),
//                         ),
//
//                         cell(
//                           text: _numberValue(
//                             operator,
//                             'PF',
//                           ),
//                         ),
//
//                         cell(
//                           text: _numberValue(
//                             operator,
//                             'FP',
//                           ),
//                         ),
//
//                         cell(
//                           text: _numberValue(
//                             operator,
//                             'FF',
//                           ),
//                         ),
//
//                         cell(
//                           text: _numberValue(
//                             operator,
//                             'total',
//                           ),
//                         ),
//
//                         cell(
//                           text: _percentValue(
//                             operator,
//                             'observedAgreement',
//                           ),
//                         ),
//
//                         cell(
//                           text: _percentValue(
//                             operator,
//                             'kappaPercent',
//                           ),
//                         ),
//
//                         cell(
//                           text: _percentValue(
//                             operator,
//                             'overkillRatePercent',
//                           ),
//                         ),
//
//                         cell(
//                           text: _percentValue(
//                             operator,
//                             'escapeRatePercent',
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//               ],
//             ),
//
//           const SizedBox(height: 18),
//
//           if (totals.isNotEmpty)
//             _crossTabTotals(
//               totals,
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _crossTabTotals(
//       Map<String, dynamic> totals,
//       ) {
//     return Card(
//       elevation: 0,
//
//       margin: EdgeInsets.zero,
//
//       shape: RoundedRectangleBorder(
//         borderRadius:
//         BorderRadius.circular(10),
//         side: const BorderSide(
//           color: borderColor,
//         ),
//       ),
//
//       child: Padding(
//         padding:
//         const EdgeInsets.all(16),
//
//         child: Column(
//           crossAxisAlignment:
//           CrossAxisAlignment.start,
//
//           children: [
//             const Text(
//               'Cross Tab Totals',
//               style: TextStyle(
//                 fontSize: 15,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//
//             const SizedBox(height: 10),
//
//             ...totals.entries.map(
//                   (entry) {
//                 return Padding(
//                   padding:
//                   const EdgeInsets.symmetric(
//                     vertical: 5,
//                   ),
//
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           entry.key,
//                           style:
//                           const TextStyle(
//                             color:
//                             Color(0xFF747B86),
//                           ),
//                         ),
//                       ),
//
//                       Text(
//                         _display(
//                           entry.value,
//                         ),
//                         style:
//                         const TextStyle(
//                           fontWeight:
//                           FontWeight.w700,
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSummary() {
//     final summary =
//         result.arrSummary;
//
//     if (summary.isEmpty) {
//       return _emptyState(
//         'No ARR summary available.',
//       );
//     }
//
//     final entries =
//     summary.entries.toList();
//
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(12),
//
//       child: Column(
//         crossAxisAlignment:
//         CrossAxisAlignment.start,
//
//         children: [
//           _sectionTitle(
//             'ARR Summary',
//             'Final summary for the selected candidates.',
//           ),
//
//           Card(
//             elevation: 0,
//
//             margin: EdgeInsets.zero,
//
//             shape:
//             RoundedRectangleBorder(
//               borderRadius:
//               BorderRadius.circular(10),
//               side: const BorderSide(
//                 color: borderColor,
//               ),
//             ),
//
//             child: Padding(
//               padding:
//               const EdgeInsets.all(16),
//
//               child: Column(
//                 children: [
//                   ...entries.map(
//                         (entry) {
//                       return Padding(
//                         padding:
//                         const EdgeInsets.symmetric(
//                           vertical: 7,
//                         ),
//
//                         child: Row(
//                           crossAxisAlignment:
//                           CrossAxisAlignment
//                               .start,
//
//                           children: [
//                             Expanded(
//                               flex: 2,
//
//                               child: Text(
//                                 _prettyKey(
//                                   entry.key,
//                                 ),
//
//                                 style:
//                                 const TextStyle(
//                                   color:
//                                   Color(
//                                     0xFF747B86,
//                                   ),
//                                   fontWeight:
//                                   FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//
//                             const SizedBox(
//                               width: 15,
//                             ),
//
//                             Expanded(
//                               flex: 3,
//
//                               child: _summaryValue(
//                                 entry.value,
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _summaryValue(
//       dynamic value,
//       ) {
//     if (value is List) {
//       if (value.isEmpty) {
//         return const Text(
//           '-',
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//           ),
//         );
//       }
//
//       return Column(
//         crossAxisAlignment:
//         CrossAxisAlignment.start,
//
//         children: [
//           ...value.map(
//                 (item) {
//               if (item is Map) {
//                 return Padding(
//                   padding:
//                   const EdgeInsets.only(
//                     bottom: 3,
//                   ),
//                   child: Text(
//                     item.entries
//                         .map(
//                           (e) =>
//                       '${e.key}: ${_display(e.value)}',
//                     )
//                         .join('  •  '),
//                     style:
//                     const TextStyle(
//                       fontSize: 12,
//                     ),
//                   ),
//                 );
//               }
//
//               return Text(
//                 _display(item),
//                 style:
//                 const TextStyle(
//                   fontSize: 12,
//                 ),
//               );
//             },
//           ),
//         ],
//       );
//     }
//
//     if (value is Map) {
//       return Text(
//         value.entries
//             .map(
//               (e) =>
//           '${e.key}: ${_display(e.value)}',
//         )
//             .join('\n'),
//         style: const TextStyle(
//           fontSize: 12,
//         ),
//       );
//     }
//
//     return Text(
//       _display(value),
//       style: const TextStyle(
//         fontWeight: FontWeight.w700,
//       ),
//     );
//   }
//
//   List<Map<String, dynamic>> _safeList(
//       dynamic value,
//       ) {
//     if (value is! List) {
//       return [];
//     }
//
//     return value
//         .whereType<Map>()
//         .map(
//           (e) => Map<String, dynamic>.from(
//         e,
//       ),
//     )
//         .toList();
//   }
//
//   Map<String, dynamic> _safeMap(
//       dynamic value,
//       ) {
//     if (value is! Map) {
//       return {};
//     }
//
//     return Map<String, dynamic>.from(
//       value,
//     );
//   }
//
//   String _value(
//       Map<String, dynamic> map,
//       String key, {
//         String fallback = '-',
//       }) {
//     final value = map[key];
//
//     if (value == null ||
//         value.toString().trim().isEmpty) {
//       return fallback;
//     }
//
//     return value.toString();
//   }
//
//   String _numberValue(
//       Map<String, dynamic> map,
//       String key,
//       ) {
//     final value = map[key];
//
//     if (value == null) {
//       return '0';
//     }
//
//     if (value is num) {
//       return value.toString();
//     }
//
//     return value.toString();
//   }
//
//   String _percentValue(
//       Map<String, dynamic> map,
//       String key,
//       ) {
//     final value = map[key];
//
//     if (value == null) {
//       return '0.00%';
//     }
//
//     if (value is num) {
//       return '${value.toStringAsFixed(2)}%';
//     }
//
//     final parsed =
//     double.tryParse(
//       value.toString(),
//     );
//
//     if (parsed == null) {
//       return value.toString();
//     }
//
//     return '${parsed.toStringAsFixed(2)}%';
//   }
//
//   String _display(
//       dynamic value,
//       ) {
//     if (value == null) {
//       return '-';
//     }
//
//     if (value is double) {
//       return value.toStringAsFixed(2);
//     }
//
//     return value.toString();
//   }
//
//   String _prettyKey(
//       String key,
//       ) {
//     if (key.isEmpty) {
//       return '-';
//     }
//
//     final withSpaces =
//     key.replaceAllMapped(
//       RegExp(r'([a-z])([A-Z])'),
//           (match) =>
//       '${match.group(1)} ${match.group(2)}',
//     );
//
//     return withSpaces
//         .replaceAll('_', ' ')
//         .replaceAll('-', ' ')
//         .split(' ')
//         .where(
//           (e) => e.isNotEmpty,
//     )
//         .map(
//           (e) =>
//       e[0].toUpperCase() +
//           e.substring(1),
//     )
//         .join(' ');
//   }
// }
