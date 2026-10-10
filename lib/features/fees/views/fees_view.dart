import 'dart:async';

import 'package:edunest/core/config/app_config.dart';
import 'package:edunest/core/routes/app_routes.dart';
import 'package:edunest/core/services/theme_service.dart';
import 'package:edunest/core/theme/app_colors.dart';
import 'package:edunest/core/theme/app_typography.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/formatters.dart';
import 'package:edunest/core/utils/haptics.dart';
import 'package:edunest/core/utils/status.dart';
import 'package:edunest/core/widgets/glass.dart';
import 'package:edunest/core/widgets/glass_controls.dart';
import 'package:edunest/core/widgets/page.dart';
import 'package:edunest/core/widgets/sheets.dart';
import 'package:edunest/core/widgets/states.dart';
import 'package:edunest/core/widgets/toast.dart';
import 'package:edunest/core/widgets/ui.dart';
import 'package:edunest/data/models/campus.dart';
import 'package:edunest/features/fees/controllers/fees_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class FeesView extends StatefulWidget {
  const FeesView({super.key});

  @override
  State<FeesView> createState() => _FeesViewState();
}

class _FeesViewState extends State<FeesView> {
  FeesController get controller => Get.find<FeesController>();

  @override
  void initState() {
    super.initState();
    // Home's "Pay" opens the sheet straight away.
    final args = Get.arguments;
    if (args is Map && args['pay'] is String) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        Installment? find() => controller.account?.installments.where((x) => x.id == args['pay']).firstOrNull;
        // The account may still be loading, or reloading for a switched child.
        for (var i = 0; i < 40 && find() == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        final item = find();
        if (item != null && mounted) unawaited(openPaySheet(item));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final standalone = ModalRoute.of(context)?.settings.name == AppRoutes.fees;
    return Obx(() {
      final state = controller.state.value;
      final account = controller.account;
      final student = controller.student;
      final cls = controller.schoolClass;
      return PageFrame(
        dockPage: !standalone,
        leading: standalone ? const BackGlass() : null,
        topPadding: standalone ? null : MediaQuery.paddingOf(context).top + 14,
        onRefresh: controller.load,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PageTitle(
                  'fees.title',
                  subtitle: account == null || student == null
                      ? null
                      : '${account.academicYear.replaceAll('-', '–')} · ${student.name.split(' ').first}${cls == null ? '' : ' · ${cls.name} ${cls.section}'}',
                ),
              ),
              if (account != null && account.receipts.isNotEmpty)
                GlassPress(
                  onTap: () => unawaited(_receipts(context, account)),
                  child: Glass(
                    height: 44,
                    width: 116,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIconsRegular.receipt, size: 15, color: context.app.ink),
                        const SizedBox(width: 6),
                        Text('fees.receipts'.tr, style: anek(14, 650, height: 1, color: context.app.ink)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          ViewStateView(
            state: state,
            onRetry: controller.load,
            errorKey: controller.errorMessage.value,
            emptyTitle: 'fees.empty',
            emptyBody: 'fees.empty_body',
            child: account == null ? const SizedBox.shrink() : _Body(controller: controller, account: account),
          ),
        ],
      );
    });
  }

  Future<void> _receipts(BuildContext context, FeeAccount account) => showSheet<void>(
    SheetBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          Text('fees.receipts'.tr, style: context.type.h2),
          const SizedBox(height: 8),
          for (final r in account.receipts)
            Pressable(
              onTap: () {
                Get.back<void>();
                unawaited(Get.toNamed<void>(AppRoutes.receipt, arguments: receiptArgs(r, controller)));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.title, style: context.type.t),
                          Text('${DateFormat('d MMM y').format(r.paidOn)} · ${r.reference}', style: context.type.cap),
                        ],
                      ),
                    ),
                    Text(Formatters.inr(r.amount), style: context.type.t),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

Map<String, Object?> receiptArgs(Receipt r, FeesController controller) => {
  'receipt': r,
  'student': controller.student?.name,
  'roll': controller.student?.rollNo,
  'class': controller.schoolClass == null ? null : '${controller.schoolClass!.name.replaceAll(RegExp('[^0-9]'), '')} ${controller.schoolClass!.section}',
};

class _Body extends StatelessWidget {
  const _Body({required this.controller, required this.account});

  final FeesController controller;
  final FeeAccount account;

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    final next = controller.next;
    final total = controller.total;
    final paid = controller.paid;
    final theme = Get.find<ThemeService>();
    final items = [...account.installments]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Rise(child: next == null ? const _AllPaid() : _DueCard(item: next)),
        const SizedBox(height: 18),
        Rise(
          index: 1,
          child: Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: '${Formatters.inr(paid)} ',
                    children: [TextSpan(text: 'fees.of_paid'.trParams({'total': Formatters.inr(total)}), style: context.type.cap)],
                  ),
                  style: context.type.t,
                ),
              ),
              Text('${total == 0 ? 0 : (paid / total * 100).round()}%', style: context.type.cap),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Rise(
          index: 1,
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  Expanded(
                    flex: items[i].amount,
                    child: _Segment(item: items[i], first: i == 0, last: i == items.length - 1),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Rise(
          index: 2,
          child: EduCard(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Column(children: [for (final item in items) _TimelineRow(item: item)]),
          ),
        ),
        const SizedBox(height: 12),
        Rise(
          index: 3,
          child: EduCard(
            padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
            child: Row(
              children: [
                Icon(PhosphorIconsRegular.bell, color: c.mariText),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('fees.remind_early'.tr, style: context.type.t),
                      Obx(
                        () => Text(
                          theme.notifyFees.value && next != null
                              ? 'fees.next_reminder'.trParams({
                                  'date': DateFormat('EEE d MMM').format(
                                    next.dueDate.subtract(const Duration(days: 3)).isBefore(DateTime.now())
                                        ? DateTime.now().add(const Duration(days: 1))
                                        : next.dueDate.subtract(const Duration(days: 3)),
                                  ),
                                })
                              : 'fees.reminders_off'.tr,
                          style: context.type.cap,
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(
                  () => GlassSwitch(
                    value: theme.notifyFees.value,
                    label: 'fees.remind_early',
                    onColor: AppColors.mari,
                    onChanged: (v) => theme.setNotify(fees: v),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.item, required this.first, required this.last});

  final Installment item;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    final status = moneyStatus(item);
    final radius = BorderRadius.horizontal(
      left: Radius.circular(first ? 6 : 2),
      right: Radius.circular(last ? 6 : 2),
    );
    if (status == MoneyStatus.paid) {
      return DecoratedBox(decoration: BoxDecoration(color: c.ink, borderRadius: radius));
    }
    if (status == MoneyStatus.overdue) {
      return DecoratedBox(decoration: BoxDecoration(color: AppColors.bad, borderRadius: radius));
    }
    return Hatch(radius: radius, child: DecoratedBox(decoration: BoxDecoration(borderRadius: radius, border: Border.all(color: c.line2))));
  }
}

class _AllPaid extends StatelessWidget {
  const _AllPaid();

  @override
  Widget build(BuildContext context) => EduCard(
    color: context.app.okSoft,
    padding: const EdgeInsets.all(18),
    child: Row(
      children: [
        const Icon(PhosphorIconsBold.checkCircle, color: AppColors.ok, size: 28),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('fees.all_paid'.tr, style: context.type.h3),
              Text('fees.all_paid_body'.tr, style: context.type.cap),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DueCard extends StatelessWidget {
  const _DueCard({required this.item});

  final Installment item;

  @override
  Widget build(BuildContext context) {
    final overdue = moneyStatus(item) == MoneyStatus.overdue;
    final days = Formatters.daysUntil(item.dueDate);
    const ink = AppColors.mariInk;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(color: AppColors.mari, borderRadius: BorderRadius.circular(26)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Overline('fees.due_now'.trParams({'title': item.title.toLowerCase()}), color: ink.withValues(alpha: .75))),
              Stamp(
                overdue ? 'fees.days_late'.trParams({'n': '${-days}'}) : 'fees.due_in'.trParams({'n': '$days'}),
                color: overdue ? const Color(0xFF7A1E12) : ink,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(Formatters.inr(item.amount), style: context.type.dl.copyWith(color: ink)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  (overdue ? 'fees.was_due' : 'fees.due_on').trParams({'date': DateFormat('EEE d MMM').format(item.dueDate)}),
                  style: context.type.s.copyWith(color: ink.withValues(alpha: .8)),
                ),
              ),
              Btn('common.pay_now', kind: BtnKind.ink, small: true, onPressed: () => unawaited(openPaySheet(item))),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item});

  final Installment item;

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    final status = moneyStatus(item);
    final Widget node = switch (status) {
      MoneyStatus.paid => Dot(c.ink, size: 16),
      MoneyStatus.overdue => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: AppColors.bad,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: c.badSoft, spreadRadius: 4)],
        ),
      ),
      _ => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: c.paper,
          shape: BoxShape.circle,
          border: Border.all(color: status == MoneyStatus.due ? AppColors.late : c.ink3, width: 2.5),
        ),
      ),
    };
    final line = switch (status) {
      MoneyStatus.paid => 'fees.paid_line'.trParams({
        'date': DateFormat('d MMM').format(item.paidOn ?? item.dueDate),
        'method': 'fees.${item.method ?? 'upi'}'.tr,
      }),
      MoneyStatus.overdue => 'fees.overdue_since'.trParams({'date': DateFormat('d MMM').format(item.dueDate)}),
      _ => 'fees.due_line'.trParams({
        'date': DateFormat('EEE d MMM').format(item.dueDate),
        'n': '${Formatters.daysUntil(item.dueDate)}',
      }),
    };
    return Pressable(
      onTap: status == MoneyStatus.paid ? null : () => unawaited(openPaySheet(item)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(top: 0, bottom: 0, left: 9, child: Container(width: 2, color: c.line2)),
                  Positioned(left: 2, child: node),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: context.type.t),
                    Text(
                      line,
                      style: context.type.cap.copyWith(
                        color: status == MoneyStatus.overdue ? c.badText : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(Formatters.inr(item.amount), style: anek(16.5, 650, height: 1, tabular: true, color: c.ink)),
          ],
        ),
      ),
    );
  }
}

Future<void> openPaySheet(Installment item) => showSheet<void>(PaySheet(item: item));

/// Payment sheet with slide-to-pay so a payment never happens by accident.
class PaySheet extends StatefulWidget {
  const PaySheet({required this.item, super.key});

  final Installment item;

  @override
  State<PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<PaySheet> {
  var _method = 'upi';
  var _x = 0.0;
  var _drag = false;
  var _busy = false;
  Receipt? _receipt;

  static const _methods = [
    ('upi', 'UPI', 'fees.upi_title', 'fees.upi_sub'),
    ('upi_id', '@', 'fees.upi_id_title', 'fees.upi_id_sub'),
    ('card', null, 'fees.card_title', 'fees.card_sub'),
    ('netbanking', null, 'fees.net_title', 'fees.net_sub'),
  ];

  Future<void> _pay(double max) async {
    setState(() {
      _drag = false;
      _busy = true;
      _x = max;
    });
    Haptics.medium();
    final receipt = await Get.find<FeesController>().pay(widget.item, _method == 'upi_id' ? 'upi' : _method);
    if (!mounted) return;
    if (receipt == null) {
      setState(() {
        _busy = false;
        _x = 0;
      });
      return;
    }
    setState(() {
      _busy = false;
      _receipt = receipt;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Get.back<void>();
    unawaited(Get.toNamed<void>(AppRoutes.receipt, arguments: receiptArgs(receipt, Get.find<FeesController>())));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    final student = Get.find<FeesController>().student?.name.split(' ').first ?? '';
    return SheetBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Overline('${widget.item.title} · $student'),
                    const SizedBox(height: 10),
                    Text(Formatters.inr(widget.item.amount), style: context.type.dl),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: 'common.close'.tr,
                child: GestureDetector(
                  onTap: () => Get.back<void>(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: c.paper2, shape: BoxShape.circle),
                    child: Icon(PhosphorIconsRegular.x, size: 18, color: c.ink),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('fees.to_school'.trParams({'school': AppConfig.schoolName}), style: context.type.cap),
          SectionLabel('fees.pay_with'.tr, top: 20),
          for (final m in _methods)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Semantics(
                selected: _method == m.$1,
                button: true,
                child: Pressable(
                  onTap: _receipt != null || _busy ? null : () => setState(() => _method = m.$1),
                  scale: .985,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _method == m.$1 ? c.paper2 : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _method == m.$1 ? c.ink : Colors.transparent, width: 2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.paper,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: c.line),
                          ),
                          child: m.$2 != null
                              ? Text(m.$2!, style: anek(11, 760, height: 1, em: .04, color: c.ink))
                              : Icon(m.$1 == 'card' ? PhosphorIconsRegular.creditCard : PhosphorIconsRegular.bank, size: 18, color: c.ink),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.$3.tr, style: context.type.t),
                              Text(m.$4.tr, style: context.type.cap),
                            ],
                          ),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _method == m.$1 ? c.ink : c.line2, width: _method == m.$1 ? 7 : 2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 18),
          _SlideToPay(
            x: _x,
            dragging: _drag,
            busy: _busy,
            paid: _receipt != null,
            amount: Formatters.inr(widget.item.amount),
            onStart: () => setState(() => _drag = true),
            onMove: (x) => setState(() => _x = x),
            onEnd: (max) {
              if (_x > max * .85) {
                unawaited(_pay(max));
              } else {
                setState(() {
                  _drag = false;
                  _x = 0;
                });
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SlideToPay extends StatelessWidget {
  const _SlideToPay({
    required this.x,
    required this.dragging,
    required this.busy,
    required this.paid,
    required this.amount,
    required this.onStart,
    required this.onMove,
    required this.onEnd,
  });

  final double x;
  final bool dragging;
  final bool busy;
  final bool paid;
  final String amount;
  final VoidCallback onStart;
  final ValueChanged<double> onMove;
  final ValueChanged<double> onEnd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        const thumb = 76.0;
        final max = box.maxWidth - thumb - 8;
        final label = paid ? 'fees.paid_amount'.trParams({'amount': amount}) : busy ? 'fees.processing'.tr : 'fees.slide'.trParams({'amount': amount});
        return Semantics(
          slider: true,
          label: 'fees.slide'.trParams({'amount': amount}),
          onIncrease: paid || busy ? null : () => onEnd(max),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            height: 64,
            decoration: BoxDecoration(
              color: paid ? AppColors.ok : const Color(0xFF10201B),
              borderRadius: BorderRadius.circular(32),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(left: 0, top: 0, bottom: 0, width: x + 40, child: const ColoredBox(color: Color(0x59F2A007))),
                Center(
                  child: Opacity(
                    opacity: paid || busy ? 1 : (1 - x / 180).clamp(.15, 1),
                    child: Text(label, style: anek(16, 680, width: 106, height: 1, color: AppColors.white)),
                  ),
                ),
                AnimatedPositioned(
                  duration: dragging || context.reduceMotion ? Duration.zero : const Duration(milliseconds: 600),
                  curve: const Cubic(.3, 1.45, .45, 1),
                  left: 4 + x.clamp(0, max),
                  top: 4,
                  width: thumb,
                  height: 56,
                  child: GestureDetector(
                    onHorizontalDragStart: paid || busy ? null : (_) => onStart(),
                    onHorizontalDragUpdate: paid || busy ? null : (d) => onMove((x + d.delta.dx).clamp(0, max)),
                    onHorizontalDragEnd: paid || busy ? null : (_) => onEnd(max),
                    child: Glass(
                      kind: GlassKind.lens,
                      radius: 28,
                      tint: const Color(0x29FFFFFF),
                      child: Center(
                        child: busy
                            ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.white))
                            : Icon(paid ? PhosphorIconsBold.check : PhosphorIconsBold.caretRight, color: AppColors.white, size: 22),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Receipt: the stored receipt printed on a perforated slip.
class ReceiptView extends StatelessWidget {
  const ReceiptView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments is Map ? Get.arguments as Map : const <String, Object?>{};
    final receipt = args['receipt'] as Receipt?;
    final c = context.app;
    final inset = MediaQuery.paddingOf(context);
    if (receipt == null) {
      return const PageFrame(
        leading: BackGlass(close: true),
        children: [EmptyState(title: 'fees.no_receipt', body: 'fees.no_receipt_body')],
      );
    }
    final number = 'GIS/${receipt.paidOn.year % 100}-${(receipt.paidOn.year + 1) % 100}/${receipt.id.replaceAll(RegExp('[^0-9]'), '').padLeft(4, '0').substring(receipt.id.replaceAll(RegExp('[^0-9]'), '').padLeft(4, '0').length - 4)}';
    final rows = [
      if (args['student'] != null)
        ('fees.student'.tr, '${args['student']} · ${args['class'] ?? ''} · ${'fees.roll'.trParams({'n': '${args['roll'] ?? ''}'})}', false),
      ('fees.paid_on'.tr, DateFormat('EEE d MMM y, h:mm').format(receipt.paidOn), false),
      ('fees.method'.tr, 'fees.${receipt.method}'.tr, false),
      ('fees.reference'.tr, receipt.reference, true),
      ('fees.receipt_no'.tr, number, true),
    ];
    return Scaffold(
      backgroundColor: c.chalk,
      body: Stack(
        children: [
          Positioned(left: 0, right: 0, top: 0, height: 253 + inset.top, child: ColoredBox(color: AppColors.subject('science').fill)),
          Positioned(
            left: 16,
            right: 16,
            top: inset.top + 8,
            child: Row(
              children: [
                GlassIconButton(
                  icon: PhosphorIconsRegular.x,
                  label: 'common.close'.tr,
                  color: AppColors.white,
                  onTap: () => Get.back<void>(),
                ),
                Expanded(
                  child: Text(
                    'fees.payment_done'.tr,
                    textAlign: TextAlign.center,
                    style: anek(17, 700, height: 1, color: AppColors.white),
                  ),
                ),
                GlassIconButton(
                  icon: PhosphorIconsRegular.export,
                  label: 'fees.share_receipt'.tr,
                  color: AppColors.white,
                  onTap: () => ToastHelper.show('fees.shared', kind: ToastKind.success),
                ),
              ],
            ),
          ),
          Positioned.fill(
            top: inset.top + 103,
            child: ListView(
              padding: EdgeInsets.fromLTRB(24, 10, 24, inset.bottom + 110),
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: context.reduceMotion ? 1 : 0, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: const Cubic(.2, .8, .2, 1),
                  builder: (context, t, child) => ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: t,
                      child: Transform.translate(offset: Offset(0, -60 * (1 - t)), child: child),
                    ),
                  ),
                  child: _Slip(receipt: receipt, rows: rows),
                ),
              ],
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 34 + inset.bottom,
            child: Row(
              children: [
                Expanded(
                  child: Btn(
                    'fees.save_pdf',
                    kind: BtnKind.quiet,
                    icon: PhosphorIconsRegular.downloadSimple,
                    expand: true,
                    onPressed: () => ToastHelper.show('fees.downloaded', kind: ToastKind.success),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Btn('common.done', kind: BtnKind.ink, expand: true, onPressed: () => Get.back<void>())),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Slip extends StatelessWidget {
  const _Slip({required this.receipt, required this.rows});

  final Receipt receipt;
  final List<(String, String, bool)> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    return PhysicalShape(
      clipper: const _PerforatedClipper(),
      color: c.paper,
      shadowColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Color(0x2210201B), blurRadius: 40, offset: Offset(0, 20))],
        ),
        padding: const EdgeInsets.fromLTRB(22, 36, 22, 34),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Overline(AppConfig.schoolName),
                const SizedBox(height: 4),
                Text('fees.school_address'.tr, style: context.type.cap),
                const SizedBox(height: 22),
                Text(Formatters.inr(receipt.amount), style: context.type.dl),
                const SizedBox(height: 6),
                Text(receipt.title, style: context.type.t),
                const _Dashed(),
                for (final r in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.$1, style: anek(14, 450, height: 1.3, color: c.ink3)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            r.$2,
                            textAlign: TextAlign.right,
                            style: r.$3
                                ? context.type.mono.copyWith(color: c.ink)
                                : anek(14, 600, height: 1.3, color: c.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                const _Dashed(),
                Text('fees.receipt_note'.tr, style: context.type.cap),
              ],
            ),
            Positioned(
              right: 0,
              top: 70,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: context.reduceMotion ? 1 : 0, end: 1),
                duration: const Duration(milliseconds: 1600),
                curve: const Interval(.6, 1, curve: Cubic(.3, 1.45, .45, 1)),
                builder: (context, t, child) => Opacity(
                  opacity: (t * .85).clamp(0, .85),
                  child: Transform.scale(scale: .86 + .14 * t, child: child),
                ),
                child: Transform.rotate(
                  angle: -.21,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.ok, width: 3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('fees.paid_stamp'.tr, style: anek(26, 800, width: 125, height: 1, em: .12, color: AppColors.ok)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dashed extends StatelessWidget {
  const _Dashed();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: LayoutBuilder(
      builder: (context, box) => Row(
        children: [
          for (var i = 0; i < box.maxWidth ~/ 10; i++)
            Container(width: 6, height: 1.5, margin: const EdgeInsets.only(right: 4), color: context.app.line2),
        ],
      ),
    ),
  );
}

class _PerforatedClipper extends CustomClipper<Path> {
  const _PerforatedClipper();

  @override
  Path getClip(Size size) {
    const r = 6.0;
    const step = 12.0;
    final path = Path()..moveTo(0, r);
    for (var x = 0.0; x < size.width; x += step) {
      path.arcToPoint(Offset(x + step, r), radius: const Radius.circular(r), clockwise: false);
    }
    path.lineTo(size.width, size.height - r);
    for (var x = size.width; x > 0; x -= step) {
      path.arcToPoint(Offset(x - step, size.height - r), radius: const Radius.circular(r), clockwise: false);
    }
    return path..close();
  }

  @override
  bool shouldReclip(_PerforatedClipper oldClipper) => false;
}
