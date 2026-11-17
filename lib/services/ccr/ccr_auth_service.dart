import 'package:supabase_flutter/supabase_flutter.dart';

import 'ccr_session.dart';

class CcrAuthService {
  CcrAuthService._();

  static final SupabaseClient _supabase =
      Supabase.instance.client;

  static Future<CcrUser> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail =
    email.trim().toLowerCase();

    final cleanPassword =
    password.trim();

    if (cleanEmail.isEmpty) {
      throw Exception(
        'Email address is required.',
      );
    }

    if (cleanPassword.isEmpty) {
      throw Exception(
        'Password is required.',
      );
    }

    try {
      final response =
      await _supabase.rpc(
        'ccr_login',
        params: {
          'p_email': cleanEmail,
          'p_password': cleanPassword,
        },
      );

      if (response == null ||
          response is! Map) {
        throw Exception(
          'Invalid login response.',
        );
      }

      final data =
      Map<String, dynamic>.from(
        response,
      );

      final token =
      data['session_token']
          ?.toString();

      if (token == null ||
          token.isEmpty) {
        throw Exception(
          'Login session was not created.',
        );
      }

      final user =
      CcrUser.fromMap(data);

      await CcrSession.setSession(
        user: user,
        sessionToken: token,
      );

      return user;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to login.',
      );
    }
  }

  static Future<CcrUser> validateSession() async {
    final token =
        CcrSession.sessionToken;

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'CCR session has expired.',
      );
    }

    try {
      final response =
      await _supabase.rpc(
        'ccr_validate_session',
        params: {
          'p_session_token':
          token,
        },
      );

      if (response == null ||
          response is! Map) {
        throw Exception(
          'Invalid session response.',
        );
      }

      final user =
      CcrUser.fromMap(
        Map<String, dynamic>.from(
          response,
        ),
      );

      await CcrSession.setSession(
        user: user,
        sessionToken: token,
      );

      return user;
    } on PostgrestException catch (e) {
      await CcrSession.clear();
      throw Exception(e.message);
    } catch (e) {
      await CcrSession.clear();

      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'CCR session has expired.',
      );
    }
  }

  static Future<void> logout() async {
    final token =
        CcrSession.sessionToken;

    try {
      if (token != null &&
          token.trim().isNotEmpty) {
        await _supabase.rpc(
          'ccr_logout',
          params: {
            'p_session_token':
            token,
          },
        );
      }
    } finally {
      await CcrSession.clear();
    }
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token =
        CcrSession.sessionToken;

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'Please login first.',
      );
    }

    if (newPassword.trim().length < 6) {
      throw Exception(
        'New password must contain at least 6 characters.',
      );
    }

    try {
      await _supabase.rpc(
        'ccr_change_password',
        params: {
          'p_session_token':
          token,
          'p_current_password':
          currentPassword.trim(),
          'p_new_password':
          newPassword.trim(),
        },
      );

      final user =
          CcrSession.currentUser;

      if (user != null) {
        await CcrSession.setSession(
          user: CcrUser(
            id: user.id,
            fullName: user.fullName,
            email: user.email,
            role: user.role,
            isActive: user.isActive,
            mustChangePassword: false,
          ),
          sessionToken: token,
        );
      }
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
  // ============================================================
// CHANGE PASSWORD FROM LOGIN PAGE
// ============================================================

  static Future<void> changePasswordFromLogin({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final normalizedEmail =
    email.trim().toLowerCase();

    final current =
    currentPassword.trim();

    final next =
    newPassword.trim();

    if (normalizedEmail.isEmpty) {
      throw Exception(
        'Email address is required.',
      );
    }

    if (current.isEmpty) {
      throw Exception(
        'Current password is required.',
      );
    }

    if (next.isEmpty) {
      throw Exception(
        'New password is required.',
      );
    }

    if (next.length < 8) {
      throw Exception(
        'New password must contain at least 8 characters.',
      );
    }

    if (current == next) {
      throw Exception(
        'New password must be different from the current password.',
      );
    }

    try {
      final response =
      await _supabase.rpc(
        'ccr_change_password_from_login',
        params: {
          'p_email': normalizedEmail,
          'p_current_password': current,
          'p_new_password': next,
        },
      );

      if (response != true) {
        throw Exception(
          'Password could not be changed.',
        );
      }
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}