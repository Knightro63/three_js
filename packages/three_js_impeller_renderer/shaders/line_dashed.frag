#include <common.glsl>
#include <fog.glsl>
#include <color.glsl>
#include <clipping.glsl>

in vec3 v_color;
in float vLineDistance;
in vec3 v_worldPosition;

out vec4 frag_color;

void main() {
  if(evaluateClippingPlanes(v_worldPosition)){
    frag_color = vec4(0.0);
    return;
  }
  vec3 color = v_color;
  float alpha = material.baseColor.a;

  // Extract user layout configurations from the uniform block vector slots
  float dashSize = material.lineParams.y;          // line.dashSize
  float gapSize = material.lineExtendedParams.x;   // line.gapSize

  if (dashSize <= 0.0) {
    dashSize = 3.0;
  }
  if (gapSize <= 0.0) {
    gapSize = 1.0;
  }

  float totalSize = dashSize + gapSize;
  
  // Run high-precision floating point modulo tracking down the uv gradient channel
  float moduloDistance = vLineDistance - totalSize * floor(vLineDistance / totalSize);

  // If the pixel lands in a gap, or fails your alpha test contract, execute early return
  if (moduloDistance > dashSize || alpha < material.pbrParams.w) {
    frag_color = vec4(0.0);
    return;
  }

  // Compile environment layers and output
  vec3 finalColor = applyFog(color, v_worldPosition);
  vec4 finalRGBA = vec4(finalColor, alpha);

  vec3 outputRGB = applyColor(vec4(finalRGBA.rgb, 1.0)).rgb;

  frag_color = vec4(clamp(outputRGB, vec3(0.0), vec3(1.0)), finalRGBA.a);
}
