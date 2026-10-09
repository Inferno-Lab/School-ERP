import 'package:edunest/core/routes/app_routes.dart';
import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/formatters.dart';
import 'package:edunest/core/widgets/app_card.dart';
import 'package:edunest/core/widgets/chips.dart';
import 'package:edunest/core/widgets/progress.dart';
import 'package:edunest/data/models/academics.dart';
import 'package:edunest/data/models/campus.dart';
import 'package:edunest/features/shell/shell_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AttendanceRingCard extends StatelessWidget {
  const AttendanceRingCard({required this.percent, super.key});

  final double percent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => Get.toNamed<void>(AppRoutes.attendance),
      child: Row(
        children: [
          AnimatedProgressRing(
            percent: percent,
            size: 92,
            child: AnimatedCounter(
              value: percent,
              suffix: '%',
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('home.attendance'.tr, style: context.text.headlineSmall),
                Text('home.this_month'.tr, style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TimetableStrip extends StatelessWidget {
  const TimetableStrip({required this.day, super.key});

  final TimetableDay? day;

  @override
  Widget build(BuildContext context) {
    final periods = day?.periods ?? const <PeriodSlot>[];
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: periods.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final period = periods[index];
          final now = _isNow(period);
          final colors = context.app.subject(period.subject);
          return InkWell(
            onTap: () => Get.toNamed<void>(AppRoutes.timetable),
            borderRadius: BorderRadius.circular(AppRadius.tile),
            child: Container(
              width: 148,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.tint,
                borderRadius: BorderRadius.circular(AppRadius.tile),
                border: now ? Border.all(color: colors.tone, width: 1.6) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${period.start}–${period.end}',
                    style: context.text.bodySmall?.copyWith(color: colors.tone),
                  ),
                  const Spacer(),
                  Text(
                    'subject.${period.subject}'.tr,
                    style: context.text.titleMedium?.copyWith(color: colors.tone),
                    maxLines: 2,
                  ),
                  if (now)
                    Text(
                      'timetable.now'.tr,
                      style: context.text.bodySmall?.copyWith(color: colors.tone),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isNow(PeriodSlot period) {
    final now = DateTime.now();
    final start = _clock(period.start);
    final end = _clock(period.end);
    final current = now.hour * 60 + now.minute;
    return current >= start && current < end;
  }

  int _clock(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

class HomeworkDueCard extends StatelessWidget {
  const HomeworkDueCard({required this.items, super.key});

  final List<Homework> items;

  @override
  Widget build(BuildContext context) {
    final nearest = items.isEmpty
        ? null
        : (items.toList()..sort((a, b) => a.dueOn.compareTo(b.dueOn))).first;
    final label = nearest == null
        ? 'home.nothing_due'.tr
        : _due(nearest.dueOn);
    return AppCard(
      onTap: () => Get.toNamed<void>(AppRoutes.homework),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${items.length}', style: context.text.headlineMedium),
          Text('home.homework'.tr, style: context.text.titleSmall),
          const Spacer(),
          Text(label, style: context.text.bodySmall),
        ],
      ),
    );
  }

  String _due(DateTime date) {
    final key = Formatters.countdown(date);
    if (key == 'time.due_in_days') {
      return key.trParams({'count': '${Formatters.daysUntil(date)}'});
    }
    return key.tr;
  }
}

class ExamCard extends StatelessWidget {
  const ExamCard({required this.exam, super.key});

  final Exam? exam;

  @override
  Widget build(BuildContext context) {
    final days = exam == null ? 0 : Formatters.daysUntil(exam!.startDate);
    return AppCard(
      onTap: () => Get.toNamed<void>(AppRoutes.results),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftChip(label: exam == null ? 'home.no_exam' : 'time.days_left'.trParams({'count': '$days'})),
          const Spacer(),
          Text(exam?.name ?? 'home.exam'.tr, style: context.text.titleMedium),
          Text('home.exam'.tr, style: context.text.bodySmall),
        ],
      ),
    );
  }
}

class FeeBanner extends StatelessWidget {
  const FeeBanner({required this.item, super.key});

  final Installment item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.app.gradientStart, context.app.gradientEnd],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'home.fee_due'.tr,
                  style: context.text.bodySmall?.copyWith(color: Colors.white),
                ),
                Text(
                  Formatters.inr(item.amount),
                  style: context.text.headlineSmall?.copyWith(color: Colors.white),
                ),
                Text(
                  item.title,
                  style: context.text.bodyMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.white),
            onPressed: () {
              if (Get.isRegistered<ShellController>()) {
                Get.find<ShellController>().index.value = 2;
              }
            },
            child: Text(
              'common.pay_now'.tr,
              style: TextStyle(color: context.colors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class NoticeCarousel extends StatefulWidget {
  const NoticeCarousel({required this.notices, super.key});

  final List<Notice> notices;

  @override
  State<NoticeCarousel> createState() => _NoticeCarouselState();
}

class _NoticeCarouselState extends State<NoticeCarousel> {
  final _page = PageController();
  var _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notices.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: _page,
            itemCount: widget.notices.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) {
              final notice = widget.notices[index];
              return AppCard(
                onTap: () => Get.toNamed<void>('/notices/${notice.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notice.title, style: context.text.titleMedium, maxLines: 2),
                    const Spacer(),
                    Text(Formatters.dayMonth(notice.date), style: context.text.bodySmall),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.notices.length; i++)
              Container(
                width: i == _index ? 14 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == _index
                      ? context.colors.primary
                      : context.colors.outline,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
