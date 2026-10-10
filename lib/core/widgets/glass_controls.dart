import 'package:edunest/core/theme/app_colors.dart';
import 'package:edunest/core/theme/app_typography.dart';
import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/haptics.dart';
import 'package:edunest/core/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Glass segmented control with a droplet that stretches as it slides.
class GlassSegmented extends StatefulWidget {
  const GlassSegmented({
    required this.labels,
    required this.index,
    required this.onChanged,
    this.height = 56,
    this.onPigment = false,
    this.droplet,
    this.dropletText,
    this.fontSize = 15,
    this.semanticLabel,
    super.key,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final double height;

  /// Sits over a pigment: unselected labels turn white with a soft shadow.
  final bool onPigment;

  /// Solid droplet colour; null means a clear glass lens.
  final Color? droplet;
  final Color? dropletText;
  final double fontSize;
  final String? semanticLabel;

  @override
  State<GlassSegmented> createState() => _GlassSegmentedState();
}

class _GlassSegmentedState extends State<GlassSegmented> {
  var _moving = false;

  @override
  void didUpdateWidget(GlassSegmented old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      setState(() => _moving = true);
      Future<void>.delayed(const Duration(milliseconds: 260), () {
        if (mounted) setState(() => _moving = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    final still = context.reduceMotion;
    final pad = widget.height >= 52 ? 5.0 : 4.0;
    final dropH = widget.height - pad * 2;
    return Semantics(
      label: widget.semanticLabel,
      container: true,
      child: Glass(
        height: widget.height,
        radius: widget.height / 2,
        tint: widget.onPigment ? const Color(0x0FFFFFFF) : null,
        child: LayoutBuilder(
          builder: (context, box) {
            final slot = (box.maxWidth - pad * 2) / widget.labels.length;
            final dropletColor = widget.droplet;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: still ? Duration.zero : const Duration(milliseconds: 550),
                  curve: kSpring,
                  left: pad + widget.index * slot,
                  top: pad,
                  width: slot,
                  height: dropH,
                  child: Transform.scale(
                    scaleX: _moving && !still ? 1.2 : 1,
                    scaleY: _moving && !still ? .88 : 1,
                    child: dropletColor != null
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              color: dropletColor,
                              borderRadius: BorderRadius.circular(dropH / 2),
                              boxShadow: [
                                BoxShadow(color: dropletColor.withValues(alpha: .45), blurRadius: 12, spreadRadius: -3, offset: const Offset(0, 4)),
                              ],
                            ),
                          )
                        : Glass(
                            kind: GlassKind.lens,
                            radius: dropH / 2,
                            tint: widget.onPigment
                                ? const Color(0xE6FFFFFF)
                                : (c.dark ? const Color(0x33FFFFFF) : const Color(0x8CFFFFFF)),
                          ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  child: Row(
                    children: [
                      for (var i = 0; i < widget.labels.length; i++)
                        Expanded(child: _segment(context, i)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _segment(BuildContext context, int i) {
    final c = context.app;
    final on = i == widget.index;
    final Color color;
    if (on) {
      color = widget.dropletText ?? (widget.onPigment ? const Color(0xFF10201B) : c.ink);
    } else {
      color = widget.onPigment ? AppColors.white : c.ink3;
    }
    return Semantics(
      button: true,
      selected: on,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (on) return;
          Haptics.selection();
          widget.onChanged(i);
        },
        child: SizedBox(
          height: widget.height,
          child: Center(
            child: Text(
              widget.labels[i].tr,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: anek(widget.fontSize, on ? 720 : (widget.onPigment ? 650 : 560), height: 1, color: color).copyWith(
                shadows: widget.onPigment && !on ? const [Shadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 1))] : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Switch: solid track, glass thumb that swells into a lens while pressed.
class GlassSwitch extends StatefulWidget {
  const GlassSwitch({
    required this.value,
    required this.onChanged,
    required this.label,
    this.onColor,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final Color? onColor;

  @override
  State<GlassSwitch> createState() => _GlassSwitchState();
}

class _GlassSwitchState extends State<GlassSwitch> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    final on = widget.value;
    final still = context.reduceMotion;
    return Semantics(
      toggled: on,
      label: widget.label.tr,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onChanged == null
            ? null
            : () {
                Haptics.selection();
                widget.onChanged!(!on);
              },
        child: SizedBox(
          width: 64,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: AppDurations.fast,
              curve: kEase,
              width: 64,
              height: 32,
              decoration: BoxDecoration(
                color: on ? (widget.onColor ?? c.ink) : c.ink.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: still ? Duration.zero : AppDurations.medium,
                    curve: kSpring,
                    left: on ? 21 : 2,
                    top: 2,
                    width: 41,
                    height: 28,
                    child: AnimatedScale(
                      scale: _pressed && !still ? 1.3 : 1,
                      duration: AppDurations.fast,
                      curve: kSpring,
                      child: Glass(
                        kind: GlassKind.lens,
                        radius: 14,
                        tint: Color.fromRGBO(255, 255, 255, _pressed ? .12 : .78),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Slider with a glass thumb. [value] is 0..1; [divisions] snaps it.
class GlassSlider extends StatefulWidget {
  const GlassSlider({
    required this.value,
    required this.onChanged,
    required this.label,
    this.valueLabel,
    this.divisions,
    this.fill,
    this.onChangeEnd,
    this.thumbChild,
    this.thumbWidth = 48,
    super.key,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final String label;
  final String? valueLabel;
  final int? divisions;
  final Color? fill;
  final Widget? thumbChild;
  final double thumbWidth;

  @override
  State<GlassSlider> createState() => _GlassSliderState();
}

class _GlassSliderState extends State<GlassSlider> {
  var _dragging = false;

  double _snap(double v) {
    final clamped = v.clamp(0.0, 1.0);
    final d = widget.divisions;
    if (d == null || d <= 0) return clamped;
    return (clamped * d).round() / d;
  }

  void _update(double dx, double width) {
    final travel = width - widget.thumbWidth;
    final next = _snap((dx - widget.thumbWidth / 2) / travel);
    if (next != widget.value) {
      if (widget.divisions != null) HapticFeedback.selectionClick();
      widget.onChanged(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    return Semantics(
      slider: true,
      label: widget.label.tr,
      value: widget.valueLabel,
      increasedValue: widget.valueLabel,
      onIncrease: () => widget.onChanged(_snap(widget.value + 1 / (widget.divisions ?? 10))),
      onDecrease: () => widget.onChanged(_snap(widget.value - 1 / (widget.divisions ?? 10))),
      child: LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth;
          final left = (width - widget.thumbWidth) * widget.value;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) {
              setState(() => _dragging = true);
              _update(d.localPosition.dx, width);
            },
            onHorizontalDragUpdate: (d) => _update(d.localPosition.dx, width),
            onHorizontalDragEnd: (_) {
              setState(() => _dragging = false);
              widget.onChangeEnd?.call(widget.value);
            },
            onTapUp: (d) {
              _update(d.localPosition.dx, width);
              widget.onChangeEnd?.call(widget.value);
            },
            child: SizedBox(
              height: 44,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(color: c.paper2, borderRadius: BorderRadius.circular(4)),
                  ),
                  Container(
                    width: left + widget.thumbWidth / 2,
                    height: 8,
                    decoration: BoxDecoration(color: widget.fill ?? c.ink, borderRadius: BorderRadius.circular(4)),
                  ),
                  AnimatedPositioned(
                    duration: _dragging || context.reduceMotion ? Duration.zero : AppDurations.medium,
                    curve: kSpring,
                    left: left,
                    top: 5,
                    width: widget.thumbWidth,
                    height: 34,
                    child: AnimatedScale(
                      scale: _dragging && !context.reduceMotion ? 1.08 : 1,
                      duration: AppDurations.fast,
                      child: Glass(
                        kind: GlassKind.lens,
                        radius: 17,
                        tint: const Color(0x80FFFFFF),
                        child: widget.thumbChild == null ? null : Center(child: widget.thumbChild),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
