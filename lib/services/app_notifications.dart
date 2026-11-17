import 'package:flutter/material.dart';

/// A GlobalKey<ScaffoldMessengerState> mounted once on the root
/// MaterialApp (see main.dart). This lets any service — including
/// realtime subscription callbacks that don't have a screen's
/// BuildContext — show an on-screen notification banner from
/// anywhere in the app.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
GlobalKey<ScaffoldMessengerState>();

/// Shows a lightweight on-screen notification banner. Safe to call
/// from a realtime callback, a background service, or any widget.
void showAppNotification(
    String message, {
      IconData icon = Icons.notifications_active_rounded,
      Color color = const Color(0xFF3155C6),
    }) {
  final messenger = rootScaffoldMessengerKey.currentState;

  if (messenger == null) {
    return;
  }

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: color,
      duration: const Duration(seconds: 4),
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}
