import 'package:edunest/core/utils/app_exception.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/formatters.dart';
import 'package:edunest/core/utils/validators.dart';
import 'package:edunest/core/widgets/app_avatar.dart';
import 'package:edunest/core/widgets/app_bottom_sheet.dart';
import 'package:edunest/core/widgets/app_text_field.dart';
import 'package:edunest/core/widgets/buttons.dart';
import 'package:edunest/core/widgets/feature_page.dart';
import 'package:edunest/core/widgets/states.dart';
import 'package:edunest/data/models/academics.dart';
import 'package:edunest/data/models/student.dart';
import 'package:edunest/data/repositories/directory_repository.dart';
import 'package:edunest/features/teacher_tools/controllers/teacher_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class MarkAttendanceView extends GetView<MarkAttendanceController> {
  const MarkAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final present = controller.marks.values.where((s) => s == AttendanceStatus.present).length;
      final absent = controller.marks.values.where((s) => s == AttendanceStatus.absent).length;
      final late = controller.marks.values.where((s) => s == AttendanceStatus.lateArrival).length;
      return FeaturePage(
        title: 'teacher.mark',
        subtitle: '${'teacher.present'.tr} $present · ${'teacher.absent'.tr} $absent · ${'teacher.late'.tr} $late',
        onRefresh: controller.load,
        child: ViewStateView(
          state: controller.state.value,
          onRetry: controller.load,
          errorKey: controller.errorMessage.value,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SecondaryButton(
                  label: 'teacher.all_present',
                  onPressed: controller.allPresent,
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: controller.students.length,
                itemBuilder: (context, index) {
                  final student = controller.students[index];
                  final status = controller.marks[student.id];
                  final color = switch (status) {
                    AttendanceStatus.present => context.app.success,
                    AttendanceStatus.absent => context.app.danger,
                    AttendanceStatus.lateArrival => context.app.warning,
                    _ => context.colors.outline,
                  };
                  return InkWell(
                    onTap: () => controller.cycle(student.id),
                    borderRadius: BorderRadius.circular(20),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppAvatar(name: student.name, url: student.avatarUrl, size: 56),
                          const SizedBox(height: 8),
                          Text(student.name, textAlign: TextAlign.center),
                          Text(
                            switch (status) {
                              AttendanceStatus.present => 'status.present'.tr,
                              AttendanceStatus.absent => 'status.absent'.tr,
                              AttendanceStatus.lateArrival => 'status.late'.tr,
                              _ => 'teacher.mark'.tr,
                            },
                            style: TextStyle(color: color),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: PrimaryButton(
                  label: 'teacher.submit_attendance',
                  loading: controller.saving.value,
                  onPressed: controller.submit,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class AssignHomeworkView extends GetView<AssignHomeworkController> {
  const AssignHomeworkView({super.key});

  @override
  Widget build(BuildContext context) {
    final classId = Get.arguments as String? ?? 'cls_8a';
    return FeaturePage(
      title: 'teacher.assign',
      subtitle: 'teacher.subject',
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              Obx(
                () => DropdownButtonFormField<String>(
                  initialValue: controller.subject.value,
                  items: [
                    for (final subject in ['maths', 'science', 'english', 'hindi', 'social'])
                      DropdownMenuItem(value: subject, child: Text('subject.$subject'.tr)),
                  ],
                  onChanged: (value) {
                    if (value != null) controller.subject.value = value;
                  },
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'teacher.title_field',
                controller: controller.title,
                validator: Validators.required,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'teacher.body_field',
                controller: controller.body,
                validator: Validators.required,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              Obx(
                () => ListTile(
                  title: Text('teacher.due'.tr),
                  subtitle: Text(Formatters.fullDate(controller.due.value)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                      initialDate: controller.due.value,
                    );
                    if (picked != null) controller.due.value = picked;
                  },
                ),
              ),
              Obx(
                () => PrimaryButton(
                  label: 'common.submit',
                  loading: controller.saving.value,
                  onPressed: () => controller.submit(classId),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GradingView extends GetView<GradingController> {
  const GradingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => FeaturePage(
        title: 'teacher.grade',
        subtitle: 'homework.submitted',
        onRefresh: controller.load,
        child: ViewStateView(
          state: controller.state.value,
          onRetry: controller.load,
          errorKey: controller.errorMessage.value,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                for (final homework in controller.items)
                  for (final submission in homework.submissions)
                    if (submission.status == HomeworkStatus.submitted)
                      ListTile(
                        title: Text(homework.title),
                        subtitle: Text(submission.studentId),
                        trailing: Text('common.submit'.tr),
                        onTap: () => _grade(homework, submission.studentId),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _grade(Homework homework, String studentId) async {
    final marks = TextEditingController();
    final feedback = TextEditingController(text: 'Clear working. Reviewed in class.');
    Student? student;
    try {
      student = await Get.find<DirectoryRepository>().student(studentId);
    } on AppException {
      student = null;
    }
    await showAppSheet<void>(
      child: AppBottomSheet(
        title: student?.name ?? studentId,
        child: Column(
          children: [
            TextField(
              controller: marks,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: '0–${homework.maxMarks}'),
            ),
            const SizedBox(height: 8),
            TextField(controller: feedback, decoration: InputDecoration(labelText: 'homework.feedback'.tr)),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'common.save',
              onPressed: () async {
                final value = int.tryParse(marks.text) ?? 0;
                await controller.grade(
                  homework: homework,
                  studentId: studentId,
                  marks: value.clamp(0, homework.maxMarks),
                  feedback: feedback.text,
                );
                Get.back<void>();
              },
            ),
          ],
        ),
      ),
    );
    marks.dispose();
    feedback.dispose();
  }
}

class MarksEntryView extends GetView<MarksEntryController> {
  const MarksEntryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => FeaturePage(
        title: 'teacher.marks',
        subtitle: 'subject.${controller.subject.value}',
        child: ViewStateView(
          state: controller.state.value,
          onRetry: controller.load,
          errorKey: controller.errorMessage.value,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                for (final student in controller.students)
                  ListTile(
                    title: Text(student.name),
                    trailing: SizedBox(
                      width: 72,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          hintText: '${controller.values[student.id] ?? ''}',
                        ),
                        onChanged: (value) {
                          final parsed = int.tryParse(value);
                          if (parsed == null) return;
                          controller.values[student.id] = parsed.clamp(0, 50);
                        },
                      ),
                    ),
                  ),
                PrimaryButton(label: 'common.save', onPressed: controller.save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PostNoticeView extends GetView<PostNoticeController> {
  const PostNoticeView({super.key});

  @override
  Widget build(BuildContext context) {
    return FeaturePage(
      title: 'teacher.notice',
      subtitle: 'teacher.audience',
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              AppTextField(
                label: 'teacher.title_field',
                controller: controller.title,
                validator: Validators.required,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'teacher.body_field',
                controller: controller.body,
                validator: Validators.required,
                maxLines: 5,
              ),
              Obx(
                () => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('notices.pinned'.tr),
                  value: controller.pinned.value,
                  onChanged: (value) => controller.pinned.value = value,
                ),
              ),
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
