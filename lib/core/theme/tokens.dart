import 'package:flutter/animation.dart';

/// Content ease: cubic-bezier(.2,.8,.2,1).
const kEase = Cubic(.2, .8, .2, 1);

/// Glass spring: cubic-bezier(.3,1.45,.45,1), a gentle ~6% overshoot.
const kSpring = Cubic(.3, 1.45, .45, 1);

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 260);
  static const medium = Duration(milliseconds: 450);
  static const slow = Duration(milliseconds: 600);
  static const rise = Duration(milliseconds: 700);
}

abstract final class AppBreakpoints {
  static const tablet = 840.0;
}

abstract final class AppRadius {
  static const card = 24.0;
  static const field = 18.0;
  static const sheet = 34.0;
}
