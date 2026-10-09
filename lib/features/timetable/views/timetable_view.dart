import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/widgets/feature_page.dart';
import 'package:edunest/core/widgets/states.dart';
import 'package:edunest/data/models/academics.dart';
import 'package:edunest/features/timetable/controllers/timetable_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TimetableView extends GetView<TimetableController> {
  const TimetableView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final day = controller.selected;
      return FeaturePage(
        title: 'timetable.title',
        subtitle: 'timetable.subtitle',
        onRefresh: controller.load,
        child: ViewStateView(
          state: controller.state.value,
          onRetry: controller.load,
          errorKey: controller.errorMessage.value,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(
              children: [
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: TimetableController.keys.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final selected = controller.dayIndex.value == index;
                      return ChoiceChip(
                        label: Text('day.${TimetableController.keys[index]}'.tr),
                        selected: selected,
                        onSelected: (_) => controller.dayIndex.value = index,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (day != null)
                  for (final period in day.periods) _Period(period: period),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _Period extends GetView<TimetableController> {
  const _Period({required this.period});

  final PeriodSlot period;

  @override
  Widget build(BuildContext context) {
    final now = controller.isNow(period);
    final colors = context.app.subject(period.subject);
    final teacher = period.teacherId == null ? '' : controller.teachers[period.teacherId] ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.tint,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: now ? Border.all(color: colors.tone, width: 1.6) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              '${period.start}\n${period.end}',
              style: context.text.bodySmall?.copyWith(color: colors.tone),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'subject.${period.subject}'.tr,
                  style: context.text.titleMedium?.copyWith(color: colors.tone),
                ),
                if (teacher.isNotEmpty)
                  Text(teacher, style: context.text.bodySmall?.copyWith(color: colors.tone)),
              ],
            ),
          ),
          if (now)
            Text('timetable.now'.tr, style: context.text.labelLarge?.copyWith(color: colors.tone)),
        ],
      ),
    );
  }
}
