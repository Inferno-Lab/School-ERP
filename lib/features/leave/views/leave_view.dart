import 'dart:async';

import 'package:edunest/core/routes/app_routes.dart';
import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/theme/app_colors.dart';
import 'package:edunest/core/theme/app_typography.dart';
import 'package:edunest/core/utils/app_exception.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/haptics.dart';
import 'package:edunest/core/utils/loadable.dart';
import 'package:edunest/core/widgets/glass.dart';
import 'package:edunest/core/widgets/glass_controls.dart';
import 'package:edunest/core/widgets/page.dart';
import 'package:edunest/core/widgets/states.dart';
import 'package:edunest/core/widgets/toast.dart';
import 'package:edunest/core/widgets/ui.dart';
import 'package:edunest/data/models/academics.dart';
import 'package:edunest/data/models/campus.dart';
import 'package:edunest/data/repositories/academic_repository.dart';
import 'package:edunest/data/repositories/campus_repository.dart';
import 'package:edunest/data/repositories/directory_repository.dart';
import 'package:edunest/core/widgets/empty_art.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

DateTime _day(DateTime d) => DateUtils.dateOnly(d);

/// Days a leave covers, counting both ends.
int _span(LeaveRequest r) => _day(r.to).difference(_day(r.from)).inDays + 1;

/// shortcut: terms are fixed halves (Jun–Nov, Dec–May); read them from the school calendar once it exists.
DateTime _termStart(DateTime now) {
  if (now.month >= 6 && now.month <= 11) return DateTime(now.year, 6);
  return now.month == 12 ? DateTime(now.year, 12) : DateTime(now.year - 1, 12);
}

class LeaveController extends GetxController with Loadable {
  List<LeaveRequest> items = [];
  String? childName;
  String? teacherName;

  /// Most recent absence no leave request covers.
  DateTime? unexplained;

  int get waiting => items.where((i) => i.status == LeaveStatus.pending).length;

  int get takenThisTerm {
    final start = _termStart(DateTime.now());
    return items
        .where((i) => i.status == LeaveStatus.approved && !i.from.isBefore(start))
        .fold(0, (sum, i) => sum + _span(i));
  }

  @override
  Future<void> load() async {
    final id = Get.find<AuthService>().activeStudentId.value;
    if (id == null) {
      await run(() async {}, isEmpty: () => true);
      return;
    }
    await run(() async {
      final directory = Get.find<DirectoryRepository>();
      final student = await directory.student(id);
      final cls = await directory.schoolClass(student.classId);
      childName = student.name.split(' ').first;
      teacherName = (await directory.teacherOrNull(cls.classTeacherId))?.name;
      items = await Get.find<LeaveRepository>().forStudent(id);
      items.sort((a, b) => b.appliedOn.compareTo(a.appliedOn));
      final days = await Get.find<AttendanceRepository>().forStudent(id);
      final absences =
          days
              .where((d) => d.status == AttendanceStatus.absent)
              .map((d) => _day(d.date))
              .where((d) => !items.any((r) => !d.isBefore(_day(r.from)) && !d.isAfter(_day(r.to))))
              .toList()
            ..sort((a, b) => b.compareTo(a));
      unexplained = absences.firstOrNull;
    }, isEmpty: () => false);
  }
}

class LeaveView extends GetView<LeaveController> {
  const LeaveView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.state.value;
      final items = controller.items;
      final unexplained = controller.unexplained;
      return PageFrame(
        leading: const BackGlass(),
        onRefresh: controller.load,
        bottomBarHeight: 56,
        bottomBar: Center(
          child: GlassPress(
            onTap: () => Get.toNamed<void>(AppRoutes.leaveApply),
            child: Semantics(
              button: true,
              child: Glass(
                width: 200,
                height: 56,
                radius: 28,
                tint: const Color(0x8CF2A007),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIconsBold.plus, size: 22, color: context.app.ink),
                    const SizedBox(width: 8),
                    Text('leave.new'.tr, style: anek(16, 700, height: 1, color: context.app.ink)),
                  ],
                ),
              ),
            ),
          ),
        ),
        children: [
          Rise(
            child: PageTitle(
              'leave.title',
              subtitle: controller.childName == null
                  ? null
                  : [
                      controller.childName!,
                      'leave.taken'.trp({'n': '${controller.takenThisTerm}'}),
                      if (controller.waiting > 0) 'leave.waiting_n'.trp({'n': '${controller.waiting}'}),
                    ].join(' · '),
            ),
          ),
          ViewStateView(
            state: controller.state.value,
            onRetry: controller.load,
            errorKey: controller.errorMessage.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (unexplained != null) ...[
                  const SizedBox(height: 18),
                  Rise(index: 2, child: _Unexplained(date: unexplained)),
                ],
                const Rise(index: 3, child: SectionLabel('leave.requests')),
                if (items.isEmpty)
                  EmptyState(
                    art: EmptyArt.plane,
                    title: 'leave.empty',
                    body: 'leave.empty_body',
                    hint: 'leave.empty_hint',
                    actions: [
                      EmptyAction(
                        'leave.new',
                        icon: PhosphorIconsRegular.plus,
                        primary: true,
                        onTap: () => Get.toNamed<void>(AppRoutes.leaveApply),
                      ),
                    ],
                  )
                else
                  Rise(
                    index: 3,
                    child: EduCard(
                      child: Column(
                        children: [
                          for (var i = 0; i < items.length; i++) ...[
                            if (i > 0) const Hr(indent: 86),
                            _Request(item: items[i], teacher: controller.teacherName),
                          ],
                        ],
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

class _DateTile extends StatelessWidget {
  const _DateTile({required this.day, required this.caption, this.background, this.foreground, this.captionColor});

  final int day;
  final String caption;
  final Color? background;
  final Color? foreground;
  final Color? captionColor;

  @override
  Widget build(BuildContext context) => Container(
    width: 58,
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(color: background ?? context.app.paper2, borderRadius: BorderRadius.circular(14)),
    child: Column(
      children: [
        Text('$day', style: anek(22, 760, width: 118, height: 1, color: foreground ?? context.app.ink)),
        const SizedBox(height: 2),
        Text(caption, style: anek(11, 700, height: 1.2, em: .06, color: captionColor ?? context.app.ink3)),
      ],
    ),
  );
}

class _Unexplained extends StatelessWidget {
  const _Unexplained({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: () => Get.toNamed<void>(AppRoutes.leaveApply, arguments: {'past': date}),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.app.badSoft, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          _DateTile(
            day: date.day,
            caption: DateFormat('MMM').format(date).toUpperCase(),
            background: AppColors.bad,
            foreground: AppColors.white,
            captionColor: Colors.white.withValues(alpha: .85),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('leave.no_reason'.tr, style: context.type.t),
                Text(
                  'leave.no_reason_body'.trp({'day': DateFormat('EEEE').format(date)}),
                  style: context.type.cap,
                ),
              ],
            ),
          ),
          Icon(PhosphorIconsRegular.caretRight, size: 18, color: context.app.ink),
        ],
      ),
    ),
  );
}

class _Request extends StatelessWidget {
  const _Request({required this.item, required this.teacher});

  final LeaveRequest item;
  final String? teacher;

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    final days = _span(item);
    final (stamp, tone) = switch (item.status) {
      LeaveStatus.pending => ('leave.waiting', c.dark ? const Color(0xFFF6BA45) : AppColors.late),
      LeaveStatus.approved => ('leave.approved', AppColors.ok),
      LeaveStatus.rejected => ('leave.declined', c.badText),
    };
    final sameMonth = item.from.month == item.to.month;
    final range = days == 1
        ? DateFormat('EEE d MMM').format(item.from)
        : '${DateFormat(sameMonth ? 'EEE d' : 'EEE d MMM').format(item.from)} – ${DateFormat('EEE d MMM').format(item.to)}';
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DateTile(
            day: item.from.day,
            caption: '${DateFormat('MMM').format(item.from).toUpperCase()} · ${days}D',
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(item.reason, style: context.type.t)),
                    const SizedBox(width: 8),
                    Stamp(stamp.tr, color: tone),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [if (item.note != null && item.note!.trim().isNotEmpty) item.note!.trim(), '$range.'].join(' '),
                  style: context.type.s,
                ),
                if (item.status == LeaveStatus.pending)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      teacher == null
                          ? 'leave.sent_on'.trp({'date': DateFormat('EEE d MMM').format(item.appliedOn)})
                          : 'leave.sent_to'.trp({
                              'date': DateFormat('EEE d MMM').format(item.appliedOn),
                              'name': teacher!,
                            }),
                      style: context.type.cap,
                    ),
                  )
                else if (item.reviewNote != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: c.paper2, borderRadius: BorderRadius.circular(18)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('“${item.reviewNote}”', style: context.type.s),
                        if (item.reviewedBy != null) ...[
                          const SizedBox(height: 4),
                          Text(item.reviewedBy!, style: context.type.cap),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LeaveApplyController extends GetxController {
  static const reasons = ['unwell', 'family', 'travel', 'appointment', 'other'];

  /// 0: upcoming leave, 1: explaining a past absence.
  final mode = 0.obs;
  final start = Rxn<DateTime>();
  final end = Rxn<DateTime>();

  /// Which end of the range the next tap sets: 0 start, 1 end.
  final picking = 0.obs;
  final month = DateTime(DateTime.now().year, DateTime.now().month).obs;
  final reason = RxnString();
  final attachment = RxnString();
  final sending = false.obs;
  final note = TextEditingController();

  final holidays = <DateTime>{}.obs;
  String? teacherName;

  DateTime get today => _day(DateTime.now());

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['past'] is DateTime) {
      final d = _day(args['past'] as DateTime);
      mode.value = 1;
      start.value = d;
      end.value = d;
      month.value = DateTime(d.year, d.month);
    }
    unawaited(_load());
  }

  @override
  void onClose() {
    note.dispose();
    super.onClose();
  }

  Future<void> _load() async {
    final id = Get.find<AuthService>().activeStudentId.value;
    if (id == null) return;
    try {
      final directory = Get.find<DirectoryRepository>();
      final student = await directory.student(id);
      final cls = await directory.schoolClass(student.classId);
      teacherName = (await directory.teacherOrNull(cls.classTeacherId))?.name;
      final days = await Get.find<AttendanceRepository>().forStudent(id);
      holidays.addAll(days.where((d) => d.status == AttendanceStatus.holiday).map((d) => _day(d.date)));
    } on AppException {
      // Without the calendar only Sundays are blocked; the class teacher still reviews.
    }
  }

  void setMode(int value) {
    if (mode.value == value) return;
    mode.value = value;
    start.value = null;
    end.value = null;
    picking.value = 0;
    month.value = DateTime(today.year, today.month);
  }

  bool disabled(DateTime d) {
    if (d.weekday == DateTime.sunday || holidays.contains(d)) return true;
    return mode.value == 1 ? d.isAfter(today) : d.isBefore(today);
  }

  /// Months the calendar may show: two back for absences, three ahead for leave.
  bool canShift(int delta) {
    final now = DateTime(today.year, today.month);
    final target = DateTime(month.value.year, month.value.month + delta);
    final diff = (target.year - now.year) * 12 + target.month - now.month;
    return mode.value == 1 ? diff <= 0 && diff >= -2 : diff >= 0 && diff <= 3;
  }

  void shift(int delta) {
    if (canShift(delta)) month.value = DateTime(month.value.year, month.value.month + delta);
  }

  void pick(DateTime d) {
    if (disabled(d)) return;
    Haptics.selection();
    final s = start.value;
    if (picking.value == 0 || s == null || d.isBefore(s)) {
      // The end can never come before the start: an earlier tap starts over.
      start.value = d;
      end.value = d;
      picking.value = 1;
    } else {
      end.value = d;
      picking.value = 0;
    }
  }

  int get schoolDays {
    final s = start.value;
    final e = end.value;
    if (s == null || e == null) return 0;
    var n = 0;
    for (var d = s; !d.isAfter(e); d = DateTime(d.year, d.month, d.day + 1)) {
      if (d.weekday != DateTime.sunday && !holidays.contains(d)) n++;
    }
    return n;
  }

  Future<void> attach() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (file != null) attachment.value = file.name;
    } on Exception {
      ToastHelper.show('leave.attach_failed', kind: ToastKind.error);
    }
  }

  Future<void> send() async {
    final id = Get.find<AuthService>().activeStudentId.value;
    final s = start.value;
    final e = end.value;
    if (id == null || s == null || e == null) {
      ToastHelper.show('leave.pick_dates', kind: ToastKind.error);
      return;
    }
    if (reason.value == null) {
      ToastHelper.show('leave.pick_reason', kind: ToastKind.error);
      return;
    }
    sending.value = true;
    try {
      final text = note.text.trim();
      await Get.find<LeaveRepository>().apply(
        LeaveRequest(
          id: 'lv_${DateTime.now().microsecondsSinceEpoch}',
          studentId: id,
          from: s,
          to: e,
          reason: 'leave.reason_${reason.value}'.tr,
          note: [if (text.isNotEmpty) text, if (attachment.value != null) 'leave.note_attached'.tr].join(' '),
          status: LeaveStatus.pending,
          appliedOn: DateTime.now(),
        ),
      );
      Get.back<void>();
      ToastHelper.show(
        teacherName == null ? 'leave.sent' : 'leave.sent_named'.trp({'name': teacherName!}),
        kind: ToastKind.success,
      );
    } on AppException catch (error) {
      ToastHelper.show(error.message, kind: ToastKind.error);
    } finally {
      sending.value = false;
    }
  }
}

class LeaveApplyView extends GetView<LeaveApplyController> {
  const LeaveApplyView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    return Obx(() {
      final past = controller.mode.value == 1;
      final s = controller.start.value;
      final e = controller.end.value;
      String chip(String key, DateTime? d) =>
          '${key.tr} · ${d == null ? 'leave.choose'.tr : DateFormat('EEE d MMM').format(d)}';
      return PageFrame(
        leading: const BackGlass(close: true),
        actions: [
          SizedBox(
            width: 240,
            child: GlassSegmented(
              labels: ['leave.upcoming'.tr, 'leave.past'.tr],
              index: controller.mode.value,
              height: 44,
              fontSize: 14,
              onChanged: controller.setMode,
              semanticLabel: 'leave.kind'.tr,
            ),
          ),
        ],
        topPadding: MediaQuery.paddingOf(context).top + 60,
        bottomBar: Glass(
          height: 64,
          radius: 32,
          padding: const EdgeInsets.only(left: 20, right: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'leave.goes_to'.tr,
                  style: anek(13, 600, height: 1.3, color: c.ink3),
                  maxLines: 2,
                ),
              ),
              Btn(
                'leave.send',
                height: 48,
                loading: controller.sending.value,
                onPressed: controller.sending.value ? null : () => unawaited(controller.send()),
              ),
            ],
          ),
        ),
        children: [
          Text(past ? 'leave.explain_title'.tr : 'leave.ask_title'.tr, style: context.type.h2),
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip2(
                chip('leave.from', s),
                on: controller.picking.value == 0 || s != null,
                onTap: () => controller.picking.value = 0,
              ),
              Icon(PhosphorIconsRegular.arrowRight, size: 15, color: c.ink3),
              Chip2(
                chip('leave.to', e),
                on: controller.picking.value == 1 || e != null,
                onTap: s == null ? null : () => controller.picking.value = 1,
              ),
            ],
          ),
          const SizedBox(height: 12),
          EduCard(
            padding: const EdgeInsets.all(12),
            child: _RangeCalendar(controller: controller),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('leave.reason'.tr, style: anek(13, 620, height: 1.2, color: c.ink2)),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in LeaveApplyController.reasons)
                Semantics(
                  selected: controller.reason.value == r,
                  child: Chip2(
                    'leave.reason_$r',
                    on: controller.reason.value == r,
                    onTap: () => controller.reason.value = r,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Field(
            controller: controller.note,
            label: controller.teacherName == null
                ? '${'leave.note'.tr} · ${'common.optional'.tr}'
                : '${'leave.note_for'.trp({'name': controller.teacherName!})} · ${'common.optional'.tr}',
            hint: past ? 'leave.note_hint_past' : 'leave.note_hint',
            maxLines: 4,
            minHeight: 76,
            textInputAction: TextInputAction.newline,
            keyboard: TextInputType.multiline,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: controller.attachment.value == null
                ? Pressable(
                    onTap: () => unawaited(controller.attach()),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsRegular.paperclip, size: 18, color: c.ink2),
                          const SizedBox(width: 8),
                          Text('leave.attach'.tr, style: anek(13, 620, height: 1.3, color: c.ink2)),
                        ],
                      ),
                    ),
                  )
                : Chip2(
                    controller.attachment.value!,
                    icon: PhosphorIconsRegular.x,
                    onTap: () => controller.attachment.value = null,
                  ),
          ),
        ],
      );
    });
  }
}

class _RangeCalendar extends StatelessWidget {
  const _RangeCalendar({required this.controller});

  final LeaveApplyController controller;

  static const _cell = 38.0;

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    final month = controller.month.value;
    controller.holidays.length;
    final s = controller.start.value;
    final e = controller.end.value;
    final today = controller.today;
    final first = DateTime(month.year, month.month);
    final lead = first.weekday - 1;
    final count = DateUtils.getDaysInMonth(month.year, month.month);
    var cells = lead + count;
    // Explaining an absence: weeks after this one hold nothing pickable.
    if (controller.mode.value == 1 && month.year == today.year && month.month == today.month) {
      cells = lead + today.day + (7 - today.weekday);
      cells = cells > lead + count ? lead + count : cells;
    }
    final rows = (cells / 7).ceil();
    final n = controller.schoolDays;
    Widget arrow(IconData icon, int delta, String label) => controller.canShift(delta)
        ? Semantics(
            button: true,
            label: label.tr,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => controller.shift(delta),
              child: SizedBox(width: 32, height: 32, child: Icon(icon, size: 16, color: c.ink)),
            ),
          )
        : const SizedBox(width: 32, height: 32);
    return GestureDetector(
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v.abs() > 200) controller.shift(v < 0 ? 1 : -1);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(DateFormat('MMMM y').format(month), style: context.type.t)),
              if (n > 0)
                Text(n == 1 ? 'leave.one_day'.tr : 'leave.n_days'.trp({'n': '$n'}), style: context.type.cap),
              const SizedBox(width: 4),
              arrow(PhosphorIconsRegular.caretLeft, -1, 'leave.prev_month'),
              arrow(PhosphorIconsRegular.caretRight, 1, 'leave.next_month'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final w in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Text(
                    w,
                    textAlign: TextAlign.center,
                    style: anek(11, 700, height: 1.4, em: .06, color: c.ink3),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var r = 0; r < rows; r++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(child: _cellAt(context, r * 7 + col - lead + 1, month, count, s, e, today)),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text('leave.calendar_rule'.tr, style: context.type.cap),
        ],
      ),
    );
  }

  Widget _cellAt(BuildContext context, int day, DateTime month, int count, DateTime? s, DateTime? e, DateTime today) {
    if (day < 1 || day > count) return const SizedBox(height: _cell);
    final c = context.app;
    final d = DateTime(month.year, month.month, day);
    final off = controller.disabled(d);
    final isStart = s != null && d == s;
    final isEnd = e != null && d == e;
    final inRange = s != null && e != null && !d.isBefore(s) && !d.isAfter(e);
    final edge = isStart || isEnd;
    return Semantics(
      button: !off,
      selected: inRange,
      label: DateFormat('d MMMM').format(d),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: off ? null : () => controller.pick(d),
        child: SizedBox(
          height: _cell,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The range is a marigold band; it starts and ends at the circles' centres.
              if (inRange && s != e)
                if (edge)
                  Align(
                    alignment: isStart ? Alignment.centerRight : Alignment.centerLeft,
                    child: FractionallySizedBox(widthFactor: .5, heightFactor: 1, child: ColoredBox(color: c.mariSoft)),
                  )
                else
                  Positioned.fill(child: ColoredBox(color: c.mariSoft)),
              if (edge)
                Container(
                  width: _cell,
                  height: _cell,
                  decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
                )
              else if (d == today)
                Container(
                  width: _cell,
                  height: _cell,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: c.line2, width: 1.5),
                  ),
                ),
              Opacity(
                opacity: off ? .45 : 1,
                child: Text(
                  '$day',
                  style: anek(14.5, 600, height: 1, tabular: true, color: edge ? c.chalk : (off ? c.ink3 : c.ink)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
