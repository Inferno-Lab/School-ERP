import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class OnboardingArt extends StatelessWidget {
  const OnboardingArt({required this.index, super.key});

  final int index;

  @override
  Widget build(BuildContext context) {
    final child = switch (index) {
      0 => const _Campus(),
      1 => const _Connect(),
      2 => const _Progress(),
      _ => const _Journey(),
    };
    return child;
  }
}

class _Campus extends StatelessWidget {
  const _Campus();

  @override
  Widget build(BuildContext context) {
    return const _Stage(
      child: Stack(
        alignment: Alignment.center,
        children: [
          _School(),
          Positioned(
            left: 0,
            top: 8,
            child: _Note(
              icon: PhosphorIconsRegular.calendarCheck,
              label: 'attendance.title',
            ),
          ),
          Positioned(
            right: 0,
            top: 28,
            child: _Note(
              icon: PhosphorIconsRegular.bell,
              label: 'menu.notifications',
            ),
          ),
          Positioned(
            left: 8,
            bottom: 4,
            child: _Note(
              icon: PhosphorIconsRegular.student,
              label: 'nav.student',
            ),
          ),
        ],
      ),
    );
  }
}

class _Connect extends StatelessWidget {
  const _Connect();

  @override
  Widget build(BuildContext context) {
    return const _Stage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Person(icon: PhosphorIconsRegular.chalkboardTeacher, label: 'nav.teacher'),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: _PhoneCard(),
              ),
              _Person(icon: PhosphorIconsRegular.usersThree, label: 'nav.parent'),
            ],
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _Note(icon: PhosphorIconsRegular.calendarCheck, label: 'attendance.title'),
              _Note(icon: PhosphorIconsRegular.clipboardText, label: 'homework.title'),
              _Note(icon: PhosphorIconsRegular.megaphone, label: 'menu.notices'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress();

  @override
  Widget build(BuildContext context) {
    return const _Stage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ProfileCard(),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _Note(icon: PhosphorIconsRegular.checkCircle, label: 'status.present'),
              _Note(icon: PhosphorIconsRegular.listChecks, label: 'homework.title'),
              _Note(icon: PhosphorIconsRegular.chartBar, label: 'results.title'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Journey extends StatelessWidget {
  const _Journey();

  @override
  Widget build(BuildContext context) {
    return _Stage(
      child: Stack(
        alignment: Alignment.center,
        children: [
          const _School(),
          const Positioned(
            right: 0,
            top: 0,
            child: _Note(icon: PhosphorIconsRegular.house, label: 'nav.home'),
          ),
          const Positioned(
            left: 0,
            bottom: 0,
            child: _Note(icon: PhosphorIconsRegular.clock, label: 'timetable.title'),
          ),
          Positioned(
            right: 8,
            bottom: 18,
            child: Icon(
              PhosphorIconsRegular.sparkle,
              color: context.colors.primary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        return Center(
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: side * 0.78,
                  height: side * 0.78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.primary.withValues(alpha: 0.10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: child,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _School extends StatelessWidget {
  const _School();

  @override
  Widget build(BuildContext context) {
    final surface = context.colors.surfaceContainerLowest;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(168, 42),
          painter: _RoofPainter(context.colors.primary),
        ),
        Container(
          width: 168,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            boxShadow: softShadow(context.app.shadow),
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 3; i++) const _Window(),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 28,
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Window extends StatelessWidget {
  const _Window();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 22,
      decoration: BoxDecoration(
        color: context.app.infoContainer,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _RoofPainter extends CustomPainter {
  _RoofPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _RoofPainter oldDelegate) => oldDelegate.color != color;
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: softShadow(context.app.shadow),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: context.colors.primary),
          const SizedBox(width: 6),
          Text(label.tr, style: context.text.labelSmall),
        ],
      ),
    );
  }
}

class _Person extends StatelessWidget {
  const _Person({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: context.colors.primary.withValues(alpha: 0.14),
          child: Icon(icon, color: context.colors.primary),
        ),
        const SizedBox(height: 6),
        Text(label.tr, style: context.text.labelSmall),
      ],
    );
  }
}

class _PhoneCard extends StatelessWidget {
  const _PhoneCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: softShadow(context.app.shadow),
      ),
      child: Column(
        children: [
          Icon(PhosphorIconsRegular.deviceMobile, color: context.colors.onPrimary, size: 22),
          const SizedBox(height: 8),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: context.colors.onPrimary.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 6,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: context.colors.onPrimary.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: softShadow(context.app.shadow),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: context.app.infoContainer,
            child: Icon(PhosphorIconsRegular.student, color: context.colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('nav.student'.tr, style: context.text.titleSmall),
                const SizedBox(height: 8),
                const _Bars(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars();

  @override
  Widget build(BuildContext context) {
    const heights = [18.0, 28.0, 22.0, 34.0];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final height in heights)
          Container(
            width: 10,
            height: height,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: height / 40),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
