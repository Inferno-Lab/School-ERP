import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/utils/app_exception.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/formatters.dart';
import 'package:edunest/core/utils/loadable.dart';
import 'package:edunest/core/utils/validators.dart';
import 'package:edunest/core/widgets/app_text_field.dart';
import 'package:edunest/core/widgets/buttons.dart';
import 'package:edunest/core/widgets/chips.dart';
import 'package:edunest/core/widgets/feature_page.dart';
import 'package:edunest/core/widgets/misc.dart';
import 'package:edunest/core/widgets/states.dart';
import 'package:edunest/core/widgets/toast.dart';
import 'package:edunest/data/models/campus.dart';
import 'package:edunest/data/repositories/campus_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LeaveController extends GetxController with Loadable {
  List<LeaveRequest> items = [];

  @override
  Future<void> load() async {
    final id = Get.find<AuthService>().activeStudentId.value;
    if (id == null) {
      await run(() async {}, isEmpty: () => true);
      return;
    }
    await run(() async {
      items = await Get.find<LeaveRepository>().forStudent(id);
      items.sort((a, b) => b.appliedOn.compareTo(a.appliedOn));
    }, isEmpty: () => false);
  }
}

class LeaveView extends GetView<LeaveController> {
  const LeaveView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => FeaturePage(
        title: 'leave.title',
        subtitle: 'leave.subtitle',
        onRefresh: controller.load,
        floating: FloatingActionButton.extended(
          onPressed: () => Get.toNamed<void>('/leave/apply'),
          label: Text('leave.new'.tr),
        ),
        child: ViewStateView(
          state: controller.state.value,
          onRetry: controller.load,
          errorKey: controller.errorMessage.value,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            child: Column(
              children: [
                if (controller.items.isEmpty)
                  const EmptyState(title: 'empty.title', body: 'leave.subtitle'),
                for (final item in controller.items)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(item.reason, style: context.text.titleMedium)),
                              attendanceBadge(context, item.status.name),
                            ],
                          ),
                          Text(
                            '${Formatters.fullDate(item.from)} – ${Formatters.fullDate(item.to)}',
                            style: context.text.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          TimelineTile(
                            title: 'status.pending',
                            subtitle: Formatters.fullDate(item.appliedOn),
                            done: true,
                          ),
                          TimelineTile(
                            title: item.status == LeaveStatus.rejected
                                ? 'status.rejected'
                                : 'status.approved',
                            subtitle: item.reviewNote ?? item.reviewedBy ?? 'status.pending'.tr,
                            done: item.status != LeaveStatus.pending,
                            last: true,
                            color: item.status == LeaveStatus.rejected
                                ? context.app.danger
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LeaveApplyController extends GetxController {
  final reason = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final from = DateTime.now().add(const Duration(days: 1)).obs;
  final to = DateTime.now().add(const Duration(days: 1)).obs;
  final saving = false.obs;

  Future<void> pick({required bool start}) async {
    final picked = await showDatePicker(
      context: Get.context!,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      initialDate: start ? from.value : to.value,
    );
    if (picked == null) return;
    if (start) {
      from.value = picked;
      if (to.value.isBefore(picked)) to.value = picked;
    } else {
      to.value = picked;
    }
  }

  Future<void> submit() async {
    if (saving.value) return;
    if (formKey.currentState?.validate() != true) return;
    final id = Get.find<AuthService>().activeStudentId.value;
    if (id == null) return;
    saving.value = true;
    try {
      await Get.find<LeaveRepository>().apply(
        LeaveRequest(
          id: 'lv_${DateTime.now().microsecondsSinceEpoch}',
          studentId: id,
          from: from.value,
          to: to.value,
          reason: reason.text.trim(),
          status: LeaveStatus.pending,
          appliedOn: DateTime.now(),
        ),
      );
      ToastHelper.show('leave.sent', kind: ToastKind.success);
      Get.back<void>();
    } on AppException catch (error) {
      ToastHelper.show(error.message, kind: ToastKind.error);
    } finally {
      saving.value = false;
    }
  }

  @override
  void onClose() {
    reason.dispose();
    super.onClose();
  }
}

class LeaveApplyView extends GetView<LeaveApplyController> {
  const LeaveApplyView({super.key});

  @override
  Widget build(BuildContext context) {
    return FeaturePage(
      title: 'leave.new',
      subtitle: 'leave.subtitle',
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              Obx(
                () => ListTile(
                  title: Text('leave.from'.tr),
                  subtitle: Text(Formatters.fullDate(controller.from.value)),
                  onTap: () => controller.pick(start: true),
                ),
              ),
              Obx(
                () => ListTile(
                  title: Text('leave.to'.tr),
                  subtitle: Text(Formatters.fullDate(controller.to.value)),
                  onTap: () => controller.pick(start: false),
                ),
              ),
              AppTextField(
                label: 'leave.reason',
                controller: controller.reason,
                validator: Validators.required,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              Obx(
                () => PrimaryButton(
                  label: 'common.submit',
                  loading: controller.saving.value,
                  onPressed: controller.submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
