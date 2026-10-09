import 'dart:ui';

import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/haptics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NavDestination {
  const NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    required this.index,
    required this.destinations,
    required this.onChanged,
    super.key,
  });

  final int index;
  final List<NavDestination> destinations;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.app.glassFill,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: context.app.glassBorder),
              boxShadow: softShadow(context.app.shadow),
            ),
            child: SizedBox(
              height: 68,
              child: Row(
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    Expanded(
                      child: _Item(
                        destination: destinations[i],
                        selected: i == index,
                        onTap: () {
                          Haptics.selection();
                          onChanged(i);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.colors.primary : context.colors.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label.tr,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: AppDurations.fast,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? context.colors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Icon(
                selected ? destination.activeIcon : destination.icon,
                color: color,
                size: 24,
              ),
            ),
            AnimatedSize(
              duration: AppDurations.fast,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        destination.label.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.primary,
                          fontSize: 11,
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({
    required this.index,
    required this.destinations,
    required this.onChanged,
    required this.child,
    super.key,
  });

  final int index;
  final List<NavDestination> destinations;
  final ValueChanged<int> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!context.isWide) {
      return Scaffold(
        body: child,
        extendBody: true,
        bottomNavigationBar: FloatingNavBar(
          index: index,
          destinations: destinations,
          onChanged: onChanged,
        ),
      );
    }
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: onChanged,
            labelType: NavigationRailLabelType.all,
            backgroundColor: context.colors.surfaceContainerLowest,
            destinations: [
              for (final item in destinations)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.activeIcon),
                  label: Text(item.label.tr),
                ),
            ],
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
