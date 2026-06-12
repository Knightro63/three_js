// Pull in the unified master uniform block structure under binding = 0
#include <common.glsl>
#include <color.glsl>
#include <clipping.glsl>
#include <flat_shading.glsl>

// Clean, reflected interpolation streams
in vec3 v_color;
in vec3 v_normal;
in vec3 v_worldNormal;   
in vec3 v_worldPosition; 

out vec4 frag_color;

void main() {
  evaluateClippingPlanes(v_worldPosition);

  vec3 N_world = evaluateNormal(v_worldNormal, v_worldPosition);
  mat3 viewMat3x3 = mat3(scene.viewMatrix);
  
  vec3 viewNormal = normalize(viewMat3x3 * N_world);
  vec3 packedColor = viewNormal * 1.0 + vec3(0.5);

  vec4 finalRGBA = vec4(packedColor, 1.0);
  finalRGBA = applyColor(finalRGBA);

  frag_color = vec4(clamp(finalRGBA.rgb, vec3(0.0), vec3(1.0)), finalRGBA.a);
}
