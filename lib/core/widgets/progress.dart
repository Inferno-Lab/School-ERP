import 'dart:async';

import 'package:edunest/core/theme/app_typography.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:flutter/material.dart';

class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    required this.value,
    this.suffix = '',
    this.decimals = 0,
    this.size = 28,
    this.color,
    super.key,
  });

  final double value;
  final String suffix;
  final int decimals;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.numeric(context, size: size).copyWith(color: color);
    if (context.reduceMotion) {
      return Text('${value.toStringAsFixed(decimals)}$suffix', style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, current, _) =>
          Text('${current.toStringAsFixed(decimals)}$suffix', style: style),
    );
  }
}

class AnimatedProgressRing extends StatefulWidget {
  const AnimatedProgressRing({
    required this.percent,
    this.size = 112,
    this.stroke = 10,
    this.color,
    this.child,
    super.key,
  });

  final double percent;
  final double size;
  final double stroke;
  final Color? color;
  final Widget? child;

  @override
  State<AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends State<AnimatedProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void initState() {
    super.initState();
    if (WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations) {
      _controller.value = 1;
    } else {
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.colors.primary;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = context.reduceMotion ? 1.0 : _controller.value;
          return CustomPaint(
            painter: _RingPainter(
              progress: (widget.percent / 100).clamp(0, 1) * t,
              color: color,
              track: context.colors.surfaceContainer,
              stroke: widget.stroke,
            ),
            child: Center(child: widget.child),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.stroke,
  });

  final double progress;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect.deflate(stroke / 2), 0, 6.28, false, paint..color = track);
    canvas.drawArc(
      rect.deflate(stroke / 2),
      -1.5708,
      6.28318 * progress,
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class AnimatedBar extends StatelessWidget {
  const AnimatedBar({required this.value, this.color, super.key});

  final double value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0, 1).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: context.reduceMotion ? target : target),
        duration: Duration(milliseconds: context.reduceMotion ? 0 : 600),
        curve: Curves.easeOutCubic,
        builder: (context, current, _) {
          return LinearProgressIndicator(
            value: current,
            minHeight: 8,
            backgroundColor: context.colors.surfaceContainer,
            color: color ?? context.colors.primary,
          );
        },
      ),
    );
  }
}
