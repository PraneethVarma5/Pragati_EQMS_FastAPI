import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/scanner_controller.dart';
import '../services/app_data.dart';
import '../services/supabase_service.dart';
import '../services/evaluation_service.dart';

class ScannerAssessmentScreen extends StatefulWidget {
  const ScannerAssessmentScreen({super.key});

  @override
  State<ScannerAssessmentScreen> createState() =>
      _ScannerAssessmentScreenState();
}

class _ScannerAssessmentScreenState extends State<ScannerAssessmentScreen> {
  List<Map<String, dynamic>> masterParts = [];

  int get totalParts => masterParts.length;

  bool isLoadingParts = true;
  String? partsLoadError;

  final ScannerController scanner = ScannerController();

  final TextEditingController scannerController =
  TextEditingController();

  final FocusNode scannerFocus = FocusNode();

  /// Change to false before delivery.
  bool developerTesting = true;

  final TextEditingController developerController =
  TextEditingController();

  final Map<int, int> answers = {};

  final Set<int> scannedParts = {};

  int completed = 0;

  bool trailCompleted = false;
  void saveAnswer(int partIndex, int value) {
    if (partIndex < 0 || partIndex >= totalParts) {
      return;
    }
    answers[partIndex] = value;

    switch (AppData.currentTrail) {
      case 1:
        AppData.trail1Answers[partIndex] = value;
        break;

      case 2:
        AppData.trail2Answers[partIndex] = value;
        break;

      case 3:
        AppData.trail3Answers[partIndex] = value;
        break;
    }

    scannedParts.add(partIndex);

    setState(() {
      completed++;
    });
  }

  Future<void> showTrailCompletedDialog() async {
    if (trailCompleted) return;

    trailCompleted = true;

    if (!mounted) return;

    final bool hasNextTrial =
        AppData.currentTrail < 3;

    final int nextTrial =
        AppData.currentTrail + 1;

    showDialog(
      context: context,
      barrierDismissible: false,

      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,

          insetPadding:
          const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 30,
          ),

          child: Container(
            width: 520,

            padding:
            const EdgeInsets.fromLTRB(
              32,
              30,
              32,
              28,
            ),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius:
              BorderRadius.circular(20),

              border: Border.all(
                color:
                const Color(0xFFE1E5EA),
              ),

              boxShadow: [
                BoxShadow(
                  color:
                  Colors.black.withValues(
                    alpha: 0.08,
                  ),
                  blurRadius: 28,
                  offset:
                  const Offset(0, 10),
                ),
              ],
            ),

            child: Column(
              mainAxisSize:
              MainAxisSize.min,

              children: [

                // STATUS HEADER
                Container(
                  width: 64,
                  height: 64,

                  decoration: BoxDecoration(
                    color:
                    const Color(0xFFEAF0FF),

                    borderRadius:
                    BorderRadius.circular(
                      17,
                    ),
                  ),

                  child: Icon(
                    hasNextTrial
                        ? Icons.task_alt_rounded
                        : Icons.assessment_outlined,

                    size: 32,

                    color:
                    const Color(0xFF3155C6),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  hasNextTrial
                      ? "Trial ${AppData.currentTrail} Completed"
                      : "Assessment Completed",

                  textAlign:
                  TextAlign.center,

                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF202124),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  hasNextTrial
                      ? "All parts in this trial have been successfully assessed."
                      : "All three trials have been completed. Your results are ready for evaluation.",

                  textAlign:
                  TextAlign.center,

                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color:
                    Color(0xFF747B86),
                  ),
                ),

                const SizedBox(height: 22),

                // COMPLETION SUMMARY
                Container(
                  width: double.infinity,

                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),

                  decoration: BoxDecoration(
                    color:
                    const Color(0xFFF7F8FA),

                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),

                    border: Border.all(
                      color:
                      const Color(0xFFE1E5EA),
                    ),
                  ),

                  child: Row(
                    children: [

                      Container(
                        width: 40,
                        height: 40,

                        decoration:
                        BoxDecoration(
                          color:
                          const Color(
                            0xFFEAF0FF,
                          ),

                          borderRadius:
                          BorderRadius.circular(
                            10,
                          ),
                        ),

                        child: const Icon(
                          Icons.fact_check_outlined,
                          size: 21,
                          color:
                          Color(0xFF3155C6),
                        ),
                      ),

                      const SizedBox(width: 13),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [

                            const Text(
                              "Inspection Status",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                FontWeight.w600,
                                color:
                                Color(0xFF7A8494),
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              "$totalParts parts assessed",

                              style:
                              const TextStyle(
                                fontSize: 13,
                                fontWeight:
                                FontWeight.w700,
                                color:
                                Color(0xFF202124),
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
                          color:
                          const Color(
                            0xFFEAF0FF,
                          ),

                          borderRadius:
                          BorderRadius.circular(
                            7,
                          ),
                        ),

                        child: Text(
                          hasNextTrial
                              ? "COMPLETED"
                              : "FINISHED",

                          style:
                          const TextStyle(
                            fontSize: 9.5,
                            fontWeight:
                            FontWeight.w800,
                            color:
                            Color(0xFF3155C6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (hasNextTrial) ...[

                  const SizedBox(height: 18),

                  // NEXT TRIAL
                  Container(
                    width: double.infinity,

                    padding:
                    const EdgeInsets.all(16),

                    decoration:
                    BoxDecoration(
                      color:
                      const Color(
                        0xFFF8FAFF,
                      ),

                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),

                      border: Border.all(
                        color:
                        const Color(
                          0xFFDCE4F8,
                        ),
                      ),
                    ),

                    child: Row(
                      children: [

                        Container(
                          width: 42,
                          height: 42,

                          decoration:
                          BoxDecoration(
                            color:
                            const Color(
                              0xFFEAF0FF,
                            ),

                            borderRadius:
                            BorderRadius.circular(
                              10,
                            ),
                          ),

                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 23,
                            color:
                            Color(0xFF3155C6),
                          ),
                        ),

                        const SizedBox(width: 13),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,

                            children: [

                              Text(
                                "Next: Trial $nextTrial",
                                style:
                                const TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                  FontWeight.w700,
                                  color:
                                  Color(
                                    0xFF202124,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 3),

                              const Text(
                                "Continue with the next inspection trial.",
                                style:
                                TextStyle(
                                  fontSize: 11,
                                  color:
                                  Color(
                                    0xFF747B86,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ACTION
                SizedBox(
                  width: double.infinity,
                  height: 48,

                  child: ElevatedButton(
                    onPressed: () async {

                      Navigator.pop(
                        dialogContext,
                      );

                      if (hasNextTrial) {

                        setState(() {

                          AppData.currentTrail++;

                          completed = 0;

                          answers.clear();

                          scannedParts.clear();

                          trailCompleted = false;
                        });

                        scannerFocus.requestFocus();

                      } else {
                        try {
                          // Show saving state while the final ARR
                          // is committed to Supabase.
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) {
                              return const Dialog(
                                child: Padding(
                                  padding: EdgeInsets.all(28),
                                  child: Column(
                                    mainAxisSize:
                                    MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 30,
                                        height: 30,
                                        child:
                                        CircularProgressIndicator(),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        "Saving ARR...",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                          FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        "Saving the assessment securely.",
                                        textAlign:
                                        TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                          Color(0xFF747B86),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );

                          await _saveCompletedArr();

                          if (!mounted) return;

                          Navigator.pop(context);

                          Navigator.pushReplacementNamed(
                            context,
                            "/ARR/combinedReport",
                          );
                        } catch (e) {
                          if (!mounted) return;

                          Navigator.pop(context);

                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Failed to save ARR: $e",
                              ),
                              duration:
                              const Duration(
                                seconds: 4,
                              ),
                            ),
                          );

                          scannerFocus.requestFocus();
                        }
                      }
                    },

                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(
                        0xFF3155C6,
                      ),

                      foregroundColor:
                      Colors.white,

                      elevation: 0,

                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          9,
                        ),
                      ),
                    ),

                    child: Text(
                      hasNextTrial
                          ? "Start Trial $nextTrial"
                          : "View Assessment Report",

                      style:
                      const TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  @override
  void initState() {
    super.initState();

    _loadBatchParts();
  }

  Future<void> _loadBatchParts() async {
    try {
      final batchId = AppData.selectedBatchId.trim();

      if (batchId.isEmpty) {
        throw Exception("No batch selected.");
      }

      final parts =
      await SupabaseService.getActiveParts(batchId);

      if (!mounted) return;

      setState(() {
        masterParts = parts;

        AppData.masterParts =
        List<Map<String, dynamic>>.from(parts);

        isLoadingParts = false;
        partsLoadError = null;
      });

      final total = parts.length;

      if (AppData.trail1Answers.length != total) {
        AppData.trail1Answers =
            List.filled(total, -1);
      }

      if (AppData.trail2Answers.length != total) {
        AppData.trail2Answers =
            List.filled(total, -1);
      }

      if (AppData.trail3Answers.length != total) {
        AppData.trail3Answers =
            List.filled(total, -1);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        masterParts = [];
        isLoadingParts = false;
        partsLoadError = e.toString();
      });
    }
  }
  @override
  void dispose() {
    scanner.dispose();

    scannerController.dispose();
    developerController.dispose();
    scannerFocus.dispose();

    super.dispose();
  }
  Future<void> markPass(
      BuildContext dialogContext,
      int partIndex,
      ) async {
    saveAnswer(partIndex, 1);

    Navigator.pop(dialogContext);

    scannerController.clear();

    Future.delayed(
      const Duration(milliseconds: 250),
          () {
        if (mounted) {
          scannerFocus.requestFocus();
        }
      },
    );

    if (completed == totalParts) {
      showTrailCompletedDialog();
    }
  }

  Future<void> markFail(
      BuildContext dialogContext,
      int partIndex,
      ) async {
    saveAnswer(partIndex, 0);

    Navigator.pop(dialogContext);

    scannerController.clear();

    Future.delayed(
      const Duration(milliseconds: 250),
          () {
        if (mounted) {
          scannerFocus.requestFocus();
        }
      },
    );

    if (completed == totalParts) {
      showTrailCompletedDialog();
    }
  }
  Future<void> showDeveloperBarcodeDialog() async {
    developerController.clear();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Developer Test"),

          content: TextField(
            controller: developerController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: "Barcode",
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) async {
              Navigator.pop(dialogContext);

              if (value.trim().isEmpty) return;

              await onBarcodeScanned(value.trim());

              scannerFocus.requestFocus();
            },
          ),
        );
      },
    );
  }
  int? _findPartIndexByBarcode(String barcode) {
    final normalizedBarcode =
    barcode.trim().toLowerCase();

    final index = masterParts.indexWhere(
          (part) =>
      (part['barcode_value']?.toString() ?? '')
          .trim()
          .toLowerCase() ==
          normalizedBarcode,
    );

    return index == -1 ? null : index;
  }
  List<Map<String, dynamic>> _buildObservations() {
    final observations =
    <Map<String, dynamic>>[];

    for (int i = 0;
    i < masterParts.length;
    i++) {
      final part = masterParts[i];

      observations.add({
        'part_id':
        part['part_id'],

        'part_number_snap':
        part['part_number']?.toString() ?? '',

        'master_status_snapshot':
        part['master_status'],

        'trail1':
        AppData.trail1Answers[i],

        'trail2':
        AppData.trail2Answers[i],

        'trail3':
        AppData.trail3Answers[i],
      });
    }

    return observations;
  }
  Future<void> _saveCompletedArr() async {
    if (isLoadingParts ||
        masterParts.isEmpty) {
      throw Exception(
        "Inspection parts are not loaded.",
      );
    }

    final observations =
    _buildObservations();

    final result =
    EvaluationService.calculate(
      masterParts: masterParts,
    );

    // Save calculated values into AppData
    AppData.finalClassification =
    result["classification"];

    AppData.falseAlertPercent =
        (result["falseAlertPercent"] as num)
            .toDouble();

    AppData.missRate =
        (result["missRate"] as num)
            .toDouble();

    AppData.effectiveness =
        (result["effectiveness"] as num)
            .toDouble();

    AppData.kappa =
        (result["kappa"] as num)
            .toDouble();

    final response =
    await SupabaseService.completeArr(
      employeeCode:
      AppData.employeeCode,

      batchId:
      AppData.selectedBatchId,

      product:
      AppData.productName,

      assessmentDate:
      DateTime.now(),

      falseAlertCount:
      result["falseAlert"] as int,

      missAlertCount:
      result["missAlert"] as int,

      falseAlertPct:
      (result["falseAlertPercent"] as num)
          .toDouble(),

      missRatePct:
      (result["missRate"] as num)
          .toDouble(),

      effectivenessPct:
      (result["effectiveness"] as num)
          .toDouble(),

      p1:
      (result["p1"] as num)
          .toDouble(),

      p0:
      (result["p0"] as num)
          .toDouble(),

      pChance:
      (result["pChance"] as num)
          .toDouble(),

      kappaPct:
      (result["kappa"] as num)
          .toDouble(),

      classification:
      result["classification"]
          .toString(),

      observations:
      observations,
    );

    final arrId =
    response['arr_id']?.toString();

    final certificateNumber =
    response['certificate_number']?.toString();

    if (arrId == null || arrId.isEmpty) {
      throw Exception(
        "ARR was saved but ARR ID was not returned.",
      );
    }

    if (certificateNumber == null ||
        certificateNumber.isEmpty) {
      throw Exception(
        "ARR was saved but certificate number was not returned.",
      );
    }

    AppData.savedArrId = arrId;

    AppData.certificateNo =
        certificateNumber;
  }
  Future<void> onBarcodeScanned(String barcode) async {
    final int? partIndex =
    _findPartIndexByBarcode(barcode);

    if (partIndex == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Unknown Barcode")));

      scannerFocus.requestFocus();


      return;
    }

    if (scannedParts.contains(partIndex)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Already Scanned in Trial ${AppData.currentTrail}"),

          duration: const Duration(seconds: 1),
        ),
      );

      scannerFocus.requestFocus();


      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent) {
                return KeyEventResult.ignored;
              }

              switch (event.logicalKey) {
                case LogicalKeyboardKey.keyP:
                case LogicalKeyboardKey.digit1:
                case LogicalKeyboardKey.enter:
                  markPass(dialogContext, partIndex);
                  return KeyEventResult.handled;

                case LogicalKeyboardKey.keyF:
                case LogicalKeyboardKey.digit0:
                  markFail(dialogContext, partIndex);
                  return KeyEventResult.handled;

                case LogicalKeyboardKey.escape:
                  Navigator.pop(dialogContext);
                  scannerFocus.requestFocus();
                  return KeyEventResult.handled;

                default:
                  return KeyEventResult.ignored;
              }
            },
          child: AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),

            insetPadding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 24,
            ),

            titlePadding: const EdgeInsets.fromLTRB(
              32,
              30,
              32,
              0,
            ),

            contentPadding: const EdgeInsets.fromLTRB(
              32,
              14,
              32,
              30,
            ),

            title: const Column(
              children: [

                Text(
                  "Inspection Result",
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202124),
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  "Complete the physical inspection and select the appropriate result.",
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Color(0xFF747B86),
                  ),
                ),
              ],
            ),

            content: SizedBox(
              width: 600,

              child: Row(
                children: [

                  // PASS
                  Expanded(
                    child: _resultButton(
                      title: "PASS",
                      description:
                      "Meets required requirements",
                      backgroundColor:
                      const Color(0xFFF2F8F4),
                      borderColor:
                      const Color(0xFFC9DFD0),
                      textColor:
                      const Color(0xFF267A4A),

                      onPressed: () =>
                          markPass(
                            dialogContext,
                            partIndex,
                          ),
                    ),
                  ),

                  const SizedBox(width: 18),

                  // FAIL
                  Expanded(
                    child: _resultButton(
                      title: "FAIL",
                      description:
                      "Does not meet requirements",
                      backgroundColor:
                      const Color(0xFFFCF4F4),
                      borderColor:
                      const Color(0xFFE5CACA),
                      textColor:
                      const Color(0xFFC13F3F),

                      onPressed: () =>
                          markFail(
                            dialogContext,
                            partIndex,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _resultButton({
    required String title,
    required String description,
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 150,

      child: Material(
        color: Colors.transparent,

        borderRadius: BorderRadius.circular(14),

        child: InkWell(
          onTap: onPressed,

          borderRadius:
          BorderRadius.circular(14),

          child: Ink(
            decoration: BoxDecoration(
              color: backgroundColor,

              borderRadius:
              BorderRadius.circular(14),

              border: Border.all(
                color: borderColor,
                width: 1.2,
              ),
            ),

            child: Padding(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),

              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,

                children: [

                  Text(
                    title,

                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                      FontWeight.w800,
                      letterSpacing: 0.6,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    description,

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.4,
                      fontWeight:
                      FontWeight.w500,
                      color: textColor.withValues(
                        alpha: 0.78,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    // return Scaffold(
    //   appBar: AppBar(
    //     title: const Text("Scanner Assessment"),
    //
    //     centerTitle: true,
    //   ),
    //
    //   body: Padding(


    //Need to Remove this testing button below and above is original
    return Shortcuts(
      shortcuts: {
        const SingleActivator(
          LogicalKeyboardKey.keyM,
          control: true,
        ): const ActivateIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) {
              if (developerTesting) {
                showDeveloperBarcodeDialog();
              }
              return null;
            },
          ),
        },
        child: Scaffold(

              appBar: AppBar(
                elevation: 0,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                toolbarHeight: 72,

                titleSpacing: 24,

                title: Row(
                  children: [

                    Container(
                      width: 42,
                      height: 42,

                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF0FF),
                        borderRadius: BorderRadius.circular(11),
                      ),

                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Color(0xFF3155C6),
                        size: 23,
                      ),
                    ),

                    const SizedBox(width: 14),

                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [

                        Text(
                          "Scanner Assessment",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF202124),
                            height: 1.1,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(
                          "Part inspection & result entry",
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF7A8494),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // CURRENT TRIAL
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),

                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F4FA),
                        borderRadius: BorderRadius.circular(9),
                      ),

                      child: Text(
                        "TRIAL ${AppData.currentTrail}",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3155C6),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),
                  ],
                ),
              ),

      // floatingActionButton: FloatingActionButton.extended(
      //
      //   backgroundColor: Colors.red,
      //
      //   icon: const Icon(Icons.bug_report),
      //
      //   label: const Text("Finish"),
      //
      //   onPressed: () {
      //
      //     AppData.trail1Answers =
      //         List.generate( totalParts, (i) => i % 2);
      //
      //     AppData.trail2Answers =
      //         List.generate( totalParts, (i) => i % 2);
      //
      //     AppData.trail3Answers =
      //         List.generate( totalParts, (i) => i % 2);
      //
      //     Navigator.pushReplacementNamed(
      //       context,
      //       "/combinedReport",
      //     );
      //
      //   },
      //
      // ),

              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1050,
                  ),
                  child: isLoadingParts
                      ? _buildPartsLoadingState()
                      : partsLoadError != null
                      ? _buildPartsErrorState()
                      : totalParts == 0
                      ? _buildNoPartsState()
                      : _buildAssessmentBody(),
                ),
              ),
        ),
    ),
    );
  }
  Widget _trialStatusCard(
      String title,
      bool completed,
      bool current,
      ) {
    final Color background = completed
        ? const Color(0xFFF0F7F3)
        : current
        ? const Color(0xFFF0F4FF)
        : const Color(0xFFF7F8FA);

    final Color foreground = completed
        ? const Color(0xFF3C7653)
        : current
        ? const Color(0xFF3155C6)
        : const Color(0xFF8A93A1);

    final String status = completed
        ? "Completed"
        : current
        ? "Current"
        : "Locked";

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),

        decoration: BoxDecoration(
          color: background,

          borderRadius:
          BorderRadius.circular(12),

          border: Border.all(
            color: current
                ? const Color(0xFFD7E1FA)
                : const Color(0xFFE1E5EA),
          ),
        ),

        child: Row(
          children: [

            Container(
              width: 9,
              height: 9,

              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(width: 10),

            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w700,
                color:
                const Color(0xFF202124),
              ),
            ),

            const Spacer(),

            Text(
              status,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight:
                FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildPartsLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 120,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF3155C6),
              ),
            ),

            SizedBox(height: 18),

            Text(
              "Loading Inspection Parts",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202124),
              ),
            ),

            SizedBox(height: 6),

            Text(
              "Loading the selected batch from the database...",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF747B86),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartsErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 100,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE1E5EA),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.cloud_off_outlined,
                  size: 29,
                  color: Color(0xFFC13F3F),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "Unable to Load Parts",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202124),
                ),
              ),

              const SizedBox(height: 7),

              Text(
                partsLoadError ?? "Unknown error",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: Color(0xFF747B86),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      isLoadingParts = true;
                      partsLoadError = null;
                    });

                    _loadBatchParts();
                  },
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 18,
                  ),
                  label: const Text(
                    "Retry",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF3155C6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoPartsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 100,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE1E5EA),
            ),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 46,
                color: Color(0xFF9AA3AF),
              ),

              SizedBox(height: 14),

              Text(
                "No Parts Found",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202124),
                ),
              ),

              SizedBox(height: 7),

              Text(
                "The selected batch does not contain any active inspection parts.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF747B86),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildAssessmentBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        28,
        26,
        28,
        36,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // HEADER / PROGRESS
          Row(
            children: [

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    Text(
                      "Part Inspection",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                        FontWeight.w700,
                        color:
                        Color(0xFF202124),
                      ),
                    ),

                    SizedBox(height: 5),

                    Text(
                      "Scan each part using the connected handheld scanner.",
                      style: TextStyle(
                        fontSize: 12,
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
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color:
                  const Color(0xFFF1F4FA),
                  borderRadius:
                  BorderRadius.circular(10),
                ),
                child: Text(
                  "$completed / $totalParts Completed",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF3155C6),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // PROGRESS
          Container(
            width: double.infinity,
            height: 7,
            decoration: BoxDecoration(
              color: const Color(0xFFE6E9EE),
              borderRadius:
              BorderRadius.circular(20),
            ),
            child: FractionallySizedBox(
              alignment:
              Alignment.centerLeft,
              widthFactor: totalParts == 0
                  ? 0
                  : (completed / totalParts)
                  .clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color:
                  const Color(0xFF3155C6),
                  borderRadius:
                  BorderRadius.circular(20),
                ),
              ),
            ),
          ),

          const SizedBox(height: 26),

          // SCANNER CARD
          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(
              horizontal: 30,
              vertical: 42,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(18),
              border: Border.all(
                color:
                const Color(0xFFE1E5EA),
              ),
              boxShadow: [
                BoxShadow(
                  color:
                  Colors.black.withValues(
                    alpha: 0.025,
                  ),
                  blurRadius: 16,
                  offset:
                  const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [

                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color:
                    const Color(0xFFEAF0FF),
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 48,
                    color:
                    Color(0xFF3155C6),
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  "READY TO SCAN",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.w800,
                    letterSpacing: 0.7,
                    color:
                    Color(0xFF3155C6),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Scan the part barcode using the handheld scanner",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                    Color(0xFF747B86),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // TRIAL STATUS
          Row(
            children: [

              _trialStatusCard(
                "Trial 1",
                AppData.currentTrail > 1,
                AppData.currentTrail == 1,
              ),

              const SizedBox(width: 12),

              _trialStatusCard(
                "Trial 2",
                AppData.currentTrail > 2,
                AppData.currentTrail == 2,
              ),

              const SizedBox(width: 12),

              _trialStatusCard(
                "Trial 3",
                false,
                AppData.currentTrail == 3,
              ),
            ],
          ),

          // HIDDEN SCANNER INPUT
          SizedBox(
            width: 1,
            height: 1,
            child: TextField(
              controller: scannerController,
              focusNode: scannerFocus,

              autofocus: true,

              showCursor: false,

              enableSuggestions: false,
              autocorrect: false,

              keyboardType: TextInputType.text,

              textInputAction: TextInputAction.done,

              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),

              onSubmitted: (value) async {
                final barcode = value.trim();

                scannerController.clear();

                if (barcode.isEmpty) {
                  Future.delayed(
                    const Duration(milliseconds: 100),
                        () {
                      if (mounted) {
                        scannerFocus.requestFocus();
                      }
                    },
                  );

                  return;
                }

                await onBarcodeScanned(barcode);

                scannerController.clear();

                Future.delayed(
                  const Duration(milliseconds: 150),
                      () {
                    if (mounted) {
                      scannerFocus.requestFocus();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
