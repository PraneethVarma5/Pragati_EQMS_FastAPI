import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Session for the Audit admin area.
///
/// The actual admin session token returned by the database is stored locally
/// and reused by all Audit admin modules.
///
/// The session expires after 15 minutes of inactivity.
class AuditAdminSession {
  AuditAdminSession._();

  static const _boxName = 'auditAdminSession';

  // Admin session inactivity timeout.
  static const _idleLimit = Duration(minutes: 15);

  static Box? _box;

  static Future<Box> _openBox() async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  /// Call once from main().
  static Future<void> restoreSession() async {
    await _openBox();

    // Immediately remove an expired session.
    if (!isLoggedIn) {
      await logout();
    }
  }

  /// Whether the current Audit Admin session is still valid.
  static bool get isLoggedIn {
    final box = _box;

    if (box == null) {
      return false;
    }

    final email = box.get('email');
    final sessionToken = box.get('sessionToken');
    final lastActivity = box.get('lastActivity');

    if (email == null ||
        sessionToken == null ||
        lastActivity == null) {
      return false;
    }

    if (email.toString().trim().isEmpty ||
        sessionToken.toString().trim().isEmpty) {
      return false;
    }

    final last = DateTime.tryParse(
      lastActivity.toString(),
    );

    if (last == null) {
      return false;
    }

    final elapsed = DateTime.now().difference(last);

    if (elapsed > _idleLimit) {
      // Do not await here because this getter is synchronous.
      logout();
      return false;
    }

    return true;
  }

  static String? get email {
    final value = _box?.get('email');

    if (value == null) {
      return null;
    }

    return value.toString();
  }

  /// The real database-issued admin session token.
  static String? get sessionToken {
    final value = _box?.get('sessionToken');

    if (value == null) {
      return null;
    }

    final token = value.toString().trim();

    return token.isEmpty ? null : token;
  }

  /// Refresh the inactivity timer.
  static void touch() {
    if (!isLoggedIn) {
      return;
    }

    _box?.put(
      'lastActivity',
      DateTime.now().toIso8601String(),
    );
  }

  /// Start an Audit Admin session using the real token returned by
  /// verify_audit_admin_login().
  static Future<void> login({
    required String email,
    required String sessionToken,
  }) async {
    final cleanEmail = email.trim();
    final cleanToken = sessionToken.trim();

    if (cleanEmail.isEmpty) {
      throw Exception('Admin email is missing.');
    }

    if (cleanToken.isEmpty) {
      throw Exception('Admin session token is missing.');
    }

    final box = await _openBox();

    await box.put(
      'email',
      cleanEmail,
    );

    await box.put(
      'sessionToken',
      cleanToken,
    );

    await box.put(
      'lastActivity',
      DateTime.now().toIso8601String(),
    );
  }

  /// Detect a rejected/expired Admin session and return the user to login.
  /// Call this from an Admin screen's catch block.
  static Future<bool> handleSessionExpired(
    BuildContext context,
    Object error,
  ) async {
    final message = error.toString().toLowerCase();
    final expired = message.contains('401') ||
        message.contains('unauthorized') ||
        message.contains('invalid or expired') ||
        message.contains('session has expired') ||
        message.contains('session is invalid') ||
        message.contains('session token is missing') ||
        message.contains('admin session is missing');

    if (!expired) return false;

    // Clear the local credentials before navigating away.
    await logout();

    if (!context.mounted) return true;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/AUDIT/admin/login',
      (route) => false,
    );
    return true;
  }

  /// Completely remove the Audit Admin session.
  static Future<void> logout() async {
    final box = await _openBox();

    await box.delete('email');
    await box.delete('sessionToken');
    await box.delete('lastActivity');
  }
}