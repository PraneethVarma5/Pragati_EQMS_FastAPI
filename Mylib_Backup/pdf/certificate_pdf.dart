// import 'dart:typed_data';
// import 'package:flutter/services.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import '../services/app_data.dart';
// import '../models/arr_record.dart';
//
// class CertificatePdf {
//   CertificatePdf._();
//
//   static Future<Uint8List> generate({
//     ArrRecord? record,
//   }) async {
//     final pdf = pw.Document();
//
//     final logo = await rootBundle.load('assets/full_logo.png');
//     final logoImage = pw.MemoryImage(logo.buffer.asUint8List());
//
//     pw.MemoryImage? candidateImage;
//     if (AppData.candidatePhoto != null) {
//       candidateImage = pw.MemoryImage(
//         await AppData.candidatePhoto!.readAsBytes(),
//       );
//     }
//
//     final now = DateTime.now();
//     final validTill =
//     AppData.finalClassification == "NOT ACCEPTABLE"
//         ? now
//         : DateTime(
//       now.year,
//       now.month + 3,
//       now.day,
//     );
//
//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat(
//           242,
//           153,
//         ),
//         margin: const pw.EdgeInsets.all(6),
//         build: (_) => pw.Container(
//           decoration: pw.BoxDecoration(
//             border: pw.Border.all(color: PdfColors.blue900, width: 3),
//           ),
//           padding: const pw.EdgeInsets.all(6),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.center,
//               children: [
//
//                 pw.Image(
//                   logoImage,
//                   width: 22,
//                   height: 22,
//                 ),
//
//                 pw.SizedBox(height: 4),
//
//                 pw.Text(
//                   "DIGITAL ARR",
//                   style: pw.TextStyle(
//                     fontSize: 8,
//                     fontWeight: pw.FontWeight.bold,
//                   ),
//                 ),
//
//                 pw.Text(
//                   "Attribute Repeatability & Reproducibility",
//                   textAlign: pw.TextAlign.center,
//                   style: const pw.TextStyle(
//                     fontSize: 5,
//                   ),
//                 ),
//
//                 pw.Divider(),
//
//                 if (candidateImage != null)
//                   pw.Image(
//                     candidateImage,
//                     width: 28,
//                     height: 35,
//                   ),
//
//                 pw.SizedBox(height: 4),
//
//                 pw.Text(
//                   record?.appraisee ?? AppData.appraiseeName,
//                   style: pw.TextStyle(
//                     fontSize: 8,
//                     fontWeight: pw.FontWeight.bold,
//                   ),
//                 ),
//
//                 pw.Text(
//                   record?.employeeCode ?? AppData.employeeCode,
//                   style: const pw.TextStyle(
//                     fontSize: 7,
//                   ),
//                 ),
//
//                 pw.SizedBox(height: 4),
//
//                 _detailRow(
//                   "Dept",
//                   record?.department ?? AppData.department,
//                 ),
//
//                 _detailRow(
//                   "Product",
//                   record?.product ?? AppData.productName,
//                 ),
//
//                 _detailRow(
//                   "Batch",
//                   record?.batchName ?? AppData.selectedBatchName,
//                 ),
//
//                 _detailRow(
//                   "Class",
//                   record?.result ?? AppData.finalClassification,
//                 ),
//
//                 _detailRow(
//                   "FA %",
//                   "${record?.falseAlertPercent ?? AppData.falseAlertPercent}",
//                 ),
//
//                 _detailRow(
//                   "MR %",
//                   "${record?.missRate ?? AppData.missRate}",
//                 ),
//
//                 _detailRow(
//                   "EFF %",
//                   "${record?.effectiveness ?? AppData.effectiveness}",
//                 ),
//
//                 _detailRow(
//                   "KAPPA",
//                   "${record?.kappa ?? AppData.kappa}",
//                 ),
//
//                 _detailRow(
//                   "Valid",
//                   "${validTill.day}/${validTill.month}/${validTill.year}",
//                 ),
//
//                 pw.SizedBox(height: 5),
//
//                 pw.BarcodeWidget(
//                   barcode: pw.Barcode.qrCode(),
//                   data: '''
// DIGITAL ARR CERTIFICATE
//
// Certificate No : ${record?.certificateNo ?? AppData.certificateNo}
//
// Employee Code : ${record?.employeeCode ?? AppData.employeeCode}
//
// Employee Name : ${record?.appraisee ?? AppData.appraiseeName}
//
// Department : ${record?.department ?? AppData.department}
//
// Product : ${record?.product ?? AppData.productName}
//
// Batch : ${record?.batchName ?? AppData.selectedBatchName}
//
// Classification : ${record?.result ?? AppData.finalClassification}
//
// False Alert % : ${(record?.falseAlertPercent ?? AppData.falseAlertPercent).toStringAsFixed(2)}
//
// Miss Rate % : ${(record?.missRate ?? AppData.missRate).toStringAsFixed(2)}
//
// Effectiveness % : ${(record?.effectiveness ?? AppData.effectiveness).toStringAsFixed(2)}
//
// Kappa % : ${(record?.kappa ?? AppData.kappa).toStringAsFixed(2)}
//
// Issue Date : ${now.day}/${now.month}/${now.year}
//
// Valid Till : ${validTill.day}/${validTill.month}/${validTill.year}
// ''',
//                   width: 24,
//                   height: 24,
//                 ),
//
//                 pw.Text(
//                   "Scan to Verify",
//                   style: const pw.TextStyle(
//                     fontSize: 5,
//                   ),
//                 ),
//               ],
//             ),
//         ),
//       ),
//     );
//
//     return pdf.save();
//   }
//
//   static pw.Widget _detailRow(String title, String value) {
//     return pw.Padding(
//       padding: const pw.EdgeInsets.symmetric(vertical: 4),
//       child: pw.Row(
//         children: [
//           pw.SizedBox(
//             width: 42,
//             child: pw.Text(
//               title,
//               style: pw.TextStyle(
//                 fontSize: 6,
//                 fontWeight: pw.FontWeight.bold,
//               ),
//             ),
//           ),
//           pw.Expanded(
//             child: pw.Text(
//               value,
//               style: const pw.TextStyle(
//                 fontSize: 6,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
//
//

import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/arr_record.dart';
import '../services/app_data.dart';

class CertificatePdf {
CertificatePdf._();

static const PdfColor primaryBlue = PdfColor.fromInt(0xFF0B2E63);
static const PdfColor gold = PdfColor.fromInt(0xFFD6A63A);
static const PdfColor lightGrey = PdfColor.fromInt(0xFFF4F4F4);
static const PdfColor darkGrey = PdfColor.fromInt(0xFF555555);
static const double scale = 0.70;
static Future<Uint8List> generate({

ArrRecord? record,
}) async {
final pdf = pw.Document();

final logo = await rootBundle.load("assets/full_logo.png");
final logoImage = pw.MemoryImage(
logo.buffer.asUint8List(),
);

// pw.MemoryImage? candidateImage;
//
// if (AppData.candidatePhoto != null) {
// candidateImage = pw.MemoryImage(
// await AppData.candidatePhoto!.readAsBytes(),
// );
// }
  pw.MemoryImage? candidateImage;

  if (AppData.candidatePhoto != null) {
    candidateImage = pw.MemoryImage(
      AppData.candidatePhoto!,
    );
  }
DateTime assessmentDate;

if (record != null && record.date.contains('/')) {
  final parts = record.date.split('/');

  assessmentDate = DateTime(
    int.parse(parts[2]),
    int.parse(parts[1]),
    int.parse(parts[0]),
  );
} else {
  assessmentDate = DateTime.now();
}
//
// final classification =
//     record?.result ?? AppData.finalClassification;

  final bool isPreviousRecord = record != null;

  final classification =
  isPreviousRecord
      ? record.result
      : AppData.finalClassification;

  DateTime validTill;

  switch (classification.toUpperCase()) {

    case "ACCEPTABLE":

      validTill = DateTime(
        assessmentDate.year,
        assessmentDate.month + 3,
        assessmentDate.day,
      );

      break;

    case "MARGINALLY ACCEPTABLE":

      validTill = DateTime(
        assessmentDate.year,
        assessmentDate.month + 1,
        assessmentDate.day,
      );

      break;

    default:

    // NOT ACCEPTABLE
      validTill = assessmentDate;

  }

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),

      build: (context) {

        return pw.Center(
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [

              _buildFrontCard(
                logoImage: logoImage,
                candidateImage: candidateImage,
                isPreviousRecord: isPreviousRecord,
                record: record,
              ),

              pw.SizedBox(width: 12*scale),

              _buildBackCard(
                isPreviousRecord: isPreviousRecord,
                record: record,
                assessmentDate: assessmentDate,
                validTill: validTill,
              ),

            ],
          ),
        );

      },
    ),
  );
return pdf.save();
}

// static const double cardWidth = 240;
// static const double cardHeight = 380;

  // ATM Card Size
  static const double cardWidth = 240 * scale;
  static const double cardHeight = 380 * scale;

  static pw.Widget _buildFrontCard({
  required pw.MemoryImage logoImage,
  required pw.MemoryImage? candidateImage,
  required bool isPreviousRecord,
  ArrRecord? record,
}) {
return pw.Container(
width: cardWidth,
height: cardHeight,
decoration: pw.BoxDecoration(
color: PdfColors.white,
borderRadius: pw.BorderRadius.circular(18*scale),
border: pw.Border.all(
color: primaryBlue,
width: 2,
),
),
child: pw.Stack(
children: [



// White Cut
// pw.Positioned(
// top: -42,
// right: -42,
// child: pw.Container(
// width: 150,
// height: 150,
// decoration: const pw.BoxDecoration(
// color: PdfColors.white,
// shape: pw.BoxShape.circle,
// ),
// ),
// ),

pw.Padding(
  padding: pw.EdgeInsets.all(16 * scale),
child: pw.Column(
crossAxisAlignment: pw.CrossAxisAlignment.start,
children: [

pw.Image(
logoImage,
width: 95*scale,
height: 40*scale,
fit: pw.BoxFit.contain,
),

pw.SizedBox(height: 8*scale),

pw.Center(
child: pw.Text(
"DIGITAL ARR",
style: pw.TextStyle(
color: primaryBlue,
fontSize: 20*scale,
fontWeight: pw.FontWeight.bold,
),
),
),

pw.Center(
child: pw.Text(
"ATTRIBUTE REPEATABILITY & REPRODUCIBILITY",
textAlign: pw.TextAlign.center,
style: pw.TextStyle(
fontSize: 7*scale,
color: darkGrey,
),
),
),

pw.SizedBox(height: 8*scale),

pw.Row(
crossAxisAlignment: pw.CrossAxisAlignment.start,
children: [

pw.Container(
width: 78*scale,
height: 96*scale,
decoration: pw.BoxDecoration(
borderRadius: pw.BorderRadius.circular(10),
border: pw.Border.all(
color: primaryBlue,
width: 1.5*scale,
),
),
child: candidateImage == null
? pw.Center(
child: pw.Text(
"PHOTO",
style: const pw.TextStyle(
fontSize: 9*scale,
),
),
)
: pw.ClipRRect(
horizontalRadius: 8*scale,
verticalRadius: 8*scale,
child: pw.Image(
candidateImage,
fit: pw.BoxFit.cover,
),
),
),

pw.SizedBox(width: 12*scale),

  pw.Expanded(
    child: pw.Column(
      children: [

        _infoTile(
          "NAME",
          isPreviousRecord
              ? record!.appraisee
              : AppData.appraiseeName,
        ),

        _infoTile(
          "EMPLOYEE",
          isPreviousRecord
              ? record!.employeeCode
              : AppData.employeeCode,
        ),

        _infoTile(
          "DEPARTMENT",
          isPreviousRecord
              ? record!.department
              : AppData.department,
        ),

        _infoTile(
          "PRODUCT",
          isPreviousRecord
              ? record!.product
              : AppData.productName,
        ),

        _infoTile(
          "BATCH",
          isPreviousRecord
              ? record!.batchName
              : AppData.selectedBatchName,
        ),

      ],
    ),
  ),
],
),

pw.Spacer(),

pw.Center(
child: pw.Text(
"CLASSIFICATION",
style: pw.TextStyle(
color: gold,
fontWeight: pw.FontWeight.bold,
fontSize: 9*scale,
),
),
),

pw.SizedBox(height: 5*scale),

pw.Container(
width: double.infinity,
padding: const pw.EdgeInsets.symmetric(
vertical: 10*scale,
),
decoration: pw.BoxDecoration(
color: primaryBlue,
borderRadius: pw.BorderRadius.circular(8*scale),
),
child: pw.Center(
child: pw.Text(
  isPreviousRecord
      ? record!.result
      : AppData.finalClassification,
  style: pw.TextStyle(

color: PdfColors.white,
fontWeight: pw.FontWeight.bold,
fontSize: 18*scale,
),
),
),
),

pw.SizedBox(height: 10*scale),

pw.Align(
alignment: pw.Alignment.centerRight,
child: pw.Container(
width: 52*scale,
height: 52*scale,

// decoration: pw.BoxDecoration(
// color: gold,
// shape: pw.BoxShape.circle,
// ),
// child: pw.Center(
// child: pw.Text(
// "QUALITY",
// textAlign: pw.TextAlign.center,
// style: pw.TextStyle(
// color: PdfColors.white,
// fontSize: 7*scale,
// fontWeight: pw.FontWeight.bold,
// ),
// ),
// ),
 ),
),
],
),
),
],
),
);
}
static pw.Widget _buildBackCard({
  required bool isPreviousRecord,
  ArrRecord? record,
  required DateTime assessmentDate,
  required DateTime validTill,
}) {
  final falseAlert =
      record?.falseAlertPercent ?? AppData.falseAlertPercent;

  final missRate =
      record?.missRate ?? AppData.missRate;

  final effectiveness =
      record?.effectiveness ?? AppData.effectiveness;

  final kappa =
      record?.kappa ?? AppData.kappa;

return pw.Container(
width: cardWidth,
height: cardHeight,
decoration: pw.BoxDecoration(
color: PdfColors.white,
borderRadius: pw.BorderRadius.circular(18*scale),
border: pw.Border.all(
color: primaryBlue,
width: 2*scale,
),
),
child: pw.Stack(
children: [

// Bottom Gold Curve

// White Cut
// pw.Positioned(
// bottom: -40,
// left: -40,
// child: pw.Container(
// width: 145,
// height: 145,
// decoration: const pw.BoxDecoration(
// color: PdfColors.white,
// shape: pw.BoxShape.circle,
// ),
// ),
// ),

pw.Padding(
padding: const pw.EdgeInsets.all(10*scale),
child: pw.Column(
crossAxisAlignment: pw.CrossAxisAlignment.start,
children: [

pw.Center(
child: pw.Text(
"CERTIFICATE DETAILS",
style: pw.TextStyle(
fontWeight: pw.FontWeight.bold,
fontSize: 16*scale,
color: primaryBlue,
),
),
),

pw.SizedBox(height: 12*scale),

  _detailRow(
    "Certificate No",
    isPreviousRecord
        ? record!.certificateNo
        : AppData.certificateNo,
  ),

  _detailRow(
    "Assessment Date",
    record?.date ??
        "${assessmentDate.day}/${assessmentDate.month}/${assessmentDate.year}",
  ),

_detailRow(
"Valid Till",
"${validTill.day}/${validTill.month}/${validTill.year}",
),


pw.SizedBox(height: 15*scale),

pw.Container(
width: double.infinity,
padding: const pw.EdgeInsets.all(8*scale),
decoration: pw.BoxDecoration(
color: lightGrey,
borderRadius: pw.BorderRadius.circular(8*scale),
),
child: pw.Column(
children: [

pw.Text(
"Evaluation Metrics",
style: pw.TextStyle(
fontWeight: pw.FontWeight.bold,
color: primaryBlue,
fontSize: 11*scale,
),
),

pw.SizedBox(height: 8*scale),

  _metricRow(
    "False Alert (%)",
    "${falseAlert.toStringAsFixed(2)} %",
  ),

  _metricRow(
    "Miss Rate (%)",
    "${missRate.toStringAsFixed(2)} %",
  ),
  _metricRow(
    "Effectiveness",
    "${effectiveness.toStringAsFixed(2)} %",
  ),
  _metricRow(
    "Classification",
    isPreviousRecord
        ? record!.result
        : AppData.finalClassification,
  ),
  _metricRow(
    "Kappa",
    "${kappa.toStringAsFixed(2)} %",
  ),
],
),
),

pw.Spacer(),

pw.Row(
mainAxisAlignment:
pw.MainAxisAlignment.spaceBetween,
children: [

pw.Column(
children: [

pw.Container(
width: 80*scale,
height: 1*scale,
color: PdfColors.black,
),

pw.SizedBox(height: 4*scale),

pw.Text(
"Authorized Signatory",
style: const pw.TextStyle(
fontSize: 8*scale,
),
),
],
),

  pw.BarcodeWidget(
    barcode: pw.Barcode.qrCode(),
    data: '''
DIGITAL ARR CERTIFICATE

Certificate No : ${
        isPreviousRecord
            ? record!.certificateNo
            : AppData.certificateNo
    }

Employee Code : ${
        isPreviousRecord
            ? record!.employeeCode
            : AppData.employeeCode
    }

Candidate : ${
        isPreviousRecord
            ? record!.appraisee
            : AppData.appraiseeName
    }

Department : ${
        isPreviousRecord
            ? record!.department
            : AppData.department
    }

Product : ${
        isPreviousRecord
            ? record!.product
            : AppData.productName
    }

Batch : ${
        isPreviousRecord
            ? record!.batchName
            : AppData.selectedBatchName
    }

Classification : ${
        isPreviousRecord
            ? record!.result
            : AppData.finalClassification
    }

False Alert : ${
        (isPreviousRecord
            ? record!.falseAlertPercent
            : AppData.falseAlertPercent).toStringAsFixed(2)
    }%

Miss Rate : ${
        (isPreviousRecord
            ? record!.missRate
            : AppData.missRate).toStringAsFixed(2)
    }%

Effectiveness : ${
        (isPreviousRecord
            ? record!.effectiveness
            : AppData.effectiveness).toStringAsFixed(2)
    }%

Kappa : ${
        (isPreviousRecord
            ? record!.kappa
            : AppData.kappa).toStringAsFixed(2)
    }%

Issue Date : ${
        isPreviousRecord
            ? record!.date
            : "${assessmentDate.day}/${assessmentDate.month}/${assessmentDate.year}"
    }

Valid Till : ${validTill.day}/${validTill.month}/${validTill.year}
''',
    width: 42*scale,
    height: 42*scale,
  ),
],
),

pw.SizedBox(height: 10*scale),

pw.Center(
child: pw.Text(
"Scan QR to Verify Certificate",
style: pw.TextStyle(
fontSize: 8*scale,
color: darkGrey,
),
),
),

pw.SizedBox(height: 8*scale),

pw.Center(
child: pw.Text(
"Pragati RRD PVT.LTD",
style: pw.TextStyle(
fontWeight: pw.FontWeight.bold,
fontSize: 9*scale,
color: primaryBlue,
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
static pw.Widget _infoTile(
    String title,
    String value,
    ) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6*scale),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [

        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 7*scale,
            color: darkGrey,
            fontWeight: pw.FontWeight.bold,
          ),
        ),

        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(
            horizontal: 6*scale,
            vertical: 4*scale,
          ),
          decoration: pw.BoxDecoration(
            color: lightGrey,
            borderRadius: pw.BorderRadius.circular(4*scale),
          ),
          child: pw.Text(
            value,
            style: const pw.TextStyle(
              fontSize: 9*scale,
            ),
          ),
        ),
      ],
    ),
  );
}

static pw.Widget _detailRow(
    String title,
    String value,
    ) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6*scale),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [

        pw.SizedBox(
          width: 85*scale,
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9*scale,
              color: primaryBlue,
            ),
          ),
        ),

        pw.Text(
          ": ",
          style: const pw.TextStyle(fontSize: 9*scale),
        ),

        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(
              fontSize: 9*scale,
            ),
          ),
        ),
      ],
    ),
  );
}

static pw.Widget _metricRow(
    String metric,
    String value,
    ) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(
      vertical: 2*scale,
    ),
    child: pw.Row(
      children: [

        pw.Expanded(
          child: pw.Text(
            metric,
            style: const pw.TextStyle(
              fontSize: 8*scale,
            ),
          ),
        ),

        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 8*scale,
            fontWeight: pw.FontWeight.bold,
            color: primaryBlue,
          ),
        ),
      ],
    ),
  );
}
}