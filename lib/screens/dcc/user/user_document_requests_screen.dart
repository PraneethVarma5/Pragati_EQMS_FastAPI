import 'package:flutter/material.dart';

import '../../../models/dcc/dcc_document_request.dart';
import '../../../services/dcc/dcc_document_request_service.dart';
import '../../../services/dcc/dcc_session.dart';
import 'new_document_screen.dart';

class UserDocumentRequestsScreen
    extends StatefulWidget {
  const UserDocumentRequestsScreen({
    super.key,
  });

  @override
  State<UserDocumentRequestsScreen> createState() =>
      _UserDocumentRequestsScreenState();
}

class _UserDocumentRequestsScreenState
    extends State<UserDocumentRequestsScreen> {

  late Future<List<DccDocumentRequest>>
  _requestsFuture;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    final user = DccSession.currentUser;

    if (user == null) {
      _requestsFuture =
          Future.value(<DccDocumentRequest>[]);
      return;
    }

    _requestsFuture =
        DccDocumentRequestService
            .getRequestsForUser(
          user.email,
        );
  }

  Future<void> _refresh() async {
    setState(() {
      _loadRequests();
    });

    await _requestsFuture;
  }

  Future<void> _openUpload(
      DccDocumentRequest request,
      ) async {

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewDocumentScreen(
          documentRequestId: request.id,
          restrictedUploadMode: true,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _loadRequests();
      });
    }
  }

  String _statusText(
      String status,
      ) {

    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pending DCC';

      case 'NOTIFIED':
        return 'Ready to Upload';

      case 'UPLOADED':
        return 'Uploaded';

      default:
        return status;
    }
  }

  Color _statusColor(
      String status,
      ) {

    switch (status.toUpperCase()) {
      case 'NOTIFIED':
        return const Color(0xFF249653);

      case 'UPLOADED':
        return const Color(0xFF3155D9);

      case 'PENDING':
      default:
        return const Color(0xFFE65100);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'My Document Requests',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor:
        const Color(0xFF172033),
        elevation: 0,
      ),

      body: FutureBuilder<
          List<DccDocumentRequest>>(
        future: _requestsFuture,

        builder: (
            context,
            snapshot,
            ) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                const EdgeInsets.all(30),
                child: Text(
                  'Unable to load document requests.\n\n'
                      '${snapshot.error}',
                  textAlign:
                  TextAlign.center,
                ),
              ),
            );
          }

          final requests =
              snapshot.data ?? [];

          if (requests.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics:
                const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 54,
                          color: Color(0xFF9AA2B1),
                        ),
                        SizedBox(height: 14),
                        Text(
                          'No document requests yet.',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                            FontWeight.w700,
                            color:
                            Color(0xFF4B5563),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Your submitted requests will appear here.',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                            Color(0xFF9AA2B1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,

            child: ListView.separated(
              padding:
              const EdgeInsets.all(24),

              itemCount:
              requests.length,

              separatorBuilder:
                  (_, _) =>
              const SizedBox(height: 14),

              itemBuilder:
                  (context, index) {

                final request =
                requests[index];

                final status =
                request.status
                    .toUpperCase();

                final readyToUpload =
                    status == 'NOTIFIED';

                final uploaded =
                    status == 'UPLOADED';

                final statusColor =
                _statusColor(status);

                return Container(
                  padding:
                  const EdgeInsets.all(20),

                  decoration:
                  BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(16),
                    border: Border.all(
                      color:
                      const Color(0xFFE4E8F0),
                    ),
                  ),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      Row(
                        children: [

                          Container(
                            width: 46,
                            height: 46,
                            decoration:
                            BoxDecoration(
                              color:
                              const Color(
                                0xFFEFF3FF,
                              ),
                              borderRadius:
                              BorderRadius.circular(
                                12,
                              ),
                            ),
                            child:
                            const Icon(
                              Icons.description_outlined,
                              color:
                              Color(0xFF3155D9),
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [

                                Text(
                                  request.documentName,
                                  style:
                                  const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                    FontWeight.w800,
                                    color:
                                    Color(0xFF172033),
                                  ),
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  request.description,
                                  maxLines: 2,
                                  overflow:
                                  TextOverflow.ellipsis,
                                  style:
                                  const TextStyle(
                                    fontSize: 12,
                                    color:
                                    Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          Container(
                            padding:
                            const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration:
                            BoxDecoration(
                              color:
                              statusColor.withValues(
                                alpha: 0.10,
                              ),
                              borderRadius:
                              BorderRadius.circular(
                                20,
                              ),
                            ),
                            child: Text(
                              _statusText(status),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight:
                                FontWeight.w800,
                                color:
                                statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      const Divider(
                        height: 1,
                      ),

                      const SizedBox(height: 15),

                      _detailRow(
                        'Document No',
                        request.documentNo ?? '-',
                      ),

                      _detailRow(
                        'Document Type',
                        request.documentType ?? '-',
                      ),

                      _detailRow(
                        'Department',
                        request.department ?? '-',
                      ),

                      _detailRow(
                        'Candidate',
                        request.candidateName ??
                            request.userName,
                      ),

                      const SizedBox(height: 16),

                      if (readyToUpload)
                        Align(
                          alignment:
                          Alignment.centerRight,
                          child:
                          ElevatedButton.icon(
                            onPressed:
                                () => _openUpload(
                              request,
                            ),
                            icon: const Icon(
                              Icons.cloud_upload_outlined,
                            ),
                            label: const Text(
                              'Upload Document',
                            ),
                            style:
                            ElevatedButton.styleFrom(
                              backgroundColor:
                              const Color(
                                0xFF3155D9,
                              ),
                              foregroundColor:
                              Colors.white,
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 13,
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

                      if (uploaded)
                        Align(
                          alignment:
                          Alignment.centerRight,
                          child: Container(
                            padding:
                            const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration:
                            BoxDecoration(
                              color:
                              const Color(
                                0xFFE8F5EC,
                              ),
                              borderRadius:
                              BorderRadius.circular(
                                10,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize:
                              MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 18,
                                  color:
                                  Color(0xFF249653),
                                ),
                                SizedBox(width: 7),
                                Text(
                                  'Document Uploaded',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                    FontWeight.w700,
                                    color:
                                    Color(0xFF249653),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(
      String label,
      String value,
      ) {

    return Padding(
      padding:
      const EdgeInsets.only(bottom: 8),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          SizedBox(
            width: 120,
            child: Text(
              label,
              style:
              const TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w700,
                color:
                Color(0xFF6B7280),
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style:
              const TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.w600,
                color:
                Color(0xFF172033),
              ),
            ),
          ),
        ],
      ),
    );
  }
}