import 'package:flutter/material.dart';

import '../../services/ncr/ncr_auth_service.dart';
import '../../services/ncr/ncr_session.dart';

class NcrLoginScreen extends StatefulWidget {
  const NcrLoginScreen({super.key});

  @override
  State<NcrLoginScreen> createState() =>
      _NcrLoginScreenState();
}

class _NcrLoginScreenState
    extends State<NcrLoginScreen> {
  final _emailController =
  TextEditingController();

  final _passwordController =
  TextEditingController();

  final _formKey =
  GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;

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
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user =
      await NcrAuthService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Welcome ${user.fullName}',
          ),
          backgroundColor:
          Colors.green,
        ),
      );

      // ========================================================
      // ROLE BASED DASHBOARD
      // ========================================================

      final role =
      user.roleKey.trim().toLowerCase();

      String route;

      switch (role) {
        case 'admin':
          route = '/NCR/admin-dashboard';
          break;

        case 'user':
          route = '/NCR/user-dashboard';
          break;

        case 'hod':
          route = '/NCR/hod-dashboard';
          break;

        case 'dcc':
          route = '/NCR/dcc-dashboard';
          break;

        default:
          await NcrAuthService.logout();

          throw Exception(
            'Unsupported NCR role: ${user.roleName.isEmpty ? user.roleKey : user.roleName}',
          );
      }

      Navigator.pushReplacementNamed(
        context,
        route,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      final message = e
          .toString()
          .replaceFirst(
        'Exception: ',
        '',
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
          Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  Future<void> _showChangePasswordDialog() async {
    final emailController =
    TextEditingController(
      text: _emailController.text.trim(),
    );

    final currentPasswordController =
    TextEditingController();

    final newPasswordController =
    TextEditingController();

    final confirmPasswordController =
    TextEditingController();

    final formKey =
    GlobalKey<FormState>();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool saving = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (
                context,
                setDialogState,
                ) {
              Future<void> changePassword() async {
                if (!formKey.currentState!
                    .validate()) {
                  return;
                }

                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  )
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'New password and confirmation do not match.',
                      ),
                      backgroundColor:
                      Colors.red,
                    ),
                  );

                  return;
                }

                setDialogState(() {
                  saving = true;
                });

                try {
                  await NcrAuthService
                      .changePasswordFromLogin(
                    email:
                    emailController.text,
                    currentPassword:
                    currentPasswordController
                        .text,
                    newPassword:
                    newPasswordController.text,
                  );

                  if (!dialogContext.mounted) {
                    return;
                  }

                  Navigator.pop(
                    dialogContext,
                  );

                  _emailController.text =
                      emailController.text
                          .trim();

                  ScaffoldMessenger.of(
                    context,
                  )
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Password changed successfully. Please login with your new password.',
                      ),
                      backgroundColor:
                      Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!dialogContext.mounted) {
                    return;
                  }

                  setDialogState(() {
                    saving = false;
                  });

                  ScaffoldMessenger.of(
                    dialogContext,
                  )
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        e
                            .toString()
                            .replaceFirst(
                          'Exception: ',
                          '',
                        ),
                      ),
                      backgroundColor:
                      Colors.red,
                    ),
                  );
                }
              }

              return AlertDialog(
                title: const Row(
                  children: [
                    Icon(
                      Icons.lock_reset_outlined,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Change Password',
                    ),
                  ],
                ),

                content: SizedBox(
                  width: 480,
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize:
                        MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller:
                            emailController,
                            enabled: !saving,
                            keyboardType:
                            TextInputType
                                .emailAddress,
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
                            validator:
                                (value) {
                              final email =
                                  value?.trim() ??
                                      '';

                              if (email.isEmpty) {
                                return 'Email is required.';
                              }

                              if (!email
                                  .contains('@')) {
                                return 'Enter a valid email address.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          TextFormField(
                            controller:
                            currentPasswordController,
                            enabled: !saving,
                            obscureText:
                            obscureCurrent,
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
                                onPressed:
                                saving
                                    ? null
                                    : () {
                                  setDialogState(
                                        () {
                                      obscureCurrent =
                                      !obscureCurrent;
                                    },
                                  );
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
                            validator:
                                (value) {
                              if (value == null ||
                                  value.isEmpty) {
                                return 'Current password is required.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          TextFormField(
                            controller:
                            newPasswordController,
                            enabled: !saving,
                            obscureText:
                            obscureNew,
                            decoration:
                            InputDecoration(
                              labelText:
                              'New Password',
                              helperText:
                              'Minimum 8 characters',
                              prefixIcon:
                              const Icon(
                                Icons
                                    .lock_reset_outlined,
                              ),
                              suffixIcon:
                              IconButton(
                                onPressed:
                                saving
                                    ? null
                                    : () {
                                  setDialogState(
                                        () {
                                      obscureNew =
                                      !obscureNew;
                                    },
                                  );
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
                            validator:
                                (value) {
                              if (value == null ||
                                  value.isEmpty) {
                                return 'New password is required.';
                              }

                              if (value.length <
                                  8) {
                                return 'Password must contain at least 8 characters.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          TextFormField(
                            controller:
                            confirmPasswordController,
                            enabled: !saving,
                            obscureText:
                            obscureConfirm,
                            decoration:
                            InputDecoration(
                              labelText:
                              'Confirm New Password',
                              prefixIcon:
                              const Icon(
                                Icons
                                    .check_circle_outline,
                              ),
                              suffixIcon:
                              IconButton(
                                onPressed:
                                saving
                                    ? null
                                    : () {
                                  setDialogState(
                                        () {
                                      obscureConfirm =
                                      !obscureConfirm;
                                    },
                                  );
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
                            validator:
                                (value) {
                              if (value == null ||
                                  value.isEmpty) {
                                return 'Please confirm the new password.';
                              }

                              if (value !=
                                  newPasswordController
                                      .text) {
                                return 'Passwords do not match.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          Container(
                            width:
                            double.infinity,
                            padding:
                            const EdgeInsets
                                .all(
                              12,
                            ),
                            decoration:
                            BoxDecoration(
                              color:
                              Colors.blue.shade50,
                              borderRadius:
                              BorderRadius
                                  .circular(
                                8,
                              ),
                            ),
                            child:
                            const Row(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Icon(
                                  Icons
                                      .security_outlined,
                                  size: 19,
                                  color:
                                  Color(
                                    0xFF3155D9,
                                  ),
                                ),
                                SizedBox(
                                  width: 8,
                                ),
                                Expanded(
                                  child: Text(
                                    'Your current password is verified before the new password is saved.',
                                    style:
                                    TextStyle(
                                      fontSize:
                                      12,
                                      height:
                                      1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

                  FilledButton.icon(
                    onPressed:
                    saving
                        ? null
                        : changePassword,
                    icon: saving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                        Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons
                          .lock_reset,
                    ),
                    label: Text(
                      saving
                          ? 'Changing...'
                          : 'Change Password',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      emailController.dispose();
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FA),

      body: Center(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 450,
            ),
            child: Card(
              elevation: 8,
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  18,
                ),
              ),
              child: Padding(
                padding:
                const EdgeInsets.all(
                  32,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration:
                        BoxDecoration(
                          color:
                          Colors.blue.shade50,
                          shape:
                          BoxShape.circle,
                        ),
                        child: Icon(
                          Icons
                              .assignment_late_outlined,
                          size: 42,
                          color:
                          Colors.blue.shade700,
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      const Text(
                        'NCR Management',
                        style:
                        TextStyle(
                          fontSize: 28,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        'Non-Conformance Report',
                        style:
                        TextStyle(
                          fontSize: 15,
                          color:
                          Colors.grey
                              .shade600,
                        ),
                      ),

                      const SizedBox(
                        height: 30,
                      ),

                      TextFormField(
                        controller:
                        _emailController,
                        keyboardType:
                        TextInputType
                            .emailAddress,
                        textInputAction:
                        TextInputAction
                            .next,
                        enabled:
                        !_isLoading,
                        decoration:
                        InputDecoration(
                          labelText: 'Email',
                          hintText:
                          'Enter your NCR email',
                          prefixIcon:
                          const Icon(
                            Icons
                                .email_outlined,
                          ),
                          border:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              10,
                            ),
                          ),
                        ),
                        validator:
                            (value) {
                          final email =
                              value?.trim() ??
                                  '';

                          if (email.isEmpty) {
                            return 'Email is required';
                          }

                          if (!email
                              .contains('@')) {
                            return 'Enter a valid email address';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      TextFormField(
                        controller:
                        _passwordController,
                        obscureText:
                        _obscurePassword,
                        enabled:
                        !_isLoading,
                        textInputAction:
                        TextInputAction
                            .done,
                        onFieldSubmitted:
                            (_) => _login(),
                        decoration:
                        InputDecoration(
                          labelText:
                          'Password',
                          hintText:
                          'Enter your password',
                          prefixIcon:
                          const Icon(
                            Icons
                                .lock_outline,
                          ),
                          suffixIcon:
                          IconButton(
                            onPressed:
                            _isLoading
                                ? null
                                : () {
                              setState(
                                    () {
                                  _obscurePassword =
                                  !_obscurePassword;
                                },
                              );
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons
                                  .visibility_outlined
                                  : Icons
                                  .visibility_off_outlined,
                            ),
                          ),
                          border:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              10,
                            ),
                          ),
                        ),
                        validator:
                            (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return 'Password is required';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 28,
                      ),

                      SizedBox(
                        width:
                        double.infinity,
                        height: 52,
                        child:
                        ElevatedButton(
                          onPressed:
                          _isLoading
                              ? null
                              : _login,
                          style:
                          ElevatedButton
                              .styleFrom(
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                10,
                              ),
                            ),
                          ),
                          child:
                          _isLoading
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                            CircularProgressIndicator(
                              strokeWidth:
                              2.5,
                            ),
                          )
                              : const Text(
                            'LOGIN',
                            style:
                            TextStyle(
                              fontSize:
                              16,
                              fontWeight:
                              FontWeight
                                  .bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ==================================================
                      // CHANGE PASSWORD
                      // ==================================================

                      SizedBox(
                        width:
                        double.infinity,
                        child:
                        OutlinedButton
                            .icon(
                          onPressed:
                          _isLoading
                              ? null
                              : _showChangePasswordDialog,
                          icon:
                          const Icon(
                            Icons
                                .lock_reset_outlined,
                          ),
                          label:
                          const Text(
                            'CHANGE PASSWORD',
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      Text(
                        'Use your NCR account credentials to continue.',
                        textAlign:
                        TextAlign.center,
                        style:
                        TextStyle(
                          fontSize: 12,
                          color:
                          Colors.grey
                              .shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}