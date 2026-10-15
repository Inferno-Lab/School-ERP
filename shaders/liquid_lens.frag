// Clear circular lens for the tab dock.
// The circle magnifies what is under it, bends the outer bezel (Snell's law, n = 1.5),
// and splits that bend into red and blue. There is no white stroke: the fringe only
// appears where the bend crosses a real edge (an icon, a label, the side of the bar).
#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uTexSize;
uniform vec2 uOrigin;
uniform vec2 uSize;
uniform vec2 uScreen;
uniform vec2 uScale;
uniform float uTravel;    // 0 settled, 1 while the lens is moving
uniform float uSpecular;  // highlight strength
uniform float uBlur;

uniform sampler2D uTexture;

out vec4 fragColor;

float surface(float x) {
  return pow(1.0 - pow(1.0 - x, 4.0), 0.25);
}

bool gFlip = false;

vec4 sampleAt(vec2 p) {
  vec2 uv = clamp(p / uTexSize, vec2(0.0), vec2(1.0));
#ifdef IMPELLER_TARGET_OPENGLES
  if (gFlip) uv.y = 1.0 - uv.y;
#endif
  return texture(uTexture, uv);
}

vec4 blurAt(vec2 p) {
  if (uBlur < 0.5) return sampleAt(p);
  const float w[5] = float[5](1.0, 4.0, 6.0, 4.0, 1.0);
  vec4 acc = vec4(0.0);
  for (int y = 0; y < 5; y++) {
    for (int x = 0; x < 5; x++) {
      acc += sampleAt(p + vec2(float(x - 2), float(y - 2)) * uBlur) * (w[x] * w[y]);
    }
  }
  return acc / 256.0;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  bool fullScreen = all(lessThan(abs(uTexSize - uScreen), vec2(3.0)));
  vec2 pad = fullScreen ? vec2(0.0) : (uTexSize - uSize) * 0.5;
  gFlip = !fullScreen;
  vec2 local = (fullScreen ? frag - uOrigin : frag - pad) / uScale;
  vec2 at = frag;

  vec2 hs = uSize * 0.5;
  vec2 p = local - hs;
  float radius = min(hs.x, hs.y);
  float r = length(p);
  vec2 n = p / max(r, 1e-4);
  float depth = radius - r;

  vec4 color;
  float rr = clamp(r / max(radius, 1.0), 0.0, 1.0);
  float travel = clamp(uTravel, 0.0, 1.0);
  // Colour split lives on the outer rim only. The icon and the word stay sharp;
  // a bent copy of them appears where the glass gets thick, at the edge.
  float rim = smoothstep(0.62, 1.0, rr);
  float ca = radius * 0.04 * rim * mix(1.0, 1.8, travel);

  if (rim > 0.001 && depth > 0.0) {
    float t = clamp(1.0 - rim, 0.002, 0.998);
    float a = max(t - 0.001, 0.0);
    float b = min(t + 0.001, 1.0);
    float slope = (surface(b) - surface(a)) / (b - a) * (radius * 0.22);
    float theta = atan(slope);
    float thetaR = asin(clamp(sin(theta) / 1.5, -1.0, 1.0));
    float h = radius * 0.22 * surface(t);
    float m = h * tan(theta - thetaR) * 0.35 * rim;
    vec2 shift = -n * m;
    vec2 split = n * ca;
    vec4 cr = blurAt(at + (shift + split) * uScale);
    vec4 cg = blurAt(at + shift * uScale);
    vec4 cb = blurAt(at + (shift - split) * uScale);
    color = vec4(cr.r, cg.g, cb.b, cg.a);
  } else if (depth > 0.0) {
    // A slight magnify, same in every direction, so the icon sits up in the glass.
    vec2 shift = -p * 0.06;
    color = blurAt(at + shift * uScale);
  } else {
    color = blurAt(at);
  }

  vec3 nrm = normalize(vec3(p / max(radius, 1.0), sqrt(max(0.0, 1.0 - rr * rr))));
  // Light from the upper left, matching the reference still.
  vec3 light = normalize(vec3(-0.85, -0.5, 0.45));
  float facing = max(dot(nrm, light), 0.0);
  // The bar is already white, so a white gleam on top of it vanishes.
  // Shade the disk a touch, then put the light back on the upper-left.
  // The circular edge is that shade meeting the bar, not a drawn stroke.
  float gleam = pow(facing, 2.2) * 0.34 * uSpecular;
  float spec = pow(facing, 14.0) * 0.45 * uSpecular;
  color.rgb = color.rgb * 0.97 + vec3(gleam + spec);
  fragColor = color;
}
