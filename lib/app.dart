import 'package:dynamic_color/dynamic_color.dart';
import 'package:edunest/core/bindings/initial_binding.dart';
import 'package:edunest/core/config/app_config.dart';
import 'package:edunest/core/routes/app_pages.dart';
import 'package:edunest/core/routes/app_routes.dart';
import 'package:edunest/core/services/theme_service.dart';
import 'package:edunest/core/theme/accent_palettes.dart';
import 'package:edunest/core/theme/app_theme.dart';
import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/translations/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EduNestApp extends StatelessWidget {
  const EduNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeService>();
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return GetMaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          translations: AppTranslations(),
          locale: theme.locale.value,
          fallbackLocale: const Locale('en'),
          initialBinding: InitialBinding(),
          initialRoute: AppRoutes.splash,
          getPages: AppPages.pages,
          theme: AppTheme.light(AccentPalette.all.first),
          darkTheme: AppTheme.dark(AccentPalette.all.first),
          builder: (context, child) {
            return Obx(() {
              final data = AppTheme.resolve(
                accent: theme.accent.value,
                mode: theme.mode.value,
                platformBrightness: MediaQuery.platformBrightnessOf(context),
                dynamicLight: theme.useDynamicColor.value ? lightDynamic : null,
                dynamicDark: theme.useDynamicColor.value ? darkDynamic : null,
              );
              return AnimatedTheme(
                data: data,
                duration: theme.reduceMotion.value
                    ? Duration.zero
                    : AppDurations.slow,
                curve: AppCurves.ease,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(theme.textScale.value),
                  ),
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            });
          },
        );
      },
    );
  }
}
