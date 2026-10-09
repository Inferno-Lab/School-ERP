import 'package:edunest/core/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum ToastKind { success, error, info }

abstract final class ToastHelper {
  static void show(String messageKey, {ToastKind kind = ToastKind.info}) {
    if (Get.testMode) return;
    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;
    final app = context.app;
    final (icon, color, background) = switch (kind) {
      ToastKind.success => (
        PhosphorIconsFill.checkCircle,
        app.success,
        app.successContainer,
      ),
      ToastKind.error => (
        PhosphorIconsFill.warningCircle,
        app.danger,
        app.dangerContainer,
      ),
      ToastKind.info => (
        PhosphorIconsFill.info,
        app.info,
        app.infoContainer,
      ),
    };
    Get.snackbar(
      '',
      '',
      titleText: const SizedBox.shrink(),
      messageText: Text(
        messageKey.tr,
        style: context.text.bodyMedium?.copyWith(color: color),
      ),
      icon: Icon(icon, color: color),
      backgroundColor: background,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
    );
  }
}
