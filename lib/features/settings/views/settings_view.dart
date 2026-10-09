import 'dart:async';

import 'package:edunest/core/config/app_config.dart';
import 'package:edunest/core/routes/app_routes.dart';
import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/services/theme_service.dart';
import 'package:edunest/core/theme/accent_palettes.dart';
import 'package:edunest/core/theme/app_theme.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/widgets/app_bottom_sheet.dart';
import 'package:edunest/core/widgets/feature_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeService>();
    return FeaturePage(
      title: 'settings.title',
      subtitle: 'settings.subtitle',
      child: Obx(() {
        return ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          children: [
            Text('settings.theme'.tr, style: context.text.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final mode in AppThemeMode.values)
                  ChoiceChip(
                    label: Text('settings.${mode.name}'.tr),
                    selected: theme.mode.value == mode,
                    onSelected: (_) => theme.setMode(mode),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('settings.accent'.tr, style: context.text.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                for (final accent in AccentPalette.all)
                  GestureDetector(
                    onTap: () => theme.setAccent(accent),
                    child: Tooltip(
                      message: accent.nameKey.tr,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accent.seed,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.accent.value.preset == accent.preset
                                ? context.colors.onSurface
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('settings.dynamic'.tr),
              value: theme.useDynamicColor.value,
              onChanged: (value) => theme.setDynamicColor(value: value),
            ),
            Text('settings.text'.tr, style: context.text.titleMedium),
            Slider(
              value: theme.textScale.value,
              min: 0.9,
              max: 1.2,
              divisions: 2,
              label: theme.textScale.value < 0.95
                  ? 'settings.small'.tr
                  : theme.textScale.value > 1.05
                  ? 'settings.large'.tr
                  : 'settings.default'.tr,
              onChanged: theme.setTextScale,
            ),
            Text('settings.language'.tr, style: context.text.titleMedium),
            Wrap(
              spacing: 8,
              children: [
                for (final item in const [('en', 'English'), ('hi', 'हिन्दी'), ('mr', 'मराठी')])
                  ChoiceChip(
                    label: Text(item.$2),
                    selected: theme.locale.value.languageCode == item.$1,
                    onSelected: (_) => theme.setLocale(Locale(item.$1)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('settings.notifications'.tr, style: context.text.titleMedium),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('settings.homework'.tr),
              value: theme.notifyHomework.value,
              onChanged: (value) => theme.setNotify(homework: value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('settings.fees'.tr),
              value: theme.notifyFees.value,
              onChanged: (value) => theme.setNotify(fees: value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('settings.chat'.tr),
              value: theme.notifyChat.value,
              onChanged: (value) => theme.setNotify(chat: value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('settings.motion'.tr),
              value: theme.reduceMotion.value,
              onChanged: (value) => theme.setReduceMotion(value: value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('settings.errors'.tr),
              subtitle: Text('settings.errors_help'.tr),
              value: AppConfig.simulateErrors.value,
              onChanged: (value) => theme.setSimulateErrors(value: value),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('common.logout'.tr),
              onTap: () async {
                final ok = await confirmSheet(
                  title: 'settings.logout_title',
                  body: 'settings.logout_body',
                  confirm: 'common.logout',
                );
                if (!ok) return;
                await Get.find<AuthService>().logout();
                unawaited(Get.offAllNamed<void>(AppRoutes.login));
              },
            ),
            GestureDetector(
              onLongPress: () => Get.toNamed<void>(AppRoutes.designSystem),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'common.version'.trParams({'version': AppConfig.version}),
                  style: context.text.bodySmall,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class HelpView extends StatelessWidget {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    return FeaturePage(
      title: 'help.title',
      subtitle: 'help.contact',
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            for (var i = 1; i <= 3; i++)
              ExpansionTile(
                title: Text('help.faq${i}_q'.tr),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('help.faq${i}_a'.tr),
                  ),
                ],
              ),
            ListTile(
              title: Text('help.contact'.tr),
              subtitle: const Text('hello@greenfield.edu.in · +91 20 4567 8900'),
            ),
          ],
        ),
      ),
    );
  }
}
