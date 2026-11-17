import 'package:flutter/material.dart';
import '../../services/dcc/dcc_user_service.dart';
import '../../models/dcc/dcc_user.dart';
import '../../services/dcc/dcc_session.dart';
import '../../models/dcc/dcc_activity.dart';
import '../../services/dcc/dcc_activity_service.dart';
class DccLoginScreen extends StatefulWidget {
  /// When set, only a login matching this exact role is accepted —
  /// any other valid account is rejected with an error instead of
  /// being logged in and sent to its own dashboard. Used when the
  /// login screen is shown in place of a role-restricted screen
  /// (e.g. Master Data, which is DCC-only).
  final String? requiredRole;

  /// When set, a successful (accepted) login navigates straight
  /// here instead of the default per-role dashboard. Used so
  /// following a link like "Master Data" while logged out lands on
  /// Master Data itself after login, not on the DCC dashboard.
  final String? redirectRoute;

  const DccLoginScreen({
    super.key,
    this.requiredRole,
    this.redirectRoute,
  });

  @override
  State<DccLoginScreen> createState() => _DccLoginScreenState();
}

class _DccLoginScreenState extends State<DccLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

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

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;


    DccUser? loggedInUser;

    try {
      loggedInUser = await DccUserService.verifyLogin(
        email: email,
        password: password,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    if (loggedInUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid email/password OR Account Not Found',
          ),
        ),
      );
      return;
    }

    // Save the server-issued session first.
    await DccSession.setUser(loggedInUser);

    if (widget.requiredRole != null &&
        loggedInUser.role.trim().toUpperCase() !=
            widget.requiredRole!.trim().toUpperCase()) {

      // The credentials were valid, but this account cannot
      // access the requested role-restricted area.
      await DccSession.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This area is only accessible to ${widget.requiredRole} accounts.',
          ),
        ),
      );
      return;
    }

    await DccActivityService.addActivity(
      DccActivity(
        id: DateTime.now()
            .microsecondsSinceEpoch
            .toString(),
        userEmail: loggedInUser.email,
        userName: loggedInUser.name,
        action: 'LOGIN',
        description: 'Logged into eQMS DCC',
        timestamp: DateTime.now(),
      ),
    );

    if (widget.redirectRoute != null) {
      Navigator.pushReplacementNamed(
        context,
        widget.redirectRoute!,
      );
      return;
    }

    if (loggedInUser.role == 'USER') {
      Navigator.pushReplacementNamed(
        context,
        '/DCC/user/dashboard',
      );
    } else if (loggedInUser.role == 'HOD') {
      Navigator.pushReplacementNamed(
        context,
        '/DCC/hod/dashboard',
      );
    } else if (loggedInUser.role == 'DCC') {
      Navigator.pushReplacementNamed(
        context,
        '/DCC/dcc/dashboard',
      );
    } else if (loggedInUser.role == 'ADMIN') {
      Navigator.pushReplacementNamed(
        context,
        '/DCC/admin/dashboard',
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 460,
              ),
              child: Container(
                padding: const EdgeInsets.all(35),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE4E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF172033),
                          ),
                          tooltip: 'Back',
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF3FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          size: 36,
                          color: Color(0xFF3155D9),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'DCC Login',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF172033),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Document Control Center',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 32),

                      const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF172033),
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE4E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE4E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF3155D9),
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }

                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF172033),
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          _login();
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE4E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE4E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF3155D9),
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3155D9),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      const SizedBox(height: 6),

                      const Text(
                        'Use the email and password provided for your eQMS account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7A8292),
                          height: 1.4,
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