// Liquid glass: convex squircle bezel, Snell refraction (n = 1.5), specular rim.
// Port of the canvas recipe (kube.io): displacement is computed per pixel
// instead of from a pre-baked map.
#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uTexSize;      // set by the engine: size of the bound backdrop texture
uniform vec2 uOrigin;       // glass top-left in physical px, in screen space
uniform vec2 uSize;         // glass size in physical px
uniform float uRadius;      // corner radius, px
uniform float uBezel;       // bezel width, px
uniform float uThickness;   // glass thickness, px
uniform float uRefraction;  // 0..1.5, animated for "materialise"
uniform float uSpecular;    // rim light strength
uniform float uSaturation;  // 1 = unchanged
uniform float uDebug;       // 1 = draw the displacement field (design system)
uniform float uBlur;        // frost radius in px; 0 = clear
uniform vec2 uScreen;       // window size in physical px

uniform sampler2D uTexture;

out vec4 fragColor;

float surface(float x) {
  return pow(1.0 - pow(1.0 - x, 4.0), 0.25);
}

// A crop of the backdrop arrives upside down on GLES; the whole-window texture does not.
bool gFlip = false;

vec4 sampleAt(vec2 p) {
  vec2 uv = clamp(p / uTexSize, vec2(0.0), vec2(1.0));
#ifdef IMPELLER_TARGET_OPENGLES
  if (gFlip) uv.y = 1.0 - uv.y;
#endif
  return texture(uTexture, uv);
}

// Frosted backdrop: a golden-angle disc of taps around the point. The engine's
// own blur is not applied to what this shader samples, so frost is done here.
vec4 blurAt(vec2 p) {
  if (uBlur < 0.5) return sampleAt(p);
  vec4 acc = sampleAt(p);
  for (int i = 0; i < 16; i++) {
    float a = float(i) * 2.39996323;
    float d = uBlur * sqrt((float(i) + 0.5) / 16.0);
    acc += sampleAt(p + vec2(cos(a), sin(a)) * d);
  }
  return acc / 17.0;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;

  // With the whole window as the backdrop, FlutterFragCoord() is a window coordinate (checked
  // on device with a colour-coded debug pass): sample it as is, and subtract the glass origin
  // for the shape. With a crop around the glass the glass sits in the middle of it, and the
  // fragment is already the sampling point.
  bool fullScreen = all(lessThan(abs(uTexSize - uScreen), vec2(3.0)));
  vec2 pad = fullScreen ? vec2(0.0) : (uTexSize - uSize) * 0.5;
  gFlip = !fullScreen;
  vec2 local = fullScreen ? frag - uOrigin : frag - pad;
  vec2 at = frag;

  vec2 hs = uSize * 0.5;
  vec2 p = local - hs;
  float r = min(uRadius, min(hs.x, hs.y));
  vec2 q = abs(p) - (hs - vec2(r));

  float sd;
  vec2 n;
  if (q.x > 0.0 && q.y > 0.0) {
    float l = length(q);
    sd = l - r;
    n = (q / max(l, 1e-4)) * sign(p);
  } else if (q.x > q.y) {
    sd = q.x - r;
    n = vec2(sign(p.x), 0.0);
  } else {
    sd = q.y - r;
    n = vec2(0.0, sign(p.y));
  }

  float depth = -sd;
  vec4 color;
  float rim = 0.0;
  vec2 shift = vec2(0.0);

  if (depth > 0.0 && depth < uBezel) {
    float t = max(depth / uBezel, 0.002);
    float a = max(t - 0.001, 0.0);
    float b = min(t + 0.001, 1.0);
    float slope = (surface(b) - surface(a)) / (b - a) * uThickness / uBezel;
    float theta = atan(slope);
    float thetaR = asin(sin(theta) / 1.5);
    float h = uThickness * surface(t);
    float m = h * tan(theta - thetaR);
    // Convex glass pulls light from further inside the shape.
    shift = -n * m * uRefraction;
    color = blurAt(at + shift);

    vec2 light = vec2(-0.6, -0.8);
    float d = dot(n, light);
    rim = pow(1.0 - t, 2.5) * (d > 0.0 ? d : -d * 0.5) * uSpecular;
  } else {
    color = blurAt(at);
  }

  float lum = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
  color.rgb = mix(vec3(lum), color.rgb, uSaturation);
  color.rgb = mix(color.rgb, vec3(color.a), clamp(rim, 0.0, 1.0));
  fragColor = color;
  if (uDebug > 0.5) {
    // Same encoding as the canvas maps: grey is still, red/green push x/y.
    vec2 enc = clamp(0.5 + shift / max(uThickness, 1.0), 0.0, 1.0);
    fragColor = vec4(enc, 0.5, 1.0);
  }
}
