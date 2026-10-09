import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.tint,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = tint ?? context.colors.primary;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.tile),
          border: Border.all(color: context.app.cardBorder),
          boxShadow: softShadow(context.app.shadow),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(value, style: context.text.headlineSmall),
            Text(
              label.tr,
              style: context.text.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    required this.labels,
    required this.index,
    required this.onChanged,
    super.key,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: i == index
                        ? context.colors.surfaceContainerLowest
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: i == index ? softShadow(context.app.shadow) : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i].tr,
                    style: context.text.labelLarge?.copyWith(
                      color: i == index
                          ? context.colors.onSurface
                          : context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TimelineTile extends StatelessWidget {
  const TimelineTile({
    required this.title,
    required this.subtitle,
    required this.done,
    this.last = false,
    this.color,
    this.trailing,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool done;
  final bool last;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? (done ? context.app.success : context.colors.outline);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(
                done ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.circle,
                color: tone,
                size: 20,
              ),
              if (!last)
                Expanded(
                  child: Container(width: 2, color: tone.withValues(alpha: 0.3)),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.tr, style: context.text.titleMedium),
                  Text(subtitle, style: context.text.bodySmall),
                  ?trailing,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BentoGrid extends StatelessWidget {
  const BentoGrid({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return GridView.count(
      crossAxisCount: wide ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: wide ? 1.3 : 1.05,
      children: children,
    );
  }
}

class NestMark extends StatelessWidget {
  const NestMark({this.size = 72, this.color = Colors.white, super.key});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _NestPainter(color),
    );
  }
}

class _NestPainter extends CustomPainter {
  _NestPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;
    final nest = Path()
      ..moveTo(w * 0.16, h * 0.58)
      ..quadraticBezierTo(w * 0.5, h * 0.28, w * 0.84, h * 0.58);
    canvas.drawPath(nest, paint);
    final lower = Path()
      ..moveTo(w * 0.24, h * 0.62)
      ..quadraticBezierTo(w * 0.5, h * 0.86, w * 0.76, h * 0.62);
    canvas.drawPath(lower, paint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.34), w * 0.07, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _NestPainter oldDelegate) => oldDelegate.color != color;
}
