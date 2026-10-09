import 'dart:async';

import 'package:edunest/core/routes/app_routes.dart';
import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/services/storage_service.dart';
import 'package:edunest/core/services/theme_service.dart';
import 'package:edunest/core/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    Future<void>.delayed(const Duration(milliseconds: 1500), _go);
  }

  void _go() {
    final seen =
        Get.find<StorageService>().read<bool>(StorageKeys.onboardingSeen) ??
        false;
    if (!seen) {
      unawaited(Get.offAllNamed<void>(AppRoutes.onboarding));
      return;
    }
    if (Get.find<AuthService>().isLoggedIn) {
      unawaited(Get.offAllNamed<void>(AppRoutes.shell));
      return;
    }
    unawaited(Get.offAllNamed<void>(AppRoutes.login));
  }
}

class OnboardingController extends GetxController {
  final page = 0.obs;
  final controller = PageController();

  Future<void> next() async {
    if (page.value < 2) {
      await controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await finish();
  }

  Future<void> finish() async {
    await Get.find<StorageService>().write(StorageKeys.onboardingSeen, true);
    unawaited(Get.offAllNamed<void>(AppRoutes.login));
  }

  @override
  void onClose() {
    controller.dispose();
    super.onClose();
  }
}
