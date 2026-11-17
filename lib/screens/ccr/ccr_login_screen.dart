import 'package:flutter/material.dart';

import '../../services/ccr/ccr_auth_service.dart';
import '../../services/ccr/ccr_session.dart';

class CcrLoginScreen extends StatefulWidget {
  const CcrLoginScreen({
    super.key,
  });

  @override
  State<CcrLoginScreen> createState() =>
      _CcrLoginScreenState();
}

class _CcrLoginScreenState
    extends State<CcrLoginScreen> {
  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _login() async {
    if (_loading) return;

    final email =
    _emailController.text.trim();

    final password =
        _passwordController.text;

    if (email.isEmpty) {
      _showMessage(
        'Email address is required.',
      );
      return;
    }

    if (password.isEmpty) {
      _showMessage(
        'Password is required.',
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final user =
      await CcrAuthService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // --------------------------------------------------------
      // New users created by Admin must change the default
      // password before entering the Admin dashboard.
      // --------------------------------------------------------

      if (user.mustChangePassword) {
        await _showForcedChangePasswordDialog();

        if (!mounted) return;

        if (CcrSession.currentUser
            ?.mustChangePassword ==
            true) {
          return;
        }
      }

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/CCR/admin',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // CHANGE PASSWORD FROM LOGIN PAGE
  //
  // This is used when the user is NOT logged in.
  //
  // Requires:
  // Email
  // Current password
  // New password
  // Confirm new password
  // ============================================================

  Future<void> _showChangePasswordDialog() async {
    final TextEditingController emailController =
    TextEditingController(
      text: _emailController.text.trim(),
    );

    final TextEditingController currentController =
    TextEditingController();

    final TextEditingController newController =
    TextEditingController();

    final TextEditingController confirmController =
    TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
              dialogBuildContext,
              setDialogState,
              ) {
            Future<void> changePassword() async {
              final email =
              emailController.text.trim();

              final current =
                  currentController.text;

              final newPassword =
                  newController.text;

              final confirm =
                  confirmController.text;

              // ------------------------------------------------
              // VALIDATION
              // ------------------------------------------------

              if (email.isEmpty) {
                _showDialogMessage(
                  dialogContext,
                  'Email address is required.',
                );
                return;
              }

              if (!email.contains('@')) {
                _showDialogMessage(
                  dialogContext,
                  'Enter a valid email address.',
                );
                return;
              }

              if (current.isEmpty) {
                _showDialogMessage(
                  dialogContext,
                  'Current password is required.',
                );
                return;
              }

              if (newPassword.isEmpty) {
                _showDialogMessage(
                  dialogContext,
                  'New password is required.',
                );
                return;
              }

              if (newPassword.length < 8) {
                _showDialogMessage(
                  dialogContext,
                  'New password must contain at least 8 characters.',
                );
                return;
              }

              if (confirm.isEmpty) {
                _showDialogMessage(
                  dialogContext,
                  'Please confirm the new password.',
                );
                return;
              }

              if (newPassword != confirm) {
                _showDialogMessage(
                  dialogContext,
                  'New passwords do not match.',
                );
                return;
              }

              if (current == newPassword) {
                _showDialogMessage(
                  dialogContext,
                  'New password must be different from the current password.',
                );
                return;
              }

              setDialogState(() {
                saving = true;
              });

              try {
                await CcrAuthService
                    .changePasswordFromLogin(
                  email: email,
                  currentPassword: current,
                  newPassword: newPassword,
                );

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                );

                if (!mounted) return;

                _showMessage(
                  'Password changed successfully. You can now login with your new password.',
                );
              } catch (e) {
                if (!dialogContext.mounted) {
                  return;
                }

                setDialogState(() {
                  saving = false;
                });

                _showDialogMessage(
                  dialogContext,
                  _cleanError(e),
                );
              }
            }

            return AlertDialog(
              title: const Text(
                'Change Password',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),

              content: SizedBox(
                width: 430,

                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,

                    children: [
                      // ------------------------------------------------
                      // EMAIL
                      // ------------------------------------------------

                      TextField(
                        controller:
                        emailController,

                        keyboardType:
                        TextInputType.emailAddress,

                        textInputAction:
                        TextInputAction.next,

                        decoration:
                        const InputDecoration(
                          labelText: 'Email',
                          prefixIcon:
                          Icon(
                            Icons
                                .email_outlined,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ------------------------------------------------
                      // CURRENT PASSWORD
                      // ------------------------------------------------

                      TextField(
                        controller:
                        currentController,

                        obscureText:
                        obscureCurrent,

                        textInputAction:
                        TextInputAction.next,

                        decoration:
                        InputDecoration(
                          labelText:
                          'Current Password',

                          prefixIcon:
                          const Icon(
                            Icons
                                .lock_outline,
                          ),

                          suffixIcon:
                          IconButton(
                            tooltip:
                            obscureCurrent
                                ? 'Show password'
                                : 'Hide password',

                            onPressed: () {
                              setDialogState(() {
                                obscureCurrent =
                                !obscureCurrent;
                              });
                            },

                            icon: Icon(
                              obscureCurrent
                                  ? Icons
                                  .visibility_outlined
                                  : Icons
                                  .visibility_off_outlined,
                            ),
                          ),

                          border:
                          const OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ------------------------------------------------
                      // NEW PASSWORD
                      // ------------------------------------------------

                      TextField(
                        controller:
                        newController,

                        obscureText:
                        obscureNew,

                        textInputAction:
                        TextInputAction.next,

                        decoration:
                        InputDecoration(
                          labelText:
                          'New Password',

                          prefixIcon:
                          const Icon(
                            Icons
                                .lock_reset_outlined,
                          ),

                          suffixIcon:
                          IconButton(
                            tooltip:
                            obscureNew
                                ? 'Show password'
                                : 'Hide password',

                            onPressed: () {
                              setDialogState(() {
                                obscureNew =
                                !obscureNew;
                              });
                            },

                            icon: Icon(
                              obscureNew
                                  ? Icons
                                  .visibility_outlined
                                  : Icons
                                  .visibility_off_outlined,
                            ),
                          ),

                          border:
                          const OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ------------------------------------------------
                      // CONFIRM NEW PASSWORD
                      // ------------------------------------------------

                      TextField(
                        controller:
                        confirmController,

                        obscureText:
                        obscureConfirm,

                        textInputAction:
                        TextInputAction.done,

                        onSubmitted: (_) {
                          if (!saving) {
                            changePassword();
                          }
                        },

                        decoration:
                        InputDecoration(
                          labelText:
                          'Confirm New Password',

                          prefixIcon:
                          const Icon(
                            Icons
                                .lock_reset_outlined,
                          ),

                          suffixIcon:
                          IconButton(
                            tooltip:
                            obscureConfirm
                                ? 'Show password'
                                : 'Hide password',

                            onPressed: () {
                              setDialogState(() {
                                obscureConfirm =
                                !obscureConfirm;
                              });
                            },

                            icon: Icon(
                              obscureConfirm
                                  ? Icons
                                  .visibility_outlined
                                  : Icons
                                  .visibility_off_outlined,
                            ),
                          ),

                          border:
                          const OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      const Align(
                        alignment:
                        Alignment.centerLeft,

                        child: Text(
                          'Password must contain at least 8 characters.',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                            Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child:
                  const Text('Cancel'),
                ),

                FilledButton(
                  onPressed:
                  saving
                      ? null
                      : changePassword,

                  child: saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Change Password',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
  }

  // ============================================================
  // FORCED PASSWORD CHANGE
  //
  // Used after a newly-created user logs in using
  // the default password "welcome123".
  //
  // At this point the user already has a CCR session.
  // ============================================================

  Future<void>
  _showForcedChangePasswordDialog() async {
    final TextEditingController currentController =
    TextEditingController();

    final TextEditingController newController =
    TextEditingController();

    final TextEditingController confirmController =
    TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool saving = false;

    await showDialog<void>(
      context: context,

      barrierDismissible: false,

      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
              dialogBuildContext,
              setDialogState,
              ) {
            Future<void> save() async {
              final current =
                  currentController.text;

              final next =
                  newController.text;

              final confirm =
                  confirmController.text;

              if (current.isEmpty ||
                  next.isEmpty ||
                  confirm.isEmpty) {
                _showDialogMessage(
                  dialogContext,
                  'All password fields are required.',
                );
                return;
              }

              if (next.length < 8) {
                _showDialogMessage(
                  dialogContext,
                  'New password must contain at least 8 characters.',
                );
                return;
              }

              if (next != confirm) {
                _showDialogMessage(
                  dialogContext,
                  'New passwords do not match.',
                );
                return;
              }

              if (current == next) {
                _showDialogMessage(
                  dialogContext,
                  'New password must be different from the current password.',
                );
                return;
              }

              setDialogState(() {
                saving = true;
              });

              try {
                await CcrAuthService
                    .changePassword(
                  currentPassword:
                  current,
                  newPassword:
                  next,
                );

                if (!dialogContext.mounted) {
                  return;
                }

                // The service should update the session's
                // mustChangePassword flag after success.

                Navigator.pop(
                  dialogContext,
                );

                if (!mounted) return;

                _showMessage(
                  'Password changed successfully.',
                );
              } catch (e) {
                if (!dialogContext.mounted) {
                  return;
                }

                setDialogState(() {
                  saving = false;
                });

                _showDialogMessage(
                  dialogContext,
                  _cleanError(e),
                );
              }
            }

            return AlertDialog(
              title: const Text(
                'Change Password Required',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              content: SizedBox(
                width: 430,

                child:
                SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,

                    children: [
                      const Padding(
                        padding:
                        EdgeInsets.only(
                          bottom: 18,
                        ),

                        child: Text(
                          'Your account was created with the default password. You must change it before continuing.',
                        ),
                      ),

                      // CURRENT
                      TextField(
                        controller:
                        currentController,

                        obscureText:
                        obscureCurrent,

                        textInputAction:
                        TextInputAction.next,

                        decoration:
                        InputDecoration(
                          labelText:
                          'Current Password',

                          prefixIcon:
                          const Icon(
                            Icons
                                .lock_outline,
                          ),

                          suffixIcon:
                          IconButton(
                            onPressed: () {
                              setDialogState(() {
                                obscureCurrent =
                                !obscureCurrent;
                              });
                            },

                            icon: Icon(
                              obscureCurrent
                                  ? Icons
                                  .visibility_outlined
                                  : Icons
                                  .visibility_off_outlined,
                            ),
                          ),

                          border:
                          const OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // NEW
                      TextField(
                        controller:
                        newController,

                        obscureText:
                        obscureNew,

                        textInputAction:
                        TextInputAction.next,

                        decoration:
                        InputDecoration(
                          labelText:
                          'New Password',

                          prefixIcon:
                          const Icon(
                            Icons
                                .lock_reset_outlined,
                          ),

                          suffixIcon:
                          IconButton(
                            onPressed: () {
                              setDialogState(() {
                                obscureNew =
                                !obscureNew;
                              });
                            },

                            icon: Icon(
                              obscureNew
                                  ? Icons
                                  .visibility_outlined
                                  : Icons
                                  .visibility_off_outlined,
                            ),
                          ),

                          border:
                          const OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // CONFIRM
                      TextField(
                        controller:
                        confirmController,

                        obscureText:
                        obscureConfirm,

                        textInputAction:
                        TextInputAction.done,

                        onSubmitted: (_) {
                          if (!saving) {
                            save();
                          }
                        },

                        decoration:
                        InputDecoration(
                          labelText:
                          'Confirm New Password',

                          prefixIcon:
                          const Icon(
                            Icons
                                .lock_reset_outlined,
                          ),

                          suffixIcon:
                          IconButton(
                            onPressed: () {
                              setDialogState(() {
                                obscureConfirm =
                                !obscureConfirm;
                              });
                            },

                            icon: Icon(
                              obscureConfirm
                                  ? Icons
                                  .visibility_outlined
                                  : Icons
                                  .visibility_off_outlined,
                            ),
                          ),

                          border:
                          const OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      const Align(
                        alignment:
                        Alignment.centerLeft,

                        child: Text(
                          'Password must contain at least 8 characters.',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                            Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                FilledButton(
                  onPressed:
                  saving ? null : save,

                  child: saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Change Password',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst(
      'Exception: ',
      '',
    )
        .replaceFirst(
      'PostgrestException(message: ',
      '',
    );
  }

  void _showMessage(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _showDialogMessage(
      BuildContext dialogContext,
      String message,
      ) {
    if (!dialogContext.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      dialogContext,
    ).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),

      appBar: AppBar(
        title:
        const Text('CCR Login'),
      ),

      body: Center(
        child: Card(
          elevation: 0,

          margin:
          const EdgeInsets.all(24),

          child: Padding(
            padding:
            const EdgeInsets.all(28),

            child: SizedBox(
              width: 430,

              child: Column(
                mainAxisSize:
                MainAxisSize.min,

                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 52,
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  const Text(
                    'CCR Administration',

                    style: TextStyle(
                      fontSize: 24,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  // ------------------------------------------------
                  // EMAIL
                  // ------------------------------------------------

                  TextField(
                    controller:
                    _emailController,

                    keyboardType:
                    TextInputType.emailAddress,

                    textInputAction:
                    TextInputAction.next,

                    decoration:
                    const InputDecoration(
                      labelText: 'Email',
                      prefixIcon:
                      Icon(
                        Icons.email_outlined,
                      ),
                      border:
                      OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // ------------------------------------------------
                  // PASSWORD
                  // ------------------------------------------------

                  TextField(
                    controller:
                    _passwordController,

                    obscureText:
                    _obscurePassword,

                    textInputAction:
                    TextInputAction.done,

                    onSubmitted: (_) {
                      if (!_loading) {
                        _login();
                      }
                    },

                    decoration:
                    InputDecoration(
                      labelText:
                      'Password',

                      prefixIcon:
                      const Icon(
                        Icons.lock_outline,
                      ),

                      border:
                      const OutlineInputBorder(),

                      suffixIcon:
                      IconButton(
                        tooltip:
                        _obscurePassword
                            ? 'Show password'
                            : 'Hide password',

                        onPressed: () {
                          setState(() {
                            _obscurePassword =
                            !_obscurePassword;
                          });
                        },

                        icon: Icon(
                          _obscurePassword
                              ? Icons
                              .visibility_outlined
                              : Icons
                              .visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ------------------------------------------------
                  // LOGIN
                  // ------------------------------------------------

                  SizedBox(
                    width:
                    double.infinity,

                    height: 48,

                    child: FilledButton(
                      onPressed:
                      _loading
                          ? null
                          : _login,

                      child: _loading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                          Colors.white,
                        ),
                      )
                          : const Text(
                        'Login',
                        style:
                        TextStyle(
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  // ------------------------------------------------
                  // CHANGE PASSWORD
                  // ------------------------------------------------

                  TextButton.icon(
                    onPressed:
                    _loading
                        ? null
                        : _showChangePasswordDialog,

                    icon:
                    const Icon(
                      Icons
                          .lock_reset_outlined,
                      size: 18,
                    ),

                    label:
                    const Text(
                      'Change Password',
                      style:
                      TextStyle(
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}