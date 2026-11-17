import 'package:hive_flutter/hive_flutter.dart';

import '../../models/dcc/dcc_notification.dart';
import 'dcc_user_service.dart';
class DccNotificationService {
  static const String boxName =
      'dccNotifications';

  static Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }

    return Hive.box(boxName);
  }

  static Future<void> addNotification(
      DccNotification notification,
      ) async {
    final box = await _getBox();

    await box.put(
      notification.id,
      notification.toMap(),
    );
  }

  static Future<List<DccNotification>>
  getNotificationsForUser(
      String email,
      ) async {
    final box = await _getBox();

    final notifications = box.values
        .map(
          (item) =>
          DccNotification.fromMap(
            Map<dynamic, dynamic>.from(item),
          ),
    )
        .where(
          (notification) =>
      notification.recipientEmail
          .trim()
          .toLowerCase() ==
          email.trim().toLowerCase(),
    )
        .toList();

    notifications.sort(
          (a, b) =>
          b.createdAt.compareTo(
            a.createdAt,
          ),
    );

    return notifications;
  }

  static Future<int> getUnreadCount(
      String email,
      ) async {
    final notifications =
    await getNotificationsForUser(
      email,
    );

    return notifications
        .where(
          (notification) =>
      !notification.isRead,
    )
        .length;
  }

  static Future<void> markAsRead(
      String notificationId,
      ) async {
    final box = await _getBox();

    final value =
    box.get(notificationId);

    if (value == null) {
      return;
    }

    final notification =
    DccNotification.fromMap(
      Map<dynamic, dynamic>.from(value),
    );

    await box.put(
      notificationId,
      notification
          .copyWith(isRead: true)
          .toMap(),
    );
  }

  static Future<void> markAllAsRead(
      String email,
      ) async {
    final notifications =
    await getNotificationsForUser(
      email,
    );

    final box = await _getBox();

    for (final notification
    in notifications) {
      if (notification.isRead) {
        continue;
      }

      await box.put(
        notification.id,
        notification
            .copyWith(isRead: true)
            .toMap(),
      );
    }
  }

  static Future<void> deleteNotification(
      String notificationId,
      ) async {
    final box = await _getBox();

    await box.delete(
      notificationId,
    );
  }

  static Future<void> clearAllForUser(
      String email,
      ) async {
    final notifications =
    await getNotificationsForUser(
      email,
    );

    final box = await _getBox();

    for (final notification
    in notifications) {
      await box.delete(
        notification.id,
      );
    }
  }

  static Future<void> notifyAllDcc({
    required String title,
    required String message,
    required String type,
    String documentNo = '',
  }) async {
    final users =
    await DccUserService.getUsers();

    final dccUsers = users.where(
          (user) {
        final userType =
        user.role.trim().toUpperCase();

        return user.active &&
            userType == 'DCC' &&
            user.email.trim().isNotEmpty;
      },
    ).toList();

    final sentEmails = <String>{};

    for (final user in dccUsers) {
      final email =
      user.email.trim().toLowerCase();

      if (sentEmails.contains(email)) {
        continue;
      }

      sentEmails.add(email);

      final notificationId =
          'DCC_${type}_${documentNo}_'
          '${email}_${DateTime.now().microsecondsSinceEpoch}';

      await addNotification(
        DccNotification(
          id: notificationId,
          recipientEmail: email,
          title: title,
          message: message,
          type: type,
          documentNo: documentNo,
          createdAt: DateTime.now(),
        ),
      );
    }
  }
}
