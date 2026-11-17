import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/dcc/dcc_notification.dart';
import '../../../services/dcc/dcc_notification_service.dart';
import '../../../services/dcc/dcc_session.dart';

class DccNotificationBell
    extends StatefulWidget {
  const DccNotificationBell({
    super.key,
  });

  @override
  State<DccNotificationBell>
  createState() =>
      _DccNotificationBellState();
}

class _DccNotificationBellState
    extends State<DccNotificationBell> {
  int _unreadCount = 0;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _loadUnreadCount();

    _timer = Timer.periodic(
      const Duration(seconds: 5),
          (_) {
        _loadUnreadCount();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    final user =
        DccSession.currentUser;

    if (user == null) {
      return;
    }

    final count =
    await DccNotificationService
        .getUnreadCount(
      user.email,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _unreadCount = count;
    });
  }

  Future<void> _openNotifications() async {
    final user =
        DccSession.currentUser;

    if (user == null) {
      return;
    }

    final notifications =
    await DccNotificationService
        .getNotificationsForUser(
      user.email,
    );

    if (!mounted) {
      return;
    }

    await showDialog(
      context: context,
      builder: (_) {
        return _NotificationDialog(
          notifications: notifications,
          userEmail: user.email,
        );
      },
    );

    await _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed:
          _openNotifications,
          icon: const Icon(
            Icons
                .notifications_none_rounded,
          ),
          tooltip: 'Notifications',
        ),

        if (_unreadCount > 0)
          Positioned(
            right: 5,
            top: 5,
            child: Container(
              constraints:
              const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              padding:
              const EdgeInsets.symmetric(
                horizontal: 4,
              ),
              decoration:
              BoxDecoration(
                color:
                const Color(0xFFD64545),
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: Text(
                _unreadCount > 99
                    ? '99+'
                    : '$_unreadCount',
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  fontSize: 9,
                  fontWeight:
                  FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationDialog
    extends StatefulWidget {
  final List<DccNotification>
  notifications;

  final String userEmail;

  const _NotificationDialog({
    required this.notifications,
    required this.userEmail,
  });

  @override
  State<_NotificationDialog>
  createState() =>
      _NotificationDialogState();
}

class _NotificationDialogState
    extends State<_NotificationDialog> {
  late List<DccNotification>
  _notifications;

  @override
  void initState() {
    super.initState();

    _notifications =
        List.from(
          widget.notifications,
        );
  }

  Future<void> _markRead(
      DccNotification notification,
      ) async {
    if (notification.isRead) {
      return;
    }

    await DccNotificationService
        .markAsRead(
      notification.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      final index =
      _notifications.indexWhere(
            (item) =>
        item.id ==
            notification.id,
      );

      if (index != -1) {
        _notifications[index] =
            notification.copyWith(
              isRead: true,
            );
      }
    });
  }

  Future<void> _deleteNotification(
      DccNotification notification,
      ) async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Notification',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this notification?',
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
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFFD64545),
                foregroundColor:
                Colors.white,
              ),
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await DccNotificationService
        .deleteNotification(
      notification.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _notifications.removeWhere(
            (item) =>
        item.id ==
            notification.id,
      );
    });
  }

  Future<void> _markAllRead() async {
    await DccNotificationService
        .markAllAsRead(
      widget.userEmail,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _notifications =
          _notifications
              .map(
                (notification) =>
                notification.copyWith(
                  isRead: true,
                ),
          )
              .toList();
    });
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

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        _notifications
            .where(
              (item) => !item.isRead,
        )
            .length;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(
            Icons
                .notifications_active_outlined,
            color:
            Color(0xFF3155D9),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                fontWeight:
                FontWeight.w800,
              ),
            ),
          ),
          if (unreadCount > 0)
            TextButton(
              onPressed:
              _markAllRead,
              child: const Text(
                'Mark all read',
              ),
            ),
        ],
      ),

      content: SizedBox(
        width: 600,
        height: 500,
        child: _notifications.isEmpty
            ? const Center(
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment
                .center,
            children: [
              Icon(
                Icons
                    .notifications_none_rounded,
                size: 48,
                color:
                Color(0xFF9AA2B1),
              ),
              SizedBox(
                height: 12,
              ),
              Text(
                'No notifications',
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
                'New document activities will appear here.',
                style: TextStyle(
                  fontSize: 12,
                  color:
                  Color(0xFF9AA2B1),
                ),
              ),
            ],
          ),
        )
            : ListView.separated(
          itemCount:
          _notifications
              .length,
          separatorBuilder:
              (_, _) =>
          const Divider(
            height: 1,
          ),
          itemBuilder:
              (context, index) {
            final notification =
            _notifications[
            index];

            return InkWell(
              onTap: () {
                _markRead(
                  notification,
                );
              },
              child: Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  vertical: 14,
                  horizontal: 8,
                ),
                color:
                notification
                    .isRead
                    ? Colors
                    .transparent
                    : const Color(
                  0xFFF1F5FF,
                ),
                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration:
                      BoxDecoration(
                        color:
                        const Color(
                          0xFFEFF3FF,
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
                            .notifications_outlined,
                        size: 20,
                        color:
                        Color(
                          0xFF3155D9,
                        ),
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
                            notification
                                .title,
                            style:
                            TextStyle(
                              fontSize:
                              13,
                              fontWeight:
                              notification
                                  .isRead
                                  ? FontWeight
                                  .w600
                                  : FontWeight
                                  .w800,
                              color:
                              const Color(
                                0xFF172033,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            notification
                                .message,
                            style:
                            const TextStyle(
                              fontSize:
                              12,
                              height:
                              1.4,
                              color:
                              Color(
                                0xFF6B7280,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 5,
                          ),

                          Text(
                            _formatDate(
                              notification
                                  .createdAt,
                            ),
                            style:
                            const TextStyle(
                              fontSize:
                              10,
                              color:
                              Color(
                                0xFF9AA2B1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Row(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        if (!notification
                            .isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin:
                            const EdgeInsets.only(
                              top: 5,
                              right: 8,
                            ),
                            decoration:
                            const BoxDecoration(
                              color:
                              Color(0xFF3155D9),
                              shape:
                              BoxShape.circle,
                            ),
                          ),

                        IconButton(
                          onPressed: () {
                            _deleteNotification(
                              notification,
                            );
                          },
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color:
                            Color(0xFFD64545),
                          ),
                          tooltip:
                          'Delete notification',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'Close',
          ),
        ),
      ],
    );
  }
}