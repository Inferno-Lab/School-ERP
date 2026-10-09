import 'package:flutter/material.dart';

abstract final class AppTypography {
  static TextTheme textTheme(Color color, Color muted) {
    TextStyle display(double size, FontWeight weight, {double tracking = -0.6}) {
      return TextStyle(
        fontFamily: 'Poppins',
        fontWeight: weight,
        fontSize: size,
        height: 1.2,
        letterSpacing: tracking,
        color: color,
      );
    }

    TextStyle body(double size, FontWeight weight, {double height = 1.45}) {
      return TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: weight,
        fontVariations: [FontVariation.weight(weight.value.toDouble())],
        fontSize: size,
        height: height,
        color: color,
      );
    }

    return TextTheme(
      displaySmall: display(32, FontWeight.w700),
      headlineLarge: display(26, FontWeight.w700, tracking: -0.4),
      headlineMedium: display(22, FontWeight.w700, tracking: -0.3),
      headlineSmall: display(18, FontWeight.w600, tracking: -0.2),
      titleMedium: body(16, FontWeight.w600, height: 1.3),
      titleSmall: body(14, FontWeight.w600, height: 1.3),
      bodyLarge: body(16, FontWeight.w500),
      bodyMedium: body(14, FontWeight.w400),
      bodySmall: body(12, FontWeight.w500).copyWith(color: muted),
      labelLarge: body(14, FontWeight.w600),
      labelSmall: body(11, FontWeight.w600, height: 1.2).copyWith(
        color: muted,
        letterSpacing: 0.8,
      ),
    );
  }

  static TextStyle numeric(BuildContext context, {double size = 28}) {
    return TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontWeight: FontWeight.w700,
      fontVariations: const [FontVariation.weight(700)],
      fontFeatures: const [FontFeature.tabularFigures()],
      fontSize: size,
      height: 1.1,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
}
