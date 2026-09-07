import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/auth/auth_identity.dart';
import '../../services/email_otp_service.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<AuthIdentity?> watchIdentity() => _auth.authStateChanges().map(_identityFromUser);

  @override
  Future<void> requestPhoneOtp({required String phoneNumber, required void Function(String verificationId) onCodeSent}) async {
    final completion = Completer<void>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
        if (!completion.isCompleted) completion.complete();
      },
      verificationFailed: (error) {
        if (!completion.isCompleted) completion.completeError(error);
      },
      codeSent: (verificationId, _) {
        onCodeSent(verificationId);
        if (!completion.isCompleted) completion.complete();
      },
      codeAutoRetrievalTimeout: (_) {},
    );
    await completion.future;
  }

  @override
  Future<AuthIdentity> confirmPhoneOtp({required String verificationId, required String smsCode}) async {
    try {
      final credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
      final user = (await _auth.signInWithCredential(credential)).user;
      if (user == null) throw StateError('Firebase did not return an authenticated user.');
      await _syncUserProfile(user, null);
      return _identityFromUser(user)!;
    } on FirebaseAuthException catch (e) {
      throw StateError(_friendlyAuthMessage(e));
    }
  }

  @override
  Future<AuthIdentity> signInWithEmail({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      final user = credential.user;
      if (user == null) throw StateError('Sign in failed: no user returned.');
      await _syncUserProfile(user, null);
      return _identityFromUser(user)!;
    } on FirebaseAuthException catch (e) {
      throw StateError(_friendlyAuthMessage(e));
    }
  }

  @override
  Future<AuthIdentity> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      final user = credential.user;
      if (user == null) throw StateError('Registration failed: no user returned.');
      final cleanName = displayName.trim();
      if (cleanName.isNotEmpty) {
        await user.updateDisplayName(cleanName);
      }
      try {
        await user.sendEmailVerification();
      } catch (verificationError) {
        // Continue even if verification email delivery fails due to rate-limit
      }
      await _syncUserProfile(user, cleanName);
      return _identityFromUser(user)!;
    } on FirebaseAuthException catch (e) {
      throw StateError(_friendlyAuthMessage(e));
    }
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw StateError(_friendlyAuthMessage(e));
    }
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
      throw StateError('Invalid or expired verification code.');
    }

    User? user = _auth.currentUser;
    if (user == null) {
      try {
        final result = await _auth.signInAnonymously();
        user = result.user;
      } catch (_) {}
    }

    final name = displayName != null && displayName.trim().isNotEmpty
        ? displayName.trim()
        : email.split('@').first;
    if (user != null && displayName != null && displayName.trim().isNotEmpty) {
      await user.updateDisplayName(displayName.trim());
    }

    final identity = AuthIdentity(
      uid: user?.uid ?? 'artisan-${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
      email: email.trim().toLowerCase(),
      displayName: name,
      phoneNumber: user?.phoneNumber ?? '',
    );
    if (user != null) {
      await _syncUserProfile(user, name);
    }
    return identity;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<void> _syncUserProfile(User user, String? optionalName) async {
    try {
      final name = optionalName ?? user.displayName ?? user.email?.split('@').first ?? 'User';
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': name,
        'phoneNumber': user.phoneNumber ?? '',
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Non-blocking sync
    }
  }

  static String _friendlyAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account registered with this email. Please click "Create Account".';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please verify and try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Please sign in instead.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes before trying again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication failed. Please check your credentials.';
    }
  }

  AuthIdentity? _identityFromUser(User? user) => user == null
      ? null
      : AuthIdentity(
          uid: user.uid,
          phoneNumber: user.phoneNumber,
          email: user.email,
          displayName: user.displayName,
        );
}
