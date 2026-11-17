import 'package:flutter/material.dart';

import '../../../models/dcc/dcc_activity.dart';
import '../../../services/dcc/dcc_activity_service.dart';
import '../../../services/dcc/dcc_session.dart';

class HodActivityHistoryScreen
    extends StatefulWidget {
  const HodActivityHistoryScreen({
    super.key,
  });

  @override
  State<HodActivityHistoryScreen>
  createState() =>
      _HodActivityHistoryScreenState();
}

class _HodActivityHistoryScreenState
    extends State<HodActivityHistoryScreen> {
  List<DccActivity> _activities = [];
  List<DccActivity> _filteredActivities = [];

  bool _isLoading = true;
  bool _isRefreshing = false;

  String _selectedFilter = 'All';

  final TextEditingController
  _searchController =
  TextEditingController();

  @override
  void initState() {
    super.initState();

    _loadActivities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities({
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
      final activities =
      await DccActivityService
          .getActivitiesForUser(
        user.email,
      );

      activities.sort(
            (a, b) =>
            b.timestamp.compareTo(
              a.timestamp,
            ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _activities = activities;
        _isLoading = false;
        _isRefreshing = false;
      });

      _applyFilters();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load activity history: $e',
          ),
        ),
      );
    }
  }

  void _applyFilters() {
    final query =
    _searchController.text
        .trim()
        .toLowerCase();

    final filtered =
    _activities.where((activity) {
      final matchesSearch =
          query.isEmpty ||
              activity.description
                  .toLowerCase()
                  .contains(query) ||
              activity.action
                  .toLowerCase()
                  .contains(query) ||
              activity.documentNo
                  .toLowerCase()
                  .contains(query);

      final matchesFilter =
          _selectedFilter == 'All' ||
              _matchesFilter(
                activity,
              );

      return matchesSearch &&
          matchesFilter;
    }).toList();

    setState(() {
      _filteredActivities =
          filtered;
    });
  }

  bool _matchesFilter(
      DccActivity activity,
      ) {
    switch (_selectedFilter) {
      case 'Documents':
        return activity.action
            .toUpperCase()
            .contains('DOCUMENT');

      case 'DMR':
        return activity.action
            .toUpperCase()
            .contains('DMR');

      case 'Approved':
        return activity.action
            .toUpperCase()
            .contains('APPROVED');

      case 'Rejected':
        return activity.action
            .toUpperCase()
            .contains('REJECTED');

      default:
        return true;
    }
  }

  String _formatDate(
      DateTime date,
      ) {
    final day =
    date.day.toString().padLeft(
      2,
      '0',
    );

    final month =
    date.month.toString().padLeft(
      2,
      '0',
    );

    final hour =
    date.hour.toString().padLeft(
      2,
      '0',
    );

    final minute =
    date.minute.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/${date.year} '
        '$hour:$minute';
  }

  IconData _activityIcon(
      DccActivity activity,
      ) {
    final action =
    activity.action.toUpperCase();

    if (action.contains('REJECT')) {
      return Icons.cancel_outlined;
    }

    if (action.contains('APPROV')) {
      return Icons.check_circle_outline;
    }

    if (action.contains('DMR')) {
      return Icons.edit_document;
    }

    if (action.contains('SUBMIT')) {
      return Icons.upload_file_outlined;
    }

    return Icons.history_rounded;
  }

  Color _activityColor(
      DccActivity activity,
      ) {
    final action =
    activity.action.toUpperCase();

    if (action.contains('REJECT')) {
      return const Color(
        0xFFD64545,
      );
    }

    if (action.contains('APPROV')) {
      return const Color(
        0xFF2E8B57,
      );
    }

    if (action.contains('DMR')) {
      return const Color(
        0xFF9C27B0,
      );
    }

    return const Color(
      0xFF3155D9,
    );
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
          'Activity History',
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
              _loadActivities(
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
              Icons.refresh_rounded,
            ),
            tooltip:
            'Refresh activity',
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
            _loadActivities(),
        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'HOD Activity History',
                style: TextStyle(
                  fontSize: 28,
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
                'Complete record of actions performed by you.',
                style: TextStyle(
                  fontSize: 13,
                  color:
                  Color(0xFF6B7280),
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              _buildSearchAndFilter(),

              const SizedBox(
                height: 20,
              ),

              _buildSummary(),

              const SizedBox(
                height: 20,
              ),

              _buildActivityList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding:
      const EdgeInsets.all(18),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color:
          const Color(0xFFE4E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller:
              _searchController,
              onChanged: (_) {
                _applyFilters();
              },
              decoration:
              InputDecoration(
                prefixIcon:
                const Icon(
                  Icons.search_rounded,
                ),
                hintText:
                'Search document, action or activity...',
                suffixIcon:
                _searchController
                    .text
                    .isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    _searchController
                        .clear();
                    _applyFilters();
                  },
                  icon:
                  const Icon(
                    Icons
                        .clear_rounded,
                  ),
                )
                    : null,
                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 15,
          ),

          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFilter,
              borderRadius:
              BorderRadius.circular(
                12,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'All',
                  child: Text('All'),
                ),
                DropdownMenuItem(
                  value: 'Documents',
                  child:
                  Text('Documents'),
                ),
                DropdownMenuItem(
                  value: 'DMR',
                  child: Text('DMR'),
                ),
                DropdownMenuItem(
                  value: 'Approved',
                  child:
                  Text('Approved'),
                ),
                DropdownMenuItem(
                  value: 'Rejected',
                  child:
                  Text('Rejected'),
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedFilter =
                      value;
                });

                _applyFilters();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final approved =
        _activities
            .where(
              (activity) =>
              activity.action
                  .toUpperCase()
                  .contains(
                'APPROVED',
              ),
        )
            .length;

    final rejected =
        _activities
            .where(
              (activity) =>
              activity.action
                  .toUpperCase()
                  .contains(
                'REJECTED',
              ),
        )
            .length;

    final dmr =
        _activities
            .where(
              (activity) =>
              activity.action
                  .toUpperCase()
                  .contains(
                'DMR',
              ),
        )
            .length;

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            'Total Activities',
            _activities.length
                .toString(),
            Icons.history_rounded,
            const Color(0xFF3155D9),
          ),
        ),

        const SizedBox(
          width: 15,
        ),

        Expanded(
          child: _summaryCard(
            'Approved',
            approved.toString(),
            Icons
                .check_circle_outline,
            const Color(0xFF2E8B57),
          ),
        ),

        const SizedBox(
          width: 15,
        ),

        Expanded(
          child: _summaryCard(
            'Rejected',
            rejected.toString(),
            Icons
                .cancel_outlined,
            const Color(0xFFD64545),
          ),
        ),

        const SizedBox(
          width: 15,
        ),

        Expanded(
          child: _summaryCard(
            'DMR Actions',
            dmr.toString(),
            Icons.edit_document,
            const Color(0xFF9C27B0),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
      String title,
      String value,
      IconData icon,
      Color iconColor,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(18),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          15,
        ),
        border: Border.all(
          color:
          const Color(0xFFE4E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
            BoxDecoration(
              color:
              iconColor.withValues(
                alpha: 0.10,
              ),
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 23,
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
                  value,
                  style:
                  const TextStyle(
                    fontSize: 21,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Color(0xFF172033),
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 11,
                    color:
                    Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    if (_filteredActivities.isEmpty) {
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
                Icons.history_rounded,
                size: 48,
                color:
                Color(0xFF9AA2B1),
              ),
              SizedBox(
                height: 12,
              ),
              Text(
                'No activity found',
                style: TextStyle(
                  fontSize: 16,
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
                'Try changing your search or filter.',
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

    return Container(
      width: double.infinity,
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
      child: ListView.separated(
        shrinkWrap: true,
        physics:
        const NeverScrollableScrollPhysics(),
        itemCount:
        _filteredActivities.length,
        separatorBuilder:
            (_, _) =>
        const Divider(
          height: 1,
        ),
        itemBuilder:
            (context, index) {
          final activity =
          _filteredActivities[
          index];

          final color =
          _activityColor(
            activity,
          );

          return ListTile(
            contentPadding:
            const EdgeInsets
                .symmetric(
              horizontal: 22,
              vertical: 10,
            ),
            leading: Container(
              width: 45,
              height: 45,
              decoration:
              BoxDecoration(
                color:
                color.withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
              ),
              child: Icon(
                _activityIcon(
                  activity,
                ),
                color: color,
                size: 22,
              ),
            ),
            title: Text(
              activity.description,
              style:
              const TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.w700,
                color:
                Color(0xFF172033),
              ),
            ),
            subtitle: Padding(
              padding:
              const EdgeInsets.only(
                top: 5,
              ),
              child: Text(
                activity.documentNo
                    .isEmpty
                    ? activity.action
                    : '${activity.action}  •  ${activity.documentNo}',
                style:
                const TextStyle(
                  fontSize: 11,
                  color:
                  Color(0xFF6B7280),
                ),
              ),
            ),
            trailing: Text(
              _formatDate(
                activity.timestamp,
              ),
              style:
              const TextStyle(
                fontSize: 10,
                color:
                Color(0xFF9AA2B1),
              ),
            ),
          );
        },
      ),
    );
  }
}