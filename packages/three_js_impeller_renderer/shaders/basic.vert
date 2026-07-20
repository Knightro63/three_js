#include <common.glsl>
#include <skinning.glsl>
#include <instancing.glsl>

in vec3 position;
in vec3 normal;
in vec2 uv;
in vec3 color;

in vec4 skinIndex;
in vec4 skinWeight;

in float instanceID;

out vec3 v_color;
out vec3 v_normal;
out vec2 v_uv;
out vec3 v_worldPosition;

void main() {
  mat4 instanceModelMatrix = mat4(1.0);
  vec3 instanceColor = color;
  vec4 skinPosition = vec4(position, 1.0);
  
  bool hasBoneTexture = material.flags0.x > 0.5;
  bool hasInstancingTexture = material.flags5.w > 0.5;
  bool hasInstancingColor = material.flags5.w > 1.5;
  if (hasInstancingTexture) {
    instanceModelMatrix = getInstanceMatrix(instanceID);
  }
  if (hasInstancingColor) {
    instanceColor = getInstanceColor(instanceID);
  }
  
  if (hasBoneTexture) {
    skinPosition = getSkinPosition(skinIndex, skinWeight, position);
  }
  
  vec4 worldPosition = material.modelMatrix * instanceModelMatrix * skinPosition;
  vec4 viewPosition = scene.viewMatrix * worldPosition;
  
  gl_Position = scene.projectionMatrix * viewPosition;
  
  // Optional: Safe replacement for depth squeezing if you run into clipping issues
  // gl_Position.z -= 0.0001; 
  gl_Position.z = gl_Position.z * 0.995; 

  v_worldPosition = worldPosition.xyz;
  v_uv = uv;
  v_color = instanceColor;

  mat4 fullModelMatrix = material.modelMatrix * instanceModelMatrix;
  mat3 combinedNormalMatrix = transpose(inverse(mat3(fullModelMatrix)));
  v_normal = normalize(combinedNormalMatrix * normal);
}
