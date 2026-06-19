#include <common.glsl>
#include <clipping.glsl>

in vec3 v_worldPosition;
in float v_viewDepth;

out vec4 frag_color;

void main() {
  if(evaluateClippingPlanes(v_worldPosition)){
    frag_color = vec4(0.0);
    return;
  }

  float near = scene.fogParams.x;
  float far = scene.fogParams.y;

  if (far <= near) {
    far = 2000.0;
  }

  float linearDepth = (v_viewDepth - near) / (far - near);
  frag_color = vec4(vec3(clamp(linearDepth, 0.0, 1.0)), material.baseColor.a);
}