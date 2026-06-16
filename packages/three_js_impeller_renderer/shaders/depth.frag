#include <common.glsl>
#include <color.glsl>
#include <clipping.glsl>
#include <flat_shading.glsl>

in vec3 v_color;
in vec3 v_worldPosition;
in vec3 v_viewDepth;

out vec4 frag_color;

void main() {
  if(evaluateClippingPlanes(v_worldPosition)){
    frag_color = vec4(0.0);
    return;
  }
  vec3 color = v_color;

  float near = 1.0;
  float far = 2000.0;

  //float linearDistance = (near * far) / (far - z * (far - near));
  float linearDepth = 1.0;//(v_viewDepth.z - near) / (far - near);
  //float linearDepth = (linearDistance - near) / (far - near);
  frag_color = vec4(vec3(clamp(linearDepth, 0.0, 1.0)), material.baseColor.a);
}