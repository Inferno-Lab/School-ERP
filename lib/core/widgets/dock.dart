import 'dart:async';

import 'package:edunest/core/theme/app_colors.dart';
import 'package:edunest/core/theme/app_typography.dart';
import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/haptics.dart';
import 'package:edunest/core/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DockItem {
  const DockItem({required this.icon, required this.activeIcon, required this.label, this.badge = 0});

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badge;
}

/// Floating glass dock. The selected tab is a thicker glass droplet that
/// stretches as it slides between tabs.
class GlassDock extends StatefulWidget {
  const GlassDock({required this.items, required this.index, required this.onChanged, super.key});

  final List<DockItem> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  State<GlassDock> createState() => _GlassDockState();
}

class _GlassDockState extends State<GlassDock> {
  var _moving = false;
  Timer? _settle;

  @override
  void didUpdateWidget(GlassDock old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      setState(() => _moving = true);
      _settle?.cancel();
      _settle = Timer(const Duration(milliseconds: 260), () {
        if (mounted) setState(() => _moving = false);
      });
    }
  }

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    final still = context.reduceMotion;
    return Glass(
      height: 64,
      radius: 32,
      child: LayoutBuilder(
        builder: (context, box) {
          const pad = 7.0;
          final slot = (box.maxWidth - pad * 2) / widget.items.length;
          final drop = (slot - 4.8).clamp(52.0, 76.0);
          return Stack(
            children: [
              AnimatedPositioned(
                duration: still ? Duration.zero : const Duration(milliseconds: 550),
                curve: const Cubic(.3, 1.35, .4, 1),
                left: pad + widget.index * slot + (slot - drop) / 2,
                top: 6,
                width: drop,
                height: 52,
                child: AnimatedScale(
                  scale: _moving && !still ? 1.12 : 1,
                  duration: AppDurations.fast,
                  curve: kEase,
                  child: Transform.scale(
                    scaleX: _moving && !still ? 1.14 : 1,
                    scaleY: _moving && !still ? .76 : 1,
                    child: Glass(
                      kind: GlassKind.lens,
                      radius: 26,
                      tint: c.dark ? const Color(0x24FFFFFF) : const Color(0x42FFFFFF),
                      shadow: false,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: pad),
                child: Row(
                  children: [
                    for (var i = 0; i < widget.items.length; i++)
                      Expanded(
                        child: _DockButton(
                          item: widget.items[i],
                          on: i == widget.index,
                          onTap: () {
                            if (i == widget.index) return;
                            Haptics.selection();
                            widget.onChanged(i);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({required this.item, required this.on, required this.onTap});

  final DockItem item;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    final color = on ? c.ink : c.ink3;
    return Semantics(
      button: true,
      selected: on,
      label: item.label.tr,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(on ? item.activeIcon : item.icon, size: 22, color: color),
                  const SizedBox(height: 3),
                  Text(
                    item.label.tr,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: anek(11, on ? 720 : 560, width: 106, height: 1, color: color),
                  ),
                ],
              ),
              if (item.badge > 0)
                // Pinned to the icon's top-right; sized by its digits, never by the tab.
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 9, left: 30),
                    child: _Badge(count: item.badge),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vertical glass rail used from 840px wide (tablet).
class GlassRail extends StatelessWidget {
  const GlassRail({required this.items, required this.index, required this.onChanged, super.key});

  final List<DockItem> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    const slot = 76.0;
    return Glass(
      width: 76,
      height: slot * items.length + 20,
      radius: 38,
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 550),
            curve: const Cubic(.3, 1.35, .4, 1),
            left: 8,
            top: 10 + index * slot + (slot - 60) / 2,
            width: 60,
            height: 60,
            child: Glass(
              kind: GlassKind.lens,
              radius: 30,
              tint: c.dark ? const Color(0x24FFFFFF) : const Color(0x66FFFFFF),
              shadow: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  Semantics(
                    button: true,
                    selected: i == index,
                    label: items[i].label.tr,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(i),
                      child: SizedBox(
                        width: 76,
                        height: slot,
                        child: Icon(
                          i == index ? items[i].activeIcon : items[i].icon,
                          size: 24,
                          color: i == index ? c.ink : c.ink3,
                        ),
                      ),
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

/// Round count pill: a circle for one digit, a short pill beyond that.
class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bad,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.app.paper, width: 1.5),
      ),
      child: SizedBox(
        height: 16,
        width: text.length == 1 ? 16 : null,
        child: Center(
          widthFactor: text.length == 1 ? null : 1,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: text.length == 1 ? 0 : 4),
            child: Text(text, style: anek(10, 700, height: 1, color: AppColors.white, tabular: true)),
          ),
        ),
      ),
    );
  }
}
