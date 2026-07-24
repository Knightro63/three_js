#include <material_block.glsl>
#include <scene_block.glsl>
#include <fog.glsl>
#include <color.glsl>
#include <clipping.glsl>

in vec3 v_color;
in float v_lineDistance;
in vec3 v_worldPosition;
in vec2 v_uv;

out vec4 frag_color;

void main() {
  if(evaluateClippingPlanes(v_worldPosition)){
    discard;
  }
  vec3 color = v_color;
  float alpha = material.baseColor.a;

  float dashSize = material.lineParams.y;
  float gapSize = material.lineExtendedParams.x;
  float totalSize = dashSize + gapSize;
  if (mod( v_lineDistance, totalSize ) > dashSize || alpha < 0.001) {
    discard;
  }

  vec3 finalColor = applyFog(color, v_worldPosition);
  vec4 finalRGBA = vec4(finalColor, alpha);
  finalRGBA = applyColor(finalRGBA,scene.rendParms.z);

  frag_color = vec4(clamp(finalRGBA.rgb, vec3(0.0), vec3(1.0)), alpha);
}
