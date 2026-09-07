import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_flow_controller.dart';
import '../../theme/kala_theme.dart';
import '../../widgets/ambient_living_canvas.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 11))..repeat();
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: AmbientLivingCanvas(
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomScrollView(slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(25, 30, 25, 8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                      const Text('कला-Connect', style: TextStyle(fontSize: 43, height: 1, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
                      const SizedBox(height: 9),
                      const Text('From “I make it” to “I can sell it.”', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 32),
                      Center(child: _RotatingCraft(progress: _controller.value)),
                      const SizedBox(height: 31),
                      const Text('Your craft.\nYour identity.', style: TextStyle(fontSize: 37, height: 1.04, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 13),
                      const Text('Take a photo, speak, and reach buyers directly.', style: TextStyle(fontSize: 17, height: 1.35)),
                      const SizedBox(height: 27),
                      _GlowAction(label: 'Get started', icon: Icons.arrow_forward_rounded, onTap: context.read<AppFlowController>().openAuthentication),
                      const SizedBox(height: 13),
                      Center(child: TextButton(onPressed: context.read<AppFlowController>().openAuthentication, child: const Text('Log in', style: TextStyle(fontWeight: FontWeight.w900, color: KalaColors.ink)))),
                    ]),
                  ),
                ),
                SliverToBoxAdapter(child: _StoryRail(progress: _controller.value)),
              ]),
            ),
          ),
        ),
      );
}

class _RotatingCraft extends StatelessWidget {
  const _RotatingCraft({required this.progress});
  final double progress;
  @override
  Widget build(BuildContext context) {
    final bob = math.sin(progress * math.pi * 2) * 8;
    return Transform.translate(
      offset: Offset(0, bob),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..rotateY(math.sin(progress * math.pi * 2) * .34)..rotateZ(math.sin(progress * math.pi * 2) * .06),
        child: Container(
          height: 240,
          width: 240,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(colors: <Color>[Color(0xFFFFE291), KalaColors.terracotta, Color(0xFF672345)]), boxShadow: <BoxShadow>[BoxShadow(color: KalaColors.terracotta.withValues(alpha: .42), blurRadius: 45, spreadRadius: 7)]),
          child: const Icon(Icons.local_florist_rounded, size: 130, color: Color(0xE6FFF5D9)),
        ),
      ),
    );
  }
}

class _GlowAction extends StatelessWidget {
  const _GlowAction({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 19),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: <Color>[KalaColors.terracotta, Color(0xFFD73C77)]), boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x66E85D3F), blurRadius: 24, spreadRadius: 2)]),
          child: Row(children: <Widget>[Text(label, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)), const Spacer(), Icon(icon, color: Colors.white)]),
        ),
      );
}

class _StoryRail extends StatelessWidget {
  const _StoryRail({required this.progress});
  final double progress;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 164,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(25, 20, 25, 28), children: const <Widget>[
          _Story(text: '“My weaving now reaches Delhi.”', color: KalaColors.indigo),
          SizedBox(width: 12),
          _Story(text: '“One photograph brought me new customers.”', color: KalaColors.leaf),
        ]),
      );
}

class _Story extends StatelessWidget {
  const _Story({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(width: 265, padding: const EdgeInsets.all(19), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)), child: Align(alignment: Alignment.bottomLeft, child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 17, height: 1.25, fontWeight: FontWeight.w800))));
}
