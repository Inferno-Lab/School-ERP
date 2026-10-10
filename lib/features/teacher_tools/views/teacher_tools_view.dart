import 'dart:async';

import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/theme/app_colors.dart';
import 'package:edunest/core/theme/app_typography.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/haptics.dart';
import 'package:edunest/core/widgets/glass.dart';
import 'package:edunest/core/widgets/glass_controls.dart';
import 'package:edunest/core/widgets/page.dart';
import 'package:edunest/core/widgets/states.dart';
import 'package:edunest/core/widgets/toast.dart';
import 'package:edunest/core/widgets/ui.dart';
import 'package:edunest/data/models/academics.dart';
import 'package:edunest/data/models/student.dart';
import 'package:edunest/features/teacher_tools/controllers/teacher_controller.dart';
import 'package:edunest/core/widgets/empty_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _houses = {
  'Emerald': Color(0xFF23784A),
  'Sapphire': Color(0xFF2F5BD3),
  'Ruby': Color(0xFFB8306F),
  'Amber': Color(0xFFE0A81E),
};

/// Glass bar with a line of text and one action, used across teacher tools.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.text,
    required this.action,
    this.sub,
    this.kind = BtnKind.primary,
    this.onPressed,
    this.loading = false,
    this.icon,
  });

  final Widget text;
  final String? sub;
  final String action;
  final BtnKind kind;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Glass(
    height: 64,
    radius: 32,
    padding: const EdgeInsets.only(left: 20, right: 8),
    child: Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sub != null) Text(sub!, style: context.type.cap.copyWith(fontSize: 11.5)),
              DefaultTextStyle.merge(maxLines: 1, overflow: TextOverflow.ellipsis, child: text),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Btn(action, kind: kind, height: 48, loading: loading, onPressed: onPressed, trailing: icon),
      ],
    ),
  );
}

// ───────────────────────────── Mark attendance ─────────────────────────────

class MarkAttendanceView extends GetView<MarkAttendanceController> {
  const MarkAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    final late = c.dark ? const Color(0xFFF6BA45) : AppColors.late;
    return Obx(() {
      controller.marks.length;
      final cls = controller.schoolClass;
      return PageFrame(
        leading: const BackGlass(),
        actions: [
          GlassPress(
            onTap: controller.allPresent,
            child: Semantics(
              button: true,
              child: Glass(
                height: 44,
                width: 150,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIconsRegular.arrowCounterClockwise, size: 15, color: c.ink),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'teacher.all_present'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: anek(14, 650, height: 1, color: c.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        topPadding: MediaQuery.paddingOf(context).top + 60,
        padContent: false,
        bottomBar: controller.students.isEmpty
            ? null
            : Semantics(
                liveRegion: true,
                child: _ActionBar(
                  text: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'teacher.n_present'.trp({'n': '${controller.present}'})),
                        if (controller.absent > 0)
                          TextSpan(
                            text: ' · ${'teacher.n_absent'.trp({'n': '${controller.absent}'})}',
                            style: TextStyle(color: c.badText),
                          ),
                        if (controller.late > 0)
                          TextSpan(
                            text: ' · ${'teacher.n_late'.trp({'n': '${controller.late}'})}',
                            style: TextStyle(color: late),
                          ),
                      ],
                    ),
                    style: anek(15, 680, height: 1.2, tabular: true, color: c.ink),
                  ),
                  action: 'teacher.submit',
                  kind: BtnKind.ink,
                  loading: controller.saving.value,
                  onPressed: controller.saving.value ? null : () => unawaited(controller.submit()),
                ),
              ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cls == null
                      ? 'teacher.attendance'.tr
                      : '${'teacher.class_n'.trp({'class': classLabel(cls)})} · ${DateFormat('EEEE').format(DateTime.now())}',
                  style: context.type.h2,
                ),
                const SizedBox(height: 6),
                Text('teacher.attendance_hint'.tr, style: context.type.cap),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ViewStateView(
              state: controller.state.value,
              onRetry: controller.load,
              errorKey: controller.errorMessage.value,
              emptyArt: EmptyArt.attendance,
            emptyTitle: 'teacher.no_students',
              emptyBody: 'teacher.no_students_body',
              child: LayoutBuilder(
                builder: (context, box) {
                  final cols = box.maxWidth >= 600 ? 6 : 4;
                  final w = (box.maxWidth - 6 * (cols - 1)) / cols;
                  return Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final s in controller.students)
                        SizedBox(
                          width: w,
                          child: _Kid(student: s, mark: controller.marks[s.id], onTap: () => controller.cycle(s.id)),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _Kid extends StatelessWidget {
  const _Kid({required this.student, required this.mark, required this.onTap});

  final Student student;
  final AttendanceStatus? mark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    final absent = mark == AttendanceStatus.absent;
    final late = mark == AttendanceStatus.lateArrival;
    final house = _houses[student.house] ?? Avatar.houseFor(student.name);
    final state = absent
        ? 'teacher.absent'.tr
        : late
        ? 'teacher.late'.tr
        : 'teacher.present'.tr;
    return Semantics(
      button: true,
      label: '${student.name}, $state. ${'teacher.tap_to_change'.tr}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: const Cubic(.2, .8, .2, 1),
          padding: const EdgeInsets.fromLTRB(2, 8, 2, 6),
          decoration: BoxDecoration(
            color: absent
                ? c.badSoft
                : late
                ? c.lateSoft
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: absent ? c.paper : house,
                      shape: BoxShape.circle,
                      border: absent ? Border.all(color: AppColors.bad, width: 2.5) : null,
                    ),
                    child: Text(
                      Avatar.initialsOf(student.name),
                      style: anek(
                        16,
                        720,
                        width: 112,
                        height: 1,
                        color: absent
                            ? AppColors.bad
                            : house == const Color(0xFFE0A81E)
                            ? AppColors.mariInk
                            : AppColors.white,
                      ),
                    ),
                  ),
                  if (absent || late)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: absent ? AppColors.bad : AppColors.late,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.chalk, width: 2),
                        ),
                        child: Text(absent ? 'A' : 'L', style: anek(11, 780, height: 1, color: AppColors.white)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                student.name.split(' ').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: anek(12.5, 620, height: 1.1, color: c.ink),
              ),
              Text('teacher.roll'.trp({'n': student.rollNo}), style: context.type.cap.copyWith(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Assign homework ─────────────────────────────

class AssignHomeworkView extends GetView<AssignHomeworkController> {
  const AssignHomeworkView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    return Obx(() {
      final classId = controller.classId.value;
      final due = controller.due.value;
      final days = controller.days;
      final clash = due == null ? const <String>[] : controller.dueByDay[DateUtils.dateOnly(due)] ?? const <String>[];
      final cls = controller.classes.where((x) => x.id == classId).firstOrNull;
      return PageFrame(
        leading: const BackGlass(close: true),
        actions: [
          AnimatedOpacity(
            opacity: controller.draftSaved.value ? 1 : 0,
            duration: const Duration(milliseconds: 260),
            child: Text('teacher.draft_saved'.tr, style: anek(13, 620, height: 1.3, color: c.ink3)),
          ),
        ],
        topPadding: MediaQuery.paddingOf(context).top + 56,
        bottomBar: _ActionBar(
          text: Text(
            'teacher.reach'.trp({'n': '${controller.roster.value}'}),
            style: anek(13, 620, height: 1.3, color: c.ink3),
          ),
          action: 'teacher.assign',
          loading: controller.saving.value,
          onPressed: controller.saving.value ? null : () => unawaited(controller.submit()),
        ),
        children: [
          Text('teacher.new_homework'.tr, style: context.type.h2),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final x in controller.classes)
                      Chip2(classLabel(x), on: x.id == classId, onTap: () => unawaited(controller.pickClass(x.id))),
                  ],
                ),
              ),
              Cover(subject: controller.subject, width: 30, height: 38),
            ],
          ),
          const SizedBox(height: 16),
          Field(
            controller: controller.title,
            label: 'teacher.title',
            hint: 'teacher.title_hint',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          Field(
            controller: controller.body,
            label: 'teacher.instructions',
            hint: 'teacher.instructions_hint',
            maxLines: 4,
            minHeight: 70,
            keyboard: TextInputType.multiline,
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('teacher.due'.tr, style: anek(13, 620, height: 1.2, color: c.ink2)),
          ),
          Row(
            children: [
              for (final (i, d) in days.indexed) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: due != null && DateUtils.isSameDay(d, due),
                    label: DateFormat('EEEE d MMMM').format(d),
                    excludeSemantics: true,
                    child: Pressable(
                      onTap: () => controller.due.value = d,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 58,
                        decoration: BoxDecoration(
                          color: due != null && DateUtils.isSameDay(d, due) ? c.ink : c.paper,
                          borderRadius: BorderRadius.circular(16),
                          border: due != null && DateUtils.isSameDay(d, due) ? null : Border.all(color: c.line),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${d.day}',
                              style: anek(
                                18,
                                720,
                                height: 1.1,
                                color: due != null && DateUtils.isSameDay(d, due) ? c.chalk : c.ink,
                              ),
                            ),
                            Text(
                              DateFormat('EEE').format(d).toUpperCase(),
                              style: anek(
                                11,
                                650,
                                height: 1.1,
                                color: due != null && DateUtils.isSameDay(d, due)
                                    ? c.chalk.withValues(alpha: .7)
                                    : c.ink3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (cls != null && due != null) ...[
            const SizedBox(height: 6),
            Text(
              clash.contains(controller.subject)
                  ? 'teacher.clash_same'.trp({
                      'subject': subjectName(controller.subject),
                      'class': classLabel(cls),
                    })
                  : clash.isEmpty
                  ? 'teacher.clash_none'.trp({'class': classLabel(cls)})
                  : 'teacher.clash_other'.trp({
                      'subject': subjectName(controller.subject),
                      'class': classLabel(cls),
                      'others': clash.toSet().map(subjectName).join(', '),
                    }),
              style: context.type.cap,
            ),
          ],
          const SizedBox(height: 14),
          EduCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(child: Text('teacher.marks'.tr, style: context.type.t)),
                _Step(icon: PhosphorIconsRegular.minus, label: 'teacher.fewer', onTap: () => controller.step(-5)),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${controller.marks.value}',
                    textAlign: TextAlign.center,
                    style: context.type.h3.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ),
                _Step(icon: PhosphorIconsRegular.plus, label: 'teacher.more', onTap: () => controller.step(5)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _Link(
                icon: PhosphorIconsRegular.camera,
                label: 'teacher.photo_board',
                onTap: () => unawaited(_pick(ImageSource.camera)),
              ),
              _Link(
                icon: PhosphorIconsRegular.paperclip,
                label: 'teacher.attach',
                onTap: () => unawaited(_pick(ImageSource.gallery)),
              ),
              for (final a in controller.attachments)
                Chip2(a, icon: PhosphorIconsRegular.x, height: 32, onTap: () => controller.attachments.remove(a)),
            ],
          ),
        ],
      );
    });
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(source: source, imageQuality: 75);
      if (file != null) controller.attachments.add(file.name);
    } on Exception {
      ToastHelper.show('teacher.attach_failed', kind: ToastKind.error);
    }
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label.tr,
    excludeSemantics: true,
    child: Pressable(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: context.app.paper2, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: context.app.ink),
      ),
    ),
  );
}

class _Link extends StatelessWidget {
  const _Link({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: context.app.ink2),
          const SizedBox(width: 6),
          Text(label.tr, style: anek(13, 640, height: 1.3, color: context.app.ink2)),
        ],
      ),
    ),
  );
}

// ───────────────────────────── Grading ─────────────────────────────

String _ago(DateTime? t) {
  if (t == null) return '';
  final days = DateUtils.dateOnly(DateTime.now()).difference(DateUtils.dateOnly(t)).inDays;
  if (days <= 0) return 'common.today'.tr.toLowerCase();
  return days == 1 ? 'teacher.one_day'.tr : 'teacher.n_days'.trp({'n': '$days'});
}

String _sent(DateTime? t) {
  if (t == null) return '';
  return DateUtils.isSameDay(t, DateTime.now())
      ? 'teacher.sent_today'.trp({'time': DateFormat('H:mm').format(t)})
      : 'teacher.sent_on'.trp({'date': DateFormat('EEE d MMM').format(t)});
}

void _openSheet(GradingController controller, int index) => unawaited(
  Get.to<void>(
    () => GradeSheetView(controller: controller, start: index),
    transition: Transition.downToUp,
  ),
);

class GradingView extends GetView<GradingController> {
  const GradingView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    return Obx(() {
      controller.state.value;
      final items = controller.items;
      final queue = controller.queue;
      return PageFrame(
        leading: const BackGlass(),
        actions: [if (items.isNotEmpty) Chip2('teacher.oldest_first'.tr)],
        onRefresh: controller.load,
        bottomBar: queue.isEmpty
            ? null
            : _ActionBar(
                sub: 'teacher.next_in_queue'.tr,
                text: Text(
                  controller.names[queue.first.$2.studentId] ?? '',
                  style: context.type.t.copyWith(fontSize: 15),
                ),
                action: 'teacher.start_grading',
                onPressed: () => _openSheet(controller, 0),
              ),
        children: [
          Rise(child: Text('teacher.to_grade_n'.trp({'n': '${controller.total}'}), style: context.type.h1)),
          const SizedBox(height: 18),
          ViewStateView(
            state: controller.state.value,
            onRetry: controller.load,
            errorKey: controller.errorMessage.value,
            emptyArt: EmptyArt.homework,
            emptyTitle: 'teacher.nothing_to_grade',
            emptyBody: 'teacher.nothing_to_grade_body',
            child: Column(
              children: [
                for (final (i, g) in items.indexed) ...[
                  if (i > 0) const SizedBox(height: 12),
                  Rise(
                    index: i + 1,
                    child: i == 0
                        ? _GradingCard(item: g, controller: controller)
                        : EduCard(
                            onTap: () => _openSheet(controller, queue.indexWhere((q) => q.$1 == g)),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Cover(subject: g.homework.subject),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(g.homework.title, style: context.type.t),
                                      Text(
                                        '${g.schoolClass == null ? '' : '${classLabel(g.schoolClass!)} · '}${'teacher.n_waiting'.trp({'n': '${g.waiting.length}'})}',
                                        style: context.type.cap,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(PhosphorIconsRegular.caretRight, size: 16, color: c.ink3),
                              ],
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _GradingCard extends StatelessWidget {
  const _GradingCard({required this.item, required this.controller});

  final GradingItem item;
  final GradingController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    final h = item.homework;
    final total = h.submissions.length;
    final graded = item.graded;
    final waiting = item.waiting.length;
    final queue = controller.queue;
    final shown = item.waiting.take(3).toList();
    return EduCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Cover(subject: h.subject),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.title, style: context.type.t),
                    Text(
                      [
                        if (item.schoolClass != null) classLabel(item.schoolClass!),
                        'teacher.due_on'.trp({'date': DateFormat('EEE d MMM').format(h.dueOn)}),
                        'teacher.n_marks'.trp({'n': '${h.maxMarks}'}),
                      ].join(' · '),
                      style: context.type.cap,
                    ),
                  ],
                ),
              ),
              Stamp(
                'teacher.n_left'.trp({'n': '$waiting'}),
                color: c.dark ? const Color(0xFFF6BA45) : AppColors.late,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 8,
            child: Row(
              children: [
                if (graded > 0)
                  Expanded(
                    flex: graded,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.ok,
                        borderRadius: BorderRadius.horizontal(
                          left: const Radius.circular(4),
                          right: Radius.circular(waiting == 0 ? 4 : 0),
                        ),
                      ),
                    ),
                  ),
                if (graded > 0 && waiting > 0) const SizedBox(width: 3),
                if (waiting > 0)
                  Expanded(
                    flex: waiting,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.late,
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(graded == 0 ? 4 : 0),
                          right: const Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                if (total - graded - waiting > 0) ...[
                  const SizedBox(width: 3),
                  Expanded(
                    flex: total - graded - waiting,
                    child: Hatch(radius: BorderRadius.circular(4), child: const SizedBox.expand()),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'teacher.progress'.trp({
              'graded': '$graded',
              'waiting': '$waiting',
              'sent': '${item.submitted}',
              'total': '$total',
            }),
            style: context.type.cap,
          ),
          const SizedBox(height: 10),
          for (final (i, s) in shown.indexed) ...[
            Container(
              height: 1,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 30),
              color: c.line,
            ),
            Pressable(
              onTap: () =>
                  _openSheet(controller, queue.indexWhere((q) => q.$1 == item && q.$2.studentId == s.studentId)),
              scale: .985,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  children: [
                    const _Page(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(controller.names[s.studentId] ?? s.studentId, style: context.type.t),
                          Text(
                            [_sent(s.submittedAt), if (s.fileName != null) s.fileName!].join(' · '),
                            style: context.type.cap,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(_ago(s.submittedAt), style: context.type.cap),
                  ],
                ),
              ),
            ),
          ],
          if (waiting > shown.length)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 6, 0, 10),
              child: Text('teacher.n_more'.trp({'n': '${waiting - shown.length}'}), style: context.type.cap),
            ),
        ],
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 33,
    height: 41,
    child: Stack(
      children: [
        Positioned(
          left: 3,
          top: 3,
          child: Container(
            width: 30,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F5EE),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: context.app.line2),
            ),
          ),
        ),
        Container(
          width: 30,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F5EE),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: context.app.line2),
          ),
        ),
      ],
    ),
  );
}

/// Grade one submission: the page on top, marks and notes below.
class GradeSheetView extends StatefulWidget {
  const GradeSheetView({required this.controller, required this.start, super.key});

  final GradingController controller;
  final int start;

  @override
  State<GradeSheetView> createState() => _GradeSheetViewState();
}

class _GradeSheetViewState extends State<GradeSheetView> {
  static const _notes = ['teacher.note_neat', 'teacher.note_all', 'teacher.note_check', 'teacher.note_see_me'];

  late List<(GradingItem, HomeworkSubmission)> _queue = widget.controller.queue;
  late int _i = widget.start.clamp(0, _queue.isEmpty ? 0 : _queue.length - 1);
  final _feedback = TextEditingController();
  final _chips = <String>{};
  var _marks = 0;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    if (_queue.isEmpty) return;
    final h = _queue[_i].$1.homework;
    _marks = (h.maxMarks * .8).round();
    _chips.clear();
    _feedback.clear();
  }

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _queue.isEmpty) return;
    final (g, s) = _queue[_i];
    setState(() => _saving = true);
    final note = [..._chips.map((k) => k.tr), if (_feedback.text.trim().isNotEmpty) _feedback.text.trim()].join('. ');
    final ok = await widget.controller.grade(
      homework: g.homework,
      studentId: s.studentId,
      marks: _marks,
      feedback: note,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) return;
    Haptics.medium();
    final rest = [..._queue]..removeAt(_i);
    if (rest.isEmpty) {
      Get.back<void>();
      ToastHelper.show('teacher.all_graded', kind: ToastKind.success);
      return;
    }
    ToastHelper.show('teacher.graded', kind: ToastKind.success);
    setState(() {
      _queue = rest;
      _i = _i.clamp(0, rest.length - 1);
      _reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    final inset = MediaQuery.paddingOf(context);
    if (_queue.isEmpty) {
      return const PageFrame(
        leading: BackGlass(),
        children: [EmptyState(art: EmptyArt.homework, title: 'teacher.nothing_to_grade', body: 'teacher.nothing_to_grade_body')],
      );
    }
    final (g, s) = _queue[_i];
    final h = g.homework;
    final name = widget.controller.names[s.studentId] ?? s.studentId;
    final next = _queue.length > 1 ? _queue[(_i + 1) % _queue.length] : null;
    final grade = GradingController.gradeFor(_marks, h.maxMarks);
    final ratio = h.maxMarks == 0 ? 0.0 : _marks / h.maxMarks;
    final tone = ratio >= .7
        ? AppColors.ok
        : ratio >= .5
        ? AppColors.late
        : AppColors.bad;
    final paperH = 230 + inset.top;
    return Scaffold(
      backgroundColor: c.paper,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: paperH + 40,
            child: ColoredBox(
              color: const Color(0xFF3B2D22),
              child: Center(
                child: Transform.rotate(
                  angle: -.0175,
                  child: Container(
                    width: 310,
                    margin: EdgeInsets.only(top: inset.top + 40),
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7F5EE),
                      boxShadow: [
                        BoxShadow(color: Color(0x99000000), blurRadius: 40, spreadRadius: -20, offset: Offset(0, 20)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.title, style: anek(13, 700, height: 1.3, color: const Color(0xFF1D2B53))),
                        const SizedBox(height: 4),
                        Text(
                          s.fileName ?? 'teacher.no_file'.tr,
                          style: context.type.mono.copyWith(fontSize: 11.5, color: const Color(0xFF1D2B53)),
                        ),
                        for (final w in const [.9, .72, .84, .66, .88, .58])
                          FractionallySizedBox(
                            widthFactor: w,
                            child: Container(
                              height: 2,
                              margin: const EdgeInsets.only(top: 15),
                              decoration: BoxDecoration(
                                color: const Color(0x802F5BD3),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: inset.top + 8,
            child: Row(
              children: [
                const BackGlass(color: AppColors.white),
                const Spacer(),
                Glass(
                  height: 44,
                  width: 130,
                  onPigment: true,
                  child: Center(
                    child: Text(
                      'teacher.n_of'.trp({'i': '${_i + 1}', 'n': '${_queue.length}'}),
                      style: anek(14, 680, height: 1, tabular: true, color: AppColors.white),
                    ),
                  ),
                ),
                const Spacer(),
                GlassIconButton(
                  icon: PhosphorIconsRegular.caretRight,
                  label: 'teacher.skip'.tr,
                  color: AppColors.white,
                  onTap: _queue.length < 2
                      ? null
                      : () => setState(() {
                          _i = (_i + 1) % _queue.length;
                          _reset();
                        }),
                ),
              ],
            ),
          ),
          Positioned.fill(
            top: paperH,
            child: Container(
              decoration: BoxDecoration(
                color: c.paper,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 18, 20, inset.bottom + 120),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: context.type.t),
                            Text('${h.title} · ${_sent(s.submittedAt)}', style: context.type.cap),
                          ],
                        ),
                      ),
                      Stamp('$grade · $_marks/${h.maxMarks}', color: tone),
                    ],
                  ),
                  const SizedBox(height: 26),
                  GlassSlider(
                    value: h.maxMarks == 0 ? 0 : _marks / h.maxMarks,
                    divisions: h.maxMarks,
                    label: 'teacher.marks'.tr,
                    describe: (v) => '${(v * h.maxMarks).round()}',
                    fill: tone,
                    thumbWidth: 60,
                    thumbChild: Text('$_marks', style: anek(15, 760, height: 1, tabular: true, color: c.ink)),
                    onChanged: (v) => setState(() => _marks = (v * h.maxMarks).round()),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0', style: context.type.cap.copyWith(fontSize: 11)),
                      Text('${h.maxMarks ~/ 2}', style: context.type.cap.copyWith(fontSize: 11)),
                      Text('${h.maxMarks}', style: context.type.cap.copyWith(fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('teacher.quick_notes'.tr, style: anek(13, 620, height: 1.2, color: c.ink2)),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final n in _notes)
                        Chip2(
                          n,
                          on: _chips.contains(n),
                          onTap: () => setState(() => _chips.contains(n) ? _chips.remove(n) : _chips.add(n)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Field(controller: _feedback, hint: 'teacher.feedback_hint', minHeight: 52, maxLines: 3),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: (MediaQuery.viewInsetsOf(context).bottom > 0
                ? MediaQuery.viewInsetsOf(context).bottom + 12
                : 28 + inset.bottom),
            child: _ActionBar(
              text: Text(
                _queue.length - 1 == 0
                    ? 'teacher.last_one'.tr
                    : 'teacher.left_after'.trp({'n': '${_queue.length - 1}'}),
                style: anek(13, 620, height: 1.3, color: c.ink3),
              ),
              action: next == null
                  ? 'teacher.save'
                  : 'teacher.save_next'.trp({
                      'name': (widget.controller.names[next.$2.studentId] ?? '').split(' ').first,
                    }),
              loading: _saving,
              onPressed: _saving ? null : () => unawaited(_save()),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Marks entry ─────────────────────────────

class MarksEntryView extends StatefulWidget {
  const MarksEntryView({super.key});

  @override
  State<MarksEntryView> createState() => _MarksEntryViewState();
}

class _MarksEntryViewState extends State<MarksEntryView> {
  MarksEntryController get controller => Get.find<MarksEntryController>();
  final _input = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _edit(Student s) {
    controller.active.value = s.id;
    final v = controller.values[s.id];
    _input.text = v == null ? '' : (v == MarksEntryController.absentMark ? 'Ab' : '$v');
    _input.selection = TextSelection(baseOffset: 0, extentOffset: _input.text.length);
    _focus.requestFocus();
  }

  void _commit(String text) {
    final id = controller.active.value;
    if (id == null) return;
    final t = text.trim().toLowerCase();
    if (t.isEmpty) {
      controller.put(id, null);
    } else if (t == 'ab' || t == 'a') {
      controller.put(id, MarksEntryController.absentMark);
    } else {
      final n = int.tryParse(t);
      if (n == null || n < 0 || n > MarksEntryController.maxMarks) {
        ToastHelper.show(
          'teacher.marks_range'.trp({'max': '${MarksEntryController.maxMarks}'}),
          kind: ToastKind.error,
        );
        return;
      }
      controller.put(id, n);
    }
  }

  void _next() {
    _commit(_input.text);
    final n = controller.nextEmpty;
    if (n == null) {
      _focus.unfocus();
      ToastHelper.show('teacher.marks_complete', kind: ToastKind.success);
      return;
    }
    _edit(n);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    return Obx(() {
      controller.values.length;
      final cls = controller.schoolClass;
      final active = controller.active.value;
      final next = controller.nextEmpty;
      final avg = controller.average;
      final high = controller.highest;
      return PageFrame(
        leading: const BackGlass(),
        actions: [
          Chip2('teacher.marks_chip'.trp({'max': '${MarksEntryController.maxMarks}'})),
        ],
        bottomBar: controller.students.isEmpty
            ? null
            : _ActionBar(
                sub: controller.saving.value ? 'teacher.saving'.tr : 'teacher.saved_typing'.tr,
                text: Text(
                  next == null ? 'teacher.all_entered'.tr : 'teacher.next_name'.trp({'name': next.name}),
                  style: context.type.t.copyWith(fontSize: 15),
                ),
                action: 'teacher.next',
                kind: BtnKind.ink,
                icon: PhosphorIconsRegular.arrowBendDownLeft,
                onPressed: next == null && active == null ? null : _next,
              ),
        children: [
          Text(
            cls == null ? 'teacher.marks'.tr : 'teacher.marks_title'.trp({'class': classLabel(cls)}),
            style: context.type.h2,
          ),
          const SizedBox(height: 14),
          ViewStateView(
            state: controller.state.value,
            onRetry: controller.load,
            errorKey: controller.errorMessage.value,
            emptyArt: EmptyArt.attendance,
            emptyTitle: 'teacher.no_students',
            emptyBody: 'teacher.no_students_body',
            child: Column(
              children: [
                _SubjectBar(
                  controller: controller,
                  onPick: (id) {
                    _focus.unfocus();
                    unawaited(controller.pickSubject(id));
                  },
                ),
                const SizedBox(height: 14),
                EduCard(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      _Stat(value: avg == null ? '—' : avg.toStringAsFixed(1), label: 'teacher.average'),
                      _Stat(value: high == null ? '—' : '$high', label: 'teacher.highest'),
                      _Stat(
                        value: '${controller.missing}',
                        label: 'teacher.to_enter',
                        color: controller.missing > 0 ? (c.dark ? const Color(0xFFF6BA45) : AppColors.late) : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                EduCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      for (final s in controller.students)
                        _MarkRow(
                          student: s,
                          value: controller.values[s.id],
                          active: active == s.id,
                          input: _input,
                          focus: _focus,
                          onTap: () => _edit(s),
                          onSubmit: (_) => _next(),
                          onChanged: _commit,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _SubjectBar extends StatelessWidget {
  const _SubjectBar({required this.controller, required this.onPick});

  final MarksEntryController controller;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    return Semantics(
      label: 'teacher.subject'.tr,
      container: true,
      child: Glass(
        height: 48,
        radius: 24,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              for (final id in controller.subjects)
                Semantics(
                  selected: controller.subject.value == id,
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onPick(id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      height: 40,
                      constraints: const BoxConstraints(minWidth: 72),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: controller.subject.value == id ? AppColors.subject(id).fill : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        subjectName(id),
                        style: anek(
                          14,
                          controller.subject.value == id ? 720 : 620,
                          height: 1,
                          color: controller.subject.value == id ? AppColors.subject(id).on : c.ink3,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.color});

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value, style: anek(22, 760, width: 118, height: 1, tabular: true, color: color ?? context.app.ink)),
        const SizedBox(height: 2),
        Text(label.tr, style: context.type.cap),
      ],
    ),
  );
}

class _MarkRow extends StatelessWidget {
  const _MarkRow({
    required this.student,
    required this.value,
    required this.active,
    required this.input,
    required this.focus,
    required this.onTap,
    required this.onSubmit,
    required this.onChanged,
  });

  final Student student;
  final int? value;
  final bool active;
  final TextEditingController input;
  final FocusNode focus;
  final VoidCallback onTap;
  final ValueChanged<String> onSubmit;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    final absent = value == MarksEntryController.absentMark;
    return Semantics(
      button: !active,
      label:
          '${student.name}, ${value == null
              ? 'teacher.no_marks'.tr
              : absent
              ? 'teacher.absent'.tr
              : '$value'}',
      child: GestureDetector(
        onTap: active ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: active ? c.mariSoft : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: Text(student.rollNo, style: context.type.mono.copyWith(fontSize: 12, color: c.ink3)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(student.name, style: context.type.t, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Container(
                width: 64,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? c.paper : c.paper2,
                  borderRadius: BorderRadius.circular(14),
                  border: active ? Border.all(color: c.ink, width: 2) : null,
                ),
                child: active
                    ? TextField(
                        controller: input,
                        focusNode: focus,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(),
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp('[0-9aAbB]')),
                          LengthLimitingTextInputFormatter(3),
                        ],
                        onSubmitted: onSubmit,
                        onChanged: onChanged,
                        style: anek(18, 720, height: 1, tabular: true, color: c.ink),
                        cursorColor: c.ink,
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      )
                    : Text(
                        value == null
                            ? '—'
                            : absent
                            ? 'Ab'
                            : '$value',
                        style: value == null
                            ? anek(14, 500, height: 1, color: c.ink3)
                            : anek(18, 720, height: 1, tabular: true, color: absent ? c.badText : c.ink),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Post a notice ─────────────────────────────

class PostNoticeView extends GetView<PostNoticeController> {
  const PostNoticeView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    final me = Get.find<AuthService>().user.value?.name ?? '';
    return Obx(() {
      controller.preview.value;
      final cls = controller.own == null ? '' : classLabel(controller.own!);
      final title = controller.title.text.trim();
      final body = controller.body.text.trim();
      final tone = switch (controller.category.value) {
        'exams' => c.badText,
        'fees' => c.dark ? const Color(0xFFF6BA45) : AppColors.late,
        'holiday' || 'events' => AppColors.ok,
        _ => c.mariText,
      };
      return PageFrame(
        leading: const BackGlass(close: true),
        actions: [Text('teacher.preview_live'.tr, style: anek(13, 620, height: 1.3, color: c.ink3))],
        topPadding: MediaQuery.paddingOf(context).top + 56,
        bottomBar: _ActionBar(
          text: Text(
            'teacher.notified'.trp({'n': '${controller.reach}'}),
            style: anek(13, 620, height: 1.3, color: c.ink3),
          ),
          action: 'teacher.post',
          loading: controller.saving.value,
          onPressed: controller.saving.value ? null : () => unawaited(controller.submit()),
        ),
        children: [
          Text('teacher.new_notice'.tr, style: context.type.h2),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('teacher.who'.tr, style: anek(13, 620, height: 1.2, color: c.ink2)),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in PostNoticeController.audiences)
                Chip2(
                  a == 'school' ? 'teacher.aud_school'.tr : 'teacher.aud_$a'.trp({'class': cls}),
                  on: controller.audience.value == a,
                  onTap: () => controller.audience.value = a,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('teacher.type'.tr, style: anek(13, 620, height: 1.2, color: c.ink2)),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in PostNoticeController.categories)
                Chip2('notices.cat_$k', on: controller.category.value == k, onTap: () => controller.category.value = k),
            ],
          ),
          const SizedBox(height: 14),
          Field(controller: controller.title, hint: 'teacher.notice_title', textInputAction: TextInputAction.next),
          const SizedBox(height: 10),
          Field(
            controller: controller.body,
            hint: 'teacher.notice_body',
            maxLines: 5,
            minHeight: 66,
            keyboard: TextInputType.multiline,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('teacher.pin'.tr, style: context.type.t.copyWith(fontSize: 15)),
                    Text('teacher.pin_hint'.tr, style: context.type.cap),
                  ],
                ),
              ),
              GlassSwitch(
                value: controller.pinned.value,
                label: 'teacher.pin'.tr,
                onChanged: (v) => controller.pinned.value = v,
              ),
            ],
          ),
          SectionLabel('teacher.preview'.tr, top: 18),
          const SizedBox(height: 4),
          Transform.rotate(
            angle: context.reduceMotion ? 0 : -.0175,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                  decoration: BoxDecoration(
                    color: c.paper,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: c.line),
                    boxShadow: const [
                      BoxShadow(color: Color(0x7310201B), blurRadius: 24, spreadRadius: -14, offset: Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stamp('notices.cat_${controller.category.value}'.tr, color: tone, size: 10),
                      const SizedBox(height: 10),
                      Text(
                        title.isEmpty ? 'teacher.notice_title'.tr : title,
                        style: context.type.t.copyWith(color: title.isEmpty ? c.ink3 : null),
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(body, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.type.s),
                      ],
                      const SizedBox(height: 6),
                      Text('$me · ${'teacher.now'.tr}', style: context.type.cap),
                    ],
                  ),
                ),
                Positioned(
                  top: -7,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(color: AppColors.subject('maths').fill, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
