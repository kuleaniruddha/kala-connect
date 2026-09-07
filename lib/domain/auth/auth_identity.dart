class AuthIdentity {
  const AuthIdentity({
    required this.uid,
    this.phoneNumber,
    this.email,
    this.displayName,
    this.isDemo = false,
  });

  final String uid;
  final String? phoneNumber;
  final String? email;
  final String? displayName;
  final bool isDemo;
}
