import 'dart:async';

import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/formatters.dart';
import 'package:edunest/core/widgets/app_bottom_sheet.dart';
import 'package:edunest/core/widgets/buttons.dart';
import 'package:edunest/core/widgets/chips.dart';
import 'package:edunest/core/widgets/feature_page.dart';
import 'package:edunest/core/widgets/misc.dart';
import 'package:edunest/core/widgets/states.dart';
import 'package:edunest/data/models/academics.dart';
import 'package:edunest/features/homework/controllers/homework_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class HomeworkView extends GetView<HomeworkController> {
  const HomeworkView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = '${controller.state.value}${controller.tab.value}${controller.selectedId.value}';
      if (!context.isWide) {
        return FeaturePage(
          title: 'homework.title',
          subtitle: 'homework.subtitle',
          onRefresh: controller.load,
          child: const _HomeworkList(),
        );
      }
      final item = controller.selected;
      return FeaturePage(
        title: 'homework.title',
        subtitle: 'homework.subtitle',
        onRefresh: controller.load,
        expand: true,
        child: Row(
          children: [
            const SizedBox(width: 420, child: SingleChildScrollView(child: _HomeworkList())),
            VerticalDivider(width: 1, color: context.colors.outlineVariant),
            Expanded(
              child: item == null
                  ? const EmptyState(title: 'empty.title', body: 'home.nothing_due')
                  : SingleChildScrollView(child: _HomeworkBody(item: item)),
            ),
          ],
        ),
      );
    });
  }
}

class _HomeworkList extends GetView<HomeworkController> {
  const _HomeworkList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        children: [
          SegmentedTabs(
            labels: const ['homework.pending', 'homework.submitted', 'homework.graded'],
            index: controller.tab.value,
            onChanged: (value) => controller.tab.value = value,
          ),
          const SizedBox(height: 16),
          ViewStateView(
            state: controller.state.value,
            onRetry: controller.load,
            errorKey: controller.errorMessage.value,
            emptyBody: 'home.nothing_due',
            child: controller.visible.isEmpty
                ? const EmptyState(title: 'empty.title', body: 'home.nothing_due')
                : Column(
                    children: [
                      for (final item in controller.visible) _HomeworkCard(item: item),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  const _HomeworkCard({required this.item});

  final Homework item;

  @override
  Widget build(BuildContext context) {
    final colors = context.app.subject(item.subject);
    final key = Formatters.countdown(item.dueOn);
    final due = key == 'time.due_in_days'
        ? key.trParams({'count': '${Formatters.daysUntil(item.dueOn)}'})
        : key.tr;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () {
          if (context.isWide) {
            Get.find<HomeworkController>().pick = item.id;
          } else {
            unawaited(Get.toNamed<void>('/homework/${item.id}'));
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: softShadow(context.app.shadow),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 96,
                decoration: BoxDecoration(
                  color: colors.tone,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(22)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SubjectChip(subject: item.subject),
                      const SizedBox(height: 6),
                      Text(item.title, style: context.text.titleMedium),
                      Text(due, style: context.text.bodySmall),
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

class HomeworkDetailView extends GetView<HomeworkDetailController> {
  const HomeworkDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final item = controller.item;
      return FeaturePage(
        title: 'homework.title',
        subtitle: item?.title ?? 'homework.subtitle',
        onRefresh: controller.load,
        child: ViewStateView(
          state: controller.state.value,
          onRetry: controller.load,
          errorKey: controller.errorMessage.value,
          child: item == null
              ? const SizedBox.shrink()
              : _HomeworkBody(item: item),
        ),
      );
    });
  }
}

class _HomeworkBody extends StatelessWidget {
  const _HomeworkBody({required this.item});

  final Homework item;

  @override
  Widget build(BuildContext context) {
    final studentId = Get.find<AuthService>().activeStudentId.value;
    final mine = studentId == null ? null : item.forStudent(studentId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: context.text.headlineSmall),
          const SizedBox(height: 8),
          SubjectChip(subject: item.subject),
          const SizedBox(height: 12),
          Text(item.description, style: context.text.bodyLarge),
          const SizedBox(height: 16),
          Text('homework.attachments'.tr, style: context.text.titleMedium),
          for (final file in item.attachments)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(PhosphorIconsRegular.filePdf),
              title: Text(file),
            ),
          if (mine?.feedback != null) ...[
            Text('homework.feedback'.tr, style: context.text.titleMedium),
            Text(mine!.feedback!, style: context.text.bodyMedium),
          ],
          if (mine?.marks != null)
            Text('${mine!.marks}/${item.maxMarks}', style: context.text.headlineMedium),
          const SizedBox(height: 20),
          if (mine == null || mine.status == HomeworkStatus.pending)
            PrimaryButton(
              label: 'homework.submit',
              onPressed: () => _sheet(item),
            ),
        ],
      ),
    );
  }

  Future<void> _sheet(Homework item) async {
    await showAppSheet<void>(
      child: AppBottomSheet(
        title: 'homework.submit',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SecondaryButton(
              label: 'homework.camera',
              icon: PhosphorIconsRegular.camera,
              onPressed: () => Get.find<HomeworkController>().submit(item, camera: true),
            ),
            const SizedBox(height: 8),
            SecondaryButton(
              label: 'homework.gallery',
              icon: PhosphorIconsRegular.image,
              onPressed: () => Get.find<HomeworkController>().submit(item, camera: false),
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'homework.sample',
              onPressed: () => Get.find<HomeworkController>().submit(item, camera: false),
            ),
          ],
        ),
      ),
    );
  }
}
