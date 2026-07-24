#include <common.glsl>

layout(std140, binding = 0) uniform CatBlock {
  mat4 modelMatrix;
  mat4 viewMatrix;
  mat4 projectionMatrix;
  mat4 rotation;
  vec4 iscube;
} cat;

in vec3 position;
in vec2 uv;

out vec3 v_worldPosition;
out vec2 v_uv;
out vec4 parms;

void main() {
  v_worldPosition = transformDirection( position, cat.modelMatrix );
  v_uv = uv;
  parms = cat.iscube;
  vec4 viewPosition = cat.viewMatrix * vec4(position,1.0);
  gl_Position  = cat.projectionMatrix * viewPosition;
  gl_Position.z = gl_Position.w;
}