import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/dcc/dcc_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../../models/dcc/dcc_document.dart';
import '../../../services/dcc/dcc_document_service.dart';
import '../../../services/dcc/dcc_session.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReleasedDocumentsScreen extends StatefulWidget {
  const ReleasedDocumentsScreen({super.key});

  @override
  State<ReleasedDocumentsScreen> createState() =>
      _ReleasedDocumentsScreenState();
}

class _ReleasedDocumentsScreenState
    extends State<ReleasedDocumentsScreen> {
  List<DccDocument> _documents = [];

  String _searchText = '';

  bool _isLoading = true;
  bool _isOpening = false;

  final TextEditingController _searchController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReleasedDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReleasedDocuments() async {
    try {
      final documents =
      await DccDocumentService.getDocuments();

      final loggedInUser =
          DccSession.currentUser;

      final released = documents.where(
            (document) {
          if (document.status != 'RELEASED') {
            return false;
          }

          // Before login:
          // show every released document.
          if (loggedInUser == null) {
            return true;
          }

          final userEmail =
          loggedInUser.email.trim().toLowerCase();

          // Normal User:
          // show documents created/released through
          // their own document workflow.
          if (loggedInUser.role == 'USER') {
            return document.createdByEmail
                .trim()
                .toLowerCase() ==
                userEmail;
          }

          // DCC:
          // show documents released by this DCC officer.
          if (loggedInUser.role == 'DCC') {
            return document.releasedByEmail
                .trim()
                .toLowerCase() ==
                userEmail;
          }

          // Admin can see all released documents.
          if (loggedInUser.role == 'ADMIN') {
            return true;
          }

          // HOD:
          // show released documents belonging to
          // their department/approval workflow.
          if (loggedInUser.role == 'HOD') {
            return document.hodEmail
                .trim()
                .toLowerCase() ==
                userEmail;
          }

          return false;
        },
      ).toList();

      released.sort(
            (a, b) {
          final documentCompare =
          a.documentNo.compareTo(
            b.documentNo,
          );

          if (documentCompare != 0) {
            return documentCompare;
          }

          return b.revision.compareTo(
            a.revision,
          );
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _documents = released;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load released documents.',
          ),
        ),
      );
    }
  }

  List<DccDocument> get _filteredDocuments {
    final search =
    _searchText.trim().toLowerCase();

    if (search.isEmpty) {
      return _documents;
    }

    return _documents.where((document) {
      return document.documentNo
          .toLowerCase()
          .contains(search) ||
          document.documentName
              .toLowerCase()
              .contains(search) ||
          document.documentType
              .toLowerCase()
              .contains(search) ||
          document.department
              .toLowerCase()
              .contains(search) ||
          document.releasedPdfName
              .toLowerCase()
              .contains(search);
    }).toList();
  }
  Future<void> _createSampleReleasedDocument() async {
    try {
      final directory =
      await getApplicationSupportDirectory();

      await directory.create(
        recursive: true,
      );

      final pdfPath =
          '${directory.path}${Platform.pathSeparator}'
          'INPC-SOP-017_Rev1.pdf';
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (context) {
            return pw.Container(
              padding:
              const pw.EdgeInsets.only(
                bottom: 12,
              ),
              decoration:
              const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColors.grey,
                  ),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment:
                pw.MainAxisAlignment
                    .spaceBetween,
                children: [
                  pw.Text(
                    'eQMS',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight:
                      pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'CONTROLLED COPY',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight:
                      pw.FontWeight.bold,
                      color:
                      PdfColors.red,
                    ),
                  ),
                ],
              ),
            );
          },
          footer: (context) {
            return pw.Align(
              alignment:
              pw.Alignment.centerRight,
              child: pw.Text(
                'Page ${context.pageNumber}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey,
                ),
              ),
            );
          },
          build: (context) {
            return [
              pw.SizedBox(height: 20),

              pw.Center(
                child: pw.Text(
                  'STANDARD OPERATING PROCEDURE',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight:
                    pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.SizedBox(height: 8),

              pw.Center(
                child: pw.Text(
                  'Runout Testing Instructions',
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight:
                    pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.SizedBox(height: 25),

              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(2),
                },
                children: [
                  _pdfInfoRow(
                    'Document No',
                    'INPC-SOP-017',
                  ),
                  _pdfInfoRow(
                    'Document Type',
                    'SOP',
                  ),
                  _pdfInfoRow(
                    'Department',
                    'Quality',
                  ),
                  _pdfInfoRow(
                    'Revision',
                    '1',
                  ),
                  _pdfInfoRow(
                    'Revision Date',
                    '17.08.2026',
                  ),
                  _pdfInfoRow(
                    'Release Status',
                    'RELEASED',
                  ),
                ],
              ),

              pw.SizedBox(height: 25),

              pw.Text(
                '1. Purpose',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight:
                  pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 8),

              pw.Text(
                'This document defines the standard '
                    'procedure for performing runout testing '
                    'during quality inspection.',
                style: const pw.TextStyle(
                  fontSize: 11,
                ),
              ),

              pw.SizedBox(height: 18),

              pw.Text(
                '2. Procedure',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight:
                  pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 8),

              pw.Bullet(
                text:
                'Verify the component identification '
                    'before testing.',
              ),

              pw.Bullet(
                text:
                'Place the component correctly on '
                    'the inspection fixture.',
              ),

              pw.Bullet(
                text:
                'Perform the runout measurement '
                    'using the approved measuring device.',
              ),

              pw.Bullet(
                text:
                'Record the measured value in the '
                    'inspection record.',
              ),

              pw.SizedBox(height: 18),

              pw.Text(
                '3. Acceptance Criteria',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight:
                  pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 8),

              pw.Text(
                'The measured runout shall comply with '
                    'the applicable product specification '
                    'and approved inspection limits.',
                style: const pw.TextStyle(
                  fontSize: 11,
                ),
              ),

              pw.SizedBox(height: 35),

              pw.Container(
                padding:
                const pw.EdgeInsets.all(12),
                decoration:
                pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.grey,
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Document Control',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight:
                        pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Released by: DCC Officer',
                      style:
                      const pw.TextStyle(
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      'Release date: 17.08.2026',
                      style:
                      const pw.TextStyle(
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      'Copy status: Controlled',
                      style:
                      const pw.TextStyle(
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();

      final file = File(pdfPath);

      await file.writeAsBytes(
        bytes,
        flush: true,
      );

      final currentUser =
          DccSession.currentUser;

      final releasedByEmail =
          currentUser?.email ?? 'officer@eqms.com';

      final releasedByName =
          currentUser?.name ?? 'DCC Officer';

      final sampleDocument = DccDocument(
        id: 'SAMPLE-RELEASED-001',
        documentNo: 'INPC-SOP-017',
        documentName:
        'Runout Testing Instructions',
        documentType: 'SOP',
        department: 'Quality',
        candidateName: '',
        employeeId: '',
        attachmentPath: '',
        attachmentName:
        'INPC-SOP-017.docx',
        createdByName:
        'Ravi Kumar',
        createdByEmail:
        'ravi@eqms.com',
        releasedPdfPath: pdfPath,
        releasedPdfName:
        'INPC-SOP-017_Rev1.pdf',
        releasedByName:
        releasedByName,
        releasedByEmail:
        releasedByEmail,
        hodName:
        'Rajesh Kumar',
        hodEmail:
        'rajesh@eqms.com',
        status: 'RELEASED',
        revision: 1,
        revisionDate: '17.08.2026',
        rejectionReason: '',
      );

      await DccDocumentService.addDocument(
        sampleDocument,
      );

      await _loadReleasedDocuments();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sample released document created successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to create sample document: $e',
          ),
        ),
      );
    }
  }

  pw.TableRow _pdfInfoRow(
      String label,
      String value,
      ) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding:
          const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight:
              pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Padding(
          padding:
          const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: const pw.TextStyle(
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
  Future<void> _viewPdf(
      DccDocument document,
      ) async {
    try {
      final storagePath =
      document.releasedPdfPath.trim();

      if (storagePath.isEmpty) {
        throw Exception(
          'The released PDF is not available.',
        );
      }

      final url =
      await DccStorageService.createSignedUrl(
        storagePath,
        expiresIn: 3600,
      );

      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.platformDefault,
      );

      if (!launched) {
        throw Exception(
          'The browser could not open the PDF.',
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open PDF: $e',
          ),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final documents = _filteredDocuments;

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'Released Documents',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor:
        const Color(0xFF172033),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadReleasedDocuments,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        DccSession.currentUser == null
                            ? 'Released Documents'
                            : 'My Released Documents',
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF172033),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        DccSession.currentUser == null
                            ? 'View all documents released by DCC.'
                            : 'View documents released by you.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 360,
                  child: TextField(
                    controller:
                    _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                      });
                    },
                    decoration:
                    InputDecoration(
                      hintText:
                      'Search documents...',
                      prefixIcon:
                      const Icon(
                        Icons
                            .search_rounded,
                      ),
                      suffixIcon:
                      _searchText.isNotEmpty
                          ? IconButton(
                        onPressed: () {
                          _searchController
                              .clear();

                          setState(() {
                            _searchText =
                            '';
                          });
                        },
                        icon:
                        const Icon(
                          Icons
                              .clear_rounded,
                        ),
                      )
                          : null,
                      filled: true,
                      fillColor:
                      Colors.white,
                      border:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          12,
                        ),
                        borderSide:
                        const BorderSide(
                          color: Color(
                            0xFFE4E8F0,
                          ),
                        ),
                      ),
                      enabledBorder:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          12,
                        ),
                        borderSide:
                        const BorderSide(
                          color: Color(
                            0xFFE4E8F0,
                          ),
                        ),
                      ),
                      focusedBorder:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          12,
                        ),
                        borderSide:
                        const BorderSide(
                          color: Color(
                            0xFF3155D9,
                          ),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            Expanded(
              child: _buildDocumentList(
                documents,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentList(
      List<DccDocument> documents,
      ) {
    if (documents.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE4E8F0),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Icon(
                Icons.picture_as_pdf_outlined,
                size: 50,
                color: Color(0xFF9AA2B1),
              ),
              SizedBox(height: 12),
              Text(
                'No released documents found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  Color(0xFF4B5563),
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Documents released by DCC will appear here.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9AA2B1),
                ),
              ),

              const SizedBox(height: 18),

              OutlinedButton.icon(
                onPressed:
                _createSampleReleasedDocument,
                icon: const Icon(
                  Icons.science_outlined,
                ),
                label: const Text(
                  'Create Sample Released Document',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE4E8F0),
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: documents.length,
        separatorBuilder: (_, _) =>
        const Divider(
          height: 1,
        ),
        itemBuilder: (context, index) {
          return _buildDocumentTile(
            documents[index],
          );
        },
      ),
    );
  }

  Widget _buildDocumentTile(
      DccDocument document,
      ) {
    final hasPdf =
        document.releasedPdfPath
            .trim()
            .isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color:
              const Color(0xFFFFEBEE),
              borderRadius:
              BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Color(0xFFD32F2F),
              size: 27,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  document.documentNo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Color(0xFF172033),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  document.documentName,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w600,
                    color:
                    Color(0xFF4B5563),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '${document.documentType}  •  '
                      '${document.department}',
                  style: const TextStyle(
                    fontSize: 11,
                    color:
                    Color(0xFF8A93A3),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Revision',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF9AA2B1),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Rev ${document.revision}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF172033),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Released',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF9AA2B1),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  document.revisionDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color:
                    Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 15),

          OutlinedButton.icon(
            onPressed: hasPdf && !_isOpening
                ? () {
              _viewPdf(document);
            }
                : null,
            icon: const Icon(
              Icons.visibility_outlined,
              size: 17,
            ),
            label: Text(
              hasPdf
                  ? 'View PDF'
                  : 'PDF Pending',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor:
              const Color(0xFF3155D9),
              padding:
              const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}