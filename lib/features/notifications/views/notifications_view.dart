import 'dart:async';

import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/theme/app_colors.dart';
import 'package:edunest/core/theme/app_typography.dart';
import 'package:edunest/core/utils/app_exception.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/haptics.dart';
import 'package:edunest/core/utils/loadable.dart';
import 'package:edunest/core/widgets/glass.dart';
import 'package:edunest/core/widgets/page.dart';
import 'package:edunest/core/widgets/states.dart';
import 'package:edunest/core/widgets/toast.dart';
import 'package:edunest/core/widgets/ui.dart';
import 'package:edunest/data/models/campus.dart';
import 'package:edunest/data/models/user.dart';
import 'package:edunest/data/repositories/campus_repository.dart';
import 'package:edunest/data/repositories/directory_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _schoolTypes = {'general', 'event', 'notice'};

class NotificationsController extends GetxController with Loadable {
  List<AppNotification> items = [];

  /// First names of a parent's children, for the per-child filter.
  List<String> children = [];

  /// 'all', 'school' or a child's first name.
  final filter = 'all'.obs;

  /// Rows swiped away, hidden at once while the dismissal saves.
  final gone = <String>{}.obs;

  List<AppNotification> get visible {
    final f = filter.value;
    final list = items.where((n) => !gone.contains(n.id)).toList()..sort((a, b) => b.date.compareTo(a.date));
    if (f == 'all') return list;
    if (f == 'school') return list.where((n) => _schoolTypes.contains(n.type)).toList();
    return list.where((n) => '${n.title} ${n.body}'.contains(f)).toList();
  }

  int get unread => items.where((n) => !n.read && !gone.contains(n.id)).length;

  @override
  Future<void> load() async {
    final user = Get.find<AuthService>().user.value;
    if (user == null) {
      await run(() async {}, isEmpty: () => true);
      return;
    }
    await run(() async {
      items = await Get.find<NotificationRepository>().forUser(user.id);
      gone.clear();
      children = [];
      if (user.role == UserRole.parent) {
        final directory = Get.find<DirectoryRepository>();
        for (final id in user.childIds) {
          children.add((await directory.student(id)).name.split(' ').first);
        }
      }
    }, isEmpty: () => items.isEmpty);
  }

  Future<void> dismiss(AppNotification n) async {
    gone.add(n.id);
    try {
      await Get.find<NotificationRepository>().dismiss(n.id);
    } on AppException catch (error) {
      gone.remove(n.id);
      ToastHelper.show(error.message, kind: ToastKind.error);
    }
  }

  Future<void> readAll() async {
    final id = Get.find<AuthService>().user.value?.id;
    if (id == null) return;
    try {
      await Get.find<NotificationRepository>().markAllRead(id);
    } on AppException catch (error) {
      ToastHelper.show(error.message, kind: ToastKind.error);
    }
  }
}

({IconData? icon, String? glyph, Color fill, Color on, String label}) _kind(BuildContext context, String type) {
  final c = context.app;
  return switch (type) {
    'fees' => (icon: null, glyph: '₹', fill: c.badSoft, on: c.badText, label: 'notifications.t_fees'.tr),
    'homework' => (
      icon: PhosphorIconsRegular.fileText,
      glyph: null,
      fill: AppColors.subject('maths').fill,
      on: AppColors.subject('maths').on,
      label: 'notifications.t_homework'.tr,
    ),
    'attendance' => (
      icon: PhosphorIconsBold.check,
      glyph: null,
      fill: c.okSoft,
      on: AppColors.ok,
      label: 'notifications.t_attendance'.tr,
    ),
    'event' => (
      icon: PhosphorIconsRegular.calendarBlank,
      glyph: null,
      fill: AppColors.subject('science').fill,
      on: AppColors.subject('science').on,
      label: 'notifications.t_event'.tr,
    ),
    'results' => (
      icon: PhosphorIconsRegular.trophy,
      glyph: null,
      fill: c.mariSoft,
      on: c.mariText,
      label: 'notifications.t_results'.tr,
    ),
    _ => (
      icon: PhosphorIconsRegular.chatCircle,
      glyph: null,
      fill: c.paper2,
      on: c.ink2,
      label: 'notifications.t_school'.tr,
    ),
  };
}

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.filter.value;
      controller.gone.length;
      final list = controller.visible;
      final today = DateUtils.dateOnly(DateTime.now());
      final weekAgo = today.subtract(const Duration(days: 6));
      final groups = <(String, List<AppNotification>)>[
        ('notifications.today', list.where((n) => !n.date.isBefore(today)).toList()),
        ('notifications.this_week', list.where((n) => n.date.isBefore(today) && !n.date.isBefore(weekAgo)).toList()),
        ('notifications.earlier', list.where((n) => n.date.isBefore(weekAgo)).toList()),
      ].where((g) => g.$2.isNotEmpty).toList();
      final filters = [
        'all',
        ...controller.children,
        if (controller.items.any((n) => _schoolTypes.contains(n.type))) 'school',
      ];
      return PageFrame(
        leading: const BackGlass(),
        actions: [
          if (controller.unread > 0)
            GlassPress(
              onTap: () => unawaited(controller.readAll()),
              child: Semantics(
                button: true,
                child: Glass(
                  height: 44,
                  width: 132,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIconsBold.check, size: 15, color: context.app.ink),
                      const SizedBox(width: 6),
                      Text('notifications.read_all'.tr, style: anek(14, 650, height: 1, color: context.app.ink)),
                    ],
                  ),
                ),
              ),
            ),
        ],
        topPadding: MediaQuery.paddingOf(context).top + 60,
        onRefresh: controller.load,
        children: [
          const Rise(child: PageTitle('notifications.title')),
          ViewStateView(
            state: controller.state.value,
            onRetry: controller.load,
            errorKey: controller.errorMessage.value,
            emptyTitle: 'notifications.empty',
            emptyBody: 'notifications.empty_body',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (filters.length > 1) ...[
                  const SizedBox(height: 14),
                  Rise(
                    index: 1,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final f in filters)
                          Semantics(
                            selected: controller.filter.value == f,
                            child: Chip2(
                              f == 'all'
                                  ? 'notifications.all_n'.trParams({
                                      'n': '${controller.items.length - controller.gone.length}',
                                    })
                                  : f == 'school'
                                  ? 'notifications.school'.tr
                                  : f,
                              on: controller.filter.value == f,
                              onTap: () => controller.filter.value = f,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (groups.isEmpty)
                  const EmptyState(title: 'notifications.none_here', body: 'notifications.none_here_body'),
                for (var g = 0; g < groups.length; g++) ...[
                  Rise(index: 2 + g, child: SectionLabel(groups[g].$1.tr, top: 20)),
                  Rise(
                    index: 2 + g,
                    child: EduCard(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Column(
                          children: [
                            for (var i = 0; i < groups[g].$2.length; i++) ...[
                              if (i > 0) const Hr(),
                              _Row(
                                item: groups[g].$2[i],
                                controller: controller,
                                today: g == 0 && groups[g].$1 == 'notifications.today',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.controller, required this.today});

  final AppNotification item;
  final NotificationsController controller;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    final kind = _kind(context, item.type);
    final when = today ? DateFormat('H:mm').format(item.date) : DateFormat('EEE d MMM').format(item.date);
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onUpdate: (d) {
        if (d.reached && !d.previousReached) Haptics.selection();
      },
      onDismissed: (_) => unawaited(controller.dismiss(item)),
      background: ColoredBox(
        color: AppColors.bad,
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Glass(
              width: 76,
              height: 52,
              radius: 26,
              kind: GlassKind.lens,
              tint: const Color(0x1FFFFFFF),
              shadow: false,
              child: Icon(
                PhosphorIconsRegular.trash,
                color: AppColors.white,
                semanticLabel: 'notifications.dismiss'.tr,
              ),
            ),
          ),
        ),
      ),
      child: Semantics(
        button: true,
        label: '${item.read ? '' : '${'notifications.unread'.tr}, '}${item.title}, ${item.body}',
        excludeSemantics: true,
        customSemanticsActions: {
          CustomSemanticsAction(label: 'notifications.dismiss'.tr): () => unawaited(controller.dismiss(item)),
        },
        child: Material(
          color: c.paper,
          child: InkWell(
            onTap: () => Get.toNamed<void>(item.route),
            child: Stack(
              children: [
                if (!item.read) const Positioned(left: 5, top: 28, child: Dot(AppColors.mari, size: 7)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: kind.fill, borderRadius: BorderRadius.circular(13)),
                        child: kind.glyph != null
                            ? Text(kind.glyph!, style: anek(18, 700, height: 1, color: kind.on))
                            : Icon(kind.icon, size: 18, color: kind.on),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: context.type.t),
                            const SizedBox(height: 2),
                            Text(item.body, style: context.type.s, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('$when · ${kind.label}', style: context.type.cap),
                          ],
                        ),
                      ),
                    ],
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
