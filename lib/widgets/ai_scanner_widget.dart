import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/kala_theme.dart';

/// Visual camera viewfinder. A platform camera texture can be inserted into
/// [cameraPreview] without changing the animation or reticle implementation.
class AiScannerWidget extends StatefulWidget {
  const AiScannerWidget({this.cameraPreview, this.onCapture, super.key});

  final Widget? cameraPreview;
  final VoidCallback? onCapture;

  @override
  State<AiScannerWidget> createState() => _AiScannerWidgetState();
}

class _AiScannerWidgetState extends State<AiScannerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: .81,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                child!,
                CustomPaint(painter: _ReticlePainter(_controller.value)),
                Align(
                  alignment: Alignment(0, -0.76 + _controller.value * 1.52),
                  child: ShaderMask(
                    blendMode: BlendMode.srcATop,
                    shaderCallback: (rect) => const LinearGradient(
                      colors: <Color>[Colors.transparent, KalaColors.turmeric, Colors.white, KalaColors.turmeric, Colors.transparent],
                    ).createShader(rect),
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 33),
                      decoration: const BoxDecoration(
                        color: KalaColors.turmeric,
                        boxShadow: <BoxShadow>[BoxShadow(color: KalaColors.turmeric, blurRadius: 15, spreadRadius: 2)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 18,
                  bottom: 18,
                  child: Material(
                    color: KalaColors.ivory,
                    shape: const CircleBorder(),
                    child: IconButton(
                      iconSize: 30,
                      onPressed: widget.onCapture,
                      icon: const Icon(Icons.camera_alt_rounded, color: KalaColors.ink),
                    ),
                  ),
                ),
              ],
            );
          },
          child: widget.cameraPreview ?? const _ScannerPlaceholder(),
        ),
      ),
    );
  }
}

class _ScannerPlaceholder extends StatelessWidget {
  const _ScannerPlaceholder();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF382D2B), Color(0xFF171923), Color(0xFF573B2B)],
          ),
        ),
        child: Center(child: Icon(Icons.auto_awesome_rounded, color: Color(0x55FFFFFF), size: 92)),
      );
}

class _ReticlePainter extends CustomPainter {
  const _ReticlePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = KalaColors.turmeric
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const inset = 27.0;
    final length = 48.0 * (.5 + progress * .5);
    final corners = <Offset>[const Offset(inset, inset), Offset(size.width - inset, inset), Offset(inset, size.height - inset), Offset(size.width - inset, size.height - inset)];
    for (var i = 0; i < corners.length; i++) {
      final point = corners[i];
      final x = i.isEven ? 1.0 : -1.0;
      final y = i < 2 ? 1.0 : -1.0;
      canvas.drawLine(point, point + Offset(x * length, 0), paint);
      canvas.drawLine(point, point + Offset(0, y * length), paint);
    }
    paint.color = KalaColors.turmeric.withValues(alpha: .48);
    canvas.drawCircle(size.center(Offset.zero), math.min(size.width, size.height) * (.12 + progress * .025), paint);
  }

  @override
  bool shouldRepaint(covariant _ReticlePainter oldDelegate) => oldDelegate.progress != progress;
}
