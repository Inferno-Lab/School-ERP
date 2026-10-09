import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/formatters.dart';
import 'package:edunest/core/utils/status.dart';
import 'package:edunest/core/widgets/app_bottom_sheet.dart';
import 'package:edunest/core/widgets/buttons.dart';
import 'package:edunest/core/widgets/chips.dart';
import 'package:edunest/core/widgets/feature_page.dart';
import 'package:edunest/core/widgets/misc.dart';
import 'package:edunest/core/widgets/states.dart';
import 'package:edunest/core/widgets/toast.dart';
import 'package:edunest/data/models/campus.dart';
import 'package:edunest/features/fees/controllers/fees_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class FeesView extends GetView<FeesController> {
  const FeesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final account = controller.account;
      return FeaturePage(
        title: 'fees.title',
        subtitle: 'fees.subtitle'.trParams({'year': account?.academicYear ?? ''}),
        onRefresh: controller.load,
        child: ViewStateView(
          state: controller.state.value,
          onRetry: controller.load,
          errorKey: controller.errorMessage.value,
          emptyBody: 'fees.empty',
          child: account == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: _FeesBody(account: account),
                ),
        ),
      );
    });
  }
}

class _FeesBody extends GetView<FeesController> {
  const _FeesBody({required this.account});

  final FeeAccount account;

  @override
  Widget build(BuildContext context) {
    final paid = account.installments.where((item) => item.paid).fold<int>(0, (sum, item) => sum + item.amount);
    final left = account.installments.where((item) => !item.paid).fold<int>(0, (sum, item) => sum + item.amount);
    final total = paid + left;
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 48,
              sections: [
                PieChartSectionData(
                  value: paid.toDouble().clamp(1, double.infinity),
                  color: context.app.success,
                  title: 'fees.paid'.tr,
                  radius: 28,
                  titleStyle: context.text.bodySmall?.copyWith(color: Colors.white),
                ),
                if (left > 0)
                  PieChartSectionData(
                    value: left.toDouble(),
                    color: context.app.warning,
                    title: 'fees.left'.tr,
                    radius: 28,
                    titleStyle: context.text.bodySmall?.copyWith(color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
        Text(Formatters.inr(total), style: context.text.headlineSmall),
        const SizedBox(height: 12),
        for (var i = 0; i < account.installments.length; i++)
          _InstallmentTile(
            item: account.installments[i],
            last: i == account.installments.length - 1,
          ),
      ],
    );
  }
}

class _InstallmentTile extends GetView<FeesController> {
  const _InstallmentTile({required this.item, required this.last});

  final Installment item;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final tone = moneyStatus(item);
    final key = tone.name;
    return TimelineTile(
      title: item.title,
      subtitle: '${Formatters.inr(item.amount)} · ${Formatters.fullDate(item.dueDate)}',
      done: item.paid,
      last: last,
      color: switch (tone) {
        MoneyStatus.paid => context.app.success,
        MoneyStatus.due => context.app.warning,
        MoneyStatus.overdue => context.app.danger,
        MoneyStatus.upcoming => context.colors.outline,
      },
      trailing: item.paid
          ? attendanceBadge(context, 'paid')
          : TextButton(
              onPressed: () => _pay(context),
              child: Text(key == 'upcoming' ? 'status.upcoming'.tr : 'common.pay_now'.tr),
            ),
    );
  }

  Future<void> _pay(BuildContext context) async {
    await showAppSheet<void>(
      child: AppBottomSheet(
        title: 'fees.pay_sheet'.trParams({'title': item.title}),
        child: Column(
          children: [
            _Method('fees.upi', PhosphorIconsRegular.qrCode, 'upi', item),
            _Method('fees.card', PhosphorIconsRegular.creditCard, 'card', item),
            _Method('fees.netbanking', PhosphorIconsRegular.bank, 'netbanking', item),
          ],
        ),
      ),
    );
  }
}

class _Method extends GetView<FeesController> {
  const _Method(this.label, this.icon, this.method, this.item);

  final String label;
  final IconData icon;
  final String method;
  final Installment item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SecondaryButton(
        label: label,
        icon: icon,
        onPressed: () => controller.pay(item, method),
      ),
    );
  }
}

class ReceiptView extends StatelessWidget {
  const ReceiptView({super.key});

  @override
  Widget build(BuildContext context) {
    final receipt = Get.arguments as Receipt?;
    if (receipt == null) {
      return const Scaffold(body: EmptyState(title: 'fees.empty', body: 'fees.empty'));
    }
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Lottie.asset(
                'assets/lottie/success.json',
                height: 140,
                errorBuilder: (_, _, _) => Icon(
                  PhosphorIconsFill.checkCircle,
                  size: 72,
                  color: context.app.success,
                ),
              ),
              Text('fees.success'.tr, style: context.text.headlineMedium),
              Text('fees.success_body'.tr, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: context.colors.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('fees.receipt'.tr, style: context.text.titleMedium),
                    Text(receipt.title, style: context.text.headlineSmall),
                    Text(Formatters.inr(receipt.amount), style: context.text.headlineMedium),
                    Text(receipt.method.toUpperCase(), style: context.text.bodySmall),
                    Text(receipt.reference, style: context.text.bodySmall),
                    Text(Formatters.fullDate(receipt.paidOn), style: context.text.bodySmall),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'common.share',
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: '${receipt.title} ${Formatters.inr(receipt.amount)} ${receipt.reference}'),
                  );
                  ToastHelper.show('fees.shared', kind: ToastKind.success);
                },
              ),
              const SizedBox(height: 8),
              SecondaryButton(
                label: 'common.download',
                onPressed: () => ToastHelper.show('fees.downloaded'),
              ),
              TextButton(onPressed: () => Get.back<void>(), child: Text('common.done'.tr)),
            ],
          ),
        ),
      ),
    );
  }
}
