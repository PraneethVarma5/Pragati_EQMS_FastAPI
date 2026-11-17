import 'dart:convert';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class EmailService {
  EmailService._();

  static String? _currentOtp;
  static DateTime? _expiryTime;
  static int _attemptsLeft = 3;

  static int get attemptsLeft => _attemptsLeft;

  /// Generates a new OTP
  static String generateOtp() {
    _attemptsLeft = 3;

    final random = Random();

    _currentOtp =
        (100000 + random.nextInt(900000)).toString();

    _expiryTime = DateTime.now().add(
      const Duration(minutes: 5),
    );

    return _currentOtp!;
  }

  /// Verify entered OTP
  static bool verifyOtp(String enteredOtp) {
    if (_currentOtp == null || _expiryTime == null) {
      return false;
    }

    // OTP expired
    if (DateTime.now().isAfter(_expiryTime!)) {
      clearOtp();
      return false;
    }

    // Wrong OTP
    if (enteredOtp.trim() != _currentOtp) {

      _attemptsLeft--;

      if (_attemptsLeft <= 0) {

        _currentOtp = null;
        _expiryTime = null;

        _attemptsLeft = 0;

      }

      return false;

    }

    // Correct OTP
    return true;
  }

  /// Send OTP using Resend
  static Future<bool> sendOtp({
    required String toEmail,
  }) async {
    final otp = generateOtp();

    try {
      final response = await http.post(
        Uri.parse("https://api.resend.com/emails"),
        headers: {
          "Authorization":
          "Bearer ${dotenv.env['RESEND_API_KEY']}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "from": dotenv.env["FROM_EMAIL"],
          "to": [toEmail],
          "subject": "Digital ARR Password Reset OTP",
          "html": """
<h2>Digital ARR</h2>

<p>Your OTP is</p>

<h1 style="letter-spacing:4px;">$otp</h1>

<p>This OTP is valid for <b>5 minutes</b>.</p>

<p>If you didn't request this password reset, please ignore this email.</p>
""",
        }),
      );

      return response.statusCode == 200 ||
          response.statusCode == 202;
    } catch (e) {
      return false;
    }
  }

  /// Remaining OTP attempts
  static int getRemainingAttempts() {
    return _attemptsLeft;
  }

  /// OTP expiry check
  static bool isOtpExpired() {
    if (_expiryTime == null) {
      return true;
    }

    return DateTime.now().isAfter(_expiryTime!);
  }
  static int getRemainingSeconds() {

    if (_expiryTime == null) {
      return 0;
    }

    final seconds = _expiryTime!
        .difference(DateTime.now())
        .inSeconds;

    return seconds > 0 ? seconds : 0;

  }

  static bool hasOtp() {

    return _currentOtp != null;

  }

  /// Clear OTP after success/failure
  static void clearOtp() {
    _currentOtp = null;
    _expiryTime = null;
    _attemptsLeft = 3;
  }
}