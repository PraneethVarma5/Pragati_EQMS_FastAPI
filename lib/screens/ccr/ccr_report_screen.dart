import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:file_saver/file_saver.dart';
import '../../services/ccr/ccr_api_client.dart';

class CcrReportScreen extends StatefulWidget {
  const CcrReportScreen({
    super.key,
    required this.ccrId,
  });

  final String ccrId;

  @override
  State<CcrReportScreen> createState() =>
      _CcrReportScreenState();
}

class _CcrReportScreenState
    extends State<CcrReportScreen> {


  bool _loading = true;
  bool _downloading = false;

  String? _error;

  Map<String, dynamic>? _ccr;
  Map<String, dynamic>? _customerView;
  Map<String, dynamic>? _supplierView;
  Map<String, dynamic>? _containment;
  Map<String, dynamic>? _closure;

  List<Map<String, dynamic>> _sorting =
  <Map<String, dynamic>>[];

  List<Map<String, dynamic>> _assignments =
  <Map<String, dynamic>>[];

  List<Map<String, dynamic>> _categories =
  <Map<String, dynamic>>[];

  List<Map<String, dynamic>> _causes =
  <Map<String, dynamic>>[];

  List<Map<String, dynamic>> _validations =
  <Map<String, dynamic>>[];

  List<Map<String, dynamic>> _whyAnalyses =
  <Map<String, dynamic>>[];

  List<Map<String, dynamic>> _whySteps =
  <Map<String, dynamic>>[];

  List<Map<String, dynamic>> _actions =
  <Map<String, dynamic>>[];

  List<Map<String, dynamic>> _attachments =
  <Map<String, dynamic>>[];
  Map<String, dynamic>?
  _customerComplaintDocument;

  Map<String, dynamic>?
  _customerFormat;

  bool _downloadingCustomerDocument = false;
  bool _downloadingCustomerFormat = false;
  List<Map<String, dynamic>> _actionEvidence =
  <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ============================================================
  // LOAD COMPLETE CCR REPORT
  // ============================================================

  Future<void> _load() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dynamic response =
      await CcrApiClient.get(
        '/cases/${widget.ccrId}/report',
        authenticated: false,
      );

      if (response is! Map) {
        throw Exception(
          'Invalid CCR report response from server.',
        );
      }

      final Map<String, dynamic> report =
      Map<String, dynamic>.from(response);

      Map<String, dynamic>? asMap(dynamic value) {
        if (value is Map) {
          return Map<String, dynamic>.from(value);
        }
        return null;
      }

      List<Map<String, dynamic>> asMapList(dynamic value) {
        if (value is! List) {
          return <Map<String, dynamic>>[];
        }

        return value
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
        )
            .toList();
      }

      final Map<String, dynamic>? ccr =
      asMap(report['case']);

      if (ccr == null) {
        throw Exception(
          'CCR case details were not returned by the server.',
        );
      }

      final Map<String, dynamic>? customerView =
      asMap(report['customer_view']);

      final Map<String, dynamic>? supplierView =
      asMap(report['supplier_view']);

      final Map<String, dynamic>? containment =
      asMap(report['containment']);

      final List<Map<String, dynamic>> sorting =
      asMapList(report['sorting']);

      final List<Map<String, dynamic>> assignments =
      asMapList(report['assignments']);

      final List<Map<String, dynamic>> categories =
      asMapList(report['categories']);

      final List<Map<String, dynamic>> causes =
      asMapList(report['causes']);

      final List<Map<String, dynamic>> validations =
      asMapList(report['validations']);

      final List<Map<String, dynamic>> whyAnalyses =
      asMapList(report['why_analyses']);

      final List<Map<String, dynamic>> whySteps =
      asMapList(report['why_steps']);

      final List<Map<String, dynamic>> actions =
      asMapList(report['actions']);

      final List<Map<String, dynamic>> attachments =
      asMapList(report['attachments']);

      final List<Map<String, dynamic>> actionEvidence =
      asMapList(report['action_evidence']);

      final Map<String, dynamic>? closure =
      asMap(report['closure']);

      if (!mounted) {
        return;
      }

      setState(() {
        _ccr = ccr;

        _customerView = customerView;
        _supplierView = supplierView;

        _containment = containment;
        _sorting = sorting;

        _assignments = assignments;

        _categories = categories;
        _causes = causes;
        _validations = validations;

        _whyAnalyses = whyAnalyses;
        _whySteps = whySteps;

        _actions = actions;
        _attachments = attachments;

        _customerComplaintDocument = null;
        _customerFormat = null;

        for (final attachment in attachments) {
          final String attachmentType =
              attachment['attachment_type']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
                  '';

          if (attachmentType ==
              'customer_complaint_document') {
            _customerComplaintDocument = attachment;
          }

          if (attachmentType == 'customer_format') {
            _customerFormat = attachment;
          }
        }

        _actionEvidence = actionEvidence;
        _closure = closure;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = _cleanError(e);
      });
    }
  }

  // ============================================================
  // DOWNLOAD
  // ============================================================

  Future<void> _downloadReport() async {
    if (_downloading ||
        _ccr == null) {
      return;
    }

    setState(() {
      _downloading = true;
    });

    try {
      final Uint8List pdfBytes =
      await _buildPdf();

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename:
        '${_displayNumber()}-CCR-Report.pdf',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'CCR report generated successfully.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanError(e),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD PDF
  // ============================================================

  Future<Uint8List> _buildPdf() async {
    await pdfDefaultTheme();

    final pw.Document document =
    pw.Document();

    // ==========================================================
    // TITLE
    // ==========================================================

    document.addPage(
      pw.MultiPage(
        pageFormat:
        PdfPageFormat.a4,
        margin:
        const pw.EdgeInsets.all(28),
        maxPages: 20,
        build: (
            pw.Context context,
            ) {
          return <pw.Widget>[
            _pdfTitle(),
          ];
        },
      ),
    );

    // ==========================================================
    // 1. REGISTRATION
    //
    // IMPORTANT:
    // Registration images are now loaded and embedded here.
    // ==========================================================

    final pw.Widget registration =
    await _pdfRegistration();

    _addPdfSection(
      document,
      '1. Registration',
      registration,
    );



    // ==========================================================
    // 4. CONTAINMENT
    // ==========================================================

    _addPdfSection(
      document,
      '2. Containment',
      _pdfContainment(),
    );

    // ==========================================================
    // 5. ASSIGNMENT
    // ==========================================================

    _addPdfSection(
      document,
      '3. Assignment',
      _pdfAssignments(),
    );

    // ==========================================================
    // 6. FISHBONE
    // ==========================================================

    _addPdfSection(
      document,
      '4. Fishbone Analysis',
      _pdfFishbone(),
    );

    _addPdfSection(
      document,
      '4.1 Fishbone Potential Causes',
      _pdfFishboneCauseTable(),
    );
    // ==========================================================
    // 7. ROOT CAUSE VALIDATION
    // ==========================================================

    _addPdfSection(
      document,
      '5. Root Cause Validation',
      _pdfValidation(),
    );

    // ==========================================================
    // 8. OCCURRENCE 5-WHY
    // ==========================================================

    _addPdfSection(
      document,
      '6. Occurrence 5-Why',
      _pdfWhy('occurrence'),
    );

    // ==========================================================
    // 9. NON-DETECTION 5-WHY
    // ==========================================================

    _addPdfSection(
      document,
      '7. Non-Detection 5-Why',
      _pdfWhy('non_detection'),
    );

    // ==========================================================
    // 10. CORRECTIVE ACTION
    // ==========================================================

    _addPdfSection(
      document,
      '8. Corrective Action & Verification',
      _pdfActions(),
    );

    // ==========================================================
    // 11. CORRECTIVE ACTION EVIDENCE
    // ==========================================================

    final pw.Widget evidence =
    await _pdfEvidence();

    _addPdfSection(
      document,
      '9. Evidence of Corrective Action',
      evidence,
    );

    // ==========================================================
    // 12. CLOSURE
    // ==========================================================

    _addPdfSection(
      document,
      '10. Closure',
      _pdfClosure(),
    );

    return document.save();
  }

  // ============================================================
  // ADD PDF SECTION
  // ============================================================

  void _addPdfSection(
      pw.Document document,
      String title,
      pw.Widget child,
      ) {
    document.addPage(
      pw.MultiPage(
        pageFormat:
        PdfPageFormat.a4,
        margin:
        const pw.EdgeInsets.all(28),
        maxPages: 100,
        build: (
            pw.Context context,
            ) {
          return <pw.Widget>[
            _pdfSectionHeader(title),
            child,
          ];
        },
      ),
    );
  }

  // ============================================================
  // PDF TITLE
  // ============================================================

  pw.Widget _pdfTitle() {
    return pw.Container(
      margin:
      const pw.EdgeInsets.only(
        bottom: 16,
      ),
      padding:
      const pw.EdgeInsets.all(16),
      decoration:
      pw.BoxDecoration(
        border:
        pw.Border.all(
          color:
          PdfColors.grey400,
        ),
        borderRadius:
        pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment:
        pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Customer Complaint Registration',
            style:
            pw.TextStyle(
              fontSize: 20,
              fontWeight:
              pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(
            height: 6,
          ),
          pw.Text(
            _displayNumber(),
            style:
            pw.TextStyle(
              fontSize: 15,
              fontWeight:
              pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(
            height: 5,
          ),
          pw.Text(
            'Generated: ${DateTime.now().toLocal()}',
            style:
            const pw.TextStyle(
              fontSize: 8,
              color:
              PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PDF SECTION HEADER
  // ============================================================

  pw.Widget _pdfSectionHeader(
      String title,
      ) {
    return pw.Container(
      width: double.infinity,
      margin:
      const pw.EdgeInsets.only(
        bottom: 10,
      ),
      padding:
      const pw.EdgeInsets.all(8),
      color:
      PdfColors.grey200,
      child: pw.Text(
        title,
        style:
        pw.TextStyle(
          fontSize: 13,
          fontWeight:
          pw.FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // PDF REGISTRATION
  //
  // NOW ASYNC BECAUSE REGISTRATION PHOTOS MUST BE DOWNLOADED
  // FROM SUPABASE STORAGE BEFORE THEY CAN BE EMBEDDED IN PDF.
  // ============================================================

  // ============================================================
  // PDF REGISTRATION
  // ============================================================

  Future<pw.Widget> _pdfRegistration() async {
    final List<pw.Widget> children = <pw.Widget>[];

    // Registration details
    children.add(
      _pdfMap(
        _ccr,
        <String, String>{
          'CCR Number': 'ccr_number',
          'Complaint Date': 'complaint_date',
          'Customer Name': 'customer_name',
          'Customer Location': 'customer_location',
          'Part Description': 'part_description',
          'Part No': 'part_no',
          'Quantity': 'qty',
          'Complaint Description': 'complaint_description',
        },
      ),
    );

    // Registration images
    final List<Map<String, dynamic>> registrationImages =
    _attachments.where((attachment) {
      return attachment['attachment_type']
          ?.toString()
          .trim()
          .toLowerCase() ==
          'complaint_photo';
    }).toList();

    if (registrationImages.isNotEmpty) {
      children.add(
        pw.SizedBox(height: 14),
      );

      children.add(
        pw.Text(
          'Registration Images',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );

      children.add(
        pw.SizedBox(height: 8),
      );

      for (int i = 0; i < registrationImages.length; i++) {
        final Map<String, dynamic> attachment =
        registrationImages[i];

        children.add(
          await _pdfAttachmentImage(
            attachment,
            title: 'Registration Image ${i + 1}',
          ),
        );

        children.add(
          pw.SizedBox(height: 10),
        );
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  // ============================================================
  // PDF CUSTOMER VIEW
  // ============================================================

  pw.Widget _pdfCustomerView() {
    return _pdfMap(
      _customerView,
      <String, String>{
        'What Happened':
        'what_happened',
        'Why Is It A Problem':
        'why_is_it_a_problem',
        'When Detected':
        'when_detected',
        'Who Detected':
        'who_detected',
        'Where Detected':
        'where_detected',
        'How Detected':
        'how_detected',
        'Bad Parts Quantity':
        'bad_parts_quantity',
        'Inspected Quantity':
        'inspected_quantity',
        'Defect Rate':
        'defect_rate',
        'PPM':
        'ppm',
      },
    );
  }

  // ============================================================
  // PDF SUPPLIER VIEW
  // ============================================================

  pw.Widget _pdfSupplierView() {
    return _pdfMap(
      _supplierView,
      <String, String>{
        'Good vs Bad Difference':
        'good_vs_bad_difference',
        'Defect Process':
        'defect_process',
        'Supplier Manufacture Date':
        'supplier_manufacture_date',
        'Supplier Lot Information':
        'supplier_lot_information',
        'Supplier Manufactured Quantity':
        'supplier_manufactured_quantity',
        'Supplier Site':
        'supplier_site',
        'Supplier Line Number':
        'supplier_line_number',
        'Supplier Shift':
        'supplier_shift',
        'Defect Should Be Detected At':
        'defect_should_be_detected_at',
        'Covered By MSOP/SIP':
        'covered_by_msop_sip',
        'Similar Problem Previously':
        'similar_problem_previously',
        'Previous Problem Details':
        'previous_problem_details',
      },
    );
  }

  // ============================================================
  // PDF CONTAINMENT
  // ============================================================

  pw.Widget _pdfContainment() {
    final List<pw.Widget> children =
    <pw.Widget>[];

    children.add(
      _pdfMap(
        _containment,
        <String, String>{
          'Sorting Activity':
          'sorting_activity',
          'Sorting Learnings':
          'sorting_learnings',
          'Customer Protection Action':
          'customer_protection_action',
          'Recover PRQ Schedule':
          'recover_prq_schedule',
          'First Certified Good Shipment':
          'first_certified_good_shipment',
          'Target ETA':
          'target_eta'
        },
      ),
    );

    if (_sorting.isNotEmpty) {
      children.add(
        pw.SizedBox(
          height: 10,
        ),
      );

      children.add(
        pw.Text(
          'Sorting Results',
          style:
          pw.TextStyle(
            fontWeight:
            pw.FontWeight.bold,
            fontSize: 9,
          ),
        ),
      );

      children.add(
        pw.SizedBox(
          height: 5,
        ),
      );

      children.add(
        _pdfTable(
          <String>[
            'Location',
            'Qty NG',
            'Qty Sorted',
            'NG %',
            'Sorting Date',
            'DRI',
          ],
          _sorting
              .map(
                (
                Map<String, dynamic> row,
                ) =>
            <String>[
              _value(
                row['location'],
              ),
              _value(
                row['qty_ng'],
              ),
              _value(
                row['qty_sorted'],
              ),
              _value(
                row['ng_percentage'],
              ),
              _value(
                row['sorting_date'],
              ),
              _value(
                row['dri'],
              ),
            ],
          )
              .toList(),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment:
      pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  // ============================================================
  // PDF ASSIGNMENTS
  // ============================================================

  pw.Widget _pdfAssignments() {
    if (_assignments.isEmpty) {
      return _pdfEmpty();
    }

    return _pdfTable(
      <String>[
        'Activity',
        'DRI',
        'Due Date',
        'Done Date',
        'Status',
        'Remarks',
      ],
      _assignments
          .map(
            (
            Map<String, dynamic> row,
            ) =>
        <String>[
          _value(
            row['activity'],
          ),
          _value(
            row['dri'],
          ),
          _value(
            row['due_date'],
          ),
          _value(
            row['done_date'],
          ),
          _value(
            row['status'],
          ),
          _value(
            row['remarks'],
          ),
        ],
      )
          .toList(),
    );
  }

  // ============================================================
  // PDF FISHBONE
  //
  // IMPORTANT:
  // The old implementation positioned the lines and the boxes
  // using different calculations.
  //
  // This implementation uses ONE geometry system.
  //
  // Everything is positioned relative to:
  //
  //   spineY
  //   spineStartX
  //   spineEndX
  //   categoryX
  //   categoryY
  //
  // Therefore every branch terminates at the corresponding
  // category box.
  // ============================================================

  pw.Widget _pdfFishbone() {
    if (_categories.isEmpty) {
      return _pdfEmpty();
    }

    const double canvasWidth =
    530;

    const double canvasHeight =
    330;

    const double spineY =
    165;

    const double spineStartX =
    25;

    const double effectWidth =
    105;

    const double effectX =
        canvasWidth - effectWidth - 5;

    const double spineEndX =
        effectX - 10;

    const double categoryWidth =
    105;

    const double categoryHeight =
    82;

    final int upperCount =
    (_categories.length / 2)
        .ceil();

    final int lowerCount =
        _categories.length -
            upperCount;

    final List<pw.Widget>
    positionedNodes =
    <pw.Widget>[];

    // ==========================================================
    // MAIN SPINE
    // ==========================================================

    positionedNodes.add(
      pw.Positioned(
        left: spineStartX,
        top: spineY,
        child:
        pw.Container(
          width:
          spineEndX -
              spineStartX,
          height: 2,
          color:
          PdfColors.blue,
        ),
      ),
    );

    // ==========================================================
    // EFFECT NODE
    // ==========================================================

    positionedNodes.add(
      pw.Positioned(
        left: effectX,
        top: spineY - 40,
        child:
        pw.Container(
          width:
          effectWidth,
          height: 80,
          padding:
          const pw.EdgeInsets.all(7),
          decoration:
          pw.BoxDecoration(
            border:
            pw.Border.all(
              color:
              PdfColors.blue,
            ),
            borderRadius:
            pw.BorderRadius.circular(
              5,
            ),
          ),
          child:
          pw.Center(
            child:
            pw.Text(
              _value(
                (_ccr?['problem_description']?.toString().trim().isNotEmpty == true)
                    ? _ccr!['problem_description']
                    : _ccr?['complaint_description'],
              ),
              maxLines: 6,
              overflow:
              pw.TextOverflow.clip,
              style:
              pw.TextStyle(
                fontSize: 7,
                fontWeight:
                pw.FontWeight.bold,
              ),
              textAlign:
              pw.TextAlign.center,
            ),
          ),
        ),
      ),
    );

    // ==========================================================
    // CATEGORY GEOMETRY
    //
    // Category boxes are evenly distributed across the same
    // x positions used by the branch junctions.
    // ==========================================================

    final double availableWidth =
        spineEndX -
            spineStartX -
            25;

    final List<double>
    upperJunctions =
    _calculateJunctions(
      upperCount,
      spineStartX,
      availableWidth,
    );

    final List<double>
    lowerJunctions =
    _calculateJunctions(
      lowerCount,
      spineStartX,
      availableWidth,
    );

    // ==========================================================
    // UPPER CATEGORIES
    // ==========================================================

    for (int i = 0;
    i < upperCount;
    i++) {
      final Map<String, dynamic>
      category =
      _categories[i];

      final double junctionX =
      upperJunctions[i];

      final double categoryLeft =
          junctionX -
              categoryWidth / 2;

      final double categoryTop =
      18;

      final double categoryBottom =
          categoryTop +
              categoryHeight;

      // Branch endpoint is the center of the
      // bottom edge of the category box.
      final double branchEndX =
          junctionX;

      final double branchEndY =
          categoryBottom;

      positionedNodes.add(
        _pdfFishboneBranch(
          startX:
          junctionX,
          startY:
          spineY,
          endX:
          branchEndX,
          endY:
          branchEndY,
        ),
      );

      positionedNodes.add(
        _pdfFishboneCategory(
          category,
          categoryLeft,
          categoryTop,
          categoryWidth,
          categoryHeight,
        ),
      );
    }

    // ==========================================================
    // LOWER CATEGORIES
    // ==========================================================

    for (int i = 0;
    i < lowerCount;
    i++) {
      final Map<String, dynamic>
      category =
      _categories[
      upperCount + i];

      final double junctionX =
      lowerJunctions[i];

      final double categoryLeft =
          junctionX -
              categoryWidth / 2;

      final double categoryTop =
          canvasHeight -
              categoryHeight -
              18;

      final double categoryTopEdge =
          categoryTop;

      positionedNodes.add(
        _pdfFishboneBranch(
          startX:
          junctionX,
          startY:
          spineY,
          endX:
          junctionX,
          endY:
          categoryTopEdge,
        ),
      );

      positionedNodes.add(
        _pdfFishboneCategory(
          category,
          categoryLeft,
          categoryTop,
          categoryWidth,
          categoryHeight,
        ),
      );
    }

    return pw.Container(
      width:
      canvasWidth,
      height:
      canvasHeight,
      decoration:
      pw.BoxDecoration(
        border:
        pw.Border.all(
          color:
          PdfColors.grey400,
        ),
      ),
      child:
      pw.Stack(
        children:
        positionedNodes,
      ),
    );
  }
  // ============================================================
  // PDF FISHBONE POTENTIAL CAUSES TABLE
  // ============================================================

  pw.Widget _pdfFishboneCauseTable() {
    if (_categories.isEmpty) {
      return _pdfEmpty();
    }

    final List<List<String>> rows = [];

    for (final Map<String, dynamic> category in _categories) {
      final String categoryId =
          category['id']?.toString() ?? '';

      final List<Map<String, dynamic>> categoryCauses =
      _causes.where(
            (Map<String, dynamic> cause) =>
        cause['category_id']?.toString() == categoryId,
      ).toList();

      if (categoryCauses.isEmpty) {
        rows.add([
          _value(category['name']),
          'No causes entered.',
        ]);
      } else {
        for (final Map<String, dynamic> cause in categoryCauses) {
          rows.add([
            _value(category['name']),
            _value(cause['cause_text']),
          ]);
        }
      }
    }

    return _pdfTable(
      [
        'Category',
        'Potential Cause',
      ],
      rows,
    );
  }
  // ============================================================
  // CALCULATE FISHBONE JUNCTIONS
  // ============================================================

  List<double> _calculateJunctions(
      int count,
      double startX,
      double availableWidth,
      ) {
    if (count <= 0) {
      return <double>[];
    }

    if (count == 1) {
      return <double>[
        startX +
            availableWidth / 2,
      ];
    }

    final double spacing =
        availableWidth /
            (count + 1);

    return List<double>.generate(
      count,
          (int index) =>
      startX +
          spacing * (index + 1),
    );
  }

  // ============================================================
  // FISHBONE BRANCH
  //
  // Uses an actual rectangle whose width and rotation are
  // calculated from the two exact endpoints.
  // ============================================================

  pw.Widget _pdfFishboneBranch({
    required double startX,
    required double startY,
    required double endX,
    required double endY,
  }) {
    final double dx =
        endX - startX;

    final double dy =
        endY - startY;

    final double length =
    math.sqrt(
      dx * dx + dy * dy,
    );
    final double angle =
    _angle(
      dx,
      dy,
    );

    final double left =
        (startX + endX) / 2 -
            length / 2;

    final double top =
        (startY + endY) / 2 -
            0.75;

    return pw.Positioned(
      left: left,
      top: top,
      child:
      pw.Transform.rotate(
        angle: angle,
        alignment:
        pw.Alignment.center,
        child:
        pw.Container(
          width:
          length,
          height: 1.5,
          color:
          PdfColors.blue,
        ),
      ),
    );
  }

  // ============================================================
  // ANGLE
  // ============================================================

  double _angle(
      double dx,
      double dy,
      ) {
    /*
     * atan2 is not imported deliberately.
     *
     * Fishbone PDF geometry only needs the two standard
     * diagonal angles for the fixed upper/lower branches.
     *
     * Calculate using sign and absolute ratio.
     */

    if (dx == 0) {
      return dy >= 0
          ? 1.57079632679
          : -1.57079632679;
    }

    final double ratio =
        dy.abs() /
            dx.abs();

    double angle;

    if (ratio < 0.5) {
      angle = 0.463647609;
    } else if (ratio < 0.9) {
      angle = 0.674740942;
    } else {
      angle = 0.785398163;
    }

    if (dx < 0) {
      angle =
          3.14159265359 -
              angle;
    }

    if (dy < 0) {
      angle = -angle;
    }

    return angle;
  }

  // ============================================================
  // FISHBONE CATEGORY
  // ============================================================
  // ============================================================
  // PDF FISHBONE CATEGORY
  // ============================================================

  pw.Widget _pdfFishboneCategory(
      Map<String, dynamic> category,
      double left,
      double top,
      double width,
      double height,
      ) {
    final String categoryId =
        category['id']?.toString() ?? '';

    final int causeCount = _causes
        .where(
          (Map<String, dynamic> cause) =>
      cause['category_id']?.toString() == categoryId,
    )
        .length;

    return pw.Positioned(
      left: left,
      top: top,
      child: pw.Container(
        width: width,
        height: height,
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(
            color: PdfColors.blue,
            width: 1,
          ),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              _value(category['name']),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              '$causeCount potential causes',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(
                fontSize: 6,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // pw.Widget _pdfFishboneCategory(
  //     Map<String, dynamic> category,
  //     double left,
  //     double top,
  //     double width,
  //     double height,
  //     ) {
  //   final String categoryId =
  //       category['id']?.toString() ??
  //           '';
  //
  //   final List<Map<String, dynamic>>
  //   categoryCauses =
  //   _causes
  //       .where(
  //         (
  //         Map<String, dynamic>
  //         cause,
  //         ) =>
  //     cause['category_id']
  //         ?.toString() ==
  //         categoryId,
  //   )
  //       .toList();
  //
  //   final List<pw.Widget>
  //   causeWidgets =
  //   <pw.Widget>[];
  //
  //   if (categoryCauses.isEmpty) {
  //     causeWidgets.add(
  //       pw.Text(
  //         'No causes entered.',
  //         style:
  //         const pw.TextStyle(
  //           fontSize: 6,
  //           color:
  //           PdfColors.grey700,
  //         ),
  //       ),
  //     );
  //   } else {
  //     for (final Map<String, dynamic>
  //     cause in categoryCauses) {
  //       causeWidgets.add(
  //         pw.Padding(
  //           padding:
  //           const pw.EdgeInsets.only(
  //             bottom: 2,
  //           ),
  //           child:
  //           pw.Text(
  //             '- ${_value(cause['cause_text'])}',
  //             maxLines: 2,
  //             style:
  //             const pw.TextStyle(
  //               fontSize: 6,
  //             ),
  //           ),
  //         ),
  //       );
  //     }
  //   }
  //
  //   return pw.Positioned(
  //     left: left,
  //     top: top,
  //     child:
  //     pw.Container(
  //       width: width,
  //       height: height,
  //       padding:
  //       const pw.EdgeInsets.all(6),
  //       decoration:
  //       pw.BoxDecoration(
  //         border:
  //         pw.Border.all(
  //           color:
  //           PdfColors.grey500,
  //         ),
  //         borderRadius:
  //         pw.BorderRadius.circular(
  //           5,
  //         ),
  //       ),
  //       child:
  //       pw.Column(
  //         crossAxisAlignment:
  //         pw.CrossAxisAlignment.start,
  //         children: [
  //           pw.Text(
  //             _value(
  //               category['name'],
  //             ),
  //             style:
  //             pw.TextStyle(
  //               fontSize: 8,
  //               fontWeight:
  //               pw.FontWeight.bold,
  //             ),
  //           ),
  //           pw.SizedBox(
  //             height: 4,
  //           ),
  //           ...causeWidgets,
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // ============================================================
  // PDF ROOT CAUSE VALIDATION
  // ============================================================

  pw.Widget _pdfValidation() {
    if (_validations.isEmpty) {
      return _pdfEmpty();
    }

    return _pdfTable(
      <String>[
        'Category',
        'Hypothesis',
        'Validation',
        'Relevance',
      ],
      _validations
          .map(
            (
            Map<String, dynamic> row,
            ) {
          final String causeId =
              row[
              'fishbone_cause_id']
                  ?.toString() ??
                  '';

          final Map<String, dynamic>?
          cause =
          _findById(
            _causes,
            causeId,
          );

          return <String>[
            _categoryName(
              cause?[
              'category_id']
                  ?.toString() ??
                  '',
            ),
            _value(
              cause?['cause_text'],
            ),
            _value(
              row[
              'validation_text'],
            ),
            _yesNo(
              row['relevance'],
            ),
          ];
        },
      )
          .toList(),
    );
  }

  // ============================================================
  // PDF WHY
  // ============================================================

  pw.Widget _pdfWhy(
      String type,
      ) {
    final List<Map<String, dynamic>>
    analyses =
    _whyAnalyses
        .where(
          (
          Map<String, dynamic>
          row,
          ) =>
      row['analysis_type']
          ?.toString()
          .trim()
          .toLowerCase() ==
          type,
    )
        .toList();

    if (analyses.isEmpty) {
      return _pdfEmpty();
    }

    final List<pw.Widget>
    children =
    <pw.Widget>[];

    for (final Map<String, dynamic>
    analysis in analyses) {
      final String validationId =
          analysis['validation_id']
              ?.toString() ??
              '';

      final Map<String, dynamic>?
      validation =
      _findById(
        _validations,
        validationId,
      );

      final Map<String, dynamic>?
      cause =
      validation == null
          ? null
          : _findById(
        _causes,
        validation[
        'fishbone_cause_id']
            ?.toString(),
      );

      final List<Map<String, dynamic>>
      steps =
      _whySteps
          .where(
            (
            Map<String, dynamic>
            row,
            ) =>
        row['analysis_id']
            ?.toString() ==
            analysis['id']
                ?.toString(),
      )
          .toList();

      children.add(
        pw.Container(
          margin:
          const pw.EdgeInsets.only(
            bottom: 14,
          ),
          padding:
          const pw.EdgeInsets.all(10),
          decoration:
          pw.BoxDecoration(
            border:
            pw.Border.all(
              color:
              PdfColors.grey400,
            ),
            borderRadius:
            pw.BorderRadius.circular(
              5,
            ),
          ),
          child:
          pw.Column(
            crossAxisAlignment:
            pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Potential Root Cause',
                style:
                pw.TextStyle(
                  fontSize: 9,
                  fontWeight:
                  pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(
                height: 4,
              ),
              pw.Text(
                _value(
                  cause?[
                  'cause_text'],
                ),
                style:
                const pw.TextStyle(
                  fontSize: 8,
                ),
              ),
              pw.SizedBox(
                height: 8,
              ),
              if (steps.isEmpty)
                _pdfEmpty()
              else
                _pdfTable(
                  <String>[
                    'Why',
                    'Why Statement',
                    'Verification',
                    'Evidence',
                  ],
                  steps
                      .map(
                        (
                        Map<String, dynamic>
                        row,
                        ) =>
                    <String>[
                      _value(
                        row[
                        'why_number'],
                      ),
                      _value(
                        row[
                        'why_text'],
                      ),
                      _value(
                        row[
                        'verification_text'],
                      ),
                      _yesNo(
                        row[
                        'evidence_available'],
                      ),
                    ],
                  )
                      .toList(),
                ),
            ],
          ),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment:
      pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  // ============================================================
  // PDF CORRECTIVE ACTION
  // ============================================================

  pw.Widget _pdfActions() {
    if (_actions.isEmpty) {
      return _pdfEmpty();
    }

    final List<pw.Widget>
    children =
    <pw.Widget>[];

    for (int i = 0;
    i < _actions.length;
    i++) {
      final Map<String, dynamic>
      action =
      _actions[i];

      final dynamic rawVerification =
      action[
      'ccr_action_verifications'];

      Map<String, dynamic>?
      verification;

      if (rawVerification is List &&
          rawVerification.isNotEmpty &&
          rawVerification.first is Map) {
        verification =
        Map<String, dynamic>.from(
          rawVerification.first
          as Map,
        );
      } else if (rawVerification
      is Map) {
        verification =
        Map<String, dynamic>.from(
          rawVerification,
        );
      }

      children.add(
        pw.Container(
          margin:
          const pw.EdgeInsets.only(
            bottom: 12,
          ),
          padding:
          const pw.EdgeInsets.all(8),
          decoration:
          pw.BoxDecoration(
            border:
            pw.Border.all(
              color:
              PdfColors.grey400,
            ),
            borderRadius:
            pw.BorderRadius.circular(
              5,
            ),
          ),
          child:
          pw.Column(
            crossAxisAlignment:
            pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Corrective Action ${i + 1}',
                style:
                pw.TextStyle(
                  fontSize: 9,
                  fontWeight:
                  pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(
                height: 5,
              ),
              _pdfMap(
                action,
                <String, String>{
                  'Problem Statement':
                  'problem_statement',
                  'Occurrence Root Cause':
                  'occurrence_root_cause',
                  'Non-Detection Root Cause':
                  'detection_root_cause',
                  'Corrective Action':
                  'corrective_action',
                  'DRI':
                  'dri',
                  'Result Before':
                  'result_before',
                  'Result After':
                  'result_after',
                  'Due Date':
                  'due_date',
                  'Completion Date':
                  'completion_date',
                },
              ),
              if (verification != null) ...[
                pw.SizedBox(
                  height: 6,
                ),
                pw.Text(
                  'Verification',
                  style:
                  pw.TextStyle(
                    fontSize: 9,
                    fontWeight:
                    pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(
                  height: 4,
                ),
                _pdfMap(
                  verification,
                  <String, String>{
                    'Verification Required':
                    'verification_required',
                    'Verification Status':
                    'verification_status',
                    'Verified By':
                    'verified_by',
                    'Verification Date':
                    'verification_date',
                    'Verification Method':
                    'verification_method',
                    'Verification Result':
                    'verification_result',
                    'Verification Remarks':
                    'verification_remarks',
                  },
                ),
              ],
            ],
          ),
        ),
      );
    }

    return pw.Column(
      children: children,
    );
  }

  // ============================================================
  // PDF CORRECTIVE ACTION EVIDENCE
  // ============================================================

  Future<pw.Widget> _pdfEvidence()
  async {
    if (_actionEvidence.isEmpty) {
      return _pdfEmpty();
    }

    final List<pw.Widget>
    children =
    <pw.Widget>[];

    for (int i = 0;
    i < _actionEvidence.length;
    i++) {
      final Map<String, dynamic>
      evidence =
      _actionEvidence[i];

      final dynamic rawAttachment =
      evidence[
      'ccr_attachments'];

      if (rawAttachment is Map) {
        final Map<String, dynamic>
        attachment =
        Map<String, dynamic>.from(
          rawAttachment,
        );

        children.add(
          await _pdfAttachmentImage(
            attachment,
            title:
            'Evidence ${i + 1}',
            evidenceType:
            _value(
              evidence[
              'evidence_type'],
            ),
            description:
            _value(
              evidence[
              'description'],
            ),
          ),
        );
      } else {
        children.add(
          pw.Container(
            width:
            double.infinity,
            margin:
            const pw.EdgeInsets.only(
              bottom: 12,
            ),
            padding:
            const pw.EdgeInsets.all(
              8,
            ),
            decoration:
            pw.BoxDecoration(
              border:
              pw.Border.all(
                color:
                PdfColors.grey400,
              ),
            ),
            child:
            pw.Text(
              _value(
                evidence[
                'description'],
              ),
              style:
              const pw.TextStyle(
                fontSize: 8,
              ),
            ),
          ),
        );
      }
    }

    return pw.Column(
      crossAxisAlignment:
      pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  // ============================================================
  // PDF ATTACHMENT IMAGE
  //
  // Shared by:
  //
  // - Registration images
  // - Corrective action evidence
  //
  // The storage bucket/path are read from the database.
  // Nothing is hardcoded here.
  // ============================================================

  Future<pw.Widget> _pdfAttachmentImage(
      Map<String, dynamic> attachment, {
        required String title,
        String? evidenceType,
        String? description,
      }) async {
    pw.Widget imageWidget =
    pw.Container(
      width:
      double.infinity,
      height: 100,
      alignment:
      pw.Alignment.center,
      child:
      pw.Text(
        'Image unavailable.',
        style:
        const pw.TextStyle(
          fontSize: 8,
          color:
          PdfColors.grey700,
        ),
      ),
    );


    final String? url = _attachmentFileUrl(attachment);

    if (url != null) {
      try {
        final http.Response response =
        await http.get(Uri.parse(url));

        if (response.statusCode >= 200 &&
            response.statusCode < 300 &&
            response.bodyBytes.isNotEmpty) {
          imageWidget = pw.Container(
            width: double.infinity,
            height: 190,
            alignment: pw.Alignment.center,
            padding: const pw.EdgeInsets.all(5),
            child: pw.Image(
              pw.MemoryImage(response.bodyBytes),
              width: 480,
              height: 180,
              fit: pw.BoxFit.contain,
            ),
          );
        }
      } catch (_) {
        imageWidget = pw.Container(
          width: double.infinity,
          height: 100,
          alignment: pw.Alignment.center,
          child: pw.Text(
            'Image could not be loaded.',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
        );
      }
    }

    final List<pw.Widget>
    details =
    <pw.Widget>[
      pw.Text(
        title,
        style:
        pw.TextStyle(
          fontSize: 9,
          fontWeight:
          pw.FontWeight.bold,
        ),
      ),
    ];

    if (evidenceType != null &&
        evidenceType.isNotEmpty &&
        evidenceType != '-') {
      details.add(
        pw.SizedBox(
          height: 3,
        ),
      );

      details.add(
        pw.Text(
          evidenceType,
          style:
          const pw.TextStyle(
            fontSize: 8,
          ),
        ),
      );
    }

    details.add(
      pw.SizedBox(
        height: 7,
      ),
    );

    details.add(
      imageWidget,
    );

    if (description != null &&
        description.isNotEmpty &&
        description != '-') {
      details.add(
        pw.SizedBox(
          height: 6,
        ),
      );

      details.add(
        pw.Text(
          description,
          style:
          const pw.TextStyle(
            fontSize: 8,
          ),
        ),
      );
    }

    return pw.Container(
      width:
      double.infinity,
      margin:
      const pw.EdgeInsets.only(
        bottom: 12,
      ),
      padding:
      const pw.EdgeInsets.all(8),
      decoration:
      pw.BoxDecoration(
        border:
        pw.Border.all(
          color:
          PdfColors.grey400,
        ),
        borderRadius:
        pw.BorderRadius.circular(
          5,
        ),
      ),
      child:
      pw.Column(
        crossAxisAlignment:
        pw.CrossAxisAlignment.start,
        children: details,
      ),
    );
  }

  // ============================================================
  // PDF CLOSURE
  // ============================================================

  pw.Widget _pdfClosure() {
    return _pdfMap(
      _closure,
      <String, String>{
        'Closure Status':
        'closure_status',
        'Closure Summary':
        'closure_summary',
        'Customer Response':
        'customer_response',
        'Final Remarks':
        'final_remarks',
        'Closed By':
        'closed_by',
        'Closed At':
        'closed_at',
      },
    );
  }

  // ============================================================
  // PDF MAP
  // ============================================================

  pw.Widget _pdfMap(
      Map<String, dynamic>? data,
      Map<String, String> fields,
      ) {
    if (data == null) {
      return _pdfEmpty();
    }

    final List<pw.TableRow>
    rows =
    <pw.TableRow>[];

    for (final MapEntry<String, String>
    entry in fields.entries) {
      rows.add(
        pw.TableRow(
          children: [
            _pdfCell(
              entry.key,
              bold: true,
            ),
            _pdfCell(
              entry.key == 'Closed At'
                  ? _formatReportDate(data[entry.value])
                  : _value(data[entry.value]),
            ),
          ],
        ),
      );
    }

    return pw.Table(
      border:
      pw.TableBorder.all(
        color:
        PdfColors.grey400,
      ),
      columnWidths:
      const <int,
          pw.TableColumnWidth>{
        0:
        pw.FlexColumnWidth(1),
        1:
        pw.FlexColumnWidth(2),
      },
      children: rows,
    );
  }

  // ============================================================
  // PDF TABLE
  // ============================================================

  pw.Widget _pdfTable(
      List<String> headers,
      List<List<String>> rows,
      ) {
    if (rows.isEmpty) {
      return _pdfEmpty();
    }

    return pw.Table.fromTextArray(
      headers:
      headers,
      data:
      rows,
      border:
      pw.TableBorder.all(
        color:
        PdfColors.grey400,
      ),
      headerStyle:
      pw.TextStyle(
        fontSize: 7,
        fontWeight:
        pw.FontWeight.bold,
      ),
      cellStyle:
      const pw.TextStyle(
        fontSize: 7,
      ),
      cellPadding:
      const pw.EdgeInsets.all(4),
      headerDecoration:
      const pw.BoxDecoration(
        color:
        PdfColors.grey200,
      ),
    );
  }

  // ============================================================
  // PDF CELL
  // ============================================================

  pw.Widget _pdfCell(
      String text, {
        bool bold = false,
      }) {
    return pw.Padding(
      padding:
      const pw.EdgeInsets.all(5),
      child:
      pw.Text(
        text,
        style:
        pw.TextStyle(
          fontSize: 8,
          fontWeight:
          bold
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // ============================================================
  // PDF EMPTY
  // ============================================================

  pw.Widget _pdfEmpty() {
    return pw.Container(
      padding:
      const pw.EdgeInsets.all(8),
      child:
      pw.Text(
        'No data entered.',
        style:
        const pw.TextStyle(
          fontSize: 8,
          color:
          PdfColors.grey700,
        ),
      ),
    );
  }
// ============================================================
// DOWNLOAD ORIGINAL CUSTOMER COMPLAINT DOCUMENT
// ============================================================

  Future<void>
  _downloadCustomerComplaintDocument() async {
    final document =
        _customerComplaintDocument;

    if (_downloadingCustomerDocument ||
        document == null) {
      return;
    }

    final String? fileUrl =
    _attachmentFileUrl(document);

    if (fileUrl == null) {
      _showMessage(
        'Customer complaint document ID is missing.',
        error: true,
      );
      return;
    }

    setState(() {
      _downloadingCustomerDocument = true;
    });

    try {
      final http.Response response =
      await http.get(Uri.parse(fileUrl));

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          'Unable to download customer complaint document.',
        );
      }

      final Uint8List bytes = response.bodyBytes;
      final fileName =
      document['original_file_name']
          ?.toString()
          .trim()
          .isNotEmpty ==
          true
          ? document['original_file_name']
          .toString()
          : document['title']
          ?.toString()
          .trim()
          .isNotEmpty ==
          true
          ? document['title']
          .toString()
          : 'customer-complaint-document';

      final extension =
      _fileExtensionFromName(
        fileName,
      );

      final mimeType =
      document['mime_type']
          ?.toString()
          .trim()
          .isNotEmpty ==
          true
          ? document['mime_type']
          .toString()
          : 'application/octet-stream';

      await FileSaver.instance.saveFile(
        name: _removeFileExtension(
          fileName,
        ),
        bytes: bytes,
        fileExtension: extension,
        mimeType: MimeType.other,
        customMimeType: mimeType,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Customer complaint document downloaded successfully.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanError(e),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloadingCustomerDocument = false;
        });
      }
    }
  }
  String _fileExtensionFromName(
      String fileName,
      ) {
    final dotIndex =
    fileName.lastIndexOf('.');

    if (dotIndex < 0 ||
        dotIndex == fileName.length - 1) {
      return 'bin';
    }

    return fileName
        .substring(dotIndex + 1)
        .toLowerCase();
  }

  String _removeFileExtension(
      String fileName,
      ) {
    final dotIndex =
    fileName.lastIndexOf('.');

    if (dotIndex <= 0) {
      return fileName;
    }

    return fileName.substring(
      0,
      dotIndex,
    );
  }

  String _documentSizeText(
      dynamic value,
      ) {
    if (value == null) {
      return 'Original customer document';
    }

    final bytes =
        int.tryParse(
          value.toString(),
        ) ??
            0;

    if (bytes <= 0) {
      return 'Original customer document';
    }

    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  // ============================================================
  // SIGNED URL
  // ============================================================


  String? _attachmentFileUrl(
      Map<String, dynamic> attachment,
      ) {
    final String id =
        attachment['id']?.toString().trim() ?? '';

    if (id.isEmpty) {
      return null;
    }

    return '${CcrApiClient.baseUrl}'
        '/api/v1/ccr/attachments/'
        '${Uri.encodeComponent(id)}/file';
  }

  Future<String?> _signedUrl(
      Map<String, dynamic> attachment,
      ) async {
    return _attachmentFileUrl(attachment);
  }

  // ============================================================
  // SCREEN
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    if (_loading) {
      return const Scaffold(
        backgroundColor:
        Color(0xFFF5F7FB),
        body:
        Center(
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor:
        const Color(0xFFF5F7FB),
        appBar:
        _appBar(),
        body:
        _errorView(),
      );
    }

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),
      appBar:
      _appBar(),
      body:
      SafeArea(
        child:
        Center(
          child:
          ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 1250,
            ),
            child:
            SingleChildScrollView(
              padding:
              const EdgeInsets.all(24),
              child:
              Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  _reportHeader(),

                  const SizedBox(
                    height: 18,
                  ),

                  _registrationCard(),

                  const SizedBox(
                    height: 18,
                  ),

                  _attachmentsCard(
                    'Registration Images',
                    _attachments.where((attachment) {
                      return attachment['attachment_type']
                          ?.toString()
                          .trim()
                          .toLowerCase() ==
                          'complaint_photo';
                    }).toList(),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  _customerComplaintDocumentCard(),

                  const SizedBox(
                    height: 18,
                  ),

                  _containmentCard(),

                  const SizedBox(
                    height: 18,
                  ),

                  _assignmentCard(),

                  const SizedBox(
                    height: 18,
                  ),

                  _fishboneCard(),

                  const SizedBox(
                    height: 18,
                  ),

                  _validationCard(),

                  const SizedBox(
                    height: 18,
                  ),

                  _whyCard(
                    'occurrence',
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  _whyCard(
                    'non_detection',
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  _actionsCard(),

                  const SizedBox(
                    height: 18,
                  ),

                  _evidenceCard(),

                  const SizedBox(
                    height: 18,
                  ),

                  _closureCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _appBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor:
      Colors.white,
      foregroundColor:
      const Color(0xFF172033),
      title:
      Row(
        children: [
          _iconBox(
            Icons.description_outlined,
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child:
            Text(
              '${_displayNumber()} Report',
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding:
          const EdgeInsets.only(
            right: 12,
          ),
          child:
          FilledButton.icon(
            onPressed:
            _downloading
                ? null
                : _downloadReport,
            style:
            FilledButton.styleFrom(
              backgroundColor:
              const Color(
                0xFF7655C9,
              ),
            ),
            icon:
            _downloading
                ? const SizedBox(
              width: 17,
              height: 17,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
                color:
                Colors.white,
              ),
            )
                : const Icon(
              Icons
                  .download_outlined,
            ),
            label:
            Text(
              _downloading
                  ? 'Generating...'
                  : 'Download Report',
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // REPORT HEADER
  // ============================================================

  Widget _reportHeader() {
    return _surfaceCard(
      child:
      Row(
        children: [
          _iconBox(
            Icons.description_outlined,
          ),
          const SizedBox(
            width: 14,
          ),
          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  _displayNumber(),
                  style:
                  const TextStyle(
                    fontSize: 22,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  _value(
                    _ccr?['complaint_description'],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF747B86),
                  ),
                ),
              ],
            ),
          ),
          _chip(
            _value(
              _ccr?['status'],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REGISTRATION CARD
  // ============================================================
  Widget _registrationCard() {
    return _sectionCard(
      'Registration',
      Icons.assignment_outlined,
      _screenMap(
        _ccr,
        <String, String>{
          'Complaint Date': 'complaint_date',
          'Customer Name': 'customer_name',
          'Customer Location': 'customer_location',
          'Part Description': 'part_description',
          'Part No': 'part_no',
          'Quantity': 'qty',
          'Complaint Description': 'complaint_description',
        },
      ),
    );
  }
  // ============================================================
  // CUSTOMER + SUPPLIER
  // ============================================================

  Widget _customerSupplierCard() {
    final List<Map<String, dynamic>>
    registrationImages =
    _attachments
        .where(
          (
          Map<String, dynamic>
          item,
          ) =>
      item[
      'attachment_type']
          ?.toString()
          .trim()
          .toLowerCase() ==
          'complaint_photo',
    )
        .toList();

    return Column(
      children: [
        _sectionCard(
          'Customer View',
          Icons.person_outline,
          _screenMap(
            _customerView,
            <String, String>{
              'What Happened':
              'what_happened',
              'Why Is It A Problem':
              'why_is_it_a_problem',
              'When Detected':
              'when_detected',
              'Who Detected':
              'who_detected',
              'Where Detected':
              'where_detected',
              'How Detected':
              'how_detected',
              'Bad Parts Quantity':
              'bad_parts_quantity',
              'Inspected Quantity':
              'inspected_quantity',
              'Defect Rate':
              'defect_rate',
              'PPM':
              'ppm',
            },
          ),
        ),

        const SizedBox(
          height: 18,
        ),

        _sectionCard(
          'Supplier View',
          Icons.factory_outlined,
          _screenMap(
            _supplierView,
            <String, String>{
              'Good vs Bad Difference':
              'good_vs_bad_difference',
              'Defect Process':
              'defect_process',
              'Supplier Manufacture Date':
              'supplier_manufacture_date',
              'Supplier Lot Information':
              'supplier_lot_information',
              'Supplier Manufactured Quantity':
              'supplier_manufactured_quantity',
              'Supplier Site':
              'supplier_site',
              'Supplier Line Number':
              'supplier_line_number',
              'Supplier Shift':
              'supplier_shift',
              'Defect Should Be Detected At':
              'defect_should_be_detected_at',
              'Covered By MSOP/SIP':
              'covered_by_msop_sip',
              'Similar Problem Previously':
              'similar_problem_previously',
              'Previous Problem Details':
              'previous_problem_details',
            },
          ),
        ),

        const SizedBox(
          height: 18,
        ),

        _attachmentsCard(
          'Registration Images',
          registrationImages,
        ),
        const SizedBox(
          height: 18,
        ),

        _customerComplaintDocumentCard(),
      ],
    );
  }

  // ============================================================
  // CONTAINMENT CARD
  // ============================================================
// ============================================================
// CUSTOMER COMPLAINT DOCUMENT
// ============================================================

  Widget _customerComplaintDocumentCard() {
    final document =
        _customerComplaintDocument;

    return _sectionCard(
      'Original Customer Complaint Document',
      Icons.description_outlined,
      document == null
          ? _emptyText(
        'No original customer complaint document was uploaded.',
      )
          : Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius:
          BorderRadius.circular(10),
          border: Border.all(
            color:
            const Color(0xFFE2E5EA),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color:
                const Color(0xFFEFF3FF),
                borderRadius:
                BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons
                    .insert_drive_file_outlined,
                color:
                Color(0xFF3155C6),
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    document[
                    'original_file_name']
                        ?.toString()
                        .trim()
                        .isNotEmpty ==
                        true
                        ? document[
                    'original_file_name']
                        .toString()
                        : document['title']
                        ?.toString() ??
                        'Customer complaint document',
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w700,
                      color:
                      Color(0xFF252A31),
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    _documentSizeText(
                      document['file_size'],
                    ),
                    style:
                    const TextStyle(
                      fontSize: 11,
                      color:
                      Color(0xFF747B86),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            FilledButton.icon(
              onPressed:
              _downloadingCustomerDocument
                  ? null
                  : _downloadCustomerComplaintDocument,
              icon:
              _downloadingCustomerDocument
                  ? const SizedBox(
                width: 16,
                height: 16,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(
                Icons.download_outlined,
              ),
              label: Text(
                _downloadingCustomerDocument
                    ? 'Downloading...'
                    : 'Download Document',
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _containmentCard() {
    return _sectionCard(
      'Containment',
      Icons.shield_outlined,
      Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          _screenMap(
            _containment,
            <String, String>{
              'Sorting Activity':
              'sorting_activity',
              'Sorting Learnings':
              'sorting_learnings',
              'Customer Protection Action':
              'customer_protection_action',
              'Recover PRQ Schedule':
              'recover_prq_schedule',
              'First Certified Good Shipment':
              'first_certified_good_shipment',
              'Target ETA':
              'target_eta',
            },
          ),
          if (_sorting.isNotEmpty) ...[
            const SizedBox(
              height: 16,
            ),
            _dataTable(
              headers: const [
                'Location',
                'Qty NG',
                'Qty Sorted',
                'NG %',
                'Sorting Date',
                'DRI',
              ],
              rows: _sorting
                  .map(
                    (
                    Map<String, dynamic>
                    row,
                    ) =>
                <String>[
                  _value(
                    row['location'],
                  ),
                  _value(
                    row['qty_ng'],
                  ),
                  _value(
                    row['qty_sorted'],
                  ),
                  _value(
                    row['ng_percentage'],
                  ),
                  _value(
                    row['sorting_date'],
                  ),
                  _value(
                    row['dri'],
                  ),
                ],
              )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ASSIGNMENT CARD
  // ============================================================

  Widget _assignmentCard() {
    return _sectionCard(
      'Assignment',
      Icons.assignment_turned_in_outlined,
      _assignments.isEmpty
          ? _emptyText(
        'No assignments entered.',
      )
          : _dataTable(
        headers: const [
          'Activity',
          'DRI',
          'Due Date',
          'Done Date',
          'Status',
          'Remarks',
        ],
        rows: _assignments
            .map(
              (
              Map<String, dynamic>
              row,
              ) =>
          <String>[
            _value(
              row['activity'],
            ),
            _value(
              row['dri'],
            ),
            _value(
              row['due_date'],
            ),
            _value(
              row['done_date'],
            ),
            _value(
              row['status'],
            ),
            _value(
              row['remarks'],
            ),
          ],
        )
            .toList(),
      ),
    );
  }

  // ============================================================
  // FISHBONE CARD
  // ============================================================

  Widget _fishboneCard() {
    return _sectionCard(
      'Fishbone Analysis',
      Icons.account_tree_outlined,
      Column(
        children: [
          _FishboneReportWidget(
            categories:
            _categories,
            causes:
            _causes,
            problem:
            _value(
              (_ccr?['problem_description']?.toString().trim().isNotEmpty == true)
                  ? _ccr!['problem_description']
                  : _ccr?['complaint_description'],
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          _dataTable(
            headers: const [
              'Category',
              'Potential Cause',
            ],
            rows: _causes
                .map(
                  (
                  Map<String, dynamic>
                  cause,
                  ) =>
              <String>[
                _categoryName(
                  cause[
                  'category_id']
                      ?.toString() ??
                      '',
                ),
                _value(
                  cause['cause_text'],
                ),
              ],
            )
                .toList(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VALIDATION CARD
  // ============================================================

  Widget _validationCard() {
    return _sectionCard(
      'Root Cause Validation',
      Icons.fact_check_outlined,
      _validations.isEmpty
          ? _emptyText(
        'No root cause validation data entered.',
      )
          : _dataTable(
        headers: const [
          'Category',
          'Hypothesis',
          'Validation',
          'Relevance',
        ],
        rows: _validations
            .map(
              (
              Map<String, dynamic>
              row,
              ) {
            final Map<String,
                dynamic>?
            cause =
            _findById(
              _causes,
              row[
              'fishbone_cause_id']
                  ?.toString(),
            );

            return <String>[
              _categoryName(
                cause?[
                'category_id']
                    ?.toString() ??
                    '',
              ),
              _value(
                cause?[
                'cause_text'],
              ),
              _value(
                row[
                'validation_text'],
              ),
              _yesNo(
                row['relevance'],
              ),
            ];
          },
        )
            .toList(),
      ),
    );
  }

  // ============================================================
  // WHY CARD
  // ============================================================

  Widget _whyCard(
      String type,
      ) {
    final List<Map<String, dynamic>>
    analyses =
    _whyAnalyses
        .where(
          (
          Map<String, dynamic>
          row,
          ) =>
      row['analysis_type']
          ?.toString()
          .trim()
          .toLowerCase() ==
          type,
    )
        .toList();

    final String title =
    type == 'occurrence'
        ? 'Occurrence 5-Why'
        : 'Non-Detection 5-Why';

    return _sectionCard(
      title,
      Icons.help_outline,
      analyses.isEmpty
          ? _emptyText(
        'No $title analysis entered.',
      )
          : Column(
        children: analyses
            .map(
              (
              Map<String, dynamic>
              analysis,
              ) {
            final Map<String,
                dynamic>?
            validation =
            _findById(
              _validations,
              analysis[
              'validation_id']
                  ?.toString(),
            );

            final Map<String,
                dynamic>?
            cause =
            validation == null
                ? null
                : _findById(
              _causes,
              validation[
              'fishbone_cause_id']
                  ?.toString(),
            );

            final List<
                Map<String,
                    dynamic>>
            steps =
            _whySteps
                .where(
                  (
                  Map<String,
                      dynamic>
                  row,
                  ) =>
              row[
              'analysis_id']
                  ?.toString() ==
                  analysis[
                  'id']
                      ?.toString(),
            )
                .toList();

            return Container(
              width:
              double.infinity,
              margin:
              const EdgeInsets.only(
                bottom: 14,
              ),
              padding:
              const EdgeInsets.all(
                14,
              ),
              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xFFF8F9FB,
                ),
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
                border:
                Border.all(
                  color:
                  const Color(
                    0xFFE2E5EA,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  const Text(
                    'Potential Root Cause',
                    style:
                    TextStyle(
                      fontSize: 12,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    _value(
                      cause?[
                      'cause_text'],
                    ),
                    style:
                    const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  _dataTable(
                    headers: const [
                      'Why',
                      'Why Statement',
                      'How Verified',
                      'Evidence',
                    ],
                    rows: steps
                        .map(
                          (
                          Map<String,
                              dynamic>
                          row,
                          ) =>
                      <String>[
                        _value(
                          row[
                          'why_number'],
                        ),
                        _value(
                          row[
                          'why_text'],
                        ),
                        _value(
                          row[
                          'verification_text'],
                        ),
                        _yesNo(
                          row[
                          'evidence_available'],
                        ),
                      ],
                    )
                        .toList(),
                  ),
                ],
              ),
            );
          },
        )
            .toList(),
      ),
    );
  }

  // ============================================================
  // ACTIONS CARD
  // ============================================================

  Widget _actionsCard() {
    return _sectionCard(
      'Corrective Action & Verification',
      Icons.build_outlined,
      _actions.isEmpty
          ? _emptyText(
        'No corrective actions entered.',
      )
          : Column(
        children: _actions
            .map(
              (
              Map<String, dynamic>
              action,
              ) =>
              _actionReportCard(
                action,
              ),
        )
            .toList(),
      ),
    );
  }

  Widget _actionReportCard(
      Map<String, dynamic> action,
      ) {
    Map<String, dynamic>?
    verification;

    final dynamic raw =
    action[
    'ccr_action_verifications'];

    if (raw is List &&
        raw.isNotEmpty &&
        raw.first is Map) {
      verification =
      Map<String, dynamic>.from(
        raw.first as Map,
      );
    } else if (raw is Map) {
      verification =
      Map<String, dynamic>.from(
        raw,
      );
    }

    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
      const EdgeInsets.all(14),
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFF8F9FB),
        borderRadius:
        BorderRadius.circular(10),
        border:
        Border.all(
          color:
          const Color(0xFFE2E5EA),
        ),
      ),
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          _screenMap(
            action,
            <String, String>{
              'Problem Statement':
              'problem_statement',
              'Occurrence Root Cause':
              'occurrence_root_cause',
              'Non-Detection Root Cause':
              'detection_root_cause',
              'Corrective Action':
              'corrective_action',
              'DRI':
              'dri',
              'Result Before':
              'result_before',
              'Result After':
              'result_after',
              'Due Date':
              'due_date',
              'Completion Date':
              'completion_date',
            },
          ),
          if (verification != null) ...[
            const SizedBox(
              height: 14,
            ),
            const Text(
              'Verification',
              style:
              TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            _screenMap(
              verification,
              <String, String>{
                'Verification Required':
                'verification_required',
                'Verification Status':
                'verification_status',
                'Verified By':
                'verified_by',
                'Verification Date':
                'verification_date',
                'Verification Method':
                'verification_method',
                'Verification Result':
                'verification_result',
                'Verification Remarks':
                'verification_remarks',
              },
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // EVIDENCE CARD
  // ============================================================

  Widget _evidenceCard() {
    return _sectionCard(
      'Evidence of Corrective Action',
      Icons.photo_library_outlined,
      _actionEvidence.isEmpty
          ? _emptyText(
        'No corrective action evidence entered.',
      )
          : Column(
        children:
        _actionEvidence
            .map(
              (
              Map<String,
                  dynamic>
              evidence,
              ) =>
              _evidenceReportCard(
                evidence,
              ),
        )
            .toList(),
      ),
    );
  }

  Widget _evidenceReportCard(
      Map<String, dynamic> evidence,
      ) {
    final dynamic rawAttachment =
    evidence[
    'ccr_attachments'];

    if (rawAttachment is! Map) {
      return _surfaceCard(
        child:
        Text(
          _value(
            evidence[
            'description'],
          ),
        ),
      );
    }

    final Map<String, dynamic>
    attachment =
    Map<String, dynamic>.from(
      rawAttachment,
    );

    return Container(
      width:
      double.infinity,
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
      const EdgeInsets.all(14),
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFF8F9FB),
        borderRadius:
        BorderRadius.circular(10),
        border:
        Border.all(
          color:
          const Color(0xFFE2E5EA),
        ),
      ),
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            _value(
              evidence[
              'evidence_type'],
            ),
            style:
            const TextStyle(
              fontSize: 13,
              fontWeight:
              FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          FutureBuilder<String?>(
            future:
            _signedUrl(
              attachment,
            ),
            builder: (
                BuildContext context,
                AsyncSnapshot<String?>
                snapshot,
                ) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const SizedBox(
                  height: 180,
                  child:
                  Center(
                    child:
                    CircularProgressIndicator(),
                  ),
                );
              }

              final String? url =
                  snapshot.data;

              if (url == null ||
                  url.isEmpty) {
                return _emptyText(
                  'Image unavailable.',
                );
              }

              return ClipRRect(
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
                child:
                Image.network(
                  url,
                  width:
                  double.infinity,
                  height: 240,
                  fit:
                  BoxFit.contain,
                  errorBuilder:
                      (
                      BuildContext context,
                      Object error,
                      StackTrace?
                      stackTrace,
                      ) {
                    return _emptyText(
                      'Image could not be loaded.',
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            _value(
              evidence[
              'description'],
            ),
            style:
            const TextStyle(
              fontSize: 12,
              color:
              Color(0xFF747B86),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CLOSURE CARD
  // ============================================================

  Widget _closureCard() {
    return Column(
      children: [
        _sectionCard(
          'Closure',
          Icons.check_circle_outline,
          _screenMap(
            _closure,
            <String, String>{
              'Closure Status':
              'closure_status',
              'Closure Summary':
              'closure_summary',
              'Customer Response':
              'customer_response',
              'Final Remarks':
              'final_remarks',
              'Closed By':
              'closed_by',
              'Closed At':
              'closed_at',
            },
          ),
        ),

        const SizedBox(height: 18),

        _customerFormatCard(),
      ],
    );
  }
  // ============================================================
  // CUSTOMER FORMAT
  // ============================================================

  Widget _customerFormatCard() {
    final document =
        _customerFormat;

    return _sectionCard(
      'Customer Format',
      Icons.file_present_outlined,
      document == null
          ? _emptyText(
        'No Customer Format was uploaded.',
      )
          : Container(
        width: double.infinity,
        padding:
        const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
          const Color(0xFFF8F9FB),
          borderRadius:
          BorderRadius.circular(10),
          border: Border.all(
            color:
            const Color(0xFFE2E5EA),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration:
              BoxDecoration(
                color:
                const Color(0xFFEFF3FF),
                borderRadius:
                BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons
                    .insert_drive_file_outlined,
                color:
                Color(0xFF3155C6),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    document[
                    'original_file_name']
                        ?.toString()
                        .trim()
                        .isNotEmpty ==
                        true
                        ? document[
                    'original_file_name']
                        .toString()
                        : document[
                    'title']
                        ?.toString() ??
                        'Customer Format',
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w700,
                      color:
                      Color(0xFF252A31),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    _documentSizeText(
                      document[
                      'file_size'],
                    ),
                    style:
                    const TextStyle(
                      fontSize: 11,
                      color:
                      Color(0xFF7A818C),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            FilledButton.icon(
              onPressed:
              _downloadingCustomerFormat
                  ? null
                  : () =>
                  _downloadCustomerFormat(
                    document,
                  ),
              icon:
              _downloadingCustomerFormat
                  ? const SizedBox(
                width: 16,
                height: 16,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                  Colors.white,
                ),
              )
                  : const Icon(
                Icons
                    .download_outlined,
              ),
              label: Text(
                _downloadingCustomerFormat
                    ? 'Downloading...'
                    : 'Download',
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ============================================================
  // DOWNLOAD CUSTOMER FORMAT
  // ============================================================

  Future<void> _downloadCustomerFormat(
      Map<String, dynamic> document,
      ) async {
    final String? fileUrl =
    _attachmentFileUrl(document);

    if (fileUrl == null) {
      _showMessage(
        'Customer Format attachment ID is missing.',
        error: true,
      );
      return;
    }

    setState(() {
      _downloadingCustomerFormat = true;
    });

    try {
      final http.Response response =
      await http.get(Uri.parse(fileUrl));

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          'Unable to download Customer Format.',
        );
      }

      final Uint8List bytes = response.bodyBytes;
      final String fileName =
      document['original_file_name']
          ?.toString()
          .trim()
          .isNotEmpty ==
          true
          ? document[
      'original_file_name']
          .toString()
          : document['title']
          ?.toString()
          .trim()
          .isNotEmpty ==
          true
          ? document['title']
          .toString()
          : 'customer-format';

      final String extension =
      _fileExtensionFromName(
        fileName,
      );

      final String mimeType =
      document['mime_type']
          ?.toString()
          .trim()
          .isNotEmpty ==
          true
          ? document['mime_type']
          .toString()
          : 'application/octet-stream';

      await FileSaver.instance.saveFile(
        name: _removeFileExtension(
          fileName,
        ),
        bytes: bytes,
        fileExtension: extension,
        mimeType: MimeType.other,
        customMimeType: mimeType,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Customer Format downloaded successfully.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanError(e),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloadingCustomerFormat = false;
        });
      }
    }
  }
  // ============================================================
  // SCREEN MAP
  // ============================================================

  Widget _screenMap(
      Map<String, dynamic>? data,
      Map<String, String> fields,
      ) {
    if (data == null) {
      return _emptyText(
        'No data entered.',
      );
    }

    return LayoutBuilder(
      builder: (
          BuildContext context,
          BoxConstraints constraints,
          ) {
        final bool twoColumns =
            constraints.maxWidth >=
                800;

        final List<Widget>
        children =
        fields.entries
            .map(
              (
              MapEntry<String, String>
              entry,
              ) =>
              SizedBox(
                width:
                twoColumns
                    ? (constraints
                    .maxWidth -
                    16) /
                    2
                    : double.infinity,
                child:
                _reportField(
                  entry.key,
                  entry.key == 'Closed At'
                      ? _formatReportDate(data[entry.value])
                      : _value(data[entry.value]),
                ),
              ),
        )
            .toList();

        return Wrap(
          spacing: 16,
          runSpacing: 14,
          children: children,
        );
      },
    );
  }
  String _formatReportDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return '-';
    }

    final parsed = DateTime.tryParse(value.toString());

    if (parsed != null) {
      return '${parsed.day.toString().padLeft(2, '0')}/'
          '${parsed.month.toString().padLeft(2, '0')}/'
          '${parsed.year}';
    }

    return value.toString().split('T').first;
  }
  // ============================================================
  // REPORT FIELD
  // ============================================================

  Widget _reportField(
      String label,
      String value,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
          const TextStyle(
            fontSize: 11.5,
            fontWeight:
            FontWeight.w600,
            color:
            Color(0xFF626873),
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        Container(
          width:
          double.infinity,
          padding:
          const EdgeInsets.all(10),
          decoration:
          BoxDecoration(
            color:
            const Color(0xFFF8F9FB),
            borderRadius:
            BorderRadius.circular(9),
            border:
            Border.all(
              color:
              const Color(0xFFE2E5EA),
            ),
          ),
          child:
          Text(
            value,
            style:
            const TextStyle(
              fontSize: 12.5,
              color:
              Color(0xFF30343A),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DATA TABLE
  // ============================================================

  Widget _dataTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    if (rows.isEmpty) {
      return _emptyText(
        'No records entered.',
      );
    }

    return SingleChildScrollView(
      scrollDirection:
      Axis.horizontal,
      child:
      DataTable(
        headingRowHeight: 42,
        dataRowMinHeight: 42,
        dataRowMaxHeight: 100,
        columns:
        headers
            .map(
              (
              String header,
              ) =>
              DataColumn(
                label:
                Text(
                  header,
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
        )
            .toList(),
        rows:
        rows
            .map(
              (
              List<String> row,
              ) =>
              DataRow(
                cells:
                row
                    .map(
                      (
                      String value,
                      ) =>
                      DataCell(
                        ConstrainedBox(
                          constraints:
                          const BoxConstraints(
                            maxWidth:
                            230,
                          ),
                          child:
                          Text(
                            value,
                            maxLines:
                            5,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            const TextStyle(
                              fontSize:
                              12,
                            ),
                          ),
                        ),
                      ),
                )
                    .toList(),
              ),
        )
            .toList(),
      ),
    );
  }

  // ============================================================
  // ATTACHMENTS CARD
  // ============================================================

  Widget _attachmentsCard(
      String title,
      List<Map<String, dynamic>>
      attachments,
      ) {
    return _sectionCard(
      title,
      Icons.photo_library_outlined,
      attachments.isEmpty
          ? _emptyText(
        'No images entered.',
      )
          : Wrap(
        spacing: 12,
        runSpacing: 12,
        children:
        attachments
            .map(
              (
              Map<String,
                  dynamic>
              attachment,
              ) =>
              _attachmentThumbnail(
                attachment,
              ),
        )
            .toList(),
      ),
    );
  }

  // ============================================================
  // ATTACHMENT THUMBNAIL
  // ============================================================

  Widget _attachmentThumbnail(
      Map<String, dynamic>
      attachment,
      ) {
    return SizedBox(
      width: 210,
      height: 170,
      child:
      ClipRRect(
        borderRadius:
        BorderRadius.circular(10),
        child:
        FutureBuilder<String?>(
          future:
          _signedUrl(
            attachment,
          ),
          builder: (
              BuildContext context,
              AsyncSnapshot<String?>
              snapshot,
              ) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child:
                CircularProgressIndicator(),
              );
            }

            final String? url =
                snapshot.data;

            if (url == null ||
                url.isEmpty) {
              return _emptyText(
                'Image unavailable.',
              );
            }

            return Image.network(
              url,
              fit:
              BoxFit.cover,
              errorBuilder:
                  (
                  BuildContext context,
                  Object error,
                  StackTrace?
                  stackTrace,
                  ) =>
                  _emptyText(
                    'Image unavailable.',
                  ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard(
      String title,
      IconData icon,
      Widget child,
      ) {
    return _surfaceCard(
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(icon),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child:
                Text(
                  title,
                  style:
                  const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 18,
          ),
          child,
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _emptyText(
      String text,
      ) {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(18),
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFF8F9FB),
        borderRadius:
        BorderRadius.circular(10),
        border:
        Border.all(
          color:
          const Color(0xFFE2E5EA),
        ),
      ),
      child:
      Text(
        text,
        style:
        const TextStyle(
          fontSize: 12,
          color:
          Color(0xFF747B86),
        ),
      ),
    );
  }

  // ============================================================
  // SURFACE CARD
  // ============================================================

  Widget _surfaceCard({
    required Widget child,
  }) {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(20),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        border:
        Border.all(
          color:
          const Color(0xFFE3E6EB),
        ),
      ),
      child:
      child,
    );
  }

  // ============================================================
  // ICON BOX
  // ============================================================

  Widget _iconBox(
      IconData icon,
      ) {
    return Container(
      width: 40,
      height: 40,
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFEFF3FF),
        borderRadius:
        BorderRadius.circular(11),
      ),
      child:
      Icon(
        icon,
        color:
        const Color(0xFF3155C6),
      ),
    );
  }

  // ============================================================
  // CHIP
  // ============================================================

  Widget _chip(
      String text,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFF3F4F6),
        borderRadius:
        BorderRadius.circular(8),
      ),
      child:
      Text(
        text,
        style:
        const TextStyle(
          fontSize: 11,
          fontWeight:
          FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // ERROR VIEW
  // ============================================================

  Widget _errorView() {
    return Center(
      child:
      _surfaceCard(
        child:
        Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 42,
              color:
              Color(0xFFE14B4B),
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              'Could not load CCR Report',
              style:
              TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              _error ?? '',
              textAlign:
              TextAlign.center,
            ),
            const SizedBox(
              height: 18,
            ),
            FilledButton(
              onPressed:
              _load,
              child:
              const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LIST CONVERSION
  // ============================================================

  List<Map<String, dynamic>>
  _asMapList(
      dynamic value,
      ) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map(
          (
          Map item,
          ) =>
      Map<String, dynamic>.from(
        item,
      ),
    )
        .toList();
  }

  // ============================================================
  // FIND BY ID
  // ============================================================

  Map<String, dynamic>? _findById(
      List<Map<String, dynamic>>
      list,
      String? id,
      ) {
    if (id == null ||
        id.isEmpty) {
      return null;
    }

    for (final Map<String, dynamic>
    item in list) {
      if (item['id']?.toString() ==
          id) {
        return item;
      }
    }

    return null;
  }

  // ============================================================
  // CATEGORY NAME
  // ============================================================

  String _categoryName(
      String categoryId,
      ) {
    final Map<String, dynamic>?
    category =
    _findById(
      _categories,
      categoryId,
    );

    return _value(
      category?['name'],
    );
  }

  // ============================================================
  // VALUE
  // ============================================================

  String _value(
      dynamic value,
      ) {
    if (value == null) {
      return '-';
    }

    if (value is bool) {
      return value
          ? 'Yes'
          : 'No';
    }

    final String text =
    value.toString().trim();

    return text.isEmpty
        ? '-'
        : text;
  }

  // ============================================================
  // YES / NO
  // ============================================================

  String _yesNo(
      dynamic value,
      ) {
    if (value is bool) {
      return value
          ? 'Yes'
          : 'No';
    }

    return _value(value);
  }

  // ============================================================
  // DISPLAY NUMBER
  // ============================================================

  String _displayNumber() {
    final int number =
        int.tryParse(
          _ccr?[
          'ccr_number']
              ?.toString() ??
              '',
        ) ??
            0;

    if (number <= 0) {
      return 'CCR';
    }

    return 'CCR-${number.toString().padLeft(6, '0')}';
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
      String message, {
        bool error = false,
      }) {
    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
        Text(message),
        backgroundColor:
        error
            ? const Color(
          0xFFC62828,
        )
            : null,
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // ERROR CLEANER
  // ============================================================

  String _cleanError(
      dynamic error,
      ) {
    return error
        .toString()
        .replaceFirst(
      'Exception: ',
      '',
    )
        .replaceFirst(
      'PostgrestException(message: ',
      '',
    );
  }
}

// ============================================================
// SCREEN FISHBONE
// ============================================================

class _FishboneReportWidget
    extends StatelessWidget {
  const _FishboneReportWidget({
    required this.categories,
    required this.causes,
    required this.problem,
  });

  final List<Map<String, dynamic>>
  categories;

  final List<Map<String, dynamic>>
  causes;

  final String problem;

  @override
  Widget build(
      BuildContext context,
      ) {
    if (categories.isEmpty) {
      return Container(
        width:
        double.infinity,
        padding:
        const EdgeInsets.all(20),
        decoration:
        BoxDecoration(
          color:
          const Color(0xFFF8F9FB),
          borderRadius:
          BorderRadius.circular(12),
          border:
          Border.all(
            color:
            const Color(0xFFE2E5EA),
          ),
        ),
        child:
        const Text(
          'No Fishbone categories entered.',
        ),
      );
    }

    return SizedBox(
      height: 560,
      child:
      SingleChildScrollView(
        scrollDirection:
        Axis.horizontal,
        child:
        SizedBox(
          width: 1180,
          height: 560,
          child:
          CustomPaint(
            painter:
            _FishbonePainter(
              categoryCount:
              categories.length,
            ),
            child:
            Stack(
              children: [
                Positioned(
                  right: 20,
                  top: 245,
                  child:
                  SizedBox(
                    width: 220,
                    child:
                    _problemNode(
                      problem,
                    ),
                  ),
                ),
                ..._categoryNodes(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _categoryNodes() {
    final List<Widget>
    nodes =
    <Widget>[];

    final int upperCount =
    (categories.length / 2)
        .ceil();

    final List<Map<String, dynamic>>
    upper =
    categories
        .take(
      upperCount,
    )
        .toList();

    final List<Map<String, dynamic>>
    lower =
    categories
        .skip(
      upperCount,
    )
        .toList();

    for (int i = 0;
    i < upper.length;
    i++) {
      nodes.add(
        _buildCategoryNode(
          upper[i],
          true,
          i,
          upper.length,
        ),
      );
    }

    for (int i = 0;
    i < lower.length;
    i++) {
      nodes.add(
        _buildCategoryNode(
          lower[i],
          false,
          i,
          lower.length,
        ),
      );
    }

    return nodes;
  }

  Widget _buildCategoryNode(
      Map<String, dynamic> category,
      bool upper,
      int index,
      int count,
      ) {
    final String categoryId =
        category['id']
            ?.toString() ??
            '';

    final List<Map<String, dynamic>>
    categoryCauses =
    causes
        .where(
          (
          Map<String, dynamic>
          cause,
          ) =>
      cause['category_id']
          ?.toString() ==
          categoryId,
    )
        .toList();

    // Match the exact branch junction positions used
    // by _FishbonePainter.
    const double diagramWidth = 1180;
    const double nodeWidth = 235;
    const double branchOffsetX = 70;

    final double spineEndX =
        diagramWidth - 260;

    final double usableWidth =
        spineEndX - 120;

    final double junctionX = count <= 1
        ? 80 + usableWidth / 2
        : 80 +
        (usableWidth / (count + 1)) *
            (index + 1);

    final double branchEndX =
        junctionX - branchOffsetX;

    final double left =
        branchEndX - nodeWidth / 2;

    final double top = upper ? 35 : 450;

    return Positioned(
      left:
      left,
      top:
      top,
      width:
      235,
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            category['name']
                ?.toString() ??
                '-',
            style:
            const TextStyle(
              fontSize: 15,
              fontWeight:
              FontWeight.w800,
              color:
              Color(0xFF202124),
            ),
          ),
          const SizedBox(
            height: 7,
          ),
          ...categoryCauses.map(
                (
                Map<String, dynamic>
                cause,
                ) =>
                Container(
                  width:
                  double.infinity,
                  margin:
                  const EdgeInsets.only(
                    bottom: 5,
                  ),
                  padding:
                  const EdgeInsets.all(
                    7,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.white,
                    border:
                    Border.all(
                      color:
                      const Color(
                        0xFFDCE2EA,
                      ),
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      7,
                    ),
                  ),
                  child:
                  Text(
                    cause[
                    'cause_text']
                        ?.toString() ??
                        '-',
                    maxLines:
                    4,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 10.5,
                      color:
                      Color(0xFF374151),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _problemNode(
      String problem,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(12),
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFEFF3FF),
        borderRadius:
        BorderRadius.circular(10),
        border:
        Border.all(
          color:
          const Color(0xFF3155C6),
          width: 1.3,
        ),
      ),
      child:
      Text(
        problem,
        maxLines:
        5,
        overflow:
        TextOverflow.ellipsis,
        style:
        const TextStyle(
          fontSize: 12,
          fontWeight:
          FontWeight.w700,
          color:
          Color(0xFF172033),
        ),
      ),
    );
  }
}

// ============================================================
// SCREEN FISHBONE PAINTER
// ============================================================

class _FishbonePainter
    extends CustomPainter {
  const _FishbonePainter({
    required this.categoryCount,
  });

  final int categoryCount;

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    if (size.width <= 0 ||
        size.height <= 0) {
      return;
    }

    final Paint paint =
    Paint()
      ..color =
      const Color(0xFF3182F6)
      ..strokeWidth =
      2
      ..style =
          PaintingStyle.stroke;

    final double centerY =
        size.height / 2;

    final double spineEndX =
        size.width - 260;

    canvas.drawLine(
      Offset(
        20,
        centerY,
      ),
      Offset(
        spineEndX,
        centerY,
      ),
      paint,
    );

    if (categoryCount <= 0) {
      return;
    }

    final int upperCount =
    (categoryCount / 2)
        .ceil();

    final int lowerCount =
        categoryCount -
            upperCount;

    final double usableWidth =
        spineEndX -
            120;

    final List<double>
    upper =
    _junctions(
      upperCount,
      80,
      usableWidth,
    );

    final List<double>
    lower =
    _junctions(
      lowerCount,
      80,
      usableWidth,
    );

    for (final double x
    in upper) {
      canvas.drawLine(
        Offset(
          x,
          centerY,
        ),
        Offset(
          x - 70,
          centerY - 160,
        ),
        paint,
      );
    }

    for (final double x
    in lower) {
      canvas.drawLine(
        Offset(
          x,
          centerY,
        ),
        Offset(
          x - 70,
          centerY + 160,
        ),
        paint,
      );
    }
  }

  List<double> _junctions(
      int count,
      double start,
      double width,
      ) {
    if (count <= 0) {
      return <double>[];
    }

    if (count == 1) {
      return <double>[
        start +
            width / 2,
      ];
    }

    final double spacing =
        width /
            (count + 1);

    return List<double>.generate(
      count,
          (int index) =>
      start +
          spacing *
              (index + 1),
    );
  }

  @override
  bool shouldRepaint(
      covariant _FishbonePainter
      oldDelegate,
      ) {
    return oldDelegate
        .categoryCount !=
        categoryCount;
  }
}