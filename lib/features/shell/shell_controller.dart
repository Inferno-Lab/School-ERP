import 'dart:async';

import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/widgets/app_bottom_sheet.dart';
import 'package:edunest/data/models/user.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ShellController extends GetxController {
  final index = 0.obs;

  bool get isTeacher => Get.find<AuthService>().role == UserRole.teacher;

  Future<void> onBack() async {
    if (index.value != 0) {
      index.value = 0;
      return;
    }
    final leave = await confirmSheet(
      title: 'common.logout',
      body: 'settings.logout_body',
      confirm: 'common.done',
    );
    if (leave) unawaited(SystemNavigator.pop());
  }
}
