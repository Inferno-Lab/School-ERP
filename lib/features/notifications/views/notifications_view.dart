import 'dart:async';

import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/formatters.dart';
import 'package:edunest/core/utils/loadable.dart';
import 'package:edunest/core/widgets/feature_page.dart';
import 'package:edunest/core/widgets/states.dart';
import 'package:edunest/data/models/campus.dart';
import 'package:edunest/data/repositories/campus_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class NotificationsController extends GetxController with Loadable {
  List<AppNotification> items = [];
  final selectedId = RxnString();

  String? get pick => selectedId.value;

  set pick(String? id) => selectedId.value = id;

  AppNotification? get selected {
    final id = selectedId.value;
    if (id != null) {
      for (final item in items) {
        if (item.id == id) return item;
      }
    }
    return items.firstOrNull;
  }

  @override
  Future<void> load() async {
    final id = Get.find<AuthService>().user.value?.id;
    if (id == null) {
      await run(() async {}, isEmpty: () => true);
      return;
    }
    await run(() async {
      items = await Get.find<NotificationRepository>().forUser(id);
    }, isEmpty: () => items.isEmpty);
  }

  Future<void> dismiss(String id) => Get.find<NotificationRepository>().dismiss(id);

  Future<void> readAll() async {
    final id = Get.find<AuthService>().user.value?.id;
    if (id == null) return;
    await Get.find<NotificationRepository>().markAllRead(id);
  }
}

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final today = <AppNotification>[];
      final earlier = <AppNotification>[];
      final now = DateTime.now();
      for (final item in controller.items) {
        if (item.date.year == now.year && item.date.month == now.month && item.date.day == now.day) {
          today.add(item);
        } else {
          earlier.add(item);
        }
      }
      final body = ViewStateView(
          state: controller.state.value,
          onRetry: controller.load,
          errorKey: controller.errorMessage.value,
          emptyTitle: 'notifications.empty',
          emptyBody: 'notifications.subtitle',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (today.isNotEmpty) ...[
                  Text('notifications.today'.tr, style: context.text.headlineSmall),
                  for (final item in today) _Tile(item: item),
                ],
                if (earlier.isNotEmpty) ...[
                  Text('notifications.earlier'.tr, style: context.text.headlineSmall),
                  for (final item in earlier) _Tile(item: item),
                ],
              ],
            ),
          ),
        );
      final actions = [
        IconButton(
          onPressed: controller.readAll,
          icon: const Icon(PhosphorIconsRegular.checks),
          tooltip: 'notifications.read'.tr,
        ),
      ];
      if (!context.isWide) {
        return FeaturePage(
          title: 'notifications.title',
          subtitle: 'notifications.subtitle',
          onRefresh: controller.load,
          actions: actions,
          child: body,
        );
      }
      final selected = controller.selected;
      return FeaturePage(
        title: 'notifications.title',
        subtitle: 'notifications.subtitle',
        onRefresh: controller.load,
        actions: actions,
        expand: true,
        child: Row(
          children: [
            SizedBox(width: 420, child: SingleChildScrollView(child: body)),
            VerticalDivider(width: 1, color: context.colors.outlineVariant),
            Expanded(
              child: selected == null
                  ? const EmptyState(title: 'notifications.empty', body: 'notifications.subtitle')
                  : _Preview(item: selected),
            ),
          ],
        ),
      );
    });
  }
}

class _Tile extends GetView<NotificationsController> {
  const _Tile({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      onDismissed: (_) => controller.dismiss(item.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: context.app.dangerContainer,
        child: Icon(PhosphorIconsRegular.trash, color: context.app.danger),
      ),
      child: ListTile(
        title: Text(
          item.title,
          style: context.text.titleMedium?.copyWith(
            fontWeight: item.read ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Text(item.body),
        trailing: Text(Formatters.timeOf(item.date), style: context.text.bodySmall),
        selected: context.isWide && controller.selectedId.value == item.id,
        onTap: () {
          controller.pick = item.id;
          if (!context.isWide) unawaited(Get.toNamed<void>(item.route));
        },
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: context.text.headlineSmall),
          const SizedBox(height: 8),
          Text(Formatters.dayMonth(item.date), style: context.text.bodySmall),
          const SizedBox(height: 16),
          Text(item.body, style: context.text.bodyLarge),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Get.toNamed<void>(item.route),
            child: Text('notifications.open'.tr),
          ),
        ],
      ),
    );
  }
}
