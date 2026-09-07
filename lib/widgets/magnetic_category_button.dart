import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A lightweight spring-like touch response for primary navigation actions.
class MagneticCategoryButton extends StatefulWidget {
  const MagneticCategoryButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<MagneticCategoryButton> createState() => _MagneticCategoryButtonState();
}

class _MagneticCategoryButtonState extends State<MagneticCategoryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    lowerBound: 0,
    upperBound: 1,
  );
  Offset _pull = Offset.zero;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() => _pull = details.delta.scale(.33, .33));
        _controller.forward(from: 0);
      },
      onPanEnd: (_) => setState(() => _pull = Offset.zero),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final wave = math.sin(_controller.value * math.pi);
          return Transform.translate(
            offset: Offset(_pull.dx * wave, _pull.dy * wave),
            child: Transform.scale(scale: 1 + wave * .055, child: child),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .72),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: widget.color.withValues(alpha: .2), width: 1.5),
            boxShadow: <BoxShadow>[
              BoxShadow(color: widget.color.withValues(alpha: .20), offset: const Offset(0, 11), blurRadius: 18, spreadRadius: -7),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(widget.icon, size: 42, color: widget.color),
              const SizedBox(height: 8),
              Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}
