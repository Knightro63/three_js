#include <common.glsl>
#include <fog.glsl>
#include <color.glsl>

uniform sampler2D map;
uniform sampler2D alphaMap;

in vec3 v_color;
in vec3 v_worldPosition;
in vec2 v_uv;

out vec4 frag_color;

void main() {
  bool hasMap      = material.flags0.y > 0.5;
  bool hasAlphaMap = material.flags0.z > 0.5;

  vec2 coord = gl_PointCoord;

  vec4 texelColor = vec4(1.0);
  float alphaOverride = material.baseColor.a;

  if (hasMap) {
    texelColor = texture(map, coord);
    alphaOverride = material.baseColor.a * texelColor.a;
  }

  vec3 blendedAlbedo = v_color * texelColor.rgb;

  float alpha = alphaOverride;
  if (hasAlphaMap) {
    alpha *= texture(alphaMap, coord).g;
  }

  if (alpha < material.pbrParams.w) {
    frag_color = vec4(0.0);
    return;
  }

  vec3 finalColor = applyFog(blendedAlbedo, v_worldPosition);
  vec4 finalRGBA = vec4(finalColor, alpha);

  vec3 outputRGB = applyColor(vec4(finalRGBA.rgb, 1.0)).rgb;

  frag_color = vec4(clamp(outputRGB, vec3(0.0), vec3(1.0)), finalRGBA.a);
}
