import 'dart:async';

import 'package:edunest/core/routes/app_routes.dart';
import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/utils/app_exception.dart';
import 'package:edunest/core/utils/loadable.dart';
import 'package:edunest/core/widgets/toast.dart';
import 'package:edunest/data/models/campus.dart';
import 'package:edunest/data/repositories/campus_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FeesController extends GetxController with Loadable {
  FeeAccount? account;

  @override
  Future<void> load() async {
    final id = Get.find<AuthService>().activeStudentId.value;
    if (id == null) {
      await run(() async {}, isEmpty: () => true);
      return;
    }
    await run(() async {
      account = await Get.find<FeeRepository>().forStudent(id);
    }, isEmpty: () => account == null);
  }

  Future<void> pay(Installment item, String method) async {
    final id = Get.find<AuthService>().activeStudentId.value;
    if (id == null) return;
    Get.back<void>();
    unawaited(
      Get.dialog<void>(
        const Center(child: _Processing()),
        barrierDismissible: false,
      ),
    );
    try {
      await Get.find<FeeRepository>().pay(
        studentId: id,
        installmentId: item.id,
        method: method,
      );
      if (Get.isDialogOpen ?? false) Get.back<void>();
      final receipt = Receipt(
        id: 'rcpt_${item.id}',
        installmentId: item.id,
        title: item.title,
        amount: item.amount,
        paidOn: DateTime.now(),
        method: method,
        reference: 'DEMO${DateTime.now().millisecondsSinceEpoch % 100000}',
      );
      await Get.toNamed<void>(AppRoutes.receipt, arguments: receipt);
    } on AppException catch (error) {
      if (Get.isDialogOpen ?? false) Get.back<void>();
      ToastHelper.show(error.message, kind: ToastKind.error);
    }
  }
}

class _Processing extends StatelessWidget {
  const _Processing();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text('fees.processing'.tr),
          ],
        ),
      ),
    );
  }
}
