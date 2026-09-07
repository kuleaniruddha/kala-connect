import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/kala_theme.dart';

/// The primary zero-literacy action. Pulsing rings convey that the app is
/// listening even before any spoken language is selected.
class MagneticVoiceButton extends StatefulWidget {
  const MagneticVoiceButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  State<MagneticVoiceButton> createState() => _MagneticVoiceButtonState();
}

class _MagneticVoiceButtonState extends State<MagneticVoiceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final wave = (math.sin(_controller.value * math.pi * 2) + 1) / 2;
        return Transform.scale(
          scale: 1 + wave * .055,
          child: Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: <Color>[Color(0xFFFFE889), KalaColors.turmeric, Color(0xFFFF9E38)],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(color: KalaColors.turmeric.withValues(alpha: .54), blurRadius: 20 + wave * 19, spreadRadius: 3 + wave * 7),
                const BoxShadow(color: Color(0x3D5B2700), offset: Offset(0, 11), blurRadius: 18),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onPressed,
                child: const Icon(Icons.mic_rounded, color: KalaColors.ink, size: 51),
              ),
            ),
          ),
        );
      },
    );
  }
}
