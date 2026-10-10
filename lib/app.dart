import 'package:edunest/core/bindings/initial_binding.dart';
import 'package:edunest/core/config/app_config.dart';
import 'package:edunest/core/routes/app_pages.dart';
import 'package:edunest/core/routes/app_routes.dart';
import 'package:edunest/core/services/theme_service.dart';
import 'package:edunest/core/theme/app_theme.dart';
import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/translations/app_translations.dart';
import 'package:edunest/core/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EduNestApp extends StatelessWidget {
  const EduNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeService>();
    return GetMaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: theme.locale.value,
      fallbackLocale: const Locale('en'),
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      theme: AppTheme.resolve(mode: AppThemeMode.light, platformBrightness: Brightness.light),
      builder: (context, child) {
        return Obx(() {
          final data = AppTheme.resolve(
            mode: theme.mode.value,
            platformBrightness: MediaQuery.platformBrightnessOf(context),
          );
          return AnimatedTheme(
            data: data,
            duration: theme.reduceMotion.value ? Duration.zero : AppDurations.slow,
            curve: kEase,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(theme.textScale.value),
              ),
              child: ToastHost(child: child ?? const SizedBox.shrink()),
            ),
          );
        });
      },
    );
  }
}
