import 'package:shared_preferences/shared_preferences.dart';

import 'session_activity.dart';

/// Tracks whether the admin area has been unlocked with the
/// correct password. Persisted to SharedPreferences so a browser
/// refresh does NOT log the user out — but idle for 30+ minutes
/// (tracked by [SessionActivity], shared across all session types)
/// still requires unlocking again, same as DccSession/ArrSession.
class AdminSession {
  AdminSession._();

  static const String _unlockedKey = 'admin_session_unlocked';

  static bool _unlocked = false;

  static bool get isUnlocked => _unlocked;

  static void unlock() {
    _unlocked = true;

    // ignore: discarded_futures
    _persist(true);

    // ignore: discarded_futures
    SessionActivity.reset();
  }

  static void lock() {
    _unlocked = false;

    // ignore: discarded_futures
    _persist(false);
  }

  static Future<void> _persist(bool unlocked) async {
    final prefs = await SharedPreferences.getInstance();

    if (unlocked) {
      await prefs.setBool(_unlockedKey, true);
    } else {
      await prefs.remove(_unlockedKey);
    }
  }

  /// Call once at app startup (mirrors DccSession.restoreSession)
  /// to restore an unlocked admin session across a page refresh,
  /// unless it's gone idle too long.
  static Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final wasUnlocked = prefs.getBool(_unlockedKey) ?? false;

      if (!wasUnlocked) {
        _unlocked = false;
        return false;
      }

      if (await SessionActivity.isExpired()) {
        await _persist(false);
        _unlocked = false;
        return false;
      }

      _unlocked = true;
      return true;
    } catch (_) {
      _unlocked = false;
      return false;
    }
  }
}
