import 'dart:async';

import 'package:edunest/core/services/connectivity_service.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class FeaturePage extends StatelessWidget {
  const FeaturePage({
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.onRefresh,
    this.floating,
    this.slivers,
    this.expand = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;
  final Future<void> Function()? onRefresh;
  final Widget? floating;
  final List<Widget>? slivers;

  /// Gives [child] a bounded height so a tablet master/detail row can scroll.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final headerActions = expand && onRefresh != null
        ? [
            IconButton(
              tooltip: 'common.retry'.tr,
              onPressed: () => unawaited(onRefresh!()),
              icon: const Icon(PhosphorIconsRegular.arrowClockwise),
            ),
            ...actions,
          ]
        : actions;
    if (expand) {
      return Scaffold(
        floatingActionButton: floating,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(title: title, subtitle: subtitle, actions: headerActions),
              const OfflineBanner(),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }
    final scroll = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Header(title: title, subtitle: subtitle, actions: actions)),
        const SliverToBoxAdapter(child: OfflineBanner()),
        ...?slivers,
        if (slivers == null) SliverToBoxAdapter(child: child),
      ],
    );
    return Scaffold(
      floatingActionButton: floating,
      body: SafeArea(
        bottom: false,
        child: onRefresh == null
            ? scroll
            : RefreshIndicator(onRefresh: onRefresh!, child: scroll),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.actions,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (Navigator.of(context).canPop())
              IconButton(
              onPressed: () => Get.back<void>(),
              icon: const Icon(PhosphorIconsRegular.caretLeft),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.headlineLarge,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!.tr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.action, this.onAction, super.key});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(title.tr, style: context.text.headlineSmall)),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!.tr)),
        ],
      ),
    );
  }
}

class GradientHeader extends StatelessWidget {
  const GradientHeader({required this.child, this.height = 210, super.key});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [context.app.gradientStart, context.app.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              const Positioned(right: -30, top: -20, child: _Blob(size: 140)),
              const Positioned(left: -20, bottom: -30, child: _Blob(size: 100)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.14),
      ),
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ConnectivityService>()) return const SizedBox.shrink();
    return Obx(() {
      final online = Get.find<ConnectivityService>().isOnline.value;
      if (online) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.app.warningContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(PhosphorIconsRegular.wifiSlash, color: context.app.warning, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'common.offline'.tr,
                style: context.text.bodySmall?.copyWith(color: context.app.warning),
              ),
            ),
          ],
        ),
      );
    });
  }
}
