#include <flutter/runtime_effect.glsl>

uniform float time;
uniform vec2 resolution;
uniform float intensity;
uniform float frequency;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / resolution.xy - 0.5;
  uv.x *= resolution.x / resolution.y;

  float dist = length(uv);
  float angle = atan(uv.y, uv.x);

  // Interference patterns
  // Pattern 1: Spiral wavefronts
  float wave1 = sin(dist * (10.0 + frequency * 0.3) - time * (2.5 + frequency * 0.08) + angle * 3.0);
  
  // Pattern 2: Concentric ripples reacting to frequency
  float wave2 = cos(dist * (15.0 - frequency * 0.1) + time * 3.0);
  
  // Combined interference
  float interference = mix(wave1, wave2, 0.4);
  
  // Pulse effect based on frequency (higher freq = faster shimmer)
  float pulse = sin(time * (1.0 + frequency * 0.5)) * 0.1 * intensity;
  
  // Soft edges and intensity modulation
  float mask = smoothstep(-0.5, 0.8, (interference + pulse) * intensity);
  
  // Chromatic Aberration (Shift color channels based on intensity/dist)
  float shift = 0.02 * intensity * dist;
  vec3 col;
  col.r = 0.5 + 0.4 * cos(time * 0.8 + dist * 2.0 + 0.0);
  col.g = 0.5 + 0.4 * cos(time * 0.9 + dist * 2.0 + 2.0 + shift);
  col.b = 0.5 + 0.4 * cos(time * 1.0 + dist * 2.0 + 4.0 - shift);

  // AURA specific tinting
  vec3 auraColor = mix(vec3(0.0, 0.8, 1.0), vec3(0.5, 0.0, 1.0), sin(time * 0.5) * 0.5 + 0.5);
  col = mix(col, auraColor, mask * 0.7);

  // Center focus / Vignette
  float vignette = smoothstep(1.5, 0.1, dist);
  
  fragColor = vec4(col * vignette, 1.0);
}