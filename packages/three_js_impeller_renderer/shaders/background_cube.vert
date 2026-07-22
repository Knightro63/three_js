#include <material_block.glsl>
#include <common.glsl>

in vec3 position;
in vec2 uv;

out vec3 v_worldPosition;
out vec2 v_uv;

void main() {
  v_worldPosition = transformDirection( position, material.modelMatrix );
  v_uv = uv;
  vec4 viewPosition = material.viewMatrix * vec4(position,1.0);
  gl_Position  = material.projectionMatrix * viewPosition;
  gl_Position.z = gl_Position.w;
}