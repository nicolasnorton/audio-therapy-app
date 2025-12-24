#include <flutter/runtime_effect.glsl>

uniform float time;
uniform vec2 resolution;
uniform float intensity;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / resolution.xy - 0.5;
  uv.x *= resolution.x / resolution.y;
  float r = length(uv);
  float a = atan(uv.y, uv.x);
  float spiral = sin(10.0 * r - time * 2.0 + a * 5.0) * (0.5 + intensity * 0.5);
  fragColor = vec4(spiral, 0.5 + 0.5 * sin(time + intensity), 0.5 + 0.5 * cos(time), 1.0);
}
