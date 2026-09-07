import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';
import '../../state/locale_controller.dart';
import '../../state/voice_controller.dart';
import '../../theme/kala_theme.dart';

class EmailAuthDialog extends StatefulWidget {
  const EmailAuthDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EmailAuthDialog(),
    );
    return result ?? false;
  }

  @override
  State<EmailAuthDialog> createState() => _EmailAuthDialogState();
}

class _EmailAuthDialogState extends State<EmailAuthDialog> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _voiceTargetField;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _errorMessage = null);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startVoiceInput(String fieldName) {
    setState(() => _voiceTargetField = fieldName);
    final voice = context.read<VoiceController>();
    voice.toggleListening();

    void listener() {
      if (!mounted) return;
      final transcript = voice.lastTranscript;
      if (transcript.isNotEmpty) {
        setState(() {
          if (_voiceTargetField == 'name') {
            _nameController.text = transcript;
          } else if (_voiceTargetField == 'email') {
            final cleaned = transcript
                .toLowerCase()
                .replaceAll(' at the rate ', '@')
                .replaceAll(' at ', '@')
                .replaceAll(' dot ', '.')
                .replaceAll(' ', '');
            _emailController.text = cleaned;
          }
        });
      }
    }

    voice.addListener(listener);
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthController>();
    await auth.signInWithEmail(email: email, password: password);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (auth.isSignedIn) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome back, ${auth.identity?.displayName ?? "Artisan"}!'),
          backgroundColor: KalaColors.leaf,
        ),
      );
    } else if (auth.message != null) {
      setState(() => _errorMessage = auth.message);
    }
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your full name.');
      return;
    }
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters long.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthController>();
    await auth.signUpWithEmail(
      email: email,
      password: password,
      displayName: name,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (auth.isSignedIn) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created! Verification email sent to $email. Welcome, $name!'),
          backgroundColor: KalaColors.leaf,
          duration: const Duration(seconds: 4),
        ),
      );
    } else if (auth.message != null) {
      setState(() => _errorMessage = auth.message);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final loc = context.read<LocaleController>();
    final resetController = TextEditingController(text: _emailController.text.trim());
    String? resetError;
    bool isSending = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.lock_reset_rounded, color: KalaColors.terracotta, size: 26),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(loc.tr('reset_password'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.tr('forgot_password_desc'),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B6572)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: resetController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: loc.tr('enter_email'),
                      hintText: 'name@example.com',
                      prefixIcon: const Icon(Icons.email_outlined, color: KalaColors.terracotta),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  if (resetError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      resetError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text(loc.tr('cancel')),
                ),
                FilledButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final email = resetController.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            setDialogState(() => resetError = loc.tr('enter_valid_email'));
                            return;
                          }
                          setDialogState(() {
                            isSending = true;
                            resetError = null;
                          });
                          final auth = context.read<AuthController>();
                          final success = await auth.sendPasswordReset(email);
                          if (!dialogContext.mounted) return;
                          if (success) {
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${loc.tr('reset_password_sent')} $email'),
                                backgroundColor: KalaColors.leaf,
                              ),
                            );
                          } else {
                            setDialogState(() {
                              isSending = false;
                              resetError = auth.message ?? loc.tr('reset_password_failed');
                            });
                          }
                        },
                  style: FilledButton.styleFrom(backgroundColor: KalaColors.terracotta),
                  child: isSending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(loc.tr('send_reset_link')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isSignIn = _tabController.index == 0;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutQuad,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Header
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: KalaColors.terracotta.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: KalaColors.terracotta,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'कला-Connect Account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: KalaColors.ink,
                            ),
                          ),
                          Text(
                            'Sign in to manage crafts and orders',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Tab Bar
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: KalaColors.terracotta,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade700,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Sign In'),
                      Tab(text: 'Create Account'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Error Banner if present
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Full Name field (Create Account only)
                if (!isSignIn) ...[
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name / कारीगर का नाम',
                    hint: 'Enter your name',
                    icon: Icons.person_outline_rounded,
                    onVoiceTap: () => _startVoiceInput('name'),
                  ),
                  const SizedBox(height: 12),
                ],

                // Email field
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address / ईमेल',
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.alternate_email_rounded,
                  onVoiceTap: () => _startVoiceInput('email'),
                ),
                const SizedBox(height: 12),

                // Password field
                _buildPasswordField(
                  controller: _passwordController,
                  label: 'Password / पासवर्ड',
                  hint: isSignIn ? 'Enter password' : 'At least 6 characters',
                  obscureText: _obscurePassword,
                  onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                if (isSignIn) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isSubmitting ? null : _showForgotPasswordDialog,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        context.watch<LocaleController>().tr('forgot_password'),
                        style: const TextStyle(
                          color: KalaColors.terracotta,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                ],

                // Confirm Password field (Create Account only)
                if (!isSignIn) ...[
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password / पासवर्ड दोहराएं',
                    hint: 'Re-enter password',
                    obscureText: _obscureConfirm,
                    onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 4),

                // Submit Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : (isSignIn ? _handleSignIn : _handleSignUp),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KalaColors.terracotta,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isSignIn ? 'Sign In' : 'Create Account',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 10),

                // Help footer
                Center(
                  child: Text(
                    isSignIn
                        ? "New to कला-Connect? Switch to 'Create Account'"
                        : "Already registered? Switch to 'Sign In'",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onVoiceTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: KalaColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              Icon(icon, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (onVoiceTap != null)
                IconButton(
                  icon: const Icon(Icons.mic_none_rounded, size: 18, color: KalaColors.terracotta),
                  tooltip: 'Speak to fill',
                  onPressed: onVoiceTap,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: KalaColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              Icon(Icons.lock_outline_rounded, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                onPressed: onToggleObscure,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
