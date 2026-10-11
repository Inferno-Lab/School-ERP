import 'dart:async';

import 'package:edunest/core/config/app_config.dart';
import 'package:edunest/core/theme/app_colors.dart';
import 'package:edunest/core/theme/app_typography.dart';
import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/widgets/ui.dart';
import 'package:edunest/features/auth/controllers/splash_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Three notebooks fan out around the exact centre of the screen, under a warm glow, with the name below.
class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.app.chalk,
      // Until the window has its final size the screen stays plain chalk, like the native launch
      // screen, so a first frame drawn at transient metrics is never seen.
      body: const _SettledSize(child: _Mark()),
    );
  }
}

/// Shows [child] once the window size has stopped changing for a moment.
class _SettledSize extends StatefulWidget {
  const _SettledSize({required this.child});

  final Widget child;

  @override
  State<_SettledSize> createState() => _SettledSizeState();
}

class _SettledSizeState extends State<_SettledSize> with WidgetsBindingObserver {
  Timer? _timer;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _wait();
  }

  @override
  void didChangeMetrics() {
    if (!_ready) _wait();
  }

  void _wait() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 160), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ready ? widget.child : const SizedBox.expand();
}

class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    final still = context.reduceMotion;
    final c = context.app;
    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 5),
          // 270 wide so the fan (books at 32, 92 and 152, each 86 wide) is centred in its own box.
          SizedBox(
            width: 270,
            height: 230,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: still ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1400),
              builder: (context, t, _) {
                final fan = kSpring.transform(((t - .07) / .64).clamp(0, 1));
                final glow = Curves.easeOut.transform((t / .8).clamp(0, 1));
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: .55 * glow,
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [AppColors.mari.withValues(alpha: .45), AppColors.mari.withValues(alpha: 0)],
                          ),
                        ),
                      ),
                    ),
                    _Book(subject: 'maths', left: 32 + 40 * (1 - fan), top: 24, angle: -.244 * fan),
                    _Book(subject: 'science', left: 152 - 40 * (1 - fan), top: 24, angle: .244 * fan),
                    const _Book(subject: 'hindi', left: 92, top: 10, angle: 0),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          Rise(
            index: 4,
            child: Text(
              AppConfig.appName,
              textAlign: TextAlign.center,
              style: anek(46, 780, width: 125, height: .9, em: -.03, color: c.ink),
            ),
          ),
          const SizedBox(height: 12),
          Rise(
            index: 5,
            child: Text(AppConfig.schoolName, textAlign: TextAlign.center, style: context.type.cap),
          ),
          const Spacer(flex: 4),
          Text(
            AppConfig.schoolTagline,
            textAlign: TextAlign.center,
            style: context.type.cap.copyWith(fontSize: 12),
          ),
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
