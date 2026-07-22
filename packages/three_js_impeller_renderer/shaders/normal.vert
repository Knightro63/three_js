#include <material_block.glsl>
#include <skinning.glsl>
#include <instancing.glsl> 
#include <displacement.glsl>

in vec3 position;
in vec3 normal;
in vec2 uv;
in vec4 skinIndex;
in vec4 skinWeight;
in float instanceID;

out vec3 v_worldNormal;
out vec3 v_worldPosition;

void main() {
  vec4 localPosition = vec4( position, 1.0 );
  vec3 localNormal = normal;
  
  mat4 instanceModelMatrix = getBatchingInstance(instanceID);
  
  BoneMatrix boneMatrix = getBoneMatrix(skinIndex, skinWeight);
  localPosition = getSkinPosition(boneMatrix, skinWeight, localPosition);
  localNormal = getSkinNormal(boneMatrix, skinWeight, localNormal);

  localPosition = getDisplacementPosition(localPosition, localNormal, uv);

  mat4 finalModelMatrix = material.modelMatrix * instanceModelMatrix;
  vec4 worldPosition = finalModelMatrix * localPosition;
  v_worldPosition = worldPosition.xyz;

  mat3 normalMatrix = transpose(inverse(mat3(finalModelMatrix)));
  v_worldNormal = normalize(normalMatrix * localNormal);

  vec4 viewPosition = material.viewMatrix * worldPosition;
  gl_Position  = material.projectionMatrix * viewPosition;
  gl_Position.z = gl_Position.z * 0.995; // Custom depth adjustments
}
