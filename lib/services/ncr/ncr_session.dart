import 'package:shared_preferences/shared_preferences.dart';

import '../../models/ncr/ncr_user.dart';

class NcrSession {
  NcrSession._();

  static const String _userIdKey = 'ncr_logged_in_user_id';

  static NcrUser? _currentUser;

  static NcrUser? get currentUser => _currentUser;

  static bool get isLoggedIn => _currentUser != null;

  static String? get userId => _currentUser?.id;

  static String? get userName => _currentUser?.fullName;

  static String? get userEmail => _currentUser?.email;

  static String? get roleId => _currentUser?.roleId;

  static String? get roleKey => _currentUser?.roleKey;

  static String? get roleName => _currentUser?.roleName;

  static bool get isAdmin => _currentUser?.isAdmin ?? false;

  static bool get isUser => _currentUser?.isUser ?? false;

  static bool get isHod => _currentUser?.isHod ?? false;

  static bool get isDcc => _currentUser?.isDcc ?? false;

  // ============================================================
  // SET USER
  // ============================================================

  static Future<void> setUser(NcrUser user) async {
    _currentUser = user;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _userIdKey,
      user.id,
    );
  }

  // ============================================================
  // RESTORE SESSION
  // ============================================================

  static Future<String?> getStoredUserId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_userIdKey);
  }

  static Future<void> restoreUser(NcrUser user) async {
    _currentUser = user;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static Future<void> clear() async {
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_userIdKey);
  }

  // ============================================================
  // ROLE CHECKS
  // ============================================================

  static bool hasRole(String role) {
    return _currentUser?.roleKey.toLowerCase() ==
        role.trim().toLowerCase();
  }

  static bool canCreateNcr() {
    return isAdmin;
  }

  static bool canManageUsers() {
    return isAdmin;
  }

  static bool canEditAssignedNcr() {
    return isUser;
  }

  static bool canApproveHod() {
    return isHod;
  }

  static bool canApproveDcc() {
    return isDcc;
  }
}