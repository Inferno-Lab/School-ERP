import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/widgets/buttons.dart';
import 'package:edunest/features/auth/controllers/splash_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    const pages = [
      ('onboard.one_title', 'onboard.one_body', 0),
      ('onboard.two_title', 'onboard.two_body', 1),
      ('onboard.three_title', 'onboard.three_body', 2),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: controller.finish,
                child: Text('common.skip'.tr),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller.controller,
                itemCount: pages.length,
                onPageChanged: (value) => controller.page.value = value,
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return _Slide(title: page.$1, body: page.$2, variant: page.$3);
                },
              ),
            ),
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    AnimatedContainer(
                      duration: AppDurations.fast,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: controller.page.value == i ? 22 : 8,
                      decoration: BoxDecoration(
                        color: controller.page.value == i
                            ? context.colors.primary
                            : context.colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Obx(
                () => PrimaryButton(
                  label: controller.page.value == 2
                      ? 'common.get_started'
                      : 'common.next',
                  onPressed: controller.next,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.title, required this.body, required this.variant});

  final String title;
  final String body;
  final int variant;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(child: _Art(variant: variant)),
          Text(title.tr, style: context.text.headlineLarge, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            body.tr,
            style: context.text.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _Art extends StatelessWidget {
  const _Art({required this.variant});

  final int variant;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _OnboardPainter(
            variant: variant,
            primary: context.app.gradientStart,
            secondary: context.app.gradientEnd,
            surface: context.colors.surfaceContainerLowest,
          ),
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }
}

class _OnboardPainter extends CustomPainter {
  _OnboardPainter({
    required this.variant,
    required this.primary,
    required this.secondary,
    required this.surface,
  });

  final int variant;
  final Color primary;
  final Color secondary;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = primary.withValues(alpha: 0.15);
    canvas.drawCircle(center, size.shortestSide * 0.34, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: size.width * 0.62, height: size.height * 0.42),
        const Radius.circular(28),
      ),
      Paint()..color = surface,
    );
    final accent = Paint()..color = variant == 1 ? secondary : primary;
    canvas.drawCircle(
      center.translate(0, variant == 2 ? -10 : -30),
      18,
      accent,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, 28),
          width: size.width * (0.28 + variant * 0.06),
          height: 14,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = primary.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _OnboardPainter oldDelegate) =>
      oldDelegate.variant != variant || oldDelegate.primary != primary;
}
