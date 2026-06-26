#include <common.glsl>
#include <skinning.glsl>

in vec3 position;
in vec3 normal;
in vec2 uv;
in vec3 color;

in vec4 skinIndex;
in vec4 skinWeight;

out vec3 v_color;
out vec3 v_normal;
out vec2 v_uv;
out vec3 v_worldPosition;

out vec4 v_skinIndex;
out vec4 v_skinWeight;

void main() {
  vec4 skinPosition = vec4(position,1.0);

  bool hasBoneTexture = material.flags0.x > 0.5;
  if(hasBoneTexture){
    skinPosition = getSkinPosition(skinIndex, skinWeight, position);
  }

  vec4 worldPosition = material.modelMatrix * skinPosition;
  vec4 viewPosition = scene.viewMatrix * worldPosition;
  gl_Position = scene.projectionMatrix * viewPosition;
  gl_Position.z = gl_Position.z * 0.995;
  
  v_worldPosition = worldPosition.xyz;
  v_uv = uv;
  v_normal = normal;
  v_color = color;

  v_skinIndex = skinIndex;
  v_skinWeight = skinWeight;
}
