import 'dart:math';

import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/loadable.dart';
import 'package:edunest/core/widgets/app_avatar.dart';
import 'package:edunest/core/widgets/buttons.dart';
import 'package:edunest/core/widgets/feature_page.dart';
import 'package:edunest/core/widgets/misc.dart';
import 'package:edunest/core/widgets/states.dart';
import 'package:edunest/data/models/campus.dart';
import 'package:edunest/data/repositories/campus_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class TransportController extends GetxController with Loadable {
  TransportInfo? route;

  @override
  Future<void> load() async {
    final id = Get.find<AuthService>().activeStudentId.value;
    if (id == null) {
      await run(() async {}, isEmpty: () => true);
      return;
    }
    await run(() async {
      route = await Get.find<TransportRepository>().forStudent(id);
    }, isEmpty: () => route == null);
  }

  Future<void> call() async {
    final phone = route?.driver.phone;
    if (phone == null) return;
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }
}

class TransportView extends GetView<TransportController> {
  const TransportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final route = controller.route;
      return FeaturePage(
        title: 'transport.title',
        subtitle: route?.routeName ?? 'transport.subtitle',
        onRefresh: controller.load,
        child: ViewStateView(
          state: controller.state.value,
          onRetry: controller.load,
          errorKey: controller.errorMessage.value,
          child: route == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        child: SizedBox(
                          height: 220,
                          width: double.infinity,
                          child: _Map(progress: route.progress),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'transport.eta'.trParams({'min': '${route.etaMinutes}'}),
                        style: context.text.headlineSmall,
                      ),
                      Text(route.busNumber, style: context.text.bodyMedium),
                      const SizedBox(height: 12),
                      for (var i = 0; i < route.stops.length; i++)
                        TimelineTile(
                          title: route.stops[i].name,
                          subtitle: route.stops[i].time,
                          done: route.stops[i].reached,
                          last: i == route.stops.length - 1,
                        ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: AppAvatar(
                          name: route.driver.name,
                          url: route.driver.avatarUrl,
                        ),
                        title: Text(route.driver.name),
                        subtitle: Text(route.driver.phone),
                      ),
                      PrimaryButton(
                        label: 'common.call',
                        onPressed: controller.call,
                      ),
                    ],
                  ),
                ),
        ),
      );
    });
  }
}

class _Map extends StatefulWidget {
  const _Map({required this.progress});

  final double progress;

  @override
  State<_Map> createState() => _MapState();
}

class _MapState extends State<_Map> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = context.reduceMotion
            ? widget.progress
            : (widget.progress + sin(_controller.value * pi * 2) * 0.03).clamp(0.05, 0.95);
        return CustomPaint(
          painter: _RoutePainter(
            progress: t,
            road: context.colors.surfaceContainerHigh,
            route: context.colors.primary,
            bus: context.app.gradientEnd,
            background: const Color(0xFFE7F0E8),
          ),
        );
      },
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({
    required this.progress,
    required this.road,
    required this.route,
    required this.bus,
    required this.background,
  });

  final double progress;
  final Color road;
  final Color route;
  final Color bus;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.2,
        size.width * 0.92,
        size.height * 0.4,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = road
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = route
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    final metric = path.computeMetrics().first;
    final tangent = metric.getTangentForOffset(metric.length * progress);
    if (tangent == null) return;
    canvas.drawCircle(tangent.position, 10, Paint()..color = bus);
    canvas.drawCircle(tangent.position, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
