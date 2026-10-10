import 'dart:math' as math;

import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/widgets/glass.dart';
import 'package:edunest/core/widgets/states.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Space a tab page leaves for the floating dock.
const kDockClearance = 112.0;

/// Phone page: content scrolls beneath floating glass controls at the top and
/// an optional glass bar at the bottom.
class PageFrame extends StatelessWidget {
  const PageFrame({
    required this.children,
    this.leading,
    this.actions = const [],
    this.bottomBar,
    this.bottomBarHeight = 64,
    this.background,
    this.onRefresh,
    this.dockPage = false,
    this.underlay,
    this.topPadding,
    this.padContent = true,
    this.topFade = true,
    this.controller,
    super.key,
  });

  final List<Widget> children;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? bottomBar;
  final double bottomBarHeight;
  final Color? background;
  final Future<void> Function()? onRefresh;

  /// Leaves room for the shell's dock instead of a bottom bar.
  final bool dockPage;

  /// Full-bleed art behind the top controls (pigment hero, ribbon, map).
  final Widget? underlay;

  /// Overrides where content starts (default: below the top controls).
  final double? topPadding;
  final bool padContent;

  /// Fade content out under the top controls; off where art already fills the top edge.
  final bool topFade;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final top = inset.top + 8;
    // On a tab page a bottom bar floats above the dock.
    final barLift = dockPage ? 76.0 : 0.0;
    final bottomSpace = bottomBar != null
        ? bottomBarHeight + 48 + barLift + inset.bottom
        : dockPage
        ? kDockClearance + inset.bottom
        : 32 + inset.bottom;
    final hasTopRow = leading != null || actions.isNotEmpty;
    // On tablets the reading column stays phone-like and centred.
    final side = padContent ? math.max<double>(20, (MediaQuery.sizeOf(context).width - 720) / 2) : 0.0;
    final list = ListView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: EdgeInsets.fromLTRB(side, topPadding ?? (hasTopRow ? top + 58 : top + 8), side, bottomSpace),
      children: [
        if (underlay == null) const OfflineCapsule(),
        ...children,
      ],
    );
    return Scaffold(
      backgroundColor: background ?? context.app.chalk,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          if (onRefresh == null)
            Positioned.fill(child: list)
          else
            Positioned.fill(
              child: RefreshIndicator(
                onRefresh: onRefresh!,
                color: context.app.ink,
                backgroundColor: context.app.paper,
                edgeOffset: top + 50,
                child: list,
              ),
            ),
          // Content never slides under glass: it fades out beneath the status bar and the top controls,
          // so the glass always sits on clean page colour (a card edge showing inside it looked like a bug).
          if (underlay == null && topFade)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: hasTopRow ? top + 70 : inset.top + 18,
              child: IgnorePointer(child: EdgeFade(color: background ?? context.app.chalk, solid: hasTopRow ? .78 : .6)),
            ),
          // The same under the dock or a bottom bar.
          if (dockPage || bottomBar != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: (bottomBar != null ? bottomBarHeight + 60 : 96) + (dockPage ? 76 : 0) + inset.bottom,
              child: IgnorePointer(child: EdgeFade(color: background ?? context.app.chalk, solid: .7, up: true)),
            ),
          if (hasTopRow)
            Positioned(
              left: 16,
              right: 16,
              top: top,
              child: Row(
                children: [
                  ?leading,
                  const Spacer(),
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    actions[i],
                  ],
                ],
              ),
            ),
          if (bottomBar != null)
            Positioned(
              left: 16,
              right: 16,
              // Rides above the keyboard when the bar holds a text field.
              bottom: keyboard > 0 ? keyboard + 12 : 28 + barLift + inset.bottom,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: bottomBar,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Glass back button; pops the current route.
class BackGlass extends StatelessWidget {
  const BackGlass({this.close = false, this.onTap, this.color, super.key});

  final bool close;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => GlassIconButton(
    icon: close ? PhosphorIconsRegular.x : PhosphorIconsRegular.caretLeft,
    label: close ? 'common.close'.tr : 'common.back'.tr,
    color: color,
    onTap: onTap ?? () => Get.back<void>(),
  );
}

/// Large page title with an optional line beneath.
class PageTitle extends StatelessWidget {
  const PageTitle(this.title, {this.subtitle, this.small = false, super.key});

  final String title;
  final String? subtitle;
  final bool small;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title.tr, style: small ? context.type.h2 : context.type.h1),
      if (subtitle != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(subtitle!.tr, style: context.type.cap),
        ),
    ],
  );
}

/// Section header: overline on the left, optional link on the right.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {this.action, this.onAction, this.top = 22, super.key});

  final String text;
  final String? action;
  final VoidCallback? onAction;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: top, bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text.tr.toUpperCase(),
            style: context.type.o,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                action!.tr,
                style: context.type.cap.copyWith(fontWeight: FontWeight.w600, color: context.app.ink2),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Page colour that holds solid for [solid] of its length, then fades to nothing.
class EdgeFade extends StatelessWidget {
  const EdgeFade({required this.color, required this.solid, this.up = false});

  final Color color;
  final double solid;
  final bool up;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: up ? Alignment.bottomCenter : Alignment.topCenter,
          end: up ? Alignment.topCenter : Alignment.bottomCenter,
          stops: [0, solid, 1],
          colors: [color, color.withValues(alpha: .94), color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
