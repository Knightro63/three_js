#include <material_block.glsl>
#include <scene_block.glsl>
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

  vec4 texelColor = vec4(1.0);
  float alphaOverride = material.baseColor.a;

  if (hasMap) {
    texelColor = texture(map, v_uv);
    alphaOverride = material.baseColor.a * texelColor.a;
  }

  vec3 blendedAlbedo = v_color * texelColor.rgb;

  float alpha = alphaOverride;
  if (hasAlphaMap) {
    alpha *= texture(alphaMap, v_uv).g;
  }

  vec3 finalColor = applyFog(blendedAlbedo, v_worldPosition);
  vec4 finalRGBA = vec4(finalColor, alpha);

  finalRGBA = applyColor(finalRGBA,scene.rendParms.z);

  if (alpha < 0.01) {
    discard; 
  }
  
  frag_color = vec4(clamp(finalRGBA.rgb, vec3(0.0), vec3(1.0)), alpha);
}
