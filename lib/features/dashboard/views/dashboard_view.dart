import 'package:edunest/core/routes/app_routes.dart';
import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/formatters.dart';
import 'package:edunest/core/widgets/app_avatar.dart';
import 'package:edunest/core/widgets/feature_page.dart';
import 'package:edunest/core/widgets/motion.dart';
import 'package:edunest/core/widgets/states.dart';
import 'package:edunest/features/dashboard/controllers/dashboard_controller.dart';
import 'package:edunest/features/dashboard/widgets/child_switcher.dart';
import 'package:edunest/features/dashboard/widgets/home_cards.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final data = controller.snapshot;
      return RefreshIndicator(
        onRefresh: controller.load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Hero(name: data?.student.name, avatar: data?.student.avatarUrl)),
            const SliverToBoxAdapter(child: OfflineBanner()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              sliver: SliverToBoxAdapter(
                child: ViewStateView(
                  state: controller.state.value,
                  onRetry: controller.load,
                  errorKey: controller.errorMessage.value,
                  child: data == null
                      ? const SizedBox.shrink()
                      : _Body(data: data),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _Hero extends StatelessWidget {
  const _Hero({this.name, this.avatar});

  final String? name;
  final String? avatar;

  @override
  Widget build(BuildContext context) {
    final user = Get.find<AuthService>().user.value;
    return GradientHeader(
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppAvatar(
                  name: user?.name ?? '',
                  url: user?.avatarUrl,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Get.toNamed<void>(AppRoutes.notifications),
                  icon: const Icon(PhosphorIconsRegular.bell, color: Colors.white),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '${Formatters.greetingKey(DateTime.now()).tr},',
              style: context.text.bodyMedium?.copyWith(color: Colors.white),
            ),
            Text(
              name ?? user?.name ?? '',
              style: context.text.headlineMedium?.copyWith(color: Colors.white),
            ),
            ChildSwitcher(name: name, avatarUrl: avatar),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data});

  final HomeSnapshot data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AttendanceRingCard(percent: data.summary.percent).enter(context),
        const SizedBox(height: 16),
        Text('home.today'.tr, style: context.text.headlineSmall),
        const SizedBox(height: 8),
        TimetableStrip(day: data.today).enter(context, 1),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: SizedBox(height: 150, child: HomeworkDueCard(items: data.pending))),
            const SizedBox(width: 12),
            Expanded(child: SizedBox(height: 150, child: ExamCard(exam: data.nextExam))),
          ],
        ).enter(context, 2),
        if (data.due != null) ...[
          const SizedBox(height: 16),
          FeeBanner(item: data.due!).enter(context, 3),
        ],
        const SizedBox(height: 16),
        Text('home.notices'.tr, style: context.text.headlineSmall),
        const SizedBox(height: 8),
        NoticeCarousel(notices: data.notices).enter(context, 4),
        const SizedBox(height: 16),
        Text('home.quick'.tr, style: context.text.headlineSmall),
        QuickActionGrid(actions: _actions(context)).enter(context, 5),
      ],
    );
  }

  List<QuickAction> _actions(BuildContext context) {
    final app = context.app;
    return [
      QuickAction('menu.notices', PhosphorIconsRegular.megaphone, () => Get.toNamed<void>(AppRoutes.notices), app.info),
      QuickAction('attendance.title', PhosphorIconsRegular.calendar, () => Get.toNamed<void>(AppRoutes.attendance), app.success),
      QuickAction('homework.title', PhosphorIconsRegular.clipboardText, () => Get.toNamed<void>(AppRoutes.homework), app.warning),
      QuickAction('timetable.title', PhosphorIconsRegular.clock, () => Get.toNamed<void>(AppRoutes.timetable), context.colors.primary),
      QuickAction('results.title', PhosphorIconsRegular.chartBar, () => Get.toNamed<void>(AppRoutes.results), const Color(0xFF7C3AED)),
      QuickAction('menu.transport', PhosphorIconsRegular.bus, () => Get.toNamed<void>(AppRoutes.transport), app.success),
      QuickAction('menu.library', PhosphorIconsRegular.bookOpen, () => Get.toNamed<void>(AppRoutes.library), app.warning),
      QuickAction('menu.gallery', PhosphorIconsRegular.image, () => Get.toNamed<void>(AppRoutes.gallery), app.danger),
    ];
  }
}
