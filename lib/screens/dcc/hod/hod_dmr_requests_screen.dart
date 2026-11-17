import 'package:flutter/material.dart';

import '../../../models/dcc/dcc_activity.dart';
import '../../../models/dcc/dcc_dmr_request.dart';
import '../../../models/dcc/dcc_notification.dart';
import '../../../services/dcc/dcc_activity_service.dart';
import '../../../services/dcc/dcc_dmr_service.dart';
import '../../../services/dcc/dcc_notification_service.dart';
import '../../../services/dcc/dcc_session.dart';
import '../../../services/realtime_service.dart';
import '../../../services/app_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HodDmrRequestsScreen
    extends StatefulWidget {
  const HodDmrRequestsScreen({
    super.key,
  });

  @override
  State<HodDmrRequestsScreen>
  createState() =>
      _HodDmrRequestsScreenState();
}

class _HodDmrRequestsScreenState
    extends State<HodDmrRequestsScreen> {
  List<DccDmrRequest> _requests = [];

  bool _isLoading = true;
  bool _isRefreshing = false;

  RealtimeChannel? _dmrChannel;

  // Current hardcoded DCC account.
  // When the admin/user-management system is
  // connected fully, this will come from the
  // DCC user list instead.
  static const List<String>
  _dccEmails = [
    'officer@eqms.com',
  ];

  @override
  void initState() {
    super.initState();

    _loadRequests();
    _subscribeToLiveUpdates();
  }

  @override
  void dispose() {
    _dmrChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToLiveUpdates() {
    final user = DccSession.currentUser;

    if (user == null) return;

    // A new DMR request lands the instant a User submits one for
    // this HOD — no manual reload needed to see it.
    _dmrChannel = RealtimeService.subscribeToTable(
      table: 'dcc_dmr_requests',
      onInsert: (row) {
        final hodEmail =
        row['hod_email']?.toString().trim().toLowerCase() ?? '';

        if (hodEmail != user.email.trim().toLowerCase()) {
          return;
        }

        showAppNotification(
          'New DMR request: ${row['document_no'] ?? ''} from '
              '${row['requested_by_name'] ?? 'a user'}',
          icon: Icons.mark_email_unread_rounded,
        );

        _loadRequests(refresh: true);
      },
      onUpdate: (row) {
        final hodEmail =
        row['hod_email']?.toString().trim().toLowerCase() ?? '';

        if (hodEmail != user.email.trim().toLowerCase()) {
          return;
        }

        _loadRequests(refresh: true);
      },
    );
  }

  Future<void> _loadRequests({
    bool refresh = false,
  }) async {
    final user =
        DccSession.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      return;
    }

    if (refresh) {
      setState(() {
        _isRefreshing = true;
      });
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final requests =
      await DccDmrService
          .getPendingHodRequests(
        user.email,
      );

      requests.sort(
            (a, b) =>
            b.createdDate.compareTo(
              a.createdDate,
            ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _requests = requests;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load DMR requests: $e',
          ),
        ),
      );
    }
  }

  Future<void> _approveRequest(
      DccDmrRequest request,
      ) async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Approve DMR',
          ),
          content: Text(
            'Approve the modification request for '
                '${request.documentNo}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Approve',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final updatedRequest =
      DccDmrRequest(
        id: request.id,
        documentId:
        request.documentId,
        documentNo:
        request.documentNo,
        documentName:
        request.documentName,
        documentType:
        request.documentType,
        department:
        request.department,
        requestedByName:
        request.requestedByName,
        requestedByEmail:
        request.requestedByEmail,
        hodName:
        request.hodName,
        hodEmail:
        request.hodEmail,
        currentRevision:
        request.currentRevision,
        requestReason:
        request.requestReason,
        status:
        'PENDING_DCC',
        rejectionReason: '',
        createdDate:
        request.createdDate,
        hodActionDate:
        DateTime.now()
            .toIso8601String(),
        dccActionDate:
        request.dccActionDate,
        modificationAccessGranted:
        false,
      );

      await DccDmrService
          .updateRequest(
        updatedRequest,
      );

      final hod = DccSession.currentUser;

      if (hod != null) {
        await DccActivityService.addActivity(
          DccActivity(
            id: DateTime.now()
                .microsecondsSinceEpoch
                .toString(),
            userEmail: hod.email,
            userName: hod.name,
            action: 'DMR_HOD_APPROVED',
            description:
            '${request.documentNo} modification request approved by HOD and sent to DCC.',
            documentNo:
            request.documentNo,
            timestamp: DateTime.now(),
          ),
        );
      }

      // Notify the User.
      await DccNotificationService
          .addNotification(
        DccNotification(
          id:
          'DMR_APPROVED_USER_${request.id}',
          recipientEmail:
          request.requestedByEmail,
          title:
          'DMR Approved by HOD',
          message:
          '${request.documentNo} has been approved by '
              '${request.hodName} and sent to DCC for review.',
          type:
          'DMR_HOD_APPROVED',
          documentNo:
          request.documentNo,
          createdAt:
          DateTime.now(),
        ),
      );

      // Notify every hardcoded DCC account.
      // Notify every active DCC user.
      await DccNotificationService.notifyAllDcc(
        title:
        'DMR Ready for DCC Review',
        message:
        '${request.documentNo} modification request '
            'was approved by ${request.hodName}.',
        type:
        'DMR_READY_FOR_DCC',
        documentNo:
        request.documentNo,
      );

      if (!mounted) {
        return;
      }

      await _loadRequests(
        refresh: true,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'DMR approved and sent to DCC.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to approve DMR: $e',
          ),
        ),
      );
    }
  }

  Future<void> _rejectRequest(
      DccDmrRequest request,
      ) async {
    final reasonController =
    TextEditingController();

    final reason =
    await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Reject DMR',
          ),
          content: SizedBox(
            width: 500,
            child: TextField(
              controller:
              reasonController,
              maxLines: 5,
              decoration:
              const InputDecoration(
                labelText:
                'Rejection reason *',
                hintText:
                'Enter the reason for rejecting this request.',
                border:
                OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(
                  0xFFD64545,
                ),
                foregroundColor:
                Colors.white,
              ),
              onPressed: () {
                final value =
                reasonController
                    .text
                    .trim();

                if (value.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Rejection reason is required.',
                      ),
                    ),
                  );

                  return;
                }

                Navigator.pop(
                  context,
                  value,
                );
              },
              child: const Text(
                'Reject',
              ),
            ),
          ],
        );
      },
    );

    reasonController.dispose();

    if (reason == null ||
        reason.trim().isEmpty) {
      return;
    }

    try {
      final updatedRequest =
      DccDmrRequest(
        id: request.id,
        documentId:
        request.documentId,
        documentNo:
        request.documentNo,
        documentName:
        request.documentName,
        documentType:
        request.documentType,
        department:
        request.department,
        requestedByName:
        request.requestedByName,
        requestedByEmail:
        request.requestedByEmail,
        hodName:
        request.hodName,
        hodEmail:
        request.hodEmail,
        currentRevision:
        request.currentRevision,
        requestReason:
        request.requestReason,
        status:
        'REJECTED',
        rejectionReason:
        reason.trim(),
        createdDate:
        request.createdDate,
        hodActionDate:
        DateTime.now()
            .toIso8601String(),
        dccActionDate:
        request.dccActionDate,
        modificationAccessGranted:
        false,
      );

      await DccDmrService
          .updateRequest(
        updatedRequest,
      );

      final hod = DccSession.currentUser;

      if (hod != null) {
        await DccActivityService.addActivity(
          DccActivity(
            id: DateTime.now()
                .microsecondsSinceEpoch
                .toString(),
            userEmail: hod.email,
            userName: hod.name,
            action: 'DMR_HOD_REJECTED',
            description:
            '${request.documentNo} modification request rejected by HOD. Reason: ${reason.trim()}',
            documentNo:
            request.documentNo,
            timestamp: DateTime.now(),
          ),
        );
      }

      // Notify the User immediately.
      await DccNotificationService
          .addNotification(
        DccNotification(
          id:
          'DMR_REJECTED_USER_${request.id}',
          recipientEmail:
          request.requestedByEmail,
          title:
          'DMR Rejected by HOD',
          message:
          '${request.documentNo} was rejected by '
              '${request.hodName}. Reason: '
              '${reason.trim()}',
          type:
          'DMR_HOD_REJECTED',
          documentNo:
          request.documentNo,
          createdAt:
          DateTime.now(),
        ),
      );

      if (!mounted) {
        return;
      }

      await _loadRequests(
        refresh: true,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'DMR rejected. User has been notified.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to reject DMR: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'DMR Requests',
          style: TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),
        backgroundColor:
        Colors.white,
        foregroundColor:
        const Color(0xFF172033),
        elevation: 0,
        actions: [
          IconButton(
            onPressed:
            _isRefreshing
                ? null
                : () {
              _loadRequests(
                refresh: true,
              );
            },
            icon: _isRefreshing
                ? const SizedBox(
              width: 20,
              height: 20,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Icon(
              Icons
                  .refresh_rounded,
            ),
            tooltip:
            'Refresh requests',
          ),
          const SizedBox(
            width: 8,
          ),
        ],
      ),

      body: _isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: () =>
            _loadRequests(),
        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              const Text(
                'Document Modification Requests',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight:
                  FontWeight.w800,
                  color:
                  Color(0xFF172033),
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              const Text(
                'Review modification requests submitted by users.',
                style: TextStyle(
                  fontSize: 13,
                  color:
                  Color(0xFF6B7280),
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              if (_requests.isEmpty)
                _emptyState()
              else
                ..._requests.map(
                  _requestCard,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      height: 350,
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
          const Color(0xFFE4E8F0),
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              Icons
                  .assignment_turned_in_outlined,
              size: 50,
              color:
              Color(0xFF9AA2B1),
            ),
            SizedBox(
              height: 12,
            ),
            Text(
              'No pending DMR requests',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                FontWeight.w700,
                color:
                Color(0xFF4B5563),
              ),
            ),
            SizedBox(
              height: 5,
            ),
            Text(
              'New modification requests will appear here.',
              style: TextStyle(
                fontSize: 12,
                color:
                Color(0xFF9AA2B1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _requestCard(
      DccDmrRequest request,
      ) {
    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(
        bottom: 18,
      ),
      padding:
      const EdgeInsets.all(22),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
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
                width: 50,
                height: 50,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFF2E8FF,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    13,
                  ),
                ),
                child: const Icon(
                  Icons
                      .edit_document,
                  color:
                  Color(0xFF9C27B0),
                ),
              ),

              const SizedBox(
                width: 15,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      request.documentNo,
                      style:
                      const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w800,
                        color:
                        Color(
                          0xFF172033,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      request.documentName,
                      style:
                      const TextStyle(
                        fontSize: 13,
                        color:
                        Color(
                          0xFF6B7280,
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
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFFFF3DF,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
                child: const Text(
                  'PENDING HOD',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Color(
                      0xFFE67E00,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          Wrap(
            spacing: 35,
            runSpacing: 15,
            children: [
              _info(
                'Requested By',
                request.requestedByName,
              ),
              _info(
                'Department',
                request.department,
              ),
              _info(
                'Document Type',
                request.documentType,
              ),
              _info(
                'Current Revision',
                '${request.currentRevision}',
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.all(
              15,
            ),
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFFF7F8FC,
              ),
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                const Text(
                  'Modification Reason',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Color(
                      0xFF172033,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 7,
                ),
                Text(
                  request.requestReason,
                  style:
                  const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color:
                    Color(
                      0xFF4B5563,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          Row(
            mainAxisAlignment:
            MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  _showDetails(
                    request,
                  );
                },
                icon: const Icon(
                  Icons.visibility_outlined,
                ),
                label:
                const Text(
                  'View Details',
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              OutlinedButton.icon(
                onPressed: () {
                  _rejectRequest(
                    request,
                  );
                },
                style:
                OutlinedButton
                    .styleFrom(
                  foregroundColor:
                  const Color(
                    0xFFD64545,
                  ),
                  side:
                  const BorderSide(
                    color:
                    Color(
                      0xFFD64545,
                    ),
                  ),
                ),
                icon: const Icon(
                  Icons.close_rounded,
                ),
                label:
                const Text(
                  'Reject',
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              ElevatedButton.icon(
                onPressed: () {
                  _approveRequest(
                    request,
                  );
                },
                icon: const Icon(
                  Icons
                      .check_circle_outline,
                ),
                label:
                const Text(
                  'Approve',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(
      String label,
      String value,
      ) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,
        children: [
          Text(
            label,
            style:
            const TextStyle(
              fontSize: 10,
              color:
              Color(0xFF9AA2B1),
              fontWeight:
              FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            value.isEmpty
                ? '-'
                : value,
            maxLines: 2,
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
        ],
      ),
    );
  }

  void _showDetails(
      DccDmrRequest request,
      ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            request.documentNo,
            style:
            const TextStyle(
              fontWeight:
              FontWeight.w800,
            ),
          ),
          content: SizedBox(
            width: 550,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  _dialogRow(
                    'Document Name',
                    request.documentName,
                  ),
                  _dialogRow(
                    'Document Type',
                    request.documentType,
                  ),
                  _dialogRow(
                    'Department',
                    request.department,
                  ),
                  _dialogRow(
                    'Requested By',
                    request.requestedByName,
                  ),
                  _dialogRow(
                    'Employee/User Email',
                    request.requestedByEmail,
                  ),
                  _dialogRow(
                    'Current Revision',
                    '${request.currentRevision}',
                  ),
                  _dialogRow(
                    'Request Date',
                    request.createdDate,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  const Text(
                    'Reason',
                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    request.requestReason,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child:
              const Text(
                'Close',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _dialogRow(
      String label,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w700,
                color:
                Color(
                  0xFF6B7280,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty
                  ? '-'
                  : value,
              style:
              const TextStyle(
                color:
                Color(
                  0xFF172033,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}