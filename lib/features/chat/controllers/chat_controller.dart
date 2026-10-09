import 'dart:async';

import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/utils/loadable.dart';
import 'package:edunest/data/models/campus.dart';
import 'package:edunest/data/repositories/campus_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatListController extends GetxController with Loadable {
  List<ChatThread> threads = [];
  final previews = <String, ChatMessage>{};
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
    for (final message in bundle.messages) {
      final current = previews[message.threadId];
      if (current == null || message.sentAt.isAfter(current.sentAt)) {
        previews[message.threadId] = message;
      }
    }
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
    await Get.find<ChatRepository>().send(
      threadId: id,
      senderId: userId,
      text: value,
    );
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
