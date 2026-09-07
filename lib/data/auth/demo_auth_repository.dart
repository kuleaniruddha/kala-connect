import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/auth/auth_identity.dart';
import '../../services/email_otp_service.dart';
import 'auth_repository.dart';

/// Keeps the visual prototype runnable before Firebase configuration exists.
class DemoAuthRepository implements AuthRepository {
  static const _sessionKey = 'demo_auth_session';
  final StreamController<AuthIdentity?> _controller = StreamController<AuthIdentity?>.broadcast();
  AuthIdentity? _current;

  @override
  Stream<AuthIdentity?> watchIdentity() async* {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_sessionKey) ?? false) {
      final savedUid = preferences.getString('demo_auth_uid') ?? 'user-${DateTime.now().millisecondsSinceEpoch}';
      final savedEmail = preferences.getString('demo_auth_email') ?? '';
      final savedName = preferences.getString('demo_auth_name') ?? 'User';
      _current = AuthIdentity(
        uid: savedUid,
        email: savedEmail,
        displayName: savedName,
        phoneNumber: '',
        isDemo: true,
      );
    }
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<void> requestPhoneOtp({required String phoneNumber, required void Function(String verificationId) onCodeSent}) async {
    onCodeSent('demo-verification');
  }

  @override
  Future<AuthIdentity> confirmPhoneOtp({required String verificationId, required String smsCode}) async {
    _current = AuthIdentity(
      uid: 'artisan-${DateTime.now().millisecondsSinceEpoch}',
      phoneNumber: '',
      email: '',
      displayName: 'Artisan',
      isDemo: true,
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_sessionKey, true);
    await preferences.setString('demo_auth_uid', _current!.uid);
    await preferences.setString('demo_auth_email', _current!.email ?? '');
    await preferences.setString('demo_auth_name', _current!.displayName ?? 'Artisan');
    _controller.add(_current);
    return _current!;
  }

  @override
  Future<AuthIdentity> signInWithEmail({required String email, required String password}) async {
    if (password.length < 6) {
      throw StateError('Password must be at least 6 characters long.');
    }
    final uid = 'user-${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    final name = email.split('@').first;
    _current = AuthIdentity(
      uid: uid,
      email: email,
      displayName: name[0].toUpperCase() + name.substring(1),
      isDemo: true,
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_sessionKey, true);
    await preferences.setString('demo_auth_uid', _current!.uid);
    await preferences.setString('demo_auth_email', _current!.email!);
    await preferences.setString('demo_auth_name', _current!.displayName!);
    _controller.add(_current);
    return _current!;
  }

  @override
  Future<AuthIdentity> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (password.length < 6) {
      throw StateError('Password must be at least 6 characters long.');
    }
    final uid = 'artisan-${DateTime.now().millisecondsSinceEpoch}';
    _current = AuthIdentity(
      uid: uid,
      email: email,
      displayName: displayName.trim().isEmpty ? 'Artisan' : displayName.trim(),
      isDemo: true,
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_sessionKey, true);
    await preferences.setString('demo_auth_uid', _current!.uid);
    await preferences.setString('demo_auth_email', _current!.email!);
    await preferences.setString('demo_auth_name', _current!.displayName!);
    _controller.add(_current);
    return _current!;
  }

  @override
  Future<String> sendEmailOtp({required String email}) async {
    final result = await EmailOtpService().sendOtp(email);
    if (!result.success && result.secondsRemaining > 0) {
      throw StateError(result.message);
    }
    return result.otpCode;
  }

  @override
  Future<AuthIdentity> verifyEmailOtp({
    required String email,
    required String otpCode,
    String? displayName,
  }) async {
    final isValid = EmailOtpService().verifyOtp(email: email, enteredOtp: otpCode);
    if (!isValid) {
      throw StateError('Invalid or expired verification code. Please check and try again.');
    }

    final name = displayName != null && displayName.trim().isNotEmpty
        ? displayName.trim()
        : email.split('@').first;
    final formattedName = name[0].toUpperCase() + (name.length > 1 ? name.substring(1) : '');

    _current = AuthIdentity(
      uid: 'artisan-${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
      email: email.trim().toLowerCase(),
      displayName: formattedName,
      phoneNumber: '+919876543210',
      isDemo: true,
    );

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_sessionKey, true);
    await preferences.setString('demo_auth_uid', _current!.uid);
    await preferences.setString('demo_auth_email', _current!.email!);
    await preferences.setString('demo_auth_name', _current!.displayName!);
    _controller.add(_current);
    return _current!;
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    // Demo implementation
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> signOut() async {
    _current = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionKey);
    await preferences.remove('demo_auth_uid');
    await preferences.remove('demo_auth_email');
    await preferences.remove('demo_auth_name');
    _controller.add(null);
  }
}

