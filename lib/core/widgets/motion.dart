import 'package:edunest/core/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

extension EnterMotion on Widget {
  Widget enter(BuildContext context, [int index = 0]) {
    if (context.reduceMotion) return this;
    return animate(delay: (40 * index).ms)
        .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.06, end: 0, duration: 280.ms, curve: Curves.easeOutCubic);
  }
}
