// Render-object setters only feed paint; nothing reads them back.
// ignore_for_file: avoid_setters_without_getters
import 'dart:ui' as ui;

import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Two thicknesses: a thin sheet for bars, a thick lens for focus.
enum GlassKind { sheet, lens }

/// Loads the liquid-glass shader once. Call [LiquidGlass.warmUp] before runApp.
abstract final class LiquidGlass {
  static ui.FragmentProgram? program;

  static bool get available => program != null && ui.ImageFilter.isShaderFilterSupported;

  static Future<void> warmUp() async {
    if (!ui.ImageFilter.isShaderFilterSupported) return;
    try {
      program = await ui.FragmentProgram.fromAsset('shaders/liquid_glass.frag');
    } on Object catch (error) {
      // Glass then falls back to blur; the app keeps working.
      debugPrint('liquid glass unavailable: $error');
    }
  }
}

/// Liquid glass for the floating controls layer. Content cards are never glass.
class Glass extends StatefulWidget {
  const Glass({
    this.child,
    this.radius = 22,
    this.kind = GlassKind.sheet,
    this.tint,
    this.padding,
    this.width,
    this.height,
    this.shadow = true,
    this.rim = true,
    this.blur,
    this.saturation,
    super.key,
  });

  final Widget? child;
  final double radius;
  final GlassKind kind;
  final Color? tint;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final bool shadow;
  final bool rim;
  final double? blur;
  final double? saturation;

  @override
  State<Glass> createState() => _GlassState();
}

class _GlassState extends State<Glass> with SingleTickerProviderStateMixin {
  // Glass materialises by ramping refraction 0 -> 1, like water condensing.
  late final _materialise = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _materialise.forward();
  }

  @override
  void dispose() {
    _materialise.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    final radius = BorderRadius.circular(widget.radius);
    final shadows = widget.shadow
        ? [
            BoxShadow(
              color: c.glassShadow.withValues(alpha: c.dark ? .3 : .06),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
            BoxShadow(color: c.glassShadow, blurRadius: 28, spreadRadius: -8, offset: const Offset(0, 10)),
          ]
        : null;
    final content = Padding(padding: widget.padding ?? EdgeInsets.zero, child: widget.child);

    if (context.reduceTransparency) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.tint?.withValues(alpha: 1) ?? c.paper,
          borderRadius: radius,
          border: Border.all(color: c.line2),
          boxShadow: shadows,
        ),
        child: content,
      );
    }

    final lens = widget.kind == GlassKind.lens;
    return CustomPaint(
      // The backdrop filter samples what is under the glass, so the shadow
      // must stay outside the shape (like CSS box-shadow) or it greys the glass.
      painter: shadows == null ? null : _OuterShadow(radius: radius, shadows: shadows),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: ClipRRect(
          borderRadius: radius,
          child: _GlassFilter(
            radius: widget.radius,
            lens: lens,
            blur: widget.blur ?? (lens ? .3 : 1.5),
            saturation: widget.saturation ?? (lens ? 1.6 : 1.5),
            specular: c.dark ? .62 : .92,
            refraction: context.reduceMotion ? null : _materialise,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.tint ?? c.glassTint,
                borderRadius: radius,
              ),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: widget.rim
                    ? BoxDecoration(
                        borderRadius: radius,
                        border: Border.all(color: c.glassRim, width: .6),
                      )
                    : const BoxDecoration(),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OuterShadow extends CustomPainter {
  const _OuterShadow({required this.radius, required this.shadows});

  final BorderRadius radius;
  final List<BoxShadow> shadows;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = radius.toRRect(Offset.zero & size);
    canvas
      ..save()
      ..clipPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect((Offset.zero & size).inflate(80)),
          Path()..addRRect(shape),
        ),
      );
    for (final s in shadows) {
      canvas.drawRRect(shape.shift(s.offset).inflate(s.spreadRadius), s.toPaint());
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OuterShadow old) => old.radius != radius || old.shadows != shadows;
}

class _GlassFilter extends SingleChildRenderObjectWidget {
  const _GlassFilter({
    required this.radius,
    required this.lens,
    required this.blur,
    required this.saturation,
    required this.specular,
    required this.refraction,
    super.child,
  });

  final double radius;
  final bool lens;
  final double blur;
  final double saturation;
  final double specular;
  final Animation<double>? refraction;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderGlass(
    radius: radius,
    lens: lens,
    blur: blur,
    saturation: saturation,
    specular: specular,
    refraction: refraction,
    dpr: MediaQuery.devicePixelRatioOf(context),
  );

  @override
  void updateRenderObject(BuildContext context, _RenderGlass renderObject) {
    renderObject
      ..radius = radius
      ..lens = lens
      ..blur = blur
      ..saturation = saturation
      ..specular = specular
      ..refraction = refraction
      ..dpr = MediaQuery.devicePixelRatioOf(context);
  }
}

class _RenderGlass extends RenderProxyBox {
  _RenderGlass({
    required double radius,
    required bool lens,
    required double blur,
    required double saturation,
    required double specular,
    required Animation<double>? refraction,
    required double dpr,
  }) : _radius = radius,
       _lens = lens,
       _blur = blur,
       _saturation = saturation,
       _specular = specular,
       _refraction = refraction,
       _dpr = dpr;

  ui.FragmentShader? _shader;

  double _radius;
  set radius(double v) => _set(_radius != v, () => _radius = v);
  bool _lens;
  set lens(bool v) => _set(_lens != v, () => _lens = v);
  double _blur;
  set blur(double v) => _set(_blur != v, () => _blur = v);
  double _saturation;
  set saturation(double v) => _set(_saturation != v, () => _saturation = v);
  double _specular;
  set specular(double v) => _set(_specular != v, () => _specular = v);
  double _dpr;
  set dpr(double v) => _set(_dpr != v, () => _dpr = v);

  Animation<double>? _refraction;
  set refraction(Animation<double>? v) {
    if (_refraction == v) return;
    if (attached) _refraction?.removeListener(markNeedsPaint);
    _refraction = v;
    if (attached) _refraction?.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  void _set(bool changed, VoidCallback apply) {
    if (!changed) return;
    apply();
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _refraction?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _refraction?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  ui.ImageFilter _filter() {
    final saturate = ui.ColorFilter.matrix(_saturationMatrix(_lens ? _saturation : 1.7));
    final program = LiquidGlass.program;
    if (!LiquidGlass.available || program == null) {
      // Frosted fallback for Skia, web and unsupported devices.
      return ui.ImageFilter.compose(outer: saturate, inner: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14));
    }
    final shader = _shader ??= program.fragmentShader();
    final origin = localToGlobal(Offset.zero) * _dpr;
    final px = size * _dpr;
    final shortest = size.shortestSide;
    final bezel = (_lens ? (shortest * .3).clamp(10, 34) : (shortest * .3).clamp(10, 18)).toDouble();
    final thickness = bezel * (_lens ? 1.6 : 1.22);
    final t = Curves.easeOutBack.transform(_refraction?.value ?? 1);
    // Index 0 and 1 hold the texture size; the engine sets them.
    shader
      ..setFloat(2, origin.dx)
      ..setFloat(3, origin.dy)
      ..setFloat(4, px.width)
      ..setFloat(5, px.height)
      ..setFloat(6, _radius * _dpr)
      ..setFloat(7, bezel * _dpr)
      ..setFloat(8, thickness * _dpr)
      ..setFloat(9, t)
      ..setFloat(10, _specular)
      ..setFloat(11, _saturation);
    final glass = ui.ImageFilter.shader(shader);
    if (_blur <= 0) return glass;
    return ui.ImageFilter.compose(
      outer: glass,
      inner: ui.ImageFilter.blur(sigmaX: _blur * _dpr / 2, sigmaY: _blur * _dpr / 2),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final filterLayer = (layer as BackdropFilterLayer?) ?? BackdropFilterLayer();
    filterLayer.filter = _filter();
    layer = filterLayer;
    context.pushLayer(filterLayer, super.paint, offset);
  }
}

List<double> _saturationMatrix(double s) {
  const r = .2126;
  const g = .7152;
  const b = .0722;
  final i = 1 - s;
  return [
    i * r + s, i * g, i * b, 0, 0, //
    i * r, i * g + s, i * b, 0, 0, //
    i * r, i * g, i * b + s, 0, 0, //
    0, 0, 0, 1, 0,
  ];
}

/// Round glass icon button (44px), the house top-bar control.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    required this.icon,
    required this.onTap,
    required this.label,
    this.color,
    this.size = 44,
    this.badge = false,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String label;
  final Color? color;
  final double size;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GlassPress(
        onTap: onTap,
        child: Glass(
          width: size,
          height: size,
          radius: size / 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 22, color: color ?? context.app.ink),
              if (badge)
                const Positioned(
                  top: 8,
                  right: 9,
                  child: SizedBox.square(
                    dimension: 9,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Color(0xFFC23B2A), shape: BoxShape.circle),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Glass squashes 5% on press (scale 1.05 x .95) with the glass spring.
class GlassPress extends StatefulWidget {
  const GlassPress({required this.child, this.onTap, super.key});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<GlassPress> createState() => _GlassPressState();
}

class _GlassPressState extends State<GlassPress> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    final squash = _down && !context.reduceMotion;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _down = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _down = false),
      child: AnimatedContainer(
        duration: squash ? const Duration(milliseconds: 120) : AppDurations.medium,
        curve: squash ? Curves.easeOut : kSpring,
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(squash ? 1.05 : 1, squash ? .95 : 1, 1),
        child: widget.child,
      ),
    );
  }
}
