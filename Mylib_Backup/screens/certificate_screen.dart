import 'package:flutter/material.dart';
import '../services/app_data.dart';
import '../services/pdf_service.dart';
class CertificateScreen extends StatelessWidget {
  const CertificateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint(
      "Certificate Screen: ${AppData.certificateNo}",
    );
    final today = DateTime.now();

    final validTill =
    AppData.finalClassification == "NOT ACCEPTABLE"
        ? today
        : DateTime(
      today.year,
      today.month + 3,
      today.day,
    );

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
              "ARR Certificate",
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
              tooltip: "Certificate options",

              offset: const Offset(0, 48),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),

              color: Colors.white,

              onSelected: (value) async {
                try {
                  if (value == "download") {
                    await PdfService.downloadCertificate(
                      context: context,
                    );
                  }

                  if (value == "print") {
                    await PdfService.printCertificate();
                  }

                  if (value == "share") {
                    await PdfService.shareCertificate();
                  }
                } catch (e) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Unable to complete this action: $e",
                      ),
                      backgroundColor: const Color(0xFFC62828),
                    ),
                  );
                }
              },

              itemBuilder: (context) => const [
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
                        "Download Certificate",
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF202124),
                        ),
                      ),
                    ],
                  ),
                ),

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
                        "Print Certificate",
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
                        "Share Certificate",
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

        body: Container(
            color: const Color(0xFFF6F8FB),

            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 28,
              ),

              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1180,
                  ),

                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE2E7EF),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),

                    padding: const EdgeInsets.symmetric(
                      horizontal: 34,
                      vertical: 30,
                    ),

                    child: Column(
                      children: [
                        Image.asset(
                          "assets/full_logo.png",
                          height: 72,
                        ),

                        const SizedBox(height: 14),

                        const Text(
                          "ARR CERTIFICATE",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Color(0xFF202124),
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          "ATTRIBUTE REPEATABILITY & REPRODUCIBILITY",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.1,
                            color: Color(0xFF6F7785),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Container(
                          width: 70,
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3155C6),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Container(
                          padding: const EdgeInsets.all(20),

                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE3E7ED),
                            ),
                          ),

                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [

                              // CANDIDATE INFORMATION
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [

                                    const Text(
                                      "Candidate Information",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF202124),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    Row(
                                      children: [

                                        Expanded(
                                          child: infoCard(
                                            "Name",
                                            AppData.appraiseeName,
                                          ),
                                        ),

                                        const SizedBox(width: 14),

                                        Expanded(
                                          child: infoCard(
                                            "Employee Code",
                                            AppData.employeeCode,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    Row(
                                      children: [

                                        Expanded(
                                          child: infoCard(
                                            "Department",
                                            AppData.department,
                                          ),
                                        ),

                                        const SizedBox(width: 14),

                                        Expanded(
                                          child: infoCard(
                                            "Product Name",
                                            AppData.productName,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    Row(
                                      children: [

                                        Expanded(
                                          child: infoCard(
                                            "Batch",
                                            AppData.selectedBatchName,
                                          ),
                                        ),

                                        const SizedBox(width: 14),

                                        Expanded(
                                          child: infoCard(
                                            "Date of Test",
                                            "${today.day}/${today.month}/${today.year}",
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    Row(
                                      children: [

                                        Expanded(
                                          child: infoCard(
                                            "Certificate Number",
                                            AppData.certificateNo,
                                          ),
                                        ),

                                        const SizedBox(width: 14),

                                        Expanded(
                                          child: infoCard(
                                            "Certificate Validity",
                                            "${validTill.day}/${validTill.month}/${validTill.year}",
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    // Row(
                                    //   children: [
                                    //
                                    //     Expanded(
                                    //       child: infoCard(
                                    //         "Date of Joining",
                                    //         "01/01/2024",
                                    //       ),
                                    //     ),
                                    //
                                    //     const Spacer(),
                                    //   ],
                                    // ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 28),

                              // PHOTO
                              Container(
                                width: 150,
                                padding: const EdgeInsets.all(12),

                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE1E5EA),
                                  ),
                                ),

                                child: Column(
                                  children: [

                                    const Text(
                                      "Candidate Photo",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF596273),
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),

                                      child: Container(
                                        width: 120,
                                        height: 145,

                                        color: const Color(0xFFF1F3F6),

                                        child: AppData.candidatePhoto == null
                                            ? const Icon(
                                          Icons.person_outline_rounded,
                                          size: 52,
                                          color: Color(0xFF9AA4B2),
                                        )
                                            : Image.memory(
                                          AppData.candidatePhoto!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                const SizedBox(height: 40),

                        Container(
                          width: double.infinity,

                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE1E5EA),
                            ),
                          ),

                          clipBehavior: Clip.antiAlias,

                          child: Column(
                            children: [

                              // HEADER
                              Container(
                                color: const Color(0xFFF4F6F9),

                                child: Row(
                                  children: const [

                                    Expanded(
                                      flex: 32,
                                      child: TableHeading(
                                        "Test Parameter",
                                      ),
                                    ),

                                    Expanded(
                                      flex: 18,
                                      child: TableHeading(
                                        "Actual",
                                      ),
                                    ),

                                    Expanded(
                                      flex: 28,
                                      child: TableHeading(
                                        "Result",
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // FALSE ALERT
                              _certificateTableRow(
                                "False Alert",
                                "${AppData.falseAlertPercent.toStringAsFixed(2)}%",
                                AppData.falseAlertStatus(),
                              ),

                              // MISS RATE
                              _certificateTableRow(
                                "Miss Rate",
                                "${AppData.missRate.toStringAsFixed(2)}%",
                                AppData.missRateStatus(),
                              ),

                              // EFFECTIVENESS
                              _certificateTableRow(
                                "Effectiveness",
                                "${AppData.effectiveness.toStringAsFixed(2)}%",
                                AppData.effectivenessStatus(),
                              ),

                              // KAPPA
                              _certificateTableRow(
                                "Kappa",
                                "${AppData.kappa.toStringAsFixed(2)}%",
                                AppData.kappaStatus(),
                              ),

                              // FINAL RESULT
                              Container(
                                width: double.infinity,

                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 16,
                                ),

                                decoration: const BoxDecoration(
                                  color: Color(0xFFFAFBFC),
                                  border: Border(
                                    top: BorderSide(
                                      color: Color(0xFFE8EBF0),
                                    ),
                                  ),
                                ),

                                child: Row(
                                  children: [

                                    const Expanded(
                                      flex: 32,

                                      child: Text(
                                        "Final Result",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF303640),
                                        ),
                                      ),
                                    ),

                                    Expanded(
                                      flex: 46,

                                      child: Center(
                                        child: _resultBadge(
                                          AppData.finalClassification,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        SizedBox(
                          height: 44,

                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/ARR',
                                (route) => false,
                              );
                            },

                            icon: const Icon(
                              Icons.home_outlined,
                              size: 19,
                            ),

                            label: const Text(
                              "Back To Home",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              const Color(0xFFF5F7FA),

                              foregroundColor:
                              const Color(0xFF3155C6),

                              elevation: 0,

                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),

                              side: const BorderSide(
                                color: Color(0xFFE1E5EA),
                              ),

                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(9),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ),
        );
    }

  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),

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
Widget infoCard(String title, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 11,
    ),

    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: const Color(0xFFE3E7ED),
      ),
    ),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Text(
          title,
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
  );
}

class TableHeading extends StatelessWidget {
  final String text;

  const TableHeading(
      this.text, {
        super.key,
      });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),

      child: Text(
        text,
        textAlign: TextAlign.center,

        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF596273),
        ),
      ),
    );
  }
}
Widget _certificateTableRow(
    String parameter,
    String actual,
    String result,
    ) {
  return Container(
    decoration: const BoxDecoration(
      border: Border(
        top: BorderSide(
          color: Color(0xFFE8EBF0),
        ),
      ),
    ),

    child: Row(
      children: [

        Expanded(
          flex: 32,

          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),

            child: Text(
              parameter,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF303640),
              ),
            ),
          ),
        ),

        Expanded(
          flex: 18,

          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Color(0xFFE8EBF0),
                ),
                right: BorderSide(
                  color: Color(0xFFE8EBF0),
                ),
              ),
            ),

            padding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 12,
            ),

            child: Text(
              actual,
              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF202124),
              ),
            ),
          ),
        ),

        Expanded(
          flex: 28,

          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 12,
            ),

            child: Center(
              child: _resultBadge(result),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _resultBadge(String result) {
  final bool isAcceptable =
      result == "ACCEPTABLE";

  final bool isMarginal =
      result == "MARGINALLY ACCEPTABLE";

  final Color resultColor =
  isAcceptable
      ? const Color(0xFF237A3B)
      : isMarginal
      ? const Color(0xFF996C00)
      : const Color(0xFFC62828);

  final Color resultBackground =
  isAcceptable
      ? const Color(0xFFEAF7EE)
      : isMarginal
      ? const Color(0xFFFFF6DF)
      : const Color(0xFFFFEEEE);

  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 6,
    ),

    decoration: BoxDecoration(
      color: resultBackground,
      borderRadius: BorderRadius.circular(6),
    ),

    child: Text(
      result.isEmpty ? "—" : result,
      textAlign: TextAlign.center,

      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: resultColor,
      ),
    ),
  );
}