import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/kala_theme.dart';

/// A low-cost painter: one controller animates a few translucent motifs rather
/// than multiple composited image layers, keeping the home view responsive.
class AmbientLivingCanvas extends StatefulWidget {
  const AmbientLivingCanvas({required this.child, super.key});

  final Widget child;

  @override
  State<AmbientLivingCanvas> createState() => _AmbientLivingCanvasState();
}

class _AmbientLivingCanvasState extends State<AmbientLivingCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 28),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.65, -0.85),
          radius: 1.35,
          colors: <Color>[Color(0xFFFFFDF8), KalaColors.warmPaper, Color(0xFFFFE5C1)],
        ),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          return CustomPaint(
            painter: _AmbientPainter(_controller.value),
            child: child,
          );
        },
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  const _AmbientPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.save();
    canvas.translate(size.width * .82, size.height * .2);
    canvas.rotate(progress * math.pi * 2);
    paint.color = KalaColors.terracotta.withValues(alpha: .11);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(Offset.zero, 42.0 + (i * 27), paint);
    }
    canvas.restore();
    canvas.save();
    canvas.translate(size.width * .14, size.height * .76);
    canvas.rotate(-progress * math.pi * 2);
    paint.color = KalaColors.indigo.withValues(alpha: .08);
    for (var i = 0; i < 5; i++) {
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 26.0 + i * 19, height: 26.0 + i * 19), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) => oldDelegate.progress != progress;
}
