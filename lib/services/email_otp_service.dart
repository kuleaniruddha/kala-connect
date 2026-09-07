import 'dart:math';
import 'package:flutter/foundation.dart';

class EmailOtpDeliveryResult {
  const EmailOtpDeliveryResult({
    required this.success,
    required this.otpCode,
    required this.message,
    this.secondsRemaining = 60,
  });

  final bool success;
  final String otpCode;
  final String message;
  final int secondsRemaining;
}

class EmailOtpService {
  static final EmailOtpService _instance = EmailOtpService._internal();
  factory EmailOtpService() => _instance;
  EmailOtpService._internal();

  final Map<String, _ActiveOtp> _activeOtps = {};

  /// Sends a 6-digit verification code to the target email.
  Future<EmailOtpDeliveryResult> sendOtp(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      return const EmailOtpDeliveryResult(
        success: false,
        otpCode: '',
        message: 'Please enter a valid email address.',
      );
    }

    final now = DateTime.now();
    final existing = _activeOtps[cleanEmail];

    // 60-second cooldown on resends
    if (existing != null && now.difference(existing.generatedAt).inSeconds < 60) {
      final waitSeconds = 60 - now.difference(existing.generatedAt).inSeconds;
      return EmailOtpDeliveryResult(
        success: false,
        otpCode: existing.code,
        message: 'Please wait $waitSeconds seconds before requesting another code.',
        secondsRemaining: waitSeconds,
      );
    }

    // Generate secure 6-digit random OTP
    final rng = Random.secure();
    final code = (100000 + rng.nextInt(900000)).toString();

    _activeOtps[cleanEmail] = _ActiveOtp(
      email: cleanEmail,
      code: code,
      generatedAt: now,
      expiresAt: now.add(const Duration(minutes: 5)),
    );

    debugPrint('📧 [EmailOtpService] Verification OTP for $cleanEmail: $code');

    // Simulate network delivery
    await Future<void>.delayed(const Duration(milliseconds: 400));

    return EmailOtpDeliveryResult(
      success: true,
      otpCode: code,
      message: 'Verification code sent to $cleanEmail',
      secondsRemaining: 60,
    );
  }

  /// Verifies entered 6-digit OTP against the recorded code.
  bool verifyOtp({required String email, required String enteredOtp}) {
    final cleanEmail = email.trim().toLowerCase();
    final cleanCode = enteredOtp.trim().replaceAll(' ', '');

    final active = _activeOtps[cleanEmail];
    if (active == null) return false;

    if (DateTime.now().isAfter(active.expiresAt)) {
      _activeOtps.remove(cleanEmail);
      return false;
    }

    if (active.code == cleanCode) {
      _activeOtps.remove(cleanEmail);
      return true;
    }

    return false;
  }

  /// Get remaining cooldown seconds for UI countdown.
  int getCooldownSeconds(String email) {
    final cleanEmail = email.trim().toLowerCase();
    final existing = _activeOtps[cleanEmail];
    if (existing == null) return 0;
    final diff = 60 - DateTime.now().difference(existing.generatedAt).inSeconds;
    return diff > 0 ? diff : 0;
  }
}

class _ActiveOtp {
  const _ActiveOtp({
    required this.email,
    required this.code,
    required this.generatedAt,
    required this.expiresAt,
  });

  final String email;
  final String code;
  final DateTime generatedAt;
  final DateTime expiresAt;
}
