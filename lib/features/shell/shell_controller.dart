import 'dart:async';

import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/widgets/sheets.dart';
import 'package:edunest/data/models/user.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ShellController extends GetxController {
  final index = 0.obs;

  bool get isTeacher => Get.find<AuthService>().role == UserRole.teacher;

  void go(int value) => index.value = value;

  Future<void> onBack() async {
    if (index.value != 0) {
      index.value = 0;
      return;
    }
    final leave = await confirmSheet(
      title: 'shell.exit_title',
      body: 'shell.exit_body',
      confirm: 'shell.exit_confirm',
      danger: false,
    );
    if (leave) unawaited(SystemNavigator.pop());
  }
}
