import 'dart:math' as math;

import 'package:edunest/core/theme/app_colors.dart';
import 'package:edunest/core/theme/app_typography.dart';
import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/widgets/glass.dart';
import 'package:edunest/core/widgets/ui.dart';
import 'package:edunest/features/auth/controllers/splash_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  static const _pages = [
    ('onboarding.one_kicker', 'onboarding.one_title', 'onboarding.one_body'),
    ('onboarding.two_kicker', 'onboarding.two_title', 'onboarding.two_body'),
    ('onboarding.three_kicker', 'onboarding.three_title', 'onboarding.three_body'),
  ];

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: context.app.chalk,
      body: Stack(
        children: [
          PageView.builder(
            controller: controller.controller,
            itemCount: 3,
            onPageChanged: (value) => controller.page.value = value,
            itemBuilder: (context, i) => LayoutBuilder(
              builder: (context, box) {
                final artH = (box.maxHeight * .557).clamp(280.0, 520.0);
                final compact = box.maxHeight < 720;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: artH,
                      width: double.infinity,
                      child: switch (i) {
                        0 => const _DayArt(),
                        1 => const _ParentArt(),
                        _ => const _TeacherArt(),
                      },
                    ),
                    // Small phones scroll the copy; it never runs under the buttons.
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(24, compact ? 22 : 34, 24, 112 + inset.bottom),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Rise(
                              child: Overline(
                                '${_pages[i].$1.tr} · ${'onboarding.page_of'.trp({'n': '${i + 1}'})}',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Rise(index: 1, child: Text(_pages[i].$2.tr, style: context.type.h1)),
                            const SizedBox(height: 12),
                            Rise(
                              index: 2,
                              child: Text(_pages[i].$3.tr, style: context.type.b.copyWith(color: context.app.ink2)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            right: 16,
            top: inset.top + 8,
            child: GlassPress(
              onTap: controller.finish,
              child: Glass(
                width: 84,
                height: 40,
                radius: 20,
                child: Center(
                  child: Text(
                    'common.skip'.tr,
                    style: anek(
                      14.5,
                      650,
                      height: 1,
                      color: context.app.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 40 + inset.bottom,
            child: Obx(() {
              final page = controller.page.value;
              return Row(
                children: [
                  Semantics(
                    label: 'onboarding.page_of'.trp({'n': '${page + 1}'}),
                    child: Row(
                      children: [
                        for (var i = 0; i < 3; i++)
                          AnimatedContainer(
                            duration: AppDurations.medium,
                            curve: kSpring,
                            margin: const EdgeInsets.only(right: 6),
                            width: i == page ? 22 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == page ? context.app.ink : context.app.line2,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: page == 2 ? 170 : 140,
                    child: Btn(
                      page == 2 ? 'common.get_started' : 'common.next',
                      trailing: page == 2 ? null : PhosphorIconsBold.caretRight,
                      expand: true,
                      onPressed: controller.next,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Thursday's periods as rising columns.
class _DayArt extends StatelessWidget {
  const _DayArt();

  @override
  Widget build(BuildContext context) {
    const cols = [
      ('hindi', 'HI', 250.0),
      ('social', 'SST', 330.0),
      ('', '', 170.0),
      ('computer', 'CS', 410.0),
      ('art', 'ART', 300.0),
      ('maths', 'MA', 360.0),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final scale = box.maxHeight / 470;
        final colW = (box.maxWidth - 16) / 6 - 4;
        return Stack(
          children: [
            for (var i = 0; i < cols.length; i++)
              Positioned(
                left: 8 + i * (colW + 4),
                bottom: 0,
                width: colW,
                height: cols[i].$3 * scale,
                child: cols[i].$1.isEmpty
                    ? Hatch(
                        radius: const BorderRadius.vertical(top: Radius.circular(14)),
                        background: context.app.paper2,
                      )
                    : Container(
                        padding: const EdgeInsets.only(bottom: 12),
                        alignment: Alignment.bottomCenter,
                        decoration: BoxDecoration(
                          color: AppColors.subject(cols[i].$1).fill,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        ),
                        child: Text(
                          cols[i].$2,
                          style: anek(12, 760, width: 120, height: 1, em: .06, color: AppColors.subject(cols[i].$1).on),
                        ),
                      ),
              ),
          ],
        );
      },
    );
  }
}

/// Two children's day cards with a swaying switch capsule.
class _ParentArt extends StatefulWidget {
  const _ParentArt();

  @override
  State<_ParentArt> createState() => _ParentArtState();
}

class _ParentArtState extends State<_ParentArt> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 5));

  @override
  void initState() {
    super.initState();
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget kid(String subject, String over, String big, String line, double angle) => Transform.rotate(
      angle: angle,
      child: Container(
        height: 176,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.subject(subject).fill,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(color: Color(0x9910201B), blurRadius: 40, spreadRadius: -22, offset: Offset(0, 22)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Overline(over, color: const Color(0xCCFFFFFF)),
            const SizedBox(height: 10),
            Text(big, style: context.type.h2.copyWith(color: AppColors.white)),
            const SizedBox(height: 4),
            Text(line, style: context.type.s.copyWith(color: const Color(0xE0FFFFFF))),
          ],
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, box) {
        final s = box.maxHeight / 470;
        return Stack(
          children: [
            Positioned(
              left: 34,
              right: 34,
              top: 96 * s,
              child: kid(
                'maths',
                'onboarding.kid_a_over'.tr,
                'onboarding.kid_a_big'.tr,
                'onboarding.kid_a_line'.tr,
                -.07,
              ),
            ),
            Positioned(
              left: 34,
              right: 34,
              top: 250 * s,
              child: kid(
                'hindi',
                'onboarding.kid_b_over'.tr,
                'onboarding.kid_b_big'.tr,
                'onboarding.kid_b_line'.tr,
                .052,
              ),
            ),
            AnimatedBuilder(
              animation: _c,
              builder: (context, child) {
                final t = context.reduceMotion ? 0 : (1 - math.cos(_c.value * 2 * math.pi)) / 2;
                return Positioned(left: box.maxWidth / 2 - 105 + 22 * t, top: 226 * s, child: child!);
              },
              child: Glass(
                width: 210,
                height: 52,
                radius: 26,
                tint: const Color(0x1AFFFFFF),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    const Avatar('Aarav Sharma', background: Color(0xFFFBFCF9), foreground: Color(0xFF10201B)),
                    Expanded(
                      child: Text(
                        'home.switch_child'.tr,
                        textAlign: TextAlign.center,
                        style: anek(15, 680, height: 1, color: AppColors.white).copyWith(
                          shadows: const [Shadow(color: Color(0x59000000), blurRadius: 6, offset: Offset(0, 1))],
                        ),
                      ),
                    ),
                    Avatar(
                      'Ananya Sharma',
                      initials: 'AN',
                      background: const Color(0xFFFBFCF9),
                      foreground: AppColors.subject('hindi').fill,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A class register with two absentees and a glass tally over it.
class _TeacherArt extends StatelessWidget {
  const _TeacherArt();

  @override
  Widget build(BuildContext context) {
    const names = [
      'AS',
      'DM',
      'KS',
      'MK',
      'VJ',
      'AR',
      'IG',
      'SK',
      'AN',
      'KP',
      'RM',
      'TS',
      'NB',
      'PD',
      'YC',
      'HV',
      'OB',
      'ZA',
      'LF',
      'EG',
    ];
    const absent = {6, 18};
    const late = {12};
    return LayoutBuilder(
      builder: (context, box) {
        final s = box.maxHeight / 470;
        final w = math.min<double>(box.maxWidth - 48, 342);
        return Stack(
          children: [
            Positioned(
              left: (box.maxWidth - w) / 2,
              top: 110 * s,
              width: w,
              child: Wrap(
                spacing: (w - 5 * 62) / 4,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < names.length; i++)
                    _RegisterDot(
                      initials: names[i],
                      colorIndex: i % 4,
                      absent: absent.contains(i),
                      late: late.contains(i),
                    ),
                ],
              ),
            ),
            Positioned(
              left: (box.maxWidth - w) / 2,
              top: 110 * s + 268,
              width: w,
              child: Glass(
                height: 56,
                radius: 28,
                tint: const Color(0x38FBFCF9),
                padding: const EdgeInsets.only(left: 18, right: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: '${'onboarding.tally_present'.tr} · ',
                          children: [
                            TextSpan(
                              text: '${'onboarding.tally_absent'.tr} · ',
                              style: TextStyle(color: context.app.badText),
                            ),
                            TextSpan(
                              text: 'onboarding.tally_late'.tr,
                              style: const TextStyle(color: AppColors.late),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: anek(15, 680, height: 1, color: context.app.ink),
                      ),
                    ),
                    Btn('common.submit', kind: BtnKind.ink, small: true, onPressed: () {}),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RegisterDot extends StatelessWidget {
  const _RegisterDot({required this.initials, required this.colorIndex, required this.absent, required this.late});

  final String initials;
  final int colorIndex;
  final bool absent;
  final bool late;

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    final bg = absent ? c.paper : AppColors.houses[colorIndex];
    final fg = absent ? c.badText : (colorIndex == 3 ? AppColors.mariInk : AppColors.white);
    return SizedBox(
      width: 62,
      height: 62,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: absent ? Border.all(color: AppColors.bad, width: 2.5) : null,
            ),
            child: Text(initials, style: anek(16, 720, width: 115, height: 1, color: fg)),
          ),
          if (absent || late)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: absent ? AppColors.bad : AppColors.late, shape: BoxShape.circle),
                child: Text(absent ? 'A' : 'L', style: anek(11, 760, height: 1, color: AppColors.white)),
              ),
            ),
        ],
      ),
    );
  }
}
