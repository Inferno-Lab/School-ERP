import 'package:edunest/core/routes/app_routes.dart';
import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/widgets/app_card.dart';
import 'package:edunest/core/widgets/feature_page.dart';
import 'package:edunest/core/widgets/misc.dart';
import 'package:edunest/core/widgets/states.dart';
import 'package:edunest/features/teacher_tools/controllers/teacher_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class TeacherHomeView extends GetView<TeacherHomeController> {
  const TeacherHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final next = controller.nextPeriod;
      final schoolClass = controller.schoolClass;
      return FeaturePage(
        title: 'nav.home',
        subtitle: 'teacher.home_sub',
        onRefresh: controller.load,
        child: ViewStateView(
          state: controller.state.value,
          onRetry: controller.load,
          errorKey: controller.errorMessage.value,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [context.app.gradientStart, context.app.gradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('teacher.next'.tr, style: const TextStyle(color: Colors.white)),
                      Text(
                        next == null ? 'teacher.no_next'.tr : 'subject.${next.subject}'.tr,
                        style: context.text.headlineMedium?.copyWith(color: Colors.white),
                      ),
                      if (next != null)
                        Text(
                          '${next.start}–${next.end} · ${schoolClass?.label ?? ''}',
                          style: const TextStyle(color: Colors.white),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: 'nav.classes',
                        value: schoolClass == null ? '0' : '1',
                        icon: PhosphorIconsRegular.chalkboardTeacher,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatTile(
                        label: 'teacher.grade',
                        value: '${controller.pendingGrades}',
                        icon: PhosphorIconsRegular.checks,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (schoolClass != null)
                  AppCard(
                    onTap: () => Get.toNamed<void>(
                      '/teacher/attendance/${schoolClass.id}',
                    ),
                    child: Row(
                      children: [
                        const Icon(PhosphorIconsRegular.calendarCheck),
                        const SizedBox(width: 12),
                        Expanded(child: Text('teacher.mark'.tr, style: context.text.titleMedium)),
                        const Icon(PhosphorIconsRegular.caretRight),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class TeacherClassesView extends GetView<TeacherClassesController> {
  const TeacherClassesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => FeaturePage(
        title: 'nav.classes',
        subtitle: 'teacher.home_sub',
        onRefresh: controller.load,
        child: ViewStateView(
          state: controller.state.value,
          onRetry: controller.load,
          errorKey: controller.errorMessage.value,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            child: Column(
              children: [
                for (final schoolClass in controller.classes)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(schoolClass.label, style: context.text.headlineSmall),
                            subtitle: Text(schoolClass.room),
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              ActionChip(
                                label: Text('teacher.mark'.tr),
                                onPressed: () => Get.toNamed<void>(
                                  '/teacher/attendance/${schoolClass.id}',
                                ),
                              ),
                              ActionChip(
                                label: Text('teacher.assign'.tr),
                                onPressed: () => Get.toNamed<void>(
                                  AppRoutes.teacherAssign,
                                  arguments: schoolClass.id,
                                ),
                              ),
                              ActionChip(
                                label: Text('teacher.grade'.tr),
                                onPressed: () => Get.toNamed<void>(AppRoutes.teacherGrade),
                              ),
                              ActionChip(
                                label: Text('teacher.marks'.tr),
                                onPressed: () => Get.toNamed<void>(
                                  '/teacher/marks/${schoolClass.id}',
                                ),
                              ),
                              ActionChip(
                                label: Text('teacher.notice'.tr),
                                onPressed: () => Get.toNamed<void>(AppRoutes.teacherNotice),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
