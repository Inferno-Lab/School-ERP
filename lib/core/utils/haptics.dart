import 'package:flutter/services.dart';

abstract final class Haptics {
  static void light() => HapticFeedback.lightImpact();

  static void medium() => HapticFeedback.mediumImpact();

  static void selection() => HapticFeedback.selectionClick();
}
