import 'package:hive_flutter/hive_flutter.dart';

class CcrUser {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;
  final bool mustChangePassword;

  const CcrUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    required this.mustChangePassword,
  });

  bool get isAdmin =>
      role.trim().toLowerCase() == 'admin';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': role,
      'is_active': isActive,
      'must_change_password': mustChangePassword,
    };
  }

  factory CcrUser.fromMap(
      Map<String, dynamic> map,
      ) {
    return CcrUser(
      id: map['id']?.toString() ?? '',
      fullName:
      map['full_name']?.toString() ?? '',
      email:
      map['email']?.toString() ?? '',
      role:
      map['role']?.toString() ?? 'user',
      isActive:
      map['is_active'] == true,
      mustChangePassword:
      map['must_change_password'] == true,
    );
  }
}

class CcrSession {
  CcrSession._();

  static const String _boxName =
      'ccrSession';

  static const String _userKey =
      'user';

  static const String _tokenKey =
      'session_token';

  static const String _activityKey =
      'last_activity';

  static const Duration idleLimit =
  Duration(minutes: 15);

  static Box? _box;

  static CcrUser? _currentUser;
  static String? _sessionToken;
  static DateTime? _lastActivity;

  static CcrUser? get currentUser =>
      _currentUser;

  static String? get sessionToken =>
      _sessionToken;

  static bool get isLoggedIn =>
      _currentUser != null &&
          _sessionToken != null;

  static bool get isAdmin =>
      _currentUser?.isAdmin ?? false;

  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    await restore();
  }

  static Future<void> restore() async {
    _box ??=
    await Hive.openBox(_boxName);

    final userMap =
    _box!.get(_userKey);

    final token =
    _box!.get(_tokenKey)?.toString();

    final activityRaw =
    _box!.get(_activityKey);

    if (userMap is! Map ||
        token == null ||
        token.trim().isEmpty ||
        activityRaw == null) {
      await clear();
      return;
    }

    final activity =
    DateTime.tryParse(
      activityRaw.toString(),
    );

    if (activity == null ||
        DateTime.now().difference(activity) >
            idleLimit) {
      await clear();
      return;
    }

    _currentUser =
        CcrUser.fromMap(
          Map<String, dynamic>.from(
            userMap,
          ),
        );

    _sessionToken =
        token;

    _lastActivity =
        activity;
  }

  static Future<void> setSession({
    required CcrUser user,
    required String sessionToken,
  }) async {
    _box ??=
    await Hive.openBox(_boxName);

    final now =
    DateTime.now();

    _currentUser = user;
    _sessionToken =
        sessionToken;
    _lastActivity = now;

    await _box!.put(
      _userKey,
      user.toMap(),
    );

    await _box!.put(
      _tokenKey,
      sessionToken,
    );

    await _box!.put(
      _activityKey,
      now.toIso8601String(),
    );
  }

  static Future<void> touch() async {
    if (!isLoggedIn) {
      return;
    }

    final now =
    DateTime.now();

    if (_lastActivity != null &&
        now.difference(_lastActivity!) >
            idleLimit) {
      await clear();
      return;
    }

    _lastActivity = now;

    _box ??=
    await Hive.openBox(_boxName);

    await _box!.put(
      _activityKey,
      now.toIso8601String(),
    );
  }

  static bool get isExpired {
    if (!isLoggedIn ||
        _lastActivity == null) {
      return true;
    }

    return DateTime.now()
        .difference(_lastActivity!) >
        idleLimit;
  }

  static Future<void> clear() async {
    _currentUser = null;
    _sessionToken = null;
    _lastActivity = null;

    _box ??=
    await Hive.openBox(_boxName);

    await _box!.clear();
  }
}