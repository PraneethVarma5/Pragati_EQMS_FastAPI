import 'package:hive_flutter/hive_flutter.dart';

import '../../models/dcc/dcc_activity.dart';

class DccActivityService {
  static const String boxName = 'dccActivities';

  static Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }

    return Hive.box(boxName);
  }

  static Future<void> addActivity(
      DccActivity activity,
      ) async {
    final box = await _getBox();

    await box.put(
      activity.id,
      activity.toMap(),
    );
  }

  static Future<List<DccActivity>> getActivitiesForUser(
      String email,
      ) async {
    final box = await _getBox();

    final activities = box.values
        .map(
          (item) => DccActivity.fromMap(
        Map<dynamic, dynamic>.from(item),
      ),
    )
        .where(
          (activity) =>
      activity.userEmail.toLowerCase() ==
          email.trim().toLowerCase(),
    )
        .toList();

    activities.sort(
          (a, b) => b.timestamp.compareTo(a.timestamp),
    );

    return activities;
  }
}