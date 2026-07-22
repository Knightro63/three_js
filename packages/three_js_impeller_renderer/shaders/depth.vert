#include <material_block.glsl>
#include <skinning.glsl>
#include <instancing.glsl>

in vec3 position;
in vec4 skinIndex;
in vec4 skinWeight;
in float instanceID;

out vec3 v_worldPosition;
out float v_viewDepth;

void main() {
  vec4 localPosition = vec4( position, 1.0 );
  mat4 instanceModelMatrix = getBatchingInstance(instanceID);
  
  BoneMatrix boneMatrix = getBoneMatrix(skinIndex, skinWeight);
  localPosition = getSkinPosition(boneMatrix, skinWeight, localPosition);

  mat4 finalModelMatrix = material.modelMatrix * instanceModelMatrix;
  vec4 worldPosition = finalModelMatrix * localPosition;
  v_worldPosition = worldPosition.xyz;

  vec4 viewPosition = material.viewMatrix * worldPosition;
  gl_Position  = material.projectionMatrix * viewPosition;
  gl_Position.z = gl_Position.z * 0.995; // Custom depth adjustments

  v_viewDepth = -viewPosition.z;
}