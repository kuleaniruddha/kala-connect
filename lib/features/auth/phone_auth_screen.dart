import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_flow_controller.dart';
import '../../state/auth_controller.dart';
import '../../theme/kala_theme.dart';
import '../../widgets/ambient_living_canvas.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});
  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phone = TextEditingController(text: '+91');
  final _code = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final askingCode = auth.phase == AuthPhase.codeSent || (auth.phase == AuthPhase.error && _code.text.isNotEmpty);

    return Scaffold(
      body: AmbientLivingCanvas(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                IconButton(
                  onPressed: context.read<AppFlowController>().returnToLanding,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(height: 24),
                const Icon(Icons.lock_person_rounded, color: KalaColors.terracotta, size: 54),
                const SizedBox(height: 16),
                Text(
                  askingCode ? 'Enter verification code' : 'Enter mobile number',
                  style: const TextStyle(fontSize: 24, height: 1.1, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  askingCode ? 'We sent a secure OTP to your phone.' : 'We will send an OTP to verify your account.',
                  style: const TextStyle(fontSize: 14, height: 1.3, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: askingCode ? _code : _phone,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  maxLength: askingCode ? 6 : 13,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.85),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                if (auth.message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      auth.message!,
                      style: const TextStyle(color: KalaColors.terracotta, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: auth.phase == AuthPhase.sendingCode
                      ? null
                      : () => askingCode ? auth.confirmOtp(_code.text.trim()) : auth.requestOtp(_phone.text.trim()),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: KalaColors.terracotta,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    auth.phase == AuthPhase.sendingCode
                        ? 'Please wait…'
                        : askingCode
                            ? 'Verify OTP'
                            : 'Send OTP',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'Secure mobile verification • Firebase Authentication',
                    style: TextStyle(color: Color(0x885E4C38), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
