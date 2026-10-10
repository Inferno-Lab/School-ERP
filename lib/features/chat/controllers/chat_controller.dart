import 'dart:async';

import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/utils/app_exception.dart';
import 'package:edunest/core/utils/loadable.dart';
import 'package:edunest/core/widgets/toast.dart';
import 'package:edunest/data/models/campus.dart';
import 'package:edunest/data/repositories/campus_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatListController extends GetxController with Loadable {
  List<ChatThread> threads = [];
  final previews = <String, ChatMessage>{};
  final unreadBy = <String, int>{};
  final unread = 0.obs;
  final selectedId = RxnString();

  String? get pick => selectedId.value;

  set pick(String? id) => selectedId.value = id;

  String? get activeId => selectedId.value ?? threads.firstOrNull?.id;

  @override
  Future<void> load() => run(() async {
    final userId = Get.find<AuthService>().user.value?.id;
    if (userId == null) return;
    final bundle = await Get.find<ChatRepository>().inbox(userId);
    threads = bundle.threads;
    unreadBy.clear();
    for (final message in bundle.messages) {
      if (!message.read && message.senderId != userId) {
        unreadBy[message.threadId] = (unreadBy[message.threadId] ?? 0) + 1;
      }
      final current = previews[message.threadId];
      if (current == null || message.sentAt.isAfter(current.sentAt)) {
        previews[message.threadId] = message;
      }
    }
    unread.value = unreadBy.values.fold(0, (a, b) => a + b);
  }, isEmpty: () => threads.isEmpty);
}

class ChatThreadController extends GetxController with Loadable {
  final text = TextEditingController();
  final typing = false.obs;
  List<ChatMessage> messages = [];
  ChatThread? thread;
  String? pinnedId;

  void focus(String id) {
    pinnedId = id;
    unawaited(load());
  }

  @override
  Future<void> load() => run(() async {
    final id = pinnedId ?? Get.parameters['id'];
    if (id == null) return;
    final userId = Get.find<AuthService>().user.value?.id ?? '';
    final threads = await Get.find<ChatRepository>().threadsFor(userId);
    for (final item in threads) {
      if (item.id == id) thread = item;
    }
    messages = await Get.find<ChatRepository>().messages(id);
    typing.value = false;
  }, isEmpty: () => false);

  Future<void> send() async {
    final value = text.text.trim();
    final id = thread?.id;
    final userId = Get.find<AuthService>().user.value?.id;
    if (value.isEmpty || id == null || userId == null) return;
    text.clear();
    typing.value = true;
    try {
      await Get.find<ChatRepository>().send(
        threadId: id,
        senderId: userId,
        text: value,
      );
    } on AppException catch (error) {
      text.text = value;
      typing.value = false;
      ToastHelper.show(error.message, kind: ToastKind.error);
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (!isClosed) typing.value = false;
    });
  }

  @override
  void onClose() {
    text.dispose();
    super.onClose();
  }
}
