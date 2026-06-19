#include <common.glsl>
#include <color.glsl>
#include <clipping.glsl>
#include <fog.glsl>

in vec3 v_color;
in vec3 v_worldPosition;

out vec4 frag_color;

void main() {
  if(evaluateClippingPlanes(v_worldPosition)){
    frag_color = vec4(0.0);
    return;
  }  
  vec3 color = v_color;
  float alpha = material.baseColor.a;
  if (alpha < material.pbrParams.w) {
    frag_color = vec4(0.0);
    return;
  }

  vec3 finalColor = applyFog(color, v_worldPosition);
  vec4 finalRGBA = vec4(finalColor, alpha);
  finalRGBA = applyColor(finalRGBA, material.lineExtendedParams.z);

  frag_color = vec4(clamp(finalRGBA.rgb, vec3(0.0), vec3(1.0)),alpha);
}
