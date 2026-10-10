import 'package:edunest/core/services/connectivity_service.dart';
import 'package:edunest/core/theme/app_colors.dart';
import 'package:edunest/core/theme/app_typography.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/view_state.dart';
import 'package:edunest/core/widgets/glass.dart';
import 'package:edunest/core/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ViewStateView extends StatelessWidget {
  const ViewStateView({
    required this.state,
    required this.child,
    required this.onRetry,
    this.emptyTitle = 'empty.title',
    this.emptyBody = 'empty.body',
    this.emptyAction,
    this.onEmpty,
    this.errorKey,
    this.skeleton,
    super.key,
  });

  final ViewState state;
  final Widget child;
  final VoidCallback onRetry;
  final String emptyTitle;
  final String emptyBody;
  final String? emptyAction;
  final VoidCallback? onEmpty;
  final String? errorKey;
  final Widget? skeleton;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
      child: switch (state) {
        ViewState.loading => KeyedSubtree(key: const ValueKey('loading'), child: skeleton ?? const SkeletonList()),
        ViewState.empty => EmptyState(
          key: const ValueKey('empty'),
          title: emptyTitle,
          body: emptyBody,
          action: emptyAction,
          onAction: onEmpty,
        ),
        ViewState.error => ErrorState(key: const ValueKey('error'), messageKey: errorKey, onRetry: onRetry),
        ViewState.success => KeyedSubtree(key: const ValueKey('ok'), child: child),
      },
    );
  }
}

/// Quiet-desk empty state: closed notebooks, a short line, an optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({required this.title, required this.body, this.action, this.onAction, super.key});

  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          const ClosedNotebooks(),
          const SizedBox(height: 26),
          Text(title.tr, style: context.type.dl.copyWith(fontSize: 40), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            body.tr,
            style: context.type.b.copyWith(color: context.app.ink2),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: 18),
            Btn(action!, kind: BtnKind.quiet, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

class ClosedNotebooks extends StatelessWidget {
  const ClosedNotebooks({super.key});

  @override
  Widget build(BuildContext context) {
    Widget book(String subject, double dx, double angle) => Transform.translate(
      offset: Offset(dx, 0),
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 150,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.subject(subject).fill,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [BoxShadow(color: Color(0x2E000000), offset: Offset(0, -4), spreadRadius: -2)],
          ),
        ),
      ),
    );
    return Column(
      children: [
        book('hindi', 6, -.052),
        book('science', 0, .026),
        book('maths', 8, -.017),
        book('english', 2, .035),
      ],
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({required this.onRetry, this.messageKey, super.key});

  final VoidCallback onRetry;
  final String? messageKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Overline('errors.title'.tr, color: context.app.badText),
          const SizedBox(height: 10),
          Text('errors.didnt_load'.tr, style: context.type.h2),
          const SizedBox(height: 8),
          Text((messageKey ?? 'errors.generic').tr, style: context.type.b.copyWith(color: context.app.ink2)),
          const SizedBox(height: 18),
          Btn('common.retry', kind: BtnKind.ink, icon: PhosphorIconsRegular.arrowClockwise, onPressed: onRetry),
        ],
      ),
    );
  }
}

/// Skeleton blocks share the glass light: one sweep travels across them all.
class SkeletonList extends StatelessWidget {
  const SkeletonList({this.rows = 3, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Sweep(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 150, height: 12),
          const SizedBox(height: 12),
          const SkeletonBox(width: 240, height: 30, radius: 10),
          const SizedBox(height: 20),
          EduCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                for (var i = 0; i < rows; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        const SkeletonBox(width: 42, height: 52, radius: 8),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FractionallySizedBox(widthFactor: i.isEven ? .8 : .6, child: const SkeletonBox(height: 14)),
                              const SizedBox(height: 8),
                              FractionallySizedBox(widthFactor: i.isEven ? .5 : .4, child: const SkeletonBox(height: 12)),
                            ],
                          ),
                        ),
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

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({this.width, this.height = 14, this.radius = 12, super.key});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(color: context.app.paper2, borderRadius: BorderRadius.circular(radius)),
  );
}

/// One specular sweep shared by every skeleton under it.
class Sweep extends StatefulWidget {
  const Sweep({required this.child, super.key});

  final Widget child;

  @override
  State<Sweep> createState() => _SweepState();
}

class _SweepState extends State<Sweep> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return widget.child;
    final glint = context.app.dark ? const Color(0x22FFFFFF) : const Color(0xD9FFFFFF);
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeInOutCubic.transform(_c.value);
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(-1.6 + 3.2 * t, -.3),
            end: Alignment(-.6 + 3.2 * t, .3),
            colors: [Colors.transparent, glint, Colors.transparent],
            stops: const [.3, .5, .7],
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}

/// Glass capsule shown under the top controls while offline.
class OfflineCapsule extends StatelessWidget {
  const OfflineCapsule({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ConnectivityService>()) return const SizedBox.shrink();
    return Obx(() {
      if (Get.find<ConnectivityService>().isOnline.value) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Center(
          child: Glass(
            height: 44,
            radius: 22,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIconsRegular.wifiSlash, size: 16, color: context.app.ink),
                const SizedBox(width: 8),
                Text('common.offline'.tr, style: anek(13, 650, height: 1, color: context.app.ink)),
              ],
            ),
          ),
        ),
      );
    });
  }
}
