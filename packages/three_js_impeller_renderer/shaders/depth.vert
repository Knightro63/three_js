#include <common.glsl>

in vec3 position;

out vec3 v_worldPosition;
out float v_viewDepth;

void main() {
  vec4 worldPosition4 = material.modelMatrix * vec4(position, 1.0);
  v_worldPosition = worldPosition4.xyz;
  
  vec4 viewPosition = scene.viewMatrix * worldPosition4;
  gl_Position = scene.projectionMatrix * viewPosition;

  v_viewDepth = -viewPosition.z;
}