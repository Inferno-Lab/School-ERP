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

uniform sampler2D uTexture;

out vec4 fragColor;

float surface(float x) {
  return pow(1.0 - pow(1.0 - x, 4.0), 0.25);
}

vec4 sampleAt(vec2 p) {
  vec2 uv = clamp(p / uTexSize, vec2(0.0), vec2(1.0));
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  return texture(uTexture, uv);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;

  // The backdrop texture is either the whole screen or just the clip around
  // this glass (Impeller may pad it). Work out where the glass sits in it.
  vec2 origin = uOrigin;
  vec2 slack = uTexSize - uSize;
  if (all(greaterThanEqual(slack, vec2(-2.0))) && all(lessThan(slack, vec2(160.0)))) {
    origin = slack * 0.5;
  }

  vec2 local = frag - origin;
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
    color = sampleAt(frag - n * m * uRefraction);

    vec2 light = vec2(-0.6, -0.8);
    float d = dot(n, light);
    rim = pow(1.0 - t, 2.5) * (d > 0.0 ? d : -d * 0.5) * uSpecular;
  } else {
    color = sampleAt(frag);
  }

  float lum = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
  color.rgb = mix(vec3(lum), color.rgb, uSaturation);
  color.rgb = mix(color.rgb, vec3(color.a), clamp(rim, 0.0, 1.0));
  fragColor = color;
}
