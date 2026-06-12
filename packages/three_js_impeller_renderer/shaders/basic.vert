// NOW it is safe to include, because #version is the absolute first line!
#include <common.glsl>

in vec3 position;
in vec3 normal;
in vec2 uv;
in vec3 color;

out vec3 v_color;
out vec3 v_normal;
out vec2 v_uv;
out vec3 v_worldPosition;

void main() {
  vec4 worldPosition = material.modelMatrix * vec4(position, 1.0);
  vec4 viewPosition = scene.viewMatrix * worldPosition;
  gl_Position = scene.projectionMatrix * viewPosition;
  
  v_worldPosition = worldPosition.xyz;
  v_uv = uv;
  v_normal = normal;
  v_color = material.baseColor.rgb * color;
}
