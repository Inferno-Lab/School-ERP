import 'package:edunest/core/services/theme_service.dart';
import 'package:edunest/core/theme/accent_palettes.dart';
import 'package:edunest/core/theme/app_theme.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/widgets/app_avatar.dart';
import 'package:edunest/core/widgets/app_card.dart';
import 'package:edunest/core/widgets/buttons.dart';
import 'package:edunest/core/widgets/chips.dart';
import 'package:edunest/core/widgets/feature_page.dart';
import 'package:edunest/core/widgets/glass_card.dart';
import 'package:edunest/core/widgets/misc.dart';
import 'package:edunest/core/widgets/progress.dart';
import 'package:edunest/core/widgets/states.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DesignSystemView extends StatelessWidget {
  const DesignSystemView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeService>();
    return FeaturePage(
      title: 'menu.design',
      subtitle: 'settings.subtitle',
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final mode in AppThemeMode.values)
                ActionChip(
                  label: Text(mode.name),
                  onPressed: () => theme.setMode(mode),
                ),
              for (final accent in AccentPalette.all)
                ActionChip(
                  label: Text(accent.nameKey.tr),
                  onPressed: () => theme.setAccent(accent),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const PrimaryButton(label: 'common.submit', onPressed: _noop),
          const SizedBox(height: 8),
          const SecondaryButton(label: 'common.cancel', onPressed: _noop),
          const SizedBox(height: 12),
          const AppCard(child: Text('App card')),
          const SizedBox(height: 12),
          const GlassCard(child: Text('Glass card')),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              const SoftChip(label: 'subject.maths'),
              const SubjectChip(subject: 'science'),
              attendanceBadge(context, 'present'),
              attendanceBadge(context, 'overdue'),
            ],
          ),
          const SizedBox(height: 12),
          const AppAvatar(name: 'Aarav Sharma', size: 56),
          const SizedBox(height: 12),
          const StatTile(label: 'home.attendance', value: '92%', icon: PhosphorIconsRegular.calendar),
          const SizedBox(height: 12),
          const AnimatedProgressRing(percent: 86, child: Text('86')),
          const SizedBox(height: 12),
          const AnimatedBar(value: 0.7),
          const SizedBox(height: 12),
          const TimelineTile(title: 'status.pending', subtitle: 'Today', done: true),
          const TimelineTile(title: 'status.approved', subtitle: 'Next', done: false, last: true),
          const SizedBox(height: 12),
          Text('Display', style: context.text.displaySmall),
          Text('Headline', style: context.text.headlineLarge),
          Text('Body copy for the school day.', style: context.text.bodyMedium),
          Text('CAPTION', style: context.text.labelSmall),
          const SizedBox(height: 12),
          const EmptyState(title: 'empty.title', body: 'empty.body'),
        ],
      ),
    );
  }
}

void _noop() {}
