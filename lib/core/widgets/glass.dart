// Render-object setters only feed paint; nothing reads them back.
// ignore_for_file: avoid_setters_without_getters
import 'dart:ui' as ui;

import 'package:edunest/core/theme/app_colors.dart';
import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Two thicknesses: a thin sheet for bars, a thick lens for focus.
enum GlassKind { sheet, lens }

/// Loads the liquid-glass shader once. Call [LiquidGlass.warmUp] before runApp.
abstract final class LiquidGlass {
  static ui.FragmentProgram? program;

  /// Design system: paint each glass's displacement field instead of the backdrop.
  static final showMaps = ValueNotifier(false);

  /// Glass surfaces currently attached (design system readout).
  static int live = 0;

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
class Glass extends StatelessWidget {
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
    this.onPigment = false,
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

  /// Sits over a pigment or photo with white content: clear glass. Otherwise
  /// the glass is frosted, so text scrolling behind it never collides with labels.
  final bool onPigment;
  final double? saturation;

  @override
  Widget build(BuildContext context) {
    final c = context.app;
    final shape = BorderRadius.circular(radius);
    // One soft shadow below the glass; a hairline shadow reads as a second outline.
    final shadows = shadow
        ? [BoxShadow(color: c.glassShadow, blurRadius: 28, spreadRadius: -8, offset: const Offset(0, 10))]
        : null;
    final content = Padding(padding: padding ?? EdgeInsets.zero, child: child);

    if (context.reduceTransparency) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: tint?.withValues(alpha: 1) ?? c.paper,
          borderRadius: shape,
          border: Border.all(color: c.line2),
          boxShadow: shadows,
        ),
        child: content,
      );
    }

    final lens = kind == GlassKind.lens;
    return CustomPaint(
      // The backdrop filter samples what is under the glass, so the shadow
      // must stay outside the shape (like CSS box-shadow) or it greys the glass.
      painter: shadows == null ? null : _OuterShadow(radius: shape, shadows: shadows),
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: shape,
          child: _GlassFilter(
            radius: radius,
            lens: lens,
            saturation: saturation ?? (lens ? 1.6 : 1.5),
            specular: c.dark ? .62 : .92,
            child: DecoratedBox(
              decoration: BoxDecoration(color: tint ?? (onPigment ? c.glassTint : c.glassTintStrong), borderRadius: shape),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: rim
                    ? BoxDecoration(
                        borderRadius: shape,
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
    required this.saturation,
    required this.specular,
    super.child,
  });

  final double radius;
  final bool lens;
  final double saturation;
  final double specular;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderGlass(
    radius: radius,
    lens: lens,
    saturation: saturation,
    specular: specular,
    dpr: MediaQuery.devicePixelRatioOf(context),
  );

  @override
  void updateRenderObject(BuildContext context, _RenderGlass renderObject) {
    renderObject
      ..radius = radius
      ..lens = lens
      ..saturation = saturation
      ..specular = specular
      ..dpr = MediaQuery.devicePixelRatioOf(context);
  }
}

// Liquid glass: convex squircle bezel, Snell refraction (n = 1.5), specular rim.
// Port of the canvas recipe (kube.io): displacement is computed per pixel
// instead of from a pre-baked map.
class _RenderGlass extends RenderProxyBox {
  _RenderGlass({
    required double radius,
    required bool lens,
    required double saturation,
    required double specular,
    required double dpr,
  }) : _radius = radius,
       _lens = lens,
       _saturation = saturation,
       _specular = specular,
       _dpr = dpr;

  ui.FragmentShader? _shader;

  double _radius;
  set radius(double v) => _set(_radius != v, () => _radius = v);
  bool _lens;
  set lens(bool v) => _set(_lens != v, () => _lens = v);
  double _saturation;
  set saturation(double v) => _set(_saturation != v, () => _saturation = v);
  double _specular;
  set specular(double v) => _set(_specular != v, () => _specular = v);
  double _dpr;
  set dpr(double v) => _set(_dpr != v, () => _dpr = v);

  void _set(bool changed, VoidCallback apply) {
    if (!changed) return;
    apply();
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    LiquidGlass.showMaps.addListener(markNeedsPaint);
    LiquidGlass.live++;
  }

  @override
  void detach() {
    LiquidGlass.showMaps.removeListener(markNeedsPaint);
    LiquidGlass.live--;
    super.detach();
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  /// Frosted fallback for Skia, web and unsupported devices; it does not depend on where the glass is.
  ui.ImageFilter _fallbackFilter() {
    final saturate = ui.ColorFilter.matrix(_saturationMatrix(_lens ? _saturation : 1.7));
    return ui.ImageFilter.compose(outer: saturate, inner: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14));
  }

  /// The shader filter for a glass whose top-left sits at [origin] (physical px, window space).
  ui.ImageFilter _shaderFilter(Offset origin) {
    final shader = _shader ??= LiquidGlass.program!.fragmentShader();
    final screen = ui.PlatformDispatcher.instance.implicitView?.physicalSize ?? size * _dpr;
    final px = size * _dpr;
    final shortest = size.shortestSide;
    final bezel = (_lens ? (shortest * .3).clamp(10, 34) : (shortest * .3).clamp(10, 18)).toDouble();
    final thickness = bezel * (_lens ? 1.6 : 1.22);
    // Index 0 and 1 hold the texture size; the engine sets them.
    shader
      ..setFloat(2, origin.dx)
      ..setFloat(3, origin.dy)
      ..setFloat(4, px.width)
      ..setFloat(5, px.height)
      ..setFloat(6, _radius * _dpr)
      ..setFloat(7, bezel * _dpr)
      ..setFloat(8, thickness * _dpr)
      ..setFloat(9, 1)
      ..setFloat(10, _specular)
      ..setFloat(11, _saturation)
      ..setFloat(12, LiquidGlass.showMaps.value ? 1 : 0)
      ..setFloat(13, (_lens ? 1 : 7) * _dpr)
      ..setFloat(14, screen.width)
      ..setFloat(15, screen.height);
    // A bare shader filter: the shader frosts and refracts the backdrop itself.
    return ui.ImageFilter.shader(shader);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final filterLayer = (layer as _GlassLayer?) ?? _GlassLayer();
    final shaded = LiquidGlass.available && LiquidGlass.program != null;
    filterLayer
      ..paintOffset = offset
      ..shaderFilter = shaded ? _shaderFilter : null;
    if (!shaded) filterLayer.filter = _fallbackFilter();
    layer = filterLayer;
    context.pushLayer(filterLayer, super.paint, offset);
  }
}

/// A backdrop filter that learns where it is on screen when the frame is composed, not when it
/// was painted. A scroll view moves a cached layer without repainting it, so a position baked in at
/// paint time left the shader drawing its edge, rim and sampling at the old spot (a ghost that only
/// showed while scrolling, and during page transitions).
class _GlassLayer extends BackdropFilterLayer {
  Offset paintOffset = Offset.zero;
  ui.ImageFilter Function(Offset origin)? shaderFilter;

  @override
  bool get alwaysNeedsAddToScene => shaderFilter != null;

  /// Physical-pixel window position of the glass: the paint offset carried through every ancestor
  /// offset and transform (the root transform is the device pixel ratio).
  Offset _windowOrigin() {
    var m = Matrix4.translationValues(paintOffset.dx, paintOffset.dy, 0);
    for (Layer? p = parent; p != null; p = p.parent) {
      if (p is TransformLayer) {
        final o = p.offset;
        m = Matrix4.translationValues(o.dx, o.dy, 0).multiplied(p.transform ?? Matrix4.identity()).multiplied(m);
      } else if (p is OffsetLayer) {
        m = Matrix4.translationValues(p.offset.dx, p.offset.dy, 0).multiplied(m);
      }
    }
    return Offset(m.storage[12], m.storage[13]);
  }

  @override
  void addToScene(ui.SceneBuilder builder) {
    final build = shaderFilter;
    if (build == null) {
      super.addToScene(builder);
      return;
    }
    // Pushed straight to the scene: the `filter` setter marks the layer dirty, which a layer that
    // always re-adds itself must not do.
    engineLayer = builder.pushBackdropFilter(
      build(_windowOrigin()),
      blendMode: blendMode,
      oldLayer: engineLayer as ui.BackdropFilterEngineLayer?,
    );
    addChildrenToScene(builder);
    builder.pop();
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
    this.onPigment,
    super.key,
  });

  /// Defaults to true for white icons: they only make sense over a pigment.
  final bool? onPigment;
  final IconData icon;
  final VoidCallback? onTap;
  final String label;
  final Color? color;
  final double size;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return GlassPress(
      onTap: onTap,
      label: label,
      child: Glass(
        width: size,
        height: size,
        radius: size / 2,
        onPigment: onPigment ?? color == AppColors.white,
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
    );
  }
}

/// Glass squashes 5% on press (scale 1.05 x .95) with the glass spring.
/// It is its own accessibility node (a button) so it never merges into the header around it;
/// icon-only controls pass [label], text controls read their own text.
class GlassPress extends StatefulWidget {
  const GlassPress({required this.child, this.onTap, this.label, super.key});

  final Widget child;
  final VoidCallback? onTap;
  final String? label;

  @override
  State<GlassPress> createState() => _GlassPressState();
}

class _GlassPressState extends State<GlassPress> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    final squash = _down && !context.reduceMotion;
    return Semantics(
      container: true,
      button: true,
      enabled: widget.onTap != null,
      label: widget.label,
      excludeSemantics: widget.label != null,
      onTap: widget.onTap,
      child: GestureDetector(
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
      ),
    );
  }
}
