import 'package:flutter/material.dart';

import '../services/admin_auth_service.dart';
import '../services/admin_session.dart';

/// Wraps any /ARR/admin/* screen. If the admin area has not been
/// unlocked yet, this shows a password gate instead of the
/// requested screen. Once unlocked, the session persists across a
/// page reload (mirrors DccGuard) — it only asks again after 30
/// minutes of no activity anywhere in the app (see
/// SessionActivity), or after an explicit logout.
class AdminGuard extends StatefulWidget {
  final Widget child;

  const AdminGuard({super.key, required this.child});

  @override
  State<AdminGuard> createState() => _AdminGuardState();
}

class _AdminGuardState extends State<AdminGuard> {
  late bool _unlocked = AdminSession.isUnlocked;

  void _onUnlocked() {
    setState(() {
      _unlocked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) {
      return widget.child;
    }

    return AdminPasswordGateScreen(onUnlocked: _onUnlocked);
  }
}

class AdminPasswordGateScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const AdminPasswordGateScreen({
    super.key,
    required this.onUnlocked,
  });

  @override
  State<AdminPasswordGateScreen> createState() =>
      _AdminPasswordGateScreenState();
}

class _AdminPasswordGateScreenState
    extends State<AdminPasswordGateScreen> {
  final _controller = TextEditingController();

  bool _obscure = true;
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.isEmpty || _checking) {
      return;
    }

    setState(() {
      _checking = true;
      _error = null;
    });

    try {
      final ok = await AdminAuthService.verifyPassword(_controller.text);

      if (!mounted) return;

      if (ok) {
        AdminSession.unlock();
        widget.onUnlocked();
      } else {
        setState(() {
          _checking = false;
          _error = "Incorrect admin password.";
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _checking = false;
        _error = "Could not verify password. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 22,
                    color: Color(0xFF3155C6),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Admin Access",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202124),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Enter your administrator password to continue.",
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF747982),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  "Administrator Password",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3F4349),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  obscureText: _obscure,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: "Enter password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscure = !_obscure;
                        });
                      },
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFD94A4A),
                      fontSize: 12.5,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/',
                            (route) => false,
                          );
                        },
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _checking ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3155C6),
                          foregroundColor: Colors.white,
                        ),
                        child: _checking
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text("Unlock"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
