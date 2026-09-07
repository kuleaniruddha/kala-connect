import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/auth/auth_repository.dart';
import '../domain/auth/auth_identity.dart';

enum AuthPhase { loading, signedOut, sendingCode, codeSent, signedIn, error }

class AuthController extends ChangeNotifier {
  AuthController(this._repository);
  final AuthRepository _repository;
  StreamSubscription<AuthIdentity?>? _subscription;
  AuthPhase _phase = AuthPhase.loading;
  AuthIdentity? _identity;
  String? _verificationId;
  String? _message;

  AuthPhase get phase => _phase;
  AuthIdentity? get identity => _identity;
  String? get message => _message;
  bool get isSignedIn => _identity != null;

  void start() {
    _subscription = _repository.watchIdentity().listen((identity) {
      _identity = identity;
      _phase = identity == null ? AuthPhase.signedOut : AuthPhase.signedIn;
      notifyListeners();
    }, onError: (Object error) {
      _phase = AuthPhase.error;
      _message = error.toString();
      notifyListeners();
    });
  }

  Future<void> requestOtp(String phoneNumber) async {
    _phase = AuthPhase.sendingCode;
    _message = null;
    notifyListeners();
    try {
      await _repository.requestPhoneOtp(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) => _verificationId = verificationId,
      );
      if (_identity == null) _phase = AuthPhase.codeSent;
    } catch (error) {
      _phase = AuthPhase.error;
      _message = error.toString();
    }
    notifyListeners();
  }

  Future<void> confirmOtp(String code) async {
    final verificationId = _verificationId;
    if (verificationId == null) return;
    _phase = AuthPhase.sendingCode;
    notifyListeners();
    try {
      _identity = await _repository.confirmPhoneOtp(verificationId: verificationId, smsCode: code);
      _phase = AuthPhase.signedIn;
    } catch (error) {
      _phase = AuthPhase.error;
      _message = error.toString();
    }
    notifyListeners();
  }

  Future<void> signInWithEmail({required String email, required String password}) async {
    _phase = AuthPhase.loading;
    _message = null;
    notifyListeners();
    try {
      _identity = await _repository.signInWithEmail(email: email, password: password);
      _phase = AuthPhase.signedIn;
    } catch (error) {
      _phase = AuthPhase.error;
      _message = error.toString().replaceAll('Exception: ', '').replaceAll('StateError: ', '');
    }
    notifyListeners();
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _phase = AuthPhase.loading;
    _message = null;
    notifyListeners();
    try {
      _identity = await _repository.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      _phase = AuthPhase.signedIn;
    } catch (error) {
      _phase = AuthPhase.error;
      _message = error.toString().replaceAll('Exception: ', '').replaceAll('StateError: ', '');
    }
    notifyListeners();
  }

  Future<String?> sendEmailOtp(String email) async {
    _phase = AuthPhase.sendingCode;
    _message = null;
    notifyListeners();
    try {
      final code = await _repository.sendEmailOtp(email: email);
      _phase = AuthPhase.codeSent;
      notifyListeners();
      return code;
    } catch (error) {
      _phase = AuthPhase.error;
      _message = error.toString().replaceAll('Exception: ', '').replaceAll('StateError: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> verifyEmailOtp({
    required String email,
    required String otpCode,
    String? displayName,
  }) async {
    _phase = AuthPhase.loading;
    _message = null;
    notifyListeners();
    try {
      _identity = await _repository.verifyEmailOtp(
        email: email,
        otpCode: otpCode,
        displayName: displayName,
      );
      _phase = AuthPhase.signedIn;
      notifyListeners();
      return true;
    } catch (error) {
      _phase = AuthPhase.error;
      _message = error.toString().replaceAll('Exception: ', '').replaceAll('StateError: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _phase = AuthPhase.loading;
    _message = null;
    notifyListeners();
    try {
      await _repository.sendPasswordReset(email: email.trim());
      _phase = AuthPhase.signedOut;
      notifyListeners();
      return true;
    } catch (error) {
      _phase = AuthPhase.error;
      _message = error.toString().replaceAll('Exception: ', '').replaceAll('StateError: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _identity = null;
    _phase = AuthPhase.signedOut;
    notifyListeners();
  }

  @override
  void dispose() { _subscription?.cancel(); super.dispose(); }
}
