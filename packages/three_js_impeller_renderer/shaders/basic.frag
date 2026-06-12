#include <common.glsl>
#include <fog.glsl>
#include <color.glsl>
#include <clipping.glsl>

uniform sampler2D map;
uniform sampler2D alphaMap;
uniform sampler2D aoMap;
uniform sampler2D specularMap;

in vec3 v_color;
in vec3 v_normal;
in vec2 v_uv;
in vec3 v_worldPosition;
out vec4 frag_color;

void main() {
  evaluateClippingPlanes(v_worldPosition);
  vec3 color = v_color;
  float alphaOverride = material.baseColor.a;
  vec3 finalColor = applyFog(color, v_worldPosition);
  vec4 finalRGBA = vec4(finalColor, alphaOverride);
  finalRGBA = applyColor(finalRGBA);
  frag_color = vec4(clamp(finalRGBA.rgb, vec3(0.0), vec3(1.0)), finalRGBA.a);
}
