import 'package:flutter/material.dart';

import '../services/dcc/dcc_session.dart';
import '../screens/dcc/dcc_login_screen.dart';

/// Wraps a DCC screen so it can only be reached by a logged-in DCC
/// user — and, when [requiredRole] is given, only by a user with
/// that exact role (any other role's valid login is rejected, not
/// silently redirected to their own dashboard). If there's no
/// active session (or the wrong role), the DCC login screen is
/// shown in place of the requested screen instead of the screen
/// itself. This closes the gap where navigating straight to a
/// dashboard URL (typing it, bookmarking it, refreshing on it)
/// used to skip login entirely.
///
/// DccSession persists to SharedPreferences and survives a page
/// reload, but expires after 30 minutes of no activity anywhere in
/// the app (see SessionActivity) — this mirrors AdminGuard and
/// ArrGuard's session behaviour.
///
/// By default, after a successful login, DccLoginScreen falls back
/// to its own role-based redirect (to that role's dashboard). Pass
/// [redirectRoute] to send a successful login straight to this
/// specific screen instead — e.g. so following a "Master Data"
/// link while logged out lands on Master Data itself, not the DCC
/// dashboard.
class DccGuard extends StatelessWidget {
  final Widget child;
  final String? requiredRole;
  final String? redirectRoute;

  const DccGuard({
    super.key,
    required this.child,
    this.requiredRole,
    this.redirectRoute,
  });

  @override
  Widget build(BuildContext context) {
    final user = DccSession.currentUser;

    final allowed = user != null &&
        (requiredRole == null || user.role == requiredRole);

    if (allowed) {
      return child;
    }

    return DccLoginScreen(
      requiredRole: requiredRole,
      redirectRoute: redirectRoute,
    );
  }
}
