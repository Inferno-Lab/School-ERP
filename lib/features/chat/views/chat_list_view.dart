import 'dart:async';

import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/formatters.dart';
import 'package:edunest/core/widgets/app_avatar.dart';
import 'package:edunest/core/widgets/feature_page.dart';
import 'package:edunest/core/widgets/states.dart';
import 'package:edunest/features/chat/controllers/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ChatListView extends GetView<ChatListController> {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = '${controller.state.value}${controller.selectedId.value}${controller.threads.length}';
      final list = ViewStateView(
          state: controller.state.value,
          onRetry: controller.load,
          errorKey: controller.errorMessage.value,
          child: ListView.separated(
            shrinkWrap: !context.isWide,
            physics: context.isWide
                ? const AlwaysScrollableScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
            itemCount: controller.threads.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final thread = controller.threads[index];
              final preview = controller.previews[thread.id];
              return ListTile(
                selected: context.isWide && controller.activeId == thread.id,
                onTap: () {
                  if (context.isWide) {
                    controller.pick = thread.id;
                  } else {
                    unawaited(Get.toNamed<void>('/chat/${thread.id}'));
                  }
                },
                leading: Stack(
                  children: [
                    AppAvatar(name: thread.title, url: thread.avatarUrl),
                    if (thread.online)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: context.app.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: context.colors.surface, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(thread.title, style: context.text.titleMedium),
                subtitle: Text(
                  preview?.text ?? thread.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: preview == null
                    ? null
                    : Text(Formatters.timeOf(preview.sentAt), style: context.text.bodySmall),
              );
            },
          ),
        );
      if (!context.isWide) {
        return FeaturePage(
          title: 'chat.title',
          subtitle: 'chat.subtitle',
          onRefresh: controller.load,
          child: list,
        );
      }
      final id = controller.activeId;
      return FeaturePage(
        title: 'chat.title',
        subtitle: 'chat.subtitle',
        onRefresh: controller.load,
        expand: true,
        child: Row(
          children: [
            SizedBox(width: 360, child: list),
            VerticalDivider(width: 1, color: context.colors.outlineVariant),
            Expanded(
              child: id == null
                  ? const EmptyState(title: 'empty.title', body: 'chat.subtitle')
                  : _PaneThread(id: id),
            ),
          ],
        ),
      );
    });
  }
}

class _PaneThread extends StatefulWidget {
  const _PaneThread({required this.id});

  final String id;

  @override
  State<_PaneThread> createState() => _PaneThreadState();
}

class _PaneThreadState extends State<_PaneThread> {
  late final ChatThreadController thread;

  @override
  void initState() {
    super.initState();
    thread = Get.put(ChatThreadController(), tag: 'pane');
    thread.focus(widget.id);
  }

  @override
  void didUpdateWidget(covariant _PaneThread oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) thread.focus(widget.id);
  }

  @override
  void dispose() {
    unawaited(Get.delete<ChatThreadController>(tag: 'pane'));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatConversation(controller: thread, showAppBar: false);
  }
}

class ChatThreadView extends GetView<ChatThreadController> {
  const ChatThreadView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChatConversation(controller: controller);
  }
}

class ChatConversation extends StatelessWidget {
  const ChatConversation({required this.controller, this.showAppBar = true, super.key});

  final ChatThreadController controller;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final me = Get.find<AuthService>().user.value?.id;
    return Scaffold(
      appBar: showAppBar
          ? AppBar(title: Obx(() => Text(controller.thread?.title ?? 'chat.title'.tr)))
          : null,
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              final messages = controller.messages;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length + (controller.typing.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= messages.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text('chat.typing'.tr, style: context.text.bodySmall),
                    );
                  }
                  final message = messages[index];
                  final mine = message.senderId == me;
                  return Align(
                    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.74),
                      decoration: BoxDecoration(
                        color: mine
                            ? context.colors.primary
                            : context.colors.surfaceContainer,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(mine ? 18 : 4),
                          bottomRight: Radius.circular(mine ? 4 : 18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            message.text,
                            style: context.text.bodyMedium?.copyWith(
                              color: mine ? context.colors.onPrimary : context.colors.onSurface,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                Formatters.timeOf(message.sentAt),
                                style: context.text.bodySmall?.copyWith(
                                  color: mine
                                      ? context.colors.onPrimary.withValues(alpha: 0.8)
                                      : context.colors.onSurfaceVariant,
                                ),
                              ),
                              if (mine) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  message.read
                                      ? PhosphorIconsFill.checks
                                      : PhosphorIconsRegular.check,
                                  size: 14,
                                  color: context.colors.onPrimary,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.text,
                      decoration: InputDecoration(hintText: 'chat.hint'.tr),
                      onSubmitted: (_) => controller.send(),
                    ),
                  ),
                  IconButton(
                    onPressed: controller.send,
                    icon: Icon(PhosphorIconsFill.paperPlaneRight, color: context.colors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
