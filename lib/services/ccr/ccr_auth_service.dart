
import 'ccr_api_client.dart';
import 'ccr_session.dart';

class CcrAuthService {
  CcrAuthService._();

  // ============================================================
  // NORMALIZE API USER RESPONSE
  // ============================================================

  static Map<String, dynamic> _normalizeUserData(
      Map<String, dynamic> data,
      ) {
    final normalized = Map<String, dynamic>.from(data);

    // Support nested or top-level user responses.
    final rawUser = normalized['user'];

    final userData = rawUser is Map
        ? Map<String, dynamic>.from(rawUser)
        : normalized;

    // Backend user_id -> Flutter id
    userData['id'] ??= userData['user_id'];

    // Support both password field spellings.
    userData['must_change_password'] ??=
        userData['must_change_passwor'] ??
            userData['must_change_password'];

    // Keep full name available.
    userData['full_name'] ??=
        userData['fullName'] ??
            userData['email'] ??
            '';

    // Normalize role.
    userData['role'] ??= 'user';

    // Normalize active status.
    userData['is_active'] ??= true;

    return userData;
  }

  // ============================================================
  // LOGIN
  // ============================================================

  static Future<CcrUser> login({
    required String email,
    required String password,
  }) async {
    final response = await CcrApiClient.post(
      '/auth/login',
      authenticated: false,
      body: {
        'email': email.trim(),
        'password': password,
      },
    );

    if (response is! Map) {
      throw Exception('Invalid login response from the server.');
    }

    final data = Map<String, dynamic>.from(response);

    final token = data['session_token']?.toString() ?? '';

    if (token.trim().isEmpty) {
      throw Exception(
        'Login failed: session token was not returned.',
      );
    }

    final userData = _normalizeUserData(data);

    if (userData['id'] == null ||
        userData['email'] == null ||
        userData['email'].toString().trim().isEmpty) {
      throw Exception(
        'Login response is missing required user details. '
            'Received keys: ${data.keys.join(', ')}',
      );
    }

    final user = CcrUser.fromMap(userData);

    if (!user.isActive) {
      throw Exception('This account is inactive.');
    }

    await CcrSession.setSession(
      user: user,
      sessionToken: token,
    );

    return user;
  }

  // ============================================================
  // VALIDATE EXISTING SESSION
  // ============================================================

  static Future<CcrUser?> validateSession() async {
    if (!CcrSession.isLoggedIn) {
      return null;
    }

    try {
      final response = await CcrApiClient.get(
        '/auth/session',
        authenticated: true,
      );

      if (response is! Map) {
        await CcrSession.clear();
        return null;
      }

      final data = Map<String, dynamic>.from(response);
      final userData = _normalizeUserData(data);

      if (userData['id'] == null ||
          userData['email'] == null) {
        await CcrSession.clear();
        return null;
      }

      final user = CcrUser.fromMap(userData);

      if (!user.isActive) {
        await CcrSession.clear();
        return null;
      }

      final token = CcrSession.sessionToken;

      if (token == null || token.trim().isEmpty) {
        await CcrSession.clear();
        return null;
      }

      await CcrSession.setSession(
        user: user,
        sessionToken: token,
      );

      return user;
    } catch (_) {
      await CcrSession.clear();
      return null;
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static Future<void> logout() async {
    try {
      if (CcrSession.sessionToken != null) {
        await CcrApiClient.post(
          '/auth/logout',
          authenticated: true,
        );
      }
    } finally {
      await CcrSession.clear();
    }
  }

  // ============================================================
  // CHANGE PASSWORD (LOGGED-IN USER)
  // ============================================================

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await CcrApiClient.post(
      '/auth/change-password',
      authenticated: true,
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );

    if (response is Map && response['success'] == false) {
      throw Exception(
        response['message']?.toString() ??
            response['detail']?.toString() ??
            'Password change failed.',
      );
    }

    final currentUser = CcrSession.currentUser;

    if (currentUser != null) {
      final updatedUser = CcrUser(
        id: currentUser.id,
        fullName: currentUser.fullName,
        email: currentUser.email,
        role: currentUser.role,
        isActive: currentUser.isActive,
        mustChangePassword: false,
      );

      final token = CcrSession.sessionToken;

      if (token != null && token.isNotEmpty) {
        await CcrSession.setSession(
          user: updatedUser,
          sessionToken: token,
        );
      }
    }
  }

  // ============================================================
  // CHANGE PASSWORD BEFORE LOGIN
  // ============================================================

  static Future<void> changePasswordFromLogin({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await CcrApiClient.post(
      '/auth/change-password-from-login',
      authenticated: false,
      body: {
        'email': email.trim(),
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );

    if (response is! Map || response['success'] != true) {
      throw Exception(
        response is Map
            ? response['message']?.toString() ??
            response['detail']?.toString() ??
            'Password change failed.'
            : 'Invalid response from the server.',
      );
    }
  }
}
