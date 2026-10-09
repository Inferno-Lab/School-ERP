import 'package:edunest/core/routes/app_routes.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/formatters.dart';
import 'package:edunest/core/widgets/chips.dart';
import 'package:edunest/core/widgets/feature_page.dart';
import 'package:edunest/core/widgets/progress.dart';
import 'package:edunest/core/widgets/states.dart';
import 'package:edunest/data/models/academics.dart';
import 'package:edunest/features/attendance/controllers/attendance_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendanceView extends GetView<AttendanceController> {
  const AttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final summary = controller.summary;
      return FeaturePage(
        title: 'attendance.title',
        subtitle: 'attendance.subtitle',
        onRefresh: controller.load,
        floating: FloatingActionButton.extended(
          onPressed: () => Get.toNamed<void>(AppRoutes.leaveApply),
          icon: const Icon(PhosphorIconsRegular.plus),
          label: Text('attendance.apply_leave'.tr),
        ),
        child: ViewStateView(
          state: controller.state.value,
          onRetry: controller.load,
          errorKey: controller.errorMessage.value,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            child: Column(
              children: [
                Row(
                  children: [
                    AnimatedProgressRing(
                      percent: summary.percent,
                      size: 88,
                      child: AnimatedCounter(value: summary.percent, suffix: '%', size: 16),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          attendanceBadge(context, 'present'),
                          attendanceBadge(context, 'absent'),
                          attendanceBadge(context, 'late'),
                          attendanceBadge(context, 'holiday'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TableCalendar<void>(
                  firstDay: DateTime.now().subtract(const Duration(days: 120)),
                  lastDay: DateTime.now().add(const Duration(days: 30)),
                  focusedDay: controller.focused.value,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                  calendarStyle: const CalendarStyle(outsideDaysVisible: false),
                  onPageChanged: (day) => controller.focused.value = day,
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, _) => _cell(context, day),
                    todayBuilder: (context, day, _) => _cell(context, day, today: true),
                    outsideBuilder: (context, day, _) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('attendance.absent_days'.tr, style: context.text.headlineSmall),
                ),
                const SizedBox(height: 8),
                ..._issues(context),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _cell(BuildContext context, DateTime day, {bool today = false}) {
    final record = controller.on(day);
    final status = record?.status;
    final color = switch (status) {
      AttendanceStatus.present => context.app.success,
      AttendanceStatus.absent => context.app.danger,
      AttendanceStatus.lateArrival => context.app.warning,
      AttendanceStatus.holiday => context.app.info,
      null => context.colors.surfaceContainer,
    };
    return Container(
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: status == null ? 1 : 0.18),
        shape: BoxShape.circle,
        border: today ? Border.all(color: context.colors.primary, width: 1.4) : null,
      ),
      child: Text('${day.day}', style: context.text.bodyMedium),
    );
  }

  List<Widget> _issues(BuildContext context) {
    final items = controller.monthDays.where(
      (day) =>
          day.status == AttendanceStatus.absent ||
          day.status == AttendanceStatus.lateArrival,
    );
    if (items.isEmpty) {
      return [Text('attendance.none'.tr, style: context.text.bodyMedium)];
    }
    return [
      for (final day in items)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(Formatters.fullDate(day.date)),
          trailing: attendanceBadge(
            context,
            day.status == AttendanceStatus.absent ? 'absent' : 'late',
          ),
        ),
    ];
  }
}
