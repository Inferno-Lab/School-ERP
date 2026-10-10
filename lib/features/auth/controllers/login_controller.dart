import 'dart:async';

import 'package:edunest/core/config/app_config.dart';
import 'package:edunest/core/routes/app_routes.dart';
import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/utils/app_exception.dart';
import 'package:edunest/core/widgets/toast.dart';
import 'package:edunest/data/models/user.dart';
import 'package:edunest/data/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final email = TextEditingController(text: 'aarav.sharma@edunest.app');
  final password = TextEditingController(text: AppConfig.demoPassword);
  final otp = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final loading = false.obs;
  final useOtp = false.obs;
  /// Demo role picked on the login shelf; none until the user taps one.
  final demoRole = Rxn<UserRole>();

  Future<void> demo(UserRole role) => _enter(
    () => Get.find<AuthRepository>().loginAs(role),
  );

  Future<void> submit() async {
    if (formKey.currentState?.validate() != true) return;
    if (useOtp.value) {
      await _enter(
        () => Get.find<AuthRepository>().loginWithOtp(
          email: email.text,
          otp: otp.text,
        ),
      );
      return;
    }
    await _enter(
      () => Get.find<AuthRepository>().login(
        email: email.text,
        password: password.text,
      ),
    );
  }

  Future<void> _enter(Future<AppUser> Function() action) async {
    if (loading.value) return;
    loading.value = true;
    try {
      final user = await action();
      await Get.find<AuthService>().setSession(user);
      unawaited(Get.offAllNamed<void>(AppRoutes.shell));
    } on AppException catch (error) {
      ToastHelper.show(error.message, kind: ToastKind.error);
    } finally {
      loading.value = false;
    }
  }

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    otp.dispose();
    super.onClose();
  }
}
