#include <material_block.glsl>
#include <scene_block.glsl>
#include <flat_shading.glsl>
#include <clipping.glsl>

in vec3 v_worldPosition;
in vec3 v_worldNormal;

out vec4 frag_color;

void main() {
  if(evaluateClippingPlanes(v_worldPosition)){
    discard;
  }  
  vec3 N = evaluateNormal(v_worldNormal, v_worldPosition);
  vec3 L = vec3(0.0, 1.0, 0.0);
  
  int totalLights = int(scene.envParms.w);
  if (totalLights > 0) {
    float typeToken = scene.lightPositions[0].w;
    if (typeToken == 1.0) {
      L = normalize(-scene.lightPositions[0].xyz);
    } 
    else {
      L = normalize(scene.lightPositions[0].xyz - v_worldPosition);
    }
  }
  
  float dotNL = dot(N, L);
  vec3 shadowColor = vec3(0.0, 0.0, 0.0);
  float shadowIntensity = clamp(1.0 - max(dotNL, 0.0), 0.0, 1.0);
  float finalAlpha = shadowIntensity * material.baseColor.a;

  frag_color = vec4(shadowColor, finalAlpha);
}
