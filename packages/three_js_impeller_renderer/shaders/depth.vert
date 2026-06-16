#include <common.glsl>

in vec3 position;
in vec3 color;

out vec3 v_color;
out vec3 v_worldPosition;
out vec3 v_viewDepth;

void main() {
  vec4 worldPosition = material.modelMatrix * vec4(position, 1.0);
  v_worldPosition = worldPosition.xyz;
  
  vec4 viewPosition = scene.viewMatrix * worldPosition;
  gl_Position = scene.projectionMatrix * viewPosition;

  v_viewDepth = -viewPosition.xyz;//1.0,2000.0,-viewPosition.z);
  v_color = color;
}