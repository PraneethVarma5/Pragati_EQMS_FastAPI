import 'package:flutter/material.dart';

import '../../../models/dcc/dcc_dmr_request.dart';
import '../../../services/dcc/dcc_dmr_service.dart';
import '../../../services/dcc/dcc_session.dart';

class DmrRequestsScreen extends StatefulWidget {
  const DmrRequestsScreen({super.key});

  @override
  State<DmrRequestsScreen> createState() =>
      _DmrRequestsScreenState();
}

class _DmrRequestsScreenState
    extends State<DmrRequestsScreen> {
  List<DccDmrRequest> _requests = [];

  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _searchText = '';

  final TextEditingController _searchController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    final user = DccSession.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final requests =
      await DccDmrService.getRequestsByUser(
        user.email,
      );

      requests.sort(
            (a, b) => b.createdDate.compareTo(
          a.createdDate,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _requests = requests;
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
            'Unable to load DMR requests.',
          ),
        ),
      );
    }
  }

  List<DccDmrRequest> get _filteredRequests {
    final search =
    _searchText.trim().toLowerCase();

    return _requests.where((request) {
      bool matchesFilter = true;

      if (_selectedFilter == 'Active') {
        matchesFilter =
            request.status == 'PENDING_HOD' ||
                request.status == 'PENDING_DCC' ||
                request.status ==
                    'EDIT_ACCESS_GRANTED';
      } else if (_selectedFilter == 'Rejected') {
        matchesFilter =
            request.status == 'REJECTED';
      } else if (_selectedFilter == 'Completed') {
        matchesFilter =
            request.status == 'COMPLETED';
      }

      if (!matchesFilter) {
        return false;
      }

      if (search.isEmpty) {
        return true;
      }

      return request.documentNo
          .toLowerCase()
          .contains(search) ||
          request.documentName
              .toLowerCase()
              .contains(search) ||
          request.documentType
              .toLowerCase()
              .contains(search) ||
          request.requestReason
              .toLowerCase()
              .contains(search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'DMR Requests',
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
            onPressed: _loadRequests,
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _loadRequests,
        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(30),
          child: Center(
            child: ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 1400,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My DMR Requests',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight:
                      FontWeight.w800,
                      color:
                      Color(0xFF172033),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Track modification requests and approval status.',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                      Color(0xFF6B7280),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildSearchAndFilters(),

                  const SizedBox(height: 20),

                  _buildRequestList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE4E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText:
                'Search document number, name or reason...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                ),
                suffixIcon:
                _searchText.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    _searchController
                        .clear();

                    setState(() {
                      _searchText = '';
                    });
                  },
                  icon: const Icon(
                    Icons.clear_rounded,
                  ),
                )
                    : null,
                filled: true,
                fillColor:
                const Color(0xFFF8F9FC),
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 18),

          _filterButton('All'),
          const SizedBox(width: 8),
          _filterButton('Active'),
          const SizedBox(width: 8),
          _filterButton('Rejected'),
          const SizedBox(width: 8),
          _filterButton('Completed'),
        ],
      ),
    );
  }

  Widget _filterButton(String filter) {
    final selected =
        _selectedFilter == filter;

    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: selected
            ? const Color(0xFF3155D9)
            : const Color(0xFF6B7280),
        backgroundColor: selected
            ? const Color(0xFFEFF3FF)
            : Colors.white,
        side: BorderSide(
          color: selected
              ? const Color(0xFF3155D9)
              : const Color(0xFFE4E8F0),
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(10),
        ),
      ),
      child: Text(filter),
    );
  }

  Widget _buildRequestList() {
    final requests = _filteredRequests;

    if (requests.isEmpty) {
      return Container(
        width: double.infinity,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE4E8F0),
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 48,
                color: Color(0xFF9AA2B1),
              ),
              SizedBox(height: 12),
              Text(
                'No DMR requests found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                  FontWeight.w700,
                  color: Color(0xFF4B5563),
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Your modification requests will appear here.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9AA2B1),
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
        shrinkWrap: true,
        physics:
        const NeverScrollableScrollPhysics(),
        itemCount: requests.length,
        separatorBuilder: (_, _) =>
        const Divider(height: 1),
        itemBuilder: (context, index) {
          return _buildRequestCard(
            requests[index],
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(
      DccDmrRequest request,
      ) {
    return InkWell(
      onTap: () {
        _showRequestDetails(request);
      },
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _statusBackground(
                  request.status,
                ),
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.description_outlined,
                color: _statusColor(
                  request.status,
                ),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    request.documentNo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight:
                      FontWeight.w800,
                      color:
                      Color(0xFF172033),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    request.documentName,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color:
                      Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Text(
                'Rev ${request.currentRevision}',
                style: const TextStyle(
                  fontSize: 12,
                  color:
                  Color(0xFF6B7280),
                ),
              ),
            ),

            Expanded(
              child: _statusChip(
                request.status,
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9AA2B1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: _statusBackground(status),
          borderRadius:
          BorderRadius.circular(20),
        ),
        child: Text(
          _displayStatus(status),
          style: TextStyle(
            fontSize: 11,
            fontWeight:
            FontWeight.w800,
            color: _statusColor(status),
          ),
        ),
      ),
    );
  }

  String _displayStatus(String status) {
    switch (status) {
      case 'PENDING_HOD':
        return 'Pending HOD';

      case 'PENDING_DCC':
        return 'Pending DCC';

      case 'EDIT_ACCESS_GRANTED':
        return 'Edit Access Granted';

      case 'REJECTED':
        return 'Rejected';

      case 'COMPLETED':
        return 'Completed';

      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING_HOD':
      case 'PENDING_DCC':
        return const Color(0xFFE67E00);

      case 'EDIT_ACCESS_GRANTED':
      case 'COMPLETED':
        return const Color(0xFF2E8B57);

      case 'REJECTED':
        return const Color(0xFFD64545);

      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _statusBackground(String status) {
    switch (status) {
      case 'PENDING_HOD':
      case 'PENDING_DCC':
        return const Color(0xFFFFF3DF);

      case 'EDIT_ACCESS_GRANTED':
      case 'COMPLETED':
        return const Color(0xFFEAF7ED);

      case 'REJECTED':
        return const Color(0xFFFDECEC);

      default:
        return const Color(0xFFF1F3F8);
    }
  }

  void _showRequestDetails(
      DccDmrRequest request,
      ) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.assignment_outlined,
                color: Color(0xFF3155D9),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  request.documentNo,
                  style: const TextStyle(
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  _detailRow(
                    'Document Name',
                    request.documentName,
                  ),
                  _detailRow(
                    'Document Type',
                    request.documentType,
                  ),
                  _detailRow(
                    'Department',
                    request.department,
                  ),
                  _detailRow(
                    'Current Revision',
                    request.currentRevision
                        .toString(),
                  ),
                  _detailRow(
                    'HOD',
                    request.hodName,
                  ),
                  _detailRow(
                    'HOD Email',
                    request.hodEmail,
                  ),
                  _detailRow(
                    'Submitted',
                    _formatDate(
                      request.createdDate,
                    ),
                  ),
                  _detailRow(
                    'Status',
                    _displayStatus(
                      request.status,
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'Modification Reason',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    request.requestReason,
                    style: const TextStyle(
                      fontSize: 13,
                      color:
                      Color(0xFF4B5563),
                    ),
                  ),

                  if (request.rejectionReason
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 18,
                    ),
                    Container(
                      width: double.infinity,
                      padding:
                      const EdgeInsets.all(
                        14,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        const Color(
                          0xFFFDECEC,
                        ),
                        borderRadius:
                        BorderRadius
                            .circular(
                          10,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          const Text(
                            'Rejection Reason',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                              FontWeight
                                  .w800,
                              color:
                              Color(
                                0xFFD64545,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          Text(
                            request
                                .rejectionReason,
                            style:
                            const TextStyle(
                              fontSize: 13,
                              color:
                              Color(
                                0xFF7A3030,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(
      String label,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
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
              value.isEmpty ? '-' : value,
              style: const TextStyle(
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

  String _formatDate(String value) {
    if (value.isEmpty) {
      return '-';
    }

    try {
      final date =
      DateTime.parse(value);

      return '${date.day.toString().padLeft(2, '0')}.'
          '${date.month.toString().padLeft(2, '0')}.'
          '${date.year}';
    } catch (_) {
      return value;
    }
  }
}