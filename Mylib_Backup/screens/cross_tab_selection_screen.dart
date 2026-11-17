import 'package:flutter/material.dart';
import '../models/arr_record.dart';
import '../services/app_data.dart';
import '../services/cross_tab_service.dart';
import 'cross_tab_result_screen.dart';

class CrossTabSelectionScreen extends StatefulWidget {
  const CrossTabSelectionScreen({super.key});

  @override
  State<CrossTabSelectionScreen> createState() =>
      _CrossTabSelectionScreenState();
}

class _CrossTabSelectionScreenState
    extends State<CrossTabSelectionScreen> {

  final TextEditingController searchController =
  TextEditingController();

  final List<ArrRecord> selected = [];

  String search = "";
  // @override
  // Widget build(BuildContext context) {
  //
  //   final records = AppData.previousArrs.where((e) {
  //
  //     return e.employeeCode
  //         .toLowerCase()
  //         .contains(search.toLowerCase()) ||
  //         e.appraisee
  //             .toLowerCase()
  //             .contains(search.toLowerCase());
  //
  //   }).toList();
  //
  //   return Scaffold(
  //
  //     appBar: AppBar(
  //       title: const Text("Cross Tab Selection"),
  //     ),
  //
  //     body: Column(
  //
  //       children: [
  //
  //         Padding(
  //
  //           padding: const EdgeInsets.all(12),
  //
  //           child: TextField(
  //
  //             controller: searchController,
  //
  //             decoration: InputDecoration(
  //
  //               hintText: "Search Candidate",
  //
  //               prefixIcon:
  //               const Icon(Icons.search),
  //
  //               border: OutlineInputBorder(
  //
  //                 borderRadius:
  //                 BorderRadius.circular(12),
  //
  //               ),
  //
  //             ),
  //
  //             onChanged: (value) {
  //
  //               setState(() {
  //
  //                 search = value;
  //
  //               });
  //
  //             },
  //
  //           ),
  //
  //         ),
  //
  //         Padding(
  //
  //           padding: const EdgeInsets.symmetric(
  //             horizontal: 12,
  //           ),
  //
  //           child: Row(
  //
  //             children: [
  //
  //               ElevatedButton.icon(
  //
  //                 onPressed: () {
  //
  //                   setState(() {
  //
  //                     selected
  //                       ..clear()
  //                       ..addAll(records);
  //
  //                   });
  //
  //                 },
  //
  //                 icon:
  //                 const Icon(Icons.select_all),
  //
  //                 label:
  //                 const Text("Select All"),
  //
  //               ),
  //
  //               const SizedBox(width: 10),
  //
  //               ElevatedButton.icon(
  //
  //                 onPressed: () {
  //
  //                   setState(() {
  //
  //                     selected.clear();
  //
  //                   });
  //
  //                 },
  //
  //                 icon: const Icon(Icons.clear),
  //
  //                 label:
  //                 const Text("Clear"),
  //
  //               ),
  //
  //             ],
  //
  //           ),
  //
  //         ),
  //
  //         const SizedBox(height: 10),
  //
  //         Expanded(
  //
  //           child: ListView.builder(
  //
  //             itemCount: records.length,
  //
  //             itemBuilder: (context, index) {
  //
  //               final record = records[index];
  //
  //               final checked =
  //               selected.contains(record);
  //
  //               return CheckboxListTile(
  //
  //                 value: checked,
  //
  //                 title: Text(record.appraisee),
  //
  //                 subtitle: Column(
  //
  //                   crossAxisAlignment:
  //                   CrossAxisAlignment.start,
  //
  //                   children: [
  //
  //                     Text(
  //                         "Employee : ${record.employeeCode}"),
  //
  //                     Text(
  //                         "Batch : ${record.batchName}"),
  //
  //                     Text(
  //                         "Result : ${record.result}"),
  //
  //                   ],
  //
  //                 ),
  //
  //                 onChanged: (value) {
  //
  //                   setState(() {
  //
  //                     if (value == true) {
  //
  //                       selected.add(record);
  //
  //                     } else {
  //
  //                       selected.remove(record);
  //
  //                     }
  //
  //                   });
  //
  //                 },
  //
  //               );
  //
  //             },
  //
  //           ),
  //
  //         ),
  //
  //         SafeArea(
  //
  //           child: Padding(
  //
  //             padding: const EdgeInsets.all(12),
  //
  //             child: SizedBox(
  //
  //               width: double.infinity,
  //
  //               child: ElevatedButton.icon(
  //
  //                 icon:
  //                 const Icon(Icons.calculate),
  //
  //                 label:
  //                 const Text("Calculate Cross Tab"),
  //
  //                 onPressed: () {
  //                   if (selected.length < 2) {
  //                     ScaffoldMessenger.of(context).showSnackBar(
  //                       const SnackBar(
  //                         content: Text(
  //                           "Select at least two candidates.",
  //                         ),
  //                       ),
  //                     );
  //                     return;
  //                   }
  //
  //                   final batch = selected.first.batchId;
  //
  //                   final valid = selected.every(
  //                         (e) => e.batchId == batch,
  //                   );
  //
  //                   if (!valid) {
  //                     ScaffoldMessenger.of(context).showSnackBar(
  //                       const SnackBar(
  //                         content: Text(
  //                           "Selected candidates must belong to the same batch.",
  //                         ),
  //                       ),
  //                     );
  //                     return;
  //                   }
  //
  //                   final result =
  //                   CrossTabService.generate(selected);
  //
  //                   Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                       builder: (_) => CrossTabResultScreen(
  //                         result: result,
  //                         selectedRecords: selected,
  //                       ),
  //                     ),
  //                   );
  //                 },
  //               ),
  //
  //             ),
  //
  //           ),
  //
  //         ),
  //
  //       ],
  //
  //     ),
  //
  //   );
  //
  // }

  @override
  Widget build(BuildContext context) {
    final records = AppData.previousArrs.where((e) {
      return e.employeeCode
          .toLowerCase()
          .contains(search.toLowerCase()) ||
          e.appraisee
              .toLowerCase()
              .contains(search.toLowerCase());
    }).toList();

    final selectedCount = selected.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF202124),
          ),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Cross Tab Analysis",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202124),
              ),
            ),
            Text(
              "Select inspection records for comparison",
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF777D86),
              ),
            ),
          ],
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1200,
          ),

          child: Column(
            children: [

              // PAGE HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  28,
                  26,
                  28,
                  18,
                ),

                child: Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(22),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                    BorderRadius.circular(18),

                    border: Border.all(
                      color: const Color(0xFFE1E4E8),
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.035,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [

                      Container(
                        width: 54,
                        height: 54,

                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF0FF),
                          borderRadius:
                          BorderRadius.circular(14),
                        ),

                        child: const Icon(
                          Icons.table_chart_outlined,
                          color: Color(0xFF3155C6),
                          size: 28,
                        ),
                      ),

                      const SizedBox(width: 16),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Cross Tab Selection",
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight:
                                FontWeight.w700,
                                color:
                                Color(0xFF202124),
                              ),
                            ),

                            SizedBox(height: 5),

                            Text(
                              "Choose two or more candidates from the same batch to generate a cross tab report.",
                              style: TextStyle(
                                fontSize: 13,
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
                          vertical: 10,
                        ),

                        decoration: BoxDecoration(
                          color:
                          const Color(0xFFF1F4FA),
                          borderRadius:
                          BorderRadius.circular(10),
                        ),

                        child: Row(
                          mainAxisSize:
                          MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.checklist_rounded,
                              size: 18,
                              color:
                              Color(0xFF3155C6),
                            ),

                            const SizedBox(width: 7),

                            Text(
                              "$selectedCount selected",
                              style:
                              const TextStyle(
                                fontSize: 12.5,
                                fontWeight:
                                FontWeight.w700,
                                color:
                                Color(0xFF3155C6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // SEARCH + ACTION BAR
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                ),

                child: Container(
                  padding: const EdgeInsets.all(12),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                    BorderRadius.circular(14),

                    border: Border.all(
                      color: const Color(0xFFE1E4E8),
                    ),
                  ),

                  child: Row(
                    children: [

                      Expanded(
                        child: TextField(
                          controller:
                          searchController,

                          onChanged: (value) {
                            setState(() {
                              search = value;
                            });
                          },

                          decoration:
                          InputDecoration(
                            hintText:
                            "Search by employee ID or candidate name",

                            prefixIcon:
                            const Icon(
                              Icons.search_rounded,
                              size: 21,
                            ),

                            filled: true,

                            fillColor:
                            const Color(0xFFF7F8FA),

                            border:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                10,
                              ),
                              borderSide:
                              BorderSide.none,
                            ),

                            enabledBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                10,
                              ),
                              borderSide:
                              const BorderSide(
                                color:
                                Color(0xFFE2E5E9),
                              ),
                            ),

                            focusedBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                10,
                              ),
                              borderSide:
                              const BorderSide(
                                color:
                                Color(0xFF3155C6),
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      OutlinedButton.icon(
                        onPressed: records.isEmpty
                            ? null
                            : () {
                          setState(() {
                            selected
                              ..clear()
                              ..addAll(records);
                          });
                        },

                        icon: const Icon(
                          Icons.select_all_rounded,
                          size: 18,
                        ),

                        label:
                        const Text("Select All"),

                        style:
                        OutlinedButton.styleFrom(
                          foregroundColor:
                          const Color(0xFF3155C6),

                          side: const BorderSide(
                            color: Color(0xFFD5DCF1),
                          ),

                          backgroundColor:
                          const Color(0xFFF8FAFF),

                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 14,
                          ),

                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              10,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      OutlinedButton.icon(
                        onPressed:
                        selected.isEmpty
                            ? null
                            : () {
                          setState(() {
                            selected.clear();
                          });
                        },

                        icon: const Icon(
                          Icons.clear_all_rounded,
                          size: 18,
                        ),

                        label: const Text("Clear"),

                        style:
                        OutlinedButton.styleFrom(
                          foregroundColor:
                          const Color(0xFF666D76),

                          side: const BorderSide(
                            color: Color(0xFFE1E4E8),
                          ),

                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 14,
                          ),

                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // RECORD LIST
              Expanded(
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 28,
                  ),

                  child: Container(
                    width: double.infinity,

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                      BorderRadius.circular(16),

                      border: Border.all(
                        color:
                        const Color(0xFFE1E4E8),
                      ),
                    ),

                    child: records.isEmpty
                        ? const Center(
                      child: Column(
                        mainAxisSize:
                        MainAxisSize.min,
                        children: [
                          Icon(
                            Icons
                                .search_off_rounded,
                            size: 48,
                            color:
                            Color(0xFFB0B6BF),
                          ),

                          SizedBox(height: 12),

                          Text(
                            "No inspection records found",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight.w600,
                              color:
                              Color(0xFF555B64),
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            "Try a different employee ID or candidate name.",
                            style: TextStyle(
                              fontSize: 12,
                              color:
                              Color(0xFF858C95),
                            ),
                          ),
                        ],
                      ),
                    )
                        : ListView.separated(
                      padding:
                      const EdgeInsets.all(
                        14,
                      ),

                      itemCount:
                      records.length,

                      separatorBuilder:
                          (_, __) =>
                      const SizedBox(
                        height: 8,
                      ),

                      itemBuilder:
                          (context, index) {
                        final record =
                        records[index];

                        final checked =
                        selected.contains(
                          record,
                        );

                        final isAcceptable =
                            record.result ==
                                "ACCEPTABLE";

                        final isMarginal =
                            record.result ==
                                "MARGINALLY ACCEPTABLE";

                        final resultColor =
                        isAcceptable
                            ? const Color(
                          0xFF249653,
                        )
                            : isMarginal
                            ? const Color(
                          0xFFD88A24,
                        )
                            : const Color(
                          0xFFD94A4A,
                        );

                        final resultBackground =
                        isAcceptable
                            ? const Color(
                          0xFFEAF7EF,
                        )
                            : isMarginal
                            ? const Color(
                          0xFFFFF4E5,
                        )
                            : const Color(
                          0xFFFDECEC,
                        );

                        return InkWell(
                          borderRadius:
                          BorderRadius
                              .circular(
                            12,
                          ),

                          onTap: () {
                            setState(() {
                              if (checked) {
                                selected.remove(
                                  record,
                                );
                              } else {
                                selected.add(
                                  record,
                                );
                              }
                            });
                          },

                          child: Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),

                            decoration:
                            BoxDecoration(
                              color: checked
                                  ? const Color(
                                0xFFF8FAFF,
                              )
                                  : Colors.white,

                              borderRadius:
                              BorderRadius
                                  .circular(
                                12,
                              ),

                              border:
                              Border.all(
                                color: checked
                                    ? const Color(
                                  0xFFBFCBF0,
                                )
                                    : const Color(
                                  0xFFE5E7EA,
                                ),
                              ),
                            ),

                            child: Row(
                              children: [

                                Checkbox(
                                  value: checked,

                                  activeColor:
                                  const Color(
                                    0xFF3155C6,
                                  ),

                                  shape:
                                  RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                      5,
                                    ),
                                  ),

                                  onChanged:
                                      (value) {
                                    setState(() {
                                      if (value ==
                                          true) {
                                        selected
                                            .add(
                                          record,
                                        );
                                      } else {
                                        selected
                                            .remove(
                                          record,
                                        );
                                      }
                                    });
                                  },
                                ),

                                const SizedBox(
                                  width: 8,
                                ),

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
                                    BorderRadius
                                        .circular(
                                      11,
                                    ),
                                  ),

                                  child:
                                  const Icon(
                                    Icons
                                        .person_outline_rounded,
                                    color:
                                    Color(
                                      0xFF3155C6,
                                    ),
                                    size: 22,
                                  ),
                                ),

                                const SizedBox(
                                  width: 14,
                                ),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                    children: [

                                      Text(
                                        record
                                            .appraisee,
                                        style:
                                        const TextStyle(
                                          fontSize:
                                          14.5,
                                          fontWeight:
                                          FontWeight
                                              .w700,
                                          color:
                                          Color(
                                            0xFF202124,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 5,
                                      ),

                                      Text(
                                        "${record.employeeCode}  •  ${record.batchName}",
                                        style:
                                        const TextStyle(
                                          fontSize:
                                          12,
                                          color:
                                          Color(
                                            0xFF747B86,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  padding:
                                  const EdgeInsets
                                      .symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),

                                  decoration:
                                  BoxDecoration(
                                    color:
                                    resultBackground,

                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                      8,
                                    ),
                                  ),

                                  child: Text(
                                    record.result,
                                    style:
                                    TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                      FontWeight
                                          .w700,
                                      color:
                                      resultColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // BOTTOM ACTION
              SafeArea(
                child: Padding(
                  padding:
                  const EdgeInsets.fromLTRB(
                    28,
                    14,
                    28,
                    22,
                  ),

                  child: Row(
                    children: [

                      Expanded(
                        child: Text(
                          selectedCount < 2
                              ? "Select at least 2 candidates from the same batch."
                              : "$selectedCount candidates selected",

                          style: TextStyle(
                            fontSize: 12.5,
                            color: selectedCount < 2
                                ? const Color(
                              0xFF747B86,
                            )
                                : const Color(
                              0xFF3155C6,
                            ),
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(width: 20),

                      SizedBox(
                        width: 230,

                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons
                                .analytics_outlined,
                          ),

                          label: const Text(
                            "Calculate Cross Tab",
                          ),

                          onPressed: () {
                            if (selected.length <
                                2) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Select at least two candidates.",
                                  ),
                                ),
                              );
                              return;
                            }

                            final batch =
                                selected.first.batchId;

                            final valid =
                            selected.every(
                                  (e) =>
                              e.batchId ==
                                  batch,
                            );

                            if (!valid) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Selected candidates must belong to the same batch.",
                                  ),
                                ),
                              );
                              return;
                            }

                            final result =
                            CrossTabService
                                .generate(
                              selected,
                            );

                            Navigator.pushNamed(
                              context,
                              '/ARR/crossTabResult',
                              arguments: {
                                'result': result,
                                'selectedRecords': selected,
                              },
                            );
                          },

                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(
                              0xFF3155C6,
                            ),

                            foregroundColor:
                            Colors.white,

                            elevation: 1,

                            padding:
                            const EdgeInsets
                                .symmetric(
                              vertical: 15,
                            ),

                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(
                                11,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}