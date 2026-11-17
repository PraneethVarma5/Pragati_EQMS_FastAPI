
import 'package:flutter/material.dart';

import '../services/dcc/dcc_session.dart';
import '../services/dcc/dcc_user_service.dart';

class DccChangePasswordDialog extends StatefulWidget {
  const DccChangePasswordDialog({super.key});

  static Future<void> show(BuildContext context) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DccChangePasswordDialog(),
    );

    if (changed == true && context.mounted) {
      // The server has already revoked the current session.
      // clear() also removes local credentials if server logout fails.
      await DccSession.clear();

      if (!context.mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/DCC',
            (route) => false,
      );
    }
  }

  @override
  State<DccChangePasswordDialog> createState() =>
      _DccChangePasswordDialogState();
}

class _DccChangePasswordDialogState
    extends State<DccChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final user = DccSession.currentUser;

    if (user == null) {
      _showMessage('Your session has expired. Please log in again.');
      return;
    }

    setState(() => _loading = true);

    try {
      final success = await DccUserService.changePassword(
        email: user.email,
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );

      if (!mounted) return;

      if (!success) {
        _showMessage('Current password is incorrect.');
        return;
      }

      Navigator.of(context).pop(true);
    } catch (e, stackTrace) {
      debugPrint('========== DCC PASSWORD CHANGE ERROR ==========');
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      debugPrint('================================================');

      if (!mounted) return;

      _showMessage('Password change failed. Check the debug console.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _decoration(
      String label,
      bool hidden,
      VoidCallback toggle,
      ) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      suffixIcon: IconButton(
        onPressed: toggle,
        icon: Icon(
          hidden ? Icons.visibility_off : Icons.visibility,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lock_outline),
          SizedBox(width: 10),
          Text('Change Password'),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _currentController,
                  obscureText: _hideCurrent,
                  enabled: !_loading,
                  decoration: _decoration(
                    'Current password',
                    _hideCurrent,
                        () => setState(
                          () => _hideCurrent = !_hideCurrent,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newController,
                  obscureText: _hideNew,
                  enabled: !_loading,
                  decoration: _decoration(
                    'New password',
                    _hideNew,
                        () => setState(() => _hideNew = !_hideNew),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'Password must contain at least 8 characters';
                    }
                    if (value.length > 128) {
                      return 'Password cannot exceed 128 characters';
                    }
                    if (value == _currentController.text) {
                      return 'New password must differ from current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _hideConfirm,
                  enabled: !_loading,
                  decoration: _decoration(
                    'Confirm new password',
                    _hideConfirm,
                        () => setState(
                          () => _hideConfirm = !_hideConfirm,
                    ),
                  ),
                  validator: (value) {
                    if (value != _newController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (!_loading) _changePassword();
                  },
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Use at least 8 characters. You will need to log in again after changing your password.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _changePassword,
          child: _loading
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
              : const Text('Update Password'),
        ),
      ],
    );
  }
}
