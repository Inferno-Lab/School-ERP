import 'package:edunest/core/config/app_config.dart';
import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/widgets/buttons.dart';
import 'package:edunest/core/widgets/misc.dart';
import 'package:edunest/features/auth/controllers/splash_controller.dart';
import 'package:edunest/features/auth/views/onboarding_art.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  static const _pages = [
    ('onboard.one_title', 'onboard.one_body'),
    ('onboard.two_title', 'onboard.two_body'),
    ('onboard.three_title', 'onboard.three_body'),
    ('onboard.four_title', 'onboard.four_body'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.app.gradientStart.withValues(alpha: 0.14),
              context.colors.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
                child: Row(
                  children: [
                    NestMark(size: 28, color: context.colors.primary),
                    const SizedBox(width: 8),
                    Text(AppConfig.appName, style: context.text.titleMedium),
                    const Spacer(),
                    Obx(
                      () => controller.isLast
                          ? const SizedBox(width: 72)
                          : TextButton(
                              onPressed: controller.finish,
                              child: Text('common.skip'.tr),
                            ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: controller.controller,
                  itemCount: OnboardingController.pageCount,
                  onPageChanged: (value) => controller.page.value = value,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return _Slide(title: page.$1, body: page.$2, index: index);
                  },
                ),
              ),
              const _Indicator(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Obx(
                  () => Row(
                    children: [
                      if (!controller.isFirst) ...[
                        TextButton(
                          onPressed: controller.previous,
                          child: Text('onboard.previous'.tr),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: PrimaryButton(
                          label: controller.isLast ? 'common.get_started' : 'common.next',
                          onPressed: controller.next,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.title, required this.body, required this.index});

  final String title;
  final String body;
  final int index;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final headline = width < 360 ? 26.0 : 30.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: _Enter(child: OnboardingArt(index: index)),
          ),
          Flexible(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    title.tr,
                    textAlign: TextAlign.center,
                    style: context.text.displaySmall?.copyWith(
                      fontSize: headline,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    body.tr,
                    textAlign: TextAlign.center,
                    style: context.text.bodyLarge?.copyWith(
                      fontSize: 16,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Enter extends StatelessWidget {
  const _Enter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final still = context.reduceMotion;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: still ? 1 : 0, end: 1),
      duration: still ? Duration.zero : AppDurations.medium,
      curve: AppCurves.ease,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 14),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _Indicator extends GetView<OnboardingController> {
  const _Indicator();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < OnboardingController.pageCount; i++)
            AnimatedContainer(
              duration: context.reduceMotion ? Duration.zero : AppDurations.fast,
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
    );
  }
}
