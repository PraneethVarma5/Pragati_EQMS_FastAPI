import 'package:flutter/material.dart';

import '../../services/ccr/ccr_team_service.dart';
import 'package:flutter/material.dart';

import '../../services/ccr/ccr_session.dart';
import '../../services/ccr/ccr_team_service.dart';

class CcrTeamManagementScreen
    extends StatefulWidget {
  final bool adminOnly;

  const CcrTeamManagementScreen({
    super.key,
    this.adminOnly = false,
  });

  @override
  State<CcrTeamManagementScreen> createState() =>
      _CcrTeamManagementScreenState();
}
class _CcrTeamManagementScreenState
    extends State<CcrTeamManagementScreen> {
  final TextEditingController
  _leaderController =
  TextEditingController();

  final List<TextEditingController>
  _memberControllers =
  <TextEditingController>[];

  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _teams =
  <Map<String, dynamic>>[];

  String? _editingTeamId;

  @override
  void initState() {
    super.initState();

    if (widget.adminOnly &&
        !CcrSession.isAdmin) {
      return;
    }

    _loadTeams();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadTeams() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final teams =
      await CcrTeamService.getTeams();

      if (!mounted) {
        return;
      }

      setState(() {
        _teams = teams;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _showError(
        'Failed to load CCR teams.\n$e',
      );
    }
  }

  // ============================================================
  // MEMBER FIELDS
  // ============================================================

  void _addMemberField() {
    setState(() {
      _memberControllers.add(
        TextEditingController(),
      );
    });
  }

  void _removeMemberField(
      int index,
      ) {
    if (_memberControllers.length <= 1) {
      _memberControllers[index].clear();
      return;
    }

    final controller =
    _memberControllers.removeAt(
      index,
    );

    controller.dispose();

    setState(() {});
  }

  // ============================================================
  // NEW TEAM
  // ============================================================

  void _startNewTeam() {
    _clearForm();

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // EDIT TEAM
  // ============================================================

  void _editTeam(
      Map<String, dynamic> team,
      ) {
    final teamId =
    team['id']?.toString();

    if (teamId == null ||
        teamId.isEmpty) {
      return;
    }

    final leader =
        team['team_leader_name']
            ?.toString() ??
            '';

    final membersRaw =
    team['ccr_team_members'];

    final memberNames =
    <String>[];

    if (membersRaw is List) {
      for (final member
      in membersRaw) {
        if (member is Map) {
          final name =
          member['member_name']
              ?.toString()
              .trim();

          if (name != null &&
              name.isNotEmpty) {
            memberNames.add(name);
          }
        }
      }
    }

    _clearForm();

    _leaderController.text =
        leader;

    for (final name
    in memberNames) {
      _memberControllers.add(
        TextEditingController(
          text: name,
        ),
      );
    }

    if (_memberControllers.length >
        1) {
      // Remove the initial empty field.
      final first =
      _memberControllers.removeAt(
        0,
      );

      first.dispose();
    }

    if (_memberControllers.isEmpty) {
      _addMemberField();
    }

    setState(() {
      _editingTeamId = teamId;
    });
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _saveTeam() async {
    if (_saving) {
      return;
    }

    final leader =
    _leaderController.text.trim();

    if (leader.isEmpty) {
      _showError(
        'Please enter a team leader name.',
      );
      return;
    }

    final memberNames =
    _memberControllers
        .map(
          (controller) =>
          controller.text.trim(),
    )
        .where(
          (name) => name.isNotEmpty,
    )
        .toList();

    if (memberNames.isEmpty) {
      _showError(
        'Please add at least one team member.',
      );
      return;
    }

    final uniqueNames =
    <String>[];

    for (final name in memberNames) {
      final alreadyExists =
      uniqueNames.any(
            (existing) =>
        existing.toLowerCase() ==
            name.toLowerCase(),
      );

      if (!alreadyExists) {
        uniqueNames.add(name);
      }
    }

    final leaderIsMember =
    uniqueNames.any(
          (name) =>
      name.toLowerCase() ==
          leader.toLowerCase(),
    );

    if (leaderIsMember) {
      _showError(
        'The team leader cannot also be a team member.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    final wasEditing =
        _editingTeamId != null;

    try {
      if (wasEditing) {
        await CcrTeamService.updateTeam(
          teamId:
          _editingTeamId!,
          teamLeaderName:
          leader,
          memberNames:
          uniqueNames,
        );
      } else {
        await CcrTeamService.createTeam(
          teamLeaderName:
          leader,
          memberNames:
          uniqueNames,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      _clearForm();

      _showSuccess(
        wasEditing
            ? 'Team updated successfully.'
            : 'Team created successfully.',
      );

      await _loadTeams();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      _showError(
        'Failed to save team.\n$e',
      );
    }
  }

  // ============================================================
  // TEAM STATUS
  // ============================================================

  Future<void> _toggleTeamStatus(
      Map<String, dynamic> team,
      ) async {
    final teamId =
    team['id']?.toString();

    if (teamId == null ||
        teamId.isEmpty) {
      return;
    }

    final current =
        team['is_active'] == true;

    try {
      await CcrTeamService.setTeamActive(
        teamId: teamId,
        isActive: !current,
      );

      await _loadTeams();

      if (!mounted) {
        return;
      }

      _showSuccess(
        !current
            ? 'Team activated.'
            : 'Team deactivated.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        'Failed to update team status.\n$e',
      );
    }
  }
// ============================================================
// DELETE TEAM
// ============================================================

  Future<void> _deleteTeam(
      Map<String, dynamic> team,
      ) async {
    final teamId =
    team['id']?.toString();

    if (teamId == null ||
        teamId.isEmpty) {
      return;
    }

    final leader =
    team['team_leader_name']
        ?.toString()
        .trim();

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Team',
          ),
          content: Text(
            'Are you sure you want to permanently delete the team led by "${leader ?? 'this leader'}"?\n\n'
                'The team and all its members will be deleted. Existing CCR records will not be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),

            FilledButton(
              style:
              FilledButton.styleFrom(
                backgroundColor:
                Colors.red,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Delete Team',
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
      await CcrTeamService.deleteTeam(
        teamId: teamId,
      );

      if (!mounted) {
        return;
      }

      if (_editingTeamId == teamId) {
        _clearForm();
      }

      await _loadTeams();

      if (!mounted) {
        return;
      }

      _showSuccess(
        'Team deleted successfully.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        'Failed to delete team.\n$e',
      );
    }
  }
  // ============================================================
  // CLEAR
  // ============================================================

  void _clearForm() {
    _leaderController.clear();

    for (final controller
    in _memberControllers) {
      controller.dispose();
    }

    _memberControllers.clear();

    _memberControllers.add(
      TextEditingController(),
    );

    _editingTeamId = null;

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CCR Team Management',
        ),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : LayoutBuilder(
        builder:
            (
            context,
            constraints,
            ) {
          final isWide =
              constraints.maxWidth >=
                  1000;

          if (isWide) {
            return Row(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                SizedBox(
                  width: 430,
                  child:
                  _buildTeamForm(),
                ),
                const VerticalDivider(
                  width: 1,
                ),
                Expanded(
                  child:
                  _buildTeamList(),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            padding:
            const EdgeInsets.all(
              20,
            ),
            child: Column(
              children: [
                _buildTeamForm(),
                const SizedBox(
                  height: 24,
                ),
                _buildTeamList(),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // FORM
  // ============================================================

  Widget _buildTeamForm() {
    final isEditing =
        _editingTeamId != null;

    return Container(
      padding:
      const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isEditing
                    ? Icons.edit_outlined
                    : Icons.group_add_outlined,
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  isEditing
                      ? 'Edit Team'
                      : 'Create Team',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 24,
          ),

          // ------------------------------------------------------
          // LEADER
          // ------------------------------------------------------

          Text(
            'Team Leader',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(
              fontWeight:
              FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          TextField(
            controller:
            _leaderController,
            textCapitalization:
            TextCapitalization.words,
            decoration:
            const InputDecoration(
              labelText:
              'Enter Team Leader Name',
              hintText:
              'Example: Rajesh Kumar',
              border:
              OutlineInputBorder(),
              prefixIcon:
              Icon(
                Icons.person_outline,
              ),
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          // ------------------------------------------------------
          // MEMBERS
          // ------------------------------------------------------

          Row(
            children: [
              Expanded(
                child: Text(
                  'Team Members',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${_memberControllers.length} field${_memberControllers.length == 1 ? '' : 's'}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          ...List.generate(
            _memberControllers.length,
                (index) {
              return Padding(
                padding:
                const EdgeInsets.only(
                  bottom: 10,
                ),
                child: TextField(
                  controller:
                  _memberControllers[
                  index],
                  textCapitalization:
                  TextCapitalization
                      .words,
                  decoration:
                  InputDecoration(
                    labelText:
                    'Team Member ${index + 1}',
                    hintText:
                    'Enter member name',
                    border:
                    const OutlineInputBorder(),
                    prefixIcon:
                    const Icon(
                      Icons.person_outline,
                    ),
                    suffixIcon:
                    IconButton(
                      tooltip:
                      'Remove member',
                      onPressed:
                      _saving
                          ? null
                          : () =>
                          _removeMemberField(
                            index,
                          ),
                      icon:
                      const Icon(
                        Icons
                            .remove_circle_outline,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          OutlinedButton.icon(
            onPressed:
            _saving
                ? null
                : _addMemberField,
            icon:
            const Icon(
              Icons.add,
            ),
            label:
            const Text(
              'Add Member',
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          // ------------------------------------------------------
          // ACTIONS
          // ------------------------------------------------------

          Row(
            children: [
              if (isEditing)
                Expanded(
                  child:
                  OutlinedButton(
                    onPressed:
                    _saving
                        ? null
                        : _clearForm,
                    child:
                    const Text(
                      'Cancel',
                    ),
                  ),
                ),

              if (isEditing)
                const SizedBox(
                  width: 12,
                ),

              Expanded(
                flex: 2,
                child:
                FilledButton.icon(
                  onPressed:
                  _saving
                      ? null
                      : _saveTeam,
                  icon: _saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                    CircularProgressIndicator(
                      strokeWidth:
                      2,
                      color:
                      Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons
                        .save_outlined,
                  ),
                  label: Text(
                    _saving
                        ? 'Saving...'
                        : isEditing
                        ? 'Update Team'
                        : 'Save Team',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TEAM LIST
  // ============================================================

  Widget _buildTeamList() {
    final activeTeams =
    _teams
        .where(
          (team) =>
      team['is_active'] ==
          true,
    )
        .toList();

    final inactiveTeams =
    _teams
        .where(
          (team) =>
      team['is_active'] !=
          true,
    )
        .toList();

    return SingleChildScrollView(
      padding:
      const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      'Configured Teams',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                        fontWeight:
                        FontWeight
                            .bold,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      '${activeTeams.length} active team${activeTeams.length == 1 ? '' : 's'}',
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .bodyMedium,
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed:
                _startNewTeam,
                icon:
                const Icon(
                  Icons.add,
                ),
                label:
                const Text(
                  'New Team',
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          if (_teams.isEmpty)
            _buildEmptyState()
          else ...[
            ...activeTeams.map(
              _buildTeamCard,
            ),

            if (inactiveTeams
                .isNotEmpty) ...[
              const SizedBox(
                height: 24,
              ),
              Text(
                'Inactive Teams',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              ...inactiveTeams.map(
                _buildTeamCard,
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ============================================================
  // TEAM CARD
  // ============================================================

  Widget _buildTeamCard(
      Map<String, dynamic> team,
      ) {
    final teamId =
    team['id']?.toString();

    final leader =
        team['team_leader_name']
            ?.toString() ??
            'Unknown';

    final isActive =
        team['is_active'] == true;

    final membersRaw =
    team['ccr_team_members'];

    final members =
    <String>[];

    if (membersRaw is List) {
      for (final member
      in membersRaw) {
        if (member is Map) {
          final name =
          member['member_name']
              ?.toString()
              .trim();

          if (name != null &&
              name.isNotEmpty) {
            members.add(name);
          }
        }
      }
    }

    return Card(
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child:
                  const Icon(
                    Icons
                        .groups_outlined,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        leader,
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight:
                          FontWeight
                              .bold,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      const Text(
                        'Team Leader',
                      ),
                    ],
                  ),
                ),

                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration:
                  BoxDecoration(
                    color: isActive
                        ? Colors.green
                        .withValues(
                      alpha: 0.12,
                    )
                        : Colors.grey
                        .withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      20,
                    ),
                  ),
                  child: Text(
                    isActive
                        ? 'Active'
                        : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                      FontWeight.w600,
                      color: isActive
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                ),

                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editTeam(team);
                    }

                    if (value == 'status') {
                      _toggleTeamStatus(team);
                    }

                    if (value == 'delete') {
                      _deleteTeam(team);
                    }
                  },

                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(
                          Icons.edit_outlined,
                        ),
                        title: Text(
                          'Edit Team',
                        ),
                        contentPadding:
                        EdgeInsets.zero,
                      ),
                    ),

                    PopupMenuItem<String>(
                      value: 'status',
                      child: ListTile(
                        leading: Icon(
                          isActive
                              ? Icons.block_outlined
                              : Icons.check_circle_outline,
                        ),
                        title: Text(
                          isActive
                              ? 'Deactivate'
                              : 'Activate',
                        ),
                        contentPadding:
                        EdgeInsets.zero,
                      ),
                    ),

                    const PopupMenuDivider(),

                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        title: Text(
                          'Delete Team',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        contentPadding:
                        EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(
              height: 24,
            ),

            Text(
              'Team Members (${members.length})',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(
                fontWeight:
                FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            if (members.isEmpty)
              const Text(
                'No members configured.',
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                members.map(
                      (name) {
                    return Chip(
                      avatar:
                      const Icon(
                        Icons
                            .person_outline,
                        size: 16,
                      ),
                      label:
                      Text(name),
                    );
                  },
                ).toList(),
              ),

            if (teamId != null)
              const SizedBox(
                height: 4,
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(40),
      decoration:
      BoxDecoration(
        border: Border.all(
          color: Theme.of(context)
              .dividerColor,
        ),
        borderRadius:
        BorderRadius.circular(
          12,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.groups_outlined,
            size: 52,
            color: Theme.of(context)
                .colorScheme
                .primary,
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            'No teams configured',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
              fontWeight:
              FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          const Text(
            'Create a team by entering a team leader and team members.',
            textAlign:
            TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  void _showError(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
        Text(message),
        backgroundColor:
        Theme.of(context)
            .colorScheme
            .error,
      ),
    );
  }

  void _showSuccess(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
        Text(message),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _leaderController.dispose();

    for (final controller
    in _memberControllers) {
      controller.dispose();
    }

    super.dispose();
  }
}