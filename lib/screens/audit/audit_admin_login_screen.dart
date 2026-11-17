import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/audit/audit_admin_session.dart';

class AuditAdminLoginScreen extends StatefulWidget {
  const AuditAdminLoginScreen({super.key});

  @override
  State<AuditAdminLoginScreen> createState() =>
      _AuditAdminLoginScreenState();
}

class _AuditAdminLoginScreenState
    extends State<AuditAdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _checkingExistingSession = true;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    await AuditAdminSession.restoreSession();

    if (!mounted) {
      return;
    }

    if (AuditAdminSession.isLoggedIn) {
      final routeArguments =
          ModalRoute.of(context)?.settings.arguments;

      String redirectTo = '/AUDIT/admin';

      if (routeArguments is Map) {
        final requestedRoute =
        routeArguments['redirectTo']
            ?.toString()
            .trim();

        if (requestedRoute != null &&
            requestedRoute.isNotEmpty) {
          redirectTo = requestedRoute;
        }
      }

      final existingSessionToken =
          AuditAdminSession.sessionToken;

      if (existingSessionToken == null ||
          existingSessionToken.isEmpty) {
        await AuditAdminSession.logout();

        if (!mounted) {
          return;
        }

        setState(() {
          _checkingExistingSession = false;
        });

        return;
      }

      AuditAdminSession.touch();

      Navigator.pushReplacementNamed(
        context,
        redirectTo,
        arguments: {
          'email': AuditAdminSession.email,
          'sessionToken': existingSessionToken,
        },
      );

      return;
    }

    setState(() {
      _checkingExistingSession = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
    });

    try {
      final result =
      await SupabaseService.verifyAuditAdminLogin(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      if (result['success'] == true) {
        final sessionToken =
        result['session_token']?.toString();

        if (sessionToken == null || sessionToken.isEmpty) {
          throw Exception(
            'Admin login succeeded but no session was returned.',
          );
        }

        await AuditAdminSession.login(
          email: _emailController.text.trim(),
          sessionToken: sessionToken,
        );
        final routeArguments =
            ModalRoute.of(context)?.settings.arguments;

        String redirectTo =
            '/AUDIT/admin';

        if (routeArguments is Map) {
          final requestedRoute =
          routeArguments['redirectTo']
              ?.toString()
              .trim();

          if (requestedRoute != null &&
              requestedRoute.isNotEmpty) {
            redirectTo = requestedRoute;
          }
        }

        Navigator.pushReplacementNamed(
          context,
          redirectTo,
          arguments: {
            'adminId':
            result['admin_id']?.toString(),
            'email':
            result['email']?.toString(),
            'sessionToken':
            sessionToken,
          },
        );

        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                'Invalid admin email or password.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Admin login failed: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Login'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 460,
            ),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings,
                        size: 64,
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Audit Administration',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Sign in to manage Audit Types, Categories and Questions.',
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 28),

                      TextFormField(
                        controller: _emailController,
                        keyboardType:
                        TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Admin Mail',
                          prefixIcon:
                          Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final email =
                              value?.trim() ?? '';

                          if (email.isEmpty) {
                            return 'Enter admin mail.';
                          }

                          if (!email.contains('@')) {
                            return 'Enter a valid email address.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon:
                          const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons
                                  .visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword =
                                !_obscurePassword;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return 'Enter password.';
                          }

                          return null;
                        },
                        onFieldSubmitted: (_) {
                          if (!_loading) {
                            _login();
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed:
                          _loading ? null : _login,
                          child: _loading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                            CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: _loading
                            ? null
                            : () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Back to Audit Dashboard',
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