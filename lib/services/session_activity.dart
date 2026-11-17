import 'package:shared_preferences/shared_preferences.dart';

/// Shared idle-activity clock used by every session type (Admin,
/// ARR, DCC). Sessions are meant to survive a browser refresh but
/// NOT survive true inactivity, so instead of each session storing
/// its own "logged in" flag forever, every session additionally
/// records a `lastActivityAt` timestamp here. On restore, each
/// session asks [isExpired] and clears itself if too much idle
/// time has passed.
///
/// "Activity" is any user interaction anywhere in the app (a tap,
/// a scroll, a keystroke) — see `main.dart`, which wraps the whole
/// app in a `Listener` that calls [touch] on every pointer event.
/// [touch] is throttled to avoid hammering SharedPreferences.
class SessionActivity {
  SessionActivity._();

  static const String _lastActivityKey = 'session_last_activity_at';

  static const Duration idleTimeout = Duration(minutes: 30);

  /// In-memory cache so repeated [touch] calls within the same
  /// tick don't all hit SharedPreferences.
  static DateTime? _lastTouch;

  static const Duration _writeThrottle = Duration(seconds: 5);

  /// Call on any user interaction. Cheap to call often — actual
  /// persistence is throttled to once every few seconds.
  static void touch() {
    final now = DateTime.now();

    if (_lastTouch != null &&
        now.difference(_lastTouch!) < _writeThrottle) {
      return;
    }

    _lastTouch = now;

    // Fire-and-forget; nothing meaningful to do if this fails.
    // ignore: discarded_futures
    _persist(now);
  }

  static Future<void> _persist(DateTime now) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(
      _lastActivityKey,
      now.millisecondsSinceEpoch,
    );
  }

  /// Whether more than [idleTimeout] has passed since the last
  /// recorded activity. If no activity has ever been recorded
  /// (e.g. very first load), treats it as not expired so a fresh
  /// login isn't immediately invalidated.
  static Future<bool> isExpired() async {
    final prefs = await SharedPreferences.getInstance();

    final storedMillis = prefs.getInt(_lastActivityKey);

    if (storedMillis == null) {
      return false;
    }

    final lastActivity =
        DateTime.fromMillisecondsSinceEpoch(storedMillis);

    return DateTime.now().difference(lastActivity) > idleTimeout;
  }

  /// Resets the idle clock — call this on every successful login
  /// so a brand new session always starts with a fresh window.
  static Future<void> reset() async {
    final now = DateTime.now();
    _lastTouch = now;
    await _persist(now);
  }
}
