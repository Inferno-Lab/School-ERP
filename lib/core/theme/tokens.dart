import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;
}

abstract final class AppRadius {
  static const card = 22.0;
  static const button = 15.0;
  static const chip = 999.0;
  static const sheet = 28.0;
  static const input = 14.0;
  static const tile = 18.0;
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 400);
  static const splash = Duration(milliseconds: 1500);
}

abstract final class AppCurves {
  static const ease = Curves.easeOutCubic;
}

abstract final class AppBreakpoints {
  static const tablet = 840.0;
}

List<BoxShadow> softShadow(Color tint) => [
  BoxShadow(
    color: tint.withValues(alpha: 0.08),
    blurRadius: 24,
    offset: const Offset(0, 10),
  ),
  BoxShadow(
    color: tint.withValues(alpha: 0.04),
    blurRadius: 6,
    offset: const Offset(0, 2),
  ),
];
