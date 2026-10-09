import 'package:edunest/core/theme/accent_palettes.dart';
import 'package:edunest/core/theme/app_colors.dart';
import 'package:edunest/core/theme/app_typography.dart';
import 'package:edunest/core/theme/tokens.dart';
import 'package:flutter/material.dart';

enum AppThemeMode { light, dark, amoled, system }

abstract final class AppTheme {
  static ThemeData resolve({
    required AccentPalette accent,
    required AppThemeMode mode,
    required Brightness platformBrightness,
    ColorScheme? dynamicLight,
    ColorScheme? dynamicDark,
  }) {
    final dark =
        mode == AppThemeMode.dark ||
        mode == AppThemeMode.amoled ||
        (mode == AppThemeMode.system &&
            platformBrightness == Brightness.dark);
    if (mode == AppThemeMode.amoled) {
      return amoled(accent, dynamicScheme: dynamicDark);
    }
    if (dark) return AppTheme.dark(accent, dynamicScheme: dynamicDark);
    return light(accent, dynamicScheme: dynamicLight);
  }

  static ThemeData light(AccentPalette accent, {ColorScheme? dynamicScheme}) {
    final scheme = _scheme(
      accent: accent,
      brightness: Brightness.light,
      dynamicScheme: dynamicScheme,
      surface: const Color(0xFFF7F8FC),
      surfaceLow: const Color(0xFFFFFFFF),
      surfaceContainer: const Color(0xFFEEF1F8),
      surfaceHigh: const Color(0xFFE6EAF3),
      onSurface: const Color(0xFF1C2434),
      onSurfaceVariant: const Color(0xFF5C6B82),
      outline: const Color(0xFFD5DDEA),
    );
    return _base(
      scheme: scheme,
      colors: AppColors.light(
        gradientStart: accent.gradientStart,
        gradientEnd: accent.gradientEnd,
      ),
    );
  }

  static ThemeData dark(AccentPalette accent, {ColorScheme? dynamicScheme}) {
    final scheme = _scheme(
      accent: accent,
      brightness: Brightness.dark,
      dynamicScheme: dynamicScheme,
      surface: const Color(0xFF101826),
      surfaceLow: const Color(0xFF172232),
      surfaceContainer: const Color(0xFF1C2940),
      surfaceHigh: const Color(0xFF24344D),
      onSurface: const Color(0xFFE7EEF8),
      onSurfaceVariant: const Color(0xFFA9B6C9),
      outline: const Color(0xFF314158),
    );
    return _base(
      scheme: scheme,
      colors: AppColors.dark(
        gradientStart: accent.gradientStart,
        gradientEnd: accent.gradientEnd,
      ),
    );
  }

  static ThemeData amoled(AccentPalette accent, {ColorScheme? dynamicScheme}) {
    final scheme = _scheme(
      accent: accent,
      brightness: Brightness.dark,
      dynamicScheme: dynamicScheme,
      surface: const Color(0xFF000000),
      surfaceLow: const Color(0xFF0A0A0A),
      surfaceContainer: const Color(0xFF141414),
      surfaceHigh: const Color(0xFF1C1C1C),
      onSurface: const Color(0xFFF4F7FB),
      onSurfaceVariant: const Color(0xFFB7C0CC),
      outline: const Color(0xFF2A2A2A),
    );
    return _base(
      scheme: scheme,
      colors: AppColors.dark(
        gradientStart: accent.gradientStart,
        gradientEnd: accent.gradientEnd,
        amoled: true,
      ),
    );
  }

  static ColorScheme _scheme({
    required AccentPalette accent,
    required Brightness brightness,
    required ColorScheme? dynamicScheme,
    required Color surface,
    required Color surfaceLow,
    required Color surfaceContainer,
    required Color surfaceHigh,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color outline,
  }) {
    final base =
        dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: accent.seed,
          brightness: brightness,
        );
    return base.copyWith(
      primary: dynamicScheme == null ? accent.seed : base.primary,
      surface: surface,
      surfaceContainerLowest: surfaceLow,
      surfaceContainerLow: surfaceLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceHigh,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outline,
    );
  }

  static ThemeData _base({
    required ColorScheme scheme,
    required AppColors colors,
  }) {
    final text = AppTypography.textTheme(scheme.onSurface, scheme.onSurfaceVariant);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      extensions: [colors],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: scheme.onSurface,
        titleTextStyle: text.headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: colors.cardBorder),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: shape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: shape,
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: colors.danger),
        ),
        labelStyle: text.bodyMedium,
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        labelStyle: text.labelLarge,
      ),
    );
  }
}
