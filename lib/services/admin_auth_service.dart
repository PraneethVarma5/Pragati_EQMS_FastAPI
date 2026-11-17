import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles admin password verification/changes against Supabase.
/// The password is stored hashed (pgcrypto, bcrypt) in
/// admin_profiles.password_hash. All comparisons happen inside
/// Postgres via RPC functions — the hash is never sent to, or
/// compared on, the client. No password is hardcoded here, and
/// this does not use Supabase Auth (by design, since the backing
/// project may change between dev/test and production).
class AdminAuthService {
  AdminAuthService._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Returns true if [password] matches the stored admin password.
  static Future<bool> verifyPassword(String password) async {
    final result = await _client.rpc(
      'verify_admin_password',
      params: {'p_password': password},
    );

    return result == true;
  }

  /// Changes the admin password. [currentPassword] must be
  /// correct; returns false (and leaves the password unchanged)
  /// if it is not.
  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await _client.rpc(
      'set_admin_password',
      params: {
        'p_current_password': currentPassword,
        'p_new_password': newPassword,
      },
    );

    return result == true;
  }

  /// Resets the admin password without the current password.
  /// Only call this after the user's identity has already been
  /// confirmed through another channel (the emailed-OTP step on
  /// the existing "Forgot Password" screen).
  static Future<void> resetPasswordAfterOtp(String newPassword) async {
    await _client.rpc(
      'admin_reset_password_after_otp',
      params: {'p_new_password': newPassword},
    );
  }
}
