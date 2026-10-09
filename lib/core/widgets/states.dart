import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/view_state.dart';
import 'package:edunest/core/widgets/buttons.dart';
import 'package:edunest/core/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
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
    return switch (state) {
      ViewState.loading => skeleton ?? const SkeletonList(),
      ViewState.empty => EmptyState(
        title: emptyTitle,
        body: emptyBody,
        action: emptyAction,
        onAction: onEmpty,
      ),
      ViewState.error => ErrorState(messageKey: errorKey, onRetry: onRetry),
      ViewState.success => child,
    };
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.body,
    this.action,
    this.onAction,
    super.key,
  });

  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LottieOrIcon(
              asset: 'assets/lottie/empty.json',
              icon: PhosphorIconsDuotone.tray,
              color: context.colors.primary,
            ),
            const SizedBox(height: 12),
            Text(title.tr, style: context.text.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              body.tr,
              style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              PrimaryButton(label: action!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({required this.onRetry, this.messageKey, super.key});

  final VoidCallback onRetry;
  final String? messageKey;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LottieOrIcon(
              asset: 'assets/lottie/error.json',
              icon: PhosphorIconsDuotone.wifiSlash,
              color: context.app.danger,
            ),
            const SizedBox(height: 12),
            Text('errors.title'.tr, style: context.text.headlineSmall),
            const SizedBox(height: 6),
            Text(
              (messageKey ?? 'errors.generic').tr,
              style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'common.retry', onPressed: onRetry, icon: PhosphorIconsRegular.arrowClockwise),
          ],
        ),
      ),
    );
  }
}

class _LottieOrIcon extends StatelessWidget {
  const _LottieOrIcon({
    required this.asset,
    required this.icon,
    required this.color,
  });

  final String asset;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: 120,
      child: Lottie.asset(
        asset,
        repeat: !context.reduceMotion,
        errorBuilder: (_, _, _) => Icon(icon, size: 72, color: color),
      ),
    );
  }
}
