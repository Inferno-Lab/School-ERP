import 'package:edunest/core/config/app_config.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/widgets/misc.dart';
import 'package:edunest/features/auth/controllers/splash_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.app.gradientStart, context.app.gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const _Blob(top: -40, right: -30, size: 180),
            const _Blob(bottom: 80, left: -50, size: 160),
            const _Blob(bottom: -20, right: 40, size: 90),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const NestMark(size: 88)
                      .animateBox(),
                  const SizedBox(height: 18),
                  Text(
                    AppConfig.appName,
                    style: context.text.headlineLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'splash.tagline'.tr,
                    style: context.text.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.86),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Widget {
  Widget animateBox() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: ((value - 0.8) / 0.2).clamp(0, 1),
        child: Transform.scale(scale: value, child: child),
      ),
      child: this,
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, this.top, this.bottom, this.left, this.right});

  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}
