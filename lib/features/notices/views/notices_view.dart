import 'dart:async';

import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/formatters.dart';
import 'package:edunest/core/widgets/app_card.dart';
import 'package:edunest/core/widgets/chips.dart';
import 'package:edunest/core/widgets/feature_page.dart';
import 'package:edunest/core/widgets/states.dart';
import 'package:edunest/data/models/campus.dart';
import 'package:edunest/features/notices/controllers/notices_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class NoticesView extends GetView<NoticesController> {
  const NoticesView({super.key});

  @override
  Widget build(BuildContext context) {
    const filters = ['all', 'academic', 'exams', 'sports', 'fees', 'holiday', 'general'];
    return Obx(() {
      final wide = context.isWide;
      final _ = '${controller.state.value}${controller.filter.value}${controller.selectedId.value}';
      final list = _List(filters: filters, embedded: wide);
      if (!wide) {
        return FeaturePage(
          title: 'notices.title',
          subtitle: 'notices.subtitle',
          onRefresh: controller.load,
          child: list,
        );
      }
      final notice = controller.selected;
      return FeaturePage(
        title: 'notices.title',
        subtitle: 'notices.subtitle',
        onRefresh: controller.load,
        expand: true,
        child: Row(
          children: [
            SizedBox(width: 380, child: SingleChildScrollView(child: list)),
            VerticalDivider(width: 1, color: context.colors.outlineVariant),
            Expanded(
              child: notice == null
                  ? const EmptyState(title: 'empty.title', body: 'notices.subtitle')
                  : SingleChildScrollView(child: _NoticeBody(notice: notice)),
            ),
          ],
        ),
      );
    });
  }
}

class _List extends GetView<NoticesController> {
  const _List({required this.filters, required this.embedded});

  final List<String> filters;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final filter in filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SoftChip(
                      label: filter == 'all' ? 'notices.all' : 'cat.$filter',
                      selected: controller.filter.value == filter,
                      onTap: () => controller.filter.value = filter,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ViewStateView(
            state: controller.state.value,
            onRetry: controller.load,
            errorKey: controller.errorMessage.value,
            child: Column(
              children: [
                for (final notice in controller.visible)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      onTap: () {
                        if (embedded) {
                          controller.pick = notice.id;
                        } else {
                          unawaited(Get.toNamed<void>('/notices/${notice.id}'));
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (notice.pinned)
                                const Icon(PhosphorIconsFill.pushPin, size: 16),
                              const SizedBox(width: 6),
                              Text('cat.${notice.category}'.tr, style: context.text.bodySmall),
                            ],
                          ),
                          Text(notice.title, style: context.text.titleMedium),
                          Text(Formatters.dayMonth(notice.date), style: context.text.bodySmall),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeBody extends StatelessWidget {
  const _NoticeBody({required this.notice});

  final Notice notice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notice.title, style: context.text.headlineSmall),
          const SizedBox(height: 8),
          Text(notice.author, style: context.text.bodySmall),
          const SizedBox(height: 8),
          Text(notice.body, style: context.text.bodyLarge),
          for (final file in notice.attachments)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(PhosphorIconsRegular.paperclip),
              title: Text(file),
            ),
        ],
      ),
    );
  }
}

class NoticeDetailView extends GetView<NoticeDetailController> {
  const NoticeDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final notice = controller.notice;
      return FeaturePage(
        title: 'notices.title',
        subtitle: notice?.title ?? 'notices.subtitle',
        onRefresh: controller.load,
        child: ViewStateView(
          state: controller.state.value,
          onRetry: controller.load,
          errorKey: controller.errorMessage.value,
          child: notice == null
              ? const SizedBox.shrink()
              : _NoticeBody(notice: notice),
        ),
      );
    });
  }
}
