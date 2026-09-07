import '../../domain/auth/auth_identity.dart';

abstract class AuthRepository {
  Stream<AuthIdentity?> watchIdentity();
  Future<void> requestPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
  });
  Future<AuthIdentity> confirmPhoneOtp({required String verificationId, required String smsCode});
  Future<AuthIdentity> signInWithEmail({required String email, required String password});
  Future<AuthIdentity> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });
  Future<String> sendEmailOtp({required String email});
  Future<AuthIdentity> verifyEmailOtp({
    required String email,
    required String otpCode,
    String? displayName,
  });
  Future<void> sendPasswordReset({required String email});
  Future<void> signOut();
}

