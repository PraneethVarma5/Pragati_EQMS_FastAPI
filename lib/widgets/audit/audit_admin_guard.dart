// import 'package:flutter/material.dart';
//
// import '../../services/audit/audit_admin_session.dart';
// import '../../screens/audit/audit_admin_login_screen.dart';
//
// /// Wraps a screen so it only renders once an Audit Administrator is logged
// /// in. If not logged in, shows the login screen inline (no navigation jump,
// /// same pattern as DccGuard/ArrGuard/AdminGuard elsewhere in the app) and
// /// re-renders the protected child automatically the moment login succeeds.
// class AuditAdminGuard extends StatefulWidget {
//   final Widget child;
//
//   const AuditAdminGuard({super.key, required this.child});
//
//   @override
//   State<AuditAdminGuard> createState() => _AuditAdminGuardState();
// }
//
// class _AuditAdminGuardState extends State<AuditAdminGuard> {
//   @override
//   Widget build(BuildContext context) {
//     if (AuditAdminSession.isLoggedIn) {
//       return widget.child;
//     }
//     return AuditAdminLoginScreen(
//       onLoggedIn: () => setState(() {}),
//     );
//   }
// }
