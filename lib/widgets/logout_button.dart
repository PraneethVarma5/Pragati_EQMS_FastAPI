import 'package:flutter/material.dart';

/// A consistent logout icon button for every dashboard app bar.
/// Shows a confirm dialog, then runs [onConfirmed] — callers pass
/// in whatever clearing/locking their session type needs, plus
/// where to navigate afterwards.
class LogoutButton extends StatelessWidget {
  final Future<void> Function() onConfirmed;
  final Color? color;

  const LogoutButton({
    super.key,
    required this.onConfirmed,
    this.color,
  });

  Future<void> _handleTap(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text(
            'You will need to log in again to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFD94A4A),
              ),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await onConfirmed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _handleTap(context),
      icon: Icon(
        Icons.logout_rounded,
        color: color ?? const Color(0xFF172033),
      ),
      tooltip: 'Log out',
    );
  }
}
