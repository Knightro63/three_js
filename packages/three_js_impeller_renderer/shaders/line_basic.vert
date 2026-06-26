#include <common.glsl>

in vec3 position;
in vec3 color;

out vec3 v_color;
out vec3 v_worldPosition;

void main() {
  vec4 worldPosition = material.modelMatrix * vec4(position, 1.0);
  v_worldPosition = worldPosition.xyz;
  gl_Position = scene.projectionMatrix * scene.viewMatrix * worldPosition;
  gl_Position.z = gl_Position.z * 0.995;

  v_color = color;//material.baseColor.rgb * vertexColor;
}
