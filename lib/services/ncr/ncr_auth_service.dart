import 'package:bcrypt/bcrypt.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/ncr/ncr_user.dart';
import 'ncr_session.dart';

class NcrAuthService {
NcrAuthService._();

static final SupabaseClient _supabase =
Supabase.instance.client;

// ============================================================
// LOGIN
// ============================================================

        static Future<NcrUser> login({
                required String email,
                required String password,
        }) async {
                final normalizedEmail = email.trim().toLowerCase();

                if (normalizedEmail.isEmpty) {
                        throw Exception('Email address is required.');
                }

                if (password.isEmpty) {
                        throw Exception('Password is required.');
                }

                try {
                        final response = await _supabase.rpc(
                                'ncr_login',
                                params: {
                                        'p_email': normalizedEmail,
                                        'p_password': password,
                                },
                        );

                        if (response == null ||
                            response is! List ||
                            response.isEmpty) {
                                throw Exception(
                                        'Invalid email or password.',
                                );
                        }

                        final rawUser = response.first;

                        if (rawUser is! Map) {
                                throw Exception(
                                        'Invalid NCR login response.',
                                );
                        }

                        final userData =
                        Map<String, dynamic>.from(rawUser);

                        final user = NcrUser.fromMap({
                                ...userData,
                                'ncr_roles': {
                                        'id': userData['role_id'],
                                        'role_key': userData['role_key'],
                                        'role_name': userData['role_name'],
                                        'description': null,
                                        'is_active': userData['is_active'],
                                },
                        });

                        if (user.id.trim().isEmpty) {
                                throw Exception(
                                        'Invalid NCR user information.',
                                );
                        }

                        if (user.roleKey.trim().isEmpty) {
                                throw Exception(
                                        'NCR role information is missing.',
                                );
                        }

                        await NcrSession.setUser(user);

                        return user;
                } on PostgrestException catch (e) {
                        throw Exception(
                                e.message,
                        );
                } catch (e) {
                        if (e is Exception) {
                                rethrow;
                        }

                        throw Exception(
                                'Unable to login to NCR.',
                        );
                }
        }
// ============================================================
// LOGOUT
// ============================================================

        static Future<void> logout() async {
                await NcrSession.clear();
        }

// ============================================================
// HASH PASSWORD
// ============================================================

static String hashPassword(String password) {
if (password.isEmpty) {
throw Exception('Password cannot be empty.');
}

return BCrypt.hashpw(
password,
BCrypt.gensalt(),
);
}

// ============================================================
// VERIFY PASSWORD
// ============================================================

static bool verifyPassword({
required String password,
required String passwordHash,
}) {
if (password.isEmpty || passwordHash.isEmpty) {
return false;
}

try {
return BCrypt.checkpw(
password,
passwordHash,
);
} catch (_) {
return false;
}
}

// ============================================================
// CHANGE CURRENT USER PASSWORD
// ============================================================
// ============================================================
// CHANGE PASSWORD FROM LOGIN PAGE
//
// The user is not required to already have an NCR session.
//
// The existing ncr_login RPC verifies the current password.
// After successful verification, the existing authenticated
// password-change method is used, then the temporary session
// is cleared.
//
// No plaintext password is stored.
// ============================================================

        static Future<void> changePasswordFromLogin({
                required String email,
                required String currentPassword,
                required String newPassword,
        }) async {
                final normalizedEmail =
                email.trim().toLowerCase();

                if (normalizedEmail.isEmpty) {
                        throw Exception(
                                'Email address is required.',
                        );
                }

                if (currentPassword.isEmpty) {
                        throw Exception(
                                'Current password is required.',
                        );
                }

                if (newPassword.isEmpty) {
                        throw Exception(
                                'New password is required.',
                        );
                }

                if (newPassword.length < 8) {
                        throw Exception(
                                'New password must contain at least 8 characters.',
                        );
                }

                if (currentPassword == newPassword) {
                        throw Exception(
                                'New password must be different from the current password.',
                        );
                }

                try {
                        // ----------------------------------------------------------
                        // VERIFY CURRENT PASSWORD THROUGH THE EXISTING LOGIN RPC
                        // ----------------------------------------------------------

                        await login(
                                email: normalizedEmail,
                                password: currentPassword,
                        );

                        // ----------------------------------------------------------
                        // CHANGE PASSWORD USING THE EXISTING LOGGED-IN METHOD
                        // ----------------------------------------------------------

                        await changePassword(
                                currentPassword: currentPassword,
                                newPassword: newPassword,
                        );
                } finally {
                        // ----------------------------------------------------------
                        // NEVER LEAVE A TEMPORARY LOGIN SESSION ACTIVE
                        // ----------------------------------------------------------

                        await logout();
                }
        }

// ============================================================
// CREATE NCR USER
// ============================================================

static Future<NcrUser> createUser({
required String fullName,
required String email,
required String roleId,
String password = 'welcome123',
}) async {
if (!NcrSession.isAdmin) {
throw Exception(
'Only an NCR Admin can create NCR users.',
);
}

final cleanedName = fullName.trim();
final normalizedEmail = email.trim().toLowerCase();
final cleanedRoleId = roleId.trim();

if (cleanedName.isEmpty) {
throw Exception('Full name is required.');
}

if (normalizedEmail.isEmpty) {
throw Exception('Email address is required.');
}

if (cleanedRoleId.isEmpty) {
throw Exception('Role is required.');
}

if (password.length < 8) {
throw Exception(
'Password must contain at least 8 characters.',
);
}

// ============================================================
// HASH PASSWORD
// ============================================================

        final passwordHash = BCrypt.hashpw(
                password,
                BCrypt.gensalt(),
        );

// ============================================================
// CREATE USER THROUGH SECURITY-DEFINER RPC
// ============================================================

        final currentUser =
            NcrSession.currentUser;

        if (currentUser == null ||
            !NcrSession.isAdmin) {
                throw Exception(
                        'Only an NCR Admin can create NCR users.',
                );
        }

        final response = await _supabase.rpc(
                'ncr_admin_create_user',
                params: {
                        'p_admin_id': currentUser.id,
                        'p_full_name': cleanedName,
                        'p_email': normalizedEmail,
                        'p_role_id': cleanedRoleId,
                        'p_password_hash': passwordHash,
                },
        );
        if (response == null) {
                throw Exception(
                        'NCR user could not be created.',
                );
        }

        if (response is! Map) {
                throw Exception(
                        'Invalid response while creating NCR user.',
                );
        }

        return NcrUser.fromMap(
                Map<String, dynamic>.from(response),
        );
}

// ============================================================
// LOAD USER BY ID
// ============================================================

static Future<NcrUser?> getUserById(
String userId,
) async {
if (userId.trim().isEmpty) {
return null;
}

final response = await _supabase
    .from('ncr_users')
    .select('''
          id,
          full_name,
          email,
          role_id,
          is_active,
          created_at,
          updated_at,
          ncr_roles (
            id,
            role_key,
            role_name,
            description,
            is_active
          )
        ''')
    .eq('id', userId)
    .maybeSingle();

if (response == null) {
return null;
}

return NcrUser.fromMap(
Map<String, dynamic>.from(response),
);
}
// ============================================================
// CHANGE CURRENT USER PASSWORD
// ============================================================

        static Future<void> changePassword({
                required String currentPassword,
                required String newPassword,
        }) async {
                final user = NcrSession.currentUser;

                if (user == null) {
                        throw Exception(
                                'No NCR user is currently logged in.',
                        );
                }

                if (currentPassword.isEmpty) {
                        throw Exception(
                                'Current password is required.',
                        );
                }

                if (newPassword.isEmpty) {
                        throw Exception(
                                'New password is required.',
                        );
                }

                if (newPassword.length < 8) {
                        throw Exception(
                                'New password must contain at least 8 characters.',
                        );
                }

                if (currentPassword == newPassword) {
                        throw Exception(
                                'New password must be different from the current password.',
                        );
                }

                try {
                        // ----------------------------------------------------------
                        // LOAD CURRENT PASSWORD HASH
                        // ----------------------------------------------------------

                        final response = await _supabase
                            .from('ncr_users')
                            .select('password_hash')
                            .eq('id', user.id)
                            .maybeSingle();

                        if (response == null) {
                                throw Exception(
                                        'NCR user account could not be found.',
                                );
                        }

                        final currentHash =
                            response['password_hash']?.toString() ?? '';

                        if (currentHash.isEmpty) {
                                throw Exception(
                                        'Current password information is missing.',
                                );
                        }

                        // ----------------------------------------------------------
                        // VERIFY CURRENT PASSWORD
                        // ----------------------------------------------------------

                        final currentPasswordMatches =
                        BCrypt.checkpw(
                                currentPassword,
                                currentHash,
                        );

                        if (!currentPasswordMatches) {
                                throw Exception(
                                        'Current password is incorrect.',
                                );
                        }

                        // ----------------------------------------------------------
                        // HASH NEW PASSWORD
                        // ----------------------------------------------------------

                        final newPasswordHash =
                        BCrypt.hashpw(
                                newPassword,
                                BCrypt.gensalt(),
                        );

                        // ----------------------------------------------------------
                        // SAVE NEW HASH
                        // ----------------------------------------------------------

                        await _supabase
                            .from('ncr_users')
                            .update({
                                'password_hash': newPasswordHash,
                                'updated_at':
                                DateTime.now()
                                    .toUtc()
                                    .toIso8601String(),
                        })
                            .eq(
                                'id',
                                user.id,
                        );
                } on PostgrestException catch (e) {
                        throw Exception(
                                e.message,
                        );
                } catch (e) {
                        if (e is Exception) {
                                rethrow;
                        }

                        throw Exception(
                                'Unable to change NCR password.',
                        );
                }
        }
}
