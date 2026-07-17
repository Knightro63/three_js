#include <common.glsl>
#include <skinning.glsl>
#include <instancing.glsl>

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

void main() {
  mat4 instanceModelMatrix = mat4(1.0);
  vec4 skinPosition = vec4(position,1.0);

  bool hasInstancingTexture = material.flags5.w > 0.5;
  bool hasBoneTexture = material.flags0.x > 0.5;
  if(hasInstancingTexture){
    instanceModelMatrix = getInstanceMatrix();
  }
  if(hasBoneTexture){
    skinPosition = getSkinPosition(skinIndex, skinWeight, position);
  }

  vec4 worldPosition = material.modelMatrix * instanceModelMatrix * skinPosition;
  vec4 viewPosition = scene.viewMatrix * worldPosition;
  gl_Position = scene.projectionMatrix * viewPosition;
  gl_Position.z = gl_Position.z * 0.995;
  
  v_worldPosition = worldPosition.xyz;
  v_uv = uv;
  mat3 combinedNormalMatrix = mat3(material.modelMatrix * instanceModelMatrix);
  v_normal = normalize(combinedNormalMatrix * normal);
  v_color = color;
}
