import 'package:edunest/core/services/theme_service.dart';
import 'package:edunest/core/theme/app_colors.dart';
import 'package:edunest/core/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

extension AppContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  AppColors get app => Theme.of(this).extension<AppColors>()!;

  TextTheme get text => Theme.of(this).textTheme;

  bool get isWide => MediaQuery.sizeOf(this).width >= AppBreakpoints.tablet;

  bool get reduceMotion =>
      MediaQuery.disableAnimationsOf(this) ||
      (Get.isRegistered<ThemeService>() &&
          Get.find<ThemeService>().reduceMotion.value);
}

extension DateOnly on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}
