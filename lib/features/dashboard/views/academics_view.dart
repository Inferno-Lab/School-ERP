import 'package:edunest/core/routes/app_routes.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/widgets/app_card.dart';
import 'package:edunest/core/widgets/feature_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AcademicsView extends StatelessWidget {
  const AcademicsView({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      ('attendance.title', 'attendance.subtitle', AppRoutes.attendance, PhosphorIconsDuotone.calendarCheck),
      ('homework.title', 'homework.subtitle', AppRoutes.homework, PhosphorIconsDuotone.clipboardText),
      ('timetable.title', 'timetable.subtitle', AppRoutes.timetable, PhosphorIconsDuotone.clock),
      ('results.title', 'results.subtitle', AppRoutes.results, PhosphorIconsDuotone.chartBar),
    ];
    return FeaturePage(
      title: 'academics.title',
      subtitle: 'academics.subtitle',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        child: Column(
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  onTap: () => Get.toNamed<void>(item.$3),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: context.colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(item.$4, color: context.colors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.$1.tr, style: context.text.titleMedium),
                            Text(item.$2.tr, style: context.text.bodySmall),
                          ],
                        ),
                      ),
                      const Icon(PhosphorIconsRegular.caretRight),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
