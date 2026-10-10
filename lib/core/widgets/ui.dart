import 'dart:async';

import 'package:edunest/core/theme/app_colors.dart';
import 'package:edunest/core/theme/app_typography.dart';
import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Short labels printed on notebook covers.
const subjectAbbr = {
  'maths': 'MA',
  'science': 'SCI',
  'english': 'EN',
  'hindi': 'HI',
  'social': 'SST',
  'computer': 'CS',
  'art': 'ART',
  'pe': 'PE',
  'music': 'MU',
};

String subjectName(String id) => 'subject.$id'.tr;

/// Uppercase tracked label ("THURSDAY · 15 OCTOBER").
class Overline extends StatelessWidget {
  const Overline(this.text, {this.color, super.key});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: context.type.o.copyWith(color: color),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

/// Notebook cover: bound on the left, subject pigment, short label at the bottom.
class Cover extends StatelessWidget {
  const Cover({
    required this.subject,
    this.label,
    this.large = false,
    this.width,
    this.height,
    super.key,
  });

  final String subject;
  final String? label;
  final bool large;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final pigment = AppColors.subject(subject);
    final w = width ?? (large ? 64.0 : 42.0);
    final h = height ?? (large ? 82.0 : 52.0);
    final r = large ? 14.0 : 11.0;
    return Container(
      width: w,
      height: h,
      padding: EdgeInsets.only(left: large ? 13 : 9, bottom: large ? 9 : 6),
      alignment: Alignment.bottomLeft,
      decoration: BoxDecoration(
        color: pigment.fill,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(large ? 6 : 5),
          bottomLeft: Radius.circular(large ? 6 : 5),
          topRight: Radius.circular(r),
          bottomRight: Radius.circular(r),
        ),
      ),
      foregroundDecoration: const _SpineDecoration(),
      child: Text(
        label ?? subjectAbbr[subject] ?? subject.substring(0, 2).toUpperCase(),
        style: anek(large ? 13 : 11, 760, width: 122, height: 1, em: .05, color: pigment.on),
        maxLines: 1,
      ),
    );
  }
}

/// The darker binding strip along the left edge of a cover.
class _SpineDecoration extends Decoration {
  const _SpineDecoration({this.width = 4});

  final double width;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _SpinePainter(width);
}

class _SpinePainter extends BoxPainter {
  _SpinePainter(this.width);

  final double width;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size!;
    final rect = offset & size;
    canvas
      ..save()
      ..clipRRect(
        RRect.fromRectAndCorners(rect, topLeft: const Radius.circular(6), bottomLeft: const Radius.circular(6)),
      )
      ..drawRect(Rect.fromLTWH(rect.left, rect.top, width, rect.height), Paint()..color = const Color(0x33000000))
      ..drawRect(Rect.fromLTWH(rect.right - 1, rect.top, 1, rect.height), Paint()..color = const Color(0x26FFFFFF))
      ..restore();
  }
}

/// Spine decoration usable on bigger custom covers (book shelf, hero bands).
const spineDecoration = _SpineDecoration(width: 6);

/// Rubber-stamp status label.
class Stamp extends StatelessWidget {
  const Stamp(this.text, {required this.color, this.size = 11, super.key});

  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 5, 8, 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: color, width: 1.6),
    ),
    child: Text(
      text.toUpperCase(),
      maxLines: 1,
      style: anek(size, 760, width: 118, height: 1, em: .09, color: color),
    ),
  );
}

class Dot extends StatelessWidget {
  const Dot(this.color, {this.size = 8, super.key});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Live indicator: a dot breathing between full and 35% opacity every 2.2s.
class PulseDot extends StatefulWidget {
  const PulseDot(this.color, {super.key});

  final Color color;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: 1, end: .35).chain(CurveTween(curve: Curves.easeInOut)).animate(_c),
    child: Dot(widget.color),
  );
}

/// Dashed rule (receipt slips, exam sittings).
class DashedLine extends StatelessWidget {
  const DashedLine({this.color, this.dash = 6, this.gap = 4, this.thickness = 1.5, super.key});

  final Color? color;
  final double dash;
  final double gap;
  final double thickness;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Row(
      children: [
        for (var i = 0; i < box.maxWidth ~/ (dash + gap); i++)
          Container(
            width: dash,
            height: thickness,
            margin: EdgeInsets.only(right: gap),
            color: color ?? context.app.line2,
          ),
      ],
    ),
  );
}

class Hr extends StatelessWidget {
  const Hr({this.indent = 0, super.key});

  final double indent;

  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    margin: EdgeInsets.only(left: indent),
    color: context.app.line,
  );
}

/// Solid content card: paper with a hairline ring, never glass.
class EduCard extends StatelessWidget {
  const EduCard({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.color,
    this.radius = AppRadius.card,
    this.ring,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;
  final Color? ring;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.app.paper,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: ring ?? context.app.line, width: ring == null ? 1 : 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
    if (onTap == null) return body;
    return Pressable(onTap: onTap, child: body);
  }
}

/// Squash-on-press wrapper used by cards, rows and buttons.
class Pressable extends StatefulWidget {
  const Pressable({required this.child, this.onTap, this.scale = .97, this.label, super.key});

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final String? label;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        child: AnimatedScale(
          scale: _down && !context.reduceMotion ? widget.scale : 1,
          duration: _down ? const Duration(milliseconds: 90) : AppDurations.medium,
          curve: _down ? Curves.easeOut : kSpring,
          child: widget.child,
        ),
      ),
    );
  }
}

enum BtnKind { primary, ink, quiet, danger, plain }

class Btn extends StatelessWidget {
  const Btn(
    this.label, {
    required this.onPressed,
    this.kind = BtnKind.primary,
    this.small = false,
    this.icon,
    this.trailing,
    this.expand = false,
    this.loading = false,
    this.height,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final BtnKind kind;
  final bool small;
  final IconData? icon;
  final IconData? trailing;
  final bool expand;
  final bool loading;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    final (bg, fg) = switch (kind) {
      BtnKind.primary => (AppColors.mari, AppColors.mariInk),
      BtnKind.ink => (c.ink, c.chalk),
      BtnKind.quiet => (Colors.transparent, c.ink),
      BtnKind.danger => (AppColors.bad, AppColors.white),
      BtnKind.plain => (Colors.transparent, c.ink),
    };
    final h = height ?? (small ? 40.0 : 52.0);
    final disabled = onPressed == null && !loading;
    final style = anek(small ? 14.5 : 16, 650, width: 108, height: 1, color: fg);
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: fg))
        else ...[
          if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
          Flexible(
            child: Text(label.tr, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), Icon(trailing, size: 18, color: fg)],
        ],
      ],
    );
    return Opacity(
      opacity: disabled ? .4 : 1,
      child: Pressable(
        scale: .96,
        label: label.tr,
        onTap: loading ? null : onPressed,
        child: Container(
          height: h,
          padding: EdgeInsets.symmetric(horizontal: small ? 16 : 22),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(h / 2),
            border: kind == BtnKind.quiet ? Border.all(color: c.line2, width: 1.5) : null,
          ),
          child: content,
        ),
      ),
    );
  }
}

class Chip2 extends StatelessWidget {
  const Chip2(
    this.label, {
    this.on = false,
    this.onTap,
    this.icon,
    this.dot,
    this.background,
    this.foreground,
    this.height = 36,
    super.key,
  });

  final String label;
  final bool on;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? dot;
  final Color? background;
  final Color? foreground;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    final fg = foreground ?? (on ? c.chalk : c.ink2);
    return Pressable(
      onTap: onTap,
      scale: .95,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: kEase,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: background ?? (on ? c.ink : c.paper),
          borderRadius: BorderRadius.circular(height / 2),
          border: on || background != null ? null : Border.all(color: c.line2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[Dot(dot!), const SizedBox(width: 6)],
            if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 6)],
            Flexible(
              child: Text(label.tr, style: anek(14, 600, height: 1, color: fg), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar(this.name, {this.size = 40, this.background, this.foreground, this.ring, this.initials, super.key});

  final String name;
  final double size;
  final Color? background;
  final Color? foreground;
  final Color? ring;

  /// Overrides the letters, e.g. to tell siblings with one surname apart.
  final String? initials;

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p.characters.first.toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  /// Initials that tell siblings apart: a later child whose initials clash
  /// with an earlier one's uses the first two letters of their first name.
  static String siblingInitials(String name, List<String> family) {
    final mine = initialsOf(name);
    final i = family.indexOf(name);
    final clash = family.take(i < 0 ? family.length : i).any((n) => initialsOf(n) == mine);
    final first = name.trim().split(RegExp(r'\s+')).first;
    return clash && first.length > 1 ? first.substring(0, 2).toUpperCase() : mine;
  }

  /// Stable house colour for a person, so the same student always looks the same.
  static Color houseFor(String seed) => AppColors.houses[seed.hashCode.abs() % 4];

  @override
  Widget build(BuildContext context) {
    final bg = background ?? houseFor(name);
    final fg = foreground ?? (bg == AppColors.houses[3] ? AppColors.mariInk : AppColors.white);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: ring == null
            ? null
            : // Later shadows paint on top, so the outer ring goes first.
              [BoxShadow(color: ring!, spreadRadius: 4.5), BoxShadow(color: context.app.chalk, spreadRadius: 2.5)],
      ),
      child: Text(
        initials ?? initialsOf(name),
        style: anek(size * .35, 700, width: 112, height: 1, em: .02, color: fg),
      ),
    );
  }
}

/// Text field in the paper style: label above, ring, focus ring in ink.
class Field extends StatefulWidget {
  const Field({
    this.controller,
    this.label,
    this.hint,
    this.icon,
    this.trailing,
    this.obscure = false,
    this.keyboard,
    this.validator,
    this.maxLines = 1,
    this.minHeight = 56,
    this.onChanged,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.inputFormatters,
    this.fill,
    this.borderless = false,
    super.key,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? icon;
  final Widget? trailing;
  final bool obscure;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  final int maxLines;
  final double minHeight;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final List<dynamic>? inputFormatters;
  final Color? fill;

  /// No resting outline (search wells); focus and errors still draw one.
  final bool borderless;

  @override
  State<Field> createState() => _FieldState();
}

class _FieldState extends State<Field> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    return FormField<String>(
      initialValue: widget.controller?.text,
      validator: widget.validator == null ? null : (_) => widget.validator!(widget.controller?.text),
      builder: (state) {
        final error = state.errorText;
        final ringColor = error != null
            ? AppColors.bad
            : (_focus.hasFocus ? c.ink : (widget.borderless ? Colors.transparent : c.line2));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(widget.label!.tr, style: anek(13, 620, height: 1.2, color: c.ink2)),
              ),
            AnimatedContainer(
              duration: AppDurations.fast,
              constraints: BoxConstraints(minHeight: widget.minHeight),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: widget.fill ?? c.paper,
                borderRadius: BorderRadius.circular(AppRadius.field),
                border: Border.all(
                  color: ringColor,
                  width: error != null || _focus.hasFocus ? 2 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: widget.maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Padding(
                      padding: EdgeInsets.only(top: widget.maxLines > 1 ? 16 : 0),
                      child: Icon(widget.icon, size: 18, color: c.ink3),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      obscureText: widget.obscure,
                      keyboardType: widget.keyboard,
                      maxLines: widget.maxLines,
                      minLines: 1,
                      textInputAction: widget.textInputAction,
                      autofillHints: widget.autofillHints,
                      onSubmitted: widget.onSubmitted,
                      inputFormatters: widget.inputFormatters?.cast(),
                      onChanged: (value) {
                        state.didChange(value);
                        widget.onChanged?.call(value);
                      },
                      style: anek(16, 450, height: 1.35, color: c.ink),
                      cursorColor: c.ink,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: widget.maxLines > 1 ? 14 : 16),
                        hintText: widget.hint?.tr,
                        hintStyle: anek(16, 450, height: 1.35, color: c.ink3),
                      ),
                    ),
                  ),
                  if (widget.trailing != null) widget.trailing!,
                ],
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 15, color: c.badText),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(error.tr, style: anek(13, 600, height: 1.3, color: c.badText)),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Fade-and-rise entrance with a 60ms stagger, skipped under Reduce motion.
class Rise extends StatefulWidget {
  const Rise({required this.child, this.index = 0, super.key});

  final Widget child;
  final int index;

  @override
  State<Rise> createState() => _RiseState();
}

class _RiseState extends State<Rise> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: AppDurations.rise);
  late final _a = CurvedAnimation(parent: _c, curve: kEase);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return widget.child;
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(offset: Offset(0, 16 * (1 - _a.value)), child: child),
      ),
    );
  }
}

/// Diagonal hatching for breaks and holidays.
class Hatch extends StatelessWidget {
  const Hatch({this.child, this.radius = BorderRadius.zero, this.background, super.key});

  final Widget? child;
  final BorderRadius radius;
  final Color? background;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: radius,
    child: CustomPaint(
      painter: HatchPainter(context.app.line2, background ?? Colors.transparent),
      child: child,
    ),
  );
}

class HatchPainter extends CustomPainter {
  HatchPainter(this.color, this.background);

  final Color color;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    // 135deg stripes every 7px, like the CSS repeating-linear-gradient.
    for (var x = -size.height; x < size.width + size.height; x += 7) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(HatchPainter old) => old.color != color || old.background != background;
}

/// Bottom-sheet grab handle.
class Grab extends StatelessWidget {
  const Grab({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40,
      height: 5,
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(color: context.app.line2, borderRadius: BorderRadius.circular(3)),
    ),
  );
}

/// Phone content column: 20px gutters, capped width on big screens.
class Gutter extends StatelessWidget {
  const Gutter({required this.child, this.top = 0, this.bottom = 0, super.key});

  final Widget child;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, top, 20, bottom),
    child: child,
  );
}
