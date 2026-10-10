import 'package:edunest/core/config/app_config.dart';
import 'package:edunest/core/theme/app_colors.dart';
import 'package:edunest/core/theme/app_typography.dart';
import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/widgets/ui.dart';
import 'package:edunest/features/auth/controllers/splash_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Three notebooks fan out and a single glass egg settles over them.
class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final still = context.reduceMotion;
    return Scaffold(
      backgroundColor: context.app.chalk,
      body: Column(
        children: [
          const Spacer(flex: 5),
          SizedBox(
            width: 220,
            height: 220,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: still ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1400),
              builder: (context, t, _) {
                final fan = kSpring.transform(((t - .07) / .64).clamp(0, 1));
                return Stack(
                  children: [
                    _Book(subject: 'maths', left: 32 + 40 * (1 - fan), top: 20, angle: -.244 * fan),
                    _Book(subject: 'science', left: 152 - 40 * (1 - fan), top: 20, angle: .244 * fan),
                    const _Book(subject: 'hindi', left: 92, top: 6, angle: 0),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 30),
          Rise(
            index: 4,
            child: Text(
              AppConfig.appName,
              style: anek(46, 780, width: 125, height: .9, em: -.03, color: context.app.ink),
            ),
          ),
          const SizedBox(height: 10),
          Rise(index: 5, child: Text(AppConfig.schoolName, style: context.type.cap)),
          const Spacer(flex: 4),
          Text(AppConfig.schoolTagline, style: context.type.cap.copyWith(fontSize: 12)),
          SizedBox(height: 44 + MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}

class _Book extends StatelessWidget {
  const _Book({required this.subject, required this.left, required this.top, required this.angle});

  final String subject;
  final double left;
  final double top;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Transform.rotate(
        angle: angle,
        alignment: Alignment.bottomCenter,
        child: Container(
          width: 86,
          height: 168,
          decoration: BoxDecoration(
            color: AppColors.subject(subject).fill,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(6), right: Radius.circular(16)),
            boxShadow: const [
              BoxShadow(color: Color(0x6610201B), blurRadius: 30, spreadRadius: -12, offset: Offset(0, 14)),
            ],
          ),
          foregroundDecoration: spineDecoration,
        ),
      ),
    );
  }
}
